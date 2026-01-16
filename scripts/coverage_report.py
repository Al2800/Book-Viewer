#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description="Generate LCOV + HTML from xccov JSON.")
    parser.add_argument("--input", required=True, help="Path to xccov JSON")
    parser.add_argument("--lcov", required=True, help="Path to write LCOV output")
    parser.add_argument("--html", required=True, help="Path to write HTML summary")
    parser.add_argument("--thresholds", default=None, help="Optional JSON thresholds file")
    return parser.parse_args()


def extract_line_coverage(lines):
    if not lines:
        return None
    executable = 0
    covered = 0
    for line in lines:
        if not line.get("isExecutable", False):
            continue
        executable += 1
        if line.get("executionCount", 0) > 0:
            covered += 1
    if executable == 0:
        return None
    return covered, executable


def collect_targets(data):
    targets = []
    for target in data.get("targets", []):
        target_name = target.get("name", "Unknown")
        target_files = []
        for f in target.get("files", []):
            file_path = f.get("path", "")
            lines = f.get("lines", [])
            coverage = extract_line_coverage(lines)
            target_files.append({
                "path": file_path,
                "lines": lines,
                "coverage": coverage,
            })
        targets.append({
            "name": target_name,
            "files": target_files,
        })
    return targets


def compute_totals(targets):
    covered = 0
    executable = 0
    for target in targets:
        for f in target["files"]:
            coverage = f["coverage"]
            if coverage is None:
                continue
            covered += coverage[0]
            executable += coverage[1]
    return covered, executable


def write_lcov(lcov_path, targets):
    lines = []
    for target in targets:
        for f in target["files"]:
            if not f["path"]:
                continue
            lines.append("TN:\n")
            lines.append(f"SF:{f['path']}\n")
            for line in f["lines"]:
                if not line.get("isExecutable", False):
                    continue
                number = line.get("lineNumber")
                count = line.get("executionCount", 0)
                if number is None:
                    continue
                lines.append(f"DA:{number},{count}\n")
            lines.append("end_of_record\n")
    Path(lcov_path).write_text("".join(lines), encoding="utf-8")


def percent(covered, executable):
    if executable == 0:
        return 0.0
    return (covered / executable) * 100.0


def write_html(html_path, targets):
    total_covered, total_executable = compute_totals(targets)
    total_percent = percent(total_covered, total_executable)

    rows = []
    for target in targets:
        target_covered, target_executable = 0, 0
        for f in target["files"]:
            coverage = f["coverage"]
            if coverage is None:
                continue
            target_covered += coverage[0]
            target_executable += coverage[1]
        rows.append((target["name"], target_covered, target_executable, percent(target_covered, target_executable)))

    html = [
        "<!doctype html>",
        "<html lang='en'>",
        "<head>",
        "  <meta charset='utf-8'>",
        "  <title>Coverage Summary</title>",
        "  <style>",
        "    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 24px; }",
        "    table { border-collapse: collapse; width: 100%; }",
        "    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }",
        "    th { background: #f4f4f4; }",
        "  </style>",
        "</head>",
        "<body>",
        f"  <h1>Coverage Summary</h1>",
        f"  <p>Total: {total_covered}/{total_executable} lines ({total_percent:.2f}%)</p>",
        "  <table>",
        "    <tr><th>Target</th><th>Covered</th><th>Executable</th><th>Percent</th></tr>",
    ]
    for name, covered, executable, pct in rows:
        html.append(f"    <tr><td>{name}</td><td>{covered}</td><td>{executable}</td><td>{pct:.2f}%</td></tr>")
    html.extend(["  </table>", "</body>", "</html>"])

    Path(html_path).write_text("\n".join(html), encoding="utf-8")


def load_thresholds(path):
    if path is None:
        return None
    threshold_path = Path(path)
    if not threshold_path.exists():
        return None
    return json.loads(threshold_path.read_text(encoding="utf-8"))


def enforce_thresholds(thresholds, targets):
    if not thresholds:
        return
    failures = []
    total_covered, total_executable = compute_totals(targets)
    total_pct = percent(total_covered, total_executable) / 100.0

    overall_threshold = thresholds.get("overall")
    if overall_threshold is not None and total_pct < overall_threshold:
        failures.append(f"overall {total_pct:.3f} < {overall_threshold:.3f}")

    target_thresholds = thresholds.get("targets", {})
    for target in targets:
        threshold = target_thresholds.get(target["name"])
        if threshold is None:
            continue
        covered, executable = 0, 0
        for f in target["files"]:
            coverage = f["coverage"]
            if coverage is None:
                continue
            covered += coverage[0]
            executable += coverage[1]
        pct = (percent(covered, executable) / 100.0) if executable > 0 else 0.0
        if pct < threshold:
            failures.append(f"{target['name']} {pct:.3f} < {threshold:.3f}")

    if failures:
        raise SystemExit("Coverage thresholds failed: " + ", ".join(failures))


def main():
    args = parse_args()
    data = json.loads(Path(args.input).read_text(encoding="utf-8"))
    targets = collect_targets(data)

    write_lcov(args.lcov, targets)
    write_html(args.html, targets)

    thresholds = load_thresholds(args.thresholds)
    enforce_thresholds(thresholds, targets)


if __name__ == "__main__":
    main()
