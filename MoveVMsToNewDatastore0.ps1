###############################################################################################
# Script moving single VM or VM List to new given storage name on vsphere using VMware powerCLI
###############################################################################################
$VMList = $args[0]
$NewDatastore = $args[1]
$CredFilePath = "D:\vCenter\Credentials.xml"
#######################################################

# Validate required paramters values are not null
if (!$VMList -Or !$NewDatastore) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <VM Name/List>  <new Datastore name to be moved>"
  Write-Host "e.g."
  Write-Host "Single Host:      .\$scriptName VM1 NEW-STORAGE"
  Write-Host "Multiple Hosts:   .\$scriptName VM1,VM2,VM3 NEW-STORAGE"
  exit 1
}

if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

# Validate if NewDatastore exist on vsphere
# Get the new datastore object
$DatastoreExist = Get-Datastore -Name $NewDatastore
if ( $DatastoreExist -eq $null ){
    Write-Output "Datastore $NewDatastore NOT FOUND at $vCenterName or vsphere user connected doesn't have privileges accessing it, exiting.."
    exit 1
}

# Move all VMs to new storage
foreach($vm in $VMList.split(','))
{
   # Validate if VM exist on vCenter
   $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
   If (! $Exists){
    Write-Host "$vm VM not found at $vCenterName vCenter, exiting.."
    exit 1
    }

    # Move the virtual machine to the new datastore
    Move-VM -VM $vm -Datastore $NewDatastore -Confirm:$false

}
