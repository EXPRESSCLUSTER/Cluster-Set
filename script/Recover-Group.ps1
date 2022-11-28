#cluster infomation
#Set the following parameters

$clusters = @(
    @(
        @("ws2019-101", "192.168.1.1", "29009", "Administrator", "password"),
        @("ws2019-102", "192.168.1.2", "29009", "Administrator", "password")
    ),
    @(
        @("ws2019-103", "192.168.1.3", "29009", "Administrator", "password"),
        @("ws2019-104", "192.168.1.4", "29009", "Administrator", "password")
    )
)

$groups = @("failover", "failover")

$monitors = @("genw", "genw")

$hostname = hostname

$sleep_time = 15

$genw_offline_counts = 0

$failover_start = 0

# Find my server in the clusters matrix.
$clusterid = -1
Write-Debug $clusters.Length
for ($i = 0; $i -lt $clusters.Length; $i++)
{
    Write-Debug $clusters[$i].Length
    for ($j = 0; $j -lt $clusters[$i].Length; $j++)
    {
        Write-Debug $clusters[$i][$j][0]
        if ($clusters[$i][$j][0] -eq $hostname)
        {
            $clusterid = $i
            $serverid = $j
            Write-Output "$hostname is in cluster ID: $clusterid."
            Write-Output "$hostname is server ID: $serverid."
            break;
        }
    }
    if ($clusterid -ne -1)
    {
        break;
    }
}

Write-Debug $clusterid
if ($clusterid -eq -1)
{
    Write-Output "Cannot find $hostname in the cluster matrix."
    clplogcmd -m "Cannot find $hostname in the cluster matrix." -l WAR
    exit 1
}

# Check the group status and recover it.
Write-Debug $groups.Length
for ($i = 0; $i -lt $groups.Length; $i++)
{
    Write-Output $groups[$i]

    $running = 0

    $user = $clusters[$clusterid][$serverid][3]
    $pass = $clusters[$clusterid][$serverid][4]
    $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $groups[$i]
    Write-Output $user
    Write-Debug $pass
    $userpass = ${user} + ":" + "${pass}"
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
    $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
    Write-Output $uri
    Write-Output $ret
    Write-Output $ret.groups.status
    if ($ret.groups.status -eq "Online")
    {
        $group = $groups[$i]
        $current = $ret.groups.current
        Write-Output "$group is running on $current."
        $running = 1
        break;
    }

    if ($ret.groups.status -eq "Online Pending" -or $ret.groups.status -eq "Offline Pending")
    {
        $group = $groups[$i]
        $current = $ret.groups.current
        Write-Output "$group is Pending on $current."
        $msg = "$group is pending on " + $current + "."
        clplogcmd -m "$msg" -l ERR
    }

    if ($ret.groups.status -eq "Online Failure" -or $ret.groups.status -eq "Offline Failure")
    {
        $group = $groups[$i]
        $current = $ret.groups.current
        Write-Output "$group is Failure on $current."
        $msg = "$group is failure on " + $current + "."
        clplogcmd -m "$msg" -l ERR
    }
    if ($ret.groups.status -eq "Offline")
    {
        Write-Output "$group is Offline on $current."
        $running = 0
        $msg = "$group is offline on " + $current + "."
        clplogcmd -m "$msg" -l ERR
    }

 # Get the group status from API server on the other clusters.
    if ($running -eq 0)
    {
    for ($j = 0; $j -lt $clusters.Length; $j++)
    {
        if ($j -eq $clusterid)
        {
                # Do nothing
        }
        else
        {
        for ($k = 0; $k -lt $clusters[$k].Length; $k++)
        {
            Write-Output $clusters[$j][$k][0]
            $user = $clusters[$j][$k][3]
            $pass = $clusters[$j][$k][4]
            $uri = "http://" + $clusters[$j][$k][1] + ":" + $clusters[$j][$k][2] + "/api/v1/groups/" + $groups[$k]
            Write-Output $user
            Write-Debug $pass
            Write-Output $uri
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
            $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
            Write-Output $ret
            Write-Output $ret.groups.status
            if ($ret.groups.status -eq "Online")
            {
                $group = $groups[$j]
                $current = $ret.groups.current
                Write-Output "$group is running on $current."
                $running = 1
                break;
            }
            if ($ret.groups.status -eq "Online Pending" -or $ret.groups.status -eq "Offline Pending")
            {
                 $group = $groups[$j]
                 $current = $ret.groups.current
                 Write-Output "$group is Pending on $current."
                 $msg = "$group is pending on " + $current + "."
                 clplogcmd -m "$msg" -l WAR
             }
            if ($ret.groups.status -eq "Online Failure" -or $ret.groups.status -eq "Offline Failure")
            {
                  $group = $groups[$j]
                  $current = $ret.groups.current
                  Write-Output "$group is Failure on $current."
                  $msg = "$groups is failure on " + $current + "."
                  clplogcmd -m "$msg" -l WAR
             }
          }
          }        
    }
    }
}

# Get the genw status on all server
if ($running -eq 0)
{
    for ($j = 0; $j -lt $clusters.Length; $j++)
        {
            $server_sum = $server_sum + $clusters[$j].Length
            for ($k = 0; $k -lt $clusters[$j].Length; $k++)
            {
            Write-Output $clusters[$j][$k][0]
            $user = $clusters[$j][$k][3]
            $pass = $clusters[$j][$k][4]
            $genw = $monitors[$j]
            $uri = "http://" + $clusters[$j][$k][1] + ":" + $clusters[$j][$k][2]+ "/api/v1/monitors/" + $genw
            Write-Output $user
            Write-Debug $pass
            Write-Output $uri
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
            $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
            Write-Output $ret
            Write-Output $ret.result.status
            $hostname = $clusters[$j][$k][0]
            if ($ret.result.status -eq "Normal" )
            {
               	$genw_offline_counts=$genw_offline_counts+1
            }
            else
            {
            	 $monitor = $monitors[$j]
            	 Write-Output "$monitor is not online on $hostname."
                 Write-Debug $genw_offline_counts
            }
            }
         }
}

       
# Recover the group
if ($running -eq 0)
{
if ($genw_offline_counts-eq $server_sum)
{
    Write-Output "All server genw is Normal."
    $user = $clusters[0][0][3]
    $pass = $clusters[0][0][4]
    $hostname = $clusters[0][0][0]
    $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $groups[$j] + "/start"
    $body = [System.Text.Encoding]::UTF8.GetBytes("{ `"target`" : `"$hostname`" }")
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
    $ret = Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri -Body $body
    break
}
else
{
    for ($j = 0; $j -lt $clusters.Length; $j++)
    {
        if ($j -eq $clusters.Length -or $failover_start -eq 1)
        {
        # Start FO
        break
        }
    else
    {
    for ($k = 0; $k -lt $clusters[$j].Length; $k++)
    {
        Write-Output $clusters[$j][$k][0]
        $user = $clusters[$j][$k][3]
        $pass = $clusters[$j][$k][4]
        $uri = "http://" + $clusters[$j][$k][1] + ":" + $clusters[$j][$k][2]+ "/api/v1/groups/" + $groups[$j] + "/start"
        $hostname = $clusters[$j][$k][0]
        Write-Output $uri 
        Write-Output $hostname
        $body = [System.Text.Encoding]::UTF8.GetBytes("{ `"target`" : `"$hostname`" }")
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
        $ret = Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri -Body $body
        Write-Output $ret.result.code
        Start-Sleep 15
        $uri = "http://" + $clusters[$j][$k][1]+ ":" + $clusters[$j][$k][2] + "/api/v1/groups/" + $groups[$i]
        $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
        Write-Output $ret.groups.status
        if ($ret.groups.status -eq "Online")
        {
            Write-Output "FO group can start on $hostname"
            $failover_start = 1 
            break
        }
        else
        {
            Write-Output "FO group can not start on $hostname"
        }
        }
     }
     }
     }
}
