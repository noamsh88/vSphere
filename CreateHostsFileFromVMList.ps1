###########################################################################################################
#Script is getting VM List , getting IP for each VM from vCenter and Creating hosts files per according it#
###########################################################################################################
$VMList = $args[0]
$OptHostFile = "$(pwd)/hosts"
$CredFilePath = "D:\vCenter\Credentials.xml"
###########################################################################################################

# Validate if argument entered is not null
if (!$VMList) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "./$scriptName <VM1,VM2,...S>"
  Write-Host "e.g."
  Write-Host "./$scriptName VM1,VM2,VM3"
  exit 1
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials


foreach($VM_Name in $VMList.split(','))
{
   # Validate if VM exist on vCenter
   $Exists = Get-VM -name $VM_Name -ErrorAction SilentlyContinue
   If (! $Exists){
    Write-Host "$VM_Name VM NOT FOUND at $vCenterName vCenter, exiting.."
    exit 1
    }

   # Get VM IP Address
   $VM_IP= Get-VM $VM_Name | Select @{N="IP Address";E={@($_.guest.IPAddress[0])}} | ft -hide | Out-String

   "$VM_IP $VM_Name" | Out-File -FilePath $OptHostFile -Append

}
