# =Change Primary Server=
# Last edit: 2022-12-31
# The Primary server has changed and VM replication needs to be updated
# This script makes that change

# (For debugging) Start-Transcript -Path "debuglog.txt" -Append

#Assign variables
#Change user name and password below!!!
$user = "Administrator"
$pwd = ""
$pass = ConvertTo-SecureString $pwd -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pass)
$OppClusterInfo = curl.exe -s $env:RestURI -u Administrator:Solutions! | ConvertFrom-Json
$OppRepSrv = $OppClusterInfo.groups.current
$OwnPriSrv = $env:COMPUTERNAME
$PriSrv = ""
$RepSrv = ""
$RetVal = 0

#Get replication info on active server in opposite cluster
#$RepInfo = Get-VMReplication -Name $env:VM -ComputerName $OppRepSrv
$RepInfo = Invoke-Command -ComputerName $OppRepSrv -Credential $cred -ScriptBlock {param($par1,$par2) Get-VMReplication -Name $par1 -ComputerName $par2} -ArgumentList $env:VM, $OppRepSrv
if ($RepInfo -eq $null){
  Write-Output "Replication is not enabled on $OppRepSrv."
} else {
  $PriSrv = $RepInfo.PrimaryServer
  $RepSrv = $RepInfo.ReplicaServer
  Write-Output "$($RepInfo.Mode)"
  If ($RepInfo.Mode -eq "Primary") {
    Write-Output "$OppRepSrv is the Primary server for replication"
  } elseif ($RepInfo.Mode -eq "Replica") {
    Write-Output "$OppRepSrv is the Replica server for replication"
  } else {
    Write-Output "Error getting the current server's mode"
  }
}

Write-Output "Virtual Machine is: $env:VM"
Write-Output "Primary server from GetVMReplication is: $PriSrv"
Write-Output "Primary server from environment variable is: $OwnPriSrv"
Write-Output "Replica server from GetVMReplication is: $RepSrv"
Write-Output "Replica server from curl command is: $OppRepSrv"
Write-Output "Replication state is: $($RepInfo.State)"

#Check to see if move group or failover occurred?

#Get primary server and replica server. If Get-VMReplication primary and replica servers haven't changed, do nothing but start VM
#Check to see if script needs to run or not
if (($PriSrv.Split('.')[0] -eq $OwnPriSrv.Split('.')[0]) -and `
    ($RepSrv.Split('.')[0] -eq $OppRepSrv.Split('.')[0]) -and `
    ($RepInfo.State -eq 'Replicating')) {
    Write-Output "Replication is functioning normally. Exiting script."
# (For debugging) Stop-Transcript #remove this line if not debugging!
    exit 0
}

#Make sure path to VM files is accessible
#Test-Path -Path $env:VMPath
Test-Path -Path $env:vmcx
$bRet = $?
if ($bRet -eq $False) {
  Write-Output "Path to VM configuration file is not accessible"
    Write-Output $Error[0]
} else {
  Write-Output "Path to VM configuration file is accessible"
}

#Make sure VM is not running on new primary server (if failing over)
$vminfo = Get-VM $env:VM
$bRet = $?
if ($bRet -eq $True){ # VM exists in Hyper-V Manager
  if ($vminfo.State -eq "Off"){
      Write-Output "$env:VM is currently off."
  } else {
    Write-Output "Stopping $env:VM"
    Stop-VM $env:VM -Confirm:$False -Force
    $bRet = $?
    if ($bRet -eq $False){  # Failed to stop VM
      Write-Output "Failed to stop $env:VM"
    } else {
      Write-Output "Stopped $env:VM successfully"
    }
  }
}
#Wait until stopped?

#-------------------------------------------------------------------------
#Check if replication is enabled on replica server
if ($RepInfo -eq $null){
    Write-Output "Replication not enabled on $OppRepSrv."
} else { #Need to remove replication from replica server
  Write-Output "Removing VM Replication from $OppRepSrv"
  Invoke-Command -ComputerName $OppRepSrv -Credential $cred -ScriptBlock {param($par1,$par2) Remove-VMReplication -VMName $par1 -ComputerName $par2} -ArgumentList $env:VM, $OppRepSrv
  $bRet = $?
  if ($bRet -eq $True){
    Write-Output "Successfully removed VM Replication from $OppRepSrv"
  }
  else {
    Write-Output "Failed to remove VM Replication from  $OppRepSrv"
    #Write-Output $Error[0]
    $Retval += 1
  }
}
#-------------------------------------------------------------------------

#=========================================================================
#Check if replication is enabled on primary server
$PriInfo = Get-VMReplication -ComputerName $OwnPriSrv
$bRet = $?
if ($PriInfo -eq $null){
    Write-Output "Replication not enabled on $OwnPriSrv. Error value is $bRet"
}
else { 
  #Need to remove VM replication from primary server
    start-sleep 30
    Write-Output "Removing VM Replication from $OwnPriSrv"
    #  Remove-VMReplication -ComputerName $OwnPriSrv -VMName $env:VM
    Remove-VMReplication -VMName $env:VM
    $bRet = $?
    if ($bRet -eq $True){
      Write-Output "Successfully removed VM Replication from $OwnPriSrv"
    }
    else {
      Write-Output "Failed to remove VM Replication from  $OwnPriSrv"
      #Write-Output $Error[0]
      $Retval += 2
    }
}
#=========================================================================

#Check if VM is already registered in Hyper-V manager on Primary Server
if ($vminfo -eq $null){ #Import the VM into Hyper-V Manager on Replica Server
  Import-VM -ComputerName $OwnPriSrv -Path $env:VMPath\$env:vmcxid -Confirm:$False
  $bRet = $?
  if ($bRet -eq $True){
    Write-Output "Successfully imported $env:VM into Hyper-V Manager on $OwnPriSrv"
  }
  else{
    Write-Output "Failed to import $env:VM into Hyper-V Manager on $OwnPriSrv"
    #Write-Output $Error[0]
    exit 1
  }
}
else {
  Write-Output "VM $env:VM already exists in Hyper-V Manager"
}

#Enable replica server VM files as replica source
Invoke-Command -ComputerName $OppRepSrv -Credential $cred -ScriptBlock {param($par1,$par2) Enable-VMReplication -VMName $par1 -ComputerName $par2 -AsReplica} -ArgumentList $env:VM, $OppRepSrv
$bRet = $?
if ($bRet -eq $True){
  Write-Output "Successfully set replica server VM copy as replica"
}
else {
  Write-Output "Failed to set replica server VM copy as replica"
  #Write-Output $Error[0]
  $Retval += 4
  #exit 1
}

#Enable replication from new Primary server to Replica server
Enable-VMReplication -Computername $OwnPriSrv -VMName $env:VM -ReplicaServerName $OppRepSrv -ReplicaServerPort 80 -AuthenticationType Kerberos
$bRet = $?
if ($bRet -eq $True){
  Write-Output "Successfully enabled replication from $OwnPriSrv to replica server $OppRepSrv"
}
else {
    Write-Output "Failed to enable replication from $OwnPriSrv to replica server $OppRepSrv"
    #Write-Output $Error[0]
    $Retval += 8
#   exit 1
}

#Check to make sure Get-VMReplication State is 'ReadyForInitialReplication' and Health is 'Warning'? on replication server
$oppvmrep = Invoke-Command -ComputerName $OppRepSrv -Credential $cred -ScriptBlock {param($par1,$par2) Get-VMReplication -VMName $par1 -ComputerName $par2} -ArgumentList $env:VM, $OppRepSrv
Write-Output "Opposite VM $env:VM state is $($oppvmrep.State)"

#Start VM replication from new Primary server to Replica server
Start-VMinitialReplication $env:VM
$bRet = $?
if ($bRet -eq $True){
  Write-Output "Successfully started replication of $env:VM"
}
else {
  Write-Output "Failed to start replication of $env:VM"
  #Write-Output $Error[0]
  $Retval += 16
# exit 1
}

#Check Get-VMReplication to see if State is 'Replicating' and ReplicaServer = $OppRepSrv?
Write-Output "VM $env:VM state is $($(Get-VMReplication).State)"
Write-Output "$($(Get-VMReplication).PrimaryServer) is now set as the new Primary Server"

#Check replication state before starting VM
$repstate = $($(Get-VMReplication).State)
Write-Output "VM Replication state is: $repstate"
$vminfo = Get-VM $env:VM
Write-Output "VM Status is: $($vminfo.Status)"
Write-Output "VM State is: $($vminfo.State)"

#Wait for VM to be in startable state
while ((Get-VM $env:VM).status -eq 'Creating checkpoint') { start-sleep -s 5 }

#Start the VM
Start-VM $env:VM
$bRet = $?
if ($bRet -eq $True){
  Write-Output "Started VM $env:VM successfully"
}
else {
  Write-Output "Failed to start VM $env:VM"
}

$repstate = $($(Get-VMReplication).State)
Write-Output "Replication state after attempting to start VM is: $repstate"

Write-Output "Script return value is: $Retval"

# (For debugging) Stop-Transcript

exit $Retval