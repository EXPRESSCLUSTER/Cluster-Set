$clusters = @(
    @(
        @("server1", "192.168.1.1", "29009", "user", "password"),
        @("server2", "192.168.1.2", "29009", "user", "password")
    ),
    @(
        @("server3", "192.168.1.3", "29009", "user", "password"),
        @("server4", "192.168.1.4", "29009", "user", "password")
    )
)

$groups = @("failover", "failover")

$monitors = @("genw", "genw")

$hostname = hostname

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
                    $uri = "http://" + $clusters[$j][$k][1] + ":" + $clusters[$j][$k][2] + "/api/v1/groups/" + $groups[$j]
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
                        $msg = "failover is pending on " + $current + "."
                        clplogcmd -m "$msg" -l ERR
                    }
                    if ($ret.groups.status -eq "Online Failure" -or $ret.groups.status -eq "Offline Failure")
                    {
                        $group = $groups[$j]
                        $current = $ret.groups.current
                        Write-Output "$group is Failure on $current."
                        $msg = "failover is failure on " + $current + "."
                        clplogcmd -m "$msg" -l ERR
                    }

                 }
            }        
        }
     }


$i = 0
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
                		$i=$i+1
            		}
            		else{
            			 Write-Output "Genw not online on $hostname."
                         Write-Output $i  
            		}
           	     }
            }
        }
        }

if ($running -eq 0)
{
if ($i-eq 4)
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
                $i = 0
            	for ($j = 0; $j -lt $clusters.Length; $j++)
            	{
            		if ($j -eq $clusters.Length -or $i -eq 1)
           			{
                	# Start FO
                    break
            		}
            		else
           			{
            			for ($k = 0; $k -lt $clusters[$k].Length; $k++)
            			{
            			Write-Output "Offline other server."
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
                            $i = 1 
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
