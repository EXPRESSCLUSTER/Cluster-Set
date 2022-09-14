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
