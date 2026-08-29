from __future__ import annotations

import copy
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/growth_scorecard.py"
spec = importlib.util.spec_from_file_location("growth_scorecard", SCRIPT)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Unable to load {SCRIPT}")
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


METRICS = {
    "views": 10,
    "reach": 10,
    "viewers": 10,
    "interactions": 1,
    "comments": 0,
    "shares": 0,
    "saves": 1,
    "link_clicks": 0,
    "follows": 0,
}


def attribution() -> dict:
    return {
        "canonical_website_origin": "https://bookquotes.uk",
        "canonical_app_store_url": "https://apps.apple.com/app/id6758091579",
        "utm_parameters": ["utm_source", "utm_medium", "utm_campaign", "utm_content"],
        "channel_conventions": [
            {
                "channel": "facebook",
                "utm_source": "facebook",
                "utm_medium": "organic_social",
                "utm_campaign_template": "bq-{experiment_id}-{yyyy_mm}",
                "utm_content_template": "{content_id}-{treatment}",
            },
            {
                "channel": "google_search",
                "utm_source": "google",
                "utm_medium": "organic_search",
                "utm_campaign_template": "bq-{experiment_id}-{yyyy_mm}",
                "utm_content_template": "{landing_page_slug}-{treatment}",
            },
        ],
        "weekly_metrics": {
            "primary": "first_time_downloads",
            "secondary": ["downloads", "activations", "sales", "proceeds"],
        },
        "reporting_window_days": 7,
        "checkpoints": {"baseline": "7d_pre_experiment", "reviews": ["24h", "72h", "7d"]},
        "activation_definition": "Add a first book and save a first quote.",
        "app_store_campaign_links": {
            "available": False,
            "value": None,
            "reason": "No generated link has been read back.",
            "next_action": "Create and read back an approved campaign link.",
        },
    }


def app_store_snapshot() -> dict:
    unavailable = {
        "available": False,
        "http_status": 403,
        "reason": "FORBIDDEN_ERROR",
        "next_action": "Authorize the required Team API report access.",
    }
    outcome = {
        "value": None,
        "available": False,
        "source": None,
        "reason": "Report access unavailable.",
        "next_action": "Read an authorized Apple report.",
    }
    return {
        "observed_at": "2026-08-10T21:45:00+01:00",
        "source": "app_store_connect_api_read_only",
        "app_id": "6758091579",
        "live_version": "1.0.1",
        "live_state": "READY_FOR_SALE",
        "downloadable": True,
        "access": {
            "metadata": {
                "available": True,
                "http_status": 200,
                "reason": None,
                "next_action": "Continue polling.",
            },
            "analytics": dict(unavailable),
            "sales": dict(unavailable),
            "finance": dict(unavailable),
        },
        "outcomes": {
            "downloads": dict(outcome),
            "first_time_downloads": dict(outcome),
            "sales": dict(outcome),
            "proceeds": dict(outcome, currency=None),
        },
    }


def evidence() -> dict:
    return {
        "schema_version": 1,
        "updated_at": "2026-08-10T21:45:00+01:00",
        "attribution": attribution(),
        "experiments": [
            {
                "id": "FB-001",
                "hypothesis": "Ritual framing earns more saves.",
                "primary_metric": "saves_per_1000_reach",
                "secondary_metric": "meaningful_comments_per_1000_reach",
                "variable": "framing",
                "treatments": ["ritual", "feature"],
                "minimum_executions_per_treatment": 3,
                "status": "Pending",
            }
        ],
        "social_observations": [
            {
                "observation_id": "fb-content-1-initial",
                "platform": "facebook",
                "identity": "BookQuotes",
                "content_id": "content-1",
                "title": "Test post",
                "format": "text",
                "published_at": "2026-08-07T12:00:00+01:00",
                "observed_at": "2026-08-07T12:05:00+01:00",
                "checkpoint": "initial",
                "status": "published",
                "experiment_id": "FB-001",
                "treatment": "ritual",
                "rights_basis": "Original text.",
                "metrics": dict(METRICS),
            }
        ],
        "search_snapshots": [
            {
                "observed_at": "2026-08-07T12:00:00+01:00",
                "property": "bookquotes.uk",
                "sitemap_url": "https://bookquotes.uk/sitemap.xml",
                "sitemap_status": "Success",
                "discovered_pages": 15,
            }
        ],
        "app_store_snapshots": [app_store_snapshot()],
    }


class GrowthEvidenceValidationTests(unittest.TestCase):
    def test_load_rejects_non_object_top_level_json(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as handle:
            handle.write("[]")
            path = Path(handle.name)
        try:
            with self.assertRaisesRegex(ValueError, "top-level JSON must be an object"):
                module.load(path)
        finally:
            path.unlink(missing_ok=True)

    def test_rejects_empty_top_level_collections(self):
        data = evidence()
        data["experiments"] = []
        data["social_observations"] = []
        data["search_snapshots"] = []
        data["app_store_snapshots"] = []
        with self.assertRaisesRegex(ValueError, "must be a non-empty list"):
            module.validate(data)

    def test_rejects_duplicate_channel_sources_and_malformed_checkpoint_plan(self):
        data = evidence()
        data["attribution"]["channel_conventions"][1]["utm_source"] = "facebook"
        data["attribution"]["checkpoints"]["reviews"] = ["24h", "7d"]
        data["attribution"]["weekly_metrics"]["primary"] = "views"
        data["attribution"]["reporting_window_days"] = 30
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("utm_source must be non-empty and unique", message)
        self.assertIn("reviews must be 24h, 72h and 7d", message)
        self.assertIn("primary must be first_time_downloads", message)
        self.assertIn("reporting_window_days must be 7", message)

        data = evidence()
        data["attribution"]["channel_conventions"][0]["utm_campaign_template"] = "static"
        data["attribution"]["channel_conventions"][0]["utm_content_template"] = "static"
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("must bind experiment_id and yyyy_mm", message)
        self.assertIn("must bind treatment and a durable content identifier", message)

    def test_verified_app_store_campaign_links_are_supported_and_validated(self):
        data = evidence()
        data["attribution"]["app_store_campaign_links"] = {
            "available": True,
            "value": [
                {
                    "channel": "facebook",
                    "campaign_id": "fb-001",
                    "url": "https://apps.apple.com/app/id6758091579?ct=fb-001",
                }
            ],
            "reason": None,
            "next_action": "Measure the generated campaign link.",
        }
        module.validate(data)

        data["attribution"]["app_store_campaign_links"]["value"][0]["url"] = (
            "https://apps.apple.com/app/apple-store/id6758091579?pt=128448172&ct=fb-001&mt=8"
        )
        module.validate(data)

        data["attribution"]["app_store_campaign_links"]["value"][0]["url"] = "https://apps.apple.com/attacker?id6758091579"
        with self.assertRaisesRegex(ValueError, "must be the BookQuotes App Store URL"):
            module.validate(data)

    def test_social_store_attribution_requires_a_verified_campaign_id(self):
        data = evidence()
        data["social_observations"][0]["campaign"] = {
            "campaign_id": "bq-fb-001-2026-08",
            "destination_url": "https://apps.apple.com/app/id6758091579?ct=unverified",
            "utm_source": "facebook",
            "utm_medium": "organic_social",
            "utm_campaign": "bq-fb-001-2026-08",
            "utm_content": "content-1-ritual",
            "app_store_campaign_id": "unverified",
        }
        with self.assertRaisesRegex(ValueError, "app_store_campaign_id is not verified"):
            module.validate(data)

        data["attribution"]["app_store_campaign_links"] = {
            "available": True,
            "value": [
                {
                    "channel": "facebook",
                    "campaign_id": "unverified",
                    "url": "https://apps.apple.com/app/id6758091579?ct=unverified",
                }
            ],
            "reason": None,
            "next_action": "Measure the generated campaign link.",
        }
        module.validate(data)
        report = module.render(data)
        self.assertIn("App Store campaign-linked items: 1", report)

        data["social_observations"][0]["campaign"]["destination_url"] = (
            "https://apps.apple.com/app/id6758091579?ct=wrong"
        )
        with self.assertRaisesRegex(ValueError, "ct parameter must equal"):
            module.validate(data)

        data["social_observations"][0]["campaign"]["destination_url"] = (
            "https://apps.apple.com/app/id6758091579?ct=unverified"
        )
        data["attribution"]["app_store_campaign_links"]["value"][0]["channel"] = "google_search"
        with self.assertRaisesRegex(ValueError, "must match the platform channel"):
            module.validate(data)

    def test_website_campaign_requires_declared_convention_and_url_parameters(self):
        data = evidence()
        data["social_observations"][0]["campaign"] = {
            "campaign_id": "bq-fb-001-2026-08",
            "destination_url": (
                "https://bookquotes.uk/?utm_source=facebook&utm_medium=organic_social&"
                "utm_campaign=bq-fb-001-2026-08&utm_content=content-1-ritual"
            ),
            "utm_source": "facebook",
            "utm_medium": "organic_social",
            "utm_campaign": "bq-fb-001-2026-08",
            "utm_content": "content-1-ritual",
            "app_store_campaign_id": None,
        }
        module.validate(data)
        report = module.render(data)
        self.assertIn("Website campaign-linked items: 1", report)

        data["social_observations"][0]["campaign"]["utm_medium"] = "spam"
        with self.assertRaisesRegex(ValueError, "utm_medium must match"):
            module.validate(data)

        data = evidence()
        campaign = {
            "campaign_id": "bq-other-2026-08",
            "destination_url": (
                "https://bookquotes.uk/?utm_source=facebook&utm_medium=organic_social&"
                "utm_campaign=bq-other-2026-08&utm_content=content-1-ritual"
            ),
            "utm_source": "facebook",
            "utm_medium": "organic_social",
            "utm_campaign": "bq-other-2026-08",
            "utm_content": "content-1-ritual",
            "app_store_campaign_id": None,
        }
        data["social_observations"][0]["campaign"] = campaign
        with self.assertRaisesRegex(ValueError, "must match the channel experiment template"):
            module.validate(data)

        data = evidence()
        data["social_observations"][0]["platform"] = "undeclared_channel"
        with self.assertRaisesRegex(ValueError, "must have a declared channel convention"):
            module.validate(data)

    def test_unavailable_app_store_metrics_must_be_null_with_next_action(self):
        data = evidence()
        data["app_store_snapshots"][0]["outcomes"]["downloads"]["value"] = 0
        del data["app_store_snapshots"][0]["outcomes"]["downloads"]["source"]
        del data["app_store_snapshots"][0]["outcomes"]["proceeds"]["currency"]
        del data["app_store_snapshots"][0]["outcomes"]["sales"]["next_action"]
        del data["app_store_snapshots"][0]["access"]["finance"]["reason"]
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("downloads.value must be null when unavailable", message)
        self.assertIn("downloads.source must be explicitly null when unavailable", message)
        self.assertIn("proceeds.currency must be explicitly null when unavailable", message)
        self.assertIn("sales requires reason and next_action", message)
        self.assertIn("access.finance requires reason and next_action", message)

    def test_available_outcome_requires_authoritative_source(self):
        data = evidence()
        downloads = data["app_store_snapshots"][0]["outcomes"]["downloads"]
        downloads.update(value=4, available=True, source="manual_guess")
        with self.assertRaisesRegex(ValueError, "source is not authoritative"):
            module.validate(data)

    def test_available_outcome_rejects_unhashable_source_types_as_validation_errors(self):
        for malformed_source in ([], {}):
            with self.subTest(malformed_source=malformed_source):
                data = evidence()
                data["app_store_snapshots"][0]["access"]["analytics"].update(
                    available=True,
                    http_status=200,
                    reason=None,
                )
                downloads = data["app_store_snapshots"][0]["outcomes"]["downloads"]
                downloads.update(value=4, available=True, source=malformed_source)
                with self.assertRaisesRegex(ValueError, "source is not authoritative"):
                    module.validate(data)

    def test_available_outcome_requires_matching_available_surface(self):
        data = evidence()
        downloads = data["app_store_snapshots"][0]["outcomes"]["downloads"]
        downloads.update(value=4, available=True, source="app_store_connect_analytics")
        with self.assertRaisesRegex(ValueError, "requires available analytics access"):
            module.validate(data)

        data["app_store_snapshots"][0]["access"]["analytics"].update(
            available=True, http_status=200, reason=None
        )
        module.validate(data)

        data["app_store_snapshots"][0]["access"]["analytics"] = []
        with self.assertRaisesRegex(ValueError, "requires available analytics access"):
            module.validate(data)

    def test_available_access_requires_2xx_and_proceeds_require_currency(self):
        data = evidence()
        data["app_store_snapshots"][0]["access"]["finance"]["available"] = True
        proceeds = data["app_store_snapshots"][0]["outcomes"]["proceeds"]
        proceeds.update(value=2.5, available=True, source="app_store_connect_finance")
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("available true requires a 2xx HTTP status", message)
        self.assertIn("currency must be a three-letter code", message)

    def test_available_proceeds_render_the_authoritative_currency(self):
        data = evidence()
        data["app_store_snapshots"][0]["access"]["finance"].update(
            available=True,
            http_status=200,
            reason=None,
        )
        data["app_store_snapshots"][0]["outcomes"]["proceeds"].update(
            value=2.5,
            available=True,
            source="app_store_connect_finance",
            currency="GBP",
            reason=None,
        )
        module.validate(data)
        report = module.render(data)
        self.assertIn("| Outcome | Value | Currency | Available |", report)
        self.assertIn("| proceeds | 2.5 | GBP | True |", report)

    def test_app_store_snapshot_requires_renderable_source_and_metadata(self):
        data = evidence()
        snapshot = data["app_store_snapshots"][0]
        del snapshot["source"]
        snapshot["live_version"] = None
        snapshot["live_state"] = ""
        snapshot["downloadable"] = "yes"
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("source must be app_store_connect_api_read_only", message)
        self.assertIn("live_version must be non-empty", message)
        self.assertIn("live_state must be non-empty", message)
        self.assertIn("downloadable must be boolean", message)

    def test_latest_app_store_snapshot_uses_absolute_time_not_timestamp_text(self):
        data = evidence()
        older = data["app_store_snapshots"][0]
        older["observed_at"] = "2026-08-10T18:00:00+02:00"
        older["live_version"] = "OLDER"
        newer = copy.deepcopy(older)
        newer["observed_at"] = "2026-08-10T17:30:00+01:00"
        newer["live_version"] = "NEWER"
        data["app_store_snapshots"].append(newer)
        module.validate(data)
        report = module.render(data)
        self.assertIn("Live version <code>NEWER</code>", report)

    def test_render_reports_separate_surfaces_null_outcomes_and_attribution_quality(self):
        data = evidence()
        module.validate(data)
        report = module.render(data)
        self.assertIn("## Weekly funnel and attribution", report)
        self.assertIn(
            "Reporting window: <code>2026-08-03T21:45:00+01:00</code>", report
        )
        self.assertIn("Channel-only items: 1", report)
        self.assertIn("## App Store performance", report)
        self.assertIn("| metadata | True | 200 |", report)
        self.assertIn("| analytics | False | 403 |", report)
        self.assertIn("| downloads | Not available | Not available | False |", report)
        self.assertIn("HTTP 403 or missing access is `Not available`, never zero", report)

    def test_rejects_invalid_updated_at_checkpoint_and_boolean_metric(self):
        data = evidence()
        data["updated_at"] = "not-a-time"
        data["social_observations"][0]["observed_at"] = "2026-08-07T12:00:00"
        data["social_observations"][0]["checkpoint"] = "whenever"
        data["social_observations"][0]["metrics"]["reach"] = True
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("updated_at", message)
        self.assertIn("timezone offset", message)
        self.assertIn("checkpoint", message)
        self.assertIn("non-negative number", message)

    def test_rejects_non_finite_metrics_and_future_observations(self):
        data = evidence()
        data["social_observations"][0]["metrics"]["saves"] = float("nan")
        data["social_observations"][0]["metrics"]["reach"] = float("inf")
        data["social_observations"][0]["observed_at"] = "2026-08-11T12:00:00+01:00"
        data["search_snapshots"][0]["observed_at"] = "2026-08-11T12:00:00+01:00"
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("finite", message)
        self.assertIn("after updated_at", message)

    def test_missing_observation_id_is_collected_as_validation_error(self):
        data = evidence()
        del data["social_observations"][0]["observation_id"]
        data["social_observations"][0]["content_id"] = None
        with self.assertRaisesRegex(ValueError, "observation_id must be non-empty"):
            module.validate(data)

    def test_rejects_undeclared_treatment(self):
        data = evidence()
        data["social_observations"][0]["treatment"] = "surprise"
        with self.assertRaisesRegex(ValueError, "declared treatments"):
            module.validate(data)

    def test_rejects_unsupported_secondary_metric_and_content_reclassification(self):
        data = evidence()
        data["experiments"][0]["secondary_metric"] = "raw_likes"
        later = copy.deepcopy(data["social_observations"][0])
        later.update(
            observation_id="fb-content-1-24h",
            observed_at="2026-08-08T12:05:00+01:00",
            checkpoint="24h",
            treatment="feature",
            platform="instagram",
        )
        data["social_observations"].append(later)
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("secondary_metric is unsupported", message)
        self.assertIn("content_id invariant", message)

    def test_malformed_json_types_are_collected_as_validation_errors(self):
        data = evidence()
        data["experiments"][0]["status"] = []
        data["experiments"][0]["primary_metric"] = []
        data["social_observations"][0]["status"] = []
        data["social_observations"][0]["checkpoint"] = []
        data["social_observations"][0]["experiment_id"] = []
        data["social_observations"][0]["treatment"] = []
        with self.assertRaises(ValueError):
            module.validate(data)

    def test_rejects_non_renderable_observation_and_search_fields(self):
        data = evidence()
        data["social_observations"][0]["title"] = 7
        data["social_observations"][0]["format"] = None
        data["social_observations"][0]["content_id"] = []
        del data["search_snapshots"][0]["sitemap_status"]
        data["search_snapshots"][0]["discovered_pages"] = True
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("title", message)
        self.assertIn("format", message)
        self.assertIn("content_id", message)
        self.assertIn("sitemap_status", message)
        self.assertIn("discovered_pages", message)

    def test_search_console_api_snapshot_renders_indexing_sitemap_and_performance_evidence(self):
        data = evidence()
        snapshot = data["search_snapshots"][0]
        snapshot["search_console"] = {
            "property": "sc-domain:bookquotes.uk",
            "permission_level": "siteOwner",
            "auth_method": "application_default_credentials",
            "read_tested": True,
            "sitemap": {
                "url": "https://bookquotes.uk/sitemap.xml",
                "status": "Success",
                "last_submitted": "2026-08-07T06:52:13.248Z",
                "last_downloaded": "2026-08-10T09:09:30.939Z",
                "is_pending": False,
                "warnings": 0,
                "errors": 0,
                "contents": [{"type": "web", "submitted": 15, "indexed": 0}],
            },
            "url_inspection": {
                "inspection_url": "https://bookquotes.uk/",
                "verdict": "PASS",
                "coverage_state": "Submitted and indexed",
                "indexing_state": "INDEXING_ALLOWED",
                "page_fetch_state": "SUCCESSFUL",
                "google_canonical": "https://bookquotes.uk/",
                "user_canonical": "https://bookquotes.uk/",
                "last_crawl_time": "2026-08-07T06:53:14Z",
            },
            "performance": {
                "processing_delay_note": "Search Analytics was queried through the latest lagged final date; Google data remains subject to reporting delay.",
                "windows": {
                    "28d": {
                        "start_date": "2026-07-14",
                        "end_date": "2026-08-10",
                        "data_state": "final",
                        "dimensions": {
                            "query": {"row_count": 0, "rows": []},
                            "page": {"row_count": 1, "rows": [{"keys": ["https://bookquotes.uk/"], "clicks": 1, "impressions": 1, "ctr": 1, "position": 2}]},
                            "country": {"row_count": 1, "rows": [{"keys": ["gbr"], "clicks": 1, "impressions": 1, "ctr": 1, "position": 2}]},
                            "device": {"row_count": 1, "rows": [{"keys": ["MOBILE"], "clicks": 1, "impressions": 1, "ctr": 1, "position": 2}]},
                        },
                    },
                    "90d": {
                        "start_date": "2026-05-13",
                        "end_date": "2026-08-10",
                        "data_state": "final",
                        "dimensions": {
                            "query": {"row_count": 0, "rows": []},
                            "page": {"row_count": 1, "rows": [{"keys": ["https://bookquotes.uk/"], "clicks": 1, "impressions": 1, "ctr": 1, "position": 2}]},
                            "country": {"row_count": 1, "rows": [{"keys": ["gbr"], "clicks": 1, "impressions": 1, "ctr": 1, "position": 2}]},
                            "device": {"row_count": 1, "rows": [{"keys": ["MOBILE"], "clicks": 1, "impressions": 1, "ctr": 1, "position": 2}]},
                        },
                    },
                },
            },
        }
        snapshot["cloudflare_http_traffic"] = {
            "available": False,
            "source": "cloudflare_graphql_api_read_only",
            "window": "2026-08-11T06:00:00Z/2026-08-12T06:00:00Z",
            "value": None,
            "reason": "CLOUDFLARE_API_TOKEN is not present in the read environment.",
            "next_action": "Provide an approved Cloudflare API token through the protected environment before the next read-only edge-traffic probe.",
        }
        module.validate(data)
        report = module.render(data)
        self.assertIn("Search Console API access: read-tested (siteOwner)", report)
        self.assertIn("Sitemap API state: Success; submitted 15; indexed 0; pending False; warnings 0; errors 0", report)
        self.assertIn("URL Inspection: PASS; Submitted and indexed; canonical https://bookquotes.uk/", report)
        self.assertIn("28d (2026-07-14 to 2026-08-10): 1 clicks, 1 impressions", report)
        self.assertIn("queries 0 rows; pages 1 rows; countries 1 rows; devices 1 rows", report)
        self.assertIn("Cloudflare HTTP traffic: unavailable", report)
        self.assertIn("not a Search Console metric", report)

    def test_rejects_malformed_search_console_api_records(self):
        data = evidence()
        data["search_snapshots"][0]["search_console"] = {
            "property": "sc-domain:bookquotes.uk",
            "permission_level": "siteOwner",
            "auth_method": "application_default_credentials",
            "read_tested": True,
            "sitemap": {"contents": "not-a-list"},
            "url_inspection": {},
            "performance": {"windows": []},
        }
        with self.assertRaisesRegex(ValueError, "search_console"):
            module.validate(data)

    def test_rejects_cloudflare_traffic_records_that_collapse_unavailable_into_zero(self):
        data = evidence()
        data["search_snapshots"][0]["cloudflare_http_traffic"] = {
            "available": False,
            "source": "cloudflare_graphql_api_read_only",
            "window": "2026-08-11T06:00:00Z/2026-08-12T06:00:00Z",
            "value": 0,
            "reason": "Not connected.",
            "next_action": "Connect the API.",
        }
        with self.assertRaisesRegex(ValueError, "cloudflare_http_traffic.*value must be null"):
            module.validate(data)

    def test_rejects_impossible_checkpoint_and_status_semantics(self):
        data = evidence()
        observation = data["social_observations"][0]
        observation["checkpoint"] = "7d-audit"
        observation["observed_at"] = "2026-08-08T12:00:00+01:00"
        observation["content_id"] = None
        observation["metrics"]["saves"] = None
        data["experiments"][0]["status"] = "Winner"
        with self.assertRaises(ValueError) as raised:
            module.validate(data)
        message = str(raised.exception)
        self.assertIn("7d checkpoint", message)
        self.assertIn("content_id is required", message)
        self.assertIn("metrics_unavailable_reason", message)
        self.assertIn("Winner requires comparison-ready evidence", message)

    def test_equal_observation_timestamps_have_a_stable_semantic_tie_break(self):
        initial = copy.deepcopy(evidence()["social_observations"][0])
        initial.update(
            observation_id="same-time-initial",
            content_id="same-time-content",
            checkpoint="initial",
            published_at="2026-08-06T12:00:00+01:00",
            observed_at="2026-08-07T12:05:00+01:00",
        )
        later = copy.deepcopy(initial)
        later.update(observation_id="same-time-24h", checkpoint="24h")

        forward = module.latest_content_observations([initial, later])
        reverse = module.latest_content_observations([later, initial])
        self.assertEqual(forward["same-time-content"]["checkpoint"], "24h")
        self.assertEqual(reverse["same-time-content"]["checkpoint"], "24h")

        stopped = copy.deepcopy(initial)
        stopped.update(observation_id="same-time-stopped", status="stopped", checkpoint="audit")
        for observations in ([later, stopped], [stopped, later]):
            latest = module.latest_content_observations(observations)
            self.assertEqual(latest["same-time-content"]["status"], "stopped")

    def test_markdown_table_cells_escape_structure_and_html(self):
        self.assertEqual(
            module.markdown_cell("a|b\n<c>`d`"),
            "a&#124;b<br>&lt;c&gt;&#96;d&#96;",
        )
        active_markdown = r"a\|b ![pixel](https://tracker.invalid/p) [link](https://example.invalid) *em* _em_"
        escaped = module.markdown_cell(active_markdown)
        self.assertNotIn(r"\|", escaped)
        self.assertNotIn("![", escaped)
        self.assertNotIn("](", escaped)
        self.assertNotIn("*em*", escaped)
        self.assertNotIn("_em_", escaped)
        self.assertIn("a&#92;&#124;b", escaped)
        self.assertIn("&#33;&#91;pixel&#93;&#40;https://tracker.invalid/p&#41;", escaped)

        data = evidence()
        data["social_observations"][0]["title"] = "Title | split\n<script>"
        data["social_observations"][0]["format"] = "image|carousel"
        data["attribution"]["channel_conventions"][0]["utm_source"] = "face|book\nsource"
        data["app_store_snapshots"][0]["access"]["finance"]["reason"] = "No | role\n<unsafe>"
        module.validate(data)
        report = module.render(data)
        self.assertIn("Title &#124; split<br>&lt;script&gt;", report)
        self.assertIn("image&#124;carousel", report)
        self.assertIn("face&#124;book<br>source", report)
        self.assertIn("No &#124; role<br>&lt;unsafe&gt;", report)
        self.assertNotIn("<script>", report)

    def test_non_table_markdown_contexts_neutralize_active_content(self):
        payload = "<img src=x onerror=alert(1)> [track](https://tracker.invalid/pixel)"
        data = evidence()
        data["experiments"][0]["id"] = f"FB-001 {payload}"
        data["experiments"][0]["hypothesis"] = payload
        data["social_observations"][0]["experiment_id"] = f"FB-001 {payload}"
        data["attribution"]["activation_definition"] = payload
        data["app_store_snapshots"][0]["live_version"] = f"`{payload}`"
        data["search_snapshots"][0]["sitemap_status"] = payload
        module.validate(data)
        report = module.render(data)

        self.assertNotIn("<img", report)
        self.assertNotIn("[track](", report)
        self.assertNotIn("`<img", report)
        self.assertIn("&lt;img src=x onerror=alert&#40;1&#41;&gt;", report)
        self.assertIn("&#91;track&#93;&#40;https://tracker.invalid/pixel&#41;", report)
        self.assertEqual(
            module.markdown_code(payload),
            "<code>&lt;img src=x onerror=alert&#40;1&#41;&gt; "
            "&#91;track&#93;&#40;https://tracker.invalid/pixel&#41;</code>",
        )


class ExperimentReadinessTests(unittest.TestCase):
    def test_unique_content_counts_once_and_compares_declared_rate(self):
        data = evidence()
        data["social_observations"] = []
        for treatment, saves, reach in (("ritual", 1, 10), ("feature", 5, 100)):
            for content_number in range(3):
                for checkpoint, observed_at in (
                    ("initial", "2026-08-07T12:05:00+01:00"),
                    ("24h", "2026-08-08T12:05:00+01:00"),
                ):
                    observation = copy.deepcopy(evidence()["social_observations"][0])
                    content_id = f"{treatment}-{content_number}"
                    observation.update(
                        observation_id=f"{content_id}-{checkpoint}",
                        content_id=content_id,
                        checkpoint=checkpoint,
                        published_at="2026-08-07T12:00:00+01:00",
                        observed_at=observed_at,
                        treatment=treatment,
                    )
                    observation["metrics"]["saves"] = saves
                    observation["metrics"]["reach"] = reach
                    data["social_observations"].append(observation)

        module.validate(data)
        report = module.render(data)
        self.assertIn(
            'Executions by treatment: <code>&#123;"feature": 3, "ritual": 3&#125;</code>',
            report,
        )
        self.assertIn("Comparison ready: yes", report)
        self.assertIn("ritual median saves/1k reach: 100.0", report)
        self.assertIn("feature median saves/1k reach: 50.0", report)
        self.assertNotIn("median saves: 5", report)

    def test_winner_rejects_initial_only_or_inconsistent_checkpoints(self):
        data = evidence()
        data["social_observations"] = []
        for treatment in ("ritual", "feature"):
            for content_number in range(3):
                observation = copy.deepcopy(evidence()["social_observations"][0])
                observation.update(
                    observation_id=f"{treatment}-{content_number}-initial",
                    content_id=f"{treatment}-{content_number}",
                    checkpoint="initial",
                    treatment=treatment,
                )
                data["social_observations"].append(observation)
        data["experiments"][0]["status"] = "Winner"
        with self.assertRaisesRegex(ValueError, "comparison-ready evidence"):
            module.validate(data)

        for observation in data["social_observations"]:
            observation["checkpoint"] = "24h" if observation["treatment"] == "ritual" else "72h"
            observation["observed_at"] = (
                "2026-08-08T12:05:00+01:00"
                if observation["treatment"] == "ritual"
                else "2026-08-10T12:05:00+01:00"
            )
        with self.assertRaisesRegex(ValueError, "comparison-ready evidence"):
            module.validate(data)

    def test_later_stopped_state_prevents_winner(self):
        data = evidence()
        data["social_observations"] = []
        for treatment in ("ritual", "feature"):
            for content_number in range(3):
                observation = copy.deepcopy(evidence()["social_observations"][0])
                observation.update(
                    observation_id=f"{treatment}-{content_number}-24h",
                    content_id=f"{treatment}-{content_number}",
                    checkpoint="24h",
                    published_at="2026-08-07T12:00:00+01:00",
                    observed_at="2026-08-08T12:05:00+01:00",
                    treatment=treatment,
                )
                data["social_observations"].append(observation)
        stopped = copy.deepcopy(data["social_observations"][0])
        stopped.update(
            observation_id="ritual-0-stopped",
            status="stopped",
            checkpoint="audit",
            observed_at="2026-08-09T12:05:00+01:00",
            experiment_id=None,
            treatment=None,
        )
        data["social_observations"].append(stopped)
        data["experiments"][0]["status"] = "Winner"
        with self.assertRaisesRegex(ValueError, "comparison-ready evidence"):
            module.validate(data)
        self.assertIn("Comparison ready: no", module.render(data))


if __name__ == "__main__":
    unittest.main()
