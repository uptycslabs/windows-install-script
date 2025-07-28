# Authors: nkarthik@uptycs.com, jwayte@uptycs.com
# Updated: July 28 2025

param(
    [Parameter(Mandatory = $true)]
    [string]$MsiPath,
  
    [Parameter(Mandatory = $true)]
    [string]$FSPath,


    [Parameter(Mandatory = $false)]
    [switch]$Silent,

    [Parameter(Mandatory = $false)]
    [string]$InstallProperties = "",

    [Parameter(Mandatory = $false)]
    [string]$LogPath
)



# --- Disable SmartScreen temporarily ---
Set-MpPreference -EnableNetworkProtection Disabled

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
        0 { Write-Host "`nInstallation completed successfully!" -ForegroundColor Green }
        1603 { Write-Error "Installation failed with error 1603 (Generic failure)" }
        1618 { Write-Error "Installation failed with error 1618 (Another installation is in progress)" }
        1619 { Write-Error "Installation failed with error 1619 (Package could not be opened)" }
        1620 { Write-Error "Installation failed with error 1620 (Invalid package)" }
        1633 { Write-Error "Installation failed with error 1633 (Unsupported platform)" }
        3010 { Write-Warning "Installation completed but requires restart (exit code 3010)" }
        default { Write-Error "Installation failed with exit code: $exitCode" }
    }

    #return $exitCode
}
catch {
    Write-Error "An unexpected error occurred: $($_.Exception.Message)"
    return 1
}

Write-Host "Wait for 20 seconds before modyfying Flags and secrets from $FSPath"
Start-Sleep -Seconds 20
Write-Host "Adding Flags and Secrets from $FSPath "
try
    {Copy-Item -Path "$FSPath\uptycs.secret", "$FSPath\osquery.flags" -Destination "C:\Program Files\Uptycs\osquery\conf" -Force}
catch
    {Write-Error "Unable to modify flags and secret. Details: $($_.Exception.Message)"}
Write-Host "Added the Flags and Secrets" -ForegroundColor Green
Write-Host "Stopping the sensor"
Stop-Service -Name "uptycsosquery"
Write-Host  "Starting the sensor"
Start-Service -Name "uptycsosquery"
Write-Host  "Status of the sensor"
Get-Service -Name "uptycsosquery"


    # Re-enable SmartScreen
    Set-MpPreference -EnableNetworkProtection Enabled

    # Re-enable UAC
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Type DWord

    # Optional: Display UAC status
    $uacStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA"
    Write-Host "UAC status re-enabled: $($uacStatus.EnableLUA)"
