<#
    teacher-startup.ps1
    This script is intended to run on the teacher VM at first boot to:
      - Download and install the Veyon server silently.
      - Configure the Veyon service and Windows firewall settings.
      - Perform any additional initialization tasks for the EduPilot teacher VM.

    **Note:** This script must be executed with administrative privileges.
#>

# Ensure the script is running as Administrator.
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator"))
{
    Write-Error "This script must be run as Administrator. Exiting."
    exit 1
}

Write-Output "Starting teacher VM initialization..."

# Set variables for the Veyon installer.
$veyonInstallerUrl = "https://github.com/veyon/veyon/releases/download/v4.9.2/veyon-4.9.2.0-win64-setup.exe"
$installerPath = "$env:TEMP\VeyonSetup.exe"

Write-Output "Downloading Veyon installer from $veyonInstallerUrl ..."
try {
    Invoke-WebRequest -Uri $veyonInstallerUrl -OutFile $installerPath -ErrorAction Stop
    Write-Output "Download completed successfully."
}
catch {
    Write-Error "Failed to download Veyon installer. Error: $_"
    exit 1
}

Write-Output "Installing Veyon server in silent mode..."
try {
    # The '/S' argument is commonly used for silent installation; verify with your installer documentation.
    Start-Process -FilePath $installerPath -ArgumentList '/S' -Wait -NoNewWindow
    Write-Output "Veyon installation completed successfully."
}
catch {
    Write-Error "Veyon installation failed. Error: $_"
    exit 1
}

Write-Output "Configuring Veyon server settings..."

# Define the configuration file path.
$veyonConfigDir = "C:\ProgramData\Veyon"
$veyonConfigPath = Join-Path -Path $veyonConfigDir -ChildPath "config.ini"

# Create the directory if it doesn't exist.
if (-not (Test-Path $veyonConfigDir)) {
    try {
        New-Item -ItemType Directory -Path $veyonConfigDir -Force | Out-Null
        Write-Output "Created directory: $veyonConfigDir"
    }
    catch {
        Write-Error "Failed to create directory $veyonConfigDir. Error: $_"
        exit 1
    }
}

# Write a simple configuration line (customize as needed).
try {
    "Configured by teacher-startup.ps1 on $(Get-Date)" | Out-File -FilePath $veyonConfigPath -Encoding UTF8
    Write-Output "Veyon configuration file created at $veyonConfigPath."
}
catch {
    Write-Error "Failed to write to $veyonConfigPath. Error: $_"
}

# Set the correct service name for Veyon.
$serviceName = "VeyonService"

# Check for the Veyon service.
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($null -eq $service) {
    Write-Warning "Service '$serviceName' not found. Please verify the installation or adjust the service name."
} else {
    Write-Output "Setting Veyon service to start automatically..."
    try {
        Set-Service -Name $serviceName -StartupType Automatic
        Start-Service -Name $serviceName
        Write-Output "Veyon service is configured and started."
    }
    catch {
        Write-Warning "Failed to configure or start the Veyon service. Error: $_"
    }
}

# Add a firewall rule to allow RDP on port 3389.
Write-Output "Adding firewall rule for RDP on port 3389..."
try {
    if (-not (Get-NetFirewallRule -DisplayName "RDP" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow
        Write-Output "Firewall rule for RDP added."
    }
    else {
        Write-Output "Firewall rule for RDP already exists."
    }
}
catch {
    Write-Warning "Failed to add RDP firewall rule. Error: $_"
}

Write-Output "Teacher VM initialization complete."
