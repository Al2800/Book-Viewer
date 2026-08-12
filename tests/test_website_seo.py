import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
JOURNAL_PAGE = REPO / "website/app/journal/[slug]/page.tsx"
JOURNAL_DATA = REPO / "website/lib/journal.ts"
GUIDE_PAGE = REPO / "website/app/guides/[slug]/page.tsx"
HOME_PAGE = REPO / "website/app/page.tsx"
ROOT_LAYOUT = REPO / "website/app/layout.tsx"
SEO_LINKS = REPO / "website/lib/seo.ts"
PRODUCT_EVIDENCE = REPO / "website/components/sections/ProductEvidence.tsx"


class WebsiteSEOContractTests(unittest.TestCase):
    def test_journal_detail_metadata_is_self_canonical(self):
        source = JOURNAL_PAGE.read_text(encoding="utf-8")
        self.assertIn("alternates: { canonical: `/journal/${article.slug}` }", source)
        self.assertIn("mainEntityOfPage: canonicalUrl", source)

    def test_journal_detail_exposes_article_and_breadcrumb_jsonld(self):
        source = JOURNAL_PAGE.read_text(encoding="utf-8")
        self.assertIn("'@type': 'Article'", source)
        self.assertIn("'@type': 'BreadcrumbList'", source)
        self.assertGreaterEqual(source.count("type=\"application/ld+json\""), 2)
        self.assertIn("datePublished: article.publishedISO", source)
        self.assertIn("dateModified: article.publishedISO", source)

    def test_every_journal_article_has_an_iso_publication_date(self):
        source = JOURNAL_DATA.read_text(encoding="utf-8")
        self.assertEqual(source.count("publishedISO: '"), 3)
        self.assertIn("publishedISO: '2026-07-24'", source)

    def test_editorial_pages_use_first_party_evidence_and_measured_cta(self):
        guide_source = GUIDE_PAGE.read_text(encoding="utf-8")
        journal_source = JOURNAL_PAGE.read_text(encoding="utf-8")
        links_source = SEO_LINKS.read_text(encoding="utf-8")
        evidence_source = PRODUCT_EVIDENCE.read_text(encoding="utf-8")
        self.assertIn("ProductEvidence", guide_source)
        self.assertIn("ProductEvidence", journal_source)
        self.assertIn("seoAppStoreUrl", guide_source)
        self.assertIn("seoAppStoreUrl", journal_source)
        self.assertIn("utm_source=organic&utm_medium=website&utm_campaign=seo", links_source)
        self.assertIn("alt", evidence_source)
        self.assertIn("/screenshots/library.png", evidence_source)

    def test_software_application_schema_is_homepage_scoped(self):
        home_source = HOME_PAGE.read_text(encoding="utf-8")
        layout_source = ROOT_LAYOUT.read_text(encoding="utf-8")
        self.assertIn("'@type': 'SoftwareApplication'", home_source)
        self.assertIn("downloadUrl: 'https://apps.apple.com/app/id6758091579'", home_source)
        self.assertNotIn("'@type': 'SoftwareApplication'", layout_source)


if __name__ == "__main__":
    unittest.main()
