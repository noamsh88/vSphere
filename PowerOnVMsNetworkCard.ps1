#################################################################################################################
#Script login to vCenter and will turn on network card of single or multiple VMs according to argumentet entered#
#################################################################################################################
$VMList = $args[0]
$CredFilePath = "D:\vCenter\Credentials.xml"
#################################################################################################################

# Validate if argument entered is not null
if (!$VMList) {
  $scriptName = $MyInvocation.MyCommand.Name
  Write-Host "Usage:"
  Write-Host "$scriptName <VM Name/List>"
  Write-Host "e.g."
  Write-Host "Single Host:      .\$scriptName VM1"
  Write-Host "Multiple Hosts:   .\$scriptName VM1,VM2,VM3"
  exit 1
}

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Create Connection to vCenter
$vCenterName = '<vCenter URL>'
$Credentials = Import-CliXml -Path "$CredFilePath"
$VC_Connect = Connect-Viserver $vCenterName -Credential $Credentials



Write-Host "Please wait, Checking vm network status..."
Write-Host "VMs list: $VMList"

foreach($vm in $VMList.split(','))
{
   # Validate if VM exist on vCenter
   $Exists = Get-VM -name $vm -ErrorAction SilentlyContinue
   If ($Exists){
    Write-Host "VM: $vm Found at $vCenterName vCenter"
   }
   else {
    Write-Host "$vm VM NOT FOUND at $vCenterName vCenter, exiting.."
    exit 1
    }

    # Check if VM is powered on, if not, VMPoweredOn paramter value will remain null
    $VMPoweredOn = Get-VM -Name $vm | Select PowerState | Select-String 'PoweredOn'

    # if VM is powered off, exit with error
    if (!$VMPoweredOn) {
     Write-Host "$vm VM is Powered OFF, please start it first before turning on its network card, exiting..."
     exit 1
    }

    try
    {
        Write-Host "##[command]Get NetworkStatus for: $vm"
        $vmNetwork = Get-VM $vm | Get-NetworkAdapter
        Write-Host "vmNetwork.ConnectionState.Connected: $($vmNetwork.ConnectionState.Connected)"
        Write-Host "vmNetwork.ConnectionState.StartConnected: $($vmNetwork.ConnectionState.StartConnected)"
        if( $($vmNetwork.ConnectionState.Connected) -like "False" )
        {
            Write-Host "##[command]Setting ConnectionState.Connected to True."
            Get-VM $vm | Get-NetworkAdapter | Set-NetworkAdapter -Connected $true -Confirm:$false
        }
        if( $($vmNetwork.ConnectionState.StartConnected) -eq $false )
        {
            Write-Host "##[command]Setting ConnectionState.StartConnected to True."
            Get-VM $vm | Get-NetworkAdapter | Set-NetworkAdapter -StartConnected $true -Confirm:$false
        }
    }
    catch
    {
        Write-Host "Fail to Connect VM to network - VM: $vm, Error: $($_.Exception.Message)"
        Write-Host "##vso[task.logissue type=warning;]Fail to Connect VM to network - VM: $vm, Error: $($_.Exception.Message)!"
        Write-Host "##vso[task.complete result=SucceededWithIssues;]"
    }
    Write-Host "##[section]Done."
}
