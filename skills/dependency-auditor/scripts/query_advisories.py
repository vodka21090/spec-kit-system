#!/usr/bin/env python3
"""Batch version-aware vulnerability lookup against OSV (no auth required).

OSV aggregates the GitHub Advisory Database (and others) and answers the precise
question "is THIS version of THIS package affected?" — which is exactly the
triage question this skill needs. Each returned advisory carries its GHSA id in
`aliases`, so results map straight back to the GitHub Advisory Database.

Usage:
    # npm packages as name@version
    python query_advisories.py --ecosystem npm lodash@4.17.20 minimist@1.2.0

    # Maven coordinates as group:artifact:version
    python query_advisories.py --ecosystem Maven \
        com.fasterxml.jackson.core:jackson-databind:2.9.10

    # read targets from a file (one per line) and emit JSON
    python query_advisories.py --ecosystem npm --input deps.txt --json

Output: a normalized findings list (text table by default, --json for machine
use). Confirm the `first_patched` against the GitHub Advisory Database GraphQL
API when a token is available — see references/github-advisory.md.
"""
import argparse
import json
import sys
import urllib.request

OSV_URL = "https://api.osv.dev/v1/query"


def parse_target(raw, ecosystem):
    """Return (package_name, version) for one CLI target."""
    raw = raw.strip()
    if not raw:
        return None
    if ecosystem == "npm":
        # name may contain a scope (@scope/name@version)
        at = raw.rfind("@")
        if at <= 0:
            raise ValueError(f"npm target must be name@version: {raw!r}")
        return raw[:at], raw[at + 1:]
    else:  # Maven: group:artifact:version
        parts = raw.rsplit(":", 1)
        if len(parts) != 2:
            raise ValueError(f"Maven target must be group:artifact:version: {raw!r}")
        return parts[0], parts[1]


def query_osv(name, version, ecosystem):
    payload = json.dumps(
        {"version": version, "package": {"name": name, "ecosystem": ecosystem}}
    ).encode()
    req = urllib.request.Request(
        OSV_URL, data=payload, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def first_patched(vuln):
    """Best-effort extraction of the first fixed version from an OSV record."""
    fixes = []
    for affected in vuln.get("affected", []):
        for rng in affected.get("ranges", []):
            for event in rng.get("events", []):
                if "fixed" in event:
                    fixes.append(event["fixed"])
    return sorted(set(fixes))


def ghsa_id(vuln):
    for alias in vuln.get("aliases", []):
        if alias.startswith("GHSA-"):
            return alias
    return vuln.get("id", "")


def cve_id(vuln):
    for alias in vuln.get("aliases", []):
        if alias.startswith("CVE-"):
            return alias
    return ""


def severity(vuln):
    # OSV "database_specific" often carries a severity label; fall back to CVSS.
    db = vuln.get("database_specific", {})
    if "severity" in db:
        return db["severity"]
    for s in vuln.get("severity", []):
        if s.get("type", "").startswith("CVSS"):
            return s.get("score", "")
    return "UNKNOWN"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--ecosystem", required=True, choices=["npm", "Maven"],
                    help="OSV ecosystem (npm or Maven)")
    ap.add_argument("--input", help="file with one target per line")
    ap.add_argument("--json", action="store_true", help="emit JSON")
    ap.add_argument("targets", nargs="*", help="name@version or group:artifact:version")
    args = ap.parse_args()

    raw_targets = list(args.targets)
    if args.input:
        with open(args.input) as fh:
            raw_targets += [ln for ln in fh.read().splitlines() if ln.strip()
                            and not ln.lstrip().startswith("#")]
    if not raw_targets:
        ap.error("no targets provided")

    findings = []
    for raw in raw_targets:
        parsed = parse_target(raw, args.ecosystem)
        if not parsed:
            continue
        name, version = parsed
        try:
            data = query_osv(name, version, args.ecosystem)
        except Exception as e:  # network/HTTP errors shouldn't kill the batch
            findings.append({"package": name, "version": version,
                             "error": str(e)})
            continue
        for vuln in data.get("vulns", []):
            findings.append({
                "package": name,
                "version": version,
                "ghsa": ghsa_id(vuln),
                "cve": cve_id(vuln),
                "severity": severity(vuln),
                "summary": vuln.get("summary", "")[:120],
                "first_patched": first_patched(vuln),
            })

    if args.json:
        print(json.dumps(findings, indent=2))
        return

    if not findings:
        print("No known advisories for the supplied versions.")
        return
    print(f"{'PACKAGE':<40} {'VERSION':<12} {'SEV':<10} {'GHSA':<20} FIXED")
    print("-" * 100)
    for f in findings:
        if "error" in f:
            print(f"{f['package']:<40} {f['version']:<12} ERROR: {f['error']}")
            continue
        fixed = ", ".join(f["first_patched"]) or "NONE"
        print(f"{f['package']:<40} {f['version']:<12} {str(f['severity']):<10} "
              f"{f['ghsa']:<20} {fixed}")


if __name__ == "__main__":
    main()
