# ECX 2 cluster two shared disks with Hyper-V Replication
This document gives more details about this particular solution.
![overview](../images/ECX2Clu2SDHVR.png)
## Script Details
- Variables need to be set in **SetEnvironment.bat** in order for the scripts to function properly.
- **Start.bat** determines if any action needs to be taken. A PowerShell script is called, and if replication is determined to be progressing normally, no action is taken. If a ‘move group’ or failover just occurred, replication is changed to occur between the active servers on each cluster and the following actions are taken by calling *ChangePrimary.ps1* or *ChangeReplica.ps1*:
  -	Determine which cluster has the Hyper-V Primary server role and Replica server role.
  -	Remove replication from the Primary and Replica servers if still enabled.
  -	Register the VM in Hyper-V Manager if it has not been done on the server the script is run from.
  -	Enable the VM files on the Hyper-V Replica’s Replica server as the replica source.
  -	Enable VM replication from the Hyper-V Replica’s Primary server to the Replica server.
  -	Start replication.
  -	Start VM on Hyper-V Replication Primary server\*    
    \*This is the only step not done on the Replica server.    
    \*\*Be sure to change the user name and password variables in the scripts.
- **Stop.bat** determines what kind of stop event occurred. If the script resource or group was stopped, no action is taken. If it is a ‘group move’ or failover on the Primary server, a PowerShell script (*stop.ps1*) is called and VM replication is removed from the Hyper-V Primary and Replica servers. The VM is also stopped.    
    \*Be sure to change the user name and password variables in the stop.ps1 PowerShell script.
    
Scripts start or stop on the active server in either cluster. If the script fails to enable replication, stopping the script resource and starting it again may fix the problem.    

Currently Cluster1 is assumed to host the Primary (source) server for replication and Cluster2 hosts the Replica server. Separate scripts exist for the Primary server and the Replica server. Once a method is created to determine which cluster hosts the Primary replication role with 100% accuracy, the Primary server and Replica server roles can be switched between clusters.    

Link to [scripts](../script/2Cluster_2SD_Hyper-VRep/).
## Setup
1.	Prepare four Windows 2019 servers (Standard or Datacenter). 
2.	Join all servers to the same domain.
3.	Install Hyper-V on all servers.
4.	Create one iSCSI shared disk for both clusters and connect two servers to each disk. 
5.	Install ECX 5.0 on all four servers, being sure to Filter Settings of Shared Disk.
6.	Open necessary ports through the firewall on each server for ECX.
7.	Reboot all servers.
8.	Create two clusters of two nodes each, Cluster-1 and Cluster-2 (both nodes accessing the same disk), and add the following resources under the failover group:    
    -	fip resource    
    -	sd resource
9.	Before uploading the configuration file, go to the API tab of Cluster Properties and Enable API Service (HTTP Communication Method is fine) in order to use RESTful API calls.
10.	Install node.js 10.16.0 or 10.21.0 on all cluster nodes (for RESTful API calls).
11.	Test the clusters (move failover group between nodes in cluster) and also make sure that RESTful API commands work from nodes in Cluster-1 to nodes in Cluster-2.
    ````
    e.g. curl.exe http://<fip or ip>:29009/api/v1/groups -u <User Name>:<Password>
    ````
    Note that the output will be in json format
12.	Install a VM on the active node of Cluster-1 with all files stored on the iSCSI shared disk.
13.	Enable all servers in each cluster as Hyper-V Replica servers with Kerberos authentication.
14.	From Hyper-V Manager enable replication from the VM on the active node of Cluster-1 to the active node of Cluster-2.
15.	After replication has completed, add the failover scripts in ECX Manager.
16.	Test to verify that the configuration is correct.
## Testing
Cluster-1 and Cluster-2 active node 
- Stop group
  Expected result: VM will continue to run but replication will be interrupted.
- Start group    
  Expected result: No changes will be made and replication will continue normally.
- Move group from primary node to standby node within cluster 1    
  Expected result: Replication origination (VM replication's Primary server) will change to standby node. Replica server on cluster 2 will stay the same. VM will start on standby node.
- Move group back from standby node to primary node within cluster 1    
  Expected result: Replication origination (VM replication's Primary server) will change to primary node. Replica server on cluster 2 will stay the same. VM will start on primary node.
- Move group from primary node to standby node within cluster 2    
  Expected result: VM replication will change to standby node and standby node will become new Replica server. VM will remain in Off state.
- Move group from standby node to primary node within cluster 2    
  Expected result: VM replication will change to primary node and primary node will become new Replica server. VM will remain in Off state.
## Problematic scenarios
- The active node in both clusters fails over at the same time    
  Concern: Depending on the timing, the scripts to modify replication might interfere with each other, leading to failure re-enabling replication.

## Potential Enhancements
- Hyper-V replication monitoring
- Cross-cluster VM failover

## Other Notes
- Stopping the script resource and starting it again should fix replication in the event that the scripts failed or did not complete after a group move or failover.
- Why not use Get-VMReplication to figure out which VM replication server is the Primary server and which one is the Replica server after a group move or failover?    
  Answer: When a group move occurs from server1 in cluster 1 to server2 in cluster 1, the Stop script removes VM replication from both the Primary server and the Replica server. Since VM replication isn't set up after a group move or failover, the Get-VMReplication command will not return any result and so it is not possible to see which direction replication was going.
- Why remove replication before moving a group or failing over?    
  Answer: This is better explained by laying out what happens when a move group or failover occurs without removing replication.    
  Scenario: Failover group on cluster1 is moved from server1 to server2 with replication going to cluster2 server1
  1. VM replication is still configured on cluster1 server1 with cluster1 server1 as Primary to cluster2 server1 as Replica, but it no longer has access to the disk. Replication State becomes Error and Replication Health becomes Critical.
  2. Cluster1 server2 has control of the disk and the start script clears the replication setting on cluster2 server1. It then clears the replication setting on cluster1 server2 (if it exists) before setting up VM replication from cluster1 server2 as Primary to cluster2 server1 as Replica.
  3. Now move the group back to cluster1 server1.
  4. VM replication is still configured on cluster1 server2 with cluster1 server2 as Primary to cluster2 server1 as Replica, but it no longer has access to the disk. Replication State becomes Error and Replication Health becomes Critical.
  5. Cluster1 server1 has control of the disk again. The Replication State on cluster1 server1 is still Error and Replication Health is Critical. It is very difficult to manage replication in this condition, so replication needs to be removed from cluster1 server1 and cluster2 server1 and set up again. Removing replication on the other cluster (cluster2 server1) succeeds, but removing it from the local server (cluster1 server1) often fails, leading to a failure to set up replication again. The Windows error message is "Operation not allowed for virtual machine '<VM Name>' because the configuration was not accessible. Try again later." "Hyper-V failed to remove replication for '<VM Name>': Operation aborted (0x80004004)." I haven't been able to figure out why the 'configuration was not accessible' but have confirmed that the disk WAS accessible. This is why replication is removed at the beginning of a group move or failover in the stop script.    
  Note: This problem only seemed to show up on the cluster with the Primary replication server (server1). Running the start script again (stop the script and start again) would often fix the problem. But for some reason, calling the start script again from start.bat if replication configuration failed would usually not succeed.
