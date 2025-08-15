# Contributing to Cloud IAM Best Practice

Thank you for your interest in contributing to this repository! This document outlines the guidelines and processes for contributing to the Cloud IAM Best Practice repository.

## 📋 Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct focused on respectful, professional collaboration in the context of enterprise IAM practices.

## 🎯 Scope of Contributions

This repository focuses on:
- **IAM research and best practices** for multi-cloud financial environments
- **Secure, read-only reporting tools** for cloud platforms
- **Documentation and runbooks** for IAM operations
- **Compliance-aligned patterns** (FFIEC, NIST, CSA STAR)

Non-goals (please don't contribute these):
- Write operations or policy enforcement
- Stored secrets or authentication bypasses
- Headless automation or MFA workarounds
- Tenant-wide destructive operations

## 🛠 Development Standards

### PowerShell Development
- **PowerShell 7.3+** required
- Follow **PSScriptAnalyzer** rules (`Invoke-ScriptAnalyzer`)
- Use **comment-based help** for all functions
- Set `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`
- Include **parameter validation** and **error handling**

### Python Development
- **Python 3.11+** required
- Follow **black** formatting (`black .`)
- Use **ruff** for linting (`ruff check .`)
- Apply **isort** for imports (`isort .`)
- Type hints encouraged (loose mypy compliance)

### Git Commit Standards
- **Conventional Commits** format:
  - `feat: Add Azure RBAC export capability`
  - `fix: Resolve principal name caching issue`
  - `docs: Update troubleshooting guide`
  - `chore: Update dependencies`

### Branch Naming
- `feature/short-description`
- `fix/issue-description`
- `docs/documentation-update`

## 📁 Repository Structure

```
/ (repo root)
├─ .clinerules/          # Implementation contracts
├─ docs/                 # Research docs (do not modify existing)
│  ├─ runbooks/          # Operational guides (OK to add)
│  └─ design/            # Technical specifications
├─ scripts/              # Implementation code
│  ├─ common/            # Shared libraries
│  ├─ azure/             # Azure implementations
│  ├─ aws/               # AWS placeholders
│  └─ gcp/               # GCP placeholders
├─ README.md             # Repository overview
├─ CONTRIBUTING.md       # This file
├─ CHANGELOG.md          # Release history
├─ .gitignore            # Git ignore patterns
└─ .editorconfig         # Editor configuration
```

## 🔧 Development Workflow

### 1. Setup Development Environment

**PowerShell:**
```powershell
# Install required modules
Install-Module -Name Az.Accounts -Scope CurrentUser -Force
Install-Module -Name Az.Resources -Scope CurrentUser -Force
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force

# Optional for XLSX export
Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

**Python:**
```bash
# Install dependencies
pip install -r scripts/azure/python/requirements.txt

# Install development tools
pip install black ruff isort mypy

# Run linting
black .
ruff check .
isort .
```

### 2. Code Review Process

All contributions require review and follow these standards:

**Security Review:**
- ✅ No stored secrets or credentials
- ✅ Read-only operations only
- ✅ SSO authentication patterns
- ✅ Least privilege scope control

**Quality Review:**
- ✅ PSScriptAnalyzer / ruff compliance
- ✅ Proper error handling and logging
- ✅ Exit code standards (0/1/2)
- ✅ Documentation updates for new features

**Documentation Review:**
- ✅ Runbook updates for new capabilities
- ✅ Troubleshooting guide additions
- ✅ Confluence integration notes
- ✅ Logging schema consistency

### 3. Testing Requirements

**PowerShell Testing:**
```powershell
# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path ./scripts/azure/powershell/

# Test script execution (dry run)
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -Limit 1 -WhatIf
```

**Python Testing:**
```bash
# Run ruff linting
ruff check scripts/azure/python/

# Run black formatting check
black --check scripts/azure/python/

# Run isort import sorting check
isort --check-only scripts/azure/python/
```

## 📝 Documentation Standards

### Runbooks
- **Non-technical audience** focus
- **Step-by-step instructions**
- **Screenshot placeholders** for visual guidance
- **Prerequisites and examples**
- **Troubleshooting cross-references**

### Technical Documentation
- **Schema definitions** with examples
- **API references** with parameter details
- **Integration patterns** with use cases
- **Security considerations** and compliance notes

### Commit Messages
Follow **Conventional Commits** with these scopes:
- `azure` - Azure/Entra implementations
- `aws` - AWS implementations
- `gcp` - GCP implementations
- `common` - Shared libraries and utilities
- `docs` - Documentation and runbooks
- `ci` - Continuous integration
- `chore` - Maintenance tasks

## 🚀 Release Process

### Versioning
- **Keep a Changelog** format
- **Semantic Versioning** (v0.1.0, v1.0.0, etc.)
- **Pre-release versions** for experimental features

### CHANGELOG.md Updates
```markdown
## [v0.2.0] - 2025-01-15
### Added
- feat(azure): Add group member expansion capability
- feat(common): Add JSON export option

### Changed
- fix(azure): Improve inherited assignment detection
- docs: Update troubleshooting guide
```

## 🤝 Getting Help

### Questions and Discussion
- **GitHub Issues** for bugs and feature requests
- **Internal Slack** #cloud-iam-research for quick questions
- **Weekly IAM Leadership** meetings for strategic discussions

### Reporting Security Issues
- **Security team contact** for sensitive matters
- **Private GitHub issue** for non-critical security improvements
- **Do not** post security issues in public forums

## 📈 Contribution Recognition

Contributors will be recognized in:
- **CHANGELOG.md** release notes
- **Repository documentation** acknowledgments
- **Quarterly IAM team** highlights
- **Internal innovation** programs

## 📄 License

By contributing, you agree that your contributions will be licensed under the repository's license (Proprietary – Internal Use Only).

## 🔄 Updates to This Guide

This contributing guide may be updated periodically. Major changes will be communicated through:
- **Team announcements**
- **Repository updates**
- **Monthly IAM meetings**

---
*Last updated: 2025*

*This CONTRIBUTING.md is part of the Cloud IAM Best Practice repository.*
