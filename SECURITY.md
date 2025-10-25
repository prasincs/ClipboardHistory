# Security Policy

## Supported Versions

We actively support and provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability, please follow these steps:

1. **Do NOT** create a public GitHub issue
2. Email security details to the maintainers (create a GitHub issue with minimal details and mention you have security concerns)
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes

We will respond within 48 hours and work with you to resolve the issue promptly.

## Security Measures

### Supply Chain Security

- **Dependency Pinning**: All dependencies are pinned to exact versions (none currently required)
- **Dependency Verification**: Checksums are verified for any future dependencies
- **Minimal Dependencies**: We keep dependencies to a minimum (currently zero third-party runtime dependencies)
- **Regular Audits**: Dependency inventory is reviewed before any additions

### Code Security

- **Static Analysis**: SwiftLint checks for common issues
- **Code Review**: All changes require review before merging
- **Automated Testing**: Comprehensive test suite runs on all changes

### Build Security

- **Reproducible Builds**: Build process is deterministic
- **CI/CD Security**: GitHub Actions workflows use pinned versions
- **Artifact Integrity**: Build artifacts are verified

### Runtime Security

- **Minimal Permissions**: App requests only necessary permissions
- **Local Storage**: All data stays on the user's machine
- **No Network Access**: App doesn't connect to external services
- **Memory Safety**: Swift's memory safety features prevent common vulnerabilities

## Dependency Information

This project does not rely on external runtime dependencies. Any future dependency additions will be documented here with versioning and security notes.

## Security Best Practices for Contributors

1. **Keep Dependencies Minimal**: Only add dependencies that are absolutely necessary
2. **Pin Versions**: Always use exact versions for dependencies
3. **Verify Dependencies**: Run `scripts/verify-dependencies.sh` before committing
4. **Review Security**: Consider security implications of all code changes
5. **Update Responsibly**: When updating dependencies, review the changelog and diff

## Security Tools

- `scripts/verify-dependencies.sh` - Verifies dependency checksums
- SwiftLint - Static analysis for code quality and security
- GitHub Security Advisories - Automated vulnerability scanning

## Threat Model

### Assets
- User clipboard data
- User preferences and settings

### Threats
- Supply chain attacks via compromised dependencies
- Malicious code injection through build process
- Unauthorized access to clipboard data
- Data exfiltration

### Mitigations
- Dependency pinning and verification
- Code review process
- Minimal permissions model
- Local-only data storage
- Open source transparency

## Security Update Process

1. Security issue identified
2. Impact assessment
3. Fix developed and tested
4. Security advisory published (if needed)
5. Patch released with priority
6. Users notified through appropriate channels

## Contact

For security-related questions or concerns, please create a GitHub issue or contact the maintainers.