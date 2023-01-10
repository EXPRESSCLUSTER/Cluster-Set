rem ===============================================
rem Parameters
rem -----------------------------------------------
rem VM 		: Virtual Machine Name
rem OppFip	: FIP of Opposite Cluster
rem OppGrp	: Opposite Cluster Group Name
rem RestURI	: REST API endpoint
rem VMPath	: Path to VM's 
rem vmcxid	: vmcx file
rem vmcx	: full path to vmcx file
set VM=TestVM1
set OppFip=192.168.1.1
set OppGrp=failover1
set RestURI=http://%OppFip%:29009/api/v1/groups/%OppGrp%
set VMPath=T:\VMs\Hyper-V Replica\Virtual Machines
set vmcxid=4C909935-BB32-4E7E-95B1-585F4F0DD174.vmcx
set vmcx=T:\VMs\Hyper-V Replica\Virtual Machines\4C909935-BB32-4E7E-95B1-585F4F0DD174.vmcx
