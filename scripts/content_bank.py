#!/usr/bin/env python3
"""Validate and render the BookQuotes cross-channel content bank."""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import struct
import subprocess
import sys
import unicodedata
import zlib
from datetime import date, datetime
from pathlib import Path
from typing import Any, Iterable

CHANNELS = ("tiktok", "instagram", "facebook")
APP_STORE_LOOKUP = "https://itunes.apple.com/lookup?id=6758091579&country=gb"
ALLOWED_SOURCES = {
    "S0": ("editorial", "internal://bookquotes/original-editorial"),
    "S1": ("app_store_public", APP_STORE_LOOKUP),
}
ALLOWED_TERRITORIES = {"discovery", "reader_practice", "bookquotes_proof"}
ALLOWED_APPROVAL_STATES = {"draft", "in_review", "approved"}
HEX64 = re.compile(r"^[0-9a-f]{64}$")
ID_PATTERN = re.compile(r"^bq14-[0-9]{2}$")
ACTIVE_COPY_PATTERNS = (
    re.compile(r"<\s*/?\s*[A-Za-z][^>]*>"),
    re.compile(r"!\["),
    re.compile(r"\[[^\]]+\]\([^)]*\)"),
    re.compile(r"(?i)javascript\s*:"),
)
SAFE_LEFT = 140
SAFE_RIGHT = 940
SAFE_TOP = 170
SAFE_BOTTOM = 1500



def _pairs_no_duplicates(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_pairs_no_duplicates)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        raise ValueError(f"unable to load {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError("content bank top level must be an object")
    return value


def _escape_markdown_text(value: Any) -> str:
    text = html.escape(str(value), quote=False)
    replacements = {
        "\\": "&#92;",
        "|": "&#124;",
        "`": "&#96;",
        "[": "&#91;",
        "]": "&#93;",
        "(": "&#40;",
        ")": "&#41;",
        "!": "&#33;",
        "*": "&#42;",
        "_": "&#95;",
        "~": "&#126;",
        "{": "&#123;",
        "}": "&#125;",
    }
    for character, entity in replacements.items():
        text = text.replace(character, entity)
    return text.replace("\r\n", "<br>").replace("\r", "<br>").replace("\n", "<br>")


def markdown_text(value: Any) -> str:
    return _escape_markdown_text(value)


def markdown_code(value: Any) -> str:
    return f"<code>{markdown_text(value).replace('<br>', '&#10;')}</code>"


def _canonical(value: Any) -> bytes:
    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
        allow_nan=False,
    ).encode("utf-8")


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _sha256_path(path: Path) -> str:
    return _sha256_bytes(path.read_bytes())


def _normalise(value: str) -> str:
    value = unicodedata.normalize("NFKC", value).replace("\r\n", "\n").replace("\r", "\n")
    return " ".join(value.strip().split()).casefold()


def _parse_date(value: Any) -> date | None:
    if not isinstance(value, str):
        return None
    try:
        return date.fromisoformat(value)
    except ValueError:
        return None


def _parse_aware_datetime(value: Any) -> datetime | None:
    if not isinstance(value, str):
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None or parsed.utcoffset() is None:
        return None
    return parsed


def _check_keys(value: Any, allowed: set[str], path: str, errors: list[str]) -> None:
    if not isinstance(value, dict):
        errors.append(f"{path} must be an object")
        return
    unknown = sorted(set(value) - allowed)
    if unknown:
        errors.append(f"{path} has unknown keys: {', '.join(unknown)}")


def _png_dimensions(raw: bytes) -> tuple[int, int] | None:
    if len(raw) < 24 or raw[:8] != b"\x89PNG\r\n\x1a\n" or raw[12:16] != b"IHDR":
        return None
    width, height = struct.unpack(">II", raw[16:24])
    return (width, height) if width and height else None


def _jpeg_dimensions(raw: bytes) -> tuple[int, int] | None:
    if len(raw) < 4 or raw[:2] != b"\xff\xd8":
        return None
    offset = 2
    while offset + 9 < len(raw):
        while offset < len(raw) and raw[offset] != 0xFF:
            offset += 1
        while offset < len(raw) and raw[offset] == 0xFF:
            offset += 1
        if offset >= len(raw):
            break
        marker = raw[offset]
        offset += 1
        if marker in (0xD8, 0xD9):
            continue
        if offset + 2 > len(raw):
            break
        segment_length = struct.unpack(">H", raw[offset : offset + 2])[0]
        if segment_length < 2 or offset + segment_length > len(raw):
            break
        if marker in set(range(0xC0, 0xC4)) | set(range(0xC5, 0xC8)) | set(range(0xC9, 0xCC)) | set(range(0xCD, 0xD0)):
            if segment_length >= 7:
                height, width = struct.unpack(">HH", raw[offset + 3 : offset + 7])
                return (width, height) if width and height else None
        offset += segment_length
    return None


def probe_dimensions(path: Path) -> tuple[int, int] | None:
    raw = path.read_bytes()
    return _png_dimensions(raw) or _jpeg_dimensions(raw)


def _png_content_bounds(path: Path) -> tuple[int, int, int, int] | None:
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    offset = 8
    width = height = bit_depth = color_type = interlace = None
    compressed = bytearray()
    while offset + 8 <= len(raw):
        length = struct.unpack(">I", raw[offset : offset + 4])[0]
        kind = raw[offset + 4 : offset + 8]
        payload_start = offset + 8
        payload_end = payload_start + length
        if payload_end + 4 > len(raw):
            return None
        payload = raw[payload_start:payload_end]
        if kind == b"IHDR" and len(payload) >= 13:
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload[:13])
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"IEND":
            break
        offset = payload_end + 4
    if None in {width, height, bit_depth, color_type, interlace} or bit_depth != 8 or color_type not in {2, 6} or interlace != 0:
        return None
    assert width is not None and height is not None and bit_depth is not None and color_type is not None and interlace is not None
    channels = 4 if color_type == 6 else 3
    stride = width * channels
    try:
        decoded = zlib.decompress(bytes(compressed))
    except zlib.error:
        return None
    if len(decoded) != height * (stride + 1):
        return None
    rows: list[bytearray] = []
    previous = bytearray(stride)
    for row_index in range(height):
        start = row_index * (stride + 1)
        filter_type = decoded[start]
        source = decoded[start + 1 : start + 1 + stride]
        row = bytearray(stride)
        for index, value in enumerate(source):
            left = row[index - channels] if index >= channels else 0
            up = previous[index]
            up_left = previous[index - channels] if index >= channels else 0
            if filter_type == 0:
                row[index] = value
            elif filter_type == 1:
                row[index] = (value + left) & 0xFF
            elif filter_type == 2:
                row[index] = (value + up) & 0xFF
            elif filter_type == 3:
                row[index] = (value + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                estimate = left + up - up_left
                distances = (abs(estimate - left), abs(estimate - up), abs(estimate - up_left))
                predictor = (left, up, up_left)[distances.index(min(distances))]
                row[index] = (value + predictor) & 0xFF
            else:
                return None
        rows.append(row)
        previous = row
    background = tuple(rows[0][:3])
    bounds: tuple[int, int, int, int] | None = None
    for y, row in enumerate(rows):
        for x in range(width):
            index = x * channels
            if channels == 4 and row[index + 3] == 0:
                continue
            pixel = tuple(row[index : index + 3])
            if sum(abs(channel - base) for channel, base in zip(pixel, background)) <= 18:
                continue
            point = (x, y)
            bounds = point + point if bounds is None else (
                min(bounds[0], x), min(bounds[1], y), max(bounds[2], x), max(bounds[3], y)
            )
    return bounds


def _check_copy(value: Any, path: str, errors: list[str]) -> None:
    if not isinstance(value, str):
        return
    if any(pattern.search(value) for pattern in ACTIVE_COPY_PATTERNS):
        _add_error(errors, path, "must not contain active HTML, Markdown links, images, or javascript URLs")


def _safe_asset_path(repo_root: Path, relative: Any) -> tuple[Path | None, str | None]:
    if not isinstance(relative, str) or not relative.strip():
        return None, "path must be a non-empty repository-relative string"
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts:
        return None, "path must not be absolute or contain '..'"
    root = repo_root.resolve()
    raw_candidate = root / path
    current = raw_candidate
    while current != root:
        if current.is_symlink():
            return None, "path must not contain symlink components"
        current = current.parent
    candidate = raw_candidate.resolve(strict=False)
    try:
        candidate.relative_to(root)
    except ValueError:
        return None, "path resolves outside the repository root"
    if not candidate.exists():
        return None, "asset file does not exist"
    if not candidate.is_file():
        return None, "asset path is not a regular file"
    if candidate.is_symlink():
        return None, "asset path must not be a symlink"
    return candidate, None


def _add_error(errors: list[str], path: str, message: str) -> None:
    errors.append(f"{path}: {message}")


def _validate_sources(data: dict[str, Any], errors: list[str]) -> dict[str, dict[str, Any]]:
    raw_sources = data.get("sources")
    if not isinstance(raw_sources, list) or not raw_sources:
        _add_error(errors, "sources", "must be a non-empty list")
        return {}
    source_map: dict[str, dict[str, Any]] = {}
    for index, source in enumerate(raw_sources):
        path = f"sources[{index}]"
        _check_keys(source, {"id", "kind", "locator", "checked_at"}, path, errors)
        if not isinstance(source, dict):
            continue
        source_id = source.get("id")
        if not isinstance(source_id, str) or not source_id.strip():
            _add_error(errors, f"{path}.id", "must be non-empty")
            continue
        if source_id in source_map:
            _add_error(errors, f"{path}.id", "must be unique")
        source_map[source_id] = source
        expected = ALLOWED_SOURCES.get(source_id)
        if expected is None:
            _add_error(errors, f"{path}.id", "is not in the audited source allowlist")
        else:
            if source.get("kind") != expected[0] or source.get("locator") != expected[1]:
                _add_error(errors, path, "kind and locator do not match the audited source")
        if _parse_aware_datetime(source.get("checked_at")) is None:
            _add_error(errors, f"{path}.checked_at", "must be timezone-aware ISO-8601")
    return source_map


def _validate_assets(data: dict[str, Any], errors: list[str], repo_root: Path) -> dict[str, dict[str, Any]]:
    raw_assets = data.get("assets")
    if not isinstance(raw_assets, list) or not raw_assets:
        _add_error(errors, "assets", "must be a non-empty list")
        return {}
    asset_map: dict[str, dict[str, Any]] = {}
    byte_owners: dict[str, str] = {}
    for index, asset in enumerate(raw_assets):
        path = f"assets[{index}]"
        _check_keys(asset, {"id", "path", "media_type", "width", "height", "rights", "checks"}, path, errors)
        if not isinstance(asset, dict):
            continue
        asset_id = asset.get("id")
        if not isinstance(asset_id, str) or not asset_id.strip():
            _add_error(errors, f"{path}.id", "must be non-empty")
            continue
        if asset_id in asset_map:
            _add_error(errors, f"{path}.id", "must be unique")
        asset_map[asset_id] = asset
        candidate, path_error = _safe_asset_path(repo_root, asset.get("path"))
        if path_error:
            _add_error(errors, f"{path}.path", path_error)
        media_type = asset.get("media_type")
        if media_type not in {"image/png", "image/jpeg"}:
            _add_error(errors, f"{path}.media_type", "must be image/png or image/jpeg")
        if not isinstance(asset.get("width"), int) or not isinstance(asset.get("height"), int):
            _add_error(errors, path, "width and height must be integers")
        elif asset.get("width") != 1080 or asset.get("height") != 1920:
            _add_error(errors, path, "dimensions must be exactly 1080x1920 portrait masters")
        elif candidate is not None:
            raw = candidate.read_bytes()
            if media_type == "image/png" and raw[:8] != b"\x89PNG\r\n\x1a\n":
                _add_error(errors, f"{path}.path", "declared PNG media type does not match file signature")
            if media_type == "image/jpeg" and raw[:2] != b"\xff\xd8":
                _add_error(errors, f"{path}.path", "declared JPEG media type does not match file signature")
            dimensions = probe_dimensions(candidate)
            if dimensions != (asset.get("width"), asset.get("height")):
                _add_error(errors, f"{path}.path", f"probed dimensions {dimensions!r} do not match declaration")
            digest = _sha256_bytes(raw)
            if digest in byte_owners:
                _add_error(errors, f"{path}.path", f"asset bytes are duplicated by {byte_owners[digest]}")
            else:
                byte_owners[digest] = asset_id
            checks = asset.get("checks")
            safe_area = checks.get("safe_area") if isinstance(checks, dict) else None
            if media_type == "image/png" and isinstance(safe_area, dict) and safe_area.get("status") == "passed":
                bounds = _png_content_bounds(candidate)
                if bounds is None:
                    _add_error(errors, f"{path}.path", "passed safe-area PNG content bounds could not be measured")
                elif bounds[0] < SAFE_LEFT or bounds[2] > SAFE_RIGHT or bounds[1] < SAFE_TOP or bounds[3] > SAFE_BOTTOM:
                    _add_error(errors, f"{path}.checks.safe_area", f"measured content bounds {bounds!r} exceed {SAFE_LEFT}..{SAFE_RIGHT} x {SAFE_TOP}..{SAFE_BOTTOM}")
        rights = asset.get("rights")
        _check_keys(rights, {"status", "basis", "source"}, f"{path}.rights", errors)
        if isinstance(rights, dict):
            if rights.get("status") not in {"pending", "verified", "rejected"}:
                _add_error(errors, f"{path}.rights.status", "must be pending, verified, or rejected")
            if rights.get("basis") not in {"original", "licensed", "permission_granted", "public_domain"}:
                _add_error(errors, f"{path}.rights.basis", "has an unsupported rights basis")
            if not isinstance(rights.get("source"), str) or not rights["source"].strip():
                _add_error(errors, f"{path}.rights.source", "must be non-empty")
        checks = asset.get("checks")
        _check_keys(checks, {"safe_area", "readability"}, f"{path}.checks", errors)
        if isinstance(checks, dict):
            for check_name in ("safe_area", "readability"):
                check = checks.get(check_name)
                _check_keys(check, {"status", "evidence"}, f"{path}.checks.{check_name}", errors)
                if isinstance(check, dict):
                    if check.get("status") not in {"pending", "passed", "failed"}:
                        _add_error(errors, f"{path}.checks.{check_name}.status", "has an unsupported status")
                    if not isinstance(check.get("evidence"), str) or not check["evidence"].strip():
                        _add_error(errors, f"{path}.checks.{check_name}.evidence", "must be non-empty")
    return asset_map


def _valid_alt_text(value: Any) -> bool:
    if not isinstance(value, str) or len(value.strip()) < 12:
        return False
    lowered = value.strip().casefold()
    return lowered not in {"image", "video", "photo", "graphic"} and not lowered.startswith(("http://", "https://"))


def _validate_approval(
    item: dict[str, Any],
    item_path: str,
    asset: dict[str, Any],
    repo_root: Path,
    errors: list[str],
) -> None:
    approval = item.get("approval")
    _check_keys(approval, {"state", "record"}, f"{item_path}.approval", errors)
    if not isinstance(approval, dict):
        return
    state = approval.get("state")
    record = approval.get("record")
    if state not in ALLOWED_APPROVAL_STATES:
        _add_error(errors, f"{item_path}.approval.state", "must be draft, in_review, or approved")
        return
    if state in {"draft", "in_review"}:
        if record is not None:
            _add_error(errors, f"{item_path}.approval.record", "must be null before approval")
        return
    if not isinstance(record, dict):
        _add_error(errors, f"{item_path}.approval.record", "must be an object for approved items")
        return
    _check_keys(record, {"approved_by", "approved_at", "native_queue_confirmed", "content_sha256", "asset_sha256", "caption_sha256"}, f"{item_path}.approval.record", errors)
    for field in ("approved_by", "approved_at", "native_queue_confirmed", "content_sha256", "asset_sha256", "caption_sha256"):
        if field not in record:
            _add_error(errors, f"{item_path}.approval.record.{field}", "is required for approved items")
    if not isinstance(record.get("approved_by"), str) or not record.get("approved_by", "").strip():
        _add_error(errors, f"{item_path}.approval.record.approved_by", "must be non-empty")
    if record.get("native_queue_confirmed") is not True:
        _add_error(errors, f"{item_path}.approval.record.native_queue_confirmed", "must be true for approved items")
    if _parse_aware_datetime(record.get("approved_at")) is None:
        _add_error(errors, f"{item_path}.approval.record.approved_at", "must be timezone-aware ISO-8601")
    rights = asset.get("rights", {})
    checks = asset.get("checks", {})
    if rights.get("status") != "verified":
        _add_error(errors, f"{item_path}.asset", "rights.status must be verified before approval")
    for check_name in ("safe_area", "readability"):
        if checks.get(check_name, {}).get("status") != "passed":
            _add_error(errors, f"{item_path}.asset", f"{check_name} must be passed before approval")
    candidate, path_error = _safe_asset_path(repo_root, asset.get("path"))
    if candidate is None or path_error:
        return
    asset_hashes = record.get("asset_sha256")
    expected_asset_ids = {asset.get("id")}
    if not isinstance(asset_hashes, dict) or set(asset_hashes) != expected_asset_ids or asset_hashes.get(asset.get("id")) != _sha256_path(candidate):
        _add_error(errors, f"{item_path}.approval.record.asset_sha256", "must exactly match the referenced asset and current bytes")
    captions = record.get("caption_sha256")
    if not isinstance(captions, dict) or set(captions) != set(CHANNELS):
        _add_error(errors, f"{item_path}.approval.record.caption_sha256", "must exactly map TikTok, Instagram, and Facebook")
    else:
        for channel, adaptation in item.get("channels", {}).items():
            if captions.get(channel) != _sha256_bytes(adaptation.get("caption", "").encode("utf-8")):
                _add_error(errors, f"{item_path}.approval.record.caption_sha256.{channel}", "does not match exact caption bytes")
    expected_content = _sha256_bytes(_canonical({key: value for key, value in item.items() if key != "approval"}))
    if record.get("content_sha256") != expected_content:
        _add_error(errors, f"{item_path}.approval.record.content_sha256", "does not match canonical item content")
    for key in ("content_sha256",):
        if not isinstance(record.get(key), str) or not HEX64.fullmatch(record.get(key, "")):
            _add_error(errors, f"{item_path}.approval.record.{key}", "must be lowercase SHA-256 hex")
    if isinstance(asset_hashes, dict):
        for key, value in asset_hashes.items():
            if not isinstance(value, str) or not HEX64.fullmatch(value):
                _add_error(errors, f"{item_path}.approval.record.asset_sha256.{key}", "must be lowercase SHA-256 hex")
    if isinstance(captions, dict):
        for key, value in captions.items():
            if not isinstance(value, str) or not HEX64.fullmatch(value):
                _add_error(errors, f"{item_path}.approval.record.caption_sha256.{key}", "must be lowercase SHA-256 hex")


def build_approval_record(
    item: dict[str, Any],
    asset: dict[str, Any],
    repo_root: Path,
    approved_by: str,
    approved_at: str,
) -> dict[str, Any]:
    candidate, path_error = _safe_asset_path(repo_root.resolve(), asset.get("path"))
    if candidate is None or path_error:
        raise ValueError(f"cannot hash approval asset: {path_error or 'invalid path'}")
    if not isinstance(approved_by, str) or not approved_by.strip():
        raise ValueError("approved_by must be non-empty")
    if _parse_aware_datetime(approved_at) is None:
        raise ValueError("approved_at must be timezone-aware ISO-8601")
    item_without_approval = {key: value for key, value in item.items() if key != "approval"}
    return {
        "approved_by": approved_by,
        "approved_at": approved_at,
        "native_queue_confirmed": True,
        "content_sha256": _sha256_bytes(_canonical(item_without_approval)),
        "asset_sha256": {asset["id"]: _sha256_path(candidate)},
        "caption_sha256": {
            channel: _sha256_bytes(item["channels"][channel]["caption"].encode("utf-8"))
            for channel in CHANNELS
        },
    }


def _validate_baseline(data: dict[str, Any], baseline: dict[str, Any], errors: list[str]) -> None:
    baseline_items = {
        item.get("id"): item
        for item in baseline.get("items", [])
        if isinstance(item, dict) and isinstance(item.get("approval"), dict) and item["approval"].get("state") == "approved"
    }
    current_items = {item.get("id"): item for item in data.get("items", []) if isinstance(item, dict)}
    baseline_assets = {asset.get("id"): asset for asset in baseline.get("assets", []) if isinstance(asset, dict)}
    current_assets = {asset.get("id"): asset for asset in data.get("assets", []) if isinstance(asset, dict)}
    baseline_sources = {source.get("id"): source for source in baseline.get("sources", []) if isinstance(source, dict)}
    current_sources = {source.get("id"): source for source in data.get("sources", []) if isinstance(source, dict)}
    for item_id, baseline_item in baseline_items.items():
        current_item = current_items.get(item_id)
        if current_item is None or _canonical(current_item) != _canonical(baseline_item):
            _add_error(errors, f"items[{item_id}]", "baseline approved item cannot be mutated or deleted")
        asset_ids = {baseline_item.get("asset_id")}
        channels = baseline_item.get("channels")
        if isinstance(channels, dict):
            asset_ids.update(
                adaptation.get("asset_id")
                for adaptation in channels.values()
                if isinstance(adaptation, dict)
            )
        for asset_id in asset_ids - {None}:
            if asset_id not in current_assets or _canonical(current_assets[asset_id]) != _canonical(baseline_assets.get(asset_id)):
                _add_error(errors, f"assets[{asset_id}]", "asset metadata referenced by a baseline approved item cannot be mutated or deleted")
        source_ids = {
            source_id
            for claim in baseline_item.get("claims", [])
            if isinstance(claim, dict)
            for source_id in claim.get("source_ids", [])
            if isinstance(source_id, str)
        }
        for source_id in source_ids:
            if source_id not in current_sources or _canonical(current_sources[source_id]) != _canonical(baseline_sources.get(source_id)):
                _add_error(errors, f"sources[{source_id}]", "source metadata referenced by a baseline approved item cannot be mutated or deleted")


def validate(
    data: dict[str, Any],
    repo_root: Path | None = None,
    baseline_data: dict[str, Any] | None = None,
) -> None:
    errors: list[str] = []
    repo_root = (repo_root or Path.cwd()).resolve()
    _check_keys(data, {"schema_version", "bank_id", "period", "sources", "assets", "items"}, "bank", errors)
    if data.get("schema_version") != 1:
        _add_error(errors, "schema_version", "must be 1")
    if not isinstance(data.get("bank_id"), str) or not data.get("bank_id", "").strip():
        _add_error(errors, "bank_id", "must be non-empty")
    period = data.get("period")
    _check_keys(period, {"start_date", "end_date", "timezone"}, "period", errors)
    start = _parse_date(period.get("start_date")) if isinstance(period, dict) else None
    end = _parse_date(period.get("end_date")) if isinstance(period, dict) else None
    if start is None or end is None or end < start:
        _add_error(errors, "period", "start_date and end_date must be ordered ISO dates")
    if isinstance(period, dict) and (not isinstance(period.get("timezone"), str) or not period.get("timezone", "").strip()):
        _add_error(errors, "period.timezone", "must be non-empty")
    source_map = _validate_sources(data, errors)
    asset_map = _validate_assets(data, errors, repo_root)
    raw_items = data.get("items")
    if not isinstance(raw_items, list) or not raw_items:
        _add_error(errors, "items", "must be a non-empty list")
        raw_items = []
    if start is not None and end is not None:
        expected_dates = [start.fromordinal(start.toordinal() + offset) for offset in range((end - start).days + 1)]
        actual_dates = [_parse_date(item.get("date")) for item in raw_items if isinstance(item, dict)]
        if len(expected_dates) != 14 or sorted(actual_dates, key=lambda value: value or date.min) != expected_dates:
            _add_error(errors, "items", "must contain exactly 14 consecutive dates in period order")
    if len(raw_items) != 14:
        _add_error(errors, "items", "must contain exactly 14 primary records")
    ids: set[str] = set()
    hooks: dict[str, str] = {}
    captions: dict[tuple[str, str], str] = {}
    asset_owners: dict[str, str] = {}
    product_count = 0
    for index, item in enumerate(raw_items):
        path = f"items[{index}]"
        _check_keys(item, {"id", "date", "territory", "product_led", "audience", "hook", "format", "cta", "metric_hypothesis", "claims", "asset_id", "channels", "approval"}, path, errors)
        if not isinstance(item, dict):
            continue
        item_id = item.get("id")
        if not isinstance(item_id, str) or not ID_PATTERN.fullmatch(item_id):
            _add_error(errors, f"{path}.id", "must match bq14-NN")
        elif item_id in ids:
            _add_error(errors, f"{path}.id", "must be unique")
        else:
            ids.add(item_id)
        item_date = _parse_date(item.get("date"))
        if item_date is None:
            _add_error(errors, f"{path}.date", "must be an ISO date")
        territory = item.get("territory")
        product_led = item.get("product_led")
        if territory not in ALLOWED_TERRITORIES:
            _add_error(errors, f"{path}.territory", "is unsupported")
        if not isinstance(product_led, bool):
            _add_error(errors, f"{path}.product_led", "must be boolean")
        else:
            product_count += int(product_led)
            if product_led != (territory == "bookquotes_proof"):
                _add_error(errors, f"{path}.product_led", "must match bookquotes_proof territory")
        for field in ("audience", "hook", "format", "cta", "metric_hypothesis", "asset_id"):
            if not isinstance(item.get(field), str) or not item.get(field, "").strip():
                _add_error(errors, f"{path}.{field}", "must be non-empty")
        for field in ("audience", "hook", "format", "cta", "metric_hypothesis"):
            _check_copy(item.get(field), f"{path}.{field}", errors)
        if isinstance(item.get("hook"), str):
            key = _normalise(item["hook"])
            if key in hooks:
                _add_error(errors, f"{path}.hook", f"duplicates {hooks[key]}")
            hooks[key] = item_id or path
        asset_id = item.get("asset_id")
        asset = asset_map.get(asset_id) if isinstance(asset_id, str) else None
        if asset is None:
            _add_error(errors, f"{path}.asset_id", "must reference an asset")
        elif isinstance(asset_id, str) and isinstance(item_id, str) and asset_id in asset_owners and asset_owners[asset_id] != item_id:
            _add_error(errors, f"{path}.asset_id", f"asset is already owned by {asset_owners[asset_id]}")
        elif isinstance(asset_id, str) and isinstance(item_id, str):
            asset_owners[asset_id] = item_id
        claims = item.get("claims")
        if not isinstance(claims, list) or not claims:
            _add_error(errors, f"{path}.claims", "must be a non-empty list")
        else:
            for claim_index, claim in enumerate(claims):
                claim_path = f"{path}.claims[{claim_index}]"
                _check_keys(claim, {"text", "source_ids"}, claim_path, errors)
                if not isinstance(claim, dict):
                    continue
                if not isinstance(claim.get("text"), str) or not claim.get("text", "").strip():
                    _add_error(errors, f"{claim_path}.text", "must be non-empty")
                _check_copy(claim.get("text"), f"{claim_path}.text", errors)
                source_ids = claim.get("source_ids")
                valid_source_ids = isinstance(source_ids, list) and bool(source_ids) and all(
                    isinstance(source_id, str) and source_id in source_map for source_id in source_ids
                )
                if not valid_source_ids:
                    _add_error(errors, f"{claim_path}.source_ids", "must be a list of audited source IDs")
            if product_led and not any(
                isinstance(claim, dict)
                and isinstance(claim.get("source_ids"), list)
                and "S1" in claim["source_ids"]
                for claim in claims
            ):
                _add_error(errors, f"{path}.claims", "product-led app claims require the audited App Store source")
        channels = item.get("channels")
        if not isinstance(channels, dict) or set(channels) != set(CHANNELS):
            _add_error(errors, f"{path}.channels", "must contain exactly TikTok, Instagram, and Facebook")
            channels = channels if isinstance(channels, dict) else {}
        for channel in CHANNELS:
            adaptation = channels.get(channel)
            adaptation_path = f"{path}.channels.{channel}"
            _check_keys(adaptation, {"format", "caption", "asset_id", "alt_text"}, adaptation_path, errors)
            if not isinstance(adaptation, dict):
                continue
            for field in ("format", "caption", "asset_id"):
                if not isinstance(adaptation.get(field), str) or not adaptation.get(field, "").strip():
                    _add_error(errors, f"{adaptation_path}.{field}", "must be non-empty")
            for field in ("format", "caption", "alt_text"):
                _check_copy(adaptation.get(field), f"{adaptation_path}.{field}", errors)
            if adaptation.get("asset_id") != asset_id:
                _add_error(errors, f"{adaptation_path}.asset_id", "must match item asset_id")
            if not _valid_alt_text(adaptation.get("alt_text")):
                _add_error(errors, f"{adaptation_path}.alt_text", "must be meaningful accessibility text")
            caption = adaptation.get("caption")
            if isinstance(caption, str):
                key = (channel, _normalise(caption))
                if key in captions:
                    _add_error(errors, f"{adaptation_path}.caption", f"duplicates {captions[key]}")
                captions[key] = item_id or path
        if asset is not None:
            _validate_approval(item, path, asset, repo_root, errors)
    if raw_items and product_count / len(raw_items) > 0.20:
        _add_error(errors, "items", "product-led share must be at most 20%")
    if baseline_data is not None:
        _validate_baseline(data, baseline_data, errors)
    if errors:
        raise ValueError("Content bank validation failed:\n- " + "\n- ".join(errors))


def _render_claims(item: dict[str, Any]) -> str:
    claims = []
    for claim in item.get("claims", []):
        sources = ", ".join(str(source_id) for source_id in claim.get("source_ids", []))
        claims.append(f"{markdown_text(claim.get('text', ''))} [{markdown_text(sources)}]")
    return "; ".join(claims)


def render(data: dict[str, Any]) -> str:
    period = data["period"]
    items = sorted(data["items"], key=lambda item: (item["date"], item["id"]))
    product_count = sum(bool(item["product_led"]) for item in items)
    lines = [
        "# BookQuotes 14-Day Content Bank",
        "",
        f"Bank: {markdown_code(data['bank_id'])}",
        f"Period: {markdown_code(period['start_date'])} to {markdown_code(period['end_date'])} ({markdown_text(period['timezone'])})",
        f"Primary records: {len(items)}; product-led: {product_count} ({product_count / len(items):.1%})",
        "",
        "## Editorial records",
        "",
        "| Date | ID | Territory | Audience | Hook | Format | Product-led | Asset | Approval |",
        "|---|---|---|---|---|---|---:|---|---|",
    ]
    for item in items:
        approval = item["approval"]["state"]
        lines.append(
            "| "
            + " | ".join(
                (
                    markdown_text(item["date"]),
                    markdown_text(item["id"]),
                    markdown_text(item["territory"]),
                    markdown_text(item["audience"]),
                    markdown_text(item["hook"]),
                    markdown_text(item["format"]),
                    markdown_text(item["product_led"]),
                    markdown_text(item["asset_id"]),
                    markdown_text(approval),
                )
            )
            + " |"
        )
    lines.extend(["", "## Claims and channel adaptations", ""])
    for item in items:
        lines.extend(
            [
                f"### {markdown_text(item['date'])} · {markdown_text(item['id'])}",
                f"- CTA: {markdown_text(item['cta'])}",
                f"- Metric hypothesis: {markdown_text(item['metric_hypothesis'])}",
                f"- Claims: {_render_claims(item)}",
            ]
        )
        for channel in CHANNELS:
            adaptation = item["channels"][channel]
            lines.append(
                f"- {markdown_text(channel)}: {markdown_text(adaptation['format'])}; "
                f"caption {markdown_code(adaptation['caption'])}; "
                f"alt text {markdown_text(adaptation['alt_text'])}"
            )
        lines.append("")
    lines.extend(["## Assets", "", "| ID | Path | Dimensions | Rights | Safe area | Readability |", "|---|---|---|---|---|---|"])
    for asset in sorted(data["assets"], key=lambda entry: entry["id"]):
        lines.append(
            "| "
            + " | ".join(
                (
                    markdown_text(asset["id"]),
                    markdown_text(asset["path"]),
                    markdown_text(f"{asset['width']}×{asset['height']}"),
                    markdown_text(f"{asset['rights']['status']} ({asset['rights']['basis']})"),
                    markdown_text(asset["checks"]["safe_area"]["status"]),
                    markdown_text(asset["checks"]["readability"]["status"]),
                )
            )
            + " |"
        )
    lines.extend(["", "## Sources", "", "| ID | Kind | Locator | Checked at |", "|---|---|---|---|"])
    for source in sorted(data["sources"], key=lambda entry: entry["id"]):
        lines.append(
            "| "
            + " | ".join(
                (
                    markdown_text(source["id"]),
                    markdown_text(source["kind"]),
                    markdown_text(source["locator"]),
                    markdown_text(source["checked_at"]),
                )
            )
            + " |"
        )
    return "\n".join(lines) + "\n"


def _load_baseline_ref(bank_path: Path, repo_root: Path, ref: str) -> dict[str, Any]:
    try:
        relative = bank_path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError as exc:
        raise ValueError("baseline validation requires a bank path inside the repository") from exc
    result = subprocess.run(
        ["git", "show", f"{ref}:{relative}"],
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise ValueError(f"unable to read baseline {ref}: {result.stderr.strip()}")
    try:
        value = json.loads(result.stdout, object_pairs_hook=_pairs_no_duplicates)
    except (json.JSONDecodeError, ValueError) as exc:
        raise ValueError(f"baseline {ref} is not valid JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError("baseline content bank top level must be an object")
    return value


def _write_if_changed(path: Path, content: str) -> None:
    encoded = content.encode("utf-8")
    if path.exists() and path.read_bytes() == encoded:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(encoded)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    validate_parser = subparsers.add_parser("validate")
    validate_parser.add_argument("bank", type=Path)
    validate_parser.add_argument("--baseline-ref")
    render_parser = subparsers.add_parser("render")
    render_parser.add_argument("bank", type=Path)
    render_parser.add_argument("--output", required=True, type=Path)
    render_parser.add_argument("--baseline-ref")
    approve_parser = subparsers.add_parser("approve")
    approve_parser.add_argument("bank", type=Path)
    approve_parser.add_argument("item_id")
    approve_parser.add_argument("--approved-by", required=True)
    approve_parser.add_argument("--approved-at", required=True)
    approve_parser.add_argument("--native-queue-confirmed", action="store_true", required=True)
    approve_parser.add_argument("--baseline-ref")
    args = parser.parse_args(argv)
    try:
        data = load_json(args.bank)
        repo_root = Path(__file__).resolve().parents[1]
        baseline = _load_baseline_ref(args.bank, repo_root, args.baseline_ref) if args.baseline_ref else None
        validate(data, repo_root=repo_root, baseline_data=baseline)
        if args.command == "approve":
            item = next((entry for entry in data["items"] if entry.get("id") == args.item_id), None)
            if item is None:
                raise ValueError(f"unknown item_id: {args.item_id}")
            if item["approval"]["state"] == "approved":
                raise ValueError(f"item {args.item_id} is already approved; create a new revision")
            asset = next(entry for entry in data["assets"] if entry["id"] == item["asset_id"])
            if asset["rights"]["status"] != "verified":
                raise ValueError("approval requires verified asset rights")
            if any(asset["checks"][check]["status"] != "passed" for check in ("safe_area", "readability")):
                raise ValueError("approval requires passed safe-area and readability checks")
            item["approval"] = {
                "state": "approved",
                "record": build_approval_record(item, asset, repo_root, args.approved_by, args.approved_at),
            }
            validate(data, repo_root=repo_root, baseline_data=baseline)
            _write_if_changed(args.bank, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
            print(f"approved {args.item_id} in {args.bank}")
            return 0
        if args.command == "render":
            _write_if_changed(args.output, render(data))
            print(f"validated and rendered {args.output}")
        else:
            print(f"validated {args.bank}")
        return 0
    except (OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
