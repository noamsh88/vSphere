###################################################################################################
#Script login to vCenter and will move single or list of VMs to new Host provided(TargetESXiNumber)
#or if TargetESXiNumber not provided, it will look for host with most free memory and move VM to it
###################################################################################################
# $Hosts = '*lab*'  - script will look only Host names (ESX) with name like *lab*
##############################################################################################
$VMList = $args[0]
$TargetESXiNumber = $args[1]
##############################################################################################
$Hosts = '*lab*'
$CredFilePath = "D:\vCenter\Credentials.xml"
##############################################################################################


# Validate if argument entered is not null
if (!$VMList) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "./$scriptName <VM Name/List> <Target ESX Host Number> 15"
  Write-Host "e.g."
  Write-Host "Single Host:      ./$scriptName VM1 15"
  Write-Host "Multiple Hosts:   ./$scriptName VM1,VM2,VM3 15"
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

# Validate if host related to $TargetESXiNumber exist on vCenter
 if ($TargetESXiNumber) {
  $TargetHostName = Get-VMHost "$Hosts*$TargetESXiNumber*" | Select-Object -First 1

  if (!$TargetHostName){
    Write-Host "Target Host Name Not Found, Please make sure TargetESXiNumber argument is for valid/accesible Host Name"
    exit 1
  }
}


foreach($vm in $VMList.split(','))
{
 # Validate if VM name exist on vCenter
 $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
 If (!$Exists){
    Write-Host "$vm VM Name NOT FOUND on $vCenterName vCenter, exiting..."
    exit 1
 }

 # if Target ESX Host Number variable is null, then set target host name with most free memory
 if (!$TargetESXiNumber) {
    Write-Host "Getting current available host name(ESX) with most free memory"
    $TargetHostName = Get-VMHost $Hosts | Sort-Object -Property {$_.MemoryTotalGB - $_.MemoryUsageGB} -Descending:$true | Select-Object -First 1
    }
  else{
    $TargetHostName = Get-VMHost "$Hosts*$TargetESXiNumber*" | Select-Object -First 1
    }

  # Validate if current VM host is equal to target ESXi is same as current host, if yes then no need to move
  $CurrentVMHost = Get-VMHost -VM $vm
  if ($TargetHostName -eq ${CurrentVMHost})
  {
    Write-Warning "$vm VM is already exist on host name with most free memory ($TargetHostName) , no need to move it to new host skipping..."
    Continue
  }

  # Move VM to new TargetHostName with most free memory
 try{
    Write-Host "Move-VM -VM $vm -Destination $TargetHostName"
    Move-VM -VM $vm -Destination $TargetHostName
    }
 catch{
    Write-Host "Error: $($_.Exception.Message)"
    }

 }
