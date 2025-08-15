# Bootstrap System

The bootstrap system ensures all prerequisites for Azure RBAC export scripts are installed and properly configured across Windows, macOS, and Linux platforms.

## 🎯 Purpose

- **Self-healing prerequisites**: Automatically install/verify required tools
- **Cross-platform support**: Works on Windows, macOS, and Linux
- **Zero-to-run experience**: Get from no tools to running scripts in one command
- **Corporate proxy aware**: Respects HTTPS_PROXY/HTTP_PROXY environment variables
- **Non-interactive mode**: Supports automation and CI/CD pipelines

## 📁 Directory Structure

```
/scripts/bootstrap/
├── Install-Prereqs.ps1     # Main bootstrap script
├── doctor.ps1             # Read-only status report
├── versions.json          # Single source of truth for versions
└── README.md              # This file
```

## 🚀 Quick Start

### Interactive Bootstrap (Recommended)
```powershell
# From repository root
.\scripts\bootstrap\Install-Prereqs.ps1
```

### Non-Interactive Bootstrap (Automation)
```powershell
# For CI/CD or unattended setups
.\scripts\bootstrap\Install-Prereqs.ps1 -NonInteractive
```

### Status Check Only
```powershell
# Read-only health check
.\scripts\bootstrap\doctor.ps1
```

## 🛠 What It Installs

### Core Runtimes
- **PowerShell 7.3+** (if below minimum)
- **Python 3.11+** (if below minimum)
- **Azure CLI 2.63+** (if missing)

### PowerShell Modules
- **Az.Accounts 3.0.0+** (required)
- **Az.Resources 7.5.0+** (required)
- **ImportExcel 7.8.6+** (optional, for XLSX exports)

### Python Environment
- **Virtual environment** (`.venv/`)
- **Pinned packages** from `scripts/azure/python/constraints.txt`
- **Development tools** (black, ruff, mypy, isort)

## ⚙️ Parameters

### Install-Prereqs.ps1

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-NonInteractive` | No prompts, fail on missing auto-install | `$false` |
| `-UpdateDeps` | Allow latest compatible versions | `$false` |
| `-DryRun` | Show what would be done without changes | `$false` |
| `-BootstrapLogPath` | Custom log directory | `logs/bootstrap` |

### doctor.ps1

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-BootstrapLogPath` | Custom log directory | `logs/bootstrap` |

## 📊 Exit Codes

| Code | Meaning | When |
|------|---------|------|
| `0` | Success | All checks passed |
| `1` | Failure | Critical errors (missing PowerShell, failed installs) |
| `2` | Partial | Warnings (missing context, outdated modules) |

## 🌐 Proxy Support

The bootstrap system respects standard proxy environment variables:

```bash
# Set before running bootstrap
export HTTPS_PROXY=http://proxy.company.com:8080
export HTTP_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1,.company.com
```

## 📋 Logging

All bootstrap operations are logged to:

```
logs/bootstrap/{YYYYMMDD}/
├── install_prereqs_{runId}.log      # Human-readable log
├── install_prereqs_{runId}.jsonl    # Structured JSON log
├── install_prereqs_{runId}_summary.json  # Summary report
├── doctor_{runId}.log               # Doctor check log
├── doctor_{runId}.jsonl             # Doctor JSON log
└── doctor_{runId}_summary.json      # Doctor summary
```

## 🧪 Development Workflow

### Update Versions
Edit `versions.json` to change minimum/pinned versions.

### Test Bootstrap
```powershell
# Dry run to see what would happen
.\scripts\bootstrap\Install-Prereqs.ps1 -DryRun

# Check current status
.\scripts\bootstrap\doctor.ps1
```

### Force Reinstall
```powershell
# Remove virtual environment and reinstall
Remove-Item .venv -Recurse -Force
.\scripts\bootstrap\Install-Prereqs.ps1
```

## 🤖 CI/CD Integration

```yaml
# GitHub Actions example
- name: Bootstrap prerequisites
  run: |
    pwsh -Command "./scripts/bootstrap/Install-Prereqs.ps1 -NonInteractive"
  shell: pwsh
```

## 📚 Integration with Export Scripts

Both Azure RBAC export scripts support the `-Bootstrap` / `--bootstrap` parameter:

```powershell
# PowerShell script will auto-bootstrap if needed
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -Bootstrap
```

```bash
# Python script will auto-bootstrap if needed  
python scripts/azure/python/export_rbac_roles_and_assignments.py --bootstrap
```

## 🔧 Troubleshooting

### Common Issues

1. **Permission denied**: Run as administrator/sudo for system-wide installs
2. **Package manager not found**: Install winget (Windows) or brew (macOS) first
3. **Proxy issues**: Ensure proxy variables are set in the same session
4. **Module conflicts**: Remove existing modules and let bootstrap reinstall

### Manual Override

If bootstrap fails, you can manually install prerequisites:

```bash
# PowerShell modules
Install-Module Az.Accounts -RequiredVersion 3.0.0 -Scope CurrentUser
Install-Module Az.Resources -RequiredVersion 7.5.0 -Scope CurrentUser

# Python packages
python -m venv .venv
.venv/bin/pip install -r scripts/azure/python/requirements.txt
```

## 📈 Version Pinning Strategy

- **Minimums**: Lowest supported versions in `versions.json`
- **Pinned versions**: Exact versions in `constraints.txt`
- **Development tools**: Latest compatible in `dev-requirements.txt`

This ensures reproducible builds while allowing flexibility for development.
