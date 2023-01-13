# ECX 2 cluster one shared disk
Configuring VM in 2 cluster one shared disk
## Architecture
- This configuration consists of 2 clusters and 1 iSCSI disk.
- Make sure that the failover group is always running on one of the four nodes.

```
                          +-----------------+
                          | Worker Cluster1 |
                          | +-----------+   |
                     +------| Worker1-1 |   |
                     |    | +---+-------+   |
                     |    |     |           |
                     |    | +-----------+   |
                     +------| Worker1-2 |   |
                     |    | +---+-------+   |
                     |    +-----------------+
+------------------+ |
| Active Directory |-+    
+------------------+ |                     
                     |
+------------------+ |
| iSCSI Disk       |-+    
+------------------+ |
                     |    +-----------------+
                     |    | Worker Cluster2 |
                     |    | +-----------+   |
                     +------| Worker2-1 |   |
                     |    | +---+-------+   |
                     |    |     |           |
                     |    | +-----------+   |
                     +------| Worker2-2 |   |
                          | +---+-------+   |
                          +-----------------+
```

## Worker Cluster Servers' spec

- Windows Server 2019 Datacenter (Desktop Experience)
- 1 CPU
- 8GB RAM
- 2 NICs
- 2 HDDs, 10 GB for OS and GB for VM

## Setup procedure
### Create ECX Server & AD server
- Open network adapter settings and set an IP address.
- Join servers to a domain and configure the firewall of the domain.
- Login to Worker Cluster using the domain account.
 
### Install Hyper-V

Open **Server Manager** and click **Add roles and features** from the dashboard in Worker Cluster.
1. Check **Hyper-V** under **Server Roles**.
2. Create one virtual switch for external access.
3. Check **Allow this server to send and receive live migrations of virtual machines**.
	- Select **Use Credential Security Support Provider (CredSSP)**.
4. VM's default location can be configured iSCSI disk.

After completing Hyper-V installation, configure Hyper-V settings in Hyper-V Manager.
- Create Virtual Switches in Virtual Switch Manager.
	- iSCSI_switch (External) should be newly created.

- Create VM
	- Edit Live Migrations Settings (under Hyper-V Settings)
		- Check **Enable incoming and outgoing migrations**.


### Set up an ECX server

1. Disable firewalld for testing.

1. Network settings
   - Configure IP addresses, gateway, DNS, (proxy)

1. Connect iSCSI disk

1. Install ECX  & Register ECX license files

1. Reboot OS

1. Once you complete the above steps on both EC servers, create an ECX cluster
   - Floating IP address
   	  - Should belong to the network connecting to iSCSI_switch.
   - Shared  disk
   	  -Allocate a partition for disk heartbeat.
      	  	-Configure it as RAW partition without formatting.
   - Script resorce
   		- start.bat
            
           ```
           rem **********
           rem Parameter : the name of the VM to be controlled in the Hyper-V manager
           set VMNAME=vm1
           rem **********
           IF "%CLP_EVENT%" == "RECOVER" GOTO EXIT

           powershell -Command "Start-VM -Name %VMNAME% -Confirm:$false"

           :EXIT
           ```
   		- stop.bat
           ```
           rem **********
           rem Parameter : the name of the VM to be controlled in the Hyper-V manager
           set VMNAME=vm1
           rem **********

           powershell -Command "Stop-VM -Name %VMNAME% -Force"
           :EXIT
           ```
   - Custom monitor resource
   		- Apply genw.bat
	
        	 ```
           	 rem **********
        	 rem Parameter : the name of the VM to be controlled in the Hyper-V manager
        	 set VMNAME=vm1
          	 rem **********

          	 rem powershell C:\Users\script\Recover-Group.ps1
          	 exit 0
          	 ```
		 
	         - https://github.com/EXPRESSCLUSTER/Cluster-Set/blob/main/script/Recover-Group.ps1
		 - ../script/Recover-Group.ps1
			 - Timeout must be more than or equal to sleep.
1. Setting user name & password in EXPRESSCLUSTER to use the RestfulAPI.

1. Create VM in cluster.
	- Edit Live Migrations Settings (under Hyper-V Settings)
		- Check **Enable incoming and outgoing migrations**.

1. Apply setting cluster

1. Test  to verify that the configuration is correct.

## Details of the script to set in custom monitor resource
- Run this script on all four nodes.
- At first, check the status of own cluster.
- If there is no failover group running in the cluster, check the status of other clusters.
- If there are no failover group running in other clusters, try to start failover group in order to the priority.
- Make sure that the failover group is always running on one of the four nodes.
- Set the priority is server 1 , 2, 3, 4.
- If FO group cannot starte on server 1, try to start on server 2. If FO group cannot started on server 2, try to start on server 3.

## Testing
- Stop group
	 - Expected result:  FO group & VM starts on the server with the highest priority.
- Start group
	 - Expected result:  FO group & VM starts on the server.
- Move group to other node within same cluster
 	 - Expected result:  FO group & VM starts on other node within same cluster.
- Move group back
	 - Expected result:  FO group & VM starts on the returned server.
- Move group to other node within other cluster
 	 - Expected result:  FO group & VM starts on other node within other cluster.
- Move group back on other cluster
	 - Expected result:  FO group & VM starts on the returned cluster.

## Potential Enhancements
- It is necessary to think about what to do when all nodes fail.
