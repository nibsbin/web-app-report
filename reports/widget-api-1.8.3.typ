// Worked example — instantiate the template with one image's data.
// `typst compile reports/widget-api-1.8.3.typ` -> PDF next to this file.
#import "../template/report.typ": security-report

#show: _ => security-report((
  product: "acme/widget-api",
  registry: "harbor.example.mil",
  report-id: "SR-2026-0042",

  prepared-by: (
    name: "J. Rivera",
    role: "Product Security Lead, ACME Platform",
    email: "security@acme.example",
  ),

  // ---- §1 Variants — each its own immutable digest ------------------------
  variants: (
    (
      name: "full", tag: "1.8.3", size: "82 MB",
      digest: "sha256:3f1d9c0a8b7e6f5d4c3b2a1908f7e6d5c4b3a29180f7e6d5c4b3a29180f7e6d5",
    ),
    (
      name: "airmark", tag: "1.8.3-airmark", size: "31 MB",
      digest: "sha256:a1b2c3d4e5f6079889aabbccddeeff00112233445566778899aabbccddeeff00",
    ),
  ),

  // ---- §2 Harbor scan summary + Crit/High table ---------------------------
  scan-summary: (critical: 0, high: 2, medium: 4, low: 9, unknown: 1),
  cves: (
    (
      id: "CVE-2024-45491", severity: "High",
      component: "libexpat", installed: "2.5.0-1",
      fixed: "2.6.3-1", fixed-available: false, variant: "full",
    ),
    (
      id: "CVE-2024-6119", severity: "High",
      component: "openssl", installed: "3.0.13-1",
      fixed: "3.0.14-1", fixed-available: true, variant: "full, airmark",
    ),
  ),

  // ---- §3 VEX / vendor statement for each UNFIXED Crit/High ---------------
  // (Only CVE-2024-45491 is unfixed; the openssl one was patched in this build.)
  vex: (
    (
      cve: "CVE-2024-45491", variant: "full",
      status: "not_affected",
      justification: "vulnerable_code_not_in_execute_path",
      statement: [libexpat is present only as a transitive dependency of the
        man-page tooling, which is stripped at runtime. No code path in
        widget-api invokes the affected XML_ParseBuffer overflow. A fix
        (2.6.3-1) will still be absorbed on the next monthly base rebase.],
      remediation-date: "2026-07-31",
    ),
  ),

  // ---- §4 SBOM ------------------------------------------------------------
  sbom: (
    format: "CycloneDX", spec-version: "1.6 JSON",
    components: "214 components (118 OS pkgs, 96 application)",
    attached-as: "in-toto attestation (predicate cyclonedx)",
    digest: "sha256:9988776655443322110099887766554433221100998877665544332211009988",
  ),

  // ---- §5 Provenance + signature ------------------------------------------
  provenance: (
    builder: "GitHub Actions (hosted runner, OIDC)",
    workflow: ".github/workflows/release.yml@refs/tags/v1.8.3",
    repo: "acme/widget-api", repo-url: "https://github.com/acme/widget-api",
    commit: "c0ffee1",
    run-id: "actions/runs/9876543210",
    run-url: "https://github.com/acme/widget-api/actions/runs/9876543210",
    predicate-type: "SLSA Provenance v1",
  ),
  signature: (
    identity: "GitHub OIDC, repo=acme/widget-api",
    rekor: "https://rekor.sigstore.dev (index 148820391)",
    verify-cmd: "cosign verify \\\n  --certificate-identity-regexp '^https://github.com/acme/widget-api' \\\n  --certificate-oidc-issuer https://token.actions.githubusercontent.com \\\n  harbor.example.mil/acme/widget-api@sha256:3f1d9c0a...e6d5",
  ),

  // ---- §6 Hardening facts -------------------------------------------------
  hardening: (
    [Runs as non-root (UID 65532, no setuid binaries)],
    [No shell and no package manager in the image],
    [Chainguard (Wolfi) distroless base, daily-rebuilt],
    [Read-only root filesystem compatible],
    [Minimal attack surface — airmark variant is 31 MB],
    [No secrets or build tooling in final layers],
  ),

  // ---- §7 As-of stamp -----------------------------------------------------
  as-of: (
    scan-date: "2026-06-28",
    harbor-version: "Harbor v2.11.1",
    scanner: "Trivy", trivy-version: "0.52.0",
    trivy-db: "ver 2, updated 2026-06-28 06:14 UTC",
  ),
))
