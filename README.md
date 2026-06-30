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
| 4 | **Build provenance** — source repo, commit, and CI run that produced the digest | Traces the scanned image back to its build |
| 5 | **Image hardening** — non-root, no shell/pkg-manager, Chainguard base | Three checkmarks, not a STIG |
| 6 | **As-of stamp** — Harbor + Trivy DB version + scan date | A scan without a date is worthless |

## Quill layout

```
container_security_report/          the quill bundle
├── Quill.yaml                       manifest: backend + field schema (the data contract)
└── plate.typ                        the reusable Typst layout (the "cookie cutter")
examples/widget-api-1.8.3.md         a worked document with realistic data
scripts/render.mjs                   renderer — drives @quillmark/wasm
package.json                         Node project: the @quillmark/wasm dependency
.github/workflows/build-report.yml   CI: render examples/ to PDF artifacts
```

- **`Quill.yaml`** declares `backend: typst`, points at `plate.typ`, and defines
  the `main.fields` schema — every field, its type, and an `example`. This is the
  authoritative contract for what a document must supply. Field keys are
  **snake_case** (a Quillmark validation requirement).
- **`plate.typ`** imports the document data from the Quillmark helper
  (`#import "@local/quillmark-helper:0.1.0": data`) and renders all six
  sections from it. The report has no free-form prose body
  (`main.body.enabled: false`); every section is rendered from structured fields.

## Build

Rendering goes through [`@quillmark/wasm`](https://www.npmjs.com/package/@quillmark/wasm)
— the Quillmark engine + Typst backend compiled to WebAssembly, so no Rust or
Typst toolchain is needed, only Node ≥ 22.

```sh
npm install            # once — pulls @quillmark/wasm

npm run render                                   # render every examples/*.md -> out/
node scripts/render.mjs examples/widget-api-1.8.3.md -o widget-api-1.8.3.pdf
node scripts/render.mjs -f svg examples/widget-api-1.8.3.md   # pdf | svg | png | txt
```

`scripts/render.mjs` reads the quill bundle into an in-memory tree
(`Quill.fromTree`), parses each document (`Document.fromMarkdown`), and renders
it with the WASM `Engine`. CI runs the same `npm run render` on push — see
`.github/workflows/build-report.yml`. The compiled PDF is uploaded as an artifact.

### PR previews

On a pull request, the `pr-preview` job rasterizes each report page to PNG
(`node scripts/render.mjs -f png`), publishes the images to the `pr-previews`
branch, and posts a sticky comment that embeds them inline — so a reviewer sees
the rendered report on the PR without downloading anything. The comment is
updated in place on every push, and links to the full PDF artifact. (Skipped on
fork PRs, whose tokens can't push the branch or comment.)

## Authoring a new report

Copy `examples/widget-api-1.8.3.md` and edit the card-yaml frontmatter. The first
(and only) block is the root `$kind: main` card, bound to the quill with
`$quill: container_security_report@1.0.0`. The field contract (see `Quill.yaml`
for types and examples):

```
product           "acme/widget-api"                  registry repo path
registry          "harbor.example.mil"
report_id         "SR-2026-0042"
prepared_by       {name, role, email}

variants[]        {name, tag, size, digest}          §1 — one row per variant; digest is binding
scan_summary      {critical, high, medium, low, unknown}   §2 — counts for the badges
cves[]            {id, severity, component, installed,     §2 — every Crit/High finding
                   fixed}                                  fixed: "" if no fix yet
vex[]             {cve, variant, status, justification,    §3 — one per UNFIXED Crit/High
                   remediation_date}                       status ∈ openvex vocab
provenance        {repo_url, commit, run_url}              §4 — build-source pointer
hardening[]       ["Runs as non-root …", …]                 §5 — one checkmark each
as_of             {scan_date, harbor_version, scanner,       §6
                   trivy_version, trivy_db}
```

Notes:
- **`vex`** holds only the Crit/High findings *without an applied fix*. Use
  `status: not_affected` with an OpenVEX `justification`
  (e.g. `vulnerable_code_not_in_execute_path`) **or** `status: affected` /
  `under_investigation` with a `remediation_date`. If `vex` is empty the report
  prints a green "nothing for the POA&M" note.
- **`provenance`** is traceability only — the source repo, commit, and CI run
  that produced the digest in §1. All three are known to the release pipeline.
- The summary strip reports the Critical+High and unfixed counts as plain facts;
  the report makes no approve/deny judgement.
- Keep the document's `cves`/`vex` consistent with the actual Harbor export —
  this quill renders facts, it does not generate them.
