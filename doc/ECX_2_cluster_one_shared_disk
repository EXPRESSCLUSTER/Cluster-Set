# ECX 2 cluster one shared disk
Configuring VM in 2 cluster one shared disk

## Host servers' spec

- Windows Server 2019 Datacenter (Desktop Experience)
-  CPU
- 8GB RAM
- 2 NICs
- 2 HDDs, GB for OS and GB for EC-VM

## Setup procedure
### Create ECX Server & AD server
 Domain User login
 
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
- 

4.Install ECX rpm & Register ECX license files

5.Reboot OS

6.Once you complete the above steps on both EC servers, create an ECX cluster


Floating IP address
	- Should belong to the network connecting to iSCSI_switch.
Shared  disk
	- File System: NTFS
	- Data Partition Device Name: /dev/cp-diska2
	- Cluster Partition Device Name: /dev/cp-diska1
EXEC
 
