<#
.SYNOPSIS
    Shared logging utilities for Azure RBAC export scripts.

.DESCRIPTION
    Provides structured logging, run ID generation, and output path management
    for PowerShell RBAC export scripts. Ensures consistent logging across all
    script implementations.

.EXAMPLE
    $logger, $runId, $paths = Start-Run -ScriptName "azure/export_rbac_roles_and_assignments"
#>

#requires -version 7.3

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-RunId {
    <#
    .SYNOPSIS
        Generate a new unique run identifier.
    #>
    [System.Guid]::NewGuid().ToString()
}

function Write-LogText {
    <#
    .SYNOPSIS
        Write human-readable log message to text file and console.
    
    .PARAMETER Message
        Log message to write.
    
    .PARAMETER Level
        Log level (INFO, WARN, ERROR).
    
    .PARAMETER LogPath
        Path to text log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Level - $Message"
    
    # Write to file
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
    
    # Write to console
    switch ($Level) {
        "ERROR" { Write-Error $Message -ErrorAction Continue }
        "WARN" { Write-Warning $Message }
        default { Write-Host $logEntry }
    }
}

function Write-LogJson {
    <#
    .SYNOPSIS
        Write structured JSON log entry.
    
    .PARAMETER Event
        Short event description.
    
    .PARAMETER Detail
        Additional structured data.
    
    .PARAMETER Level
        Log level.
    
    .PARAMETER RunId
        Current run identifier.
    
    .PARAMETER ScriptName
        Name of the script.
    
    .PARAMETER LogPath
        Path to JSONL log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Event,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Detail = @{},
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $true)]
        [string]$RunId,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )
    
    $logEntry = @{
        ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        run_id = $RunId
        script = $ScriptName
        level = $Level
        event = $Event
        detail = $Detail
    }
    
    $jsonEntry = $logEntry | ConvertTo-Json -Compress
    Add-Content -Path $LogPath -Value $jsonEntry -Encoding UTF8
}

function Write-Summary {
    <#
    .SYNOPSIS
        Write summary JSON file.
    
    .PARAMETER SummaryData
        Hashtable containing summary information.
    
    .PARAMETER SummaryPath
        Path to write the summary file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SummaryData,
        
        [Parameter(Mandatory = $true)]
        [string]$SummaryPath
    )
    
    try {
        # Ensure directory exists
        $summaryDir = Split-Path $SummaryPath -Parent
        if (!(Test-Path $summaryDir)) {
            New-Item -ItemType Directory -Path $summaryDir -Force | Out-Null
        }
        
        $SummaryData | ConvertTo-Json -Depth 10 | Set-Content -Path $SummaryPath -Encoding UTF8
        Write-Host "Summary written to $SummaryPath"
    }
    catch {
        Write-Error "Failed to write summary: $_"
    }
}

function New-OutputPaths {
    <#
    .SYNOPSIS
        Generate deterministic output paths.
    
    .PARAMETER BasePath
        Optional base path. If not provided, generates timestamped path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BasePath
    )
    
    if (-not $BasePath) {
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss")
        $BasePath = "output/azure/export_rbac_roles_and_assignments_$timestamp"
    }
    
    # Ensure output directory exists
    if (!(Test-Path $BasePath)) {
        New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
    }
    
    return @{
        Base = $BasePath
        RoleDefinitions = Join-Path $BasePath "role_definitions.csv"
        RoleAssignments = Join-Path $BasePath "role_assignments.csv"
        RoleAssignmentsXlsx = Join-Path $BasePath "role_assignments.xlsx"
        RoleAssignmentsMd = Join-Path $BasePath "role_assignments.md"
        Index = Join-Path $BasePath "index.json"
    }
}

function Start-Run {
    <#
    .SYNOPSIS
        Initialize structured logging for a script run.
    
    .PARAMETER ScriptName
        Name of the script (e.g., 'azure/export_rbac_roles_and_assignments').
    
    .EXAMPLE
        $logger, $runId, $paths = Start-Run -ScriptName "azure/export_rbac_roles_and_assignments"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )
    
    $runId = [System.Guid]::NewGuid().ToString()
    
    # Create logs directory with date structure
    $dateStr = (Get-Date).ToUniversalTime().ToString("yyyyMMdd")
    $logsDir = Join-Path "logs" $dateStr
    if (!(Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    
    # Define log paths
    $scriptFileName = $ScriptName -replace '/', '_'
    $logPaths = @{
        Text = Join-Path $logsDir "${scriptFileName}_${runId}.log"
        Jsonl = Join-Path $logsDir "${scriptFileName}_${runId}.jsonl"
        Summary = Join-Path $logsDir "${scriptFileName}_${runId}_summary.json"
    }
    
    # Create logger hashtable
    $logger = @{
        ScriptName = $ScriptName
        RunId = $runId
        LogPaths = $logPaths
        Log = {
            param(
                [string]$Message,
                [string]$Level = "INFO",
                [hashtable]$Detail = @{}
            )
            
            Write-LogText -Message $Message -Level $Level -LogPath $this.LogPaths.Text
            Write-LogJson -Event $Message -Detail $Detail -Level $Level -RunId $this.RunId -ScriptName $this.ScriptName -LogPath $this.LogPaths.Jsonl
        }
    }
    
    Write-LogText -Message "Logging initialized for run $runId" -LogPath $logPaths.Text
    Write-LogJson -Event "Logging initialized" -Level "INFO" -RunId $runId -ScriptName $ScriptName -LogPath $logPaths.Jsonl
    
    return $logger, $runId, $logPaths
}

Export-ModuleMember -Function New-RunId, Write-LogText, Write-LogJson, Write-Summary, New-OutputPaths, Start-Run
