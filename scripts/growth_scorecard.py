#!/usr/bin/env python3
"""Validate BookQuotes growth evidence and render a deterministic scorecard."""

from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
from collections import Counter
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlsplit

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
APP_STORE_SURFACES = {"metadata", "analytics", "sales", "finance"}
APP_STORE_OUTCOME_METRICS = {
    "downloads",
    "first_time_downloads",
    "sales",
    "proceeds",
}
AUTHORITATIVE_APP_STORE_SOURCES = {
    "downloads": {"app_store_connect_analytics", "app_store_connect_sales"},
    "first_time_downloads": {"app_store_connect_analytics", "app_store_connect_sales"},
    "sales": {"app_store_connect_sales"},
    "proceeds": {"app_store_connect_finance", "app_store_connect_sales"},
}
UTM_PARAMETERS = ["utm_source", "utm_medium", "utm_campaign", "utm_content"]


def is_bookquotes_app_store_url(value: str) -> bool:
    parsed = urlsplit(value)
    return (
        parsed.scheme == "https"
        and parsed.netloc == "apps.apple.com"
        and parsed.path == "/app/id6758091579"
        and not parsed.fragment
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
    for name in ("experiments", "social_observations", "search_snapshots", "app_store_snapshots"):
        value = data.get(name)
        if not isinstance(value, list) or not value:
            errors.append(f"{name} must be a non-empty list")
            collections[name] = []
        else:
            collections[name] = value

    experiments = collections["experiments"]

    attribution = data.get("attribution")
    if not isinstance(attribution, dict):
        errors.append("attribution must be an object")
        attribution = {}
    if attribution.get("canonical_website_origin") != "https://bookquotes.uk":
        errors.append("attribution.canonical_website_origin must be https://bookquotes.uk")
    if attribution.get("canonical_app_store_url") != "https://apps.apple.com/app/id6758091579":
        errors.append("attribution.canonical_app_store_url must identify BookQuotes")
    if attribution.get("utm_parameters") != UTM_PARAMETERS:
        errors.append("attribution.utm_parameters must use the canonical ordered UTM parameters")
    conventions = attribution.get("channel_conventions")
    seen_channels: set[str] = set()
    channel_sources: dict[str, str] = {}
    channel_media: dict[str, str] = {}
    channel_campaign_templates: dict[str, str] = {}
    channel_content_templates: dict[str, str] = {}
    if not isinstance(conventions, list) or not conventions:
        errors.append("attribution.channel_conventions must be a non-empty list")
    else:
        seen_sources: set[str] = set()
        for index, convention in enumerate(conventions):
            prefix = f"attribution.channel_conventions[{index}]"
            if not isinstance(convention, dict):
                errors.append(f"{prefix} must be an object")
                continue
            channel = convention.get("channel")
            source = convention.get("utm_source")
            medium = convention.get("utm_medium")
            if not isinstance(channel, str) or not channel or channel in seen_channels:
                errors.append(f"{prefix}.channel must be non-empty and unique")
            else:
                seen_channels.add(channel)
            if not isinstance(source, str) or not source or source in seen_sources:
                errors.append(f"{prefix}.utm_source must be non-empty and unique")
            else:
                seen_sources.add(source)
            if isinstance(channel, str) and channel and isinstance(source, str) and source:
                channel_sources[channel] = source
            if not isinstance(medium, str) or not medium:
                errors.append(f"{prefix}.utm_medium must be non-empty")
            elif isinstance(channel, str) and channel:
                channel_media[channel] = medium
            for field in ("utm_campaign_template", "utm_content_template"):
                if not isinstance(convention.get(field), str) or not convention.get(field):
                    errors.append(f"{prefix}.{field} must be non-empty")
            campaign_template = convention.get("utm_campaign_template")
            content_template = convention.get("utm_content_template")
            if isinstance(campaign_template, str) and not all(
                placeholder in campaign_template for placeholder in ("{experiment_id}", "{yyyy_mm}")
            ):
                errors.append(
                    f"{prefix}.utm_campaign_template must bind experiment_id and yyyy_mm"
                )
            if isinstance(content_template, str) and (
                "{treatment}" not in content_template
                or not any(
                    placeholder in content_template
                    for placeholder in ("{content_id}", "{landing_page_slug}", "{cta_location}")
                )
            ):
                errors.append(
                    f"{prefix}.utm_content_template must bind treatment and a durable content identifier"
                )
            if isinstance(channel, str) and channel:
                if isinstance(campaign_template, str) and campaign_template:
                    channel_campaign_templates[channel] = campaign_template
                if isinstance(content_template, str) and content_template:
                    channel_content_templates[channel] = content_template
    metrics = attribution.get("weekly_metrics")
    if not isinstance(metrics, dict):
        errors.append("attribution.weekly_metrics must be an object")
    else:
        if metrics.get("primary") != "first_time_downloads":
            errors.append("attribution.weekly_metrics.primary must be first_time_downloads")
        secondary = metrics.get("secondary")
        if (
            not isinstance(secondary, list)
            or not secondary
            or any(not isinstance(item, str) or not item for item in secondary)
            or len(set(secondary)) != len(secondary)
            or "first_time_downloads" in secondary
        ):
            errors.append("attribution.weekly_metrics.secondary must contain unique non-primary metrics")
    if attribution.get("reporting_window_days") != 7:
        errors.append("attribution.reporting_window_days must be 7")
    checkpoints = attribution.get("checkpoints")
    if not isinstance(checkpoints, dict):
        errors.append("attribution.checkpoints must be an object")
    else:
        if checkpoints.get("baseline") != "7d_pre_experiment":
            errors.append("attribution.checkpoints.baseline must be 7d_pre_experiment")
        if checkpoints.get("reviews") != ["24h", "72h", "7d"]:
            errors.append("attribution.checkpoints.reviews must be 24h, 72h and 7d")
    activation = attribution.get("activation_definition")
    if not isinstance(activation, str) or not activation:
        errors.append("attribution.activation_definition must be a non-empty string")
    campaign_links = attribution.get("app_store_campaign_links")
    verified_app_store_campaign_ids: set[str] = set()
    verified_app_store_campaign_channels: dict[str, str] = {}
    if not isinstance(campaign_links, dict):
        errors.append("attribution.app_store_campaign_links must be an object")
    else:
        campaign_links_available = campaign_links.get("available")
        campaign_links_value = campaign_links.get("value")
        if not isinstance(campaign_links_available, bool):
            errors.append("attribution.app_store_campaign_links.available must be boolean")
        elif campaign_links_available is False:
            if campaign_links_value is not None:
                errors.append("unavailable App Store campaign links must have value null")
            if not campaign_links.get("reason") or not campaign_links.get("next_action"):
                errors.append("unavailable App Store campaign links require reason and next_action")
        elif (
            not isinstance(campaign_links_value, list)
            or not campaign_links_value
            or any(not isinstance(item, dict) for item in campaign_links_value)
        ):
            errors.append("available App Store campaign links must contain a non-empty list of records")
        else:
            campaign_ids: set[str] = set()
            for index, record in enumerate(campaign_links_value):
                record_prefix = f"attribution.app_store_campaign_links.value[{index}]"
                for field in ("channel", "campaign_id", "url"):
                    if not isinstance(record.get(field), str) or not record.get(field):
                        errors.append(f"{record_prefix}.{field} must be non-empty")
                channel = record.get("channel")
                if isinstance(channel, str) and channel not in seen_channels:
                    errors.append(f"{record_prefix}.channel must use a declared channel convention")
                campaign_id = record.get("campaign_id")
                if isinstance(campaign_id, str):
                    if campaign_id in campaign_ids:
                        errors.append(f"{record_prefix}.campaign_id must be unique")
                    campaign_ids.add(campaign_id)
                    verified_app_store_campaign_ids.add(campaign_id)
                    if isinstance(channel, str):
                        verified_app_store_campaign_channels[campaign_id] = channel
                url = record.get("url")
                if isinstance(url, str) and not is_bookquotes_app_store_url(url):
                    errors.append(f"{record_prefix}.url must be the BookQuotes App Store URL")
                elif isinstance(url, str) and parse_qs(urlsplit(url).query).get("ct") != [campaign_id]:
                    errors.append(f"{record_prefix}.url ct parameter must equal campaign_id")
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
        platform = observation.get("platform")
        if isinstance(platform, str) and platform not in channel_sources:
            errors.append(f"{prefix}.platform must have a declared channel convention")
        campaign = observation.get("campaign")
        if campaign is not None:
            if not isinstance(campaign, dict):
                errors.append(f"{prefix}.campaign must be null or an object")
            else:
                campaign_fields = (
                    "campaign_id",
                    "destination_url",
                    "utm_source",
                    "utm_medium",
                    "utm_campaign",
                    "utm_content",
                )
                for field in campaign_fields:
                    if not isinstance(campaign.get(field), str) or not campaign.get(field):
                        errors.append(f"{prefix}.campaign.{field} must be non-empty")
                expected_source = channel_sources.get(platform) if isinstance(platform, str) else None
                expected_medium = channel_media.get(platform) if isinstance(platform, str) else None
                if expected_source and campaign.get("utm_source") != expected_source:
                    errors.append(f"{prefix}.campaign.utm_source must match the platform convention")
                if expected_medium and campaign.get("utm_medium") != expected_medium:
                    errors.append(f"{prefix}.campaign.utm_medium must match the platform convention")
                if campaign.get("campaign_id") != campaign.get("utm_campaign"):
                    errors.append(f"{prefix}.campaign.campaign_id must equal utm_campaign")
                experiment_id = observation.get("experiment_id")
                treatment = observation.get("treatment")
                content_id_for_campaign = observation.get("content_id")
                published_at_for_campaign = observation.get("published_at")
                if not isinstance(experiment_id, str) or not experiment_id:
                    errors.append(f"{prefix}.campaign requires a declared experiment_id")
                if not isinstance(treatment, str) or not treatment:
                    errors.append(f"{prefix}.campaign requires a declared treatment")
                if not isinstance(content_id_for_campaign, str) or not content_id_for_campaign:
                    errors.append(f"{prefix}.campaign requires a durable content_id")
                if isinstance(platform, str):
                    campaign_template = channel_campaign_templates.get(platform)
                    content_template = channel_content_templates.get(platform)
                    if (
                        campaign_template
                        and isinstance(experiment_id, str)
                        and isinstance(published_at_for_campaign, str)
                        and len(published_at_for_campaign) >= 7
                    ):
                        expected_campaign = campaign_template.replace(
                            "{experiment_id}", experiment_id.lower()
                        ).replace("{yyyy_mm}", published_at_for_campaign[:7])
                        if campaign.get("campaign_id") != expected_campaign:
                            errors.append(
                                f"{prefix}.campaign.campaign_id must match the channel experiment template"
                            )
                    if (
                        content_template
                        and isinstance(content_id_for_campaign, str)
                        and isinstance(treatment, str)
                    ):
                        expected_content = content_template.replace(
                            "{content_id}", content_id_for_campaign
                        ).replace("{treatment}", treatment)
                        if campaign.get("utm_content") != expected_content:
                            errors.append(
                                f"{prefix}.campaign.utm_content must match the channel content template"
                            )
                destination = campaign.get("destination_url")
                store_campaign_id = campaign.get("app_store_campaign_id")
                if store_campaign_id is not None:
                    if not isinstance(store_campaign_id, str) or not store_campaign_id:
                        errors.append(f"{prefix}.campaign.app_store_campaign_id must be null or non-empty")
                    elif store_campaign_id not in verified_app_store_campaign_ids:
                        errors.append(f"{prefix}.campaign.app_store_campaign_id is not verified")
                    elif verified_app_store_campaign_channels.get(store_campaign_id) != platform:
                        errors.append(
                            f"{prefix}.campaign.app_store_campaign_id must match the platform channel"
                        )
                    if isinstance(destination, str) and not is_bookquotes_app_store_url(destination):
                        errors.append(f"{prefix}.campaign.destination_url must identify BookQuotes in the App Store")
                    elif isinstance(destination, str) and (
                        parse_qs(urlsplit(destination).query).get("ct") != [store_campaign_id]
                    ):
                        errors.append(
                            f"{prefix}.campaign.destination_url ct parameter must equal app_store_campaign_id"
                        )
                elif isinstance(destination, str):
                    parsed_destination = urlsplit(destination)
                    if not (
                        parsed_destination.scheme == "https"
                        and parsed_destination.netloc == "bookquotes.uk"
                        and not parsed_destination.fragment
                    ):
                        errors.append(f"{prefix}.campaign.destination_url must use the canonical website")
                    query = parse_qs(parsed_destination.query, keep_blank_values=True)
                    for parameter in UTM_PARAMETERS:
                        expected = campaign.get(parameter)
                        if query.get(parameter) != [expected]:
                            errors.append(
                                f"{prefix}.campaign.destination_url must contain the declared {parameter}"
                            )
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

    for index, snapshot in enumerate(collections["app_store_snapshots"]):
        prefix = f"app_store_snapshots[{index}]"
        if not isinstance(snapshot, dict):
            errors.append(f"{prefix} must be an object")
            continue
        try:
            snapshot_at = parse_timestamp(snapshot.get("observed_at"), f"{prefix}.observed_at")
        except ValueError as error:
            errors.append(str(error))
            snapshot_at = None
        if updated_at and snapshot_at and snapshot_at > updated_at:
            errors.append(f"{prefix}.observed_at cannot be after updated_at")
        if snapshot.get("app_id") != "6758091579":
            errors.append(f"{prefix}.app_id must identify BookQuotes")
        if snapshot.get("source") != "app_store_connect_api_read_only":
            errors.append(f"{prefix}.source must be app_store_connect_api_read_only")
        if not isinstance(snapshot.get("live_version"), str) or not snapshot.get("live_version"):
            errors.append(f"{prefix}.live_version must be non-empty")
        if not isinstance(snapshot.get("live_state"), str) or not snapshot.get("live_state"):
            errors.append(f"{prefix}.live_state must be non-empty")
        if not isinstance(snapshot.get("downloadable"), bool):
            errors.append(f"{prefix}.downloadable must be boolean")
        access = snapshot.get("access")
        if not isinstance(access, dict) or set(access) != APP_STORE_SURFACES:
            errors.append(f"{prefix}.access must separately contain metadata, analytics, sales and finance")
        else:
            for surface in sorted(APP_STORE_SURFACES):
                state = access[surface]
                state_prefix = f"{prefix}.access.{surface}"
                if not isinstance(state, dict):
                    errors.append(f"{state_prefix} must be an object")
                    continue
                available = state.get("available")
                status = state.get("http_status")
                if not isinstance(available, bool):
                    errors.append(f"{state_prefix}.available must be boolean")
                if isinstance(status, bool) or not isinstance(status, int) or status < 0:
                    errors.append(f"{state_prefix}.http_status must be a non-negative integer")
                if available is True and isinstance(status, int) and not 200 <= status < 300:
                    errors.append(f"{state_prefix}.available true requires a 2xx HTTP status")
                if available is False and (not state.get("reason") or not state.get("next_action")):
                    errors.append(f"{state_prefix} requires reason and next_action when unavailable")
        outcomes = snapshot.get("outcomes")
        if not isinstance(outcomes, dict) or set(outcomes) != APP_STORE_OUTCOME_METRICS:
            errors.append(f"{prefix}.outcomes must contain downloads, first_time_downloads, sales and proceeds")
        else:
            for metric in sorted(APP_STORE_OUTCOME_METRICS):
                record = outcomes[metric]
                metric_prefix = f"{prefix}.outcomes.{metric}"
                if not isinstance(record, dict):
                    errors.append(f"{metric_prefix} must be an object")
                    continue
                available = record.get("available")
                value = record.get("value")
                if not isinstance(available, bool):
                    errors.append(f"{metric_prefix}.available must be boolean")
                if value is not None and (
                    isinstance(value, bool)
                    or not isinstance(value, (int, float))
                    or not math.isfinite(value)
                    or value < 0
                ):
                    errors.append(f"{metric_prefix}.value must be null or a finite non-negative number")
                if available is False:
                    if value is not None:
                        errors.append(f"{metric_prefix}.value must be null when unavailable")
                    if "source" not in record or record.get("source") is not None:
                        errors.append(f"{metric_prefix}.source must be explicitly null when unavailable")
                    if metric == "proceeds" and (
                        "currency" not in record or record.get("currency") is not None
                    ):
                        errors.append(
                            f"{metric_prefix}.currency must be explicitly null when unavailable"
                        )
                    if not record.get("reason") or not record.get("next_action"):
                        errors.append(f"{metric_prefix} requires reason and next_action when unavailable")
                elif value is None:
                    errors.append(f"{metric_prefix}.value is required when available")
                if available is True and record.get("source") not in AUTHORITATIVE_APP_STORE_SOURCES[metric]:
                    errors.append(f"{metric_prefix}.source is not authoritative for {metric}")
                if available is True and isinstance(access, dict) and set(access) == APP_STORE_SURFACES:
                    source = record.get("source")
                    source_surface = {
                        "app_store_connect_analytics": "analytics",
                        "app_store_connect_sales": "sales",
                        "app_store_connect_finance": "finance",
                    }.get(source) if isinstance(source, str) else None
                    if source_surface:
                        source_access = access.get(source_surface)
                        if not isinstance(source_access, dict) or source_access.get("available") is not True:
                            errors.append(
                                f"{metric_prefix}.source requires available {source_surface} access"
                            )
                if metric == "proceeds" and available is True:
                    currency = record.get("currency")
                    if not isinstance(currency, str) or len(currency) != 3:
                        errors.append(f"{metric_prefix}.currency must be a three-letter code when available")

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


def attribution_quality(
    observation: dict[str, Any], verified_app_store_campaign_ids: set[str]
) -> str:
    campaign = observation.get("campaign")
    if not isinstance(campaign, dict):
        return "channel_only"
    required = ("campaign_id", "destination_url", "utm_source", "utm_medium", "utm_campaign", "utm_content")
    if not all(isinstance(campaign.get(field), str) and campaign.get(field) for field in required):
        return "channel_only"
    if campaign.get("app_store_campaign_id") in verified_app_store_campaign_ids:
        return "store_campaign_linked"
    return "website_campaign_linked"


def render(data: dict[str, Any]) -> str:
    observations = data.get("social_observations", [])
    latest_by_content = latest_content_observations(observations)
    report_end = parse_timestamp(data["updated_at"], "updated_at")
    report_start = report_end - timedelta(days=data["attribution"]["reporting_window_days"])
    weekly_latest = {
        content_id: observation
        for content_id, observation in latest_by_content.items()
        if parse_timestamp(observation["published_at"], "published_at") >= report_start
    }

    totals = Counter()
    for observation in weekly_latest.values():
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
        f"- Reporting window: {report_start.isoformat()} to {report_end.isoformat()}",
        f"- Published Facebook items represented: {sum(1 for item in weekly_latest.values() if item['platform'] == 'facebook' and item['status'] == 'published')}",
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

    published_latest = [item for item in weekly_latest.values() if item.get("status") == "published"]
    campaign_link_state = data["attribution"]["app_store_campaign_links"]
    verified_ids = {
        item["campaign_id"]
        for item in (campaign_link_state.get("value") or [])
        if campaign_link_state.get("available") is True
    }
    attribution_counts = Counter(
        attribution_quality(item, verified_ids) for item in published_latest
    )
    lines.extend(
        [
            "## Weekly funnel and attribution",
            "",
            f"- Baseline window: `{data['attribution']['checkpoints']['baseline']}`",
            f"- Review checkpoints: `{', '.join(data['attribution']['checkpoints']['reviews'])}`",
            f"- Primary weekly metric: `{data['attribution']['weekly_metrics']['primary']}`",
            f"- Secondary weekly metrics: `{', '.join(data['attribution']['weekly_metrics']['secondary'])}`",
            f"- Activation: {data['attribution']['activation_definition']}",
            f"- Durable published items: {len(published_latest)}",
            f"- Channel-only items: {attribution_counts['channel_only']}",
            f"- Website campaign-linked items: {attribution_counts['website_campaign_linked']}",
            f"- App Store campaign-linked items: {attribution_counts['store_campaign_linked']}",
            "- Attribution quality: `none` for downstream App Store outcomes until an Apple campaign link or another authoritative install attribution path is read-tested.",
            "",
            "### Campaign conventions",
            "",
            "| Channel | utm_source | utm_medium | Campaign/content convention |",
            "| --- | --- | --- | --- |",
        ]
    )
    for convention in data["attribution"]["channel_conventions"]:
        lines.append(
            f"| {convention['channel']} | `{convention['utm_source']}` | `{convention['utm_medium']}` | "
            f"`{convention['utm_campaign_template']}` / `{convention['utm_content_template']}` |"
        )

    lines.extend(["", "## App Store performance", ""])
    latest_store = max(
        data["app_store_snapshots"],
        key=lambda item: parse_timestamp(item["observed_at"], "app_store_snapshots.observed_at"),
    )
    lines.append(
        f"Observed `{latest_store['observed_at']}` from `{latest_store['source']}` for app `{latest_store['app_id']}`."
    )
    lines.append(
        f"Live version `{latest_store.get('live_version', 'Not available')}`; state "
        f"`{latest_store.get('live_state', 'Not available')}`; downloadable "
        f"`{latest_store.get('downloadable', 'Not available')}`."
    )
    lines.extend(
        [
            "",
            "| Surface | Available | HTTP | Reason | Next action |",
            "| --- | --- | ---: | --- | --- |",
        ]
    )
    for surface in ("metadata", "analytics", "sales", "finance"):
        state = latest_store["access"][surface]
        lines.append(
            f"| {surface} | {state['available']} | {state['http_status']} | "
            f"{display(state.get('reason'))} | {display(state.get('next_action'))} |"
        )
    lines.extend(
        [
            "",
            "| Outcome | Value | Available | Authoritative source | Reason | Next action |",
            "| --- | ---: | --- | --- | --- | --- |",
        ]
    )
    for metric in ("downloads", "first_time_downloads", "sales", "proceeds"):
        record = latest_store["outcomes"][metric]
        lines.append(
            f"| {metric} | {display(record.get('value'))} | {record['available']} | "
            f"{display(record.get('source'))} | {display(record.get('reason'))} | "
            f"{display(record.get('next_action'))} |"
        )
    lines.extend(
        [
            "",
            "Downloads, sales and proceeds are reported only from authoritative Apple evidence. HTTP 403 or missing access is `Not available`, never zero.",
            "",
        ]
    )

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
            "3. Obtain a Team API key or equivalent authorized Apple report path before reporting downloads, sales or proceeds; keep unavailable values null.",
            "4. Create/read-test App Store campaign links before claiming install attribution; website UTMs alone prove only attributed web visits.",
            "5. Verify homepage indexing and Search Console performance when the inspection surface is available; do not duplicate-submit the sitemap.",
            "6. Promote recurring reader language into a search brief only after three independent occurrences.",
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
        print(
            f"validated {len(data.get('social_observations', []))} social observations and "
            f"{len(data.get('app_store_snapshots', []))} App Store snapshots and wrote {args.output}"
        )
    else:
        sys.stdout.write(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
