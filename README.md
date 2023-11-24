# svmtool
### Powershell tools to manage NetApp Storage Virtual Machine (aka SVM)

## This script is not a NetApp product, so there is not support at all for this script which is provided as is


This script use [NetApp PowerShell Toolkit](https://mysupport.netapp.com/site/tools/tool-eula/powershell-toolkit)

If you need to Encrypt your destination volumes you will need at least the version 4.7 of the PowerShell ToolKit (PSTK)

It also require at least .Net Framework v3.5 and Windows Powershell at least v3.0.

SVMTOOL is now compatible with Powershell Core (Powershell version 7.x and upper)

So SVMTOOL is now compatible under Windows, Linux and MacOS.

To execute SVMTOOL under Linux or MacOS you must install the last PSTK v9.9.1 which compatible with Powershell Core.

Compatible with REST API with at least PSTK 9.13.1.2306 and ONTAP 9.10.1 or upper

Due to BURT 1525926 and with Metrocluster in the loop you must run the following ONTAP version or upper:
9.10.1P14, 9.11.1P11, 9.12.1P5, 9.13.1P2



Mains objectives of this script are:
- Create/Maintain/Manage SVM Disaster Relationship between NetApp MetroCluster
- Migrate SVM between Cluster or MetroCluster
- Backup and Restore all configuration (volumes, lif, cron, junction-path, etc...) to original or alternate cluster
- Clone DR SVM which allows to test your DR SVM through a cloned version of it, without interrupting SnapMirror relationships during the test timeframe

### DR & Migration Purpose
**All Supported Options**

Supported Protocols | SVMTOOL
--------------------|--------
Support NFS | Yes
Support CIFS | Yes
Support iSCSI | Yes
Support FCP | No

Supported Network Services | SVMTOOL
---------------------------|--------
DNS Client Setup | Yes
NIS Client Setup | Yes
LDAP Client Setup | Yes

Supported NAS Objects | SVMTOOL
---------------------|---------
Export Policy & Rules | Yes
CIFS Shares | Yes
CIFS ACL | Yes
CIFS HomeDir | Yes
CIFS NetBios Alias | Yes
Quota Replication* | Yes
Snapshot Policy* | Yes
QoS Policy Group | Yes
Vscan Policy | Yes
Fpolicy | Yes
CIFS Local User & Group | Yes
CIFS Symlink | Yes
Name Mapping | Yes
Local Unix User & Group | Yes
Vserver User & Role | Yes
Flexgroup<br>Due to current Flexgroup limitations, any SVM with Flexgroup will not be compatible with<br>Double DR and Synchronous Data replication<br>You need ONTAP 9.7 on destination if you want to use CloneDR with Flexgroup | Yes

(*)Require a Local SVMDB flat files database to replicate Quota and Snapshot-Policy

Supported SAN Objects | SVMTOOL
----------------------|--------
SAN iGroup* | Yes
SAN LUN* | Yes
SAN LUN Serial Number* | Yes
SAN LUN Mapping* | Yes

(*)Only for iSCSI protocol

Supported Options | SVMTOOL
------------------|--------
Create a new SVM DR relationship | Yes
Update DR SVM | Yes
Activate DR SVM | Yes
Remediation with Resync or Resync Reverse | Yes
Provisioning New Volumes during Update | Yes
Can be used to Failover | Yes
Can be use to test Failover | Yes
Use an MCC for source or destination or both | Yes
Two differents DR destination | Yes
DR inside the same cluster, between HA pair in different rooms | Yes
Use Version Flexible SnapMirror when necessary<br>(by example: build a DR from 8.3.2 to 9.X) | Yes
Migrate an SVM and keep it identity<br>For CIFS, IP and Server Name will be the same,<br>so users will only have to reconnect just by refreshing explorer<br>or double-click on folder<br> | Yes 
Select subset of sources volumes that will be replicated | Yes
Clone DR SVM<br>In order to test DR without interrupting SnapMirror relationships during the timeframe of the test | Yes
FabricPool on Destination | Yes<br>
Encrypt Destination's volumes (NVE)<br>with conversion support if running at least ONTAP 9.3 | Yes
Compatible with SM-S (Sync and StrictSync Policy) for Data replication<br>Is able to convert from Async to Sync relationship and vice versa<br>Object replication cannot be Synchronous and is still an Asynchronous replication | Yes
Preserve Network Identity<br>By default, svmtool will Preserve Network Identity between Source and DR<br>But you can, if needed, create a DR with its own Network Identity and preserve it during Activation | Yes
Compatible with Powershell Core under Windows, Linux and MacOS<br>Requiere PSTK Core | Yes
Migrate inside the same MCC : Move SVM from ClusterA to ClusterB inside the same Metrocluster | Yes



### BACKUP & RESTORE Purpose
In order to perform a restore operation a minimal config must exist on the destination Cluster:
- Node Setup done
- Cluster Setup done
- Data aggregates recreated
- Low Level Network configuration done : IFGRP, IPSPACE, SUBNET, BROADCAST-DOMAIN already created

### RestoreObject Purpose
Allow to restore only part of SVM configuration to original SVM or to different SVM on same or different Cluster

Currently compatible with following Objects:
- LIFs
- Volumes
- Exports (NFS rules)
- Shares (CIFS shares)

### Documentation
For more information download [Manual](https://github.com/oliviermasson/svmtool/blob/master/SVMTOOL_Manual_v2.4.pdf)

HTH
