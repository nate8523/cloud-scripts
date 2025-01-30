# Get all uninitialized (RAW) disks excluding the OS disk
$DataDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" }

# Define available drive letters (E to Z)
$DriveLetters = [char[]](69..90) # ASCII values for 'E' to 'Z'
$Index = 0

if ($DataDisks) {
    foreach ($Disk in $DataDisks) {
        # Initialize the disk
        Initialize-Disk -Number $Disk.Number -PartitionStyle GPT -Confirm:$false

        # Create a partition
        $Partition = New-Partition -DiskNumber $Disk.Number -UseMaximumSize

        # Assign a drive letter dynamically
        $DriveLetter = $DriveLetters[$Index]
        if ($DriveLetter) {
            $DriveLetterStr = "$DriveLetter" + ":"
            Set-Partition -PartitionNumber $Partition.PartitionNumber -DiskNumber $Disk.Number -NewDriveLetter $DriveLetter

            # Format the partition as NTFS
            Format-Volume -DriveLetter $DriveLetter -FileSystem NTFS -NewFileSystemLabel "VeeamBackup_$DriveLetter" -Confirm:$false

            Write-Host "Disk $($Disk.Number) initialized and mounted as $DriveLetterStr"
        } else {
            Write-Host "No available drive letters left!"
        }

        $Index++
    }
} else {
    Write-Host "No uninitialized disks found."
}
