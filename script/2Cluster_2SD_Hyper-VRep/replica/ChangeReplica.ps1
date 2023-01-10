# Last edit: 2022-12-31
# The Replica server has changed and replication needs to be updated
# This script makes that change

#  (For debugging) Start-Transcript -Path "debuglog.txt" -Append

#Assign variables
#Change user name and password below!!!
$user = "Administrator"
$pwd = ""
$pass = ConvertTo-SecureString $pwd -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pass)
$OppClusterInfo = curl.exe -s $env:RestURI -u Administrator:Solutions! | ConvertFrom-Json
$OppPriSrv = $OppClusterInfo.groups.current
$OwnRepSrv = $env:COMPUTERNAME
$RetVal = 0

#Get replication info on active server in opposite cluster
#$RepInfo = Get-VMReplication -Name $env:VM -ComputerName $OppPriSrv
$RepInfo = Invoke-Command -ComputerName $OppPriSrv -Credential $cred -ScriptBlock {param($par1,$par2) Get-VMReplication -Name $par1 -ComputerName $par2} -ArgumentList $env:VM, $OppPriSrv
Write-Output "$($RepInfo.Mode)"
If ($RepInfo.Mode -eq "Primary") {
  Write-Output "$OppPriSrv is the Primary server for replication"
} elseif ($RepInfo.Mode -eq "Replica") {
  Write-Output "$OppPriSrv is the Replica server for replication"
} else {
  Write-Output "Error getting the current server's mode"
}

$PriSrv = $RepInfo.PrimaryServer
$RepSrv = $RepInfo.ReplicaServer
Write-Output "Virtual Machine is: $env:VM"
Write-Output "Primary server from GetVMReplication is:  $PriSrv"
Write-Output "Primary server from curl command is: $OppPriSrv"
Write-Output "Replica server from GetVMReplication is: $RepSrv"
Write-Output "Replica server from environment variable is: $OwnRepSrv"
Write-Output "Replication state is: $($RepInfo.State)"

#Check to see if move group or failover occurred?

# Get primary server and replica server. If Get-VMReplication primary and replica servers haven't changed, do nothing
#Check to see if script needs to run or not
if (($PriSrv.Split('.')[0] -eq $OppPriSrv.Split('.')[0]) -and `
    ($RepSrv.Split('.')[0] -eq $OwnRepSrv.Split('.')[0]) -and `
    ($RepInfo.State -eq 'Replicating')) {
    Write-Output "Replication is functioning normally. Exiting script."
# (For debugging) Stop-Transcript #remove this line if not debugging!
    exit 0
}

#Can remove this section
#If replication is removed, cannot get primary server name
If ($RepSrv -eq $null) {
  $RepSrv = $env:COMPUTERNAME
  Write-Output "Replication may have been removed, so setting local Replica server to: $RepSrv"
}

#Check primary server to see if replication is enabled
#Get-VMReplication $env:VM -ComputerName $OppPriSrv
$RepInfo = Invoke-Command -ComputerName $OppPriSrv -Credential $cred -ScriptBlock {param($par1,$par2) Get-VMReplication -Name $par1 -ComputerName $par2} -ArgumentList $env:VM, $OppPriSrv
$bRet = $?
if ($bRet -eq $True){ #Remove replication on primary server
  Write-Output "Removing VM Replication from primary server $OppPriSrv"  
  #Remove replication on Primary server
  #Remove-VMReplication -ComputerName $OppPriSrv -VMName $env:VM
  Invoke-Command -ComputerName $OppPriSrv -Credential $cred -ScriptBlock {param($par1,$par2) Remove-VMReplication -VMName $par1 -ComputerName $par2} -ArgumentList $env:VM, $OppPriSrv
  $bRet = $?
  if ($bRet -eq $True){
    Write-Output "Successfully removed VM Replication from $OppPriSrv"
  }
  else {
    Write-Output "Failed to remove VM Replication from $OppPriSrv"
    $RetVal += 1
    #Write-Output $Error[0]
#    exit 1
  }
}

#Check replica server to see if replication is enabled
$RepInfo = Get-VMReplication -ComputerName $OwnRepSrv
$bRet = $?
if ($bRet -eq $True){ #Remove replication on replica server if enabled
  Write-Output "Removing VM Replication from replica server $OwnRepSrv"  
  #Remove replication on Replica server
  Remove-VMReplication -ComputerName $OwnRepSrv -VMName $env:VM
  $bRet = $?
  if ($bRet -eq $True){
    Write-Output "Successfully removed VM Replication from $OwnRepSrv"
  }
  else {
    Write-Output "Failed to remove VM Replication from $OwnRepSrv"
    $RetVal += 2
    #Write-Output $Error[0]
#    exit 1
  }
}

#Check if VM is already registered in Hyper-V manager on Replica Server
$VMInfo = Get-VM -ComputerName $OwnRepSrv -Name $env:VM
$bRet = $?
if ($bRet -eq $False){ #Import the VM into Hyper-V Manager on Replica Server
  Import-VM -ComputerName $OwnRepSrv -Path $env:VMPath\$env:vmcxid -Confirm:$False
  $bRet = $?
  if ($bRet -eq $True){
    Write-Output "Successfully imported $env:VM into Hyper-V Manager on $OwnRepSrv"
  }
  else{
    Write-Output "Failed to import $env:VM into Hyper-V Manager on $OwnRepSrv"
    #Write-Output $Error[0]
    exit 1
  }
}
else {
  Write-Output "VM $env:VM already exists in Hyper-V Manager"
}

#Set Replica server VM copy as replica
Enable-VMReplication $env:VM -AsReplica -Computername $OwnRepSrv
$bRet = $?
if ($bRet -eq $True){
  Write-Output "Successfully set replica server VM copy as replica"
}
else {
    Write-Output "Failed to set replica server VM copy as replica"
    #Write-Output $Error[0]
    $RetVal += 4
#    exit 1
}

#Enable replication from Primary server to Replica server
#Enable-VMReplication $env:VM -ReplicaServerName $OwnRepSrv -ReplicaServerPort 80 -AuthenticationType Kerberos -Computername $OppPriSrv
Invoke-Command -ComputerName $OppPriSrv -Credential $cred -ScriptBlock {param($par1,$par2,$par3,$par4,$par5) Enable-VMReplication -VMName $par1 -ComputerName $par2 -ReplicaServerName $par3 -ReplicaServerPort $par4 -AuthenticationType $par5} -ArgumentList $env:VM, $OppPriSrv, $OwnRepSrv, 80, Kerberos
$bRet = $?
if ($bRet -eq $True){
  Write-Output "Successfully enabled replication from $OppPriSrv to replica server $OwnRepSrv"
}
else {
  Write-Output "Failed to enable replication from $OppPriSrv to replica server $OwnRepSrv"
  $RetVal += 8
  #Write-Output $Error[0]
#  exit 1
}

#Check to make sure Get-VMReplication State is 'ReadyForInitialReplication' and Health is 'Warning'?
Write-Output "VM $env:VM state is $($(Get-VMReplication).State)"
#Start VM replication from Primary server to Replica server

#Start-VMinitialReplication $env:VM -ComputerName $OppPriSrv
Invoke-Command -ComputerName $OppPriSrv -Credential $cred -ScriptBlock {param($par1,$par2) Start-VMinitialReplication -VMName $par1 -ComputerName $par2} -ArgumentList $env:VM, $OppPriSrv
$bRet = $?
if ($bRet -eq $True){
  Write-Output "Successfully started replication of $env:VM"
}
else {
  Write-Output "Failed to start replication of $env:VM"
  $RetVal += 16
  #Write-Output $Error[0]
#  exit 1
}

#Check Get-VMReplication to see if State is 'Replicating' and ReplicaServer = $OwnRepSrv?
$RepInfo = Get-VMReplication -Name $env:VM
Write-Output "VM $env:VM state is $($RepInfo.State) and Health is $($RepInfo.Health)"
Write-Output "$($RepInfo.ReplicaServer) is now set as the new Replica Server"
Write-Output "Return value is: $RetVal"

# (For debugging) Stop-Transcript

exit $Retval