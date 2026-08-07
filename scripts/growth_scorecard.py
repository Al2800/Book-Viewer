#!/usr/bin/env python3
"""Validate BookQuotes growth evidence and render a deterministic scorecard."""

from __future__ import annotations

import argparse
import json
import statistics
from collections import Counter, defaultdict
from datetime import datetime
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


def load(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if data.get("schema_version") != 1:
        raise ValueError("schema_version must be 1")
    return data


def parse_timestamp(value: str, field: str) -> None:
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ValueError(f"{field} is not an ISO-8601 timestamp: {value}") from error


def validate(data: dict[str, Any]) -> None:
    errors: list[str] = []
    experiments = data.get("experiments", [])
    experiment_ids: set[str] = set()
    for index, experiment in enumerate(experiments):
        prefix = f"experiments[{index}]"
        experiment_id = experiment.get("id")
        if not experiment_id or experiment_id in experiment_ids:
            errors.append(f"{prefix}.id must be non-empty and unique")
        else:
            experiment_ids.add(experiment_id)
        if experiment.get("status") not in RESULT_LABELS:
            errors.append(f"{prefix}.status is not an allowed result label")
        if int(experiment.get("minimum_executions_per_treatment", 0)) < 3:
            errors.append(f"{prefix}.minimum_executions_per_treatment must be at least 3")
        for field in ("hypothesis", "primary_metric", "variable"):
            if not experiment.get(field):
                errors.append(f"{prefix}.{field} is required")

    observation_ids: set[str] = set()
    content_checkpoints: set[tuple[str, str]] = set()
    for index, observation in enumerate(data.get("social_observations", [])):
        prefix = f"social_observations[{index}]"
        observation_id = observation.get("observation_id")
        if not observation_id or observation_id in observation_ids:
            errors.append(f"{prefix}.observation_id must be non-empty and unique")
        else:
            observation_ids.add(observation_id)
        if observation.get("identity") != "BookQuotes":
            errors.append(f"{prefix}.identity must be BookQuotes")
        if observation.get("status") not in SOCIAL_STATUSES:
            errors.append(f"{prefix}.status is invalid")
        if observation.get("status") in {"scheduled", "published"} and not observation.get("rights_basis"):
            errors.append(f"{prefix}.rights_basis is required for scheduled/published content")
        try:
            parse_timestamp(observation["published_at"], f"{prefix}.published_at")
        except (KeyError, ValueError) as error:
            errors.append(str(error))
        experiment_id = observation.get("experiment_id")
        if experiment_id is not None and experiment_id not in experiment_ids:
            errors.append(f"{prefix}.experiment_id references unknown experiment {experiment_id}")
        if experiment_id is not None and not observation.get("treatment"):
            errors.append(f"{prefix}.treatment is required for experiment observations")
        content_key = observation.get("content_id") or observation_id.rsplit("-", 1)[0]
        checkpoint_key = (str(content_key), str(observation.get("checkpoint")))
        if checkpoint_key in content_checkpoints:
            errors.append(f"{prefix} duplicates content/checkpoint {checkpoint_key}")
        content_checkpoints.add(checkpoint_key)
        metrics = observation.get("metrics", {})
        missing = REQUIRED_METRICS - set(metrics)
        if missing:
            errors.append(f"{prefix}.metrics missing: {', '.join(sorted(missing))}")
        for metric, value in metrics.items():
            if value is not None and (not isinstance(value, (int, float)) or value < 0):
                errors.append(f"{prefix}.metrics.{metric} must be null or a non-negative number")

    for index, snapshot in enumerate(data.get("search_snapshots", [])):
        prefix = f"search_snapshots[{index}]"
        try:
            parse_timestamp(snapshot["observed_at"], f"{prefix}.observed_at")
        except (KeyError, ValueError) as error:
            errors.append(str(error))
        if snapshot.get("property") != "bookquotes.uk":
            errors.append(f"{prefix}.property must be bookquotes.uk")
        if snapshot.get("sitemap_url") != "https://bookquotes.uk/sitemap.xml":
            errors.append(f"{prefix}.sitemap_url must use the canonical sitemap")

    if errors:
        raise ValueError("Evidence validation failed:\n- " + "\n- ".join(errors))


def display(value: Any) -> str:
    return "Not available" if value is None else str(value)


def rate(count: float | int | None, denominator: float | int | None) -> str:
    if count is None or denominator in (None, 0):
        return "Not available"
    return f"{(float(count) / float(denominator)) * 1000:.1f}"


def render(data: dict[str, Any]) -> str:
    observations = data.get("social_observations", [])
    latest_by_content: dict[str, dict[str, Any]] = {}
    for observation in observations:
        key = observation.get("content_id") or observation["observation_id"].split("-audit")[0]
        current = latest_by_content.get(str(key))
        if current is None or observation["published_at"] >= current["published_at"]:
            latest_by_content[str(key)] = observation

    totals = Counter()
    for observation in latest_by_content.values():
        if observation["status"] != "published":
            continue
        for metric, value in observation["metrics"].items():
            if value is not None:
                totals[metric] += value

    by_experiment: dict[str, dict[str, list[dict[str, Any]]]] = defaultdict(lambda: defaultdict(list))
    for observation in observations:
        if observation.get("experiment_id") and observation.get("status") == "published":
            by_experiment[observation["experiment_id"]][observation["treatment"]].append(observation)

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
        treatments = by_experiment.get(experiment["id"], {})
        counts = {name: len(items) for name, items in treatments.items()}
        minimum = experiment["minimum_executions_per_treatment"]
        ready = bool(counts) and all(value >= minimum for value in counts.values()) and len(counts) >= 2
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
            for treatment, items in sorted(treatments.items()):
                values = [item["metrics"].get("saves") for item in items if item["metrics"].get("saves") is not None]
                lines.append(f"- {treatment} median saves: {statistics.median(values) if values else 'Not available'}")
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
