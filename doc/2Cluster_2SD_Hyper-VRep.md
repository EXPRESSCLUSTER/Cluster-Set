# 
Script Details
•	Variables need to be set in SetEnvironment.bat.
•	Start.bat determines if any action needs to be taken. If replication is progressing normally, no action is taken. If a ‘move group’ or failover just occurred, replication is changed to occur between the active servers on each cluster.
•	Stop.bat determines what kind of stop event occurred. If the script resource or group was stopped, no action is taken. If it is a ‘group move’ or failover, VM replication is removed from the Hyper-V Primary and Replica servers.
•	Start.bat calls a startup script which will do the following on the Primary server:
o	Determine which cluster has the Hyper-V Primary server role and Replica server role.
o	Remove replication from the Primary and Replica servers if still enabled.
o	Register the VM in Hyper-V Manager if it has not been done on the server the script is run from.
o	Enable the VM files on the Hyper-V Replica’s Replica server as the replica source.
o	Enable VM replication from the Hyper-V Replica’s Primary server to the Replica server.
o	Start replication.
o	Start VM on Hyper-V Replication Primary server*

*This is the only step not done on the Replica server.
•	Scripts start or stop on the active server in either cluster.
Setup
1.	Prepare four Windows 2019 servers (Standard or Datacenter) 
2.	Join all servers to the same domain
3.	Install Hyper-V on all servers
4.	Create one iSCSI shared disk for both clusters and connect two servers to each disk 
5.	Install ECX 5.0 on all four servers, being sure to Filter Settings of Shared Disk
6.	Open necessary ports through the firewall on each server for ECX
7.	Reboot all servers
8.	Create two clusters of two nodes each, Cluster-1 and Cluster-2 and add the following resources under the failover group:
a.	fip resource
b.	sd resource
9.	Before uploading the configuration file, go to the API tab of Cluster Properties and Enable API Service (HTTP Communication Method is fine) in order to use RESTful API calls
10.	Install node.js 10.16.0 or 10.21.0 on all cluster nodes (for RESTful API calls)
11.	Test the clusters (move failover group between nodes in cluster) and also make sure that RESTful API commands work from nodes in Cluster-1 to nodes in Cluster-2
e.g. curl.exe http://<fip or ip>:29009/api/v1/groups -u <User Name>:<Password>
Note that the output will be in json format
12.	Install a VM on the active node of Cluster-1 with all files stored on iSCSI shared disk
13.	Enable all servers in each cluster as Hyper-V Replica servers using Kerberos authentication
14.	From Hyper-V Manager enable replication from the VM on the active node of Cluster-1 to the active node of Cluster-2
15.	After replication has completed, add failover scripts in ECX Manager
16.	Test
Testing
•	Cluster-1 and Cluster-2 active node 
Stop group
Start group
Move group to another node in cluster
Move group back
Problematic scenarios
•	The active node in both clusters fails over at the same time
Concern: Depending on the timing, the scripts to modify replication might interfere with each other, leading to failure re-enabling replication.
Potential Enhancements
•	Hyper-V replication monitoring

Other Notes
•	Stopping the script resource and starting it again should fix replication in the event that the scripts failed or did not complete after a group move or failover.
