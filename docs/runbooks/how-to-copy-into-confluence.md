# How to Copy RBAC Export Data into Confluence

## Overview

This guide explains how to effectively copy Azure RBAC export data into Confluence for documentation, analysis, and sharing. The export scripts generate multiple output formats optimized for different Confluence use cases.

## Choosing the Right Format

### When to Use CSV
- **Large datasets** (>200 rows)
- **Detailed analysis** required
- **Data filtering** and sorting needed
- **Integration** with other tools

**Best Practice:** Use per-subscription CSV files for large tenants to avoid Confluence import limits.

### When to Use Markdown
- **Small datasets** (<200 rows)
- **Quick documentation** updates
- **Inline tables** in existing pages
- **Visual review** of key assignments

**Best Practice:** Use `--markdown-top 50` for executive summaries.

### When to Use XLSX
- **Advanced Excel features** needed
- **Pivot tables** and complex analysis
- **Sharing with non-technical stakeholders**
- **Data validation** requirements

## CSV to Confluence Table

### Method 1: Direct Import (Recommended for large files)

1. **Navigate to your Confluence page**
2. **Click "Insert" → "Table" → "CSV Table"**
3. **Upload the CSV file**:
   - Choose `role_assignments_{SUBID}.csv` for targeted data
   - Or `role_assignments.csv` for merged data
4. **Configure import settings**:
   - Ensure "First row as header" is checked
   - Verify delimiter (comma)
   - Set appropriate column widths

### Method 2: Copy-Paste (For smaller datasets)

1. **Open CSV in Excel or text editor**
2. **Select and copy table data** (including headers)
3. **In Confluence, paste using Ctrl+V**
4. **Confluence automatically converts to table format**

### Method 3: Macro Table (For formatting control)

1. **Create table manually:**
   ```
   ||Header 1||Header 2||Header 3||
   |Data 1|Data 2|Data 3|
   ```

2. **Copy CSV data row by row**
3. **Use Confluence table macros for advanced formatting**

## Markdown Paste Tips

### Small Tables (<50 rows)

1. **Open `role_assignments.md` in text editor**
2. **Copy the entire table content**
3. **Paste directly into Confluence editor**
4. **Confluence renders as formatted table**

### Example Markdown Table:
```markdown
| scopeType | roleDefinitionName | principalType | principalDisplayName |
|-----------|-------------------|---------------|---------------------|
| Subscription | Contributor | User | John Doe |
| ResourceGroup | Reader | Group | Finance Team |
```

### Best Practices:
- **Limit to 200 rows** for page performance
- **Use `--markdown-top 100`** for focused views
- **Add context above the table** (filters, date, scope)

## XLSX Integration

### Sharing Excel Files

1. **Upload XLSX as attachment:**
   - Click "Attachments" in Confluence page
   - Upload `role_assignments.xlsx` or `role_assignments_{SUBID}.xlsx`
   - Add descriptive filename with date

2. **Link to attachment:**
   ```
   [Download RBAC Export (Excel)](attachment.xlsx)
   ```

### Embedding Excel Data

1. **Use Office Connector macro:**
   ```
   {officeconnector:file=role_assignments.xlsx}
   ```

2. **Embed specific sheets:**
   - Configure macro to show particular worksheets
   - Set refresh options for live data

## Per-Subscription Files for Large Tenants

### Why Per-Subscription Files?
- **Confluence import limits** (~10MB per file)
- **Browser performance** with large tables
- **Targeted analysis** by business unit
- **Easier sharing** with subscription owners

### Working with Per-Subscription Files:

1. **Identify relevant subscriptions:**
   - Check `index.json` for row counts per subscription
   - Focus on high-activity subscriptions first

2. **Import one file at a time:**
   ```bash
   # Example files generated:
   role_assignments_12345678-1234-1234-1234-123456789012.csv
   role_assignments_98765432-4321-4321-4321-210987654321.csv
   ```

3. **Add subscription context:**
   ```
   h2. Production Subscription RBAC (SUB-ID: 12345678-...)

   [Table content here]
   ```

## Data Redaction for Sharing

### When to Redact:
- **External sharing** (auditors, vendors)
- **Compliance requirements** (PII protection)
- **Public documentation** (runbooks, procedures)

### Using Redaction:
```bash
# Python
python export_script.py --subscriptions SUB1 --redact

# PowerShell
.\Export-RbacRolesAndAssignments.ps1 -Subscriptions SUB1 -Redact
```

### Redacted Data Format:
- **UPNs**: `user@company.com` → `[REDACTED]`
- **App IDs**: `12345678-...` → `[REDACTED]`
- **Display Names**: `John Doe` → `[REDACTED]`

## Performance Optimization

### Large File Handling:
1. **Use per-subscription files** instead of merged exports
2. **Filter by date range** if supported in future versions
3. **Limit columns** to essential data only
4. **Compress files** when attaching multiple exports

### Page Loading:
1. **Avoid embedding large tables directly**
2. **Use expandable sections** for detailed data:
   ```
   {expand:Click to view RBAC assignments}
   [Table content]
   {expand}
   ```

3. **Link to attachments** rather than pasting large content

## Formatting Best Practices

### Table Headers:
- **Use clear, descriptive column names**
- **Freeze header rows** in Excel before upload
- **Add sorting capabilities** where possible

### Data Organization:
1. **Sort by scope type** (MG → Subscription → RG)
2. **Group by role definition** for role-based analysis
3. **Filter by principal type** (Users vs Groups vs SPs)

### Visual Enhancements:
- **Use Confluence table styles** (striped rows, borders)
- **Add color coding** for critical roles (Owner, Contributor)
- **Include summary statistics** above tables

## Troubleshooting Common Issues

### "Table too large to import"
- **Solution:** Use per-subscription files or increase `--markdown-top` limit

### "Formatting lost during paste"
- **Solution:** Use Confluence table macros instead of direct paste

### "Data appears corrupted"
- **Solution:** Verify CSV encoding (UTF-8 with BOM) and line endings

### "Performance issues with large tables"
- **Solution:** Use expandable sections and attachment links

## Example Workflows

### Executive Summary Page:
1. **Markdown table** with top 20 critical assignments
2. **Key metrics** from summary JSON
3. **Links to detailed subscription exports**

### Technical Deep Dive:
1. **Per-subscription CSV attachments**
2. **Filtered views** for specific role types
3. **Change tracking** between export dates

### Audit Preparation:
1. **Redacted exports** for external sharing
2. **XLSX files** with pivot tables for analysis
3. **Version-controlled** export history

## Automation Tips

### Regular Export Schedule:
1. **Set up CI/CD pipeline** for automated exports
2. **Upload to Confluence** via API
3. **Update dashboard pages** with latest data

### Template Pages:
1. **Create RBAC report templates** in Confluence
2. **Use variables** for dynamic content
3. **Standardize reporting** across teams

---
*This Confluence integration guide is part of the Cloud IAM Best Practice repository. Last updated: 2025*
