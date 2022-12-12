# Cluster-Set
The goal is to realize the value of WSFC's Cluster-Set with ECX.

## Implementing Cluster-Set by EC (planning and investigation)

### Gary's premise 2022.08.02

- Ignore network address difference across migration.
- LiveMigration still needs WSFC.
- Firewall going to be configured
- Hyper-V Replica
	- Router VM will not be required
- 2 node clusters
- MD resource will not be used
- Scripts will manage intra-cluster VM moves and replication changes between clusters
- Manually move the VM Cross-Cluster using Hyper-V Replica's "Planned Failover" option: 
	- Stop the VM on a node in cluster-A
	- Select option to reverse the direction of replication
	- Select option to start the VM on a node in cluster-B
- LM requirement : optional or mandatory
- WSFC requirement : optional or mandatory

### Yoshida's Ideas 2022.08.03

- The values of Cluster-Set
	- Scalability
	- Load Balancing
	- Can be managed fully by CLI
	- Fault domains and Availability set
- Implement LB on Cluster-Set
- Implement the function for deletion of (script, MD, SD) resource from `clp.conf`. `clpcfset` does not have the function.

### WSFC with Hyper-V Replica notes 2022.09.14
*Relocation of a VM from one server rack to another is possible without using Cluster-Set*    

 **Testing Configuration**
- Two WSFC clusters of 2 nodes each were created    
	\*Note that clusters can have more nodes and be in the same domain or on different subnets.
- Hyper-V Replica Broker was added as a role to each WSFC cluster to facilitate cross-cluster VM migration
- Hyper-V Replica server was configured on each cluster from the Hyper-V Replica Broker role in Failover Cluster Manager.     
	- By configuring this on both clusters, the replication direction can be reversed when a VM is moved from one cluster to another.
	- A specific server in a cluster cannot be selected, so the Hyper-V Replica Broker fills in to represent all of the servers in the cluster. 
- Hyper-V Replication from WSFC cluster1 to WSFC cluster2 was enabled from the VM in Failover Cluster Manager
	- Kerberos authentication (http) can be used for clusters in the same domain.
	- Certificate-based authentication (https) can be used for clusters in the same domain or in different subnets.

**VM Migration**
- VMs can be moved across clusters using the Planned Failover feature of Replication (this was confirmed in testing)
	- VMs must be stopped first since live migration is not possible.
- VMs can be live-migrated to another node within the same cluster from Failover Cluster Manager (also confirmed in testing)

## Implementing Cluster-Set by EC (application)

### 1. ECX 2-cluster one shared disk

### ECX 2 cluster note 2022.09.28 
*Reproduce the same configuration as Cluster-Set only with ECX*

**Testing Configuration**
- Two clusters of 2 nodes each were created.
- They connect to the same iSCSI and check the contents of the disk.
- Set start script and end script to control VM.
- I stop the disk resource from one of the cluster, to prevent seeing on the same disc at the same time.
- I use RestfulAPI in my custom monitor resource script to check if other clusters are running 
- It is difficult to FO to other cluster with only script resource.
	- There is a risk that the script will not run when the server turned off at the same time by using the script resource.
	- It is not possible to determine when to move manually and when not to move during maintenance etc.

**VM Migration**
- VMs can be moved across clusters using the script resource and Stopping the disk resource by manual.

### ECX 2 cluster script outline
- This script can be started on any server
- The information of cluster1, cluster2, server1, server2, server3, server4 as variables
- specify as an array
- subsequent processing
- Get the status of the cluster to which the server belongs, change the URL later

```
$result = curl.exe -u root:cluster-0 http://127.0.0.1:29009/api/v1/groups/failover1 --noproxy 127.0.0.1 | ConvertFrom-Json
if ($result.groups.status -eq "Online")
{
    Write-Output "Failover group is running on my cluster."
    exit 0
}
```

- Get group status of other cluster
- Insert the process to get the status of the group from other clusters here
- If a communication error occurs, go to another server in another cluster to get the status
```
if ($result.groups.status -eq "Online")
{
    Write-Output "Failover group is running on the other cluster."
    exit 0
```
 Start group with RESTful API or clprexec

### 2. ECX 2 cluster two shared disks with Hyper-V Replication

This Cluster Set type solution uses Hyper-V replication between active nodes on each cluster. If required, a cross-cluster VM “move” can be done using the Planned Failover command and then reversing replication.

#### Notes:
- All nodes in each cluster belong to the same domain.
- A cross-cluster VM move is not automated. It has to be done manually.
- Scripts automate intra-cluster failovers, changing Hyper-V Replica’s Primary or Replica servers as needed.
- Kerberos authentication was used.
- RESTful API used to query details of the other cluster 

#### Testing Configuration
•	Two ECX clusters of two nodes each were created (Windows Server 2019).
•	Each cluster has one iSCSI shared disk.
•	FIP resource is used.
•	Script resource is used.

## Other

### Move-VM

If you only want to temporarily move a VM to another cluster (while performing maintenance), and do not care about HA or DR, this PowerShell command will work. The command can Live-Migrate a VM from a node in Cluster-A to a node in Cluster-B.

```
Move-VM -Name <vm name> -DestinationHost <active node in other cluster> -IncludeStorage -DestinationStoragePath <location for files>
```

