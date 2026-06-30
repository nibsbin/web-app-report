~~~
$quill: container_security_report@1.0.0
$kind: main
product: acme/widget-api
registry: harbor.example.mil
report_id: SR-2026-0042
prepared_by:
  name: J. Rivera
  role: Product Security Lead, ACME Platform
  email: security@acme.example

# §1 Variants — each its own immutable digest
variants:
  - name: full
    tag: "1.8.3"
    size: 82 MB
    digest: "sha256:3f1d9c0a8b7e6f5d4c3b2a1908f7e6d5c4b3a29180f7e6d5c4b3a29180f7e6d5"
  - name: airmark
    tag: 1.8.3-airmark
    size: 31 MB
    digest: "sha256:a1b2c3d4e5f6079889aabbccddeeff00112233445566778899aabbccddeeff00"

# §2 Harbor scan summary + Crit/High table
scan_summary:
  critical: 0
  high: 2
  medium: 4
  low: 9
  unknown: 1
cves:
  - id: CVE-2024-45491
    severity: High
    component: libexpat
    installed: 2.5.0-1
    fixed: 2.6.3-1
  - id: CVE-2024-6119
    severity: High
    component: openssl
    installed: 3.0.13-1
    fixed: 3.0.14-1

# Appendix A — every finding, all severities
all_cves:
  - id: CVE-2024-45491
    severity: High
    component: libexpat
    installed: 2.5.0-1
    fixed: 2.6.3-1
  - id: CVE-2024-6119
    severity: High
    component: openssl
    installed: 3.0.13-1
    fixed: 3.0.14-1
  - id: CVE-2024-2961
    severity: Medium
    component: glibc
    installed: 2.36-9
    fixed: 2.36-9+deb12u7
  - id: CVE-2023-31484
    severity: Low
    component: perl
    installed: 5.36.0-7
    fixed: ""
  - id: CVE-2024-0001
    severity: Unknown
    component: zlib1g
    installed: 1:1.2.13-1
    fixed: ""

# §3 SBOM — generated server-side by Harbor, recorded as a pointer
sbom:
  format: CycloneDX
  spec_version: 1.6 JSON
  digest: "sha256:9988776655443322110099887766554433221100998877665544332211009988"
  source: Harbor accessory — additions/sbom

# Appendix B — full SBOM component inventory
sbom_packages:
  - name: openssl
    version: 3.0.13-1
    type: deb
    license: Apache-2.0
  - name: libexpat1
    version: 2.5.0-1
    type: deb
    license: MIT
  - name: glibc
    version: 2.36-9
    type: deb
    license: LGPL-2.1-or-later
  - name: perl-base
    version: 5.36.0-7
    type: deb
    license: ""
  - name: tslib
    version: 2.6.2
    type: npm
    license: MIT

# §4 Build provenance — source pointer for the digest above
provenance:
  repo_url: https://github.com/acme/widget-api
  run_url: https://github.com/acme/widget-api/actions/runs/9876543210

# §5 As-of stamp
as_of:
  scan_date: "2026-06-28"
  harbor_version: Harbor v2.11.1
  scanner: Trivy
  trivy_version: "0.52.0"
  trivy_db: ver 2, updated 2026-06-28 06:14 UTC
~~~
