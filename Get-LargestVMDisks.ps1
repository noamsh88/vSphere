#######################################################################################################################################
# Script display and export to .csv file the largest disks in VMs of vcenter and their VM details (VM Name , IP and Disk Size in GB)  #
#######################################################################################################################################

# Load VMware Core Module
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Script Configuration
$credFilePath = "D:\vCenter\credentials.xml"
$date = Get-Date -Format "dd_MM_yyyy_HH_mm"

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$credentials = Import-CliXml -Path "$credFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $credentials

# Create an array to store the results
$results = @()

# Get all VMs from vCenter
$vmList = Get-VM

# Iterate through each VM
foreach ($vm in $vmList) {
    # Get VM Name
    $vmName = $vm.Name
    
    # Get VM IP Address
    $vmIP = $vm.Guest.IPAddress

    # Get all hard disks for the VM
    $hardDisks = Get-HardDisk -VM $vm

    # Loop through each hard disk and gather size
    foreach ($disk in $hardDisks) {
        # Create a custom object for each disk
        $results += [PSCustomObject]@{
            VMName = $vmName
            IPAddress = $vmIP
            DiskSizeGB = [math]::Round($disk.CapacityKB / 1MB, 2) # Convert KB to GB
        }
    }
}

# Sort results by DiskSizeGB in descending order
$sortedResults = $results | Sort-Object -Property DiskSizeGB -Descending

# Output the results
$sortedResults | Format-Table -AutoSize

# Export the results to CSV file
$sortedResults | Export-Csv -Path "VM_Disk_Sizes_$date.csv" -NoTypeInformation

