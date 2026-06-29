// =============================================================================
// Container Image Security Report — reusable Typst template
// -----------------------------------------------------------------------------
// One report == one immutable digest set. Instantiate by importing this file and
// calling `security-report(..)` with a data dictionary. See `reports/` for a
// worked example, and `README.md` for the field contract.
// =============================================================================

// --- Palette ----------------------------------------------------------------
// Restrained on purpose. Structure is navy; meaning is carried by exactly two
// semantic colors — danger (Critical/High, affected, no-fix) and positive
// (not-affected, satisfied checks). Everything else is ink or muted gray.
#let ink       = rgb("#1f2328")
#let muted     = rgb("#5b6470")
#let hairline  = rgb("#dfe3e8")
#let panel-bg  = rgb("#f7f8fa")
#let accent    = rgb("#16314f")
#let danger    = rgb("#b3261e")
#let positive  = rgb("#2f7d4f")

// Severity → text color. Only Critical/High are coloured; the rest are muted,
// because only Critical/High drive the decision.
#let sev-color(level) = (
  Critical: danger, High: danger,
  Medium: muted, Low: muted, Unknown: muted,
).at(level, default: muted)

// --- Spacing scale (4 / 8 / 12 / 16) + one panel inset ----------------------
#let s1  = 4pt
#let s2  = 8pt
#let s3  = 12pt
#let s4  = 16pt
#let pad = 10pt  // the single inset used by every panel

// --- Type-level labels (no containers — aligned, letter-spaced caps) ---------
#let tag(label, color) = text(fill: color, weight: "bold", size: 8pt, tracking: 0.5pt, upper(label))
#let sev-label(level) = tag(level, sev-color(level))
#let status-label(status) = {
  let c = if status == "not_affected" or status == "fixed" { positive }
          else if status == "affected" { danger } else { muted }
  tag(status.replace("_", " "), c)
}

// One panel language for every grouped callout: hairline outline only — no fill,
// barely-there radius. Quiet structure, not a coloured card.
#let panel(body) = block(width: 100%, radius: 2pt,
  inset: pad, stroke: 0.5pt + hairline, body)

// --- Small helpers ----------------------------------------------------------

// Monospace digest that wraps cleanly instead of overflowing the page. Insert
// zero-width spaces so the long hex hash can break across lines.
#let digest(d) = {
  let zws = "\u{200B}"
  let out = ""
  let i = 0
  for c in d.clusters() {
    out += c
    i += 1
    if calc.rem(i, 4) == 0 { out += zws }
  }
  text(font: "DejaVu Sans Mono", size: 8.5pt, fill: ink, out)
}

// One severity count, rendered as an aligned label-over-number stat.
#let stat-cell(label, value, color) = stack(spacing: 3pt,
  text(size: 7.5pt, fill: muted, weight: "medium", tracking: 0.6pt, upper(label)),
  text(size: 14pt, weight: "bold", fill: if value == 0 { muted } else { color })[#value],
)

// Section heading with a rule under it.
#let section(no, title) = {
  v(s2)
  block(width: 100%, breakable: false, {
    grid(columns: (auto, 1fr), column-gutter: s2, align: bottom,
      text(fill: accent, weight: "bold", size: 12pt)[#no],
      text(fill: ink, weight: "bold", size: 12pt)[#title],
    )
    v(3pt)
    line(length: 100%, stroke: 0.75pt + accent)
  })
  v(s1)
}

// Key/value definition row.
#let kv(k, v) = grid(
  columns: (32%, 1fr), column-gutter: 10pt, row-gutter: s1,
  text(fill: muted, weight: "medium")[#k], v,
)

// =============================================================================
// Main template
// =============================================================================
#let security-report(data) = {
  set document(title: "Security Report — " + data.product,
               author: data.at("prepared-by", default: ("name": "")).name)
  set page(
    paper: "us-letter",
    margin: (x: 1.9cm, top: 2.2cm, bottom: 1.9cm),
    header: context {
      if counter(page).get().first() > 1 {
        grid(columns: (1fr, auto),
          text(size: 8pt, fill: muted)[#data.product — Report #data.report-id],
          text(size: 8pt, fill: muted, font: "DejaVu Sans Mono")[#data.variants.first().digest.slice(0, 19)…],
        )
        v(1pt)
        line(length: 100%, stroke: 0.5pt + hairline)
      }
    },
    footer: context {
      line(length: 100%, stroke: 0.5pt + hairline)
      v(1pt)
      grid(columns: (1fr, auto),
        text(size: 8pt, fill: muted)[Report #data.report-id],
        align(right, text(size: 8pt, fill: muted)[Page #context counter(page).display() of #context counter(page).final().first()]),
      )
    },
  )
  // Sans-serif, left-aligned body — the Linear-leaning foundation.
  set text(font: ("Liberation Sans", "DejaVu Sans"), size: 10pt, fill: ink)
  set par(justify: false, leading: 0.62em, spacing: 6pt)
  show raw: set text(font: "DejaVu Sans Mono")
  show heading: set text(fill: accent)
  // Header fill via the `fill` function (a `set table.cell(fill: ..)` show rule
  // silently no-ops on header cells, leaving white-on-white labels).
  set table(
    stroke: 0.5pt + hairline,
    inset: 6pt,
    fill: (x, y) => if y == 0 { accent },
  )
  show table.cell.where(y: 0): set text(weight: "bold", fill: white, size: 8.5pt)

  // --- Cover masthead (left-anchored) ---------------------------------------
  block(width: 100%, breakable: false, {
    text(size: 9pt, fill: muted, tracking: 1.5pt)[CONTAINER IMAGE SECURITY REPORT]
    v(3pt)
    text(size: 22pt, weight: "bold", fill: ink)[#data.product]
    v(2pt)
    text(size: 10pt, fill: muted)[Registry #data.registry · Report #data.report-id · Issued #data.as-of.scan-date]
    v(6pt)
    line(length: 100%, stroke: 0.75pt + accent)
  })
  v(s2)

  // At-a-glance summary strip (informational — no verdict) -----------------
  let s = data.scan-summary
  let blocking = s.critical + s.high
  panel({
    text(size: 9pt, fill: muted)[Critical + High findings ]
    text(weight: "bold", fill: if blocking == 0 { ink } else { danger })[#blocking]
    text(size: 9pt, fill: muted)[   ·   Unfixed Critical/High ]
    text(weight: "bold", fill: if data.vex.len() == 0 { ink } else { danger })[#data.vex.len()]
    text(size: 9pt, fill: muted)[   ·   Scanned ]
    text(weight: "bold")[#data.as-of.scan-date]
    text(size: 9pt, fill: muted)[ with #data.as-of.scanner #data.as-of.trivy-version, DB #data.as-of.trivy-db]
    linebreak()
    text(size: 9pt, fill: muted)[Records the scan results for the immutable digests in §1. Any rebuild produces a new digest and requires a new report.]
  })

  // === §1 Image identity ==================================================
  section[1.][Images Covered]
  [
    This report describes #emph[only] the exact images below, identified by
    immutable SHA256 digest. Tags are mutable and are listed for convenience
    only — the digest is the binding identifier.
  ]
  v(s1)
  table(
    columns: (1.8cm, 3.2cm, 1fr, 1.4cm),
    align: left + horizon,
    table.header[Variant][Tag][Image \@ Digest][Size],
    ..data.variants.map(vr => (
      [#vr.name], [#vr.tag],
      digest(data.registry + "/" + data.product + "\@" + vr.digest),
      [#vr.size],
    )).flatten()
  )
  v(s1)
  text(size: 8.5pt, fill: muted)[
    #strong[full] — complete runtime image. #strong[airmark] —
    minimized/distroless variant for air-gapped & edge deployment. Each variant
    carries its own digest; both are covered by this single report.
  ]

  // === §2 Vulnerability scan (the headline artifact) ======================
  section[2.][Harbor Vulnerability Scan Results]
  grid(columns: (auto,) * 6, column-gutter: 1.3cm,
    stat-cell("Critical", s.critical, danger),
    stat-cell("High", s.high, danger),
    stat-cell("Medium", s.medium, muted),
    stat-cell("Low", s.low, muted),
    stat-cell("Unknown", s.unknown, muted),
    stat-cell("Total", s.critical + s.high + s.medium + s.low + s.unknown, ink),
  )
  v(s2)
  [Full enumeration of all Critical and High findings (the gate-relevant set):]
  v(s1)
  table(
    columns: (2.9cm, 1.6cm, 1fr, 2.6cm),
    align: left + horizon,
    table.header[CVE][Severity][Component \@ Version][Fixed Version],
    ..data.cves.map(c => (
      link("https://nvd.nist.gov/vuln/detail/" + c.id,
        text(fill: accent, c.id)),
      sev-label(c.severity),
      [#raw(c.component) #h(2pt) #text(fill: muted)[#c.installed]],
      if c.fixed == "" { text(fill: muted)[—] } else { raw(c.fixed) },
    )).flatten()
  )
  v(s1)
  text(size: 8.5pt, fill: muted)[
    Severity as adjudicated by Harbor (Trivy). Only Critical/High shown; the full
    Medium/Low set is in the attached SBOM-linked scan JSON (§7).
  ]

  // === §3 Vendor statement + VEX ==========================================
  section[3.][VEX — Unfixed Critical / High]
  [
    For every Critical/High finding #emph[without an applied fix], the VEX
    assertion below states whether it is exploitable and, where remediation is
    planned, the target date. These rows can be transcribed directly into a
    POA&M. Statuses use OpenVEX vocabulary.
  ]
  v(s1)
  if data.vex.len() == 0 {
    panel(text(fill: positive, weight: "bold")[
      ✓ No unfixed Critical/High findings. Nothing to carry into a POA&M.
    ])
  } else {
    for vx in data.vex {
      block(below: s2, panel({
        grid(columns: (1fr, auto), column-gutter: 10pt, align: horizon,
          link("https://nvd.nist.gov/vuln/detail/" + vx.cve,
            text(weight: "bold", fill: accent, size: 11pt, vx.cve)),
          {
            status-label(vx.status)
            h(8pt)
            text(size: 8.5pt, fill: muted)[#vx.variant]
          },
        )
        v(s1)
        if vx.status == "not_affected" {
          kv[Justification][#vx.justification]
        }
        if vx.at("remediation-date", default: "") != "" {
          kv[Remediation by][#text(weight: "bold")[#vx.remediation-date]]
        }
      }))
    }
  }

  // === §4 SBOM =============================================================
  section[4.][Software Bill of Materials (SBOM)]
  let b = data.sbom
  kv[Format][#b.format (#b.spec-version)]
  kv[Components inventoried][#b.components]
  kv[Attached as][#raw(b.attached-as)]
  kv[SBOM digest][#digest(b.digest)]
  v(s1)
  text(size: 9pt)[
    The SBOM is machine-readable and answers component-presence questions
    (e.g. "is log4j-core or openssl X present?") without re-scanning. It is
    attached to the image as an in-toto attestation and independently
    retrievable from the registry.
  ]

  // === §5 Provenance + signature ==========================================
  section[5.][Build Provenance & Signature]
  let p = data.provenance
  kv[Built by][#p.builder]
  kv[Workflow][#raw(p.workflow)]
  kv[Source][#link(p.repo-url, raw(p.repo)) \@ #raw(p.commit)]
  kv[Run][#link(p.run-url)[#raw(p.run-id)] · #p.predicate-type]
  let sg = data.signature
  kv[Signed with][cosign (keyless / #sg.identity)]
  kv[Transparency log][#raw(sg.rekor)]
  v(s1)
  panel(text(font: "DejaVu Sans Mono", size: 8pt, fill: ink)[#sg.verify-cmd])
  v(2pt)
  text(size: 8.5pt, fill: muted)[
    Verifying the signature against the digest in §1 proves the scanned image is
    the one this pipeline built — not a substitute.
  ]

  // === §6 Hardening ========================================================
  section[6.][Image Hardening]
  grid(columns: (1fr, 1fr), column-gutter: s3, row-gutter: 5pt,
    ..data.hardening.map(hf => box({
      text(fill: positive, weight: "bold")[✓]
      h(6pt)
      text(hf)
    }))
  )

  // === §7 As-of stamp ======================================================
  section[7.][Scan Metadata — As Of]
  let a = data.as-of
  grid(columns: (1fr, 1fr), column-gutter: s4,
    {
      kv[Scan date][#text(weight: "bold")[#a.scan-date]]
      kv[Harbor][#a.harbor-version]
      kv[Scanner][#a.scanner #a.trivy-version]
    },
    {
      kv[Trivy vuln DB][#a.trivy-db]
      kv[Report prepared by][#data.prepared-by.name, #data.prepared-by.role]
      kv[Contact][#link("mailto:" + data.prepared-by.email)[#data.prepared-by.email]]
    },
  )
  v(s1)
  text(size: 8pt, fill: muted, style: "italic")[
    A vulnerability scan is a point-in-time assertion. This report reflects the
    threat data available as of #a.scan-date and is valid only for the digests in §1.
  ]
}
