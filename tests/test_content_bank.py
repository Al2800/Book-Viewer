from __future__ import annotations

import contextlib
import copy
import importlib.util
import io
import json
import struct
import sys
import tempfile
import unittest
import zlib
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/content_bank.py"
spec = importlib.util.spec_from_file_location("content_bank", SCRIPT)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Unable to load {SCRIPT}")
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


def png_bytes(width: int = 1080, height: int = 1920, seed: int = 0) -> bytes:
    def chunk(kind: bytes, payload: bytes) -> bytes:
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)

    background = bytes((235 - seed % 20, 235 - (seed * 3) % 20, 235 - (seed * 5) % 20, 255))
    accent = bytes((40 + (seed * 7) % 80, 80 + (seed * 5) % 80, 120 + (seed * 3) % 80, 255))
    rows = []
    for y in range(height):
        band = accent if 170 <= y <= 300 else background
        rows.append(b"\x00" + background * 140 + band * 801 + background * (width - 941))
    raw = b"".join(rows)
    header = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return header + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def draft_bank() -> dict:
    start = date(2026, 8, 19)
    items = []
    for index in range(14):
        item_id = f"bq14-{index + 1:02d}"
        items.append(
            {
                "id": item_id,
                "date": (start + timedelta(days=index)).isoformat(),
                "territory": "reader_practice" if index < 12 else "bookquotes_proof",
                "product_led": index >= 12,
                "audience": f"Readers who need prompt {index + 1}",
                "hook": f"A distinct reader prompt {index + 1}",
                "format": "typography_card",
                "cta": f"Try prompt {index + 1} and tell us what you notice.",
                "metric_hypothesis": "Useful prompts will earn saves per 1,000 reach.",
                "claims": [
                    {
                        "text": "An original optional reading prompt.",
                        "source_ids": ["S1" if index >= 12 else "S0"],
                    }
                ],
                "asset_id": item_id,
                "channels": {
                    channel: {
                        "format": "image",
                        "caption": f"{channel.title()} prompt {index + 1}: try this reading practice.",
                        "asset_id": item_id,
                        "alt_text": f"Original BookQuotes typography card for reader prompt {index + 1}.",
                    }
                    for channel in ("tiktok", "instagram", "facebook")
                },
                "approval": {"state": "draft", "record": None},
            }
        )
    return {
        "schema_version": 1,
        "bank_id": "bookquotes-2026-08-a",
        "period": {
            "start_date": start.isoformat(),
            "end_date": (start + timedelta(days=13)).isoformat(),
            "timezone": "Europe/London",
        },
        "sources": [
            {
                "id": "S0",
                "kind": "editorial",
                "locator": "internal://bookquotes/original-editorial",
                "checked_at": "2026-08-11T16:00:00+01:00",
            },
            {
                "id": "S1",
                "kind": "app_store_public",
                "locator": "https://itunes.apple.com/lookup?id=6758091579&country=gb",
                "checked_at": "2026-08-11T16:00:00+01:00",
            }
        ],
        "assets": [
            {
                "id": f"bq14-{index + 1:02d}",
                "path": f"assets/content-bank/bq14-{index + 1:02d}.png",
                "media_type": "image/png",
                "width": 1080,
                "height": 1920,
                "rights": {
                    "status": "pending",
                    "basis": "original",
                    "source": "BookQuotes-owned typography generated from this bank.",
                },
                "checks": {
                    "safe_area": {"status": "pending", "evidence": "Awaiting phone review."},
                    "readability": {"status": "pending", "evidence": "Awaiting phone review."},
                },
            }
            for index in range(14)
        ],
        "items": items,
    }


def approve_first(data: dict, repo: Path) -> None:
    item = data["items"][0]
    asset = next(entry for entry in data["assets"] if entry["id"] == item["asset_id"])
    asset["rights"]["status"] = "verified"
    asset["checks"]["safe_area"] = {"status": "passed", "evidence": "Reviewed in a 9:16 phone preview."}
    asset["checks"]["readability"] = {"status": "passed", "evidence": "Read at normal phone size with muted playback."}
    item["approval"] = {
        "state": "approved",
        "record": module.build_approval_record(item, asset, repo, "owner", "2026-08-11T17:00:00+01:00"),
    }


class ContentBankTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name)
        for index in range(14):
            path = self.repo / "assets" / "content-bank" / f"bq14-{index + 1:02d}.png"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(png_bytes(seed=index))

    def tearDown(self):
        self.temp.cleanup()

    def test_valid_fourteen_day_draft_bank_passes(self):
        module.validate(draft_bank(), repo_root=self.repo)

    def test_calendar_and_product_mix_are_strict(self):
        data = draft_bank()
        data["items"][5]["date"] = "2026-08-30"
        data["items"][0]["product_led"] = True
        data["items"][0]["territory"] = "bookquotes_proof"
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        message = str(raised.exception)
        self.assertIn("consecutive", message)
        self.assertIn("product-led", message)

    def test_product_led_requires_every_claim_to_cite_s1(self):
        data = draft_bank()
        data["items"][12]["claims"].append(
            {"text": "A second app claim with the wrong source.", "source_ids": ["S0"]}
        )
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        self.assertIn("each product-led claim", str(raised.exception))

    def test_channel_captions_must_be_distinct_within_item(self):
        data = draft_bank()
        data["items"][0]["channels"]["instagram"]["caption"] = data["items"][0]["channels"]["tiktok"]["caption"]
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        self.assertIn("caption", str(raised.exception))

    def test_approved_item_requires_verified_asset_checks_and_hashes(self):
        data = draft_bank()
        item = data["items"][0]
        item["approval"] = {"state": "approved", "record": {}}
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        message = str(raised.exception)
        self.assertIn("rights.status", message)
        self.assertIn("asset_sha256", message)

    def test_approved_item_with_matching_hashes_passes(self):
        data = draft_bank()
        item = data["items"][0]
        asset = next(entry for entry in data["assets"] if entry["id"] == item["asset_id"])
        asset["rights"]["status"] = "verified"
        asset["checks"]["safe_area"] = {"status": "passed", "evidence": "Reviewed in a 9:16 phone preview."}
        asset["checks"]["readability"] = {"status": "passed", "evidence": "Read at normal phone size with muted playback."}
        item["approval"] = {
            "state": "approved",
            "record": module.build_approval_record(item, asset, self.repo, "owner", "2026-08-11T17:00:00+01:00"),
        }
        module.validate(data, repo_root=self.repo)

    def test_approve_cli_parser_requires_confirmation_and_handles_unknown_id(self):
        with contextlib.redirect_stderr(io.StringIO()) as stderr:
            result = module.main([
                "approve",
                str(ROOT / "Marketing/Social/CommunityPush/ContentBank.json"),
                "unknown-item",
                "--approved-by",
                "owner",
                "--approved-at",
                "2026-08-11T17:00:00+01:00",
                "--native-queue-confirmed",
            ])
        self.assertEqual(result, 1)
        self.assertIn("unknown item_id", stderr.getvalue())

    def test_duplicate_asset_path_traversal_dimension_and_product_claims_fail(self):
        data = draft_bank()
        data["items"][1]["asset_id"] = data["items"][0]["asset_id"]
        data["items"][1]["channels"]["tiktok"]["asset_id"] = data["items"][0]["asset_id"]
        data["assets"][0]["path"] = "../outside.png"
        data["assets"][1]["width"] = 999
        data["items"][12]["claims"][0]["source_ids"] = ["S0"]
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        message = str(raised.exception)
        self.assertIn("absolute", message)
        self.assertIn("dimensions", message)
        self.assertIn("already owned", message)
        self.assertIn("App Store", message)

    def test_unknown_keys_and_unsupported_sources_fail_closed(self):
        data = draft_bank()
        data["unexpected"] = True
        data["sources"][0]["locator"] = "https://untrusted.example/claim"
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        message = str(raised.exception)
        self.assertIn("unknown keys", message)
        self.assertIn("audited source", message)

    def test_duplicate_hooks_and_channel_captions_are_rejected(self):
        data = draft_bank()
        data["items"][1]["hook"] = "  " + data["items"][0]["hook"].upper() + "  "
        data["items"][1]["channels"]["instagram"]["caption"] = data["items"][0]["channels"]["instagram"]["caption"]
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        message = str(raised.exception)
        self.assertIn("duplicates", message)

    def test_duplicate_json_keys_are_rejected(self):
        path = self.repo / "duplicate.json"
        path.write_text('{"schema_version": 1, "schema_version": 2}', encoding="utf-8")
        with self.assertRaises(ValueError) as raised:
            module.load_json(path)
        self.assertIn("duplicate JSON key", str(raised.exception))

    def test_duplicate_asset_bytes_are_rejected(self):
        data = draft_bank()
        data["assets"][1]["path"] = data["assets"][0]["path"]
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        self.assertIn("asset bytes are duplicated", str(raised.exception))

    def test_nested_claim_source_ids_fail_as_validation_errors(self):
        data = draft_bank()
        data["items"][0]["claims"][0]["source_ids"] = [[]]
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        self.assertIn("source_ids", str(raised.exception))

    def test_generated_asset_bounds_are_measured(self):
        asset_root = ROOT / "Marketing/Social/CommunityPush/assets/content-bank"
        for index in range(1, 15):
            bounds = module._png_content_bounds(asset_root / f"bq14-{index:02d}.png")
            self.assertEqual(bounds, (140, 170, 940, 1453))

    def test_symlink_asset_paths_are_rejected(self):
        link = self.repo / "assets" / "content-bank" / "linked.png"
        link.symlink_to(self.repo / "assets" / "content-bank" / "bq14-01.png")
        data = draft_bank()
        data["assets"][1]["path"] = "assets/content-bank/linked.png"
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        self.assertIn("symlink", str(raised.exception))

    def test_input_order_does_not_change_rendered_bytes(self):
        data = draft_bank()
        reordered = copy.deepcopy(data)
        reordered["items"] = list(reversed(reordered["items"]))
        reordered["assets"] = list(reversed(reordered["assets"]))
        reordered["sources"] = list(reversed(reordered["sources"]))
        module.validate(reordered, repo_root=self.repo)
        self.assertEqual(module.render(data), module.render(reordered))

    def test_baseline_approved_item_cannot_be_mutated_or_deleted(self):
        baseline = draft_bank()
        approve_first(baseline, self.repo)
        mutated = copy.deepcopy(baseline)
        mutated["items"][0]["hook"] = "Changed after approval"
        with self.assertRaises(ValueError) as raised:
            module.validate(mutated, repo_root=self.repo, baseline_data=baseline)
        self.assertIn("baseline approved item", str(raised.exception))
        deleted = copy.deepcopy(baseline)
        deleted["items"] = deleted["items"][1:]
        with self.assertRaises(ValueError) as raised:
            module.validate(deleted, repo_root=self.repo, baseline_data=baseline)
        self.assertIn("baseline approved item", str(raised.exception))
        asset_tampered = copy.deepcopy(baseline)
        asset_tampered["assets"][0]["rights"]["source"] = "changed rights evidence"
        with self.assertRaises(ValueError) as raised:
            module.validate(asset_tampered, repo_root=self.repo, baseline_data=baseline)
        self.assertIn("asset metadata", str(raised.exception))
        source_tampered = copy.deepcopy(baseline)
        source_tampered["sources"][0]["locator"] = "internal://changed"
        with self.assertRaises(ValueError) as raised:
            module.validate(source_tampered, repo_root=self.repo, baseline_data=baseline)
        self.assertIn("source metadata", str(raised.exception))

    def test_render_escapes_active_content_and_is_deterministic(self):
        data = draft_bank()
        data["items"][0]["hook"] = "<img src=x onerror=alert(1)> [track](https://invalid.example)"
        data["items"][0]["channels"]["tiktok"]["caption"] = data["items"][0]["hook"]
        with self.assertRaises(ValueError) as raised:
            module.validate(data, repo_root=self.repo)
        self.assertIn("active HTML", str(raised.exception))
        first = module.render(data)
        second = module.render(copy.deepcopy(data))
        self.assertEqual(first, second)
        self.assertNotIn("<img", first)
        self.assertNotIn("[track](", first)
        self.assertIn("&lt;img", first)
        self.assertIn("&#91;track&#93;&#40;https://invalid.example&#41;", first)


if __name__ == "__main__":
    unittest.main()
