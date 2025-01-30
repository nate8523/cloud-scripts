# Define the flag file to prevent duplicate execution
$FlagFile = "C:\AzureData\disk_initialized.flag"

if (Test-Path $FlagFile) {
    Write-Host "Disk initialization already completed. Exiting..."
    exit 0
}

# Initialize all uninitialized (RAW) disks
Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' } | Initialize-Disk -PartitionStyle GPT

# Get all disks that are online but do not have a drive letter
$onlineDisksWithoutDriveLetter = Get-Disk | Where-Object { $_.PartitionStyle -eq 'GPT' -and $_.IsOffline -eq $false -and !$_.DriveLetter }

# Function to get the first available drive letter (starting from F)
function Get-FirstUnusedDriveLetter {
    $usedLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $allLetters = 'F'..'Z'
    return $allLetters | Where-Object { $_ -notin $usedLetters } | Select-Object -First 1
}

# Assign drive letters and format disks using ReFS for Veeam
foreach ($disk in $onlineDisksWithoutDriveLetter) {
    $driveLetter = Get-FirstUnusedDriveLetter
    if (-not $driveLetter) {
        Write-Host "No available drive letters for disk $($disk.Number). Skipping..."
        continue
    }
    $partition = $disk | New-Partition -AssignDriveLetter -UseMaximumSize
    $partition | Format-Volume -FileSystem ReFS -AllocationUnitSize 64KB -Confirm:$false
    Write-Host "Disk $($disk.Number) formatted as ReFS and assigned drive letter: $driveLetter"
}

# Import Veeam Backup PowerShell module
Import-Module Veeam.Backup.PowerShell

# Connect to the Veeam backup server
$hostname = [Net.Dns]::GetHostName()
$Server = Get-VBRServer -Name $hostname

# Add each formatted disk as a Veeam backup repository
$initializedDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'GPT' -and $_.IsOffline -eq $false }
foreach ($disk in $initializedDisks) {
    $driveLetter = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    if ($driveLetter) {
        $folderPath = $driveLetter + ":\"
        Add-VBRBackupRepository -Name "Local Backups $folderPath" -Server $Server -Folder $folderPath -Type WinLocal
        Write-Host "Veeam repository added for disk $($disk.Number) at $folderPath"
    } else {
        Write-Host "No drive letter found for disk $($disk.Number). Skipping..."
    }
}

# Create a flag file to indicate successful initialization
New-Item -Path $FlagFile -ItemType File -Force
Write-Host "Disk initialization complete."
