# Container Image Security Report — a Quillmark quill (Typst backend)

A professional, cookie-cutter security report that gives an ISSO everything they
need to assess a specific container image — and nothing they don't. It is purely
informational: it records facts about an image, it is not an approval or
authorization to operate. **One report == one immutable digest set.** Rebuild the
image, you get a new digest, you issue a new report.

This template is packaged as a [Quillmark](https://quillmark.dev) **quill** with
the **Typst** backend. The report is data-driven: a reusable quill
(`container_security_report/`) plus a small per-image Markdown document that
carries the data in its [card-yaml](https://quillmark.dev/reference/markdown-spec/)
frontmatter. Fill in the frontmatter, render, hand over the PDF.

```
acme/widget-api  →  examples/widget-api-1.8.3.md  →  widget-api-1.8.3.pdf
```

## What's in the report (keyed to one digest)

| § | Section | What the ISSO does with it |
|---|---------|----------------------------|
| 1 | **Images covered** — image name + immutable SHA256 digest, per variant (full + airmark) | Confirms the exact artifact under review |
| 2 | **Harbor vulnerability scan** — Critical/High counts + full Crit/High CVE table (CVE, severity, component, fixed version) | The headline artifact — the gate decision |
| 3 | **VEX** — for each *unfixed* Crit/High: not-affected (with justification) or remediation-with-date | Copies these rows straight into the POA&M |
| 4 | **SBOM** — CycloneDX/SPDX, attached | Answers "is log4j / openssl X in here?" |
| 5 | **Provenance + signature** — GitHub Actions build, cosign signature verifiable in Harbor | Proves the scanned image is the one you built |
| 6 | **Image hardening** — non-root, no shell/pkg-manager, Chainguard base | Three checkmarks, not a STIG |
| 7 | **As-of stamp** — Harbor + Trivy DB version + scan date | A scan without a date is worthless |

## Quill layout

```
container_security_report/          the quill bundle
├── Quill.yaml                       manifest: backend + field schema (the data contract)
└── plate.typ                        the reusable Typst layout (the "cookie cutter")
examples/widget-api-1.8.3.md         a worked document with realistic data
attachments/                         example SBOM the report points at (§4)
.github/workflows/build-report.yml   CI: render examples/ to PDF artifacts
```

- **`Quill.yaml`** declares `backend: typst`, points at `plate.typ`, and defines
  the `main.fields` schema — every field, its type, and an `example`. This is the
  authoritative contract for what a document must supply.
- **`plate.typ`** imports the document data from the Quillmark helper
  (`#import "@local/quillmark-helper:0.1.0": data`) and renders all seven
  sections from it. The report has no free-form prose body
  (`main.body.enabled: false`); every section is rendered from structured fields.

## Build

Render with the [Quillmark CLI](https://quillmark.dev/cli/reference/):

```sh
cargo install quillmark-cli   # once

# from the repo root:
quillmark render ./container_security_report examples/widget-api-1.8.3.md -o widget-api-1.8.3.pdf
```

CI renders every document under `examples/` on push — see
`.github/workflows/build-report.yml`. The compiled PDF is uploaded as an artifact.

## Authoring a new report

Copy `examples/widget-api-1.8.3.md` and edit the card-yaml frontmatter. The first
(and only) block is the root `$kind: main` card, bound to the quill with
`$quill: container_security_report@1.0.0`. The field contract (see `Quill.yaml`
for types and examples):

```
product           "acme/widget-api"                  registry repo path
registry          "harbor.example.mil"
report-id         "SR-2026-0042"
prepared-by       {name, role, email}

variants[]        {name, tag, size, digest}          §1 — one row per variant; digest is binding
scan-summary      {critical, high, medium, low, unknown}   §2 — counts for the badges
cves[]            {id, severity, component, installed,     §2 — every Crit/High finding
                   fixed}                                  fixed: "" if no fix yet
vex[]             {cve, variant, status, justification,    §3 — one per UNFIXED Crit/High
                   remediation-date}                       status ∈ openvex vocab
sbom              {format, spec-version, components,        §4
                   attached-as, digest}
provenance        {builder, workflow, repo, repo-url,       §5
                   commit, run-id, run-url, predicate-type}
signature         {identity, rekor, verify-cmd}             §5
hardening[]       ["Runs as non-root …", …]                 §6 — one checkmark each
as-of             {scan-date, harbor-version, scanner,       §7
                   trivy-version, trivy-db}
```

Notes:
- **`vex`** holds only the Crit/High findings *without an applied fix*. Use
  `status: not_affected` with an OpenVEX `justification`
  (e.g. `vulnerable_code_not_in_execute_path`) **or** `status: affected` /
  `under_investigation` with a `remediation-date`. If `vex` is empty the report
  prints a green "nothing for the POA&M" note.
- The summary strip reports the Critical+High and unfixed counts as plain facts;
  the report makes no approve/deny judgement.
- Keep the document's `cves`/`vex` consistent with the actual Harbor export —
  this quill renders facts, it does not generate them.
