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

# §3 Build provenance — source pointer for the digest above
provenance:
  repo_url: https://github.com/acme/widget-api
  commit: c0ffee1
  run_url: https://github.com/acme/widget-api/actions/runs/9876543210

# §4 As-of stamp
as_of:
  scan_date: "2026-06-28"
  harbor_version: Harbor v2.11.1
  scanner: Trivy
  trivy_version: "0.52.0"
  trivy_db: ver 2, updated 2026-06-28 06:14 UTC
~~~
