# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please follow these steps:

1. **Do NOT** create a public GitHub issue
2. Send details to the maintainers through GitHub Security Advisories
3. Include the following in your report:
   - Description of the vulnerability
   - Steps to reproduce
   - Possible impact
   - Suggested fix (if any)

### What to expect

- Acknowledgment of your report within 48 hours
- Regular updates on our progress
- Credit for responsible disclosure (unless you prefer to remain anonymous)

## Security Best Practices

When using this gem:

1. **API Key Management**
   - Never commit API keys to version control
   - Use environment variables or secure credential management
   - Rotate API keys regularly

2. **Dependencies**
   - Keep the gem updated to the latest version
   - Monitor security advisories
   - Use `bundle audit` to check for vulnerable dependencies

3. **Data Handling**
   - Be cautious with sensitive data in logs
   - Use HTTPS for all API communications
   - Implement proper error handling to avoid information leakage

## Security Features

This gem includes:
- Automatic API key masking in logs
- SSL/TLS verification by default
- Rate limiting protection
- Input validation and sanitization

## Contact

For security concerns, please use GitHub Security Advisories or contact the maintainers directly through GitHub.