#!/usr/bin/env python3
"""Validate BookQuotes growth evidence and render a deterministic scorecard."""

from __future__ import annotations

import argparse
import json
import math
import statistics
from collections import Counter
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

RESULT_LABELS = {
    "Pending",
    "Promising",
    "Needs another test",
    "Packaging failure",
    "Topic failure",
    "Winner",
    "Stopped",
}
SOCIAL_STATUSES = {"draft", "scheduled", "published", "failed", "stopped"}
CHECKPOINTS = {"preflight", "initial", "audit", "24h", "24h-plus", "72h", "7d", "7d-audit"}
STATUS_CHECKPOINTS = {
    "draft": {"preflight"},
    "scheduled": {"preflight"},
    "published": {"initial", "audit", "24h", "24h-plus", "72h", "7d", "7d-audit"},
    "failed": {"preflight", "initial", "audit"},
    "stopped": {"initial", "audit", "24h", "24h-plus", "72h", "7d", "7d-audit"},
}
CHECKPOINT_MIN_AGE = {
    "24h": timedelta(hours=20),
    "24h-plus": timedelta(hours=20),
    "72h": timedelta(hours=68),
    "7d": timedelta(days=6, hours=20),
    "7d-audit": timedelta(days=6, hours=20),
}
COMPARISON_RESULT_LABELS = {"Promising", "Packaging failure", "Topic failure", "Winner"}
COMPARISON_CHECKPOINTS = {"24h", "72h", "7d"}
RATE_METRICS = {
    "saves_per_1000_reach": ("saves", "reach", "saves/1k reach"),
    "meaningful_comments_per_1000_reach": ("comments", "reach", "meaningful comments/1k reach"),
}
REQUIRED_METRICS = {
    "views",
    "reach",
    "viewers",
    "interactions",
    "comments",
    "shares",
    "saves",
    "link_clicks",
    "follows",
}
CONTENT_INVARIANT_FIELDS = (
    "platform",
    "identity",
    "title",
    "format",
    "published_at",
    "experiment_id",
    "treatment",
    "rights_basis",
)


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError("top-level JSON must be an object")
    if data.get("schema_version") != 1:
        raise ValueError("schema_version must be 1")
    return data


def parse_timestamp(value: Any, field: str) -> datetime:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{field} must be a non-empty ISO-8601 timestamp")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ValueError(f"{field} is not an ISO-8601 timestamp: {value}") from error
    if parsed.utcoffset() is None:
        raise ValueError(f"{field} must include a timezone offset")
    return parsed


def is_later_observation(candidate: dict[str, Any], current: dict[str, Any]) -> bool:
    return parse_timestamp(candidate.get("observed_at"), "observed_at") >= parse_timestamp(
        current.get("observed_at"), "observed_at"
    )


def latest_content_observations(
    observations: list[dict[str, Any]], experiment_id: str | None = None
) -> dict[str, dict[str, Any]]:
    latest: dict[str, dict[str, Any]] = {}
    for observation in observations:
        if experiment_id is not None and observation.get("experiment_id") != experiment_id:
            continue
        content_id = observation.get("content_id")
        if not isinstance(content_id, str) or not content_id:
            continue
        try:
            parse_timestamp(observation.get("observed_at"), "observed_at")
        except ValueError:
            continue
        current = latest.get(content_id)
        if current is None or is_later_observation(observation, current):
            latest[content_id] = observation
    return latest


def normalized_comparison_checkpoint(checkpoint: Any) -> str | None:
    if checkpoint in ("24h", "24h-plus"):
        return "24h"
    if checkpoint == "72h":
        return "72h"
    if checkpoint in ("7d", "7d-audit"):
        return "7d"
    return None


def comparison_state(
    experiment: dict[str, Any], observations: list[dict[str, Any]]
) -> tuple[dict[str, list[dict[str, Any]]], bool]:
    declared = experiment.get("treatments")
    minimum = experiment.get("minimum_executions_per_treatment")
    primary_metric = experiment.get("primary_metric")
    experiment_id = experiment.get("id")
    if (
        not isinstance(declared, list)
        or not all(isinstance(item, str) for item in declared)
        or not isinstance(minimum, int)
        or isinstance(minimum, bool)
        or not isinstance(primary_metric, str)
        or primary_metric not in RATE_METRICS
        or not isinstance(experiment_id, str)
    ):
        return {}, False
    latest = latest_content_observations(observations)
    published = [
        item
        for item in latest.values()
        if item.get("experiment_id") == experiment_id and item.get("status") == "published"
    ]
    grouped = {
        treatment: [item for item in published if item.get("treatment") == treatment]
        for treatment in declared
    }
    checkpoints = {
        normalized_comparison_checkpoint(item.get("checkpoint"))
        for items in grouped.values()
        for item in items
    }
    all_items = [item for items in grouped.values() for item in items]
    ready = (
        all(len(items) >= minimum for items in grouped.values())
        and None not in checkpoints
        and len(checkpoints) == 1
        and checkpoints.issubset(COMPARISON_CHECKPOINTS)
        and all(experiment_metric_value(item, primary_metric) is not None for item in all_items)
    )
    return grouped, ready


def validate(data: dict[str, Any]) -> None:
    errors: list[str] = []
    updated_at: datetime | None = None
    try:
        updated_at = parse_timestamp(data.get("updated_at"), "updated_at")
    except ValueError as error:
        errors.append(str(error))

    collections: dict[str, list[Any]] = {}
    for name in ("experiments", "social_observations", "search_snapshots"):
        value = data.get(name)
        if not isinstance(value, list) or not value:
            errors.append(f"{name} must be a non-empty list")
            collections[name] = []
        else:
            collections[name] = value

    experiments = collections["experiments"]
    experiment_ids: set[str] = set()
    experiment_treatments: dict[str, set[str]] = {}
    for index, experiment in enumerate(experiments):
        prefix = f"experiments[{index}]"
        if not isinstance(experiment, dict):
            errors.append(f"{prefix} must be an object")
            continue
        experiment_id = experiment.get("id")
        if not isinstance(experiment_id, str) or not experiment_id or experiment_id in experiment_ids:
            errors.append(f"{prefix}.id must be non-empty and unique")
        else:
            experiment_ids.add(experiment_id)
        status = experiment.get("status")
        if not isinstance(status, str) or status not in RESULT_LABELS:
            errors.append(f"{prefix}.status is not an allowed result label")
        minimum = experiment.get("minimum_executions_per_treatment")
        if isinstance(minimum, bool) or not isinstance(minimum, int) or minimum < 3:
            errors.append(f"{prefix}.minimum_executions_per_treatment must be at least 3")
        for field in ("hypothesis", "primary_metric", "variable"):
            value = experiment.get(field)
            if not isinstance(value, str) or not value:
                errors.append(f"{prefix}.{field} must be a non-empty string")
        primary_metric = experiment.get("primary_metric")
        if not isinstance(primary_metric, str) or primary_metric not in RATE_METRICS:
            errors.append(f"{prefix}.primary_metric is unsupported")
        secondary_metric = experiment.get("secondary_metric")
        if (
            not isinstance(secondary_metric, str)
            or secondary_metric not in RATE_METRICS
            or secondary_metric == primary_metric
        ):
            errors.append(f"{prefix}.secondary_metric is unsupported or duplicates primary_metric")
        treatments = experiment.get("treatments")
        if (
            not isinstance(treatments, list)
            or len(treatments) < 2
            or any(not isinstance(item, str) or not item for item in treatments)
            or len(set(treatments)) != len(treatments)
        ):
            errors.append(f"{prefix}.treatments must contain at least two unique non-empty names")
        elif isinstance(experiment_id, str) and experiment_id:
            experiment_treatments[experiment_id] = set(treatments)

    observation_ids: set[str] = set()
    content_checkpoints: set[tuple[str, str]] = set()
    content_invariants: dict[str, dict[str, Any]] = {}
    for index, observation in enumerate(collections["social_observations"]):
        prefix = f"social_observations[{index}]"
        if not isinstance(observation, dict):
            errors.append(f"{prefix} must be an object")
            continue
        observation_id = observation.get("observation_id")
        if not isinstance(observation_id, str) or not observation_id or observation_id in observation_ids:
            errors.append(f"{prefix}.observation_id must be non-empty and unique")
        else:
            observation_ids.add(observation_id)
        if observation.get("identity") != "BookQuotes":
            errors.append(f"{prefix}.identity must be BookQuotes")
        for field in ("platform", "title", "format"):
            value = observation.get(field)
            if not isinstance(value, str) or not value:
                errors.append(f"{prefix}.{field} must be a non-empty string")
        content_id = observation.get("content_id")
        if content_id is not None and (not isinstance(content_id, str) or not content_id):
            errors.append(f"{prefix}.content_id must be null or a non-empty string")
        status = observation.get("status")
        if not isinstance(status, str) or status not in SOCIAL_STATUSES:
            errors.append(f"{prefix}.status is invalid")
        if status in ("scheduled", "published") and not observation.get("rights_basis"):
            errors.append(f"{prefix}.rights_basis is required for scheduled/published content")
        checkpoint = observation.get("checkpoint")
        if not isinstance(checkpoint, str) or checkpoint not in CHECKPOINTS:
            errors.append(f"{prefix}.checkpoint is invalid")
        elif isinstance(status, str) and checkpoint not in STATUS_CHECKPOINTS.get(status, set()):
            errors.append(f"{prefix}.checkpoint contradicts status {status}")
        published_at: datetime | None = None
        observed_at: datetime | None = None
        try:
            published_at = parse_timestamp(observation.get("published_at"), f"{prefix}.published_at")
        except ValueError as error:
            errors.append(str(error))
        try:
            observed_at = parse_timestamp(observation.get("observed_at"), f"{prefix}.observed_at")
        except ValueError as error:
            errors.append(str(error))
        if updated_at and observed_at and observed_at > updated_at:
            errors.append(f"{prefix}.observed_at cannot be after updated_at")
        if status in ("published", "stopped") and published_at and observed_at:
            if observed_at < published_at:
                errors.append(f"{prefix}.observed_at cannot precede published_at")
            minimum_age = CHECKPOINT_MIN_AGE.get(checkpoint) if isinstance(checkpoint, str) else None
            if minimum_age and observed_at - published_at < minimum_age:
                label = "7d" if checkpoint in {"7d", "7d-audit"} else checkpoint
                errors.append(f"{prefix}.{label} checkpoint was observed too early")
        experiment_id = observation.get("experiment_id")
        if experiment_id is not None and not isinstance(experiment_id, str):
            errors.append(f"{prefix}.experiment_id must be null or a string")
            experiment_id = None
        elif experiment_id is not None and experiment_id not in experiment_ids:
            errors.append(f"{prefix}.experiment_id references unknown experiment {experiment_id}")
        treatment = observation.get("treatment")
        if experiment_id is not None and (not isinstance(treatment, str) or not treatment):
            errors.append(f"{prefix}.treatment is required for experiment observations")
        if experiment_id in experiment_treatments and (
            not isinstance(treatment, str) or treatment not in experiment_treatments[experiment_id]
        ):
            errors.append(f"{prefix}.treatment must be one of the experiment's declared treatments")
        if status in ("scheduled", "published") and not observation.get("content_id"):
            errors.append(f"{prefix}.content_id is required for scheduled/published observations")
        stable_content_id = observation.get("content_id")
        if isinstance(stable_content_id, str) and stable_content_id:
            signature = {field: observation.get(field) for field in CONTENT_INVARIANT_FIELDS}
            baseline = content_invariants.get(stable_content_id)
            if baseline is None:
                content_invariants[stable_content_id] = signature
            else:
                changed = [
                    field
                    for field in CONTENT_INVARIANT_FIELDS
                    if baseline.get(field) != signature.get(field)
                ]
                if changed:
                    errors.append(
                        f"{prefix}.content_id invariant changed for {stable_content_id}: {', '.join(changed)}"
                    )
        content_key = observation.get("content_id") or observation_id
        if content_key:
            checkpoint_key = (str(content_key), str(observation.get("checkpoint")))
            if checkpoint_key in content_checkpoints:
                errors.append(f"{prefix} duplicates content/checkpoint {checkpoint_key}")
            content_checkpoints.add(checkpoint_key)
        metrics = observation.get("metrics")
        if not isinstance(metrics, dict):
            errors.append(f"{prefix}.metrics must be an object")
            continue
        missing = REQUIRED_METRICS - set(metrics)
        if missing:
            errors.append(f"{prefix}.metrics missing: {', '.join(sorted(missing))}")
        for metric, value in metrics.items():
            if value is not None and (
                isinstance(value, bool)
                or not isinstance(value, (int, float))
                or not math.isfinite(value)
                or value < 0
            ):
                errors.append(f"{prefix}.metrics.{metric} must be null or a finite non-negative number")
        if status == "published" and any(metrics.get(metric) is None for metric in REQUIRED_METRICS):
            reason = observation.get("metrics_unavailable_reason")
            if not isinstance(reason, str) or not reason:
                errors.append(
                    f"{prefix}.metrics_unavailable_reason is required when published metrics are unavailable"
                )

    for index, snapshot in enumerate(collections["search_snapshots"]):
        prefix = f"search_snapshots[{index}]"
        if not isinstance(snapshot, dict):
            errors.append(f"{prefix} must be an object")
            continue
        snapshot_observed_at: datetime | None = None
        try:
            snapshot_observed_at = parse_timestamp(snapshot.get("observed_at"), f"{prefix}.observed_at")
        except ValueError as error:
            errors.append(str(error))
        if updated_at and snapshot_observed_at and snapshot_observed_at > updated_at:
            errors.append(f"{prefix}.observed_at cannot be after updated_at")
        if snapshot.get("property") != "bookquotes.uk":
            errors.append(f"{prefix}.property must be bookquotes.uk")
        if snapshot.get("sitemap_url") != "https://bookquotes.uk/sitemap.xml":
            errors.append(f"{prefix}.sitemap_url must use the canonical sitemap")
        sitemap_status = snapshot.get("sitemap_status")
        if not isinstance(sitemap_status, str) or not sitemap_status:
            errors.append(f"{prefix}.sitemap_status must be a non-empty string")
        discovered_pages = snapshot.get("discovered_pages")
        if (
            isinstance(discovered_pages, bool)
            or not isinstance(discovered_pages, int)
            or discovered_pages < 0
        ):
            errors.append(f"{prefix}.discovered_pages must be a non-negative integer")

    for index, experiment in enumerate(experiments):
        if not isinstance(experiment, dict):
            continue
        result_status = experiment.get("status")
        if not isinstance(result_status, str) or result_status not in COMPARISON_RESULT_LABELS:
            continue
        valid_observations = [
            observation
            for observation in collections["social_observations"]
            if isinstance(observation, dict)
        ]
        _, ready = comparison_state(experiment, valid_observations)
        if not ready:
            errors.append(
                f"experiments[{index}].status {experiment['status']} requires comparison-ready evidence"
            )

    if errors:
        raise ValueError("Evidence validation failed:\n- " + "\n- ".join(errors))


def display(value: Any) -> str:
    return "Not available" if value is None else str(value)


def rate(count: float | int | None, denominator: float | int | None) -> str:
    if count is None or denominator in (None, 0):
        return "Not available"
    return f"{(float(count) / float(denominator)) * 1000:.1f}"


def experiment_metric_value(observation: dict[str, Any], metric_name: str) -> float | None:
    numerator_name, denominator_name, _ = RATE_METRICS[metric_name]
    metrics = observation["metrics"]
    numerator = metrics.get(numerator_name)
    denominator = metrics.get(denominator_name)
    if numerator is None or denominator in (None, 0):
        return None
    return (float(numerator) / float(denominator)) * 1000


def render(data: dict[str, Any]) -> str:
    observations = data.get("social_observations", [])
    latest_by_content = latest_content_observations(observations)

    totals = Counter()
    for observation in latest_by_content.values():
        if observation["status"] != "published":
            continue
        for metric, value in observation["metrics"].items():
            if value is not None:
                totals[metric] += value


    lines = [
        "# BookQuotes Growth Scorecard",
        "",
        f"Generated from structured evidence updated `{data['updated_at']}`.",
        "",
        "## Current signal",
        "",
        f"- Published Facebook items represented: {sum(1 for item in latest_by_content.values() if item['platform'] == 'facebook' and item['status'] == 'published')}",
        f"- Visible views: {totals['views']}",
        f"- Visible reach: {totals['reach']}",
        f"- Meaningful interactions: {totals['comments'] + totals['shares'] + totals['saves']}",
        f"- Link clicks: {totals['link_clicks']}",
        "- Interpretation: distribution is too small for a creative or timing winner. Continue controlled instrumentation; do not increase volume.",
        "",
        "## Latest social observations",
        "",
        "| Date | Status | Platform | Content | Format | Checkpoint | Views | Reach | Saves/1k reach | Comments/1k reach | Decision |",
        "| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: | --- |",
    ]
    for observation in sorted(observations, key=lambda item: item["published_at"], reverse=True):
        metrics = observation["metrics"]
        if observation["status"] in {"draft", "scheduled"}:
            decision = "Awaiting publication/read-back"
        else:
            decision = (
                "Insufficient distribution"
                if (metrics.get("reach") or 0) < 20
                else "Review against declared experiment"
            )
        lines.append(
            "| {date} | {status} | {platform} | {title} | {format} | {checkpoint} | {views} | {reach} | {saves} | {comments} | {decision} |".format(
                date=observation["published_at"][:10],
                status=observation["status"],
                platform=observation["platform"],
                title=observation["title"].replace("|", "\\|"),
                format=observation["format"],
                checkpoint=observation["checkpoint"],
                views=display(observation["metrics"].get("views")),
                reach=display(observation["metrics"].get("reach")),
                saves=rate(metrics.get("saves"), metrics.get("reach")),
                comments=rate(metrics.get("comments"), metrics.get("reach")),
                decision=decision,
            )
        )

    lines.extend(["", "## Experiment readiness", ""])
    for experiment in data.get("experiments", []):
        treatments, ready = comparison_state(experiment, observations)
        counts = {name: len(items) for name, items in treatments.items()}
        minimum = experiment["minimum_executions_per_treatment"]
        primary_metric = experiment["primary_metric"]
        metric_values = {
            name: [experiment_metric_value(item, primary_metric) for item in items]
            for name, items in treatments.items()
        }

        lines.extend(
            [
                f"### {experiment['id']}: {experiment['status']}",
                "",
                experiment["hypothesis"],
                "",
                f"- Primary metric: `{experiment['primary_metric']}`",
                f"- Executions by treatment: {json.dumps(counts, sort_keys=True) if counts else 'none'}",
                f"- Minimum per treatment: {minimum}",
                f"- Comparison ready: {'yes' if ready else 'no'}",
                "",
            ]
        )
        if ready:
            _, _, metric_label = RATE_METRICS[primary_metric]
            for treatment, values in sorted(metric_values.items()):
                numeric_values = [value for value in values if value is not None]
                median = statistics.median(numeric_values)
                lines.append(f"- {treatment} median {metric_label}: {median:.1f}")
            lines.append("")

    lines.extend(["## Search state", ""])
    for snapshot in sorted(data.get("search_snapshots", []), key=lambda item: item["observed_at"], reverse=True):
        lines.extend(
            [
                f"- {snapshot['observed_at'][:10]}: sitemap `{snapshot['sitemap_status']}`, {snapshot['discovered_pages']} pages discovered; homepage indexed={display(snapshot.get('indexed_homepage'))}; request `{snapshot.get('indexing_request_status', 'Not available')}`; performance `{snapshot.get('performance_status', display(snapshot.get('performance_available')))}`.",
            ]
        )

    lines.extend(
        [
            "",
            "## Next controlled actions",
            "",
            "1. Record the 24-hour and 72-hour checkpoints for `Find the line` without interpreting an initial zero as failure.",
            "2. Execute FB-001 only with a rights-safe original treatment and a declared comparable product baseline.",
            "3. Verify homepage indexing and Search Console performance when the inspection surface is available; do not duplicate-submit the sitemap.",
            "4. Promote recurring reader language into a search brief only after three independent occurrences.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("evidence", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    data = load(args.evidence)
    validate(data)
    report = render(data)
    if args.output:
        args.output.write_text(report, encoding="utf-8")
        print(f"validated {len(data.get('social_observations', []))} social observations and wrote {args.output}")
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
