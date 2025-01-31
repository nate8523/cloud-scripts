# Define the flag file to prevent duplicate execution
$FlagFile = "C:\AzureData\disk_initialized.flag"

# Function to check and start Veeam services
function Start-VeeamServices {
    $veeamServices = @(
        "Veeam.Archiver.Service",
        # "Veeam.Archiver.RESTful.Service",
        "Veeam.Archiver.Proxy.Service"
    )

    foreach ($service in $veeamServices) {
        $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($serviceStatus -and $serviceStatus.Status -ne 'Running') {
            Write-Host "Starting Veeam service: $service"
            Start-Service -Name $service
        }
    }
}

# Ensure Veeam services are running
Start-VeeamServices

# Wait for services to be fully operational
Start-Sleep -Seconds 30

# Get all uninitialized (RAW) or unallocated disks (excluding OS Disk 0 & Temp Disk 1)
$UnallocatedDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $_.Number -ge 2 }

if ((Test-Path $FlagFile) -and (-not $UnallocatedDisks)) {
    Write-Host "Disk initialization already completed and no unallocated disks found. Exiting..."
    exit 0
}

# Initialize all uninitialized (RAW) disks
$UnallocatedDisks | ForEach-Object { Initialize-Disk -Number $_.Number -PartitionStyle GPT -Confirm:$false }

# Get all online disks that do not have a drive letter and are not partitioned
$onlineDisksWithoutDriveLetter = Get-Disk | Where-Object { 
    $_.PartitionStyle -eq 'GPT' -and $_.IsOffline -eq $false -and !$_.DriveLetter -and $_.LargestFreeExtent -gt 0 -and $_.Number -ge 2
}

# Function to get the first available drive letter (starting from F)
function Get-FirstUnusedDriveLetter {
    $usedLetters = (Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter) -join ''
    $allLetters = @('F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')
    return ($allLetters | Where-Object { $_ -notin $usedLetters })[0]
}

# Assign drive letters and format disks using ReFS for Veeam
foreach ($disk in $onlineDisksWithoutDriveLetter) {
    $driveLetter = Get-FirstUnusedDriveLetter
    if (-not $driveLetter) {
        Write-Host "No available drive letters for disk $($disk.Number). Skipping..."
        continue
    }

    # Ensure the disk is not already partitioned before creating a new one
    if ($disk.LargestFreeExtent -gt 0) {
        $partition = New-Partition -DiskNumber $disk.Number -AssignDriveLetter -UseMaximumSize
        $partition | Format-Volume -FileSystem ReFS -AllocationUnitSize 64KB -Confirm:$false
        Write-Host "Disk $($disk.Number) formatted as ReFS and assigned drive letter: $driveLetter"
    } else {
        Write-Host "Disk $($disk.Number) is already partitioned. Skipping partition creation."
    }
}

# Import Veeam Backup for Microsoft 365 PowerShell module
$VeeamModulePath = "C:\Program Files\Veeam\Backup365\Veeam.Archiver.PowerShell.dll"
if (Test-Path $VeeamModulePath) {
    Import-Module $VeeamModulePath
} else {
    Write-Host "Veeam 365 PowerShell module not found. Skipping repository creation."
    exit 1
}

# Connect to the Veeam 365 proxy server
$proxy = Get-VBOProxy
if (-not $proxy) {
    Write-Host "No VBO proxy found. Exiting..."
    exit 1
}

# Add each formatted disk as a Veeam 365 backup repository
$initializedDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'GPT' -and $_.IsOffline -eq $false -and $_.Number -ge 2 }
foreach ($disk in $initializedDisks) {
    $driveLetter = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    if ($driveLetter) {
        $folderPath = $driveLetter + ":\" 
        Add-VBORepository -Proxy $proxy -Name "Local Backups $folderPath" -Path $folderPath
        Write-Host "Veeam 365 repository added for disk $($disk.Number) at $folderPath"
    } else {
        Write-Host "No drive letter found for disk $($disk.Number). Skipping..."
    }
}

# Create a flag file to indicate successful initialization
New-Item -Path $FlagFile -ItemType File -Force
Write-Host "Disk initialization complete."
