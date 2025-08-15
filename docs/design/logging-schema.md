# Logging Schema Documentation

## Overview

The Azure RBAC export scripts implement structured logging with multiple output formats to support both human operators and automated systems. This document defines the logging schema, file formats, and data structures used throughout the export process.

## Log File Structure

### Directory Layout
```
./logs/
└── {YYYYMMDD}/
    ├── azure_export_rbac_roles_and_assignments_{runId}.log
    ├── azure_export_rbac_roles_and_assignments_{runId}.jsonl
    └── azure_export_rbac_roles_and_assignments_{runId}_summary.json
```

### File Types

| File | Purpose | Format | Audience |
|------|---------|--------|----------|
| `.log` | Human-readable operational log | Text with timestamps | Operators, troubleshooting |
| `.jsonl` | Machine-parseable structured log | JSON Lines (NDJSON) | Automation, SIEM, analytics |
| `_summary.json` | Execution summary and metrics | JSON object | Reporting, monitoring |

## Text Log Format (.log)

### Structure
```
{timestamp} - {level} - {message}
```

### Example
```
2025-01-15 14:30:22 - INFO - Starting Azure RBAC export run 123e4567-e89b-12d3-a456-426614174000
2025-01-15 14:30:25 - INFO - Found 25 management groups
2025-01-15 14:30:30 - WARN - Failed to process management group mg-legacy: Access denied
2025-01-15 14:35:45 - INFO - Run completed successfully
```

### Fields
- **timestamp**: `YYYY-MM-DD HH:MM:SS` in local timezone
- **level**: `INFO`, `WARN`, `ERROR`
- **message**: Human-readable log message

## Structured Log Format (.jsonl)

### JSON Lines Structure
Each line is a complete JSON object. No commas between lines, no wrapping array.

### Schema
```json
{
  "ts": "ISO8601 UTC timestamp",
  "run_id": "UUID string",
  "script": "script identifier",
  "level": "INFO|WARN|ERROR",
  "event": "short event description",
  "detail": {
    "key": "additional structured data"
  }
}
```

### Example Entries
```json
{"ts":"2025-01-15T14:30:22Z","run_id":"123e4567-e89b-12d3-a456-426614174000","script":"azure/export_rbac_roles_and_assignments","level":"INFO","event":"Logging initialized","detail":{}}
{"ts":"2025-01-15T14:30:25Z","run_id":"123e4567-e89b-12d3-a456-426614174000","script":"azure/export_rbac_roles_and_assignments","level":"INFO","event":"Found management groups","detail":{"count":25}}
{"ts":"2025-01-15T14:30:30Z","run_id":"123e4567-e89b-12d3-a456-426614174000","script":"azure/export_rbac_roles_and_assignments","level":"WARN","event":"Failed to process management group","detail":{"name":"mg-legacy","error":"Access denied"}}
```

### Field Definitions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `ts` | string | UTC timestamp in ISO8601 format | `"2025-01-15T14:30:22Z"` |
| `run_id` | string | Unique UUID for this execution | `"123e4567-e89b-..."` |
| `script` | string | Script identifier | `"azure/export_rbac_roles_and_assignments"` |
| `level` | string | Log level | `"INFO"`, `"WARN"`, `"ERROR"` |
| `event` | string | Short event description | `"Found management groups"` |
| `detail` | object | Additional structured data | `{"count": 25}` |

### Common Event Types

#### Initialization Events
- `"Logging initialized"` - Script startup
- `"Performing preflight checks"` - Authentication verification
- `"Azure context found"` - Valid credentials detected

#### Discovery Events
- `"Found management groups"` - MG enumeration complete
- `"Found subscriptions"` - Subscription enumeration complete
- `"Found resource groups"` - RG enumeration complete

#### Processing Events
- `"Processing management groups"` - MG scope processing start
- `"Processing subscriptions"` - Subscription scope processing start
- `"Resolving principal names"` - Name resolution start
- `"Expanding group members"` - Group expansion start

#### Output Events
- `"Writing outputs"` - File writing start
- `"Wrote CSV file"` - CSV export complete
- `"Wrote XLSX file"` - XLSX export complete
- `"Wrote index file"` - Index generation complete

#### Completion Events
- `"Run completed successfully"` - Exit code 0
- `"Run completed with warnings"` - Exit code 2
- `"Run completed with errors"` - Exit code 1

## Summary JSON Format (_summary.json)

### Schema
```json
{
  "run_id": "UUID string",
  "start_time": "ISO8601 UTC timestamp",
  "end_time": "ISO8601 UTC timestamp",
  "duration_seconds": "number",
  "scopes_processed": {
    "managementGroups": "integer",
    "subscriptions": "integer",
    "resourceGroups": "integer"
  },
  "scopes_skipped": ["string array"],
  "roles_count": "integer",
  "assignments_count": "integer",
  "warnings": ["string array"],
  "errors": ["string array"],
  "success": "boolean",
  "credential_type": "string",
  "arguments": {
    "key": "value pairs of command line arguments"
  }
}
```

### Example
```json
{
  "run_id": "123e4567-e89b-12d3-a456-426614174000",
  "start_time": "2025-01-15T14:30:22Z",
  "end_time": "2025-01-15T14:35:45Z",
  "duration_seconds": 323.5,
  "scopes_processed": {
    "managementGroups": 25,
    "subscriptions": 150,
    "resourceGroups": 0
  },
  "scopes_skipped": [
    "MG:mg-legacy",
    "SUB:sub-deprecated"
  ],
  "roles_count": 1250,
  "assignments_count": 45200,
  "warnings": [
    "Failed to process management group mg-legacy: Access denied"
  ],
  "errors": [],
  "success": true,
  "credential_type": "DefaultAzureCredential",
  "arguments": {
    "subscriptions": ["sub1", "sub2"],
    "redact": true,
    "safe_mode": true
  }
}
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `run_id` | string | Unique execution identifier |
| `start_time` | string | UTC start timestamp |
| `end_time` | string | UTC end timestamp |
| `duration_seconds` | number | Total execution time |
| `scopes_processed` | object | Count of successfully processed scopes |
| `scopes_skipped` | array | List of skipped scopes with reasons |
| `roles_count` | integer | Total role definitions exported |
| `assignments_count` | integer | Total role assignments exported |
| `warnings` | array | Non-fatal warning messages |
| `errors` | array | Fatal error messages |
| `success` | boolean | Overall execution success |
| `credential_type` | string | Authentication method used |
| `arguments` | object | Copy of command-line arguments |

## Output File Schema

### Role Definitions CSV
```csv
roleDefinitionName,roleDefinitionId,isCustom,description,permissionsCount,assignableScopes
```

### Role Assignments CSV
```csv
scope,scopeType,subscriptionId,resourceGroup,roleDefinitionId,roleDefinitionName,assignmentId,principalId,principalType,principalDisplayName,principalUPNOrAppId,inherited,condition,conditionVersion,createdOn
```

### Expanded Group Members (when `--expand-group-members` used)
```csv
scope,scopeType,subscriptionId,resourceGroup,roleDefinitionId,roleDefinitionName,assignmentId,principalId,principalType,principalDisplayName,principalUPNOrAppId,inherited,condition,conditionVersion,createdOn,memberPrincipalId,memberType,memberDisplayName,memberUPN
```

## Index File Schema (index.json)

### Schema
```json
{
  "artifacts": {
    "role_definitions_csv": "string",
    "role_assignments_csv": "string",
    "role_assignments_xlsx": "string or null",
    "role_assignments_md": "string or null"
  },
  "row_counts": {
    "role_definitions": "integer",
    "role_assignments": "integer"
  },
  "per_subscription": {
    "subscription_id": "integer"
  }
}
```

## UTC Timestamp Standards

All timestamps in logs and outputs follow these standards:

### Format
- **ISO8601**: `YYYY-MM-DDTHH:MM:SSZ`
- **Timezone**: Always UTC (denoted by `Z`)
- **Precision**: Seconds (microseconds truncated)

### Examples
- ✅ `"2025-01-15T14:30:22Z"`
- ❌ `"2025-01-15 14:30:22"` (missing T/Z)
- ❌ `"2025-01-15T14:30:22.123456Z"` (microseconds)

## Redaction Policy

When `--redact` / `-Redact` flag is used:

### Redacted Fields
- `principalUPNOrAppId` → `"[REDACTED]"`
- `memberUPN` → `"[REDACTED]"`
- `principalDisplayName` → `"[REDACTED]"` (in logs only)

### Log Redaction
- UPNs/AppIds in log messages are also redacted
- Principal names in debug logs are redacted
- Error messages containing PII are sanitized

## Exit Code Mapping

| Exit Code | JSON Success | Log Message | Meaning |
|-----------|--------------|-------------|---------|
| `0` | `true` | `"Run completed successfully"` | All operations successful |
| `1` | `false` | `"Run completed with {n} errors"` | Critical failures |
| `2` | `true` | `"Run completed with {n} warnings"` | Partial success with warnings |

## PowerShell vs Python Consistency

Both implementations use identical schemas to ensure:

### Matching Fields
- Identical CSV column names and order
- Same JSON structure for logs and outputs
- Consistent timestamp formats
- Equivalent redaction behavior

### Cross-Platform Compatibility
- UTF-8 encoding with BOM for CSV files
- LF line endings for all text files
- Path normalization using platform-appropriate separators

## Integration Examples

### SIEM Integration
```bash
# Stream structured logs to SIEM
tail -f ./logs/*/azure_export_rbac_roles_and_assignments_*.jsonl | nc siem-server 514
```

### Monitoring Dashboard
```python
# Parse summary JSON for monitoring
import json
with open('summary.json') as f:
    summary = json.load(f)
    print(f"Duration: {summary['duration_seconds']}s")
    print(f"Assignments: {summary['assignments_count']}")
```

### Automation Script
```powershell
# Check for successful runs
$summary = Get-Content "summary.json" | ConvertFrom-Json
if ($summary.success) {
    Write-Host "Export successful: $($summary.assignments_count) assignments"
} else {
    Write-Error "Export failed: $($summary.errors.Count) errors"
}
```

## Version Compatibility

### Schema Versioning
- **v1.0**: Initial schema (2025)
- Future versions will maintain backward compatibility
- Breaking changes will increment major version

### Deprecation Policy
- Deprecated fields marked with `_deprecated` suffix
- 6-month notice for schema changes
- Migration guides provided for breaking changes

---
*This logging schema documentation is part of the Cloud IAM Best Practice repository. Last updated: 2025*
