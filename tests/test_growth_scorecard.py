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


def evidence() -> dict:
    return {
        "schema_version": 1,
        "updated_at": "2026-08-10T21:45:00+01:00",
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
        with self.assertRaisesRegex(ValueError, "must be a non-empty list"):
            module.validate(data)

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
        self.assertIn('Executions by treatment: {"feature": 3, "ritual": 3}', report)
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
