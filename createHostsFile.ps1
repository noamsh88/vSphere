###############################################################################################
# Script creates hosts file (IP address and VM Name) from vsphere per $vmPrefix value.        #
# if $vmPrefix is null, then it will create hosts file for all VMs on vsphere that powered on #
###############################################################################################
$vmPrefix = $args[0]
$CredFilePath = "D:\vCenter\Credentials.xml"

# Import VMware modules
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

# create hosts file (IP address and VM Name) from vsphere per $vmPrefix value
Get-VM | Where-Object { $_.Name -like "*$vmPrefix*" -and $_.PowerState -like 'PoweredOn' }  | Select @{N="IP Address";E={@($_.guest.IPAddress[0])}},Name | ft -hide | Out-String | Out-File -FilePath ./hosts



