# =Stop Group on Primary Server=
# Last edit: 2022-12-31
# This script should be called when the Group is being moved or is being failed over
# This script removes replication 

# (for debugging) Start-Transcript -Path "debugstoplog.txt" -Append

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

#Stop VM
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

#-------------------------------------------------------------------------
#Check if replication is enabled on replica server and remove if it is
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
#Check if replication is enabled on primary server and remove if it is
$PriInfo = Get-VMReplication -ComputerName $OwnPriSrv
$bRet = $?
if ($PriInfo -eq $null){
    Write-Output "Replication not enabled on $OwnPriSrv. Error value is $bRet"
}
else { 
  #Need to remove VM replication from primary server
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

# (for debugging) Stop-Transcript

exit $Retval