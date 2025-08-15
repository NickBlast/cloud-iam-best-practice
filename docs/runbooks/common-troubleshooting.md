# Common Troubleshooting Guide

## Authentication Issues

### "Not connected to Azure" / "Please run Connect-AzAccount"

**Problem:** Scripts report authentication failure.

**Solution:**
1. **PowerShell:**
   ```powershell
   Connect-AzAccount
   # Or for device authentication:
   Connect-AzAccount -UseDeviceAuthentication
   ```

2. **Python:**
   ```bash
   az login
   # Or for device authentication:
   az login --use-device-code
   ```

### "DefaultAzureCredential failed" / "AzureCliCredential failed"

**Problem:** Python script can't acquire authentication token.

**Solution:**
1. Verify Azure CLI is installed and in PATH
2. Run `az account show` to verify active subscription
3. If using corporate SSO, ensure browser session is active
4. Try `az login --tenant YOUR-TENANT-ID` for explicit tenant

### "Stale Azure CLI broker session"

**Problem:** Authentication tokens expired or corrupted.

**Solution:**
1. Clear Azure CLI cache:
   ```bash
   az account clear
   az login
   ```
2. Restart terminal/PowerShell session
3. For persistent issues, clear browser cookies for Azure/Entra ID

## Module Installation Issues

### PowerShell: "Az.Accounts module not found"

**Problem:** Required Azure PowerShell modules missing.

**Solution:**
```powershell
# Install required modules
Install-Module -Name Az.Accounts -Scope CurrentUser -Force
Install-Module -Name Az.Resources -Scope CurrentUser -Force

# Optional for XLSX export
Install-Module -Name ImportExcel -Scope CurrentUser -Force
```

### Python: "No module named 'azure'"

**Problem:** Required Python packages not installed.

**Solution:**
```bash
# Install from requirements file
pip install -r scripts/azure/python/requirements.txt

# Or install individually
pip install azure-identity azure-mgmt-authorization azure-mgmt-resource azure-mgmt-managementgroups

# Optional packages
pip install openpyxl msgraph-sdk
```

### "ImportExcel module not available"

**Problem:** XLSX export requested but module missing.

**Solution:**
```powershell
Install-Module -Name ImportExcel -Scope CurrentUser -Force
```
Or run without XLSX export (CSV only).

## Permission and Access Issues

### "Authorization failed" / "Insufficient privileges"

**Problem:** Principal lacks required permissions for RBAC enumeration.

**Required Permissions:**
- **Reader role** at target scopes (MG/Subscription/RG)
- **Directory Readers** or **Global Reader** for principal resolution
- **Management Group Reader** for MG traversal

**Solution:**
1. Request Reader role at target scopes
2. For principal resolution, request Directory Readers role
3. Verify access with:
   ```powershell
   Get-AzRoleAssignment -Scope "/subscriptions/YOUR-SUB-ID"
   ```

### "No management groups found or access denied"

**Problem:** Principal can't enumerate management groups.

**Solution:**
1. Verify Management Group Reader role at root MG
2. Use `-DiscoverSubscriptions` instead of `-TraverseManagementGroups`
3. Target specific subscriptions with `-Subscriptions`

### "No subscriptions found or accessible"

**Problem:** Principal has no subscription access.

**Solution:**
1. Verify subscription Reader role assignments
2. Check subscription state (not Disabled/Suspended)
3. Use `Get-AzSubscription` to list accessible subscriptions

## Throttling and Performance Issues

### "429 Too Many Requests" / Throttling errors

**Problem:** API rate limits exceeded during large tenant enumeration.

**Solutions:**
1. **Reduce concurrency:**
   ```bash
   --max-concurrency 2  # Python
   -MaxConcurrency 2    # PowerShell
   ```

2. **Use smoke testing:**
   ```bash
   --limit 5  # Python
   -Limit 5   # PowerShell
   ```

3. **Target specific subscriptions:**
   ```bash
   --subscriptions sub1,sub2
   -Subscriptions sub1,sub2
   ```

4. **Skip principal resolution for speed:**
   ```bash
   --no-resolve-principals  # Python
   -NoResolvePrincipals     # PowerShell
   ```

### "Operation timed out" / Long-running enumeration

**Problem:** Large tenant taking excessive time.

**Solutions:**
1. **Use subscription filtering:**
   ```bash
   --subscriptions PROD-SUB1,PROD-SUB2
   ```

2. **Avoid resource-level enumeration:**
   Don't use `--include-resources` / `-IncludeResources` unless necessary

3. **Monitor progress:**
   Check logs in `./logs/{YYYYMMDD}/` for real-time progress

## Large Tenant Performance

### "LARGE TENANT DETECTED - Safety rail triggered!"

**Problem:** Tenant exceeds safety thresholds.

**Solution:**
Add confirmation flag:
```bash
--confirm-large-scan  # Python
-ConfirmLargeScan     # PowerShell
```

### Memory issues with large datasets

**Problem:** Script consumes excessive memory with 100k+ assignments.

**Solutions:**
1. **Process in batches:**
   ```bash
   --subscriptions SUB1  # Target one subscription at a time
   ```

2. **Skip principal resolution:**
   ```bash
   --no-resolve-principals  # Python
   -NoResolvePrincipals     # PowerShell
   ```

3. **Use smoke testing for validation:**
   ```bash
   --limit 10  # Python
   -Limit 10   # PowerShell
   ```

## Graph and Principal Resolution Issues

### "Failed to resolve principal" / Name resolution errors

**Problem:** Graph API calls failing for user/group/service principal names.

**Solutions:**
1. **Verify Graph permissions:**
   - Directory Readers role required
   - Consent granted for Microsoft Graph API

2. **Skip resolution for speed:**
   ```bash
   --no-resolve-principals  # Python
   -NoResolvePrincipals     # PowerShell
   ```

3. **Check for deleted principals:**
   Some assignments may reference deleted users/groups

### "Microsoft Graph SDK not available"

**Problem:** msgraph-sdk package not installed.

**Solution:**
```bash
pip install msgraph-sdk
```

Or run without principal resolution.

## Output and File Issues

### "Permission denied" writing files

**Problem:** Script lacks write permissions to output directories.

**Solutions:**
1. Run from directory with write permissions
2. Use `--output-path` to specify writable location:
   ```bash
   --output-path ./my-output  # Python
   -OutputPath ./my-output    # PowerShell
   ```

3. Create directories manually:
   ```bash
   mkdir -p output logs
   ```

### "File too large for Confluence"

**Problem:** Single CSV exceeds Confluence import limits.

**Solutions:**
1. **Use per-subscription files:**
   Scripts automatically create `role_assignments_{SUBID}.csv`

2. **Limit Markdown export:**
   ```bash
   --markdown-top 100  # Python
   -MarkdownTop 100    # PowerShell
   ```

3. **Filter by subscriptions:**
   Target fewer subscriptions at once

## Network and Proxy Issues

### Proxy configuration

**Problem:** Corporate proxy blocking Azure API calls.

**Solutions:**
1. **Set environment variables:**
   ```bash
   export HTTPS_PROXY=http://proxy.company.com:8080
   export HTTP_PROXY=http://proxy.company.com:8080
   ```

2. **PowerShell proxy settings:**
   ```powershell
   $env:HTTPS_PROXY="http://proxy.company.com:8080"
   ```

3. **Azure CLI proxy:**
   ```bash
   az cloud set --name AzureCloud --profile latest
   ```

### "SSL certificate verify failed"

**Problem:** Corporate certificate inspection breaking TLS.

**Solutions:**
1. **Update certificate store:**
   - Install corporate root CA certificates
   - Update Python certificates: `pip install --upgrade certifi`

2. **Corporate network troubleshooting:**
   - Work with security team on certificate policies
   - Use approved network paths

## Exit Code Troubleshooting

### Exit Code 1 (Failure)

**Check:**
1. Authentication status (`az account show` or `Get-AzContext`)
2. Required modules/packages installed
3. Basic API connectivity (`Get-AzSubscription`)

### Exit Code 2 (Partial/Warnings)

**Check:**
1. Summary JSON for skipped scopes
2. Warning messages in logs
3. Permission boundaries at different scopes

### No output files generated

**Check:**
1. Script completed successfully (exit code 0)
2. Output directory exists and is writable
3. Check `./logs/` for error details

## Debugging and Logging

### Enable verbose logging

**PowerShell:**
```powershell
# Check detailed logs in ./logs/{YYYYMMDD}/
Get-Content -Path "./logs/*/azure_export_rbac_roles_and_assignments_*.log" -Tail 50
```

**Python:**
```bash
# Logs are in ./logs/{YYYYMMDD}/
tail -f ./logs/*/azure_export_rbac_roles_and_assignments_*.log
```

### Check structured logs

JSONL logs provide detailed structured information:
```bash
# View recent JSON log entries
jq . ./logs/20250101/azure_export_rbac_roles_and_assignments_*.jsonl | tail -10
```

## Version Compatibility Issues

### PowerShell version errors

**Problem:** "requires PowerShell 7.3+" error.

**Solution:**
1. Install PowerShell 7.3+ from [GitHub Releases](https://github.com/PowerShell/PowerShell/releases)
2. Verify version:
   ```powershell
   $PSVersionTable.PSVersion
   ```

### Python version errors

**Problem:** "Python 3.11+ required" errors.

**Solution:**
1. Install Python 3.11+ from [python.org](https://www.python.org/downloads/)
2. Verify version:
   ```bash
   python --version
   ```

## Corporate Environment Specific Issues

### SAML/SSO authentication loops

**Problem:** Authentication repeatedly prompting for credentials.

**Solutions:**
1. **Use device authentication:**
   ```bash
   az login --use-device-code  # Python
   Connect-AzAccount -UseDeviceAuthentication  # PowerShell
   ```

2. **Clear browser session:**
   - Close all browser windows
   - Clear Azure/Entra ID cookies
   - Restart authentication flow

### Conditional Access policies

**Problem:** MFA/Compliance policies blocking automation.

**Solutions:**
1. **Use interactive authentication:**
   Avoid headless/service principal authentication

2. **Work with security team:**
   - Request automation exemptions
   - Configure app registrations with proper consent

3. **Verify compliance status:**
   Ensure device is compliant with Intune/MDM policies

---
*This troubleshooting guide is part of the Cloud IAM Best Practice repository. Last updated: 2025*
