param(
    [Parameter(Mandatory = $true)]
    [string]$MsiPath,

    [Parameter(Mandatory = $false)]
    [switch]$Silent,

    [Parameter(Mandatory = $false)]
    [string]$InstallProperties = ""
)

# Disable SmartScreen temporarily 
Set-MpPreference -EnableNetworkProtection Disabled

# Disable UAC in Windows (optional) Commented
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Type DWord

# --- MSI Installation Script ---


# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if MSI file exists
if (-not (Test-Path $MsiPath)) {
    Write-Error "MSI file not found: $MsiPath"
    exit 1
}
# Check if MSI file exists
#if (Test-Path $MsiPath) {
#    Write-Error "MSI file found: $MsiPath"
#}

if (-not $Silent.IsPresent) {
    $Silent = $true
}

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Warning "Script is not running as Administrator. Some installations may fail."
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit 1
    }
}

# Set up log file path if not provided
if ([string]::IsNullOrEmpty($LogPath)) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $msiName = [System.IO.Path]::GetFileNameWithoutExtension($MsiPath)
    $LogPath = "$env:TEMP\$msiName`_install_$timestamp.log"
}

# Display installation details
Write-Host "Installing MSI: $MsiPath" -ForegroundColor Green
Write-Host "Log file: $LogPath" -ForegroundColor Yellow
Write-Host "Silent mode: $Silent" -ForegroundColor Yellow

if (-not [string]::IsNullOrEmpty($InstallProperties)) {
    Write-Host "Properties: $InstallProperties" -ForegroundColor Yellow
}

Write-Host "`nStarting installation..." -ForegroundColor Green

# Build msiexec command
$msiCommand = "/i `"$MsiPath`""

if ($Silent) {
    $msiCommand += " /quiet /norestart"
} else {
    $msiCommand += " /passive"
}

$msiCommand += " /l*v `"$LogPath`""

if (-not [string]::IsNullOrEmpty($InstallProperties)) {
    $msiCommand += " $InstallProperties"
}

Write-Host $msiCommand


# Execute the installation
try {
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiCommand -Wait -PassThru
    $exitCode = $process.ExitCode

    switch ($exitCode) {
        0 {
            Write-Host "`nInstallation completed successfully!" -ForegroundColor Green
        }
        1603 {
            Write-Error "Installation failed with error 1603 (Generic failure)"
        }
        1618 {
            Write-Error "Installation failed with error 1618 (Another installation is in progress)"
        }
        1619 {
            Write-Error "Installation failed with error 1619 (Package could not be opened)"
        }
        1620 {
            Write-Error "Installation failed with error 1620 (Invalid package)"
        }
        1633 {
            Write-Error "Installation failed with error 1633 (Unsupported platform)"
        }
        3010 {
            Write-Warning "Installation completed but requires restart (exit code 3010)"
        }
        default {
            Write-Error "Installation failed with exit code: $LASTEXITCODE"
        }
    }

    #Write-Host "Log file location: $LogPath" -ForegroundColor Cyan

    #if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
    #    $openLog = Read-Host "`nWould you like to open the log file? (y/n)"
    #    if ($openLog -eq 'y') {
    #        Start-Process notepad.exe -ArgumentList $LogPath
    #    }
    #}

    return $LASTEXITCODE
}
catch {
    Write-Error "An unexpected error occurred: $($_.Exception.Message)"
    return 1
}

# Re-enable SmartScreen (optional)
Set-MpPreference -EnableNetworkProtection Enabled

# Re-enable UAC in Windows
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Type DWord

# Verify UAC setting
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA"
