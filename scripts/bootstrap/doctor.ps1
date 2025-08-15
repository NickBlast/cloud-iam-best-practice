<#
.SYNOPSIS
    Read-only status report for Azure RBAC export environment.

.DESCRIPTION
    Performs a comprehensive health check of the Azure RBAC export environment,
    including PowerShell version, Azure CLI, Python, modules, and authentication status.

    Exits with appropriate codes: 0 (all good), 1 (failure), 2 (partial/warnings).

.PARAMETER BootstrapLogPath
    Custom path for bootstrap logs (default: logs/bootstrap/).

.EXAMPLE
    # Run doctor check
    .\doctor.ps1

.EXAMPLE
    # Run doctor check with custom log path
    .\doctor.ps1 -BootstrapLogPath "custom/logs"

.NOTES
    Requires PowerShell 7.3+
    Version: 1.0.0
#>

#requires -version 7.3

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$BootstrapLogPath = "logs/bootstrap"
)

# Import shared logging module
try {
    Import-Module "$PSScriptRoot\..\common\powershell\Common.Logging.psm1" -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to import Common.Logging module: $_"
    exit 1
}

# Global variables
$Script:VersionsFile = Join-Path $PSScriptRoot "versions.json"
$Script:StartTime = Get-Date
$Script:RunId = [System.Guid]::NewGuid().ToString()

function Write-DoctorLog {
    <#
    .SYNOPSIS
        Write doctor-specific log entries.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Detail = @{}
    )
    
    # Ensure bootstrap log directory exists
    $dateStr = (Get-Date).ToUniversalTime().ToString("yyyyMMdd")
    $bootstrapLogDir = Join-Path $BootstrapLogPath $dateStr
    if (!(Test-Path $bootstrapLogDir)) {
        New-Item -ItemType Directory -Path $bootstrapLogDir -Force | Out-Null
    }
    
    $logPath = Join-Path $bootstrapLogDir "doctor_${Script:RunId}.log"
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Level - $Message"
    
    # Write to file
    Add-Content -Path $logPath -Value $logEntry -Encoding UTF8
    
    # Write to console
    switch ($Level) {
        "ERROR" { Write-Error $Message -ErrorAction Continue }
        "WARN" { Write-Warning $Message }
        "DEBUG" { if ($VerbosePreference -ne 'SilentlyContinue') { Write-Host $logEntry } }
        default { Write-Host $logEntry }
    }
    
    # Write JSONL entry
    $jsonLogPath = Join-Path $bootstrapLogDir "doctor_${Script:RunId}.jsonl"
    $logEntry = @{
        ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        run_id = $Script:RunId
        script = "bootstrap/doctor"
        level = $Level
        event = $Message
        detail = $Detail
    }
    
    $jsonEntry = $logEntry | ConvertTo-Json -Compress
    Add-Content -Path $jsonLogPath -Value $jsonEntry -Encoding UTF8
}

function Load-VersionsConfig {
    <#
    .SYNOPSIS
        Load versions configuration from JSON file.
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (Test-Path $Script:VersionsFile) {
            $config = Get-Content -Path $Script:VersionsFile -Raw | ConvertFrom-Json
            Write-DoctorLog "Loaded versions configuration from $Script:VersionsFile" "INFO"
            return $config
        } else {
            Write-DoctorLog "Versions file not found: $Script:VersionsFile" "ERROR"
            return $null
        }
    } catch {
        Write-DoctorLog "Failed to load versions configuration: $_" "ERROR"
        return $null
    }
}

function Test-PowerShellVersion {
    <#
    .SYNOPSIS
        Check if PowerShell version meets minimum requirements.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    $minVersion = [System.Version]$Config.minimums.powershell
    $currentVersion = $PSVersionTable.PSVersion
    
    Write-DoctorLog "PowerShell version: current=$currentVersion, minimum=$minVersion" "INFO"
    
    if ($currentVersion -ge $minVersion) {
        Write-DoctorLog "PowerShell version meets minimum requirement" "INFO"
        return $true
    } else {
        Write-DoctorLog "PowerShell version is below minimum requirement" "ERROR"
        return $false
    }
}

function Test-AzureCli {
    <#
    .SYNOPSIS
        Check if Azure CLI is installed and working.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $azVersionOutput = az --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Parse version from output
            $versionLine = $azVersionOutput | Where-Object { $_ -match "^azure-cli\s+" }
            if ($versionLine) {
                $version = ($versionLine -split '\s+')[1]
                Write-DoctorLog "Azure CLI version: $version" "INFO"
                return $true, $version
            } else {
                Write-DoctorLog "Azure CLI found but could not parse version" "WARN"
                return $true, "unknown"
            }
        } else {
            Write-DoctorLog "Azure CLI not found or not in PATH" "WARN"
            return $false, $null
        }
    } catch {
        Write-DoctorLog "Failed to check Azure CLI: $_" "WARN"
        return $false, $null
    }
}

function Test-AzureContext {
    <#
    .SYNOPSIS
        Check Azure PowerShell context and authentication status.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if ($context -and $context.Account) {
            Write-DoctorLog "Azure PowerShell context: $($context.Account.Id)" "INFO"
            return $true, $context
        } else {
            Write-DoctorLog "No Azure PowerShell context found" "WARN"
            return $false, $null
        }
    } catch {
        Write-DoctorLog "Failed to get Azure context: $_" "WARN"
        return $false, $null
    }
}

function Test-PythonEnvironment {
    <#
    .SYNOPSIS
        Check Python environment and virtual environment status.
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Check Python version
        $pythonVersionOutput = python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            $pythonVersionOutput = python3 --version 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-DoctorLog "Python not found or not in PATH" "WARN"
                return $false, $null, $null
            }
            $pythonCmd = "python3"
        } else {
            $pythonCmd = "python"
        }
        
        $versionMatch = [regex]::Match($pythonVersionOutput, "Python\s+(\d+\.\d+\.\d+)")
        if ($versionMatch.Success) {
            $pythonVersion = $versionMatch.Groups[1].Value
            Write-DoctorLog "Python version: $pythonVersion (using $pythonCmd)" "INFO"
        } else {
            Write-DoctorLog "Could not parse Python version" "WARN"
            $pythonVersion = "unknown"
        }
        
        # Check virtual environment
        $venvPython = if ($IsWindows) { ".venv\Scripts\python.exe" } else { ".venv/bin/python" }
        $venvExists = Test-Path $venvPython
        
        if ($venvExists) {
            Write-DoctorLog "Virtual environment found" "INFO"
            
            # Check installed packages
            $pipList = & $venvPython -m pip list 2>&1
            if ($LASTEXITCODE -eq 0) {
                $packageCount = ($pipList | Measure-Object).Count
                Write-DoctorLog "Virtual environment has $packageCount packages installed" "INFO"
                return $true, $pythonVersion, $packageCount
            } else {
                Write-DoctorLog "Virtual environment exists but failed to list packages" "WARN"
                return $true, $pythonVersion, 0
            }
        } else {
            Write-DoctorLog "Virtual environment not found" "WARN"
            return $true, $pythonVersion, 0
        }
    } catch {
        Write-DoctorLog "Failed to check Python environment: $_" "WARN"
        return $false, $null, $null
    }
}

function Test-PowerShellModules {
    <#
    .SYNOPSIS
        Check if required PowerShell modules are installed and meet version requirements.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    $results = @{
        required = @()
        optional = @()
    }
    
    # Check required modules
    foreach ($module in $Config.powershellModules) {
        try {
            $installedModule = Get-Module -ListAvailable -Name $module.name -ErrorAction SilentlyContinue | 
                              Sort-Object Version -Descending | Select-Object -First 1
            
            if ($installedModule) {
                $meetsVersion = $installedModule.Version -ge [System.Version]$module.version
                $status = if ($meetsVersion) { "ok" } else { "outdated" }
                
                $moduleResult = @{
                    name = $module.name
                    installed_version = $installedModule.Version.ToString()
                    required_version = $module.version
                    status = $status
                }
                
                $results.required += $moduleResult
                
                if ($meetsVersion) {
                    Write-DoctorLog "Module $($module.name) $($installedModule.Version) meets requirement $($module.version)" "INFO"
                } else {
                    Write-DoctorLog "Module $($module.name) $($installedModule.Version) below required version $($module.version)" "WARN"
                }
            } else {
                $moduleResult = @{
                    name = $module.name
                    installed_version = $null
                    required_version = $module.version
                    status = "missing"
                }
                
                $results.required += $moduleResult
                Write-DoctorLog "Module $($module.name) not found" "WARN"
            }
        } catch {
            Write-DoctorLog "Failed to check module $($module.name): $_" "WARN"
            $results.required += @{
                name = $module.name
                installed_version = $null
                required_version = $module.version
                status = "error"
                error = $_.ToString()
            }
        }
    }
    
    # Check optional modules
    foreach ($module in $Config.powershellOptionalModules) {
        try {
            $installedModule = Get-Module -ListAvailable -Name $module.name -ErrorAction SilentlyContinue | 
                              Sort-Object Version -Descending | Select-Object -First 1
            
            if ($installedModule) {
                $meetsVersion = $installedModule.Version -ge [System.Version]$module.version
                $status = if ($meetsVersion) { "ok" } else { "outdated" }
                
                $moduleResult = @{
                    name = $module.name
                    installed_version = $installedModule.Version.ToString()
                    required_version = $module.version
                    status = $status
                }
                
                $results.optional += $moduleResult
                Write-DoctorLog "Optional module $($module.name) $($installedModule.Version) available" "INFO"
            } else {
                $moduleResult = @{
                    name = $module.name
                    installed_version = $null
                    required_version = $module.version
                    status = "missing"
                }
                
                $results.optional += $moduleResult
                Write-DoctorLog "Optional module $($module.name) not found" "INFO"
            }
        } catch {
            Write-DoctorLog "Failed to check optional module $($module.name): $_" "INFO"
            $results.optional += @{
                name = $module.name
                installed_version = $null
                required_version = $module.version
                status = "error"
                error = $_.ToString()
            }
        }
    }
    
    return $results
}

function Test-Bootstrap {
    <#
    .SYNOPSIS
        Test bootstrap functionality by running the test script.
    #>
    [CmdletBinding()]
    param()
    
    try {
        $testScript = Join-Path $PSScriptRoot "test_bootstrap.py"
        if (Test-Path $testScript) {
            Write-DoctorLog "Running bootstrap test script: $testScript" "INFO"
            $result = & python $testScript 2>&1
            $success = $LASTEXITCODE -eq 0
            
            if ($success) {
                Write-DoctorLog "Bootstrap test completed successfully" "INFO"
            } else {
                Write-DoctorLog "Bootstrap test failed with exit code $LASTEXITCODE" "WARN"
            }
            
            return @{
                script_exists = $true
                success = $success
                exit_code = $LASTEXITCODE
                output = $result
            }
        } else {
            Write-DoctorLog "Bootstrap test script not found: $testScript" "WARN"
            return @{
                script_exists = $false
                success = $false
                exit_code = -1
                output = "Script not found"
            }
        }
    } catch {
        Write-DoctorLog "Failed to run bootstrap test: $_" "WARN"
        return @{
            script_exists = $true
            success = $false
            exit_code = -1
            output = $_.ToString()
        }
    }
}

function Write-Summary {
    <#
    .SYNOPSIS
        Write doctor summary JSON file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SummaryData
    )
    
    try {
        $dateStr = (Get-Date).ToUniversalTime().ToString("yyyyMMdd")
        $bootstrapLogDir = Join-Path $BootstrapLogPath $dateStr
        if (!(Test-Path $bootstrapLogDir)) {
            New-Item -ItemType Directory -Path $bootstrapLogDir -Force | Out-Null
        }
        
        $summaryPath = Join-Path $bootstrapLogDir "doctor_${Script:RunId}_summary.json"
        $SummaryData | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8
        Write-DoctorLog "Summary written to $summaryPath" "INFO"
    } catch {
        Write-DoctorLog "Failed to write summary: $_" "ERROR"
    }
}

# Main function
function Main {
    [CmdletBinding()]
    param()
    
    Write-DoctorLog "Starting doctor check (Run ID: $Script:RunId)" "INFO"
    
    # Load configuration
    $config = Load-VersionsConfig
    if (-not $config) {
        Write-DoctorLog "Failed to load configuration, exiting" "ERROR"
        exit 1
    }
    
    # Initialize results
    $results = @{
        doctor = @{
            run_id = $Script:RunId
            start_time = $Script:StartTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            end_time = $null
            duration_seconds = 0
        }
        checks = @{}
        success = $true
        warnings = @()
        errors = @()
    }
    
    # System info
    $results.system = @{
        platform = if ($IsWindows) { "Windows" } elseif ($IsMacOS) { "macOS" } elseif ($IsLinux) { "Linux" } else { "Unknown" }
        os_version = [System.Environment]::OSVersion.VersionString
        powershell_version = $PSVersionTable.PSVersion.ToString()
        architecture = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    }
    
    Write-DoctorLog "System: $($results.system.platform) $($results.system.os_version)" "INFO"
    Write-DoctorLog "PowerShell: $($results.system.powershell_version)" "INFO"
    
    # Proxy info
    $results.proxy = @{
        https_proxy = $env:HTTPS_PROXY
        http_proxy = $env:HTTP_PROXY
        no_proxy = $env:NO_PROXY
    }
    
    if ($results.proxy.https_proxy -or $results.proxy.http_proxy) {
        Write-DoctorLog "Proxy detected" "INFO"
    }
    
    # PowerShell version check
    $results.checks.powershell = @{
        version = $PSVersionTable.PSVersion.ToString()
        meets_minimum = Test-PowerShellVersion -Config $config
    }
    
    if (-not $results.checks.powershell.meets_minimum) {
        $results.errors += "PowerShell version below minimum"
    }
    
    # Azure CLI check
    $azResult, $azVersion = Test-AzureCli
    $results.checks.azure_cli = @{
        installed = $azResult
        version = $azVersion
    }
    
    if (-not $azResult) {
        $results.warnings += "Azure CLI not found"
    }
    
    # Azure context check
    $contextResult, $context = Test-AzureContext
    $results.checks.azure_context = @{
        has_context = $contextResult
        account = if ($context) { $context.Account.Id } else { $null }
        tenant = if ($context) { $context.Tenant.Id } else { $null }
    }
    
    if (-not $contextResult) {
        $results.warnings += "No Azure context found"
    }
    
    # Python environment check
    $pythonResult, $pythonVersion, $packageCount = Test-PythonEnvironment
    $venvPath = if ($IsWindows) { ".venv\Scripts\python.exe" } else { ".venv/bin/python" }
    $venvExists = Test-Path $venvPath
    $results.checks.python = @{
        installed = $pythonResult
        version = $pythonVersion
        venv_exists = $venvExists
        package_count = $packageCount
    }
    
    if (-not $pythonResult) {
        $results.errors += "Python not found"
    }
    
    # PowerShell modules check
    $modulesResult = Test-PowerShellModules -Config $config
    $results.checks.powershell_modules = $modulesResult
    
    # Check for missing required modules
    $missingModules = $modulesResult.required | Where-Object { $_.status -eq "missing" }
    if ($missingModules.Count -gt 0) {
        $results.errors += "Missing required PowerShell modules: $($missingModules.name -join ', ')"
    }
    
    # Check for outdated modules
    $outdatedModules = $modulesResult.required | Where-Object { $_.status -eq "outdated" }
    if ($outdatedModules.Count -gt 0) {
        $results.warnings += "Outdated PowerShell modules: $($outdatedModules.name -join ', ')"
    }
    
    # Bootstrap test
    $bootstrapResult = Test-Bootstrap
    $results.checks.bootstrap = $bootstrapResult
    
    if (-not $bootstrapResult.success) {
        $results.warnings += "Bootstrap test failed"
    }
    
    # Finalize timing
    $endTime = Get-Date
    $duration = $endTime - $Script:StartTime
    $results.doctor.end_time = $endTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $results.doctor.duration_seconds = $duration.TotalSeconds
    
    # Write summary
    Write-Summary -SummaryData $results
    
    # Output summary to console
    Write-Host ""
    Write-Host "=== Doctor Check Summary ===" -ForegroundColor Cyan
    Write-Host "Run ID: $Script:RunId"
    Write-Host "Duration: $($duration.TotalSeconds.ToString('F2')) seconds"
    Write-Host ""
    
    Write-Host "PowerShell: $($results.checks.powershell.version) - $(if($results.checks.powershell.meets_minimum){"OK"}else{"BELOW MINIMUM"})" -ForegroundColor $(if($results.checks.powershell.meets_minimum){"Green"}else{"Red"})
    Write-Host "Azure CLI: $(if($results.checks.azure_cli.installed){"Installed ($($results.checks.azure_cli.version))"}else{"Not found"})" -ForegroundColor $(if($results.checks.azure_cli.installed){"Green"}else{"Yellow"})
    Write-Host "Azure Context: $(if($results.checks.azure_context.has_context){"Connected ($($results.checks.azure_context.account))"}else{"Not connected"})" -ForegroundColor $(if($results.checks.azure_context.has_context){"Green"}else{"Yellow"})
    Write-Host "Python: $(if($results.checks.python.installed){"Installed ($($results.checks.python.version))"}else{"Not found"})" -ForegroundColor $(if($results.checks.python.installed){"Green"}else{"Red"})
    Write-Host "Virtual Environment: $(if($results.checks.python.venv_exists){"Exists ($($results.checks.python.package_count) packages)"}else{"Not found"})" -ForegroundColor $(if($results.checks.python.venv_exists){"Green"}else{"Yellow"})
    
    Write-Host ""
    Write-Host "Required Modules:" -ForegroundColor Cyan
    foreach ($module in $results.checks.powershell_modules.required) {
        $color = switch ($module.status) {
            "ok" { "Green" }
            "outdated" { "Yellow" }
            "missing" { "Red" }
            default { "White" }
        }
        Write-Host "  $($module.name): $($module.installed_version) (required: $($module.required_version)) - $($module.status.ToUpper())" -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "Optional Modules:" -ForegroundColor Cyan
    foreach ($module in $results.checks.powershell_modules.optional) {
        $color = switch ($module.status) {
            "ok" { "Green" }
            "outdated" { "Yellow" }
            "missing" { "Gray" }
            default { "White" }
        }
        Write-Host "  $($module.name): $($module.installed_version) (required: $($module.required_version)) - $($module.status.ToUpper())" -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "Bootstrap Test:" -ForegroundColor Cyan
    if ($results.checks.bootstrap.script_exists) {
        $bootstrapColor = if ($results.checks.bootstrap.success) { "Green" } else { "Red" }
        Write-Host "  Test Script: Found" -ForegroundColor Green
        Write-Host "  Status: $(if($results.checks.bootstrap.success){"Success"}else{"Failed (exit code: $($results.checks.bootstrap.exit_code))"})" -ForegroundColor $bootstrapColor
    } else {
        Write-Host "  Test Script: Not found" -ForegroundColor Red
    }
    
    Write-Host ""
    if ($results.errors.Count -gt 0) {
        Write-Host "Errors: $($results.errors.Count)" -ForegroundColor Red
        foreach ($error in $results.errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    
    if ($results.warnings.Count -gt 0) {
        Write-Host "Warnings: $($results.warnings.Count)" -ForegroundColor Yellow
        foreach ($warning in $results.warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    # Determine exit code
    if ($results.errors.Count -gt 0) {
        Write-DoctorLog "Doctor check completed with $($results.errors.Count) errors" "ERROR"
        exit 1
    } elseif ($results.warnings.Count -gt 0) {
        Write-DoctorLog "Doctor check completed with $($results.warnings.Count) warnings" "WARN"
        exit 2
    } else {
        Write-DoctorLog "Doctor check completed successfully" "INFO"
        exit 0
    }
}

# Execute main function
Main
