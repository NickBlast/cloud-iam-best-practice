<#
.SYNOPSIS
    Export Azure RBAC roles and assignments across Management Groups, Subscriptions, and Resource Groups.

.DESCRIPTION
    This script exports Azure role definitions and assignments with inherited flag detection,
    principal resolution, and structured logging. It supports large tenant safety rails,
    redaction, and various output formats.

    Supports Management Groups, Subscriptions, and Resource Group scopes with proper
    inherited assignment detection.

.PARAMETER Subscriptions
    Target subscription IDs (comma-separated or array). Use with -ConfirmLargeScan for large tenants.

.PARAMETER IncludeResources
    Include resource-level assignments (off by default due to performance impact).

.PARAMETER ExpandGroupMembers
    Expand group members (extreme fan-out, use with caution). Requires -ConfirmLargeScan.

.PARAMETER Redact
    Mask UPNs/AppIds (including expanded members) for sharing.

.PARAMETER MarkdownTop
    Max rows for Markdown export (default: 200).

.PARAMETER NoResolvePrincipals
    Skip principal name resolution (speeds up large runs).

.PARAMETER ConfirmLargeScan
    Required when large tenant thresholds are hit (>25 subs or >200 RGs).

.PARAMETER OutputPath
    Output directory path (default: deterministic timestamped path).

.PARAMETER SafeMode
    Read-only mode (default: $true).

.PARAMETER MaxConcurrency
    Max parallel calls (default: 4).

.PARAMETER Limit
    Process first N scopes/assignments for smoke tests.

.PARAMETER DiscoverSubscriptions
    Discover subscriptions (off by default to prevent accidental tenant-wide enumeration).

.PARAMETER TraverseManagementGroups
    Traverse management groups (off by default).

.PARAMETER GroupMembersTop
    Hard cap per group members (default: 500).

.PARAMETER GroupMembershipMode
    Group membership mode: 'direct' or 'transitive' (default: direct).

.PARAMETER Json
    Emit JSON exports (newline-delimited or array).

.PARAMETER Login
    Attempt device authentication if not already connected.

.PARAMETER Bootstrap
    Run bootstrap prerequisites check before execution.

.EXAMPLE
    # Export specific subscriptions with redaction
    .\Export-RbacRolesAndAssignments.ps1 -Subscriptions "sub1,sub2" -Redact

.EXAMPLE
    # Discover subscriptions with large tenant confirmation
    .\Export-RbacRolesAndAssignments.ps1 -DiscoverSubscriptions -ConfirmLargeScan

.EXAMPLE
    # Traverse management groups without principal resolution
    .\Export-RbacRolesAndAssignments.ps1 -TraverseManagementGroups -NoResolvePrincipals

.NOTES
    Requires PowerShell 7.3+
    Requires Az.Accounts and Az.Resources modules
    Authentication: Run Connect-AzAccount first (SSO recommended)
    Version: 1.0.0
#>

#requires -version 7.3
#requires -modules @{ModuleName='Az.Accounts';ModuleVersion='2.10.0'},@{ModuleName='Az.Resources';ModuleVersion='6.0.0'}

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Subscriptions,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeResources,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExpandGroupMembers,
    
    [Parameter(Mandatory = $false)]
    [switch]$Redact,
    
    [Parameter(Mandatory = $false)]
    [int]$MarkdownTop = 200,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoResolvePrincipals,
    
    [Parameter(Mandatory = $false)]
    [switch]$ConfirmLargeScan,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$SafeMode = $true,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxConcurrency = 4,
    
    [Parameter(Mandatory = $false)]
    [int]$Limit,
    
    [Parameter(Mandatory = $false)]
    [switch]$DiscoverSubscriptions,
    
    [Parameter(Mandatory = $false)]
    [switch]$TraverseManagementGroups,
    
    [Parameter(Mandatory = $false)]
    [int]$GroupMembersTop = 500,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('direct', 'transitive')]
    [string]$GroupMembershipMode = 'direct',
    
    [Parameter(Mandatory = $false)]
    [switch]$Json,
    
[Parameter(Mandatory = $false)]
    [switch]$Login,

    [Parameter(Mandatory = $false)]
    [switch]$Bootstrap
)

# Import shared logging module
try {
    Import-Module "$PSScriptRoot\..\..\common\powershell\Common.Logging.psm1" -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to import Common.Logging module: $_"
    exit 1
}

# Constants
$Script:DEFAULT_MAX_CONCURRENCY = 4
$Script:DEFAULT_MARKDOWN_TOP = 200
$Script:DEFAULT_GROUP_MEMBERS_TOP = 500
$Script:LARGE_SUBSCRIPTION_THRESHOLD = 25
$Script:LARGE_RESOURCE_GROUP_THRESHOLD = 200

# Global cache for principal lookups
$Script:PrincipalCache = @{}

function Test-Preflight {
    <#
    .SYNOPSIS
        Perform preflight checks for Azure authentication and required modules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Logger
    )
    
    $Logger.Log("Performing preflight checks...", "INFO")
    
    # Check if connected to Azure
    try {
        $context = Get-AzContext -ErrorAction Stop
        if (-not $context.Account) {
            throw "No Azure account found in context"
        }
        $Logger.Log("Azure context found: $($context.Account.Id)", "INFO")
    } catch {
        if ($Login) {
            $Logger.Log("Attempting device authentication...", "INFO")
            try {
                Connect-AzAccount -UseDeviceAuthentication -ErrorAction Stop | Out-Null
                $Logger.Log("Device authentication successful", "INFO")
            } catch {
                $Logger.Log("Device authentication failed: $_", "ERROR")
                $Logger.Log("Authentication failed. Please run 'Connect-AzAccount' or ensure SSO is configured.", "ERROR")
                return $false
            }
        } else {
            $Logger.Log("Not connected to Azure. Please run 'Connect-AzAccount' first.", "ERROR")
            $Logger.Log("Or use -Login to attempt device authentication.", "INFO")
            return $false
        }
    }
    
    # Check required modules
    $requiredModules = @('Az.Accounts', 'Az.Resources')
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable $module)) {
            $Logger.Log("Required module $module not found", "ERROR")
            $Logger.Log("Install with: Install-Module $module -Scope CurrentUser", "INFO")
            return $false
        }
    }
    
    # Detect proxy settings
    $httpsProxy = $env:HTTPS_PROXY
    $httpProxy = $env:HTTP_PROXY
    if ($httpsProxy -or $httpProxy) {
        $Logger.Log("Proxy detected: HTTPS_PROXY=$httpsProxy, HTTP_PROXY=$httpProxy", "INFO")
    }
    
    return $true
}

function Get-ManagementGroups {
    <#
    .SYNOPSIS
        Get management groups with error handling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Logger
    )
    
    try {
        $mgList = @()
        $mgs = Get-AzManagementGroup -ErrorAction Stop
        
        foreach ($mg in $mgs) {
            $mgList += @{
                Id = $mg.Id
                Name = $mg.Name
                DisplayName = $mg.DisplayName
                Type = $mg.Type
            }
        }
        
        $Logger.Log("Found $($mgList.Count) management groups", "INFO")
        return $mgList
    } catch {
        $Logger.Log("Failed to list management groups: $_", "WARN")
        return @()
    }
}

function Get-SubscriptionsList {
    <#
    .SYNOPSIS
        Get subscriptions with optional filtering.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [string[]]$SubscriptionIds
    )
    
    try {
        $subList = @()
        $subs = Get-AzSubscription -ErrorAction Stop
        
        foreach ($sub in $subs) {
            if ($SubscriptionIds -and $SubscriptionIds -notcontains $sub.SubscriptionId) {
                continue
            }
            
            $subList += @{
                Id = $sub.Id
                SubscriptionId = $sub.SubscriptionId
                DisplayName = $sub.Name
                State = $sub.State
            }
        }
        
        $Logger.Log("Found $($subList.Count) subscriptions", "INFO")
        return $subList
    } catch {
        $Logger.Log("Failed to list subscriptions: $_", "WARN")
        return @()
    }
}

function Get-ResourceGroupsList {
    <#
    .SYNOPSIS
        Get resource groups for a subscription.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        
        [Parameter(Mandatory = $true)]
        $Logger
    )
    
    try {
        # Set context to subscription
        Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
        
        $rgList = @()
        $rgs = Get-AzResourceGroup -ErrorAction Stop
        
        foreach ($rg in $rgs) {
            $rgList += @{
                Id = $rg.ResourceId
                Name = $rg.ResourceGroupName
                Location = $rg.Location
                SubscriptionId = $SubscriptionId
            }
        }
        
        $Logger.Log("Found $($rgList.Count) resource groups in subscription $SubscriptionId", "DEBUG")
        return $rgList
    } catch {
        $Logger.Log("Failed to list resource groups for $SubscriptionId: $_", "WARN")
        return @()
    }
}

function Get-RoleDefinitionsList {
    <#
    .SYNOPSIS
        Get role definitions for a scope.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Scope,
        
        [Parameter(Mandatory = $true)]
        $Logger
    )
    
    try {
        $roleDefs = @()
        $defs = Get-AzRoleDefinition -Scope $Scope -ErrorAction Stop
        
        foreach ($def in $defs) {
            $roleDefs += @{
                roleDefinitionName = $def.Name
                roleDefinitionId = $def.Id
                isCustom = $def.IsCustom
                description = $def.Description
                permissionsCount = if ($def.Permissions) { $def.Permissions.Count } else { 0 }
                assignableScopes = ($def.AssignableScopes -join ';')
            }
        }
        
        $Logger.Log("Found $($roleDefs.Count) role definitions at scope $Scope", "DEBUG")
        return $roleDefs
    } catch {
        $Logger.Log("Failed to list role definitions at $Scope: $_", "WARN")
        return @()
    }
}

function Get-RoleAssignmentsList {
    <#
    .SYNOPSIS
        Get role assignments for a scope.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Scope,
        
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeInherited = $true
    )
    
    try {
        $assignments = @()
        $assigns = Get-AzRoleAssignment -Scope $Scope -IncludeClassicAdministrators:$false -ErrorAction Stop
        
        # Filter by inherited if needed
        if (-not $IncludeInherited) {
            $assigns = $assigns | Where-Object { $_.Scope -eq $Scope }
        }
        
        foreach ($assign in $assigns) {
            # Determine scope type
            $scopeType = 'Unknown'
            $subscriptionId = ''
            $resourceGroup = ''
            
            if ($Scope -like '*Microsoft.Management/managementGroups/*') {
                $scopeType = 'ManagementGroup'
            } elseif ($Scope -like '*resourceGroups/*') {
                $scopeType = 'ResourceGroup'
                # Extract subscription ID and RG name
                if ($Scope -match '/subscriptions/([^/]+)/resourceGroups/([^/]+)') {
                    $subscriptionId = $matches[1]
                    $resourceGroup = $matches[2]
                }
            } elseif ($Scope -like '*subscriptions/*') {
                $scopeType = 'Subscription'
                if ($Scope -match '/subscriptions/([^/]+)') {
                    $subscriptionId = $matches[1]
                }
            }
            
            $assignments += @{
                scope = $Scope
                scopeType = $scopeType
                subscriptionId = $subscriptionId
                resourceGroup = $resourceGroup
                roleDefinitionId = $assign.RoleDefinitionId
                roleDefinitionName = ''  # Will be filled later
                assignmentId = $assign.RoleAssignmentId
                principalId = $assign.ObjectId
                principalType = $assign.ObjectType
                principalDisplayName = ''  # Will be filled later
                principalUPNOrAppId = ''   # Will be filled later
                inherited = ($assign.Scope -ne $Scope)
                condition = $assign.Condition
                conditionVersion = $assign.ConditionVersion
                createdOn = if ($assign.CreatedOn) { $assign.CreatedOn.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') } else { '' }
            }
        }
        
        $Logger.Log("Found $($assignments.Count) role assignments at scope $Scope", "DEBUG")
        return $assignments
    } catch {
        $Logger.Log("Failed to list role assignments at $Scope: $_", "WARN")
        return @()
    }
}

function Resolve-Principal {
    <#
    .SYNOPSIS
        Resolve principal display name and UPN/AppId.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrincipalId,
        
        [Parameter(Mandatory = $true)]
        [string]$PrincipalType,
        
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [bool]$NoResolve = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$RedactFlag = $false
    )
    
    # Check cache first
    if ($Script:PrincipalCache.ContainsKey($PrincipalId)) {
        return $Script:PrincipalCache[$PrincipalId]
    }
    
    # If no resolution requested, return IDs only
    if ($NoResolve) {
        $displayName = $PrincipalId
        $upnOrAppId = $PrincipalId
        if ($RedactFlag) {
            $displayName = '[REDACTED]'
            $upnOrAppId = '[REDACTED]'
        }
        $result = @($displayName, $upnOrAppId)
        $Script:PrincipalCache[$PrincipalId] = $result
        return $result
    }
    
    $displayName = $PrincipalId
    $upnOrAppId = $PrincipalId
    
    try {
        switch ($PrincipalType) {
            'User' {
                $user = Get-AzADUser -ObjectId $PrincipalId -ErrorAction Stop
                $displayName = $user.DisplayName
                $upnOrAppId = $user.UserPrincipalName
                break
            }
            'Group' {
                $group = Get-AzADGroup -ObjectId $PrincipalId -ErrorAction Stop
                $displayName = $group.DisplayName
                $upnOrAppId = $group.Id
                break
            }
            'ServicePrincipal' {
                $sp = Get-AzADServicePrincipal -ObjectId $PrincipalId -ErrorAction Stop
                $displayName = $sp.DisplayName
                $upnOrAppId = $sp.AppId
                break
            }
            'ManagedIdentity' {
                # Managed identities are harder to resolve, keep IDs
                break
            }
        }
    } catch {
        $Logger.Log("Failed to resolve principal $PrincipalId: $_", "DEBUG")
        # Keep IDs as fallback
    }
    
    # Apply redaction if requested
    if ($RedactFlag) {
        $displayName = '[REDACTED]'
        $upnOrAppId = '[REDACTED]'
    }
    
    $result = @($displayName, $upnOrAppId)
    $Script:PrincipalCache[$PrincipalId] = $result
    return $result
}

function Expand-GroupMembers {
    <#
    .SYNOPSIS
        Expand group members with optional transitive expansion.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [int]$Top = 500,
        
        [Parameter(Mandatory = $false)]
        [string]$Mode = 'direct'
    )
    
    $members = @()
    
    try {
        if ($Mode -eq 'direct') {
            # Get direct members
            $groupMembers = Get-AzADGroupMember -GroupObjectId $GroupId -ErrorAction Stop
            $memberCount = 0
            
            foreach ($member in $groupMembers) {
                if ($memberCount -ge $Top) { break }
                
                $members += @{
                    memberPrincipalId = $member.Id
                    memberType = $member.Type
                    memberDisplayName = $member.DisplayName
                    memberUPN = if ($member.UserPrincipalName) { $member.UserPrincipalName } else { '' }
                }
                
                $memberCount++
            }
        } elseif ($Mode -eq 'transitive') {
            # Transitive expansion requires additional logic
            $Logger.Log("Transitive group expansion not implemented in this version", "WARN")
        }
    } catch {
        $Logger.Log("Failed to expand group $GroupId: $_", "WARN")
    }
    
    return $members
}

function Test-LargeTenantThresholds {
    <#
    .SYNOPSIS
        Check if large tenant thresholds are exceeded and require confirmation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Subscriptions,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ResourceGroupsPerSub,
        
        [Parameter(Mandatory = $true)]
        $Args,
        
        [Parameter(Mandatory = $true)]
        $Logger
    )
    
    $subCount = $Subscriptions.Count
    $totalRgCount = ($ResourceGroupsPerSub.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    
    $Logger.Log("Tenant size: $subCount subscriptions, $totalRgCount resource groups", "INFO")
    
    # Check thresholds
    if (($subCount -gt $Script:LARGE_SUBSCRIPTION_THRESHOLD) -or 
        ($totalRgCount -gt $Script:LARGE_RESOURCE_GROUP_THRESHOLD) -or
        ($Args.IncludeResources -and -not $Args.Subscriptions)) {
        
        if (-not $Args.ConfirmLargeScan) {
            $Logger.Log("LARGE TENANT DETECTED - Safety rail triggered!", "WARN")
            $Logger.Log("  Subscriptions: $subCount (threshold: $($Script:LARGE_SUBSCRIPTION_THRESHOLD))", "WARN")
            $Logger.Log("  Resource Groups: $totalRgCount (threshold: $($Script:LARGE_RESOURCE_GROUP_THRESHOLD))", "WARN")
            $Logger.Log("  Use -ConfirmLargeScan to proceed with large tenant enumeration", "WARN")
            return $false
        } else {
            $Logger.Log("Large tenant scan confirmed by user", "INFO")
        }
    }
    
    return $true
}

function Write-CsvFile {
    <#
    .SYNOPSIS
        Write data to CSV file with UTF-8 BOM for Excel compatibility.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$Filename,
        
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [bool]$RedactFlag = $false
    )
    
    if (-not $Data -or $Data.Count -eq 0) {
        $Logger.Log("No data to write to $Filename", "WARN")
        return
    }
    
    try {
        # Apply redaction if requested
        if ($RedactFlag) {
            $redactedData = @()
            foreach ($row in $Data) {
                $redactedRow = $row.Clone()
                if ($redactedRow.ContainsKey('principalUPNOrAppId')) {
                    $redactedRow['principalUPNOrAppId'] = '[REDACTED]'
                }
                if ($redactedRow.ContainsKey('memberUPN')) {
                    $redactedRow['memberUPN'] = '[REDACTED]'
                }
                $redactedData += $redactedRow
            }
            $Data = $redactedData
        }
        
        # Convert to PSObjects and export
        $psObjects = $Data | ForEach-Object {
            $props = @{}
            $_.Keys | ForEach-Object { $props[$_] = $_.Value }
            New-Object -TypeName PSObject -Property $props
        }
        
        # Export with UTF-8 BOM for Excel compatibility
        $psObjects | Export-Csv -Path $Filename -Encoding UTF8 -NoTypeInformation
        
        $Logger.Log("Wrote $($Data.Count) rows to $Filename", "INFO")
    } catch {
        $Logger.Log("Failed to write CSV $Filename: $_", "ERROR")
    }
}

function Write-XlsxFile {
    <#
    .SYNOPSIS
        Write data to XLSX file if ImportExcel module is available.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$Filename,
        
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [bool]$RedactFlag = $false
    )
    
    # Check if ImportExcel is available
    if (-not (Get-Module -ListAvailable ImportExcel)) {
        $Logger.Log("ImportExcel module not available, skipping XLSX export", "DEBUG")
        return
    }
    
    if (-not $Data -or $Data.Count -eq 0) {
        $Logger.Log("No data to write to $Filename", "WARN")
        return
    }
    
    try {
        # Apply redaction if requested
        if ($RedactFlag) {
            $redactedData = @()
            foreach ($row in $Data) {
                $redactedRow = $row.Clone()
                if ($redactedRow.ContainsKey('principalUPNOrAppId')) {
                    $redactedRow['principalUPNOrAppId'] = '[REDACTED]'
                }
                if ($redactedRow.ContainsKey('memberUPN')) {
                    $redactedRow['memberUPN'] = '[REDACTED]'
                }
                $redactedData += $redactedRow
            }
            $Data = $redactedData
        }
        
        # Convert to PSObjects and export
        $psObjects = $Data | ForEach-Object {
            $props = @{}
            $_.Keys | ForEach-Object { $props[$_] = $_.Value }
            New-Object -TypeName PSObject -Property $props
        }
        
        $psObjects | Export-Excel -Path $Filename -AutoSize -TableName "Data" -ErrorAction Stop
        
        $Logger.Log("Wrote $($Data.Count) rows to $Filename", "INFO")
    } catch {
        $Logger.Log("Failed to write XLSX $Filename: $_", "ERROR")
    }
}

function Write-MarkdownFile {
    <#
    .SYNOPSIS
        Write data to Markdown table.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$Filename,
        
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [int]$Top = 200,
        
        [Parameter(Mandatory = $false)]
        [bool]$RedactFlag = $false
    )
    
    if (-not $Data -or $Data.Count -eq 0) {
        $Logger.Log("No data to write to $Filename", "WARN")
        return
    }
    
    try {
        # Limit rows for Markdown
        $limitedData = $Data | Select-Object -First $Top
        
        # Apply redaction if requested
        if ($RedactFlag) {
            $redactedData = @()
            foreach ($row in $limitedData) {
                $redactedRow = $row.Clone()
                if ($redactedRow.ContainsKey('principalUPNOrAppId')) {
                    $redactedRow['principalUPNOrAppId'] = '[REDACTED]'
                }
                if ($redactedRow.ContainsKey('memberUPN')) {
                    $redactedRow['memberUPN'] = '[REDACTED]'
                }
                $redactedData += $redactedRow
            }
            $limitedData = $redactedData
        }
        
        # Write Markdown table
        if ($limitedData.Count -gt 0) {
            # Get headers from first row
            $headers = $limitedData[0].Keys | Sort-Object
            
            # Write header row
            $headerRow = '| ' + ($headers -join ' | ') + ' |'
            $separatorRow = '| ' + ($headers | ForEach-Object { '---' }) -join ' | ' + ' |'
            
            $content = @($headerRow, $separatorRow)
            
            # Write data rows
            foreach ($row in $limitedData) {
                $dataRow = '| ' + ($headers | ForEach-Object { $row[$_] }) -join ' | ' + ' |'
                $content += $dataRow
            }
            
            # Add footer
            $content += ''
            $content += "*Showing first $($limitedData.Count) rows of $($Data.Count) total*"
            
            $content | Set-Content -Path $Filename -Encoding UTF8
        }
        
        $Logger.Log("Wrote $($limitedData.Count) rows to $Filename", "INFO")
    } catch {
        $Logger.Log("Failed to write Markdown $Filename: $_", "ERROR")
    }
}

function Write-JsonFile {
    <#
    .SYNOPSIS
        Write data to JSON file (array format).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$Filename,
        
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [bool]$RedactFlag = $false
    )
    
    if (-not $Data -or $Data.Count -eq 0) {
        $Logger.Log("No data to write to $Filename", "WARN")
        return
    }
    
    try {
        # Apply redaction if requested
        if ($RedactFlag) {
            $redactedData = @()
            foreach ($row in $Data) {
                $redactedRow = $row.Clone()
                if ($redactedRow.ContainsKey('principalUPNOrAppId')) {
                    $redactedRow['principalUPNOrAppId'] = '[REDACTED]'
                }
                if ($redactedRow.ContainsKey('memberUPN')) {
                    $redactedRow['memberUPN'] = '[REDACTED]'
                }
                $redactedData += $redactedRow
            }
            $Data = $redactedData
        }
        
        # Convert to JSON and write
        $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $Filename -Encoding UTF8
        
        $Logger.Log("Wrote $($Data.Count) rows to $Filename", "INFO")
    } catch {
        $Logger.Log("Failed to write JSON $Filename: $_", "ERROR")
    }
}

function Write-IndexFile {
    <#
    .SYNOPSIS
        Write index.json file with artifact information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$IndexData,
        
        [Parameter(Mandatory = $true)]
        [string]$Filename,
        
        [Parameter(Mandatory = $true)]
        $Logger
    )
    
    try {
        $IndexData | ConvertTo-Json -Depth 10 | Set-Content -Path $Filename -Encoding UTF8
        $Logger.Log("Wrote index file to $Filename", "INFO")
    } catch {
        $Logger.Log("Failed to write index file $Filename: $_", "ERROR")
    }
}

function Start-SleepWithJitter {
    <#
    .SYNOPSIS
        Sleep with exponential backoff and jitter for retry logic.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Attempt
    )
    
    $baseDelay = 0.5
    $maxDelay = 8.0
    $jitter = Get-Random -Minimum 0.0 -Maximum 1.0
    
    $delay = [Math]::Min($baseDelay * [Math]::Pow(2, $Attempt - 1), $maxDelay)
    $delay = $delay * (1 + $jitter * 0.1)  # Add 10% jitter
    
    Start-Sleep -Seconds $delay
}

function Invoke-WithRetry {
    <#
    .SYNOPSIS
        Invoke a script block with retry logic for 429/5xx errors.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true)]
        $Logger,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3
    )
    
    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        try {
            return & $ScriptBlock
        } catch {
            $attempt++
            if ($attempt -ge $MaxRetries) {
                throw $_
            }
            
            # Check if it's a retryable error (429, 5xx)
            $shouldRetry = $false
            if ($_.Exception.Response) {
                $statusCode = $_.Exception.Response.StatusCode.value__
                if ($statusCode -eq 429 -or ($statusCode -ge 500 -and $statusCode -lt 600)) {
                    $shouldRetry = $true
                }
            }
            
            if ($shouldRetry) {
                $Logger.Log("Retryable error on attempt $attempt/$MaxRetries: $_", "WARN")
                Start-SleepWithJitter -Attempt $attempt
            } else {
                throw $_
            }
        }
    }
}

# Main function
function Main {
    [CmdletBinding()]
    param()
    
    # Check if bootstrap is requested
    if ($Bootstrap) {
        $bootstrapScript = Join-Path $PSScriptRoot "..\..\bootstrap\Install-Prereqs.ps1"
        if (Test-Path $bootstrapScript) {
            Write-Host "Running bootstrap prerequisites check..." -ForegroundColor Cyan
            & $bootstrapScript -NonInteractive
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Bootstrap failed with exit code $LASTEXITCODE"
                exit $LASTEXITCODE
            }
            Write-Host "Bootstrap completed successfully" -ForegroundColor Green
        } else {
            Write-Warning "Bootstrap script not found at $bootstrapScript"
        }
    }
    
    $startTime = Get-Date
    
    # Initialize logging
    $logger, $runId, $logPaths = Start-Run -ScriptName "azure/export_rbac_roles_and_assignments"
    $logger.Log("Starting Azure RBAC export run $runId", "INFO")
    $logger.Log("Arguments: $($PSBoundParameters | ConvertTo-Json -Compress)", "INFO")
    
    # Preflight check
    if (-not (Test-Preflight -Logger $logger)) {
        exit 1
    }
    
    # Parse comma-separated subscriptions
    if ($Subscriptions) {
        $expandedSubs = @()
        foreach ($sub in $Subscriptions) {
            $expandedSubs += $sub.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries).Trim()
        }
        $Subscriptions = $expandedSubs | Where-Object { $_ }
    }
    
    # Validate arguments
    if (-not $Subscriptions -and -not $DiscoverSubscriptions -and -not $TraverseManagementGroups) {
        $logger.Log("ERROR: Must specify -Subscriptions, -DiscoverSubscriptions, or -TraverseManagementGroups", "ERROR")
        $logger.Log("       This prevents accidental tenant-wide enumeration.", "ERROR")
        exit 1
    }
    
    if ($GroupMembershipMode -eq 'transitive' -and -not $ConfirmLargeScan) {
        $logger.Log("ERROR: -GroupMembershipMode transitive requires -ConfirmLargeScan", "ERROR")
        exit 1
    }
    
    # Get management groups if requested
    $managementGroups = @()
    if ($TraverseManagementGroups) {
        $managementGroups = Get-ManagementGroups -Logger $logger
        if ($managementGroups.Count -eq 0) {
            $logger.Log("No management groups found or access denied", "WARN")
        }
    }
    
    # Get subscriptions
    $subscriptions = @()
    if ($Subscriptions) {
        $subscriptions = Get-SubscriptionsList -Logger $logger -SubscriptionIds $Subscriptions
    } elseif ($DiscoverSubscriptions -or $TraverseManagementGroups) {
        $subscriptions = Get-SubscriptionsList -Logger $logger
    }
    
    if ($subscriptions.Count -eq 0) {
        $logger.Log("No subscriptions found or accessible", "ERROR")
        exit 1
    }
    
    # Get resource groups per subscription
    $resourceGroupsPerSub = @{}
    if ($IncludeResources -or $Limit) {
        $logger.Log("Enumerating resource groups...", "INFO")
        foreach ($sub in $subscriptions) {
            $subId = $sub.SubscriptionId
            $rgs = Get-ResourceGroupsList -SubscriptionId $subId -Logger $logger
            $resourceGroupsPerSub[$subId] = $rgs
            if ($Limit -and $resourceGroupsPerSub.Count -ge $Limit) {
                break
            }
        }
    }
    
    # Check large tenant thresholds
    if (-not (Test-LargeTenantThresholds -Subscriptions $subscriptions -ResourceGroupsPerSub $resourceGroupsPerSub -Args $PSBoundParameters -Logger $logger)) {
        $logger.Log("Large tenant safety rail triggered - exiting", "ERROR")
        exit 2
    }
    
    # Generate output paths
    $outputPaths = New-OutputPaths -BasePath $OutputPath
    $logger.Log("Output directory: $($outputPaths.Base)", "INFO")
    
    # Collect all data
    $allRoleDefinitions = @()
    $allRoleAssignments = @()
    $scopesProcessed = @{ managementGroups = 0; subscriptions = 0; resourceGroups = 0 }
    $scopesSkipped = @()
    $errors = @()
    $warnings = @()
    
    # Process management groups
    if ($TraverseManagementGroups -and $managementGroups.Count -gt 0) {
        $logger.Log("Processing management groups...", "INFO")
        foreach ($mg in $managementGroups) {
            try {
                $mgId = $mg.Name  # Management group name is used in scope
                $scope = "/providers/Microsoft.Management/managementGroups/$mgId"
                
                # Get role definitions with retry logic
                $roleDefs = Invoke-WithRetry -ScriptBlock {
                    Get-RoleDefinitionsList -Scope $scope -Logger $logger
                } -Logger $logger
                
                $allRoleDefinitions += $roleDefs
                
                # Get role assignments with retry logic
                $assignments = Invoke-WithRetry -ScriptBlock {
                    Get-RoleAssignmentsList -Scope $scope -Logger $logger
                } -Logger $logger
                
                # Mark inherited assignments
                foreach ($assignment in $assignments) {
                    if ($assignment.scope -ne $scope) {
                        $assignment.inherited = $true
                    }
                }
                
                $allRoleAssignments += $assignments
                $scopesProcessed.managementGroups++
                
                if ($Limit -and $scopesProcessed.managementGroups -ge $Limit) {
                    break
                }
                
            } catch {
                $errorMsg = "Failed to process management group $($mg.Name): $_"
                $logger.Log($errorMsg, "ERROR")
                $errors += $errorMsg
                $scopesSkipped += "MG:$($mg.Name)"
            }
        }
    }
    
    # Process subscriptions
    $logger.Log("Processing subscriptions...", "INFO")
    foreach ($sub in $subscriptions) {
        try {
            $subId = $sub.SubscriptionId
            $scope = "/subscriptions/$subId"
            
            # Get role definitions with retry logic
            $roleDefs = Invoke-WithRetry -ScriptBlock {
                Get-RoleDefinitionsList -Scope $scope -Logger $logger
            } -Logger $logger
            
            $allRoleDefinitions += $roleDefs
            
            # Get role assignments with retry logic
            $assignments = Invoke-WithRetry -ScriptBlock {
                Get-RoleAssignmentsList -Scope $scope -Logger $logger
            } -Logger $logger
            
            # Mark inherited assignments
            foreach ($assignment in $assignments) {
                if ($assignment.scope -ne $scope) {
                    $assignment.inherited = $true
                }
            }
            
            $allRoleAssignments += $assignments
            $scopesProcessed.subscriptions++
            
            # Process resource groups if requested
            if ($IncludeResources -and $resourceGroupsPerSub.ContainsKey($subId)) {
                $rgs = $resourceGroupsPerSub[$subId]
                foreach ($rg in $rgs) {
                    try {
                        $rgScope = "/subscriptions/$subId/resourceGroups/$($rg.Name)"
                        
                        # Get role assignments at RG level with retry logic
                        $rgAssignments = Invoke-WithRetry -ScriptBlock {
                            Get-RoleAssignmentsList -Scope $rgScope -Logger $logger
                        } -Logger $logger
                        
                        # Mark inherited assignments
                        foreach ($assignment in $rgAssignments) {
                            if ($assignment.scope -ne $rgScope) {
                                $assignment.inherited = $true
                            }
                        }
                        
                        $allRoleAssignments += $rgAssignments
                        $scopesProcessed.resourceGroups++
                        
                        if ($Limit -and $scopesProcessed.resourceGroups -ge $Limit) {
                            break
                        }
                    } catch {
                        $errorMsg = "Failed to process resource group $($rg.Name) in $subId: $_"
                        $logger.Log($errorMsg, "ERROR")
                        $errors += $errorMsg
                        $scopesSkipped += "RG:$($rg.Name):$subId"
                    }
                }
            }
            
            if ($Limit -and $scopesProcessed.subscriptions -ge $Limit) {
                break
            }
            
        } catch {
            $errorMsg = "Failed to process subscription $($sub.SubscriptionId): $_"
            $logger.Log($errorMsg, "ERROR")
            $errors += $errorMsg
            $scopesSkipped += "SUB:$($sub.SubscriptionId)"
        }
    }
    
    # Resolve principal names if not disabled
    if (-not $NoResolvePrincipals -and $allRoleAssignments.Count -gt 0) {
        $logger.Log("Resolving $($allRoleAssignments.Count) principal names...", "INFO")
        $resolvedCount = 0
        
        foreach ($assignment in $allRoleAssignments) {
            try {
                $result = Resolve-Principal -PrincipalId $assignment.principalId -PrincipalType $assignment.principalType -Logger $logger -NoResolve $NoResolvePrincipals -RedactFlag $Redact
                $assignment.principalDisplayName = $result[0]
                $assignment.principalUPNOrAppId = $result[1]
                $resolvedCount++
                
                if ($resolvedCount % 100 -eq 0) {
                    $logger.Log("Resolved $resolvedCount/$($allRoleAssignments.Count) principals", "DEBUG")
                }
                
            } catch {
                $logger.Log("Failed to resolve principal $($assignment.principalId): $_", "DEBUG")
                # Keep IDs as fallback
            }
        }
        
        $logger.Log("Resolved $resolvedCount principal names", "INFO")
    }
    
    # Expand group members if requested
    if ($ExpandGroupMembers -and $allRoleAssignments.Count -gt 0) {
        $logger.Log("Expanding group members...", "INFO")
        $expandedCount = 0
        
        foreach ($assignment in $allRoleAssignments) {
            if ($assignment.principalType -eq 'Group') {
                try {
                    $members = Expand-GroupMembers -GroupId $assignment.principalId -Logger $logger -Top $GroupMembersTop -Mode $GroupMembershipMode
                    
                    # Add member information to assignment
                    if ($members.Count -gt 0) {
                        $assignment.memberCount = $members.Count
                        # For simplicity, we'll add the first member's info
                        if ($members.Count -gt 0) {
                            $firstMember = $members[0]
                            $assignment.memberPrincipalId = $firstMember.memberPrincipalId
                            $assignment.memberType = $firstMember.memberType
                            $assignment.memberDisplayName = $firstMember.memberDisplayName
                            $assignment.memberUPN = if ($Redact) { '[REDACTED]' } else { $firstMember.memberUPN }
                        }
                        
                        $expandedCount++
                    }
                    
                } catch {
                    $logger.Log("Failed to expand group $($assignment.principalId): $_", "WARN")
                }
            }
        }
        
        $logger.Log("Expanded $expandedCount groups", "INFO")
    }
    
    # Write outputs
    $logger.Log("Writing outputs...", "INFO")
    
    # Write role definitions
    Write-CsvFile -Data $allRoleDefinitions -Filename $outputPaths.RoleDefinitions -Logger $logger -RedactFlag $Redact
    
    # Write role assignments (merged)
    Write-CsvFile -Data $allRoleAssignments -Filename $outputPaths.RoleAssignments -Logger $logger -RedactFlag $Redact
    
    Write-XlsxFile -Data $allRoleAssignments -Filename $outputPaths.RoleAssignmentsXlsx -Logger $logger -RedactFlag $Redact
    
    if ($MarkdownTop -gt 0) {
        Write-MarkdownFile -Data $allRoleAssignments -Filename $outputPaths.RoleAssignmentsMd -Logger $logger -Top $MarkdownTop -RedactFlag $Redact
    }
    
    if ($Json) {
        Write-JsonFile -Data $allRoleDefinitions -Filename ($outputPaths.RoleDefinitions -replace '\.csv$', '.json') -Logger $logger -RedactFlag $Redact
        Write-JsonFile -Data $allRoleAssignments -Filename ($outputPaths.RoleAssignments -replace '\.csv$', '.json') -Logger $logger -RedactFlag $Redact
    }
    
    # Write per-subscription files
    $subAssignments = @{}
    foreach ($assignment in $allRoleAssignments) {
        $subId = $assignment.subscriptionId
        if ($subId) {
            if (-not $subAssignments.ContainsKey($subId)) {
                $subAssignments[$subId] = @()
            }
            $subAssignments[$subId] += $assignment
        }
    }
    
    foreach ($subId in $subAssignments.Keys) {
        $assignments = $subAssignments[$subId]
        $subFile = $outputPaths.RoleAssignments -replace '\.csv$', "_$subId.csv"
        Write-CsvFile -Data $assignments -Filename $subFile -Logger $logger -RedactFlag $Redact
        
        $subXlsx = $subFile -replace '\.csv$', '.xlsx'
        Write-XlsxFile -Data $assignments -Filename $subXlsx -Logger $logger -RedactFlag $Redact
    }
    
    # Create index file
    $indexData = @{
        artifacts = @{
            role_definitions_csv = $outputPaths.RoleDefinitions
            role_assignments_csv = $outputPaths.RoleAssignments
            role_assignments_xlsx = $outputPaths.RoleAssignmentsXlsx
            role_assignments_md = if ($MarkdownTop -gt 0) { $outputPaths.RoleAssignmentsMd } else { $null }
        }
        row_counts = @{
            role_definitions = $allRoleDefinitions.Count
            role_assignments = $allRoleAssignments.Count
        }
        per_subscription = @{}
    }
    
    foreach ($subId in $subAssignments.Keys) {
        $indexData.per_subscription[$subId] = $subAssignments[$subId].Count
    }
    
    Write-IndexFile -IndexData $indexData -Filename $outputPaths.Index -Logger $logger
    
    # Write summary
    $duration = (Get-Date) - $startTime
    $summaryData = @{
        run_id = $runId
        start_time = $startTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        end_time = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        duration_seconds = $duration.TotalSeconds
        scopes_processed = $scopesProcessed
        scopes_skipped = $scopesSkipped
        roles_count = $allRoleDefinitions.Count
        assignments_count = $allRoleAssignments.Count
        warnings = $warnings
        errors = $errors
        success = ($errors.Count -eq 0)
        arguments = $PSBoundParameters
    }
    
    Write-Summary -SummaryData $summaryData -SummaryPath $logPaths.Summary
    
    # Determine exit code
    if ($errors.Count -gt 0) {
        $logger.Log("Run completed with $($errors.Count) errors", "ERROR")
        exit 1
    } elseif ($warnings.Count -gt 0 -or $scopesSkipped.Count -gt 0) {
        $logger.Log("Run completed with $($warnings.Count) warnings", "WARN")
        exit 2
    } else {
        $logger.Log("Run completed successfully", "INFO")
        exit 0
    }
}

# Execute main function
Main
