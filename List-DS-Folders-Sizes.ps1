# Script uses VMware PowerCLI to list all datastore folders and their sizes in descending order

# Connect to vCenter server
Connect-VIServer -Server vcenter.example.com

# Get all datastore folders
$datastoreFolders = Get-Folder -Type Datastore

# Initialize an empty array to store the folder sizes
$folderSizes = @()

# Loop through each datastore folder and get its size
foreach ($folder in $datastoreFolders) {
    $folderSize = (Get-Datastore -Location $folder | Measure-Object -Property CapacityGB -Sum).Sum
    $folderSizes += [pscustomobject]@{
        Name = $folder.Name
        Size = $folderSize
    }
}

# Sort the array by size in descending order
$folderSizes = $folderSizes | Sort-Object -Property Size -Descending

# Output the datastore folder name and size
foreach ($folder in $folderSizes) {
    Write-Host "Name: $($folder.Name)  Size: $($folder.Size) GB"
}