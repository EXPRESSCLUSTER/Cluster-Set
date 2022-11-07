# clusters
# - Add cluster servers.
# - The following sample has 2 clusters.
# - If you want to add one more cluster that has server5 and
#   server6, write as below.

$server1 = @("ws2019-232", "192.168.1.1", "29009", "Administrator", "password")
$server2 = @("ws2019-233", "192.168.1.2", "29009", "Administrator", "password")
$server3 = @("ws2019-234", "192.168.1.3", "29009", "Administrator", "password")
$server4 = @("ws2019-235", "192.168.1.4", "29009", "Administrator", "password")
$cluster1 = @($server1, $server2)
$cluster2 = @($server3, $server4)

$clusters = @($cluster1, $cluster2)

$groups = @("failover", "failover")

$hostname = hostname

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
    Write-Output "Cannot find the server in the cluster matrix."
    clplogcmd -m "Cannot find the server in the cluster matrix." -l ERR
    exit 1
}


Write-Debug $groups.Length
for ($i = 0; $i -lt $groups.Length; $i++)
{
    Write-Debug $groups[$i]

    $running = 0

    $user = $clusters[$clusterid][$serverid][3]
    $pass = $clusters[$clusterid][$serverid][4]
    $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $groups[$i]
    Write-Output $user
    Write-Debug $pass
    Write-Output $uri
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
    }

    if ($ret.groups.status -eq "Online Pending" -or $ret.groups.status -eq "Offline Pending")
    {
        $group = $groups[$i]
        $current = $ret.groups.current
        Write-Output "$group is Pending on $current."
        $msg = "failover is pending on " + $current + "."
        clplogcmd -m "$msg" -l ERR
    }

    if ($ret.groups.status -eq "Online Failure" -or $ret.groups.status -eq "Offline Failure")
    {
        $group = $groups[$i]
        $current = $ret.groups.current
        Write-Output "$group is Failure on $current."
        $msg = "failover is failure on " + $current + "."
        clplogcmd -m "$msg" -l ERR
    }
    if ($ret.groups.status -eq "Offline")
    {
        Write-Output "$group is Offline on $current."
        $running = 0
        $msg = "failover is offline on " + $current + "."
        clplogcmd -m "$msg" -l ERR
    }
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
                    $uri = "http://" + $clusters[$j][$k][1] + ":" + $clusters[$j][$k][2] + "/api/v1/groups/" + $groups[$i]
                    Write-Output $user
                    Write-Debug $pass
                    Write-Output $uri
                    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
                    $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
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
                        $msg = "failover is pending on " + $current + "."
                        clplogcmd -m "$msg" -l ERR
                    }
                    if ($ret.groups.status -eq "Online Failure" -or $ret.groups.status -eq "Offline Failure")
                    {
                        $group = $groups[$i]
                        $current = $ret.groups.current
                        Write-Output "$group is Failure on $current."
                        $msg = "failover is failure on " + $current + "."
                        clplogcmd -m "$msg" -l ERR
                    }

                 }
            }        
        }
     }

# Recover the group
if ($running -eq 0)
        {
            $user = $clusters[$clusterid][$serverid][3]
            $pass = $clusters[$clusterid][$serverid][4]
            $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $groups[$i] + "start"
            $body = [System.Text.Encoding]::UTF8.GetBytes("{ `"target`" : `"$hostname`" }")
            Write-Output $user
            Write-Debug $pass
            Write-Output $uri
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$pass)))
            $ret = Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri -Body $body
            Write-Output $ret
            Write-Output $ret.result.code
             if ($ret.result.code -eq 0)
             {
                 $uri = "http://" + $clusters[$clusterid][$serverid][1] + ":" + $clusters[$clusterid][$serverid][2] + "/api/v1/groups/" + $groups[$i]
                 $ret = Invoke-RestMethod -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Uri $uri
                 Write-Output "$groups[$i] : $ret.groups.status"
             }
             else 
             {
             Write-Output $ret.result.message
             clplogcmd -m "Cannot start Failover." -l ERR
             }
}
