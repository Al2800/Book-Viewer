#!/usr/bin/env python3
"""Verify BookQuotes canonical hosts and essential SEO endpoints."""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from html.parser import HTMLParser
from typing import Iterable
from urllib.parse import urljoin, urlparse
from xml.etree import ElementTree

CANONICAL_ORIGIN = "https://bookquotes.uk"
USER_AGENT = "BookQuotesDeploymentVerifier/1.0"


@dataclass
class Check:
    url: str
    status: int | None
    final_url: str | None
    ok: bool
    detail: str


class CanonicalParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.canonical: str | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() != "link":
            return
        values = {key.lower(): value for key, value in attrs}
        if values.get("rel") == "canonical":
            self.canonical = values.get("href")


def fetch(url: str, timeout: float) -> tuple[int, str, bytes, dict[str, str]]:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        headers = {key.lower(): value for key, value in response.headers.items()}
        return response.status, response.geturl(), response.read(), headers


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):  # type: ignore[no-untyped-def]
        return None


def fetch_no_redirect(url: str, timeout: float) -> tuple[int, str]:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(request, timeout=timeout) as response:
            return response.status, response.geturl()
    except urllib.error.HTTPError as error:
        location = error.headers.get("Location")
        if 300 <= error.code < 400 and location:
            return error.code, urljoin(url, location)
        raise


def is_canonical_url(url: str) -> bool:
    parsed = urlparse(url)
    canonical = urlparse(CANONICAL_ORIGIN)
    return parsed.scheme == canonical.scheme and parsed.netloc == canonical.netloc


def check_redirect(url: str, expected_final: str, timeout: float) -> Check:
    try:
        redirect_status, location = fetch_no_redirect(url, timeout)
        final_status, final_url, _, _ = fetch(url, timeout)
        ok = (
            redirect_status == 308
            and location == expected_final
            and final_status == 200
            and final_url == expected_final
        )
        detail = (
            f"HTTP {redirect_status} Location {location}; "
            f"resolved to {final_url} with HTTP {final_status}"
        )
        return Check(url, redirect_status, final_url, ok, detail)
    except (urllib.error.URLError, TimeoutError) as error:
        return Check(url, None, None, False, str(error))


def check_homepage(timeout: float) -> Check:
    url = f"{CANONICAL_ORIGIN}/"
    try:
        status, final_url, body, headers = fetch(url, timeout)
        parser = CanonicalParser()
        parser.feed(body.decode("utf-8", errors="replace"))
        canonical_ok = parser.canonical in {CANONICAL_ORIGIN, f"{CANONICAL_ORIGIN}/"}
        robots_header = headers.get("x-robots-tag", "")
        robots_ok = "noindex" not in robots_header.lower()
        ok = status == 200 and final_url == url and canonical_ok and robots_ok
        detail = f"canonical={parser.canonical!r}; x-robots-tag={robots_header or 'absent'!r}"
        return Check(url, status, final_url, ok, detail)
    except (urllib.error.URLError, TimeoutError) as error:
        return Check(url, None, None, False, str(error))


def check_text(url: str, required: Iterable[bytes], timeout: float) -> Check:
    try:
        status, final_url, body, _ = fetch(url, timeout)
        missing = [item.decode("utf-8", errors="replace") for item in required if item not in body]
        ok = status == 200 and final_url == url and not missing
        detail = (
            "required markers present on canonical endpoint"
            if ok
            else f"final_url={final_url}; missing markers: {missing}"
        )
        return Check(url, status, final_url, ok, detail)
    except (urllib.error.URLError, TimeoutError) as error:
        return Check(url, None, None, False, str(error))


def check_sitemap(timeout: float) -> Check:
    url = f"{CANONICAL_ORIGIN}/sitemap.xml"
    try:
        status, final_url, body, _ = fetch(url, timeout)
        root = ElementTree.fromstring(body)
        namespace = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
        locations = [node.text or "" for node in root.findall("sm:url/sm:loc", namespace)]
        foreign = [location for location in locations if not is_canonical_url(location)]
        ok = status == 200 and final_url == url and len(locations) >= 15 and not foreign
        detail = f"final_url={final_url}; {len(locations)} canonical URLs; foreign={foreign}"
        return Check(url, status, final_url, ok, detail)
    except (urllib.error.URLError, TimeoutError, ElementTree.ParseError) as error:
        return Check(url, None, None, False, str(error))


def check_deployment(expected_revision: str, timeout: float) -> Check:
    url = f"{CANONICAL_ORIGIN}/deployment.json"
    try:
        status, final_url, body, _ = fetch(url, timeout)
        document = json.loads(body)
        actual_revision = document.get("sourceRevision")
        ok = status == 200 and final_url == url and actual_revision == expected_revision
        detail = f"sourceRevision={actual_revision!r}; expected={expected_revision!r}"
        return Check(url, status, final_url, ok, detail)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, TypeError) as error:
        return Check(url, None, None, False, str(error))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=float, default=20)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--expect-revision")
    args = parser.parse_args()

    checks = [
        check_redirect("http://bookquotes.uk/", f"{CANONICAL_ORIGIN}/", args.timeout),
        check_redirect("https://www.bookquotes.uk/", f"{CANONICAL_ORIGIN}/", args.timeout),
        check_redirect("http://www.bookquotes.uk/", f"{CANONICAL_ORIGIN}/", args.timeout),
        check_homepage(args.timeout),
        check_text(f"{CANONICAL_ORIGIN}/robots.txt", [b"Sitemap: https://bookquotes.uk/sitemap.xml"], args.timeout),
        check_sitemap(args.timeout),
    ]
    if args.expect_revision:
        checks.append(check_deployment(args.expect_revision, args.timeout))

    if args.json:
        print(json.dumps([asdict(check) for check in checks], indent=2))
    else:
        for check in checks:
            print(f"{'PASS' if check.ok else 'FAIL'} {check.url} — {check.detail}")
    return 0 if all(check.ok for check in checks) else 1


if __name__ == "__main__":
    sys.exit(main())
