# Security Checklist for Contributors

Please review this checklist before submitting any pull request that:
- Adds or updates dependencies
- Modifies build/CI configuration
- Handles sensitive data
- Changes security-related code

## Pre-Submission Checklist

### 📋 General Security
- [ ] No hardcoded secrets, API keys, or passwords
- [ ] No sensitive information in commit messages
- [ ] Code follows security best practices
- [ ] All user inputs are properly validated
- [ ] Error messages don't leak sensitive information

### 🔗 Dependencies
- [ ] New dependencies are minimal and necessary
- [ ] Dependency sources are verified and trustworthy
- [ ] Dependencies are pinned to exact versions
- [ ] `scripts/verify-dependencies.sh` passes
- [ ] No vulnerable dependencies (check GitHub security alerts)

### 🔧 Build & CI
- [ ] GitHub Actions use pinned versions (@v4, not @main)
- [ ] No secrets in CI logs or artifacts
- [ ] Build process is reproducible
- [ ] Security checks pass in CI

### 🛡️ Runtime Security
- [ ] Minimal permissions requested
- [ ] No unnecessary network connections
- [ ] User data stays local
- [ ] Proper memory management (no leaks)

### 📝 Documentation
- [ ] Security implications documented
- [ ] CHANGELOG.md updated if security-relevant
- [ ] README updated if new security features

## Testing Security Changes

Run these commands before submitting:

```bash
# Run all security checks
make security

# Verify dependencies
make verify-deps

# Check for secrets
gitleaks detect --config .gitleaks.toml --source . -v

# Run full test suite
make test
```

## Questions to Ask

1. **Does this change increase the attack surface?**
2. **Could this introduce a supply chain vulnerability?**
3. **Are we handling user data securely?**
4. **Could this leak sensitive information?**
5. **Is the security/functionality trade-off justified?**

## Red Flags 🚩

Stop and get additional review if:
- Adding dependencies from unknown sources
- Disabling security checks
- Adding network functionality
- Handling credentials or keys
- Modifying CI/CD security controls

## Getting Help

If you're unsure about security implications:
1. Create a draft PR and ask for security review
2. Reference this checklist in your PR description
3. Tag security-conscious maintainers for review

Remember: **When in doubt, ask!** Security issues are much easier to prevent than to fix.