# Cluster-Set
The goal is to realize the value of WSFC's Cluster-Set with ECX.

## Implementing Cluster-Set by EC

### Gary's premise 2022.08.02

- Ignore network address difference across migration.
- LiveMigration still needs WSFC.
- Firewall going to be configured
- Hyper-V Replica
	- Router VM will not be required
- 2 node clusters
- MD resource will not be used
- Manually move the VM: a script would be run the commands. 
	- Stop the VM on a node in cluster-A
	- Start the VM on a node in cluster-B
	- Reverse the direction
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

### ECX 2 cluster note 2022.09.21 
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
