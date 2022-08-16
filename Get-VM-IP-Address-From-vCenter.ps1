#####################################################################
#Script is getting VM name and returning its IP address from vCenter#
#####################################################################
$VM_Name = $args[0]

#Validate if argument entered is not null
if (!$VM_Name) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "./$scriptName <VM Name>"
  Write-Host "e.g."
  Write-Host "./$scriptName VM1"
  exit 1
}

# Load VMware Core Module
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

# Validate if VM Name exist on vCenter
$Exists = Get-VM -name $VM_Name -ErrorAction SilentlyContinue
If (! $Exists){
    Write-Host "$VM_Name VM NOT FOUND at $vCenterName vCenter, exiting.."
    exit 1
}

# Get NN1 VM Name IP Address
$VM_IP= Get-VM $VM_Name | Select @{N="IP Address";E={@($_.guest.IPAddress[0])}} | ft -hide | Out-String
$VM_IP = $VM_IP.Trim()

Write-Host "$VM_Name IP address is :  $VM_IP"

# Write output variable for next tasks to get VM_IP variable value
Write-Host "##vso[task.setvariable variable=VM_IP;]$VM_IP"
