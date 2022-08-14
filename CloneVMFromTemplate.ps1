##########################################################################################
#Script login to vCenter and will create single or multiple VMs per Template Name entered#
##########################################################################################
# $Datastores = 'ST*'  - script will look only datastores names starting with "ST"
# $Hosts = '*lab*'  - script will look only Host names (ESX) with name like *lab*
##########################################################################################
$VMList = $args[0]
$TemplateName = $args[1]
##########################################################################################
$Datastores = 'ST*'
$Hosts = '*lab*'
$CredFilePath = "D:\vCenter\Credentials.xml"
##########################################################################################

# Validate if argument entered is not null
if (!$VMList -Or !$TemplateName) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "./$scriptName <VM Name/List> <Template Name> "
  Write-Host "e.g."
  Write-Host "Single Host:      ./$scriptName VM1 VM-TST-TEMPLATE"
  Write-Host "Multiple Hosts:   ./$scriptName VM1,VM2,VM3 VM-TST-TEMPLATE"
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


# Validate if template name is exist
$TemplateExists = Get-Template $TemplateName

# if template name not found, exit with error
if (!$TemplateExists) {
  Write-Host "Template Name ($TemplateName) Not Found on vCenter $vCenterName , Please enter correct template name, exiting.."
  exit 1
}


foreach($vm in $VMList.split(','))
{
 # Validate if VM name exist on vCenter
 $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
 If ($Exists){
    Write-Host "$vm VM Name is already exist $vCenterName vCenter, Please enter new VM name to be created or remove existing VM and re-run, exiting..."
    exit 1
 }

 # Get datastore name with most free space
 $DataStore = Get-Datastore $Datastores | Sort-Object -Property FreeSpaceMb -Descending | Select -First 1

 # Get current available host name(ESX) with most free memory
 $HostName = Get-VMHost $Hosts | Sort-Object -Property {$_.MemoryTotalGB - $_.MemoryUsageGB} -Descending:$true | Select-Object -First 1

  # Create VM from template
 try{
    Write-Host "New-VM -Name $vm -Datastore $DataStore -Template $TemplateName -ResourcePool $HostName"
    New-VM -Name $vm -Datastore $DataStore -Template $TemplateName -ResourcePool $HostName
    }
 catch{
    Write-Host "Error: $($_.Exception.Message)"
    }

 }
