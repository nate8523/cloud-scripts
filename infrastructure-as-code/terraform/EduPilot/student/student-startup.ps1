<#
    student-startup.ps1
    This script runs on each student VM at first boot.
    It downloads and installs the Veyon agent in silent mode using the recommended parameters:
      - /S             : Silent installation.
      - /NoMaster      : Install without the Veyon Master component.
      - /NoStartMenuFolder : Do not create a start menu folder.
    Optionally, you can specify an installation directory (/D=...) or apply a configuration (/ApplyConfig=...).
    
    Note: This script must be executed with administrative privileges.
#>

# Ensure the script is running as Administrator.
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator"))
{
    Write-Error "This script must be run as Administrator. Exiting."
    exit 1
}

Write-Output "Starting student VM initialization..."

# Define the URL for the Veyon installer.
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

# Build the installer arguments.
# /S for silent installation
# /NoMaster to install without the Veyon Master component
# /NoStartMenuFolder to avoid creating a start menu folder
# Optionally, uncomment and adjust the following lines if you wish to specify an installation directory or apply a configuration:
#
#$installDir = "C:\Veyon"  # Must be an absolute path. This parameter must come last if used.
#$configFile = "C:\Path\To\MyConfig.json"  # Absolute path to the configuration file.
#
# If you want to apply the configuration automatically, add: /ApplyConfig=$configFile
#
# In this example, we'll install without the Master component and without a start menu folder:
$installerArgs = "/S /NoMaster /NoStartMenuFolder"
#
# Uncomment the following line to specify an installation directory (must be last):
# $installerArgs = "$installerArgs /D=$installDir"
#
# Uncomment the following line to automatically apply a configuration:
# $installerArgs = "$installerArgs /ApplyConfig=$configFile"

Write-Output "Installing Veyon agent in silent mode with arguments: $installerArgs"
try {
    Start-Process -FilePath $installerPath -ArgumentList $installerArgs -Wait -NoNewWindow
    Write-Output "Veyon agent installation completed successfully."
}
catch {
    Write-Error "Veyon agent installation failed. Error: $_"
    exit 1
}

# Configure and start the Veyon service.
$serviceName = "VeyonService"  # Ensure this matches the service installed by Veyon.
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($null -ne $service) {
    Write-Output "Setting Veyon agent service to start automatically..."
    try {
        Set-Service -Name $serviceName -StartupType Automatic
        Start-Service -Name $serviceName
        Write-Output "Veyon agent service is configured and started."
    }
    catch {
        Write-Warning "Failed to configure or start the Veyon agent service. Error: $_"
    }
}
else {
    Write-Warning "Veyon agent service '$serviceName' not found."
}

Write-Output "Student VM initialization complete."
