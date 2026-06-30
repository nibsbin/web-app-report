// =============================================================================
// Container Image Security Report — Quillmark plate (Typst backend)
// -----------------------------------------------------------------------------
// One report == one immutable digest set. The document data arrives from the
// Quillmark helper package as the `data` dictionary (populated from the
// markdown card-yaml frontmatter — see Quill.yaml for the field contract).
// Quillmark requires snake_case field keys, so every data field below is
// snake_case. This plate renders that data; it does not generate facts.
// =============================================================================

#import "@local/quillmark-helper:0.1.0": data

// --- Palette ----------------------------------------------------------------
// Restrained on purpose. Structure is navy; meaning is carried by exactly two
// semantic colors — danger (Critical/High, no-fix) and positive (clean scan).
// Everything else is ink or muted gray.
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
  v(s3)
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
               author: data.at("prepared_by", default: ("name": "")).name)
  set page(
    paper: "us-letter",
    margin: (x: 1.9cm, top: 2.2cm, bottom: 1.9cm),
    header: context {
      if counter(page).get().first() > 1 {
        grid(columns: (1fr, auto),
          text(size: 8pt, fill: muted)[#data.product — Report #data.report_id],
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
        text(size: 8pt, fill: muted)[Report #data.report_id],
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
  // Title carries the weight; the document type is a quiet subtitle and the
  // admin metadata is parked to the right so it isn't a third stacked line.
  block(width: 100%, breakable: false, {
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom), column-gutter: s3,
      text(size: 22pt, weight: "bold", fill: ink)[#data.product],
      align(right, text(size: 9pt, fill: muted)[
        Report #data.report_id \
        Issued #data.as_of.scan_date
      ]),
    )
    v(6pt)
    line(length: 100%, stroke: 0.75pt + accent)
  })
  v(s2)

  // At-a-glance summary strip (informational — no verdict) -----------------
  let s = data.scan_summary
  let blocking = s.critical + s.high
  panel({
    text(weight: "bold", fill: if blocking == 0 { ink } else { danger })[#blocking]
    text(size: 9pt, fill: muted)[ Critical / High]
    text(size: 9pt, fill: muted)[ #h(s2) · #h(s2) Scanned #data.as_of.scan_date]
  })

  // === §1 Image identity ==================================================
  section[1.][Images Covered]
  [
    Each image is identified by its immutable SHA256 digest. Tags are mutable and
    listed for convenience only.
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
    #strong[full] — complete runtime image. #strong[airmark] — minimized
    distroless variant for air-gapped & edge use.
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
    Critical and High only; Medium and Low are in the attached scan JSON.
  ]

  // === §3 Build provenance ================================================
  section[3.][Build Provenance]
  let p = data.provenance
  kv[Source][#link(p.repo_url)[#raw(p.repo_url)] \@ #raw(p.commit)]
  kv[CI run][#link(p.run_url)[#raw(p.run_url)]]
  v(s1)
  text(size: 8.5pt, fill: muted)[
    The build that produced the digest in §1 — traceable to its source commit
    and CI run.
  ]

  // === §4 As-of stamp ======================================================
  section[4.][Scan Metadata — As Of]
  let a = data.as_of
  grid(columns: (1fr, 1fr), column-gutter: s4,
    {
      kv[Scan date][#text(weight: "bold")[#a.scan_date]]
      kv[Harbor][#a.harbor_version]
      kv[Scanner][#a.scanner #a.trivy_version]
    },
    {
      kv[Trivy vuln DB][#a.trivy_db]
      kv[Report prepared by][#data.prepared_by.name, #data.prepared_by.role]
      kv[Contact][#link("mailto:" + data.prepared_by.email)[#data.prepared_by.email]]
    },
  )
  v(s1)
  text(size: 8pt, fill: muted, style: "italic")[
    Point-in-time scan; valid only for the digests in §1, as of #a.scan_date.
  ]
}

// --- Entry point ------------------------------------------------------------
// Render the document data supplied by the Quillmark Typst backend.
#show: _ => security-report(data)
