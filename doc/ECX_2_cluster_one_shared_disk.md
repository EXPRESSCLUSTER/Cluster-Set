# ECX 2 cluster one shared disk
Configuring VM in 2 cluster one shared disk
## Architecture
- This configuration consists of 2 clusters and 1 iSCSI disk.
- Make sure that the FO group is always running on one of the four nodes.

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

## Host servers' spec

- Windows Server 2019 Datacenter (Desktop Experience)
-  CPU
- 8GB RAM
- 2 NICs
- 2 HDDs, GB for OS and GB for EC-VM

## Setup procedure
### Create ECX Server & AD server
 - ***
 
### Installing Hyper-V

Open **Server Manager** and click **Add roles and features** from the dashboard.
- Check **Hyper-V** under **Server Roles**.
- Create one virtual switch for external access.
- Check **Allow this server to send and receive live migrations of virtual machines**.
	- Select **Use Credential Security Support Provider (CredSSP)**.
- VM's default location can be configured iSCSI disk.

After completing Hyper-V installation, configure Hyper-V settings in Hyper-V Manager.
- Create Virtual Switches in Virtual Switch Manager.
	- Management_switch was created during Hyper-V installation.
	- NAT_switch (External) should be newly created.
	- iSCSI_switch (External) should be newly created.
	- VM_switch (External) should be newly created.

- Create VM
	- Edit Live Migrations Settings (under Hyper-V Settings)
		- Check **Enable incoming and outgoing migrations**.


### Set up an ECX Server
- Open network adapter settings and set an IP address for each vEthernet adapter.
- Join servers to a domain and configure the firewall of the domain.
- Login to the domain account.

Once OS installation is finished, do the following on each EC VM:

1.Disable firewalld

2.Network settings
- Configure IP addresses, gateway, DNS, proxy

3.Connect iSCSI disk
 - **** 

4.Install ECX rpm & Register ECX license files

5.Reboot OS

6.Once you complete the above steps on both EC servers, create an ECX cluster


- Floating IP address
	- Should belong to the network connecting to iSCSI_switch.
- Shared  disk
	- File System: NTFS
	- Data Partition Device Name: /dev/cp-diska2
	- Cluster Partition Device Name: /dev/cp-diska1
 
7.Setting user name & password in EXPRESSCLUSTER.

8.Once you complete the above steps on both EC servers, create an ECX cluster.


- Floating IP address
	- Should belong to the network connecting to iSCSI_switch.
- Shared  disk
	- File System: NTFS
	- Data Partition Device Name: /dev/cp-diska2
	- Cluster Partition Device Name: /dev/cp-diska1
- Script resorce

start.bat 
```
rem **********
rem Parameter : the name of the VM to be controlled in the Hyper-V manager
set VMNAME=VM1
rem **********
IF "%CLP_EVENT%" == "RECOVER" GOTO EXIT

powershell -Command "Start-VM -Name %VMNAME% -Confirm:$false"

IF "%CLP_EVENT%" == "RECOVER" GOTO RECOVER

:EXIT
```
stop.bat
```
rem **********
rem Parameter : the name of the VM to be controlled in the Hyper-V manager
set VMNAME=vm1
rem **********

powershell -Command "Stop-VM -Name %VMNAME% -Force"
:EXIT
```
Genw
Add genw

9.Create VM in cluster.
- Edit Live Migrations Settings (under Hyper-V Settings)
	- Check **Enable incoming and outgoing migrations**.

10. Apply setting cluster

11. Test
12. 
## Testing
Cluster-1 and Cluster-2 active node 
- Stop group
- Start group
- Move group to other node within same cluster
- Move group back
- Move group to other node within other cluster
- Move group back

## Potential Enhancements
