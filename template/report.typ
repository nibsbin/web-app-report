// =============================================================================
// Container Image Security Approval Report — reusable Typst template
// -----------------------------------------------------------------------------
// One report == one immutable digest set. Instantiate by importing this file and
// calling `security-report(..)` with a data dictionary. See `reports/` for a
// worked example, and `README.md` for the field contract.
// =============================================================================

// --- Palette ----------------------------------------------------------------
#let ink       = rgb("#1a1a1a")
#let muted     = rgb("#5b6470")
#let hairline  = rgb("#d7dce3")
#let panel-bg  = rgb("#f4f6f9")
#let accent    = rgb("#0b3d6b")

#let sev-colors = (
  Critical: rgb("#7a0c1f"),
  High:     rgb("#c0392b"),
  Medium:   rgb("#d98c00"),
  Low:      rgb("#b8a000"),
  Unknown:  rgb("#6b7280"),
  None:     rgb("#2e7d32"),
)

// --- Small helpers ----------------------------------------------------------

// Monospace digest that wraps cleanly instead of overflowing the page.
// Insert zero-width spaces so the long hex hash can break across lines, and use
// `highlight` (line-breakable) rather than `box` (non-breakable).
#let digest(d) = {
  let zws = "\u{200B}"
  let out = ""
  let i = 0
  for c in d.clusters() {
    out += c
    i += 1
    if calc.rem(i, 4) == 0 { out += zws }
  }
  highlight(fill: panel-bg, extent: 1pt, radius: 2pt,
    text(font: "DejaVu Sans Mono", size: 8.5pt, fill: ink, out))
}

// Coloured severity pill.
#let sev-badge(level, count: none) = {
  let c = sev-colors.at(level, default: muted)
  box(
    fill: c, inset: (x: 6pt, y: 2pt), radius: 3pt,
    text(fill: white, weight: "bold", size: 8.5pt,
      if count == none { upper(level) } else { upper(level) + "  " + str(count) }),
  )
}

// Yes/No/Verify chip used in tables.
#let chip(label, kind) = {
  let c = if kind == "good" { sev-colors.None }
          else if kind == "bad" { sev-colors.High }
          else { muted }
  box(fill: c, inset: (x: 5pt, y: 1.5pt), radius: 3pt,
    text(fill: white, weight: "bold", size: 8pt, label))
}

// Section heading with a rule under it.
#let section(no, title) = {
  v(4pt)
  block(width: 100%, breakable: false, {
    grid(columns: (auto, 1fr), column-gutter: 8pt, align: bottom,
      text(fill: accent, weight: "bold", size: 13pt)[#no],
      text(fill: ink, weight: "bold", size: 13pt)[#title],
    )
    v(-2pt)
    line(length: 100%, stroke: 1pt + accent)
  })
  v(2pt)
}

// Key/value definition row.
#let kv(k, v) = grid(
  columns: (32%, 1fr), column-gutter: 10pt, row-gutter: 4pt,
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
      grid(columns: (1fr, auto, 1fr),
        text(size: 8pt, fill: muted)[Report #data.report-id],
        text(size: 8pt, fill: muted, style: "italic")[Informational — not an authorization to operate],
        align(right, text(size: 8pt, fill: muted)[Page #context counter(page).display() of #context counter(page).final().first()]),
      )
    },
  )
  set text(font: ("Libertinus Serif", "DejaVu Serif"), size: 10pt, fill: ink)
  set par(justify: true, leading: 0.62em)
  show heading: set text(fill: accent)
  set table(stroke: 0.5pt + hairline, inset: 6pt)
  show table.cell.where(y: 0): set text(weight: "bold", fill: white, size: 8.5pt)
  show table.cell.where(y: 0): set table.cell(fill: accent)

  // --- Cover masthead -------------------------------------------------------
  v(6pt)
  block(width: 100%, breakable: false, {
    line(length: 100%, stroke: 1.5pt + accent)
    v(8pt)
    align(center, {
      text(size: 11pt, fill: muted, tracking: 2pt)[CONTAINER IMAGE SECURITY REPORT]
      v(2pt)
      text(size: 22pt, weight: "bold", fill: ink)[#data.product]
      v(2pt)
      text(size: 11pt, fill: muted)[Registry: #data.registry · Report #data.report-id · Issued #data.as-of.scan-date]
    })
    v(8pt)
    line(length: 100%, stroke: 1.5pt + accent)
  })
  v(8pt)

  // At-a-glance summary strip (informational — no verdict) -----------------
  let s = data.scan-summary
  let blocking = s.critical + s.high
  block(width: 100%, fill: panel-bg, radius: 4pt, inset: 10pt, stroke: 0.5pt + hairline, {
    text(size: 9pt, fill: muted)[Critical + High findings: ]
    text(weight: "bold")[#blocking]
    text(size: 9pt, fill: muted)[ · Unfixed Critical/High: ]
    text(weight: "bold")[#data.vex.len()]
    text(size: 9pt, fill: muted)[ · Scanned ]
    text(weight: "bold")[#data.as-of.scan-date]
    text(size: 9pt, fill: muted)[ · #data.as-of.scanner #data.as-of.trivy-version · DB #data.as-of.trivy-db]
    linebreak()
    text(size: 9pt, fill: muted)[This report records the scan results for the immutable digests in §1. Any rebuild produces a new digest and requires a new report. Informational only — it is not an approval or authorization to operate.]
  })
  v(6pt)

  // === §1 Image identity ==================================================
  section[1.][Images Covered]
  [
    This report describes *only* the exact images below, identified by immutable
    SHA256 digest. Tags are mutable and are listed for convenience only — the
    digest is the binding identifier.
  ]
  v(4pt)
  table(
    columns: (auto, auto, 1fr, auto),
    align: (x, y) => if y == 0 { center + horizon } else { left + horizon },
    table.header[Variant][Tag][Image \@ Digest][Size],
    ..data.variants.map(vr => (
      [#vr.name], [#vr.tag],
      digest(data.registry + "/" + data.product + "\@" + vr.digest),
      [#vr.size],
    )).flatten()
  )
  v(2pt)
  text(size: 8.5pt, fill: muted)[
    *full* — complete runtime image. *airmark* — minimized/distroless variant for
    air-gapped & edge deployment. Each variant carries its own digest; both are
    covered by this single report.
  ]

  // === §2 Vulnerability scan (the headline artifact) ======================
  section[2.][Harbor Vulnerability Scan Results]
  grid(columns: (auto,) * 6, column-gutter: 6pt, row-gutter: 6pt,
    sev-badge("Critical", count: s.critical),
    sev-badge("High", count: s.high),
    sev-badge("Medium", count: s.medium),
    sev-badge("Low", count: s.low),
    sev-badge("Unknown", count: s.unknown),
    chip("TOTAL " + str(s.critical + s.high + s.medium + s.low + s.unknown), "neutral"),
  )
  v(6pt)
  [Full enumeration of all Critical and High findings (the gate-relevant set):]
  v(3pt)
  table(
    columns: (auto, auto, 1fr, auto, auto, auto),
    align: (x, y) => if y == 0 { center + horizon } else { left + horizon },
    table.header[CVE][Severity][Component \@ Version][Fixed Version][Fixed?][Variant],
    ..data.cves.map(c => (
      link("https://nvd.nist.gov/vuln/detail/" + c.id,
        text(fill: accent, c.id)),
      sev-badge(c.severity),
      [#raw(c.component) #h(2pt) #text(fill: muted)[#c.installed]],
      if c.fixed == "" { text(fill: muted)[—] } else { raw(c.fixed) },
      if c.fixed-available { chip("YES", "good") } else { chip("NO", "bad") },
      [#c.variant],
    )).flatten()
  )
  v(2pt)
  text(size: 8.5pt, fill: muted)[
    Severity as adjudicated by Harbor (Trivy). Only Critical/High shown; the full
    Medium/Low set is in the attached SBOM-linked scan JSON (§7).
  ]

  // === §3 Vendor statement + VEX ==========================================
  section[3.][Vendor Statement & VEX — Unfixed Critical / High]
  [
    For every Critical/High finding *without an applied fix*, the statement below
    is the vendor's position. These rows can be transcribed directly into a
    POA&M. Justifications use OpenVEX status vocabulary.
  ]
  v(4pt)
  if data.vex.len() == 0 {
    block(fill: panel-bg, radius: 4pt, inset: 8pt, stroke: 0.5pt + hairline,
      text(fill: sev-colors.None, weight: "bold")[
        ✓ No unfixed Critical/High findings. Nothing to carry into a POA&M.
      ])
  } else {
    for vx in data.vex {
      block(width: 100%, breakable: false, fill: panel-bg, radius: 4pt,
        inset: 9pt, stroke: 0.5pt + hairline, below: 7pt, {
        grid(columns: (auto, 1fr), column-gutter: 10pt, align: horizon,
          link("https://nvd.nist.gov/vuln/detail/" + vx.cve,
            text(weight: "bold", fill: accent, size: 11pt, vx.cve)),
          {
            let kind = if vx.status == "not_affected" { "good" }
                       else if vx.status == "fixed" { "good" } else { "neutral" }
            chip(upper(vx.status), kind)
            h(4pt)
            text(size: 9pt, fill: muted)[#vx.variant]
          },
        )
        v(3pt)
        if vx.status == "not_affected" {
          kv[VEX justification][#vx.justification]
        }
        kv[Statement][#vx.statement]
        if vx.at("remediation-date", default: "") != "" {
          kv[Remediation by][#text(weight: "bold")[#vx.remediation-date]]
        }
      })
    }
  }

  // === §4 SBOM =============================================================
  section[4.][Software Bill of Materials (SBOM)]
  let b = data.sbom
  kv[Format][#b.format (#b.spec-version)]
  kv[Components inventoried][#b.components]
  kv[Attached as][#raw(b.attached-as)]
  kv[SBOM digest][#digest(b.digest)]
  v(3pt)
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
  v(2pt)
  let sg = data.signature
  kv[Signed with][cosign (keyless / #sg.identity)]
  kv[Transparency log][#raw(sg.rekor)]
  v(4pt)
  block(fill: rgb("#0d1b2a"), radius: 4pt, inset: 9pt, width: 100%,
    text(font: "DejaVu Sans Mono", size: 8pt, fill: rgb("#d7e3f0"))[
      #sg.verify-cmd
    ])
  v(2pt)
  text(size: 8.5pt, fill: muted)[
    Verifying the signature against the digest in §1 proves the scanned image is
    the one this pipeline built — not a substitute.
  ]

  // === §6 Hardening ========================================================
  section[6.][Image Hardening]
  grid(columns: (1fr, 1fr), column-gutter: 12pt, row-gutter: 6pt,
    ..data.hardening.map(hf => box(inset: (y: 2pt), {
      chip("✓", "good"); h(5pt); text(hf)
    }))
  )

  // === §7 As-of stamp ======================================================
  section[7.][Scan Metadata — As Of]
  let a = data.as-of
  grid(columns: (1fr, 1fr), column-gutter: 16pt,
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
  v(6pt)
  align(center, text(size: 8pt, fill: muted, style: "italic")[
    A vulnerability scan is a point-in-time assertion. This report reflects the
    threat data available as of #a.scan-date and is valid only for the digests in §1.
  ])
}
