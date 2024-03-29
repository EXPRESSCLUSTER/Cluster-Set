# Cluster Set with ECX

## What is Cluster Set?
- Features introduced from Windows Server 2019. See below for an overview.
  - https://docs.microsoft.com/ja-jp/azure-stack/hci/deploy/cluster-set

## Benefit of Cluster set
1. Scalability
2. LoadBalancing
3. Perform FO with VM backup restore (method ?,I don't understand much. I need to think about benefit)
4. Cluster-Configure a cluster consisting of VMs in the set with ECX to increase availability. (method? ?,I don't understand much. I need to think about benefit)

## How to verify the benefits
1. Measure the MTTR and MTBF, calculate the system availability, and compare the availability of the ECX alone with that of the cluster set.
2. - Is there a difference in writing performance to the disk?
   - Investigate items that can be realized at low cost

## How to realize Cluster Set
- final goals
  --Achieves the same function as Cluster Set only with ECX without WSFC (whether it is superior to WSFC or not is set aside)
  

### Limitations
- (First of all,)Live Migration is excluded.
- Set the data replication method aside.
　- First, focus on the node management method.


### Configuration plan
- According to Microsoft's Cluster Set image, Master is supposed to be on a VM on each WSFC. But for simplicity, I think of Master and Worker separately.
- They are separated as VMs, or the location of VMs can be on the same physical machine.
- Witness Server is also required.
  - Witness Server contains the status of the server, so is this information available?
  - Contact Witness Server to get the status of the running server with RESTful API?
- For simplicity, both Master and Worker have a 2-node configuration in the figure below.
- AD, DNS, client omitted. At first, consider putting them all in the same domain.
- Access to the Worker server from the client uses name resolution by DNS. 
```

                          +----------------+
                          | Master Cluster |
+---------+               | +---------+    |
| Witness |----------+-+----| Master1 |    |
+---------+          | |  | +---+-----+    |
                     | |  |     |          |
                     | |  | +---+-----+    |
                     | +----| Master2 |    |
+------------------+ |    | +---------+    |
| Active Directory |-+    +----------------+
+------------------+ |
                     |    +-----------------+
                     |    | Worker Cluster1 |
                     |    | +-----------+   |
                     +------| Worker1-1 |   |
                     |    | +---+-------+   |
                     |    |     |           |
                     |    | +-----------+   |
                     +------| Worker1-2 |   |
                     |    | +---+-------+   |
                     |    +-----------------+
                     |
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

### Master
- Build a cluster with ECX.
- Check the status of workers one by one.
   --Use RESTful API etc.
- Referal SoFS
   --Use ECX's DDNS to replace it.


### Worker
- Build a cluster with ECX.
- Enable RESTful API.



## Milestone
### 1st step: The purpose is to control the Worker from the Master
- We need to get cluster status and operate cluster
- Check if the connection is possible from the client.

### 2nd step: Handing over data between workers
- Since mirror disk resources and hybrid disk resources cannot be used, it is necessary to consider ways to take over the data by other means.
- If you want to failover the VM, can you take advantage of the backup and restore of the VM

## Script Outline
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
### Feature
- A cluster set consisting of 2 clusters and 2 nodes
- Make sure that the FO group is always running on one of the four nodes.
- Priority is server 1 , server 2, 3, 4
- If FO group cannot be started on server 1, try to start on server 2.

### Script description
- l1-l26  
  - Set server and user information.
- l27-l58  
  - Check if the server that started the script belongs to the cluster set
- l59-l111  
  - Get FO group status of own cluster
  - If any one is online, exit this program.
  - If both are offline, proceed to next step.
- l112~165  
  - Get FO status of other cluster
  - If any one is online, end
  - If both are offline, proceed to next step
- l166-l201  
  - Get custom monitor resource status for each of the 4 servers.
- l202-l217  
  - Processing when custom monitors are running on four servers
  - Start FO group on server 1
- l218-l259  
  - Processing when the custom monitor is not running on any one of the servers
  - Attempt to start FO group in order from server 1 according to the priority
  - If there is a server that can be started, exit there
  - If the server cannot be started, start it on server 2 in order to the priority
