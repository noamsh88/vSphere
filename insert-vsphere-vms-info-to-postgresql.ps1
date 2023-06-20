<#
### Script actions:
1. Get VMs prefix
2. Gather VMs info from vSphere
3. Prepare INSERT statments for PG DB table (vsphere_vmlist) and append it to temp sql file
4. Connect and execute new sql file created with all VMs info insert statments using psql PG client tool

### Pre-requisites
1. psql.exe PG DB client installed
2. Install-Module PostgreSQLCmdlets
3. create vsphere_vmlist table on target PG DB
e.g.
DROP TABLE vsphere_vmlist;

CREATE TABLE vsphere_vmlist(
  vm_name            varchar(20),
  vm_ip              varchar(20),
  vm_memory_gb       INT,
  vm_cpu             INT,
  vm_state           varchar(20),
  vm_host            varchar(20),
  when_inserted      varchar(20)
)
;
#>
$vm_prefix = $args[0]

# Script Configurations
$CredFilePath = "D:\vCenter\Credentials.xml"
$date = Get-Date -Format "yyyy-MM-dd"
$pg_db_name = ""
$pg_db_user = ""
$pg_db_pass = ""
$pg_db_host = ""
$port = 5432
$insert_vm_info_sqlfile = "./insert_vsphere_vmlist_$vm_prefix_$date.sql"

# Validation - all required variables values are set
if (!$vm_prefix) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:" -BackgroundColor DarkRed
  Write-Host "pwsh $scriptName <VMs Prefix> " -BackgroundColor DarkRed
  exit 1
}

# Validation - PG DB Credentials variables values are set
if (!$pg_db_name -or !$pg_db_user -or !$pg_db_pass -or !$pg_db_host -or !$port) {
  Write-Host "NOT ALL PG DB Credentials variables values are set, please make sure to set them, exiting.." -BackgroundColor DarkRed
  Write-Host "PG DB Credentials variables names are: pg_db_name,pg_db_user,pg_db_pass,pg_db_host and port" -BackgroundColor DarkRed
  exit 1
}

# Load VMware Core Module
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core))
{
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware.VimAutomation.Core -ErrorAction Stop
}

# Create Connection to vSphere
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials

# Get VM List Names realted to vm_prefix input value
$VMList = (Get-VM -Name "*$vm_prefix*" -ErrorAction SilentlyContinue  | Select-Object -ExpandProperty Name | Sort) | Get-Unique

# Validate VMList not null
if (!$VMList) {
  Write-Host "Not Found VMs with similar name to: $vm_prefix , please enter VMs name with diffrent prefix and retry, exiting.." -BackgroundColor DarkRed
  exit 1
}

$VMList

Write-Host "Preparing sql file for inserting vSphere VMs Info related to $vm_prefix into PG DB (DB User: $pg_db_user , DB Name: $pg_db_name , PG DH Host: $pg_db_host)" -BackgroundColor DarkCyan

# Remove temp sql file if exist
Remove-Item $insert_vm_info_sqlfile -ErrorAction SilentlyContinue

# Add PG Delete statment related vm prefix to avoid duplicates in vsphere_vmlist table
"DELETE FROM vsphere_vmlist WHERE vm_name LIKE '%$vm_prefix%' ;" | Add-Content -Path $insert_vm_info_sqlfile


# Get VMs info and append it as INSERT statement to temp sql file to be executed
foreach($vm_name in $VMList)
{
   # Get VM IP Address
   $vm_ip= (Get-VM $vm_name | select-object -first 1 | Select @{N="IP Address";E={@($_.guest.IPAddress[0])}} | ft -hide | Out-String).Trim()

   # Get VM Host
   $vm_host = (Get-VM $vm_name | Get-VMHost).Name | select-object -first 1

   # Get VM Memory in GB
   $vm_memory_gb = (Get-VM $vm_name | select-object -first 1 | Select-Object MemoryGB | ft -hide | Out-String).Trim()

   # Get VM CPU
   $vm_cpu = (Get-VM $vm_name | select-object -first 1 | Select-Object NumCpu | ft -hide | Out-String).Trim()

   # Get VM State (Powered ON/OFF)
   $vm_state = (Get-VM $vm_name | select-object -first 1 | Select-Object PowerState | ft -hide | Out-String).Trim()

   # Prepare PG Insert statment and append it to temp sql file
   "INSERT INTO vsphere_vmlist (vm_name,vm_ip,vm_memory_gb,vm_cpu,vm_state,vm_host,when_inserted) VALUES ('$vm_name','$vm_ip',$vm_memory_gb,$vm_cpu,'$vm_state','$vm_host','$date');" | Add-Content -Path $insert_vm_info_sqlfile

}


# Set PGPASSWORD variable for shell auto PG login
$Env:PGPASSWORD=$pg_db_pass

# Connect to DB and execute the sqlfile created from VMs info using psql client PG DB tool
Write-Host "psql.exe -d $pg_db_name -U $pg_db_user -h $pg_db_host -p $port -f $insert_vm_info_sqlfile -v ON_ERROR_STOP=1 --echo-all -q"
psql.exe -d $pg_db_name -U $pg_db_user -h $pg_db_host -p $port -f "$insert_vm_info_sqlfile" -v ON_ERROR_STOP=1 --echo-all -q
