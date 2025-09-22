# Security Policy

## Reporting a Vulnerability

We take the security of Cosmian CLI seriously. If you discover a security vulnerability, please report it responsibly by following these steps:

### Private Reporting

Please do not report security vulnerabilities through public GitHub issues. Instead, please use one of the following methods:

1. GitHub Security Advisories (Preferred): Use the private vulnerability reporting feature on GitHub
   - <https://github.com/Cosmian/cli/security/advisories/new>
2. Email: Send details to <tech@cosmian.com>

### What to Include

When reporting a vulnerability, please include as much of the following information as possible:

- A clear description of the vulnerability
- Steps to reproduce the issue
- Potential impact of the vulnerability
- Suggested fix (if you have one)
- Your contact information

### Response Timeline

- Initial Response: We will acknowledge receipt of your vulnerability report within 48 hours
- Investigation: We will investigate and validate the vulnerability within 5 business days
- Fix Development: We will work to develop and test a fix as quickly as possible
- Disclosure: We will coordinate the disclosure timeline with you

## Known Security Advisories

The following table lists security advisories that are currently being tracked or have been assessed for this project (as configured in `deny.toml`):

| ID                | Description                                                            | Status  | Reason                                                                                                      |
| ----------------- | ---------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------- |
| RUSTSEC-2023-0071 | RSA Marvin Attack: potential key recovery through timing side channels | Ignored | Temporary; waiting for upstream fix.                                                                        |
| RUSTSEC-2024-0436 | Transitive dependency (`paste`) unmaintained in `agnostic_lite`        | Ignored | Temporary; pending upstream migration to `pastry`. Tracked at <https://github.com/al8n/agnostic/issues/26>. |

### Advisory Details

- RUSTSEC-2023-0071: The `rsa` crate is affected by a timing side-channel vulnerability known as the Marvin Attack, which could potentially allow key recovery. This advisory is currently ignored in our tracking as we await an upstream fix.
- RUSTSEC-2024-0436: `paste` is no longer maintained. The advisory surfaces via a transitive dependency chain in `agnostic_lite`. Upstream is expected to migrate to `pastry`; we are tracking progress and will update when available.

Note: `cargo-deny` may report issues from optional or feature-gated dependencies because our configuration collects metadata with all features enabled (see `deny.toml`), even if those dependencies aren't compiled in release builds.

## Security Best Practices

When using Cosmian CLI, we recommend:

1. Keep Updated: Always use the latest supported version
2. Secure Configuration: Follow the security configuration guidelines in our documentation
3. Network Security: Prefer secure endpoints (HTTPS/TLS) for KMS and Findex servers
4. Access Control: Implement proper authentication and authorization on connected services
5. Monitoring: Enable logging and monitoring for security events on your servers

## FIPS Considerations

Cosmian CLI can operate against Cosmian KMS built in FIPS mode. For FIPS-compliant deployments, ensure the target KMS uses OpenSSL 3.2.0 in FIPS mode and that your CLI is configured accordingly.

## Security Audits and Tooling

This project tracks and manages security advisories using `cargo-deny` and related tooling. Relevant configuration files include `deny.toml`. By configuration, `cargo-deny` collects metadata with all features enabled, which can surface advisories from optional dependencies for visibility; CI pipelines may run advisory and license checks.

## Contact

For general security questions or concerns, please contact us at <tech@cosmian.com>.

For immediate security issues, please use the private reporting methods described above.
