# Container Image Security Report (Typst)

A professional, cookie-cutter security report that gives an ISSO everything they
need to assess a specific container image — and nothing they don't. It is purely
informational: it records facts about an image, it is not an approval or
authorization to operate. **One report == one immutable digest set.** Rebuild the
image, you get a new digest, you issue a new report.

The report is data-driven: a reusable template (`template/report.typ`) plus a
small per-image data file (`reports/<image>-<tag>.typ`). Fill in the dictionary,
compile, hand over the PDF.

```
acme/widget-api  →  reports/widget-api-1.8.3.typ  →  widget-api-1.8.3.pdf
```

## What's in the report (keyed to one digest)

| § | Section | What the ISSO does with it |
|---|---------|----------------------------|
| 1 | **Images covered** — image name + immutable SHA256 digest, per variant (full + airmark) | Confirms the exact artifact under review |
| 2 | **Harbor vulnerability scan** — Critical/High counts + full Crit/High CVE table (CVE, severity, component, fixed version, fixed-or-not) | The headline artifact — the gate decision |
| 3 | **Vendor statement & VEX** — for each *unfixed* Crit/High: not-affected (with justification) or remediation-with-date | Copies these rows straight into the POA&M |
| 4 | **SBOM** — CycloneDX/SPDX, attached | Answers "is log4j / openssl X in here?" |
| 5 | **Provenance + signature** — GitHub Actions build, cosign signature verifiable in Harbor | Proves the scanned image is the one you built |
| 6 | **Image hardening** — non-root, no shell/pkg-manager, Chainguard base | Three checkmarks, not a STIG |
| 7 | **As-of stamp** — Harbor + Trivy DB version + scan date | A scan without a date is worthless |

## Build

Requires [Typst](https://github.com/typst/typst) ≥ 0.12.

```sh
# from the repo root (so the template import resolves):
typst compile --root . reports/widget-api-1.8.3.typ

# live preview while editing data:
typst watch --root . reports/widget-api-1.8.3.typ
```

CI builds every report under `reports/` on push — see
`.github/workflows/build-report.yml`. The compiled PDF is uploaded as an artifact.

## Authoring a new report

Copy `reports/widget-api-1.8.3.typ` and edit the dictionary passed to
`security-report(..)`. The field contract:

```
product           "acme/widget-api"                  registry repo path
registry          "harbor.example.mil"
report-id         "SR-2026-0042"
prepared-by       (name, role, email)

variants[]        (name, tag, size, digest)          §1 — one row per variant; digest is binding
scan-summary      (critical, high, medium, low, unknown)   §2 — counts for the badges
cves[]            (id, severity, component, installed,     §2 — every Crit/High finding
                   fixed, fixed-available: bool, variant)
vex[]             (cve, variant, status, justification,    §3 — one per UNFIXED Crit/High
                   statement, remediation-date)            status ∈ openvex vocab
sbom              (format, spec-version, components,        §4
                   attached-as, digest)
provenance        (builder, workflow, repo, repo-url,       §5
                   commit, run-id, run-url, predicate-type)
signature         (identity, rekor, verify-cmd)             §5
hardening[]       ["Runs as non-root …", …]                 §6 — one checkmark each
as-of             (scan-date, harbor-version, scanner,       §7
                   trivy-version, trivy-db)
```

Notes:
- **`vex`** holds only the Crit/High findings *without an applied fix*. Use
  `status: "not_affected"` with an OpenVEX `justification`
  (e.g. `vulnerable_code_not_in_execute_path`) **or** `status: "affected"` /
  `"under_investigation"` with a `remediation-date`. If `vex` is empty the report
  prints a green "nothing for the POA&M" note.
- The summary strip reports the Critical+High and unfixed counts as plain facts;
  the report makes no approve/deny judgement.
- Keep the data file's `cves`/`vex` consistent with the actual Harbor export —
  this template renders facts, it does not generate them.

## Repo layout

```
template/report.typ                 reusable layout + styling (the "cookie cutter")
reports/widget-api-1.8.3.typ        worked example with realistic data
reports/widget-api-1.8.3.pdf        compiled output (committed for review)
attachments/                        example SBOM the report points at (§4)
.github/workflows/build-report.yml  CI: compile reports to PDF artifacts
```
