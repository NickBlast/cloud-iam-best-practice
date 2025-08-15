# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Azure RBAC export capability for Management Groups, Subscriptions, and Resource Groups
- PowerShell and Python implementations with identical functionality
- Shared logging libraries for structured logging (text + JSONL + summary JSON)
- Large tenant safety rails with confirmation thresholds
- Principal name resolution with caching and redaction options
- Per-subscription output partitioning for Confluence compatibility
- Multiple output formats: CSV (UTF-8 BOM), XLSX, Markdown, JSON
- Comprehensive documentation suite (runbooks, troubleshooting, Confluence guide)
- Enterprise security posture (SSO-only, read-only, no stored secrets)

### Changed
- Repository structure to accommodate scripts, docs, and common libraries
- README.md extended with Scripts Quickstart section
- Enhanced error handling with proper exit codes (0/1/2)

### Fixed
- Inherited assignment detection across scope levels
- UTC timestamp standardization across all outputs
- Cross-platform path normalization (Windows/Linux/macOS)

## [v0.1.0] - 2025-01-15

### Added
- Initial repository structure
- Azure RBAC export scripts (PowerShell and Python)
- Shared logging utilities
- Documentation framework
- Basic CI/CD placeholders

### Security
- SSO-only authentication patterns
- Read-only operation enforcement
- Safe mode enabled by default
- No stored secrets or credentials

---
*This CHANGELOG.md is part of the Cloud IAM Best Practice repository. Last updated: 2025*
