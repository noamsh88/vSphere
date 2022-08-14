###################################################################################
#Script creating new template from VM
###################################################################################
# $Datastores = 'ST*'  - script will look only datastores names starting with "ST"
# $Hosts = '*lab*'  - script will look only Host names (ESX) with name like *lab*
###################################################################################
$VM = $args[0]
$TemplateName= $args[1]
###################################################################################
$Datastores = 'ST*'
$Hosts = '*lab*'
$CredFilePath = "D:\vCenter\Credentials.xml"
###################################################################################

# Validate if argument entered is not null
if (!$VM -Or !$TemplateName) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "./$scriptName <VM Name> <TemplateName>"
  Write-Host "e.g."
  Write-Host "./$scriptName VM1 VM-TST-TEMPLATE"
  exit 1
}

if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -WebOperationTimeoutSeconds 3600 -Confirm:$false

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials


# Validate if VM name exist on vCenter
$Exists = get-vm -name $VM -ErrorAction SilentlyContinue
If (!$Exists){
   Write-Host "$VM VM Name is NOT exist on $vCenterName vCenter, Please enter valid VM Name"
   exit 1
 }

# Validate if template name is exist
$TemplateExists = Get-Template $TemplateName -ErrorAction SilentlyContinue

# exit 1 if template name exist already on vCenter
if ($TemplateExists) {
   Write-Host "$TemplateExists Template Name is already exist on $vCenterName vCenter, Please enter new Template name to be created"
   exit 1
}

# Get datastore name with most free space
$DataStore = Get-Datastore $Datastores | Sort-Object -Property FreeSpaceMb -Descending | Select -First 1

# Get current available host name(ESX) with most free memory
$HostName = Get-VMHost $Hosts | Sort-Object -Property {$_.MemoryTotalGB - $_.MemoryUsageGB} -Descending:$true | Select-Object -First 1

# Create teamplate from vm
 try{
    Write-Host "Creating $TemplateName Template from $vm VM"
    New-Template -VM $vm -Name "$TemplateName" -Datastore $DataStore -Location $HostName
    }
 catch{
    Write-Host "Error: $($_.Exception.Message)"
    }
