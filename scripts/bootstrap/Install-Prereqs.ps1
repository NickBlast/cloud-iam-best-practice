<#
.SYNOPSIS
    Bootstrap script to install/verify prerequisites for Azure RBAC export scripts.

.DESCRIPTION
    This script ensures all required runtimes, CLIs, modules, and Python packages
    are installed and up to date. It provides narrated steps and logs all actions.

    Supports Windows, macOS, and Linux with platform-specific package managers.

.PARAMETER NonInteractive
    Run in non-interactive mode (no prompts, fail on missing auto-install).

.PARAMETER UpdateDeps
    Allow latest compatible versions instead of pinned versions.

.PARAMETER DryRun
    Show what would be done without making changes.

.PARAMETER BootstrapLogPath
    Custom path for bootstrap logs (default: logs/bootstrap/).

.EXAMPLE
    # Install prerequisites interactively
    .\Install-Prereqs.ps1

.EXAMPLE
    # Non-interactive install for automation
    .\Install-Prereqs.ps1 -NonInteractive

.EXAMPLE
    # Dry run to see what would be done
    .\Install-Prereqs.ps1 -DryRun

.NOTES
    Requires PowerShell 7.3+
    Version: 1.0.0
#>

#requires -version 7.3

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$NonInteractive,
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateDeps,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
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

function Write-BootstrapLog {
    <#
    .SYNOPSIS
        Write bootstrap-specific log entries.
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
    
    $logPath = Join-Path $bootstrapLogDir "install_prereqs_${Script:RunId}.log"
    
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
    $jsonLogPath = Join-Path $bootstrapLogDir "install_prereqs_${Script:RunId}.jsonl"
    $logEntry = @{
        ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        run_id = $Script:RunId
        script = "bootstrap/install_prereqs"
        level = $Level
        event = $Message
        detail = $Detail
    }
    
    $jsonEntry = $logEntry | ConvertTo-Json -Compress
    Add-Content -Path $jsonLogPath -Value $jsonEntry -Encoding UTF8
}

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Get system information for logging.
    #>
    [CmdletBinding()]
    param()
    
    $systemInfo = @{
        OS = [System.Environment]::OSVersion.VersionString
        Platform = if ($IsWindows) { "Windows" } elseif ($IsMacOS) { "macOS" } elseif ($IsLinux) { "Linux" } else { "Unknown" }
        Architecture = [System.Environment]::Is64BitOperatingSystem
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        PSEdition = $PSVersionTable.PSEdition
    }
    
    return $systemInfo
}

function Get-ProxyInfo {
    <#
    .SYNOPSIS
        Get proxy environment information.
    #>
    [CmdletBinding()]
    param()
    
    $proxyInfo = @{
        HTTPS_PROXY = $env:HTTPS_PROXY
        HTTP_PROXY = $env:HTTP_PROXY
        NO_PROXY = $env:NO_PROXY
    }
    
    return $proxyInfo
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
            Write-BootstrapLog "Loaded versions configuration from $Script:VersionsFile" "INFO"
            return $config
        } else {
            Write-BootstrapLog "Versions file not found: $Script:VersionsFile" "ERROR"
            return $null
        }
    } catch {
        Write-BootstrapLog "Failed to load versions configuration: $_" "ERROR"
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
    
    Write-BootstrapLog "Checking PowerShell version: current=$currentVersion, minimum=$minVersion" "INFO"
    
    if ($currentVersion -ge $minVersion) {
        Write-BootstrapLog "PowerShell version $currentVersion meets minimum requirement $minVersion" "INFO"
        return $true
    } else {
        Write-BootstrapLog "PowerShell version $currentVersion is below minimum $minVersion" "ERROR"
        return $false
    }
}

function Install-PowerShell {
    <#
    .SYNOPSIS
        Install/upgrade PowerShell if needed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    if ($DryRun) {
        Write-BootstrapLog "DRY RUN: Would install PowerShell" "INFO"
        return $true
    }
    
    Write-BootstrapLog "PowerShell installation/upgrade required" "INFO"
    
    if ($NonInteractive) {
        Write-BootstrapLog "Non-interactive mode: Cannot install PowerShell automatically" "WARN"
        Write-BootstrapLog "Please install PowerShell 7.3+ manually:" "INFO"
        
        if ($IsWindows) {
            Write-BootstrapLog "  Option 1: winget install Microsoft.PowerShell" "INFO"
            Write-BootstrapLog "  Option 2: choco install powershell-core" "INFO"
            Write-BootstrapLog "  Option 3: Download from https://github.com/PowerShell/PowerShell/releases" "INFO"
        } elseif ($IsMacOS) {
            Write-BootstrapLog "  brew install --cask powershell" "INFO"
        } elseif ($IsLinux) {
            Write-BootstrapLog "  Follow instructions at https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux" "INFO"
        }
        
        return $false
    }
    
    # Interactive mode - offer installation options
    Write-BootstrapLog "Interactive installation not implemented in this version" "WARN"
    Write-BootstrapLog "Please install PowerShell 7.3+ manually and re-run this script" "INFO"
    
    return $false
}

function Test-AzureCli {
    <#
    .SYNOPSIS
        Check if Azure CLI is installed and meets minimum version.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    try {
        $azVersionOutput = az --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-BootstrapLog "Azure CLI not found or not in PATH" "WARN"
            return $false
        }
        
        # Parse version from output
        $versionLine = $azVersionOutput | Where-Object { $_ -match "^azure-cli\s+" }
        if ($versionLine) {
            $currentVersion = [System.Version]($versionLine -split '\s+')[1]
            $minVersion = [System.Version]$Config.minimums.azureCli
            
            Write-BootstrapLog "Azure CLI version: current=$currentVersion, minimum=$minVersion" "INFO"
            
            if ($currentVersion -ge $minVersion) {
                Write-BootstrapLog "Azure CLI version $currentVersion meets minimum requirement $minVersion" "INFO"
                return $true
            } else {
                Write-BootstrapLog "Azure CLI version $currentVersion is below minimum $minVersion" "WARN"
                return $false
            }
        } else {
            Write-BootstrapLog "Could not parse Azure CLI version" "WARN"
            return $false
        }
    } catch {
        Write-BootstrapLog "Failed to check Azure CLI version: $_" "WARN"
        return $false
    }
}

function Install-AzureCli {
    <#
    .SYNOPSIS
        Install/upgrade Azure CLI.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    if ($DryRun) {
        Write-BootstrapLog "DRY RUN: Would install Azure CLI" "INFO"
        return $true
    }
    
    Write-BootstrapLog "Installing/upgrading Azure CLI" "INFO"
    
    try {
        if ($IsWindows) {
            # Try winget first
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-BootstrapLog "Installing Azure CLI via winget" "INFO"
                if (-not $NonInteractive) {
                    winget install Microsoft.AzureCLI
                } else {
                    winget install Microsoft.AzureCLI --silent
                }
            } else {
                Write-BootstrapLog "winget not found, please install Azure CLI manually" "WARN"
                return $false
            }
        } elseif ($IsMacOS) {
            # Try brew
            if (Get-Command brew -ErrorAction SilentlyContinue) {
                Write-BootstrapLog "Installing Azure CLI via brew" "INFO"
                brew update
                brew install azure-cli
            } else {
                Write-BootstrapLog "brew not found, please install Azure CLI manually" "WARN"
                return $false
            }
        } elseif ($IsLinux) {
            # Try package managers
            if (Get-Command apt-get -ErrorAction SilentlyContinue) {
                Write-BootstrapLog "Installing Azure CLI via apt" "INFO"
                curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            } elseif (Get-Command yum -ErrorAction SilentlyContinue) {
                Write-BootstrapLog "Installing Azure CLI via yum" "INFO"
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
                sudo yum install azure-cli
            } else {
                Write-BootstrapLog "No supported package manager found, please install Azure CLI manually" "WARN"
                return $false
            }
        }
        
        Write-BootstrapLog "Azure CLI installation completed" "INFO"
        return $true
    } catch {
        Write-BootstrapLog "Failed to install Azure CLI: $_" "ERROR"
        return $false
    }
}

function Test-Python {
    <#
    .SYNOPSIS
        Check if Python is installed and meets minimum version.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    try {
        $pythonVersionOutput = python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            # Try python3
            $pythonVersionOutput = python3 --version 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-BootstrapLog "Python not found or not in PATH" "WARN"
                return $false
            }
            $pythonCmd = "python3"
        } else {
            $pythonCmd = "python"
        }
        
        # Parse version
        $versionMatch = [regex]::Match($pythonVersionOutput, "Python\s+(\d+\.\d+\.\d+)")
        if ($versionMatch.Success) {
            $currentVersion = [System.Version]$versionMatch.Groups[1].Value
            $minVersion = [System.Version]$Config.minimums.python
            
            Write-BootstrapLog "Python version: current=$currentVersion, minimum=$minVersion (using $pythonCmd)" "INFO"
            
            if ($currentVersion -ge $minVersion) {
                Write-BootstrapLog "Python version $currentVersion meets minimum requirement $minVersion" "INFO"
                return $true, $pythonCmd
            } else {
                Write-BootstrapLog "Python version $currentVersion is below minimum $minVersion" "WARN"
                return $false, $pythonCmd
            }
        } else {
            Write-BootstrapLog "Could not parse Python version from: $pythonVersionOutput" "WARN"
            return $false, $pythonCmd
        }
    } catch {
        Write-BootstrapLog "Failed to check Python version: $_" "WARN"
        return $false, "python"
    }
}

function Install-Python {
    <#
    .SYNOPSIS
        Install/upgrade Python and create virtual environment.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    if ($DryRun) {
        Write-BootstrapLog "DRY RUN: Would install Python and create virtual environment" "INFO"
        return $true
    }
    
    Write-BootstrapLog "Installing/upgrading Python" "INFO"
    
    try {
        if ($IsWindows) {
            # Try winget first
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-BootstrapLog "Installing Python via winget" "INFO"
                if (-not $NonInteractive) {
                    winget install Python.Python.3
                } else {
                    winget install Python.Python.3 --silent
                }
            } else {
                Write-BootstrapLog "winget not found, please install Python manually" "WARN"
                return $false
            }
        } elseif ($IsMacOS) {
            # Try brew
            if (Get-Command brew -ErrorAction SilentlyContinue) {
                Write-BootstrapLog "Installing Python via brew" "INFO"
                brew install python
            } else {
                Write-BootstrapLog "brew not found, please install Python manually" "WARN"
                return $false
            }
        } elseif ($IsLinux) {
            # Try package managers
            if (Get-Command apt-get -ErrorAction SilentlyContinue) {
                Write-BootstrapLog "Installing Python via apt" "INFO"
                sudo apt update
                sudo apt install python3 python3-pip python3-venv
            } elseif (Get-Command yum -ErrorAction SilentlyContinue) {
                Write-BootstrapLog "Installing Python via yum" "INFO"
                sudo yum install python3 python3-pip
            } else {
                Write-BootstrapLog "No supported package manager found, please install Python manually" "WARN"
                return $false
            }
        }
        
        Write-BootstrapLog "Python installation completed" "INFO"
        return $true
    } catch {
        Write-BootstrapLog "Failed to install Python: $_" "ERROR"
        return $false
    }
}

function Setup-VirtualEnvironment {
    <#
    .SYNOPSIS
        Create and setup Python virtual environment.
    #>
    [CmdletBinding()]
    param()
    
    if ($DryRun) {
        Write-BootstrapLog "DRY RUN: Would create virtual environment" "INFO"
        return $true
    }
    
    Write-BootstrapLog "Setting up Python virtual environment" "INFO"
    
    try {
        # Determine Python command
        $pythonCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
        
        # Create virtual environment
        Write-BootstrapLog "Creating virtual environment in .venv" "INFO"
        & $pythonCmd -m venv .venv
        
        if ($LASTEXITCODE -ne 0) {
            Write-BootstrapLog "Failed to create virtual environment" "ERROR"
            return $false
        }
        
        # Upgrade pip, wheel, setuptools
        $venvPython = if ($IsWindows) { ".venv\Scripts\python.exe" } else { ".venv/bin/python" }
        Write-BootstrapLog "Upgrading pip, wheel, setuptools in virtual environment" "INFO"
        & $venvPython -m pip install --upgrade pip wheel setuptools
        
        if ($LASTEXITCODE -ne 0) {
            Write-BootstrapLog "Failed to upgrade pip/wheel/setuptools" "ERROR"
            return $false
        }
        
        Write-BootstrapLog "Virtual environment setup completed" "INFO"
        return $true
    } catch {
        Write-BootstrapLog "Failed to setup virtual environment: $_" "ERROR"
        return $false
    }
}

function Install-PythonPackages {
    <#
    .SYNOPSIS
        Install Python packages in virtual environment.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    if ($DryRun) {
        Write-BootstrapLog "DRY RUN: Would install Python packages" "INFO"
        return $true
    }
    
    Write-BootstrapLog "Installing Python packages" "INFO"
    
    try {
        $venvPython = if ($IsWindows) { ".venv\Scripts\python.exe" } else { ".venv/bin/python" }
        $requirementsFile = $Config.python.requirements
        $constraintsFile = $Config.python.constraints
        
        # Build pip install command
        $pipArgs = @("-m", "pip", "install")
        
        if ($UpdateDeps) {
            Write-BootstrapLog "Installing latest compatible versions (UpdateDeps mode)" "INFO"
        } else {
            # Use constraints file for pinned versions
            if (Test-Path $constraintsFile) {
                $pipArgs += "--constraint", $constraintsFile
                Write-BootstrapLog "Using constraints file: $constraintsFile" "INFO"
            }
        }
        
        # Add requirements file
        if (Test-Path $requirementsFile) {
            $pipArgs += "--requirement", $requirementsFile
            Write-BootstrapLog "Installing from requirements file: $requirementsFile" "INFO"
        } else {
            Write-BootstrapLog "Requirements file not found: $requirementsFile" "WARN"
            return $false
        }
        
        # Check for wheelhouse or custom index
        if (Test-Path "wheelhouse") {
            $pipArgs += "--find-links", "wheelhouse"
            Write-BootstrapLog "Using local wheelhouse" "INFO"
        }
        
        if ($env:PIP_INDEX_URL) {
            Write-BootstrapLog "Using custom PIP index: $env:PIP_INDEX_URL" "INFO"
        }
        
        # Execute pip install
        Write-BootstrapLog "Running: $venvPython $($pipArgs -join ' ')" "DEBUG"
        & $venvPython @pipArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-BootstrapLog "Failed to install Python packages" "ERROR"
            return $false
        }
        
        Write-BootstrapLog "Python packages installed successfully" "INFO"
        return $true
    } catch {
        Write-BootstrapLog "Failed to install Python packages: $_" "ERROR"
        return $false
    }
}

function Test-PowerShellModules {
    <#
    .SYNOPSIS
        Check if required PowerShell modules are installed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    $allModulesFound = $true
    
    # Check required modules
    foreach ($module in $Config.powershellModules) {
        try {
            $installedModule = Get-Module -ListAvailable -Name $module.name -ErrorAction SilentlyContinue | 
                              Where-Object { $_.Version -ge [System.Version]$module.version }
            
            if ($installedModule) {
                Write-BootstrapLog "Module $($module.name) $($installedModule.Version) meets requirement $($module.version)" "INFO"
            } else {
                Write-BootstrapLog "Module $($module.name) not found or below version $($module.version)" "WARN"
                $allModulesFound = $false
            }
        } catch {
            Write-BootstrapLog "Failed to check module $($module.name): $_" "WARN"
            $allModulesFound = $false
        }
    }
    
    return $allModulesFound
}

function Install-PowerShellModules {
    <#
    .SYNOPSIS
        Install/update PowerShell modules.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    if ($DryRun) {
        Write-BootstrapLog "DRY RUN: Would install PowerShell modules" "INFO"
        return $true
    }
    
    Write-BootstrapLog "Installing PowerShell modules" "INFO"
    
    try {
        foreach ($module in $Config.powershellModules) {
            $installParams = @{
                Name = $module.name
                Scope = "CurrentUser"
                Repository = "PSGallery"
                Force = $true
                AllowClobber = $true
            }
            
            if (-not $UpdateDeps) {
                $installParams["RequiredVersion"] = $module.version
            }
            
            Write-BootstrapLog "Installing module $($module.name) version $($module.version)" "INFO"
            Install-Module @installParams -ErrorAction Stop
        }
        
        Write-BootstrapLog "PowerShell modules installed successfully" "INFO"
        return $true
    } catch {
        Write-BootstrapLog "Failed to install PowerShell modules: $_" "ERROR"
        return $false
    }
}

function Test-OptionalPowerShellModules {
    <#
    .SYNOPSIS
        Check if optional PowerShell modules are installed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    foreach ($module in $Config.powershellOptionalModules) {
        try {
            $installedModule = Get-Module -ListAvailable -Name $module.name -ErrorAction SilentlyContinue | 
                              Where-Object { $_.Version -ge [System.Version]$module.version }
            
            if ($installedModule) {
                Write-BootstrapLog "Optional module $($module.name) $($installedModule.Version) available" "INFO"
            } else {
                Write-BootstrapLog "Optional module $($module.name) not found or below version $($module.version)" "INFO"
            }
        } catch {
            Write-BootstrapLog "Failed to check optional module $($module.name): $_" "INFO"
        }
    }
}

function Write-Summary {
    <#
    .SYNOPSIS
        Write bootstrap summary JSON file.
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
        
        $summaryPath = Join-Path $bootstrapLogDir "install_prereqs_${Script:RunId}_summary.json"
        $SummaryData | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8
        Write-BootstrapLog "Summary written to $summaryPath" "INFO"
    } catch {
        Write-BootstrapLog "Failed to write summary: $_" "ERROR"
    }
}

function Test-DoctorChecks {
    <#
    .SYNOPSIS
        Perform doctor checks (same as doctor.ps1 but integrated).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )
    
    $doctorResults = @{
        success = $true
        warnings = @()
        errors = @()
        checks = @{}
    }
    
    Write-BootstrapLog "Running doctor checks..." "INFO"
    
    # Check PowerShell context
    try {
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if ($context -and $context.Account) {
            $doctorResults.checks["az_context"] = @{
                status = "ok"
                account = $context.Account.Id
                tenant = $context.Tenant.Id
            }
            Write-BootstrapLog "Azure context: $($context.Account.Id)" "INFO"
        } else {
            $doctorResults.checks["az_context"] = @{
                status = "warning"
                message = "Not connected to Azure"
            }
            Write-BootstrapLog "Not connected to Azure" "WARN"
            $doctorResults.warnings += "Not connected to Azure"
        }
    } catch {
        $doctorResults.checks["az_context"] = @{
            status = "error"
            message = "Failed to get Azure context: $_"
        }
        Write-BootstrapLog "Failed to get Azure context: $_" "WARN"
        $doctorResults.warnings += "Failed to get Azure context"
    }
    
    # Check Azure CLI
    try {
        $azVersion = az --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $versionLine = $azVersion | Where-Object { $_ -match "^azure-cli\s+" }
            if ($versionLine) {
                $version = ($versionLine -split '\s+')[1]
                $doctorResults.checks["az_cli"] = @{
                    status = "ok"
                    version = $version
                }
                Write-BootstrapLog "Azure CLI version: $version" "INFO"
            }
        } else {
            $doctorResults.checks["az_cli"] = @{
                status = "warning"
                message = "Azure CLI not found or not in PATH"
            }
            Write-BootstrapLog "Azure CLI not found" "WARN"
            $doctorResults.warnings += "Azure CLI not found"
        }
    } catch {
        $doctorResults.checks["az_cli"] = @{
            status = "warning"
            message = "Failed to check Azure CLI: $_"
        }
        Write-BootstrapLog "Failed to check Azure CLI: $_" "WARN"
        $doctorResults.warnings += "Failed to check Azure CLI"
    }
    
    # Check Python packages in venv
    try {
        $venvPython = if ($IsWindows) { ".venv\Scripts\python.exe" } else { ".venv/bin/python" }
        if (Test-Path $venvPython) {
            $pipList = & $venvPython -m pip list 2>&1
            if ($LASTEXITCODE -eq 0) {
                $doctorResults.checks["python_packages"] = @{
                    status = "ok"
                    count = ($pipList | Measure-Object).Count
                }
                Write-BootstrapLog "Python virtual environment has packages installed" "INFO"
            } else {
                $doctorResults.checks["python_packages"] = @{
                    status = "warning"
                    message = "Failed to list Python packages"
                }
                Write-BootstrapLog "Failed to list Python packages" "WARN"
                $doctorResults.warnings += "Failed to list Python packages"
            }
        } else {
            $doctorResults.checks["python_packages"] = @{
                status = "warning"
                message = "Virtual environment not found"
            }
            Write-BootstrapLog "Virtual environment not found" "WARN"
            $doctorResults.warnings += "Virtual environment not found"
        }
    } catch {
        $doctorResults.checks["python_packages"] = @{
            status = "warning"
            message = "Failed to check Python packages: $_"
        }
        Write-BootstrapLog "Failed to check Python packages: $_" "WARN"
        $doctorResults.warnings += "Failed to check Python packages"
    }
    
    return $doctorResults
}

# Main function
function Main {
    [CmdletBinding()]
    param()
    
    Write-BootstrapLog "Starting bootstrap process (Run ID: $Script:RunId)" "INFO"
    
    # Get system info
    $systemInfo = Get-SystemInfo
    $proxyInfo = Get-ProxyInfo
    
    Write-BootstrapLog "System: $($systemInfo.Platform) $($systemInfo.OS)" "INFO"
    Write-BootstrapLog "PowerShell: $($systemInfo.PowerShellVersion)" "INFO"
    
    if ($proxyInfo.HTTPS_PROXY -or $proxyInfo.HTTP_PROXY) {
        Write-BootstrapLog "Proxy: HTTPS=$($proxyInfo.HTTPS_PROXY), HTTP=$($proxyInfo.HTTP_PROXY)" "INFO"
    }
    
    # Load configuration
    $config = Load-VersionsConfig
    if (-not $config) {
        Write-BootstrapLog "Failed to load configuration, exiting" "ERROR"
        exit 1
    }
    
    # Initialize results
    $results = @{
        bootstrap = @{
            run_id = $Script:RunId
            start_time = $Script:StartTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            end_time = $null
            duration_seconds = 0
            actions = @()
            system_info = $systemInfo
            proxy_info = $proxyInfo
        }
        success = $true
        warnings = @()
        errors = @()
    }
    
    # Check PowerShell version
    if (-not (Test-PowerShellVersion -Config $config)) {
        $results.success = $false
        $results.errors += "PowerShell version check failed"
        
        if (-not $DryRun) {
            if (-not (Install-PowerShell -Config $config)) {
                if (-not $NonInteractive) {
                    Write-BootstrapLog "PowerShell installation failed, please install manually" "ERROR"
                    exit 1
                }
            }
        }
    } else {
        $results.bootstrap.actions += "powershell_version_check"
    }
    
    # Check Azure CLI
    if (-not (Test-AzureCli -Config $config)) {
        if (-not $DryRun) {
            if (-not (Install-AzureCli -Config $config)) {
                if (-not $NonInteractive) {
                    $results.success = $false
                    $results.errors += "Azure CLI installation failed"
                } else {
                    $results.warnings += "Azure CLI installation failed (non-interactive mode)"
                }
            } else {
                $results.bootstrap.actions += "az_cli_install"
            }
        } else {
            $results.bootstrap.actions += "az_cli_check"
        }
    } else {
        $results.bootstrap.actions += "az_cli_check"
    }
    
    # Check Python
    $pythonResult, $pythonCmd = Test-Python -Config $config
    if (-not $pythonResult) {
        if (-not $DryRun) {
            if (-not (Install-Python -Config $config)) {
                if (-not $NonInteractive) {
                    $results.success = $false
                    $results.errors += "Python installation failed"
                } else {
                    $results.warnings += "Python installation failed (non-interactive mode)"
                }
            } else {
                $results.bootstrap.actions += "python_install"
                
                # Setup virtual environment
                if (Setup-VirtualEnvironment) {
                    $results.bootstrap.actions += "venv_setup"
                } else {
                    $results.success = $false
                    $results.errors += "Virtual environment setup failed"
                }
            }
        } else {
            $results.bootstrap.actions += "python_check"
        }
    } else {
        $results.bootstrap.actions += "python_check"
        
        # Setup virtual environment if it doesn't exist
        $venvPath = if ($IsWindows) { ".venv\Scripts\python.exe" } else { ".venv/bin/python" }
        if (-not (Test-Path $venvPath)) {
            if (-not $DryRun) {
                if (Setup-VirtualEnvironment) {
                    $results.bootstrap.actions += "venv_setup"
                } else {
                    $results.success = $false
                    $results.errors += "Virtual environment setup failed"
                }
            }
        }
    }
    
    # Install Python packages
    if (-not $DryRun) {
        if (Install-PythonPackages -Config $config) {
            $results.bootstrap.actions += "python_packages_install"
        } else {
            $results.success = $false
            $results.errors += "Python packages installation failed"
        }
    } else {
        $results.bootstrap.actions += "python_packages_check"
    }
    
    # Check PowerShell modules
    if (-not (Test-PowerShellModules -Config $config)) {
        if (-not $DryRun) {
            if (Install-PowerShellModules -Config $config)) {
                $results.bootstrap.actions += "ps_modules_install"
            } else {
                $results.success = $false
                $results.errors += "PowerShell modules installation failed"
            }
        } else {
            $results.bootstrap.actions += "ps_modules_check"
        }
    } else {
        $results.bootstrap.actions += "ps_modules_check"
    }
    
    # Check optional modules
    Test-OptionalPowerShellModules -Config $config
    $results.bootstrap.actions += "ps_optional_modules_check"
    
    # Run doctor checks
    $doctorResults = Test-DoctorChecks -Config $config
    $results.doctor = $doctorResults
    
    # Update results with doctor findings
    if ($doctorResults.warnings.Count -gt 0) {
        $results.warnings += $doctorResults.warnings
    }
    
    if ($doctorResults.errors.Count -gt 0) {
        $results.errors += $doctorResults.errors
    }
    
    # Finalize timing
    $endTime = Get-Date
    $duration = $endTime - $Script:StartTime
    $results.bootstrap.end_time = $endTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $results.bootstrap.duration_seconds = $duration.TotalSeconds
    
    # Write summary
    Write-Summary -SummaryData $results
    
    # Determine exit code
    if ($results.errors.Count -gt 0) {
        Write-BootstrapLog "Bootstrap completed with $($results.errors.Count) errors" "ERROR"
        exit 1
    } elseif ($results.warnings.Count -gt 0) {
        Write-BootstrapLog "Bootstrap completed with $($results.warnings.Count) warnings" "WARN"
        exit 2
    } else {
        Write-BootstrapLog "Bootstrap completed successfully" "INFO"
        exit 0
    }
}

# Execute main function
Main
