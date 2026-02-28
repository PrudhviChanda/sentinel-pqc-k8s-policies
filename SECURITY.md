# Security Policy

## Supported Versions

We actively provide security updates for the following versions of Sentinel-PQC:

| Version | Supported          |
| ------- | ------------------ |
| < 1.0.x | :white_check_mark: |
| < 0.9.x | :x:                |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

If you discover a way to bypass the Post-Quantum Admission Controller (e.g., a specific RSA key format that evades the regex/logic) or a vulnerability in the deployment automation, please report it through one of the following channels:

1. **GitHub Private Reporting:** Use the "Report a security vulnerability" feature on the Security tab of this repository.
2. **Email:** [Your Email Address or Security Alias]

### Our Response Process

1. **Acknowledgement:** You will receive an acknowledgement of your report within 48 hours.
2. **Validation:** We will coordinate with you to validate the finding and determine the severity (CVSS).
3. **Fix:** We aim to provide a patch or mitigation strategy within 7-14 days for high-severity issues.
4. **Disclosure:** Once a patch is available, we will issue a Security Advisory and credit you for the discovery (unless you prefer to remain anonymous).

## Security Philosophy

Sentinel-PQC is designed as a **fail-safe** mechanism. By default, the policies are configured to:
* **Fail Closed:** If the Kyverno engine is unavailable, requests for cryptographic resources are blocked (tunable in `values.yaml`).
* **Namespace Isolation:** Core Kubernetes namespaces (e.g., `kube-system`) are excluded by default to prevent control-plane deadlocks, prioritizing cluster stability.

## Third-Party Dependencies

This project relies on:
* **Kyverno:** Policy engine execution.
* **Prometheus Operator:** Metrics collection and scraping.

Vulnerabilities found in the underlying engines should be reported directly to the respective CNCF project maintainers.



