from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/verify_web_deployment.py"
spec = importlib.util.spec_from_file_location("verify_web_deployment", SCRIPT)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Unable to load {SCRIPT}")
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


SITEMAP = b'''<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
%s
</urlset>'''


class DeploymentVerificationTests(unittest.TestCase):
    def setUp(self):
        self.original_fetch = module.fetch
        self.original_fetch_no_redirect = getattr(module, "fetch_no_redirect", None)

    def tearDown(self):
        module.fetch = self.original_fetch
        if self.original_fetch_no_redirect is None:
            if hasattr(module, "fetch_no_redirect"):
                delattr(module, "fetch_no_redirect")
        else:
            module.fetch_no_redirect = self.original_fetch_no_redirect

    def test_redirect_requires_308_then_canonical_200(self):
        module.fetch_no_redirect = lambda url, timeout: (302, "https://bookquotes.uk/")
        module.fetch = lambda url, timeout: (200, "https://bookquotes.uk/", b"", {})
        self.assertFalse(module.check_redirect("http://bookquotes.uk/", "https://bookquotes.uk/", 1).ok)

        module.fetch_no_redirect = lambda url, timeout: (308, "https://bookquotes.uk/")
        self.assertTrue(module.check_redirect("http://bookquotes.uk/", "https://bookquotes.uk/", 1).ok)

        module.fetch_no_redirect = lambda url, timeout: (308, "https://bookquotes.uk////")
        module.fetch = lambda url, timeout: (200, "https://bookquotes.uk////", b"", {})
        self.assertFalse(module.check_redirect("http://bookquotes.uk/", "https://bookquotes.uk/", 1).ok)

    def test_text_endpoint_rejects_off_origin_final_url(self):
        module.fetch = lambda url, timeout: (200, "https://evil.example/robots.txt", b"required", {})
        result = module.check_text("https://bookquotes.uk/robots.txt", [b"required"], 1)
        self.assertFalse(result.ok)

    def test_homepage_rejects_lowercase_noindex_header(self):
        module.fetch = lambda url, timeout: (
            200,
            "https://bookquotes.uk/",
            b'<link rel="canonical" href="https://bookquotes.uk/">',
            {"x-robots-tag": "noindex"},
        )
        self.assertFalse(module.check_homepage(1).ok)

    def test_sitemap_rejects_deceptive_origin_and_off_origin_response(self):
        canonical_rows = b"".join(
            f"<url><loc>https://bookquotes.uk/page-{index}</loc></url>".encode()
            for index in range(14)
        )
        deceptive = b"<url><loc>https://bookquotes.uk.evil.example/page</loc></url>"
        module.fetch = lambda url, timeout: (
            200,
            "https://evil.example/sitemap.xml",
            SITEMAP % (canonical_rows + deceptive),
            {},
        )
        self.assertFalse(module.check_sitemap(1).ok)

    def test_workflow_exercises_built_deployment_endpoint(self):
        workflow = (ROOT / ".github/workflows/website-verification.yml").read_text()
        self.assertIn('"tests/test_verify_web_deployment.py"', workflow)
        self.assertIn("python3 -m unittest tests.test_verify_web_deployment -v", workflow)
        self.assertIn("http://127.0.0.1:4173/deployment.json", workflow)
        self.assertIn('document["sourceRevision"] == expected', workflow)
        self.assertIn("service", workflow)
        self.assertIn("canonicalOrigin", workflow)
        self.assertIn('document["canonicalOrigin"] == "https://bookquotes.uk"', workflow)

    def test_growth_ci_validates_ledger_and_deterministic_scorecard(self):
        workflow_path = ROOT / ".github/workflows/growth-evidence-verification.yml"
        self.assertTrue(workflow_path.exists())
        workflow = workflow_path.read_text()
        self.assertIn("scripts/growth_scorecard.py", workflow)
        self.assertIn("GrowthEvidence.json", workflow)
        self.assertIn("GrowthScorecard.md", workflow)
        self.assertIn("diff --unified", workflow)
        self.assertIn("python3 -m unittest", workflow)
        self.assertIn("permissions:\n  contents: read", workflow)


if __name__ == "__main__":
    unittest.main()
