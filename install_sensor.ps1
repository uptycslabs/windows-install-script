# Authors: nkarthik@uptycs.com, jwayte@uptycs.com
# Updated: July 24 2025

param(
    [Parameter(Mandatory = $true)]
    [string]$MsiPath,

    [Parameter(Mandatory = $false)]
    [switch]$Silent,

    [Parameter(Mandatory = $false)]
    [string]$InstallProperties = "",

    [Parameter(Mandatory = $false)]
    [string]$LogPath
)

# --- CHECK AND MODIFY SAC ENFORCEMENT MODE ---
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
$registryValue = "VerifiedAndReputablePolicyState"

try {
    $currentState = Get-ItemProperty -Path $registryPath -Name $registryValue -ErrorAction Stop
    $state = $currentState.$registryValue
    Write-Host "Current Smart App Control (SAC) State: $state (0=OFF, 1=ON, 2=EVALUATION)"

    if ($state -eq 1) {
        Write-Host "SAC is in Enforcement mode. Switching to Evaluation mode (2)..."
        try
           {
                Set-ItemProperty -Path $registryPath -Name $registryValue -Value 2 -Type DWord -Force
           }
        catch
           {
                Write-Error "Unable to modify SAC state to Eval Mode. Details: $($_.Exception.Message)"
           }

        Start-Process -FilePath "gpupdate.exe" -ArgumentList "/force" -Wait 
         
        $newState = (Get-ItemProperty -Path $registryPath -Name $registryValue).$registryValue
        if ($newState -ne 2) {
            Write-Error "Failed to change SAC to Evaluation mode. Aborting installation"
            exit 1
        } else {
           Write-Host "SAC set to Eval mode. Please restart your system and run this script again to complete Uptycs Installation"
           exit 0
        }
    }
}
catch {
    Write-Warning "Unable to check or modify SAC state. Details: $($_.Exception.Message)"
}

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

    return $exitCode
}
catch {
    Write-Error "An unexpected error occurred: $($_.Exception.Message)"
    return 1
}
finally {
    # Re-enable SmartScreen
    Set-MpPreference -EnableNetworkProtection Enabled

    # Re-enable UAC
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Type DWord

    # Optional: Display UAC status
    $uacStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA"
    Write-Host "UAC status re-enabled: $($uacStatus.EnableLUA)"

}
