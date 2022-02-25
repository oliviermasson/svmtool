<#
.SYNOPSIS
	The svmdr script allows to manage DR relationship at SVM level
	It also help to Backup & Restore SVM configuration
.DESCRIPTION
	This script deploys tools to:
	creates and manages Disaster Recovery SVM for ONTAP cluster
	Backup & Restore full configuration settings of an SVM
.PARAMETER Vserver
    Vserver Name of the source Vserver
.PARAMETER Instance
    Instance Name which will associate two cluster for a DR scenario
    An instance could manage one or several SVM DR relationships inside the corresponding cluster
.PARAMETER RootAggr
    Allows to set a default aggregate for SVM root volume creation
    Used only with ConfigureDR or CloneDR options
.PARAMETER DataAggr
    Allows to set a default aggregate for all SVM data volume creation
    Used only with ConfigureDR, UpdateDR, UpdateReverse, CloneDR options
.PARAMETER MirrorSchedule
    Allows to set a SnapMirror automatic update schedule for Source to DR relationship 
    When used with ConfigureDR and UpdateDR the default schedule is "hourly" (for backwards compatibility)
    When used with ConfigureDR and UpdateDR you can use "none" to omit the schedule
.PARAMETER MirrorScheduleReverse
    Optional argument
    Allow to set a SnapMirror automatic update schedule for DR to Source relationship 
.PARAMETER ListInstance
	Display all Instance available and configured
.PARAMETER CredName
    Provide a Credential name that will have its password reseted through ListInstance -ResetPassword -CredName <Credential Name>
.PARAMETER ImportInstance
	Import previous generation SVMDR script's instances
.PARAMETER RemoveInstance
    Allow to remove a previously configured instance
    -RemoveInstance <instance name>
.PARAMETER Setup
    Used with Instance to create a new instance
    -Instance <instance name> -Setup
.PARAMETER PrimaryCluster
    Use for silent setup
.PARAMETER SecondaryCluster
    Use for silent setup
.PARAMETER QuotaDR
    Use for silent setup
    Enables QuotaDR for this setup
.PARAMETER Help
    Display help message
.PARAMETER ResetPassword
    Allows to reset all passwords stored for all instances
.PARAMETER HTTP
    Optional argument
    Allow to connect controller with HTTP instead of HTTPS
.PARAMETER ConfigureDR
    Allow to Create (or update) a SVM DR relationship
    -Instance <instance name> -Vserver <vserver source name> -ConfigureDR [-SelectVolume] -[PreserveIdentity <true|false>] [-RootAggr <aggr>] [-DataAggr <aggr>]

    -SelectVolume : (switch parameter) Allows to select volume one by one before creating a DR volume
    -PreserveIdentity : (bool parameter) Allows to set PreserveIdentity Mode. Default is True
    -RootAggr : (string parameter) Defines destination aggr name where to store SVM root volume
    -DataAggr : (string parameter) Defines destination aggr name where to store destination volumes 
.PARAMETER ShowDR
    Allow to display all informations for a particular SVM DR relationship
    -Instance <instance name> -Vserver <vserver source name> -ShowDR [-Lag] [-schedule] [-NoVolumeDetail]
    Optional parameters:
        Lag            : display lag beetween last transfert
        Schedule       : display automatic schedule set on SnapMirror relationship
        NoVolumeDetail : only display SVM informations
.PARAMETER DeleteDR
    Allow to delete a SVM DR relationship, by deleting all data and object associated to the DR SVM
    -Instance <instance name> -Vserver <vserver source name> -DeleteDR
.PARAMETER DeleteSource
    During Migrate procedure, you could choose not to delete source SVM
    In this case, source SVM is only stopped
    Once everything has been test and validate on destination, you could safely delete the source SVM,
    by running DeleteSource step
    PS: if you do not DeleteSource and want to go back to normal situation (Sync from Primary to Secondary) after a Migrate you can performs following operations:
        . ResyncReverse with ForceRecreate
        . UpdateReverse
        . ReActivate
.PARAMETER RemoveDRconf
    Delete configuration files for a particular SVM DR relationship
    -Instance <instance name> -Vserver <vserver source name> -RemoveDRconf
.PARAMETER UpdateDR
    Allow to update data and metadata for a particular SVM DR relationship
    -Instance <instance name> -Vserver <vserver source name> -UpdateDR
.PARAMETER Backup
    Backup Cluster/SVM configuration into JSON files
    Without specifying any Vserver, will backup all SVM availables

    -Backup <Cluster Name> [-Vserver <SVM name>] [-RecreateConf]
    
	-RecreateConf : Force recreate Backup configuration directory for selected Cluster
.PARAMETER Restore
	Restore Cluster/SVM configuration from JSON files
    Without specifying any Vserver, will list available SVM if backup folder and Restore all of them.

    -Restore <Cluster Name> [-Vserver <SVM name>] [-SelectBackupDate] [-DestinationCluster] [-RW]
    
	-Vserver : Choose one SVM to restore. By Default restore all SVM available in Backup folder
	-SelectBackupDate : Ask script to display all dates availables and prompt user to choose a date to restore. 
						By default select last data available in backup folder
	-Destination : Destination Cluster where to restore selected SVM.
                   If not specified, script will ask for
    -RW : When restoring volumes, chose to restore them as Read/Write volumes
          By default will restore as DP volumes
.PARAMETER RestoreObject
    Restore a specific Object configuration from JSON files to one destination SVM
    You must specify the SourceCluster & SourceSVM from which object will be restored
    You must specify DestinationCluster & DestinationSVM to which object will be retored
    
    -RestoreObject <Source Cluster> -Vserver <source SVM name> [-DestinationCluster <Dest Cluster>] [-DestinationSVM <dest SVM name>] -Object <name> [-SelectBackupDate] [-RW]

    -Vserver : Name of Source SVM where to select object to restore
    [-DestinationCluster] : Name of Cluster where to restore object
                            If not specified, restore to source Cluster
    [-DestinationSVM] : Name of destination SVM where to restore object
                        If not specified, restore to source SVM
    -Object : List of available object for restore operation
              Lif, Volumes, Exports, CifsServer, Shares, Symlinks, Quotas, Users
    [-SelectBackupDate] : Ask script to display all dates available and prompt user to choose a date to restore. 
                          By default select last data available in backup folder
    [-RW] : When restoring volumes, chose to restore them as Read/Write volumes
            By default will restore as DP volumes
.PARAMETER Migrate
    Allow to migrate a source SVM to destination SVM
    ConfigureDR and UpdateDR should have already been successful
	You could choose to cleanly delete source SVM
	Destination SVM is started with source identity (IP address and CIFS server identity)
    -Instance <instance name> -Vserver <vserver source name> -Migrate [-ForceUpdateSnapPolicy]
.PARAMETER CreateQuotaDR
    Allow to recreate all quota rules on the DR SVM
	-Instance <instance name> -Vserver <vserver source name> -CreateQuotaDR
	PS: SnapMirror relationship must be broken
.PARAMETER ReCreateQuota
    Allow to recreate all quota rules on the source SVM
    -Instance <instance name> -Vserver <vserver source name> -ReCreateQuota
.PARAMETER CorrectQuotaError
    Optional argument
    Allow to Correct Source Quota Error before to save the Quota rules configuration in SVMTOOL_DB
	Used with ConfigureDR, UpdateDR and UpdateReverse
.PARAMETER IgnoreQtreeExportPolicy
    Optional argument
    Allow to not check Qtree Export Policy during an UpdateDR
    This option greatly reduces cutover window.
    This can only be used during the last UpdateDR, when activity has been shutdown on source and before the ActivateDR.
    Obviously, a previous UpdateDR should be run without this argument in order to sync all Qtree Export Policy.
	This penultimate UpdateDR will be launched (normally without this argument) right after freezing all creation/modification/deletion of qtree, 
	but by keeping an activity on source platform.
.PARAMETER IgnoreQuotaOff
    Optional argument
    Allow to ignore a volume for which quota are currently set to off
    Used with ConfigureDR, UpdateDR and UpdateReverse
.PARAMETER LastSnapshot
    Deprecated
.PARAMETER UpdateReverse
    Allow to update data and metadata during a DR test or crash un reverse order, from DR to source
    -Instance <instance name> -Vserver <vserver source name> -UpdateReverse
.PARAMETER CleanReverse
    Remove all broken Reverse SnapMirror relationship (after DR test or crash)
    -Instance <instance name> -Vserver <vserver source name> -CleanReverse
.PARAMETER Resync
    Force a manual update of all data only for a particular DR relationship 
    -Instance <instance name> -Vserver <vserver source name> -Resync
.PARAMETER ActivateDR
    Switch Production from Primary SVM to Secondary SVM
    Test if Primary is still alive and perform necessary operations to switch IP and services
    from Primary to Secondary and break all snapmirror relationship to make destination volumes accessible in Read & Write
    If Primary not alive it will force activation and switch to Secondary SVM
	-Instance <instance name> -Vserver <vserver source name> -ActivateDR [-ForceUpdateSnapPolicy]
.PARAMETER CloneDR
	Clone a Vserver on destination Cluster
	A new temporary Vserver will be created on destination Cluster (named <destination-vserver>_clone)
	All destination volumes will be cloned as RW volumes and hosted into this new temporary Vserver
	This allows testing the DR without interrupting SnapMirror relationship between Source Vserver and Destination Vserver
	-Instance <instance name> -Vserver <vserver source name> -CloneDR [-DefaultPass] [-RootAggr <default svm rootvol aggregate name>]
.PARAMETER SplitCloneDR
	Split a Cloned Vserver (not ready yet)
.PARAMETER DeleteCloneDR
	Delete a Cloned Vserver
	-Instance <instance name> -Vserver <vserver source name> -DeleteCloneDR [-CloneName <Vserver Clone DR name>]
	If [-CloneName] is not specified, script will search for all Clones associated with DR Vserver for this instance
	Only delete Cloned Vserver where all Flexclone are not splitted
.PARAMETER CloneName
	Name of the Cloned Vserver to work with
	Use with [-DeleteCloneDR]
.PARAMETER DefaultPass
	Deprecated. Use DefaultLocalUserCredentials argument
	Force a Default Password for all users inside an SVM DR or Clone SVM
.PARAMETER ForceClean
	Optional argument used only during CleanReverse step
	It allows to forcibly remove and release Reverse SnapMirror relationships
.PARAMETER ForceRestart
	Optional argument used to force restart of a stopped Vserver
	Used with ReActivate option
.PARAMETER ForceDeleteQuota
    Optional argument
    Allow to forcibly delete a quota rules in error
    Used with ConfigureDR, UpdateDR and UpdateReverse
.PARAMETER ForceRecreate
    Optional argument used only in double DR scenario or during Source creation after disaster
    Allow to forcibly recreate a SnapMirror relationship
	Used with ReaActivate, Resync and ResyncReverse
.PARAMETER ForceUpdateSnapPolicy
	Optional argument
	Allow to forcibly update SnapShot Policy on destination volume, based on source Snapshot Policy
	Warning: If Source & Destination volume have different number of snapshot (XDP relationship)
			 This could cause the deletion of snapshot on destination
.PARAMETER AlwaysChooseDataAggr
    Optional argument used to always ask to choose a Data Aggregate to store each Data volume
    Used with ConfigureDR only
.PARAMETER SelectVolume
    Optional argument used to choose for each source volume if it needs to be replicated/cloned on SVM DR or not
    Used with ConfigureDR and CloneDR only
.PARAMETER ResyncReverse
    Force a manual update of all data only for a particular DR relationship in reverse order, DR SVM to Source SVM 
    -Instance <instance name> -Vserver <vserver source name> -ResyncReverse
.PARAMETER ReActivate
    Allows to ReActivate a source SVM after a DR-test or RealLife Crash.  
    This will ReverseActivateDR (Destination->Source) + Resync (Source->Destination), 
    thus recovering the relationship to the original state (Source->Destination)
    -Instance <instance name> -Vserver <vserver source name> -ReActivate [-ForceUpdateSnapPolicy]
.PARAMETER Version
    Display version of the script
.PARAMETER DRfromDR
    Optional argument used only in double DR scenario
    Allow to create the second DR relationship for a particular instance and SVM
    Used only with ConfigureDR
.PARAMETER XDPPolicy
    Optional argument to specify a particular SnapMirror policy to use when creates or updates XDP relationship
    By default, it uses MirrorAllSnapshots policy
    The specified Policy must already exist in ONTAP and be correctly configured
    You can change XDPPolicy with this argument during ConfigureDR or UpdateDR operations
.PARAMETER NoSnapmirrorUpdate
	During UpdateDR, omit snapmirror updates in the assumption that schedules are applied.
	Note that new snapmirrors will of course still be created
.PARAMETER NoSnapmirrorWait
	During UpdateDR, omit snapmirror wait, to speed up the process
	Note that this will create a bigger lag to create mounts and shares as it will only be picked up by next run, assuming snapmirrors are finished by then.
.PARAMETER DebugLevel
	Deprecated - use the LogLevelConsole & LogLevelLogFile parameters and the level "Debug"
.PARAMETER NoLog
    Deprecated - use the LogLevelLogFile parameter and the level "Off"
.PARAMETER Silent
    Deprecated - use the LogLevelConsole parameter and the level "Off"
.PARAMETER LogLevelConsole
    Optional argument to set the level of logging for the console
    Values are Debug,Info,Warn,Error,Fatal,Off
    Default = Info
.PARAMETER LogLevelLogFile
    Optional argument to set the level of logging for logging to file
    Values are Debug,Info,Warn,Error,Fatal,Off
    Default = Debug
.PARAMETER SnapmirrorType
    Optional argument to force (if possible, less then 9.6) snapmirror relationships to be created as DP instead of XDP
    Used with ConfigureDr, UpdateDr, CloneDr, UpdateReverse, Migrate, Backup and Restore
.PARAMETER DefaultLocalUserCredentials
    Optional argument to pass the credentials for local user create/update
	In NonInteractive Mode, we cannot prompt for user password.  If you want users to be created, the password from these credentials is used.
	Can be used during ConfigureDR, Restore or CloneDR
.PARAMETER ActiveDirectoryCredentials
	Optional argument to pass the credentials for joining AD in NonInteractive Mode during ConfigureDR, Restore or CloneDR
.PARAMETER DefaultLDAPCredentials
	Optional argument to pass the credentials for binding LDAP server during ConfigureDR, Restore or CloneDR
.PARAMETER TemporarySecondaryCifsIp
    For cifs, sometimes a secondary lif is needed to join in Active Directory (duplicate ip conflict)
    This ip address will be used to create that temporary lif
    Must be used together with SecondaryCifsLifMaster
.PARAMETER SecondaryCifsLifMaster
    For cifs, sometimes a secondary lif is needed to join in Active Directory (duplicate ip conflict)
    This lif will be used as a template to create a new temporary lif to complete this AD join
    Must be used together with TemporarySecondaryCifsIp
.PARAMETER SecondaryCifsLifCustomVlan
    For cifs, sometimes a secondary lif is needed to join in Active Directory (duplicate ip conflict)
    We use the SecondaryCifsLifMaster to clone a new temp lif, however with this parameter you can override the vlan
    to which this Temp lif is bound.
    Must be used together with TemporarySecondaryCifsIp and SecondaryCifsLifMaster 
.PARAMETER ActiveDirectoryCustomOU
    When joining a DR Cifs vserver in AD, you can override the target OU with this parameter.     
.PARAMETER NonInteractive
    Runs the script in Non-Interactive Mode.  
    No confirmations and resource selection are automated
    If no smart resource selection is possible, the RootAggr and DataAggr parameters are used as a fallback
.PARAMETER WfaIntegration
    Will convert all logging to WFA Logging
    Will use WFA Cluster connection, using WFA storage credentials
    Will automatically run in NonInteractive Mode
.PARAMETER RW
	Only in Restore mode, this option will allow to create RW volume instead of default DP volume
    This cas be used when you want to restore/clone an SVM conf, but don't need to or can't restore data back through SnapMirror
.PARAMETER ForceCloneOriginal
    Only during creation of a Clone DR, this switch parameter allow to set on then Clone same identity as Production
    This is only possible if Clone and Production will run is two completely isolated IPspace or Site with network isolation
    Will automatially set Production IP address on Cloned LIF
    Will automaticaly set Production CIFS server name on Cloned CIFS server
.PARAMETER PreserveIdentity
    Used with ConfigureDR to preserve source Identity (IP addresses and CIFS server name) on destination SVM.
    In this case, all destinations LIF will be created with APIPA addresses.
    A temporary LIF will be mandatory if a CIFS server must be registered in destination SVM.
    In case of Activation, IP addresses and CIFS server from source will be replicated on destination.
    Default is PreserveIdentity = True
    If PreserveIdentity = False, then you must provide IP addresses and CIFS identity on destination SVM
.PARAMETER TieringPolicy
	Allows to force a TieringPolicy on destination volume when FabricPool is available
	If this option is present whith a valid TieringPolicy, destination volume will be created with this Policy
	It not present, we will check if a TieringPolicy is used on Primary volume and use it on destination
    And if no TieringPolicy is defined on source volume then we will use auto as default TieringPolicy for secondary volumes
.PARAMETER UseCifsDeleteMethod
    Force to use CIFS delete method, instead of modify existing CIFS server
.INPUTS
    None. You cannot pipe objects to this script
.OUTPUTS
    Only display result of operations
.LINK
    https://github.com/oliviermasson/svmtool
.EXAMPLE
    svmtool.ps1 -Instance test -Setup

    Create a new instance named test
.EXAMPLE
    svmtool.ps1 -Instance test -Vserver svm_source -ConfigureDR [-XDPPolicy <policy name>]

    Configure a SVM DR relationship for SVM svm_source in the instance test
    And create all necessary DR objects
.EXAMPLE
    svmtool.ps1 -Instance test -Vserver svm_source -ConfigureDR -AlwaysChooseDataAggr -SelectVolume

    Configure a SVM DR relationship for SVM svm_source in the instance test
    Request user to select which volume will be replicated and which not
    Ask for each volume on which destination aggregate it will be provisionned
.EXAMPLE
    svmtool.ps1 -Instance test -Vserver svm_source -ConfigureDR -RootAggr data -DataAggr data2 -PreserveIdentity $True -DefaultLocalUserCredentials $cred 
    -DefaultLDAPCredentials $cred -NonInteractive -TemporarySecondaryCifsIp 102.11.12.219 -SecondaryCifsLifMaster lif_data1

    Configure a SVM DR relationship for SVM svm_source in the instance test

    Will works Non Interactively, without prompting user, for this we provide:
    - a default password through $cred
    - a default Data Aggr and Root Aggr

    We will preserve identity on destination, so we must provide a temporary CIFS IP to register our CIFS server on destination:
    - Destination temporary IP address will be 102.11.12.219
    - We will clone the configuration of source LIF named lif_data1, to create our temporary LIF on destination
.EXAMPLE
   svmtool.ps1 -Instance test -Vserver svm_source -UpdateDR
   
   Set and Update all data and metadata for the DR SVM associated with source SVM svm_source
.EXAMPLE
    svmtool.ps1 -Instance test -Vserver svm_source -ActivateDR
    
	Activate the DR SVM associated with source SVM svm_source
	Snapshot Policy on destination volume will not beeing updated
    Access will be allowed on DR SVM
.EXAMPLE
    svmtool.ps1 -Instance test -Vserver svm_source -ResyncReverse
    
    Following an ActivateDR, create a reverse SnapMirror relationship from DR to source and erase data only on source SVM
.EXAMPLE
    svmtool.ps1 -Instance test -Vserver svm_source -UpdateReverse

    Following a ResyncReverse, push all metadata modifications achieved on DR SVM to source SVM
.EXAMPLE
    svmtool.ps1 -Instance test -Vserver svm_source -ReActivate

	Following an ActivateDR, restart production on source SVM
.EXAMPLE
	svmtools.ps1 -Instance test -Vserver source_svm -ShowDR [-Schedule] [-Lag]

	Display status and details of source SVM object and destination SVM object, as well as all SnapMirror relatiohships
	Use color to display destination volume different from source
	With option -Schedule, it also display SnapMirror schedule that is set
	With option -Lag, it also display SnapMirror Lag
.EXAMPLE
	svmtool.ps1 -Instance test -Vserver svm_source -Migrate -ForceUpdateSnapPolicy

	Following successful ConfigureDR and UpdateDR, Migrate an SVM to destination cluster
	During this step, you will be prompt to delete or not source SVM and all its objects
	If not deleted, source SVM is stopped
	Once Migration is done, destination SVM gain source identity
	Temporary IP address are replaced by source IP address and CIFS server identity is changed with source name
.EXAMPLE
	svmtool.ps1 -Instance test -Vserver svm_source -DeleteSource
	
	When Migrate is performed without deleting source SVM, you can choose (when ready)
	to delete source SVM by using -DeleteSource option
	During this step, SVM name on destination Cluster will be renamed with source name
	And all objects of source SVM, and source SVM itself will be destroyed
.EXAMPLE
	svmtool.ps1 -Backup clusterA [-Vserver <svm name>]

	Backup all SVM on clusterA.
	If Backup&Restore Instance associated to clusterA does not exist, the script will create it.
	All SVM will be backed up in separate folder inside the directory chosen for this instance
	If you want to recreate the instance for clusterA, add -Recreateconf
	If you want to only Backup a particular SVM, add -Vserver <svm name>
.EXAMPLE
	svmtool.ps1 -Restore clusterA [-Vserver <svm name>] -Destination clusterB [-RW] [-SelectBackupDate] 

	Restore all SVM available from the Backup folder defined in the clusterA Backup&Restore instance to clusterB
	If you need to restore a particular SVM, just -add -Vserver <svm name>
	By default, the script will automaticaly restore from the most recent backup folder available for each SVM
	If you want to restore from a particular date, just add -SelectBackupDate, and the script will display all dates available
	for each SVM and prompt you to chose the date you want
	By default, the script restore all volume as Data-Protection type (DP) volume. 
	In order to allow you to restore data inside this volumes from a SnapMirror/SnapVault previous backup.
	If you don't have a SnapMirror/SnapVault backup or will restore data back with another method,
	or because you only need to recreate the "envelop" fo the SVM (to clone an environment by example), just add -RW to the command line
	In that case, all volumes will be restored as Read/Write (RW) volume.
.EXAMPLE
	svmtool.ps1 -Instance <instance name> -Vserver <vserver source name> -CloneDR [-DataAggr <default data aggregate name>] [-RootAggr] [-DefaultPass] [-ForceCloneOriginal]

	Create a temporary Clone Vserver on destination cluster
	Clone all destinations volumes (DP) into this cloned vserver as Read/Write volume (RW)
	In order, to perform/test the DR without interrupting Snapmirror relationship during the timeframe of the DR test
	It could also be used to provision an cloned environment of production SVM on destination cluster for test/dev
	Once cloned environment successfully done, all volumes are Flexclone volumes attached to destinations volumes through lastest snapshot available
	If needed, this cloned environment and all its volumes could be split from destination vserver : see SplitCloneDR option
	With the optional arugment -SelectVolume, you could choose which volume will be cloned in the temporay Cloned SVM
.EXAMPLE
	svmtool.ps1 -Instance <instance name> -Vserver <vserver source name> -DeleteCloneDR -CloneName PSLAB_DR_clone.2

	Completely delete Vserver Clone named PSLAB_DR_clone.2 from secondary cluster
.EXAMPLE
	To enable encryption on destination volume you need:
	
		. Upgrade PowerShell ToolKit (PSTK) to version 4.7 minimum (NaToolkitVersion 4.5 minimum)
		. Destination Cluster must run at least ONTAP 9.1
		. Destination Cluster must run at least ONTAP 9.3 if you want to convert existing destination volumes into encrypted volumes
		. You must modify your instance configuration by running
			.\svmtool.ps1 -Setup <Instance Name> -Vserver <SVM Name>
			or
			New-SvmDrConfiguration -Instance <Instance Name> -Vserver <SVM Name>

			And answer yes to the question to enable encryption
		. Once instance modified, all new volumes will be automatically encyrpted on destination
		. If you already have unencrypted volumes on destination, you can choose to encrypt them by running:
			.\svmtool.ps1 -Instance <Instance Name> -Vserver <SVM Name> -ConfiguredDR
			or
			New-SvmDr -Instance <Instance Name> -Vserver <SVM Name>

            You will then be prompted to choose to encrypt volume by volume, all volumes or no volume
.EXAMPLE
    svmtool.ps1 -Instance <instance name> -Vserver <vserver source name> [-ConfigureDR|-UpdateDR] -XDPPolicy <policy name>
    
    You can change existing Policy of all snapmirror relationships by running ConfigureDR or UpdateDR with XDPpolicy argument
    The chosen policy must already exist on destination Cluster.
    If not, switch to default Policy : DPDefault or MirrorAllSnapshot, depending on ONTAP version on both source and destination
.EXAMPLE
	New-SvmDr -Instance <instance name> -Vserver <vserver name> -NonInteractive -PreserveIdentity $true -DataAggr <aggr name> -RootAggr <aggr name>
	-DefaultLocalUserCredentials $cred -DefaultLDAPCredentials $cred -TemporarySecondaryCifsIp <IP> -SecondaryCifsLifMaster <lif name> -TieringPolicy snapshot-only
	
	With all this options, you will create a DR SVM with Network Identity perserved on DR and one Temporary Secondary LIF to allow AD registration
	All created user will get their password from the $cred argument
	This $cred argument must be initialized before running this command, with the following cmdlet:
	$cred=get-credential
	All secondary volume will be created with a snapshot-only TieringPolicy
    All this will be performed non-interactively
.EXAMPLE
    Restore a specific Object configuration from JSON files to one destination SVM
    You must specify the SourceCluster & SourceSVM from which object will be restored
    You should specify DestinationCluster & DestinationSVM to which object will be retored, by default it will restore into SourceCluster and SourceSVM
    
    .\svmtool.ps1 -RestoreObject <Source Cluster name> -Vserver <source SVM name> [-DestinationCluster <Dest Cluster name>] [-DestinationSVM <dest SVM name>] -Object <Exports|Lifs|Quotas|CifsServer|Shares|Symlinks|Users|Volumes> [-SelectBackupDate] [-RW]

    You can choose to restore several type of objects, like :
        . Exports    : NFS exports
        . Lifs       : Network Data LIF
        . Quotas     : Quotas
        . CifsServer : CIFS server only
        . Shares     : CIFS shares
        . Symlinks   : CIFS Symlinks
        . Users      : CIFS users
        . Volumes    : Data Volume


.NOTES
    Author  : Olivier Masson
    Author  : Mirko Van Colen
    Version : October 5th, 2020
    Version History : 
        - 0.0.3 : 	Initial version 
        - 0.0.4 : 	Bugfix, typos and added ParameterSets
		- 0.0.5 : 	Bugfixes, advancements and colorcoding
		- 0.0.6 : 	Change behaviour when SVM has no LIF, nor Data volume
		- 0.0.7 : 	Add ForceUpdateSnapPolicy to not update snapshot policy on destination volumes by default
				  	Add EXAMPLE for ShowDR, DeleteSource, Migrate, ...
    	- 0.0.8 : 	Add CloneDR option to create Cloned SVM from Destination Vserver
					Add DeleteCloneDR option to remove a previously Cloned Vserver          
    	- 0.0.9 : 	Added symlinks and noninteractive mode
              		Bugfixes (cifs groups & users)
              		Added default usercredentials for noninteractive mode
              		Added smart resource selections (with regex and defaults) for noninteractive mode
              		Minor typos
              		Remove Restamp_msid option
				    Add ForceRestart optional parameter to forcibly restart a stopped Vserver during ReActivate step
    	- 0.1.0 : 	Adding log4net logging and WFA logging integration, setup can now run in noninteractive mode
		- 0.1.1 : 	Bugfixes, added new cmdlet wrapper with official verbs
		- 0.1.2 :	Bugfixes, Add FabricPool support on destination
		- 0.1.3 : 	Fix create CIFS share during Restore
					Fix create SYMLINK
					Fix restore Quota
		- 0.1.4 :	Simplify and improve ActivateDR and ReActivate behaviour
					Improve Restore behaviour when restoring Vserver to its original place (Cluster/Vserver)
		- 0.1.5 :	Fix ActivateDR and ReActivate to keep CIFS shares on the active SVM
		- 0.1.6 :   Fix restart services during ReActivate
		- 0.1.7 : 	Add support for Volume Encryption on Destination
		- 0.1.8 :	Change version display and align to Github release number
		- 0.1.9 :   Correct import_instance_svmdr to generate lif and cifs into json files
		- 0.2.0 :	Modify updateDR behavior.  Omit diff check for lifs & routes
        - 0.2.1 :	Added NoSnapmirrorUpdate and NoSnapmirrorWait flags for updateDR (mirko)
                    Added MirrorSchedule & XDPPolicy for UpdateDR & ConfigureDR (default remains hourly schedule)
                    Use "none" to omit the schedule
        - 0.2.2 :   Fix change of XDPPolicy during ConfigureDR or UpdateDR
        - 0.2.3 :   Add Cifs join options : override AD OU + override temp-cifs-join-lif VLAN
        - 0.2.4 :   Fix check if CIFS server is running
        - 0.2.5 :   Fix gateway creation
                    Add support for Data replication with Sync and StrictSync Policy
                    Automatic conversion of Async to Sync relationships and vice versa
                    Introduce RestoreObject to allow restores only part of SVM configuration: LIFs, Volumes, Exports, Shares, Quotas, Users (still is progress)
        - 0.2.6 :   Add option to skip anti virus check completely, bugfixes (acl encoding, export policy, ...) 
        - 0.2.7 :   Fix wait_snapmirror_dr
        - 0.2.8 :   Fix import-module svmtool
        - 0.2.9 :   Add snapmirror type option
        - 0.3.0 :   Modify NonInteractive mode for ConfigureDR and for CloneDR with ForceOriginalClone
        - 0.3.1 :   Add PreserveIdentity Mode
        - 0.3.2 :   Correct Firewall Policy sync during UpdateDR
		- 0.3.3 :   Change some behaviour around NonInteractive mode.
					Fix Update_Cifs_usergroup function
		- 0.3.4 :   Add TieringPolicy option to force Tiering Policy for FabricPool's created volume on destination
					without this option, TieringPolicy of source volumes is used on destination.
					And if there is no TieringPolicy on source volumes, then TieringPolicy auto is used on destination
        - 0.3.5 :   Fix UpdateDR when CIFS server does not already exists on DR
        - 0.3.6 :   Change behaviour with settings CIFS parameters when distant AD is not available
                    Change behaviour with settings CIFS parameters with requested AD credential
                    Add CredName to Show-SvmdrConfiguration/ListInstance in RestPassword mode, to allows reset password only for this credential
                    Add argument ActiveDirectoryCredential to UpdateDR
                    Change behaviour when ActiveDirectoryCredential is used. Now, this credential will be used instead of the one previously saved by svmtool
                    Fix subfolder for Backup and Restore. When you choose a backup folder, svmtool automaticaly add a subfolder with the name of the cluster backed up
                    Add Remove-SvmdrInstance wrapper for RemoveInstance operation
                    Change output display during MirrorSchedule/Set-SvmDrSchedule
                    Fix management of Temporary Secondary CIFS Lif
        - 0.3.7 :   Fix Restore job creation
                    Add Restore-ObjectSvmDr wrapper for RestoreObject operation
        - 0.4.0 :   Add Flexgroup support (due to flexgroup limitation, if you SVM contains flexgroup you will not be able to use Double DR and Synchronous replication)
                    Fix Temporary LIF management
                    Fix NFS only replication
                    Fix onAccessPolicy management
                    Change test source alive with only SSh and HTTPS (no more ping)
        - 0.4.1 :   Change default Log level for logfile to Debug
                    Update user guide
        - 0.4.2 :   Fix Restore-SvmDr
        - 0.4.3 :   Fix QOS policy group
        - 0.4.4 :   Fix behavior with additional snapmirror relationship outdide smvtool context
        - 0.5.0 :   Compatible with PSTK Core under Windows, Linux and Macos
                    Allow to migrate SVM inside one Metrocluster (between the two Clusters that compose this Metrocluster)
                    Improve Cron replication with Powershell >=7
        - 0.5.1     Use Netmask of the Primary Vserver LIF Master instead of Secondary one to create the Secondary Temporary Lif
        - 0.5.2     Correct AV scan replication with filters and mandatory scan
                    Restore possibility during a Migrate to choose delete or not the source SVM. Not possible in the case of migration inside the same MCC, where source SVM must be delete during Migration
                    Rename flexgroup with _dst suffix once migration done
                    Correct ReActivate with SM-S
                    Correct how to test if SVM source is alive to be compatible with and without Powershell Core
        - 0.5.3     Detect when service-policy should be used instead of firewall-policy if ONTAP 9.6 or greater
        - 0.6.0     Complete rewrite of migrate, activateDR and ReActivate

#>
[CmdletBinding(HelpURI = "https://github.com/oliviermasson/svmtool", DefaultParameterSetName = "ListInstance")]
Param (

    [Parameter(Mandatory = $true, ParameterSetName = 'Setup')]
    [switch]$Setup,

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [string]$PrimaryCluster,

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [string]$SecondaryCluster,

    [Parameter(Mandatory = $true, ParameterSetName = 'ConfigureDR')]
    [switch]$ConfigureDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'UpdateDR')]
    [switch]$UpdateDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'ShowDR')]
    [switch]$ShowDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'ActivateDR')]
    [switch]$ActivateDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'CloneDR')]
    [switch]$CloneDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'SplitCloneDR')]
    [switch]$SplitCloneDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteCloneDR')]
    [switch]$DeleteCloneDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteDR')]
    [switch]$DeleteDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'RemoveDRConf')]
    [switch]$RemoveDRConf,

    [Parameter(Mandatory = $true, ParameterSetName = 'ResyncReverse')]
    [switch]$ResyncReverse,

    [Parameter(Mandatory = $true, ParameterSetName = 'UpdateReverse')]
    [switch]$UpdateReverse,

    [Parameter(Mandatory = $true, ParameterSetName = 'ReActivate')]
    [switch]$ReActivate,

    [Parameter(Mandatory = $true, ParameterSetName = 'CleanReverse')]
    [switch]$CleanReverse,

    [Parameter(Mandatory = $true, ParameterSetName = 'Resync')]
    [switch]$Resync,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
    [switch]$Version,

    [Parameter(Mandatory = $true, ParameterSetName = 'ListInstance')]
    [switch]$ListInstance,

    [Parameter(Mandatory = $true, ParameterSetName = 'ImportInstance')]
    [switch]$ImportInstance,

    [Parameter(Mandatory = $true, ParameterSetName = 'RemoveInstance')]
    [string]$RemoveInstance,

    [Parameter(Mandatory = $true, ParameterSetName = 'Backup')]
    [string]$Backup,

    [Parameter(Mandatory = $true, ParameterSetName = 'Restore')]
    [string]$Restore,

    [Parameter(Mandatory = $true, ParameterSetName = 'RestoreObject')]
    [string]$RestoreObject,

    [Parameter(Mandatory = $true, ParameterSetName = 'MirrorSchedule')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]  
    [string]$MirrorSchedule = "",

    [Parameter(Mandatory = $true, ParameterSetName = 'MirrorScheduleReverse')]
    [string]$MirrorScheduleReverse,

    [Parameter(Mandatory = $true, ParameterSetName = 'Migrate')]
    [switch]$Migrate,

    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteSource')]
    [switch]$DeleteSource,

    [Parameter(Mandatory = $true, ParameterSetName = 'CreateQuotaDR')]
    [switch]$CreateQuotaDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'ReCreateQuota')]
    [switch]$ReCreateQuota,

    [Parameter(Mandatory = $true, ParameterSetName = 'Help')]
    [switch]$Help,

    [Parameter(Mandatory = $true, ParameterSetName = 'InternalTest')]
    [switch]$InternalTest,

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ShowDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ActivateDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'SplitCloneDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteCloneDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'RemoveDRConf')]
    [Parameter(Mandatory = $true, ParameterSetName = 'MirrorSchedule')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $true, ParameterSetName = 'UpdateReverse')]
    [Parameter(Mandatory = $true, ParameterSetName = 'MirrorScheduleReverse')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $true, ParameterSetName = 'CleanReverse')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Resync')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Backup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $true, ParameterSetName = 'RestoreObject')]
    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteSource')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $true, ParameterSetName = 'CreateQuotaDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ReCreateQuota')]
    [Parameter(Mandatory = $true, ParameterSetName = 'InternalTest')]
    [string]$Vserver,

    [Parameter(Mandatory = $true, ParameterSetName = 'RestoreObject')]
    [ValidateSet("Lifs", "Volumes", "Exports", "CifsServer", "NetBios", "Shares", "Symlinks", "Quotas","Users")]
    [string[]]$Objects=@(""),

    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [string]$DestinationCluster,

    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [string]$DestinationSVM,

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [string]$VserverDr,

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [switch]$QuotaDR,

    [Parameter(Mandatory = $true, ParameterSetName = 'Setup')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ShowDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ActivateDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'SplitCloneDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteCloneDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteDR')]
    [Parameter(Mandatory = $true, ParameterSetName = 'RemoveDRConf')]
    [Parameter(Mandatory = $true, ParameterSetName = 'MirrorSchedule')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $true, ParameterSetName = 'UpdateReverse')]
    [Parameter(Mandatory = $true, ParameterSetName = 'MirrorScheduleReverse')]
    [Parameter(Mandatory = $true, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $true, ParameterSetName = 'CleanReverse')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Resync')]
    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteSource')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CreateQuotaDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReCreateQuota')]
    [Parameter(Mandatory = $false, ParameterSetName = 'InternalTest')]
    [string]$Instance,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [ValidateSet("DP", "XDP")]
    [string]$SnapmirrorType="XDP",

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [string]$RootAggr = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [switch]$AlwaysChooseDataAggr,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [switch]$SelectVolume,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [switch]$DRfromDR,

    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [switch]$ForceCloneOriginal,

    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [switch]$ForceRestoreOriginal,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')] 
    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')] 
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]  
    [Parameter(Mandatory = $false, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Resync')]
    [string]$XDPPolicy = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]  
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]  
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [string]$DataAggr = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [switch]$LastSnapshot,

    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]	
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]    
    [switch]$NoSnapmirrorUpdate,

    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]	
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [switch]$NoSnapmirrorWait,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]  
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')] 
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [string]$AggrMatchRegex,    

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]   
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')] 
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [string]$NodeMatchRegex,    

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [switch]$CorrectQuotaError,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [switch]$IgnoreQtreeExportPolicy,
	  
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [switch]$IgnoreQuotaOff,
	   
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [switch]$ForceDeleteQuota,

    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [switch]$SkipVscanFpolicy,    

    [Parameter(Mandatory = $false, ParameterSetName = 'CleanReverse')]
    [switch]$ForceClean,

    [Parameter(Mandatory = $false, ParameterSetName = 'Resync')]
    [switch]$ForceResync,

    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [switch]$ForceRestart,

    [Parameter(Mandatory = $false, ParameterSetName = 'ShowDR')]
    [switch]$Lag,

    [Parameter(Mandatory = $false, ParameterSetName = 'ShowDR')]
    [switch]$Schedule,

    [Parameter(Mandatory = $false, ParameterSetName = 'ShowDR')]
    [switch]$NoVolumeDetail,

    [Parameter(Mandatory = $false, ParameterSetName = 'ListInstance')]
    [switch]$ResetPassword,

    [Parameter(Mandatory = $false, ParameterSetName = 'ListInstance')]
    [string]$CredName=$null,

    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Resync')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [switch]$ForceRecreate,

    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ActivateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [switch]$ForceUpdateSnapPolicy,

    [Parameter(Mandatory = $false, ParameterSetName = 'Backup')]
    [switch]$Recreateconf,

    [Parameter(Mandatory = $true, ParameterSetName = 'DeleteCloneDR')]
    [string]$CloneName = "",

    [Parameter(Mandatory = $true, ParameterSetName = 'Restore')]
    [string]$Destination = "",

    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [switch]$SelectBackupDate,

    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [switch]$RW,

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ShowDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ActivateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorSchedule')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorScheduleReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CleanReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Resync')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Backup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteSource')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CreateQuotaDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReCreateQuota')]
    [Parameter(Mandatory = $false, ParameterSetName = 'InternalTest')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'SplitCloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteCloneDR')]
    [switch]$HTTP,

    [switch]$NoLog,
    [switch]$Silent,

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListInstance')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ShowDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ActivateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveDRConf')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorSchedule')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorScheduleReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CleanReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Resync')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteSource')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CreateQuotaDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReCreateQuota')]
    [Parameter(Mandatory = $false, ParameterSetName = 'InternalTest')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Backup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ImportInstance')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'SplitCloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteCloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveInstance')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Version')]
    [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
    [string]$LogLevelConsole = "Info",

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ListInstance')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ShowDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ActivateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveDRConf')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorSchedule')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorScheduleReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CleanReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Resync')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteSource')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CreateQuotaDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReCreateQuota')]
    [Parameter(Mandatory = $false, ParameterSetName = 'InternalTest')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Backup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ImportInstance')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'SplitCloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteCloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveInstance')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Version')]
    [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
    [string]$LogLevelLogFile = "Debug",

    [Parameter(Mandatory = $false, ParameterSetName = 'Version')]
    [switch]$PSTKalpha,

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ShowDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ActivateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'SplitCloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteCloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveDRConf')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorSchedule')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorScheduleReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CleanReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Resync')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteSource')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CreateQuotaDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReCreateQuota')]
    [Parameter(Mandatory = $false, ParameterSetName = 'InternalTest')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Backup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [Int32]$Timeout = 60,  #Timeout in seconds for dialog with controller

    [Parameter(Mandatory = $false, ParameterSetName = 'Setup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ActivateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorSchedule')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ResyncReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'MirrorScheduleReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CleanReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Resync')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Backup')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteSource')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CreateQuotaDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReCreateQuota')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]	
    [Parameter(Mandatory = $false, ParameterSetName = 'SplitCloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DeleteCloneDR')]	
    [switch]$NonInteractive,
    
    [Parameter(Mandatory = $False, ParameterSetName = 'ConfigureDR')]
    #[Parameter(Mandatory = $False, ParameterSetName = 'Migrate')]  With Migrate PreserveIdentity is not an option, it is mandatory
    [bool]$PreserveIdentity=$True,
    
    #By default ReActivate & ActivateDR will try not to delete existing CIFS server, but instead, modify them
    #If you want to use the method which consist to first delete existing CIFS server, pass the switch parameter UseCifsDeleteMethod 
    [Parameter(Mandatory = $False, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $False, ParameterSetName = 'ActivateDR')]
    #[Parameter(Mandatory = $False, ParameterSetName = 'Migrate')] With Migrate NoCifsDeleteMethod is no more an option, it is decided by svmtool depending on the scenario (migration inside a Metrocluster or not)
    [switch]$UseCifsDeleteMethod,

    [switch]$WfaIntegration,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateReverse')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ReActivate')]
    [Parameter(Mandatory = $false, ParameterSetName = 'RestoreObject')]
    [pscredential]$DefaultLocalUserCredentials = $null,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')] 
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')] 
    [pscredential]$ActiveDirectoryCredentials = $null,
	
    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')] 
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]   
    [pscredential]$DefaultLDAPCredentials = $null,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]  
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]   
    [string]$TemporarySecondaryCifsIp = $null,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Restore')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')] 
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]    
    [string]$SecondaryCifsLifMaster = $null,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')] 
    [Parameter(Mandatory = $false, ParameterSetName = 'Migrate')]
    [string]$SecondaryCifsLifCustomVlan = $null,

    [Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'CloneDR')]
    [string]$ActiveDirectoryCustomOU = $null,
	
	[Parameter(Mandatory = $false, ParameterSetName = 'ConfigureDR')]
    [Parameter(Mandatory = $false, ParameterSetName = 'UpdateDR')]
	[ValidateSet("auto", "snapshot-only", "all", "none", $null)]
    [string]$TieringPolicy = $null
)

#############################################################################################
# Minimum Netapp Supported PSTK
#############################################################################################
$Global:MIN_MAJOR = 4
$Global:MIN_MINOR = 5
$Global:MIN_BUILD = 0
$Global:MIN_REVISION = 0
#############################################################################################
$Global:RELEASE = "0.6.0"
$Global:SCRIPT_RELEASE = "0.1.30"
if($PSVersionTable.PSVersion.Major -lt 7){
    $Global:BASEDIR = 'C:\Scripts\SVMTOOL'      
}
elseif($PSVersionTable.PSVersion.Major -ge 7 -and $IsWindows){
    $Global:BASEDIR = 'C:\Scripts\SVMTOOL'  
}else{
    # In Linux/MacOS svmtool will create all its files inside home directory of user running the script
    $UserHome=$Home
    $Global:BASEDIR = $UserHome + '/SVMTOOL'
}

$Global:SVMTOOL_DB_DEFAULT = $Global:BASEDIR
if($PSVersionTable.PSVersion.Major -lt 7){
    $Global:CONFBASEDIR = $BASEDIR + '\etc\'
}elseif($PSVersionTable.PSVersion.Major -ge 7 -and $IsWindows){
    $Global:CONFBASEDIR = $BASEDIR + '\etc\'
}else{
    $Global:CONFBASEDIR = $BASEDIR + '/etc/'
}
$Global:STOP_TIMEOUT = 360
$Global:START_TIMEOUT = 360
$Global:SINGLE_CLUSTER = $False
$Global:SILENT_PERIOD = 3 				# SILENT_PERIOD in seconds after which we will test again if Primary site is alive
$Global:RESTORE_ORIGINAL = $False
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$ErrorActionPreference = "Continue"
if ($WfaIntegration -or $UpdateDR -or $UpdateReverse) {
    $NonInteractive = $true
}
$Global:RootAggr = $RootAggr
$Global:DataAggr = $DataAggr
$Global:NonInteractive = $NonInteractive
if ($NonInteractive) {
    $AlwaysChooseDataAggr = $true
}
$Global:LogLevelConsole = $LogLevelConsole
$Global:LogLevelLogFile = $LogLevelLogFile
$Global:AlwaysChooseDataAggr = $AlwaysChooseDataAggr
$Global:WfaIntegration = $WfaIntegration
$Global:SkipVscanFpolicy = $SkipVscanFpolicy
$Global:DefaultLocalUserCredentials = $DefaultLocalUserCredentials
$Global:ActiveDirectoryCredentials = $ActiveDirectoryCredentials
$Global:DefaultLDAPCredentials = $DefaultLDAPCredentials
$Global:ForceClean = $ForceClean
$Global:SkipVscanFpolicy = $SkipVscanFpolicy
$Global:ForceCloneOriginal = $ForceCloneOriginal
$Global:ForceRestoreOriginal = $ForceRestoreOriginal
$Global:BACKUPALLSVM = $False
$Global:PreserveIdentity=$PreserveIdentity
$Global:TieringPolicy=$TieringPolicy
$Global:Timeout=$Timeout
if($DeleteSource.IsPresent){
    $Global:DeleteSource=$true
}else{
    $Global:DeleteSource=$False
}
# Force to use CIFS modify method, instead of delete/recreate when CIFS server name need to be changed
$Global:UseCifsDeleteMethod=$UseCifsDeleteMethod
if($PSVersionTable.PSVersion.Major -lt 7){
    $Global:NumberOfLogicalProcessor = (Get-CimInstance  Win32_Processor).NumberOfLogicalProcessors
}
elseif($PSVersionTable.PSVersion.Major -ge 7 -and $IsWindows){
    $Global:NumberOfLogicalProcessor = (Get-CimInstance  Win32_Processor).NumberOfLogicalProcessors
}else{
    $Global:NumberOfLogicalProcessor = (get-content /proc/cpuinfo | sls "processor" | Measure-Object).count   
}
if ($Global:NumberOfLogicalProcessor -lt 4) {
    $Global:NumberOfLogicalProcessor = 4
}
#$Global:maxJobs = 100
$Global:XDPPolicy = $XDPPolicy
$Global:MirrorSchedule = $MirrorSchedule
$Global:DefaultPass = $DefaultPass
$Global:Schedule = $Schedule
$Global:SnapmirrorType = $SnapmirrorType

if ( ( $null -eq $Instance ) -or ( $Instance -eq "" ) ) {
    if ($Backup.Length -eq 0 -and $Restore.Length -eq 0 -and $RestoreObject.Length -eq 0) {
        if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:CONFDIR = $Global:CONFBASEDIR + 'default\'}else{$Global:CONFDIR = $Global:CONFBASEDIR + 'default'}
    }
    elseif ($Backup.Length -gt 0) {
        if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:CONFDIR = $Global:CONFBASEDIR + $Backup + '\'}else{$Global:CONFDIR = $Global:CONFBASEDIR + $Backup + '/'}
    }
    elseif ($Restore.Length -gt 0) {
        if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:CONFDIR = $Global:CONFBASEDIR + $Restore + '\'}else{$Global:CONFDIR = $Global:CONFBASEDIR + $Restore + '/'}
    }
    elseif ($RestoreObject.Length -gt 0) {
        if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:CONFDIR = $Global:CONFBASEDIR + $RestoreObject + '\'}else{$Global:CONFDIR = $Global:CONFBASEDIR + $RestoreObject + '/'}
    }
}
else {
    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:CONFDIR = $Global:CONFBASEDIR + $Instance + '\'}else{$Global:CONFDIR = $Global:CONFBASEDIR + $Instance + '/'}
}

$Global:CONFFILE = $Global:CONFDIR + 'svmtool.conf'

if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:ROOTLOGDIR = ($Global:BASEDIR + '\log\')}else{$Global:ROOTLOGDIR = ($Global:BASEDIR + '/log/')}

if ($Backup -ne "") {
    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:ROOTLOGDIR = ($Global:ROOTLOGDIR + $Backup + '\')}else{$Global:ROOTLOGDIR = ($Global:ROOTLOGDIR + $Backup + '/')}
    if (-not (Test-Path $Global:ROOTLOGDIR)) {
        New-Item -Path $Global:ROOTLOGDIR -ItemType "directory" -ErrorAction "silentlycontinue" | Out-Null
    }		
}

if ($Restore -ne "") {
    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:ROOTLOGDIR = ($Global:ROOTLOGDIR + $Restore + '\')}else{$Global:ROOTLOGDIR = ($Global:ROOTLOGDIR + $Restore + '/')}
    if (-not (Test-Path $Global:ROOTLOGDIR)) {
        New-Item -Path $Global:ROOTLOGDIR -ItemType "directory" -ErrorAction "silentlycontinue" | Out-Null
    }
}

if ($RestoreObject -ne "") {
    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:ROOTLOGDIR = ($Global:ROOTLOGDIR + $RestoreObject + '\')}else{$Global:ROOTLOGDIR = ($Global:ROOTLOGDIR + $RestoreObject + '/')}
    if (-not (Test-Path $Global:ROOTLOGDIR)) {
        New-Item -Path $Global:ROOTLOGDIR -ItemType "directory" -ErrorAction "silentlycontinue" | Out-Null
    }
}

if ($Vserver -ne "" -and ($Backup -eq "" -and $Restore -eq "" -and $RestoreObject -eq "")) {
    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:LOGDIR = ($Global:ROOTLOGDIR + $Vserver + '\')}else{$Global:LOGDIR = ($Global:ROOTLOGDIR + $Vserver + '/')}
}
else {
    $Global:LOGDIR = $Global:ROOTLOGDIR
}

$LOGFILE = $LOGDIR + "svmtool.log"
if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Global:CRED_CONFDIR = $BASEDIR + "\cred\"}else{$Global:CRED_CONFDIR = $BASEDIR + "/cred/"}
$Global:MOUNT_RETRY_COUNT = 100
$Global:TemporarySecondaryCifsIp=$TemporarySecondaryCifsIp
$Global:NFSonly=$False

#############################################################################################
# MAIN
#############################################################################################
if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Path = $env:PSModulePath.split(";")}else{$Path = $env:PSModulePath.split(":")}
if ($Path -notcontains $PSScriptRoot) {
    $Path += $PSScriptRoot
    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Path = [string]::Join(";", $Path)}else{$Path = [string]::Join(":", $Path)}
    [System.Environment]::SetEnvironmentVariable('PSModulePath', $Path)
}
Remove-Module -Name svmtools -ErrorAction SilentlyContinue
if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$module = Import-Module "$PSScriptRoot\svmtools" -PassThru}else{$module = Import-Module "$PSScriptRoot/svmtools" -PassThru}
if ( $module -eq $null ) {
    Write-Host "ERROR: Failed to load module SVMTOOLS" -ForegroundColor Red
    Write-Error "ERROR: Failed to load module SVMTOOLS"
    exit 1
}

# initialize log4net, only needed once.
init_log4net

# appenders (logfile, eventviewer & console)
$masterLogFileAppender = create_rolling_log_appender -name "svmtool.log" -file $LOGFILE -threshold $LogLevelLogFile
if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$masterEventViewerAppender = create_eventviewer_appender -name "eventviewer" -applicationname "svmtool"}
$consoleAppender = create_console_appender -name "console" -threshold $LogLevelConsole

# initialize logonly
add_appender -loggerinstance "logonly" $masterLogFileAppender
set_log_level -loggerinstance "logonly" -level "All"
$Global:MasterLog = get_logger -name "logonly" 

# initialize console
add_appender -loggerinstance "console" $masterLogFileAppender
if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){add_appender -loggerinstance "console" $masterEventViewerAppender}
add_appender -loggerinstance "console" $consoleAppender 
set_log_level -loggerinstance "console" -level "All"
$Global:ConsoleLog = get_logger -name "console"


$PSVersion=$PSVersionTable.PSVersion
if($PSVersionTable.PSVersion.Major -le 5){
    Write-LogDebug "Running svmtool with Powershell version [$PSVersion]"
    Write-LogDebug "Import classical PSTK"
    if (!($env:PSModulePath -match "NetApp PowerShell Toolkit")) {
        $env:PSModulePath = $($env:PSModulePath + ";C:\Program Files (x86)\NetApp\NetApp PowerShell Toolkit\Modules")
    }
    if (-not $WfaIntegration) {
        $module = Get-Module DataONTAP
        if ($module -eq $null) {
            $module = Import-Module -Name DataONTAP -PassThru
            $module = Get-Module DataONTAP
            if ( $module -eq $null ) {
                Write-Error "ERROR: DataONTAP module not found" 
                clean_and_exit 1
            }
        }
        else {
            # dataontap was loaded externally
            Write-LogDebug "DataONTAP module already loaded"
        }
    }
    else {
        $module = Import-Module "$PSScriptRoot\..\DataOntap" -PassThru
        $module = Get-Module DataONTAP
        if ( $module -eq $null ) {
            Write-Error "ERROR: DataONTAP Core module not found" 
            clean_and_exit 1
        }
    }
}else{
    Write-LogDebug "Running svmtool with PWSH Core version [$PSVersion]"
    Write-LogDebug "Import PSTK Core version"
    $module = Get-Module NetApp.ONTAP
    if ($module -eq $null) {
        if($PSTKalpha.IsPresent){
            Write-Log "Import PSTK Core Alpha"
            $module = Import-Module 'C:\Users\masson\Downloads\PSTK REST ALPHA\NetApp.ONTAP\NetApp.ONTAP\NetApp.ONTAP.psd1'
        }else{
            #Write-Log "Import PSTK Core Standard"
            $module = Import-Module NetApp.ONTAP
            # workaround for BURT 1385162
            $DataONTAP_SkipEmsReport = $null
            $DataONTAP_SkipUsageReport = $true
        }
    }
    <# if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
        #$module = Import-Module "C:\Users\masson\Downloads\PSTK 9.8 CORE\NetApp.ONTAP\NetApp.ONTAP.psd1"
        
    }else{

    } #>
    $module = Get-Module NetApp.ONTAP
    if ( $module -eq $null ) {
        Write-Error "ERROR: NetApp.ONTAP Core module not found" 
        clean_and_exit 1
    }
}

$PSTKVersion = Get-NaToolkitVersion
<# if ($PSTKVersion.Major -lt $Global:MIN_MAJOR -and $PSTKVersion.Minor -lt $Global:MIN_MINOR -and $PSTKVersion.Minor -lt $Global:MIN_BUILD) {
    Write-LogWarn "Your PSTK version is lower than mandatory version (ToolkitVersion 4.5.0 / PSTK 4.7)"
    Write-LogWarn "You will not be able to manage volume encryption and other options may not work properly"
    $Global:PSTKEncryptionPossible = $False
}
else {
    $Global:PSTKEncryptionPossible = $True
} #>

#check_ToolkitVersion 

if ($LastSnapshot) {
    Write-Warn "The switch -LastSnapshot is deprecated, Cdot always transfers last snapshot"
}
if ($Silent) {
    Write-Warn "The switch -Silent is deprecated, please use parameter -LogLevelConsole"
    $LogLevelConsole = "Off"
}
if ($NoLog) {
    Write-Warn "The switch -NoLog is deprecated, please use parameter -LogLevelLogFile"
    $LogLevelLogFile = "Off"
}

if ($DebugLevel) {
    Write-Warn "The switch -DebugLevel is deprecated, please use parameters -LogLevelLogFile Debug or -LogLevelConsole Debug"
    $LogLevelLogFile = "Debug"
}

if ( ( check_init_setup_dir ) -eq $False ) {
    Write-LogError "ERROR: Failed to create new folder item: exit" 
    clean_and_exit 1
}

Write-LogOnly " "
Write-LogOnly " "
Write-LogOnly "**************************************************************************************************************************************************************"
Write-LogOnly "SVMTOOL START $($Global:RELEASE)"
if ( $Help ) {
    Write-Help 
}
####################################################################################################

if ( $Version ) {
    $ModulesVersion = (Get-Module -Name svmtools).Version
    $ModulesVersion = $ModulesVersion.ToString()
    $ModuleVersion = (Get-Module -Name svmtool).Version
    if ($ModuleVersion -eq $null) {
        $path = (Get-Variable -Name PSCommandPath).Value
        $path = Split-Path $path
        $module = Import-Module $($path+"\svmtool") -PassThru
        if ($module -ne $null) {
            $ModuleVersion = (Get-Module -Name svmtool).Version
            $ModuleVersion = $ModuleVersion.ToString()
        }
    }
    else {
        $ModuleVersion = $ModuleVersion.ToString()	
    }
    Write-Log "[svmtool] Release [$RELEASE]"
    Write-Log "[Script] Version [$SCRIPT_RELEASE]"
    if ($ModuleVersion -ne $null) {
        Write-Log "[Module svmtool] Version [$ModuleVersion]"
    }
    Write-Log "[Module svmtools] Version [$ModulesVersion]"
    Clean_and_exit 0 
}

Write-LogDebug "BASEDIR           [$BASEDIR]"
Write-LogDebug "CONFDIR           [$Global:CONFDIR]"
Write-LogDebug "LOGDIR            [$LOGDIR]"
Write-LogDebug "LOGFILE           [$LOGFILE]"
Write-LogDebug "CRED_CONFDIR      [$CRED_CONFDIR]"
Write-LogDebug "CONFFILE          [$Global:CONFFILE]"
Write-LogDebug "VERSION           [$RELEASE]"
Write-LogDebug "Vserver           [$Vserver]"
Write-LogDebug "LogLevelConsole   [$LogLevelConsole]"
Write-LogDebug "LogLevelLogFile   [$LogLevelLogFile]"
Write-LogDebug "RW                [$RW]"
Write-LogDebug "PSVersionTable    [$PSVersion]"
####################################################################################################

if ( $ListInstance ) {
    show_instance_list -ResetPassword:$ResetPassword -CredName $CredName
    clean_and_exit 0
}
####################################################################################################

if ($ImportInstance) {
    if (($ret = import_instance_svmdr) -eq $True) {
        clean_and_exit 0
    }
    else {
        clean_and_exit 1	
    }
}
####################################################################################################

if ( $RemoveInstance ) {
    if ( ( remove_configuration_instance $RemoveInstance ) -eq $True ) {
        clean_and_exit 0
    }
    else {
        clean_and_exit 1
    }
}
####################################################################################################

if ( $Setup ) {
    if ($Global:NonInteractive) {
        if (-not $PrimaryCluster -or -not $SecondaryCluster) {
            Write-LogError "ERROR : Setup in non interactive requires options PrimaryCluster, SecondaryCluster and optionally Vserver"
        }
    }
    create_config_file_cli -primaryCluster $PrimaryCluster -secondaryCluster $SecondaryCluster
    if ( ! $Vserver ) {
        clean_and_exit 1
    }
}
####################################################################################################

if ( $Backup ) {
    $Global:Run_Mode = "Backup"
    Write-Log "SVMTOOL Run Backup"
    if ((Test-Path $Global:CONFFILE) -eq $True ) {
        Write-LogDebug "use Config File [$Global:CONFFILE]"
        $read_conf = read_config_file $Global:CONFFILE
        if ( $read_conf -eq $null ) {
            Write-LogError "ERROR: read configuration file $Global:CONFFILE failed"
            clean_and_exit 1 ;
        }
        $SVMTOOL_DB = $read_conf.Get_Item("SVMTOOL_DB")
        if ($RecreateConf -eq $True) {
            $ANS = Read-HostOptions -question "Configuration file already exist. Do you want to recreate it ?" -options "y/n" -default "y"
            if ( $ANS -ne 'y' ) {
                $RecreateConf = $False 
            }
        }
    }
    if ($RecreateConf -eq $True -or (Test-Path $Global:CONFFILE) -eq $False) {
        Write-Log "[$Backup] Create new Config File"
        $ANS = 'n'
        while ( $ANS -ne 'y' ) {
            $SVMTOOL_DB = Read-HostDefault -question  "Please enter the directory in which the backups will be stored" -default $Global:SVMTOOL_DB_DEFAULT
            if($SVMTOOL_DB -notmatch $("\\"+$Backup+"$")){
                Write-LogDebug "Backup directory [$SVMTOOL_DB] does not contains subfolder with Cluster name [$Backup]"
                if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$SVMTOOL_DB+=$("\"+$Backup)}
                else{$SVMTOOL_DB+=$("/"+$Backup)}
            }else{
                Write-LogDebug "Backup directory [$SVMTOOL_DB] already contains subfolder with Cluster name [$Backup]"    
            }
            Write-Log "SVMTOOL Backup directory:  [$SVMTOOL_DB]"
            Write-Log ""
            $ANS = Read-HostOptions -question "Apply new configuration ?" -options "y/n/q" -default "y"
            if ( $ANS -eq 'q' ) {
                clean_and_exit 1 
            }
            Write-Output "#" | Out-File -FilePath $Global:CONFFILE  
            Write-Output "SVMTOOL_DB=$SVMTOOL_DB" | Out-File -FilePath $Global:CONFFILE -Append 
            Write-Output "INSTANCE_MODE=BACKUP_RESTORE" | Out-File -FilePath $Global:CONFFILE -Append
            Write-Output "BACKUP_CLUSTER=$Backup" | Out-File -FilePath $Global:CONFFILE -Append  
        }
    }
    elseif ($SVMTOOL_DB.Length -gt 0) {
        Write-Log "Backup will be done inside [$SVMTOOL_DB]"
    }
    if ($Vserver.length -eq 0) { 
        Write-LogDebug "No SVM selected. Will backup all SVM on Cluster [$Backup]"
        $BACKUPALLSVM = $True
    }
    else {
        Write-Log "Backup SVM [$Vserver] on Cluster [$Backup]"
    }

    $myCred = get_local_cDotcred ($Backup)
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$Backup] with login [$tmp_str]"
    Write-LogDebug "connect_cluster -myController $Backup -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster -myController $Backup -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$Backup]" 
        clean_and_exit 1
    }
    if ($BACKUPALLSVM -eq $True) {
        $AllSVM = Get-NcVserver -Query @{VserverType = "data"; VserverSubtype = "!sync_destination,!dp_destination" } -Controller $NcPrimaryCtrl -ErrorVariable ErrorVar 
        if ( $? -ne $True ) {
            $Return = $False ; throw "ERROR: Get-NcVserver failed [$ErrorVar]" 
        }
        if ($AllSVM) {
            $SVMList = $AllSVM.Vserver
        }
        else {
            Write-Log "ERROR: No active SVM available on Cluster [$Backup]"
            clean_and_exit 1
        }
    }
    else {
        $SVMList = @($Vserver)   
    }
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool_Backup = [runspacefactory]::CreateRunspacePool(1, $Global:NumberOfLogicalProcessor, $iss, $Host)
    $RunspacePool_Backup.Open()
    [System.Collections.ArrayList]$jobs = @()
    $SVMcount = $SVMList.Count
    $Jobs_Backup = @()
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    $numJobBackup = 0
    $BackupDate = Get-Date -UFormat "%Y%m%d%H%M%S"
    foreach ($svm in $SVMList) {
        $svm_status = Get-NcVserver -Vserver $svm -Controller $NcPrimaryCtrl -ErrorVariable ErrorVar
        $svm_status = $svm_status.OperationalState
        if ($svm_status -eq "stopped") {
            Write-LogWarn "[$svm] can't be saved because it is in `"stopped`" state"
            continue
        }
        Write-Log "Create Backup Job for [$svm]" "Blue" -multithreaded
        $codeBackup = [scriptblock]::Create( {
                param(
                    [Parameter(Mandatory = $True)][string]$script_path,
                    [Parameter(Mandatory = $True)][NetApp.Ontapi.Filer.C.NcController]$myPrimaryController,
                    [Parameter(Mandatory = $True)][string]$myPrimaryVserver,
                    [Parameter(Mandatory = $True)][string]$SVMTOOL_DB,
                    [Parameter(Mandatory = $True)][String]$BackupDate,
                    [Parameter(Mandatory = $True)][String]$LOGFILE,
                    [Parameter(Mandatory = $False)][string]$LogLevelConsole,
                    [Parameter(Mandatory = $False)][string]$LogLevelLogFile,
                    [boolean]$NonInteractive
                )
                #Wait-Debugger
                $ConsoleThreadingRequired = $true

                if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Path = $env:PSModulePath.split(";")}else{$Path = $env:PSModulePath.split(":")}
                if ($Path -notcontains $script_path) {
                    $Path += $script_path
                    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Path = [string]::Join(";", $Path)}else{$Path = [string]::Join(":", $Path)}
                    [System.Environment]::SetEnvironmentVariable('PSModulePath', $Path)
                }
        
                $module = Import-Module svmtools -PassThru
                if ( $module -eq $null ) {
                    Write-Error "ERROR: Failed to load module SVMTOOLS"
                    exit 1
                }
                $Global:Run_Mode="Backup"
                $Global:NFSonly=$False
                $Global:STOP_TIMEOUT = 360
                $Global:START_TIMEOUT = 360
                $dir = Split-Path -Path $LOGFILE -Parent
                $file = Split-Path -Path $LOGFILE -Leaf
                if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
                    $LOGFILE = ($dir + '\' + $myPrimaryVserver + '\' + $file)
                }else{
                    $LOGFILE = ($dir + '/' + $myPrimaryVserver + '/' + $file)
                }

                # appenders (logfile, eventviewer & console)
                if($LogLevelConsole -eq ""){$LogLevelConsole="Info"}
                if($LogLevelLogFile -eq ""){$LogLevelLogFile="Debug"}
                $guid = ([guid]::NewGuid()).Guid
                $masterLogFileAppender = create_rolling_log_appender -name "svmtool.log_$guid"  -file $LOGFILE -threshold $LogLevelLogFile
                $consoleAppender = create_console_appender -name "console_$guid" -threshold $LogLevelConsole

                # initialize console
                add_appender -loggerinstance "console_$guid" $masterLogFileAppender
                add_appender -loggerinstance "console_$guid" $consoleAppender
                set_log_level -loggerinstance "console_$guid" -level "All"
                $Global:ConsoleLog = get_logger -name "console_$guid"

                add_appender -loggerinstance "logonly_$guid" $masterLogFileAppender
                set_log_level -loggerinstance "logonly_$guid" -level "All"
                $Global:MasterLog = get_logger -name "logonly" 

                $Global:NonInteractive = $NonInteractive
                
                $PSVersion=$PSVersionTable.PSVersion
                if($PSVersionTable.PSVersion.Major -le 5){
                    Write-LogDebug "Running svmtool with Powershell version [$PSVersion]"
                    Write-LogDebug "Import classical PSTK"
                    if (!($env:PSModulePath -match "NetApp PowerShell Toolkit")) {
                        $env:PSModulePath = $($env:PSModulePath + ";C:\Program Files (x86)\NetApp\NetApp PowerShell Toolkit\Modules")
                    }
                    $module = Import-Module -Name DataONTAP -PassThru
                    if ( $module -eq $null ) {
                        Write-LogError "ERROR: Failed to load module Netapp PSTK"
                        exit 1
                    }
                }else{
                    Write-LogDebug "Running svmtool with PWSH Core version [$PSVersion]"
                    Write-LogDebug "Import PSTK Core version"
                    #$module = Import-Module "C:\Users\masson\Downloads\PSTK 9.8 CORE\NetApp.ONTAP\NetApp.ONTAP.psd1"
                    $module = Import-Module NetApp.ONTAP
                    $module = Get-Module NetApp.ONTAP
                    if ( $module -eq $null ) {
                        Write-Error "ERROR: NetApp.ONTAP Core module not found" 
                        exit 1
                    }  
                    # workaround for BURT 1385162
                    $DataONTAP_SkipEmsReport = $null
                    $DataONTAP_SkipUsageReport = $true  
                }

                check_create_dir -FullPath $LOGFILE -Vserver $myPrimaryVserver | Out-Null
                Write-Log "[$myPrimaryVserver] Log File is [$LOGFILE]"
                $Global:SVMTOOL_DB = $SVMTOOL_DB
                if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
                    $Global:JsonPath = $($SVMTOOL_DB + "\" + $myPrimaryVserver + "\" + $BackupDate + "\")
                }else{
                    $Global:JsonPath = $($SVMTOOL_DB + "/" + $myPrimaryVserver + "/" + $BackupDate + "/")    
                }
                Write-LogDebug "[$myPrimaryVserver] Backup Folder is [$Global:JsonPath]"
                check_create_dir -FullPath $($Global:JsonPath + "backup.json") -Vserver $myPrimaryVserver | Out-Null
                #wait-debugger
                Write-LogDebug "[$myPrimaryVserver] Backup Folder after check_create_dir is [$Global:JsonPath]"
                if ( ( $ret = create_vserver_dr -myPrimaryController $myPrimaryController -workOn $myPrimaryVserver -Backup -myPrimaryVserver $myPrimaryVserver -DDR $False -aggrMatchRegEx $AggrMatchRegex -nodeMatchRegEx $NodeMatchRegex -myDataAggr $DataAggr -RootAggr $RootAggr)[-1] -ne $True ) {
                    Write-LogDebug "create_vserver_dr return False [$ret]"
                    flush_log4net -loggerinstance "console_$guid"
                    flush_log4net -loggerinstance "logonly_$guid"
                    return $False
                }
                Write-LogDebug "create_vserver_dr correctly finished [$ret]"
                Write-Log "[$myPrimaryVserver] Check Quota"
                $AllQuotaRulesList = Get-NcQuota -Controller $myPrimaryController -VserverContext $myPrimaryVserver -ErrorVariable ErrorVar 
                if ( $? -ne $True ) { 
                    Write-LogDebug "ERROR: Get-NcQuota Failed"
                    flush_log4net -loggerinstance "console_$guid"	
                    flush_log4net -loggerinstance "logonly_$guid"
                    return $False
                }
                $AllQuotaRulesList | ConvertTo-Json -Depth 7 | Out-File -FilePath $($Global:JsonPath + "Get-NcQuota.json") -Encoding ASCII -Width 65535
                if ( ($ret = Get-Item $($Global:JsonPath + "Get-NcQuota.json") -ErrorAction SilentlyContinue) -ne $null ) {
                    Write-LogDebug "$($Global:JsonPath+"Get-NcQuota.json") saved successfully"
                }
                else {
                    Write-LogError "ERROR: Failed to saved $($Global:JsonPath+"Get-NcQuota.json")"
                    flush_log4net -loggerinstance "console_$guid"
                    flush_log4net -loggerinstance "logonly_$guid"
                    return $False
                }
                Write-Log "[$myPrimaryVserver] Check Quota Policy"
                $AllQuotaPolicyList = Get-NcQuotaPolicy -Controller $myPrimaryController -VserverContext $myPrimaryVserver -ErrorVariable ErrorVar 
                if ( $? -ne $True ) { 
                    Write-LogDebug "ERROR: Get-NcQuotaPolicy Failed"
                    flush_log4net -loggerinstance "console_$guid"
                    flush_log4net -loggerinstance "logonly_$guid"
                    return $False
                }
                $AllQuotaPolicyList | ConvertTo-Json -Depth 7 | Out-File -FilePath $($Global:JsonPath + "Get-NcQuotaPolicy.json") -Encoding ASCII -Width 65535
                if ( ($ret = Get-Item $($Global:JsonPath + "Get-NcQuotaPolicy.json") -ErrorAction SilentlyContinue) -ne $null ) {
                    Write-LogDebug "$($Global:JsonPath+"Get-NcQuotaPolicy.json") saved successfully"
                }
                else {
                    Write-LogError "ERROR: Failed to saved $($Global:JsonPath+"Get-NcQuotaPolicy.json")"
                    flush_log4net -loggerinstance "console_$guid"
                    flush_log4net -loggerinstance "logonly_$guid"
                    return $False
                }
                flush_log4net -loggerinstance "console_$guid"
                flush_log4net -loggerinstance "logonly_$guid"
                return $True
            })
        $BackupJob = [System.Management.Automation.PowerShell]::Create()
        ## $createVserverBackup=Get-Content Function:\create_vserver_dr -ErrorAction Stop
        ## $codeBackup=$createVserverBackup.Ast.Body.Extent.Text
        [void]$BackupJob.AddScript($codeBackup)
        [void]$BackupJob.AddParameter("script_path", $PSScriptRoot)
        [void]$BackupJob.AddParameter("myPrimaryController", $NcPrimaryCtrl)
        [void]$BackupJob.AddParameter("myPrimaryVserver", $svm)
        [void]$BackupJob.AddParameter("SVMTOOL_DB", $SVMTOOL_DB)
        [void]$BackupJob.AddParameter("BackupDate", $BackupDate)
        [void]$BackupJob.AddParameter("LOGFILE", $LOGFILE)
        [void]$BackupJob.AddParameter("LogLevelLogFile", $LogLevelLogFile)
        [void]$BackupJob.AddParameter("LogLevelConsole", $LogLevelConsole)
        [void]$BackupJob.AddParameter("NonInteractive", $NonInteractive)
        $BackupJob.RunspacePool = $RunspacePool_Backup
        $Handle = $BackupJob.BeginInvoke()
        $JobBackup = "" | Select-Object Handle, Thread, Name
        $JobBackup.Handle = $Handle
        $JobBackup.Thread = $BackupJob
        $JobBackup.Name = $svm
        <# if($JobBackup.Thread.InvocationStateInfo.State -eq "Failed"){
			$reason=$JobBackup.Thread.InvocationStateInfo.Reason
			Write-LogDebug "ERROR: Failed to invoke Backup Job [$svm] Reason: $reason"
			clean_and_exit 1
		}
		if($JobBackup.Thread.Streams.Error -ne $null){
			$reason=$JobBackup.Thread.Stream.Error
			Write-LogDebug "ERROR: Failed to invoke Backup Job [$svm] Reason: $reason"
			clean_and_exit 1
		} #>
        $Jobs_Backup += $JobBackup
        $numJobBackup++
    }
    While (($Jobs_Backup | Where-Object { $_.Handle.IsCompleted -eq $True } | Measure-Object).Count -ne $numJobBackup) {
        $JobRemain = $Jobs_Backup | Where-Object { $_.Handle.IsCompleted -eq $False }
        $Remaining = ""
        $Remaining = $JobRemain.Name
        If ($Remaining.Length -gt 80) {
            $Remaining = $Remaining.Substring(0, 80) + "..."
        }
        $numberRemaining = ($JobRemain | Measure-Object).Count
        if ($numberRemaining -eq $null -or $numberRemaining -eq 0) {
            $JobRemain
        }
        $percentage = [math]::round((($numJobBackup - $numberRemaining) / $numJobBackup) * 100)
        <# Write-Progress `
            -id 1 `
            -Activity "Waiting for all $numJobBackup Jobs to finish..." `
            -PercentComplete (((($Jobs_Backup.Count) - $numberRemaining) / $Jobs_Backup.Count) * 100) `
            -Status "$($($($Jobs_Backup | Where-Object {$_.Handle.IsCompleted -eq $False})).count) remaining task(s) : $Remaining [$percentage% done]" #>
    }
    ForEach ($JobBackup in $($Jobs_Backup | Where-Object { $_.Handle.IsCompleted -eq $True })) {
        $jobname = $JobBackup.Name
        Write-log "$jobname finished" -color magenta
        $result_Backup = $JobBackup.Thread.EndInvoke($JobBackup.Handle)
        if ($result_Backup.count -gt 0) {
            $ret = $result_Backup[-1]
        }
        else {
            $ret = $result_Backup
        }
        if ($ret -ne $True) {
            Write-LogError "ERROR: Backup for SVM [$jobname]"
            Write-LogError "Check log"
        }
        #Write-LogDebug "result Backup Job [$jobname] = $result_Backup"
    }
    $RunspacePool_Backup.Close()
    $RunspacePool_Backup.Dispose()

    # end 
    $stopwatch.stop()
    Write-Log $("Finished - Script ran for {0}" -f $stopwatch.Elapsed.toString())
    clean_and_exit 0
} #End Backup
####################################################################################################

if ( $Restore ) {
    $Global:Run_Mode = "Restore"
    $Global:RESTORE_SRC_CLUSTER = $Restore
    $Global:RESTORE_DST_CLUSTER = $Destination
    if ($Global:RESTORE_SRC_CLUSTER -eq $Global:RESTORE_DST_CLUSTER) {
        $Global:RESTORE_ORIGINAL = $True
        Write-Log "[$Restore] Restore to Origin [$Vserver]"
    }
    else {
        $Global:RESTORE_ORIGINAL = $False	
    }
    Write-LogOnly "SVMTOOL Run Restore"
    if ((Test-Path $Global:CONFFILE) -eq $True ) {
        $read_conf = read_config_file $Global:CONFFILE
        if ( $read_conf -eq $null ) {
            Write-LogError "ERROR: read configuration file $Global:CONFFILE failed"
            clean_and_exit 1
        }
        $SVMTOOL_DB = $read_conf.Get_Item("SVMTOOL_DB")
    }
    if ($SVMTOOL_DB.Length -gt 0) {
        Write-Log "Restore from Cluster [$Restore] from Backup Folder [$SVMTOOL_DB]"
    }
    else {
        Write-Error "ERROR: No Backup Folder configured, check configuration file [$Global:CONFFILE] for item [SVMTOOL_DB]"
        clean_and_exit 1
    }
    $RESTOREALLSVM = $False
    if ($Vserver.Length -eq 0) { 
        Write-Log "No SVM selected, will restore all SVM availables in Backup folder for Cluster [$Restore]"
        $RESTOREALLSVM = $True
    }
    else {
        Write-Log "Restore SVM [$Vserver] from Backup for Cluster [$Restore]"
    }
    if ($Destination.length -lt 1) {
        $Destination = $Restore
        Write-Log "No Destination specified. Will restore on source Cluster [$Destination]"
    }
    else {
        Write-Log "Will restore on new Cluster [$Destination]"	
    }
    $myCred = get_local_cDotcred ($Destination)
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$Destination] with login [$tmp_str]"
    Write-LogDebug "connect_cluster -myController $Destination -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster -myController $Destination -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$Destination]" 
        clean_and_exit 1
    }
    if ($RESTOREALLSVM -eq $True) {
        if (($ALLSVM = (Get-ChildItem $SVMTOOL_DB).Name) -eq $null) {
            $Return = $False ; throw "ERROR: Get-ChildItem failed for [$SVMTOOL_DB]`nERROR: no Backup available"
        }
        if ($AllSVM) {
            $SVMList = $AllSVM
        }
    }
    else {
        if ((Test-Path $SVMTOOL_DB) -eq $null) {
            $Return = $False ; throw "ERROR: no Backup available for [$Restore] inside [$SVMTOOL_DB]"	
        }
        else {
            $SVMList = @($Vserver)
        }
    }
    #Loop to Restore all SVM in List . Loop in RunspacePool
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool_Restore = [runspacefactory]::CreateRunspacePool(1, $Global:NumberOfLogicalProcessor, $iss, $Host)
    $RunspacePool_Restore.Open()
    [System.Collections.ArrayList]$jobs = @()
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    $SVMcount = $SVMList.Count
    $Jobs_Restore = @()
    $numJobRestore = 0
    foreach ($svm in $SVMList) {
        Write-Log "Select Backup Date for [$svm]"
        if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
            $BackupAvailable = Get-ChildItem $($SVMTOOL_DB + "\" + $svm) -Directory | Sort-Object -Property CreationTime
        }else{
            $BackupAvailable = Get-ChildItem $($SVMTOOL_DB + "/" + $svm) -Directory | Sort-Object -Property CreationTime
        }
        if ($BackupAvailable -eq $null) {
            Write-Error "ERROR: No Backup available for [$svm]"
            next
        }
        else {
            $ans = $null
            if ($SelectBackupDate -eq $True) {
                $listBackupAvailable = ($BackupAvailable | Select-Object Name).Name
                while ($ans -eq $null) {
                    Write-Host "Select a Backup Date for [$svm] : "
                    $i = 1
                    foreach ($date in $listBackupAvailable) {
                        if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
                            $numFiles = (Get-ChildItem $($SVMTOOL_DB + "\" + $svm + "\" + $date + "\") | Measure-Object).Count
                        }else{
                            $numFiles = (Get-ChildItem $($SVMTOOL_DB + "/" + $svm + "/" + $date + "/") | Measure-Object).Count
                        }
                        $datetime = [datetime]::parseexact($date, "yyyyMMddHHmmss", $null)
                        Format-ColorBrackets "`t[$i] : [$datetime] [$numFiles Files]" -FirstIsSpecial
                        $i++
                    }
                    $Query = "Please select Backup from (1.." + $listBackupAvailable.count + ")"
                    $ans = Read-HostDefault -question $Query -default $listBackupAvailable.count
                    $ans = [int]$ans / 1
                    if (($ans -notmatch "[0-9]") -or ($ans -lt 1 -or $ans -gt $listBackupAvailable.count)) {
                        Write-Warning "Bad input"; $ans = $null
                    }
                }
                if($listBackupAvailable.count -gt 1){
                    $date = $listBackupAvailable[$ans - 1]
                }else{
                    $date = $listBackupAvailable
                }
            }
            else {
                # display lastbackup automatically selected for each SVM (with #files inside folder)
                $LastBackup = $BackupAvailable[-1]
                $date = $LastBackup.Name
                $datetime = [datetime]::parseexact($date, "yyyyMMddHHmmss", $null)
                if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
                    $numFiles = (Get-ChildItem $($SVMTOOL_DB + "\" + $svm + "\" + $date + "\") | Measure-Object).Count
                }else{
                    $numFiles = (Get-ChildItem $($SVMTOOL_DB + "/" + $svm + "/" + $date + "/") | Measure-Object).Count
                }
                Write-Log "[$svm] Last Backup date is [$datetime] with [$numFiles Files]" -firstValueIsSpecial
            }
        }
        if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
            $JsonPath = $($SVMTOOL_DB + "\" + $svm + "\" + $date + "\")
        }else{
            $JsonPath = $($SVMTOOL_DB + "/" + $svm + "/" + $date + "/")
        }
        Write-Log "[$svm] Create Restore Job from [$JsonPath]"
        $codeRestore = [scriptblock]::Create( {
                param(
                    [Parameter(Mandatory = $True)][string]$script_path,
                    [Parameter(Mandatory = $True)][string]$SourceVserver,
                    [Parameter(Mandatory = $True)][string]$SVMTOOL_DB,
                    [Parameter(Mandatory = $True)][String]$JsonPath,
                    [Parameter(Mandatory = $True)][String]$LOGFILE,
                    [Parameter(Mandatory = $True)][NetApp.Ontapi.Filer.C.NcController]$DestinationController,
                    [Parameter(Mandatory = $True)][string]$VOLTYPE,
                    [Parameter(Mandatory = $False)][pscredential]$DefaultLocalUserCredentials,
                    [Parameter(Mandatory = $False)][pscredential]$ActiveDirectoryCredentials,
                    [Parameter(Mandatory = $False)][pscredential]$DefaultLDAPCredentials,
                    [Parameter(Mandatory = $False)][string]$TemporarySecondaryCifsIp="",
                    [Parameter(Mandatory = $False)][string]$SecondaryCifsLifMaster="",
                    [Parameter(Mandatory = $False)][string]$RootAggr="",
                    [Parameter(Mandatory = $False)][string]$DataAggr="",        
                    [Parameter(Mandatory = $False)][string]$LogLevelConsole="Info",
                    [Parameter(Mandatory = $False)][string]$LogLevelLogFile="Debug",
                    [Parameter(Mandatory = $True)][bool]$RESTORE_ORIGINAL=$False,
                    [Parameter(Mandatory = $False)][bool]$FORCE_RESTORE_ORIGINAL=$False,
                    [boolean]$NonInteractive=$True
                )
                $Global:Run_Mode="Restore"
                $Global:NFSonly=$False
                $Global:RootAggr = $RootAggr
                $Global:DataAggr = $DataAggr
                $Global:ConsoleThreadingRequired = $true
                $Global:RESTORE_ORIGINAL = $RESTORE_ORIGINAL
                $Global:ForceRestoreOriginal = $FORCE_RESTORE_ORIGINAL

                if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Path = $env:PSModulePath.split(";")}else{$Path = $env:PSModulePath.split(":")}
                if ($Path -notcontains $script_path) {
                    $Path += $script_path
                    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){$Path = [string]::Join(";", $Path)}else{$Path = [string]::Join(":", $Path)}
                    [System.Environment]::SetEnvironmentVariable('PSModulePath', $Path)
                }

                $module = Import-Module svmtools -PassThru
                if ( $module -eq $null ) {
                    Write-Error "ERROR: Failed to load module SVMTOOLS"
                    exit 1
                }
                $Global:NonInteractive = $NonInteractive
			
                $PSVersion=$PSVersionTable.PSVersion
                if($PSVersionTable.PSVersion.Major -le 5){
                    Write-LogDebug "Running svmtool with Powershell version [$PSVersion]"
                    Write-LogDebug "Import classical PSTK"
                    if (!($env:PSModulePath -match "NetApp PowerShell Toolkit")) {
                        $env:PSModulePath = $($env:PSModulePath + ";C:\Program Files (x86)\NetApp\NetApp PowerShell Toolkit\Modules")
                    }
                    $module = Import-Module -Name DataONTAP -PassThru
                    if ( $module -eq $null ) {
                        Write-LogError "ERROR: Failed to load module Netapp PSTK"
                        exit 1
                    }
                }else{
                    Write-LogDebug "Running svmtool with PWSH Core version [$PSVersion]"
                    Write-LogDebug "Import PSTK Core version"
                    #$module = Import-Module "C:\Users\masson\Downloads\PSTK 9.8 CORE\NetApp.ONTAP\NetApp.ONTAP.psd1"
                    $module = Import-Module NetApp.ONTAP
                    $module = Get-Module NetApp.ONTAP
                    if ( $module -eq $null ) {
                        Write-Error "ERROR: NetApp.ONTAP Core module not found" 
                        exit 1
                    }  
                    # workaround for BURT 1385162
                    $DataONTAP_SkipEmsReport = $null
                    $DataONTAP_SkipUsageReport = $true  
                }

                $Global:STOP_TIMEOUT = 360
                $Global:START_TIMEOUT = 360
                $dir = Split-Path -Path $LOGFILE -Parent
                $file = Split-Path -Path $LOGFILE -Leaf
                if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
                    $LOGFILE = ($dir + '\' + $SourceVserver + '\' + $file)
                }else{
                    $LOGFILE = ($dir + '/' + $SourceVserver + '/' + $file)    
                }

                # appenders (logfile, eventviewer & console)
                
                $guid = ([guid]::NewGuid()).Guid
                $masterLogFileAppender = create_rolling_log_appender -name "svmtool.log_$guid"  -file $LOGFILE -threshold $LogLevelLogFile
                $consoleAppender = create_console_appender -name "console_$guid" -threshold $LogLevelConsole

                # initialize console
                add_appender -loggerinstance "console_$guid" $masterLogFileAppender
                add_appender -loggerinstance "console_$guid" $consoleAppender
                set_log_level -loggerinstance "console_$guid" -level "Debug"
                $Global:ConsoleLog = get_logger -name "console_$guid"

                add_appender -loggerinstance "logonly_$guid" $masterLogFileAppender
                set_log_level -loggerinstance "logonly_$guid" -level "All"
                $Global:MasterLog = get_logger -name "logonly" 

                check_create_dir -FullPath $LOGFILE -Vserver $SourceVserver | Out-Null

                $Global:SVMTOOL_DB = $SVMTOOL_DB
                $Global:JsonPath = $JsonPath
                $Global:VOLUME_TYPE = $VOLTYPE
                $Global:DefaultLocalUserCredentials = $DefaultLocalUserCredentials
                $Global:ActiveDirectoryCredentials = $ActiveDirectoryCredentials
                $Global:DefaultLDAPCredentials = $DefaultLDAPCredentials
                check_create_dir -FullPath $Global:JsonPath -Vserver $SourceVserver | Out-Null
                $DestinationCluster = $DestinationController.Name
                Write-LogDebug ""
                Write-LogDebug "Restore [$SourceVserver] on Cluster [$DestinationCluster]"
                Write-LogDebug "LOGFILE [$LOGFILE]"
                Write-Log "[$SourceVserver] LOGFILE [$LOGFILE]"
                Write-LogDebug "SVMTOOL_DB [$Global:SVMTOOL_DB]"
                Write-LogDebug "JsonPath [$Global:JsonPath]"
                Write-LogDebug "SourceVserver [$SourceVserver]"
                Write-LogDebug "DestinationController [$DestinationController]"
                Write-LogDebug "VOLUME_TYPE [$Global:VOLUME_TYPE]"
                Write-LogDebug "RootAggr [$Global:RootAggr]"
                Write-LogDebug "DataAggr [$Global:DataAggr]"
                if ( ( $ret = create_vserver_dr -myPrimaryVserver $SourceVserver -mySecondaryController $DestinationController -workOn $SourceVserver -mySecondaryVserver $SourceVserver -Restore -DDR $False -aggrMatchRegEx $AggrMatchRegex -nodeMatchRegEx $NodeMatchRegex -myDataAggr $Global:DataAggr -RootAggr $Global:RootAggr -TemporarySecondaryCifsIp $TemporarySecondaryCifsIp -SecondaryCifsLifMaster $SecondaryCifsLifMaster)[-1] -ne $True ) {

                    Write-LogDebug "ERROR in create_vserver_dr [$ret]"
                    #return $False
                }
                if ($Global:VOLUME_TYPE -eq "RW") {
                    # in restore mode force update snapshot policy on all destinations volumes
                    $Global:ForceUpdateSnapPolicy = $True
                    if ( ( $ret = set_vol_options_from_voldb -myVserver $SourceVserver -myController $DestinationController -Restore) -ne $True ) {
                        Write-LogDebug "ERROR in set_vol_options_from_voldb [$ret]"
                        #return $False
                    }
                    if ( ($ret = restore_quota -myController $DestinationController -myVserver $SourceVserver) -ne $True) {
                        Write-LogDebug "restore_quota return False [$ret]"
                        #return $False
                    }
                }
                else {
                    Write-Log "Once Data restored via SnapMirror on DP destinations volumes, update, as necessarry, Snapshot Policy and Efficiency"
                }
                flush_log4net -loggerinstance "console_$guid"
                flush_log4net -loggerinstance "logonly_$guid"
                return $True
            })
        $RestoreJob = [System.Management.Automation.PowerShell]::Create()
        ## $createVserverVackup=Get-Content Function:\create_vserver_dr -ErrorAction Stop
        ## $codeRestore=$createVserverVackup.Ast.Body.Extent.Text
        [void]$RestoreJob.AddScript($codeRestore)
        [void]$RestoreJob.AddParameter("script_path", $PSScriptRoot)
        [void]$RestoreJob.AddParameter("SourceVserver", $svm)
        [void]$RestoreJob.AddParameter("SVMTOOL_DB", $SVMTOOL_DB)
        [void]$RestoreJob.AddParameter("JsonPath", $JsonPath)
        [void]$RestoreJob.AddParameter("LOGFILE", $LOGFILE)
        [void]$RestoreJob.AddParameter("DestinationController", $NcSecondaryCtrl)
        [void]$RestoreJob.AddParameter("DefaultLocalUserCredentials", $DefaultLocalUserCredentials)
        [void]$RestoreJob.AddParameter("ActiveDirectoryCredentials", $ActiveDirectoryCredentials)
        [void]$RestoreJob.AddParameter("DefaultLDAPCredentials", $DefaultLDAPCredentials)
        [void]$RestoreJob.AddParameter("TemporarySecondaryCifsIp", $TemporarySecondaryCifsIp)
        [void]$RestoreJob.AddParameter("SecondaryCifsLifMaster", $SecondaryCifsLifMaster)
        [void]$RestoreJob.AddParameter("RootAggr", $Global:RootAggr)
        [void]$RestoreJob.AddParameter("DataAggr", $Global:DataAggr)
        [void]$RestoreJob.AddParameter("RESTORE_ORIGINAL", $Global:RESTORE_ORIGINAL)

        if($Global:ForceRestoreOriginal.IsPresent){
            [void]$RestoreJob.AddParameter("FORCE_RESTORE_ORIGINAL", $True)
        }else{
            [void]$RestoreJob.AddParameter("FORCE_RESTORE_ORIGINAL", $False)
        }
        
        if ($RW -eq $True) {
            [void]$RestoreJob.AddParameter("VOLTYPE", "RW")
        }
        else {
            [void]$RestoreJob.AddParameter("VOLTYPE", "DP")
        }
        [void]$RestoreJob.AddParameter("LogLevelLogFile", $LogLevelLogFile)
        [void]$RestoreJob.AddParameter("LogLevelConsole", $LogLevelConsole)
        [void]$RestoreJob.AddParameter("NonInteractive", $NonInteractive)
        $RestoreJob.RunspacePool = $RunspacePool_Restore
        $Handle = $RestoreJob.BeginInvoke()
        $JobRestore = "" | Select-Object Handle, Thread, Name, Log
        $JobRestore.Handle = $Handle
        $JobRestore.Thread = $RestoreJob
        $JobRestore.Name = $svm
        $dir = Split-Path -Path $LOGFILE -Parent
        $file = Split-Path -Path $LOGFILE -Leaf
        if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
            $LOGJOB = ($dir + '\' + $svm + '\' + $file)
        }else{
            $LOGJOB = ($dir + '/' + $svm + '/' + $file)    
        }
        $JobRestore.Log = $LOGJOB
        <# if ($JobRestore.Thread.InvocationStateInfo.State -eq "Failed") {
            $reason = $JobRestore.Thread.InvocationStateInfo.Reason
            Write-LogDebug "ERROR: Failed to invoke Restore Job [$svm] Reason: [$reason]"
            clean_and_exit 1
        }
        if ($JobRestore.Thread.Streams.Error -ne $null) {
            $reason = $JobRestore.Thread.Stream.Error
            Write-LogDebug "ERROR: Failed to invoke Restore Job [$svm] Reason: [$reason]"
            clean_and_exit 1
        } #>
        $Jobs_Restore += $JobRestore
        $numJobRestore++
    }
    While ( (@($Jobs_Restore | Where-Object { $_.Handle.IsCompleted -eq $True }) | Measure-Object).Count -ne $numJobRestore ) {
        $JobRemain = $Jobs_Restore | Where-Object { $_.Handle.IsCompleted -eq $False }
        $Remaining = ""
        $Remaining = $JobRemain.Name
        If ($Remaining.Length -gt 80) {
            $Remaining = $Remaining.Substring(0, 80) + "..."
        }
        $numberRemaining = ($JobRemain | Measure-Object).Count
        if ($numberRemaining -eq $null -or $numberRemaining -eq 0) {
            $JobRemain
        }
        $percentage = [math]::round((($numJobRestore - $numberRemaining) / $numJobRestore) * 100)
        Write-Progress `
            -id 1 `
            -Activity "Waiting for all $numJobRestore Jobs to finish..." `
            -PercentComplete (((($Jobs_Restore.Count) - $numberRemaining) / $Jobs_Restore.Count) * 100) `
            -Status "$($($($Jobs_Restore | Where-Object {$_.Handle.IsCompleted -eq $False})).count) remaining : $Remaining [$percentage% done]"
    }
    ForEach ($JobRestore in $($Jobs_Restore | Where-Object { $_.Handle.IsCompleted -eq $True })) {
        $jobname = $JobRestore.Name
        Write-logDebug "$jobname finished"
        $result_Restore = $JobRestore.Thread.EndInvoke($JobRestore.Handle)
        if ($result_Restore.count -gt 0) {
            $ret = $result_Restore[-1]
        }
        else {
            $ret = $result_Restore
        }
        if ($ret -ne $True) {
            Write-LogError "ERROR: Restore for SVM [$jobname]:[$ret]:[$result_Restore]"
            $LOGPATH = $JobRestore.Log
            Write-LogError "Check log [$LOGPATH]"
        }
        #Write-LogDebug "result Restore Job [$jobname] = $result_Restore"
    }
    $RunspacePool_Restore.Close()
    $RunspacePool_Restore.Dispose()
    # end 
    $stopwatch.stop()
    Write-Log $("Finished - Script ran for {0}" -f $stopwatch.Elapsed.toString())
    clean_and_exit 0
} #End Restore
########################################################################################################
# RestoreObject  : Restore from JSON Backup specific objects into an SVM

if ( $RestoreObject ){
    $Global:Run_Mode = "RestoreObject"
    Write-LogOnly "SVMTOOL Run RestoreObject"
    $RESTORE_SRC_CLUSTER = $RestoreObject
    if( $DestinationCluster ){
        $RESTORE_DST_CLUSTER = $DestinationCluster
    }else{
        $RESTORE_DST_CLUSTER = $RestoreObject    
    }
    if( -not $DestinationSVM ){
        $DestinationSVM = $Vserver
    }
    if ( ($Vserver -eq $DestinationSVM) -and ($RESTORE_SRC_CLUSTER -eq $RESTORE_DST_CLUSTER) ) {
        $Global:RESTORE_ORIGINAL = $True
        Write-Log "[$RestoreObject] Restore to Origin [$Vserver]"
    }
    else {
        $Global:RESTORE_ORIGINAL = $False	
    }
    if($Global:ForceRestoreOriginal.IsPresent){
        $Global:RESTORE_ORIGINAL = $True    
    }
    if ((Test-Path $Global:CONFFILE) -eq $True ) {
        $read_conf = read_config_file $Global:CONFFILE
        if ( $read_conf -eq $null ) {
            Write-LogError "ERROR: read configuration file $Global:CONFFILE failed"
            clean_and_exit 1
        }
        $SVMTOOL_DB = $read_conf.Get_Item("SVMTOOL_DB")
    }
    if ($SVMTOOL_DB.Length -gt 0) {
        Write-Log "Restore from Cluster [$RESTORE_SRC_CLUSTER] from Backup Folder [$SVMTOOL_DB]"
    }
    else {
        Write-Error "ERROR: No Backup Folder configured, check configuration file [$Global:CONFFILE] for item [SVMTOOL_DB]"
        clean_and_exit 1
    }
    if ((Test-Path $SVMTOOL_DB) -eq $null) {
        Write-Error "ERROR: no Backup available for [$RESTORE_SRC_CLUSTER] inside [$SVMTOOL_DB]"
        clean_and_exit 1	
    }
    Write-Log "Select Backup Date for [$Vserver]"
    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
        $BackupAvailable = Get-ChildItem $($SVMTOOL_DB + "\" + $Vserver) | Sort-Object -Property CreationTime
    }else{
        $BackupAvailable = Get-ChildItem $($SVMTOOL_DB + "/" + $Vserver) | Sort-Object -Property CreationTime   
    }
    if ($BackupAvailable -eq $null) {
        Write-Error "ERROR: No Backup available for [$Vserver]"
        clean_and_exit 1
    }
    else {
        $ans = $null
        if ($SelectBackupDate -eq $True) {
            $listBackupAvailable = ($BackupAvailable | Select-Object Name).Name
            while ($ans -eq $null) {
                Write-Host "Select a Backup Date for [$Vserver] : "
                $i = 1
                foreach ($date in $listBackupAvailable) {
                    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
                        $numFiles = (Get-ChildItem $($SVMTOOL_DB + "\" + $Vserver + "\" + $date + "\") | Measure-Object).Count
                    }else{
                        $numFiles = (Get-ChildItem $($SVMTOOL_DB + "/" + $Vserver + "/" + $date + "/") | Measure-Object).Count    
                    }
                    $datetime = [datetime]::parseexact($date, "yyyyMMddHHmmss", $null)
                    Format-ColorBrackets "`t[$i] : [$datetime] [$date] [$numFiles Files]" -FirstIsSpecial
                    $i++
                }
                $Query = "Please select Backup from (1.." + $listBackupAvailable.count + ")"
                $ans = Read-HostDefault -question $Query -default $listBackupAvailable.count -forceAsk $True
                $ans = [int]$ans / 1
                if (($ans -notmatch "[0-9]") -or ($ans -lt 1 -or $ans -gt $listBackupAvailable.count)) {
                    Write-Warning "Bad input"; $ans = $null
                }
            }
            if($listBackupAvailable.count -gt 1){
                $date = $listBackupAvailable[$ans - 1]
            }else{
                $date = $listBackupAvailable
            }
        }
        else {
            # display lastbackup automatically selected for each SVM (with #files inside folder)
            $LastBackup = $BackupAvailable[-1]
            $date = $LastBackup.Name
            $datetime = [datetime]::parseexact($date, "yyyyMMddHHmmss", $null)
            if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
                $numFiles = (Get-ChildItem $($SVMTOOL_DB + "\" + $Vserver + "\" + $date + "\") | Measure-Object).Count
            }else{
                $numFiles = (Get-ChildItem $($SVMTOOL_DB + "/" + $Vserver + "/" + $date + "/") | Measure-Object).Count
            }
            Write-Log "[$Vserver] Last Backup date is [$datetime] with [$numFiles Files]" -firstValueIsSpecial
        }
    }
    if(($PSVersionTable.PSVersion.Major -lt 7) -or $IsWindows){
        $Global:JsonPath = $($SVMTOOL_DB + "\" + $Vserver + "\" + $date + "\")
    }else{
        $Global:JsonPath = $($SVMTOOL_DB + "/" + $Vserver + "/" + $date + "/")
    }
    check_create_dir -FullPath $Global:JsonPath -Vserver $Vserver | Out-Null

    # Connect to the Cluster
    $myCred = get_local_cDotcred ($RESTORE_SRC_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$RESTORE_SRC_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster -myController $RESTORE_SRC_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster -myController $RESTORE_SRC_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$RESTORE_SRC_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($RESTORE_DST_CLUSTER) 
    Write-LogDebug "connect_cluster -myController $RESTORE_DST_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster -myController $RESTORE_DST_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$RESTORE_DST_CLUSTER]" 
        clean_and_exit 1
    } 

    # if restore volumes to Origin, force restore volumes as RW volumes
    if ($RW -eq $True) {
        $Global:VOLUME_TYPE = "RW"
    }
    else {
        $Global:VOLUME_TYPE = "DP"
    }
    if($Global:RESTORE_ORIGINAL -eq $True){
        $Global:VOLUME_TYPE="RW"
    }
    $Global:SVMTOOL_DB=$SVMTOOL_DB
    
    if ( ( $ret= restore_object -myPrimaryController $NcPrimaryCtrl `
    -mySecondaryController $NcSecondaryCtrl `
    -myPrimaryVserver $Vserver `
    -mySecondaryVserver $DestinationSVM `
    -workOn $DestinationSVM `
    -nodeMatchRegEx $nodeMatchRegEx `
    -aggrMatchRegEx $aggrMatchRegEx `
    -myDataAggr $myDataAggr `
    -objects $Objects ) -ne $True ) {
        Write-LogError "ERROR : Failed to restore all objects for [$Global:DestinationSVM]"
        clean_and_exit 1
    }

    Write-Log "Finished restore object [$Objects] from [$RESTORE_SRC_CLUSTER]:[$Vserver] to [$RESTORE_DST_CLUSTER]:[$DestinationSVM]" -firstValueIsSpecial
    clean_and_exit 0  
}


####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################

if ( ( Test-Path $Global:CONFFILE ) -eq $False ) {
    Write-LogError "ERROR: instance [$instance] not found please run setup option" 
    clean_and_exit 1
}

if ( ( $null -eq $Vserver ) -or ( $Vserver -eq "" ) ) { 
    Write-LogError "ERROR: Missing an argument for parameter 'Vserver'" 
    Write-LogError "ERROR: Please run get-help .\svmtools.ps1 for more information" 
    Clean_and_exit 1 
}

# Read configuration file
$read_conf = read_config_file $Global:CONFFILE ;
if ( $null -eq $read_conf ) {
    Write-LogError "ERROR: read configuration file $Global:CONFFILE failed" 
    clean_and_exit 1 ;
}

$PRIMARY_CLUSTER = $read_conf.Get_Item("PRIMARY_CLUSTER") ;
if ( $PRIMARY_CLUSTER -eq $Null ) {
    Write-LogError "ERROR: unable to find PRIMARY_CLUSTER in $Global:CONFFILE"
    clean_and_exit 1 ;
}
$SECONDARY_CLUSTER = $read_conf.Get_Item("SECONDARY_CLUSTER") ;
if ( $SECONDARY_CLUSTER -eq $Null ) {
    Write-LogError "ERROR: unable to find SECONDARY_CLUSTER in $Global:CONFFILE"
    clean_and_exit 1 ;
}

if ($PRIMARY_CLUSTER -eq $SECONDARY_CLUSTER) { 
    $Global:SINGLE_CLUSTER = $True
    Write-LogDebug "Detected SINGLE_CLUSTER Configuration"
}

# Read Vserver configuration file
$VCONFFILE = $Global:CONFDIR + $Vserver + '.conf'
if ($RemoveDRconf) {
    $Global:Run_Mode = "RemoveDRconf"
    Write-LogOnly "SVMTOOL RemoveDRconf"
    if ((Test-Path $VCONFFILE ) -eq $True ) {
        Remove-Item $VCONFFILE
        Write-Log "$VCONFFILE removed successfully..." -color green
    }
    else {
        Write-Log "No such config [$VCONFFILE] found..." -color yellow
    }
    clean_and_exit 1 ;
}

Write-LogDebug "VCONFFILE [$VCONFFILE]"
$read_vconf = read_config_file $VCONFFILE
####################################################################################################

if ( ( $Setup ) -or ( $null -eq $read_vconf ) ) {
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster -myController $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster -myController $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1 ;
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster -myController $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster -myController $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1 ;
    }
    $VserverPeerList = get_vserver_peer_list -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver
    if ( $VserverPeerList ) {
        Write-Log "$Vserver has already existing vserver peer to the cluster [$NcSecondaryCtrl]"
        foreach ( $VserverPeer in $VserverPeerList ) {
            Write-Log "[$Vserver] -> [$VserverPeer]"
        }
    }
    create_vserver_config_file_cli -Vserver $Vserver -ConfigFile $VCONFFILE -VserverDr $VserverDr -QuotaDr:$QuotaDR -NcSecondaryCtrl $NcSecondaryCtrl
    $read_vconf = read_config_file $VCONFFILE
    if ( $null -eq $read_vconf ) {
        Write-LogError "ERROR: Failed to create $VCONFFILE "
        clean_and_exit 2
    }
    if ( ! $ConfigureDR ) {
        clean_and_exit 0
    }
}

$VserverDR = $read_vconf.Get_Item("VserverDR")
if ( $null -eq $Vserver ) {
    Write-LogError "ERROR: unable to find VserverDR in $VCONFFILE"
    clean_and_exit 1 ;
}
$Global:VserverDR=$VserverDR
$AllowQuotaDR = $read_vconf.Get_Item("AllowQuotaDR")
$AllowEncryption = $read_vconf.Get_Item("AllowEncrypt")
if ($AllowEncryption -ne $null) {
    $Global:AllowEncryption = $AllowEncryption
}
$SVMTOOL_DB = $read_conf.Get_Item("SVMTOOL_DB")
$Global:SVMTOOL_DB = $SVMTOOL_DB
$Global:CorrectQuotaError = $CorrectQuotaError
$Global:ForceDeleteQuota = $ForceDeleteQuota
$Global:ForceActivate = $ForceActivate
$Global:ForceRecreate = $ForceRecreate
$Global:ForceRestart = $ForceRestart
$Global:ForceUpdateSnapPolicy = $ForceUpdateSnapPolicy
$Global:SelectVolume = $SelectVolume
$Global:IgnoreQtreeExportPolicy = $IgnoreQtreeExportPolicy
$Global:AllowQuotaDr = $AllowQuotaDr
$Global:IgnoreQuotaOff = $IgnoreQuotaOff

Write-LogDebug "PRIMARY_CLUSTER:            		 [$PRIMARY_CLUSTER]" 
Write-LogDebug "SECONDARY_CLUSTER:          		 [$SECONDARY_CLUSTER]" 
Write-LogDebug "VSERVER                     		 [$Vserver]" 
Write-LogDebug "VSERVER DR                  		 [$VserverDR]" 
Write-LogDebug "QUOTA DR                    		 [$Global:AllowQuotaDr]" 
Write-LogDebug "SVMTOOL DB                           [$Global:SVMTOOL_DB]"
Write-LogDebug "OPTION IgnoreQuotaOff       		 [$Global:IgnoreQuotaOff]"
Write-LogDebug "OPTION CorrectQuotaError    		 [$Global:CorrectQuotaError]"
Write-LogDebug "OPTION ForceDelete          		 [$Global:ForceDeleteQuota]"
Write-LogDebug "OPTION ForceActivate        		 [$Global:ForceActivate]"
Write-LogDebug "OPTION ForceRecreate        		 [$Global:ForceRecreate]"
Write-LogDebug "OPTION ForceRestart        		     [$Global:ForceRestart]"
Write-LogDebug "OPTION ForceUpdateSnapPolicy         [$Global:ForceUpdateSnapPolicy]"
Write-LogDebug "OPTION AlwaysChooseDataAggr 		 [$Global:AlwaysChooseDataAggr]"
Write-LogDebug "OPTION SelectVolume         		 [$Global:SelectVolume]"
Write-LogDebug "OPTION IgnoreQtreeExportPolicy       [$Global:IgnoreQtreeExportPolicy]"
####################################################################################################

if ( $ShowDR ) {
    $Global:Run_Mode = "ShowDR"
    Write-LogOnly "SVMTOOL ShowDR"
    if($NoVolumeDetail.IsPresent -eq $False ){
        $Global:NoVolumeDetail=$False
    }else{
        $Global:NoVolumeDetail=$True
    }

    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster -myController $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster -myController $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        $NcPrimaryCtrl = $null
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster -myController $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster -myController $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        $NcSecondaryCtrl = $null
    }
    Write-LogDebug "show_vserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR"
    $ret = show_vserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR -Lag:$Lag -Schedule:$Schedule
    clean_and_exit $ret
}
####################################################################################################

if ( $ConfigureDR ) {
    $Global:Run_Mode = "ConfigureDR"
    Write-LogOnly "SVMTOOL ConfigureDR"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster -myController $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster -myController $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    # Analyse argument
    
    $CIFSsource=Get-NcCifsServer -VserverContext $Vserver -Controller $NcPrimaryCtrl -ErrorVariable ErrorVar
    if($null -ne $CIFSsource){
        Write-LogDebug "CIFS server exist on Source SVM"
        if( ($Global:PreserveIdentity -eq $True) -and ($TemporarySecondaryCifsIp.Length -eq 0) ){
            Write-LogWarn "In PreserveIdentity mode (default for ConfigureDR/New-SvmDr), you must provide information to create a Temporary LIF on destination capable to register CIFS server"
            Write-LogWarn "use TemporarySecondaryCifsIp and SecondaryCifsLifMaster parameter to define this Temporay LIF on destination"
            clean_and_exit 1
        }
		<# if( ($Global:PreserveIdentity -eq $False) -and ($Global:NonInteractive.IsPresent) ){
			Write-LogWarn "In NonInteractive mode without PreserveIdentity, you must provide a Temporary LIF on destination capable to register CIFS server"
            Write-LogWarn "use TemporarySecondaryCifsIp and SecondaryCifsLifMaster parameter to define this Temporay LIF on destination"
            #clean_and_exit 1
		} #>
    }else{
        Write-LogDebug "No CIFS Server on Source, switch to NFSonly mode"
        $Global:NFSonly=$True
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster -myController $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster -myController $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }

    Check_Running_Inside_Same_MCC -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl

    if ( ($ret = Save_Cluster_To_JSON -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl) -ne $True) {
        Write-Warning "FAILED to backup cluster information"
    }
    $DestVserver = Get-NcVserver -Vserver $VserverDR -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar

    if ( ( $Global:XDPPolicy -ne "" ) -and ( $Global:XDPPolicy -ne "MirrorAllSnapshots" ) ) {
        $ret = Get-NcSnapmirrorPolicy -Name $Global:XDPPolicy -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "XDPPolicy [$Global:XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will use MirrorAllSnapshots as default Policy"
            Write-Warning "XDPPolicy [$Global:XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will use [MirrorAllSnapshots] as default Policy for all XDP relationships"
            $Global:XDPPolicy = ""
        }
    }
    if ( $MirrorSchedule -ne "" -and $MirrorSchedule -ne "none") {
        $ret = Get-NcJobCronSchedule -Name $MirrorSchedule -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "MirrorSchedule [$MirrorSchedule] does not exist on [$SECONDARY_CLUSTER]. Will use no schedule"
            Write-Warning "MirrorSchedule [$MirrorSchedule] does not exist on [$SECONDARY_CLUSTER]. Will use no schedule"
            $Global:MirrorSchedule = "none"
        }
    } 
    # default to hourly
    if ($MirrorSchedule -eq "") {
        $Global:MirrorSchedule = "hourly"
    }
    # no schedule if Policy Sync or StrictSync is chosen
    if ( ( $Global:XDPPolicy -ne "") -and ( $Global:XDPPolicy -in $("Sync","StrictSync") ) ) {
        Write-Log "Reset MirrorSchedule for Sync or StrictSync relationships"
        $Global:MirrorSchedule = "none"    
    }
    if ( $? -ne $True ) {
        $Return = $False ; throw "ERROR: Get-NcVserver failed [$ErrorVar]" 
    }
    if ($DestVserver.IsConfigLockedForChanges -eq $True) {
        Write-logDebug "Unlock-NcVserver -Vserver $VserverDR -Force -Confirm:$False -Controller $NcSecondaryCtrl"
        $ret = Unlock-NcVserver -Vserver $VserverDR -Force -Confirm:$False -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True ) {
            $Return = $False ; throw "ERROR: Dest Vserver [$VserverDR] has its config locked. Unlock-NcVserver failed [$ErrorVar]" 
        }
    }
    if ( ( $ret = check_cluster_peer -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl ) -ne $True ) {
        Write-LogError "ERROR: check_cluster_peer" 
        clean_and_exit 1
    }

    if ( ( $ret = create_vserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR -DDR ($DRfromDR.isPresent) -aggrMatchRegEx $AggrMatchRegex -nodeMatchRegEx $NodeMatchRegex -myDataAggr $DataAggr -RootAggr $RootAggr -TemporarySecondaryCifsIp $TemporarySecondaryCifsIp -SecondaryCifsLifMaster $SecondaryCifsLifMaster -SecondaryCifsLifCustomVlan $SecondaryCifsLifCustomVlan -ActiveDirectoryCustomOU $ActiveDirectoryCustomOU)[-1] -ne $True ) {
        clean_and_exit 1

    }
    if ( ( $ret = svmdr_db_switch_datafiles -myController $NcPrimaryCtrl -myVserver $Vserver -secondaryVserver $VserverDR) -eq $false ) {
        Write-LogError "ERROR: Failed to switch SVMTOOL_DB datafiles" 
        clean_and_exit 1
    }
    # Verify if CIFS Service is Running if yes stop it
    $CifService = Get-NcCifsServer  -VserverContext  $VserverDR -Controller $NcSecondaryCtrl  -ErrorVariable ErrorVar
    if ( $? -ne $True ) {
        $Return = $False ; throw "ERROR: Get-NcCifsServer failed [$ErrorVar]" 
    }
    if ( $null -eq $CifService ) {
        Write-Log "[$VserverDR] No CIFS services"
    }
    else {
        if ( $CifService.AdministrativeStatus -eq 'up' ) {
            Write-LogDebug "stop-NcCifsServer -VserverContext $VserverDR -Controller $NcSecondaryCtrl -Confirm:$False"
            $out = Stop-NcCifsServer -VserverContext $VserverDR -Controller $NcSecondaryCtrl  -ErrorVariable ErrorVar -Confirm:$False
            if ( $? -ne $True ) {
                Write-LogError "ERROR: Failed to disable CIFS on Vserver [$VserverDR]" 
                $Return = $False
            }
        }
    }
    if ( ( $ret = save_vol_options_to_voldb -myController $NcPrimaryCtrl -myVserver $Vserver -mySecondaryVserver $VserverDR) -ne $True ) {
        Write-LogError "ERROR: save_vol_options_to_voldb failed"
        clean_and_exit 1
    }

    Write-LogDebug "AllowQuotaDR [$AllowQuotaDr]"
    if ( $AllowQuotaDR -eq "True" ) {
        Write-Log "[$VserverDR] Save quota policy rules to SVMTOOL_DB [$SVMTOOL_DB]" -firstValueIsSpecial
        if ( ( $ret = save_quota_rules_to_quotadb -myPrimaryController $NcPrimaryCtrl -myPrimaryVserver $Vserver -mySecondaryController $NcSecondaryCtrl -mySecondaryVserver $VserverDR ) -ne $True ) {
            Write-LogError "ERROR: save_quota_rules_to_quotadb failed"
            clean_and_exit 1
        }
    }
    clean_and_exit 0
}
####################################################################################################

if ( $DeleteDR ) {
    $Global:Run_Mode = "DeleteDR"
    Write-LogOnly "SVMTOOL DeleteDR"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred  -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }

    # if ( ( $ret=analyse_junction_path -myController $NcPrimaryCtrl -myVserver $Vserver ) -ne $True ) {
    # Write-LogError "ERROR: analyse_junction_path" 
    # clean_and_exit 1
    # }
    if ( ( $ret = remove_vserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR ) -eq $False ) {
        Write-LogError "ERROR: remove_vserver_dr: Unable to remove Vserver [$VserverDR]" 
        clean_and_exit 1
    }
    clean_and_exit 0
}

####################################################################################################

if ($Migrate) {
    $Global:Run_Mode = "Migrate"
    Write-LogOnly "SVMTOOL Migrate"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $PrimaryClusterName = $NcPrimaryCtrl.Name
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    $SecondaryClusterName = $NcSecondaryCtrl.Name

    # if ( ( $ret=analyse_junction_path -myController $NcPrimaryCtrl -myVserver $Vserver ) -ne $True ) {
    # Write-LogError "ERROR: analyse_junction_path" 
    # clean_and_exit 1
    # }
    Write-Warning "SVMTOOL script does not manage FCP configuration"
    Write-Warning "You will have to backup and recreate all these configurations manually after the Migrate step"
    Write-Warning "Files Locks are not migrated during the Migration process"
    $ASK_WAIT = Read-HostOptions -question "[$Vserver] Have all clients saved their work ?" -options "y/n" -default "y"
    if ($ASK_WAIT -eq 'y') {
        Write-LogDebug "Clients ready to migrate. User choose to continue migration procedure"
        Write-Log "[$VserverDR] Run last UpdateDR" -firstValueIsSpecial
        if ( ( $ret = create_update_cron_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl ) -ne $True ) {
            Write-LogError "ERROR: create_update_cron_dr"
        }
        if ( ( $ret = create_update_snap_policy_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR) -ne $True ) {
            Write-LogError "ERROR: create_update_snap_policy_dr"
        }

        if ( ( $ret = check_cluster_peer -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl ) -ne $True ) {
            Write-LogError "ERROR: check_cluster_peer failed"
            clean_and_exit 1
        }

        # This will set $Global:NEED_CIFS_SERVER
        $ret=check_update_CIFS_server_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR

        if ( ($ret = update_vserver_dr -myDataAggr $DataAggr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR -DDR ($DRfromDR.IsPresent) -aggrMatchRegEx $AggrMatchRegex -nodeMatchRegEx $NodeMatchRegex -TemporarySecondaryCifsIp $TemporarySecondaryCifsIp -SecondaryCifsLifMaster $SecondaryCifsLifMaster -SecondaryCifsLifCustomVlan $SecondaryCifsLifCustomVlan ) -ne $True ) {
            Write-LogError "ERROR: update_vserver_dr failed" 
            #clean_and_exit 1

        }
        if ( ( $ret = wait_snapmirror_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR ) -ne $True ) { 
            Write-LogError  "ERROR: wait_snapmirror_dr failed"  
        }
        if ( ( $ret = break_snapmirror_vserver_dr -myController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR ) -ne $True ) {
            Write-LogError "ERROR: Unable to break all relations from Vserver [$VserverDR] on [$SecondaryClusterName]"
            #clean_and_exit 1
        }

        # Remove Reverse SnapMirror Relationship if exist
        if ( ( $ret = remove_snapmirror_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver	 ) -ne $True ) { 
            Write-LogError "ERROR: remove_snapmirror_dr failed"
            #clean_and_exit 1
        }

        # Remove SnapMirror Relationship 
        if ( ( $ret = remove_snapmirror_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR -NoRelease) -ne $True ) {
            Write-LogError "ERROR: remove_snapmirror_dr failed" 
            #clean_and_exit 1
        }

        # Restamp MSID destination volume
        # if ( ( $ret=restamp_msid -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDr) -ne $True) {
        # 	Write-LogError "ERROR: restamp_msid failed"
        # 	clean_and_exit 1
        # }

        Check_Running_Inside_Same_MCC -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl
        if(($Global:InsideMCC -eq $True) -and (-not ($DeleteSource.IsPresent))){
            Write-LogError("ERROR: When migrating from the same MCC, you must delete source SVM")
            clean_and_exit 1
        }

        $ASK_MIGRATE = Read-HostOptions -question "[$Vserver] IP and Services will switch now. Ready to go ?" -options "y/n" -default "y"

        if ($ASK_MIGRATE -eq 'y') {
            
            $mySourceVserverComment=(Get-NcVserver -Name $Vserver -Controller $NcPrimaryCtrl).Comment

            # Call migrate CIFS function
            if ( ( $ret = migrate_cifs_server -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR -NoInteractive -PreserveIdentity $Global:PreserveIdentity) -ne $True ) {
                Write-LogError "ERROR: migrate_cifs_server failed"
                clean_and_exit 1
            }
            
            if ( ( $ret = set_vol_options_from_voldb -myController $NcSecondaryCtrl -myVserver $VserverDR -NoCheck) -ne $True ) {
                Write-LogError "ERROR: set_vol_options_from_voldb failed"
            }
            #if ( ( $ret=set_shareacl_options_from_shareacldb -myController $NcSecondaryCtrl -myVserver $VserverDR -NoCheck) -ne $True ) {
            #    Write-LogError "ERROR: set_shareacl_options_from_shareacldb"
            #}

            

            if ( $AllowQuotaDR -eq "True" ) {
                if ( ( $ret = create_quota_rules_from_quotadb -myController $NcSecondaryCtrl -myVserver $VserverDR -NoCheck ) -ne $True ) {
                    Write-LogError "ERROR: create_quota_rules_from_quotadb failed"
                }
            }

            #Rename flexgroup with _dst suffix generated by bug in snapmirror protect
            foreach($volume in (Get-NcVol -Vserver $VserverDR -Controller $NcSecondaryCtrl)){
                if($volume.VolumeIdAttributes.StyleExtended-eq "flexgroup"){
                    Write-LogDebug "Rename volume $($volume.Name)"
                    $ret=Rename-NcVol -Name $volume.Name -Controller $NcSecondaryCtrl -Confirm:$False -NewName $($volume.Name -replace "_dst","") -VserverContext $VserverDR
                }
            }

            # Verify if NFS service is Running 
            #Write-Log "Migrate NFS service if any"
            Write-LogDebug "Get-NcNfsService -VserverContext $VserverDR -Controller $NcSecondaryCtrl"
            $NfsService = Get-NcNfsService -VserverContext $VserverDR -Controller $NcSecondaryCtrl  -ErrorVariable ErrorVar
            if ( $? -ne $True ) {
                $Return = $False ; throw "ERROR: Get-NcNfsService failed [$ErrorVar]" 
            }
            if ( $null -eq $NfsService ) {
                Write-Log "[$VserverDR] No NFS services in vserver"
            }
            else {  # NFSservice exist on secondary, so activate it
                if ( $NfsService.GeneralAccess -ne $True ) {
                    Write-Log "[$VserverDR] Enable NFS"
                    Write-LogDebug "Enable-NcNfs -VserverContext $VserverDR -Controller $NcSecondaryCtrl"
                    $out = Enable-NcNfs -VserverContext $VserverDR -Controller $NcSecondaryCtrl  -ErrorVariable ErrorVar -Confirm:$False
                    if ( $? -ne $True ) {
                        Write-Warning "ERROR: Failed to enable NFS on Vserver [$VserverDR] [ErrorVar]"
                        Write-LogError "ERROR: Failed to enable NFS on Vserver [$VserverDR]" 
                    }
                }
            }

            # Verify if ISCSI service is Running 
            #Write-Log "Migrate iSCSI service if any"
            Write-LogDebug "Get-NcIscsiService -VserverContext $VserverDR -Controller $NcSecondaryCtrl"
            $IscsiService = Get-NcIscsiService -VserverContext $VserverDR -Controller $NcSecondaryCtrl  -ErrorVariable ErrorVar
            if ( $? -ne $True ) {
                $Return = $False ; throw "ERROR: Get-NcIscsiService failed [$ErrorVar]" 
            }
            if ( $null -eq $IscsiService ) {
                Write-Log "[$VserverDR] No iSCSI services in Vserver"
            }
            else {
                if ( $IscsiService.IsAvailable -ne $True ) {
                    Write-Log "[$VserverDR] Enable iSCSI service on Vserver"
                    Write-LogDebug "Enable-NcIscsi -VserverContext $VserverDR -Controller $NcSecondaryCtrl"
                    $out = Enable-NcIscsi -VserverContext $VserverDR -Controller $NcSecondaryCtrl  -ErrorVariable ErrorVar -Confirm:$False
                    if ( $? -ne $True ) {
                        Write-Warning "ERROR: Failed to enable iSCSI on Vserver [$VserverDR] [ErrorVar]"
                        Write-LogError "ERROR: Failed to enable iSCSI on Vserver [$VserverDR] [ErrorVar]" 
                    }
                }
            }

            if($Global:SVMSourceDeleted -eq $True){
                Write-Log "[$VserverDR] Renamed to [$Vserver]"
                Write-LogDebug "Rename-NcVserver -Name $VserverDR -NewName $Vserver -Controller $NcSecondaryCtrl"
                $out = Rename-NcVserver -Name $VserverDR -NewName $Vserver -Controller $NcSecondaryCtrl  -ErrorVariable ErrorVar
                if ( $? -ne $True ) {
                    throw "ERROR: Rename-NcVserver failed [$ErrorVar]"
                }
                if($mySourceVserverComment.lenght -gt 1){
                    Write-LogDebug "Set-NcVserver -Name $Vserver -Controller $NcSecondaryCtrl -Comment $mySourceVserverComment"
                    $ret=Set-NcVserver -Name $Vserver -Controller $NcSecondaryCtrl -Comment $mySourceVserverComment
                }
            }else{
                # stop primary SVM
                Write-Log "[$Vserver] stop Vserver"
                Write-LogDebug "Stop-NcVserver -Name $Vserver -Controller $NcPrimaryCtrl"
                $ret=Stop-NcVserver -Name $Vserver -Controller $NcPrimaryCtrl -Confirm:$False
                if($? -ne $True){Throw "ERROR: Failed to stop Vserver [$Vserver]"}
            }
            
            #Write-Log "[$Vserver] completely removed on [$PrimaryClusterName]"
            Write-Log "[$Vserver] has been migrated on destination cluster [$SecondaryClusterName]"
            Write-Log "[$Vserver] Users can now connect on destination with source Identity (IP and CIFS server name)"
        }
        else {
            Write-Log "[$Vserver] Migration process has been stopped by user"
            Write-Log "[$Vserver] You could restart the [Migrate] step when ready"
            Write-Log "[$Vserver] Or resynchronize your DR by running a [Resync -ForceRecreate] then a [ConfigureDR] step"
        }
    }
    else {
        Write-LogDebug "Client not ready for Migrate"
        Write-Log "[$Vserver] Migration canceled"
        clean_and_exit 1
    }
    clean_and_exit 0
}

####################################################################################################

if ( $DeleteSource ) {
    $Global:Run_Mode = "DeleteSource"
    Write-LogOnly "SVMTOOL DeleteSource"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $PrimaryClusterName = $NcPrimaryCtrl.Name
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    $SecondaryClusterName = $NcSecondaryCtrl.Name

    #Check_Running_Inside_Same_MCC -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl

    $SourceVserver = Get-NcVserver -Name $Vserver -Controller $NcPrimaryCtrl -ErrorVariable ErrorVar
    if ($? -ne $True) {
        Write-LogError "ERROR : SVM [$Vserver] does not exist on [$PrimaryClusterName]"; clean_and_exit 1
    }
    $SourceState = $SourceVserver.State
    $SourceVserverComment=$SourceVserver.Comment

    $DestVserver = Get-NcVserver -Name $VserverDR -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
    if ($? -ne $True) {
        Write-LogError "ERROR : SVM [$VserverDR] does not exist on [$SecondaryClusterName]"; clean_and_exit 1
    }
    
    $DestState = $DestVserver.State
    if ($SourceState -ne "stopped" -or $DestState -ne "running") {
        Write-LogError "ERROR : SVM [$Vserver] not correctly migrated to destination [$SecondaryClusterName]. Failed to delete on source"
        clean_and_exit 1
    }
    else {
        Write-Warning "[$Vserver] Delete Source SVM cannot be interrupted or rolled back"
        $ASK_WAIT = Read-HostOptions -question "Do you want to completely delete [$Vserver] on [$PrimaryClusterName] ?" -options "y/n" -default "y"
        if ($ASK_WAIT -eq 'y'){
            if ( ( $ret = remove_snapmirror_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR) -ne $True ) {
                Write-LogError "ERROR: remove_snapmirror_dr failed" 
                clean_and_exit 1
            }

            if ( ( remove_vserver_peer -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR ) -ne $True ) {
                Write-LogError "ERROR: remove_vserver_peer failed" 
                return $false
            }
            
            Write-Log "[$VserverDR] Renamed to [$Vserver]"
            Write-LogDebug "Rename-NcVserver -Name $VserverDR -NewName $Vserver -Controller $NcSecondaryCtrl"
            $out = Rename-NcVserver -Name $VserverDR -NewName $Vserver -Controller $NcSecondaryCtrl  -ErrorVariable ErrorVar
            if ( $? -ne $True ) {
                throw "ERROR: Rename-NcVserver failed [$ErrorVar]"
            }
            if($SourceVserverComment.lenght -gt 1){
                Write-LogDebug "Set-NcVserver -Name $Vserver -Controller $NcSecondaryCtrl -Comment $SourceVserverComment"
                $ret=Set-NcVserver -Name $Vserver -Controller $NcSecondaryCtrl -Comment $SourceVserverComment
            }

            Write-Log "[$Vserver] will be deleted on cluster [$PrimaryClusterName]"
            Write-LogDebug "remove_vserver_source -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $Vserver"
            if ( ( $ret = remove_vserver_source -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $Vserver ) -eq $False ) {
                Write-LogError "ERROR: remove_vserver_dr: Unable to remove vserver [$VserverDR]" 
                clean_and_exit 1
            }

            Write-Log "[$Vserver] completely deleted on [$PrimaryClusterName]"
            clean_and_exit 0

        }
        else {
            Write-Log "[$Vserver] will not be deleted on [$PrimaryClusterName]"
            clean_and_exit 0
        }
    }
}

####################################################################################################

if ( $UpdateDR ) {
    $Global:Run_Mode = "UpdateDR"
    Write-LogOnly "SVMTOOL UpdateDR"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }

    if ( $XDPPolicy -ne "" -and $XDPPolicy -ne "MirrorAllSnapshots" ) {
        $ret = Get-NcSnapmirrorPolicy -Name $XDPPolicy -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            Write-Warning "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            $Global:XDPPolicy = ""
        }
    }
    if ( $MirrorSchedule -ne "" -and $MirrorSchedule -ne "none") {
        $ret = Get-NcJobCronSchedule -Name $MirrorSchedule -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "MirrorSchedule [$MirrorSchedule] does not exist on [$SECONDARY_CLUSTER]. Will use no schedule"
            Write-Warning "MirrorSchedule [$MirrorSchedule] does not exist on [$SECONDARY_CLUSTER]. Will use no schedule"
            $Global:MirrorSchedule = "none"
        }
    } 
    # default to hourly
    if ($MirrorSchedule -eq "") {
        $Global:MirrorSchedule = "hourly"
    }    
    # no schedule if Policy Sync or StrictSync is chosen
    if ( ( $Global:XDPPolicy -ne "") -and ( $Global:XDPPolicy -in $("Sync","StrictSync") ) ) {
        $Global:MirrorSchedule = "none"    
    }
    # if ( ( $ret=analyse_junction_path -myController $NcPrimaryCtrl -myVserver $Vserver ) -ne $True ) {
    # Write-LogError "ERROR: analyse_junction_path" 
    # clean_and_exit 1
    # }
    if ( ( $ret = create_update_cron_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl ) -ne $True ) {
        Write-LogError "ERROR: create_update_cron_dr"
    }
    if ( ( $ret = create_update_snap_policy_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR) -ne $True ) {
        Write-LogError "ERROR: create_update_snap_policy_dr"
    }
    if ( ( $ret = check_cluster_peer -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl ) -ne $True ) {
        Write-LogError "ERROR: check_cluster_peer failed"
        clean_and_exit 1
    }

    # This will set $Global:NEED_CIFS_SERVER
    $ret=check_update_CIFS_server_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR

    if ( ($ret = update_vserver_dr -myDataAggr $DataAggr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR -DDR ($DRfromDR.IsPresent) -aggrMatchRegEx $AggrMatchRegex -TemporarySecondaryCifsIp $TemporarySecondaryCifsIp -SecondaryCifsLifMaster $SecondaryCifsLifMaster -SecondaryCifsLifCustomVlan $SecondaryCifsLifCustomVlan -nodeMatchRegEx $NodeMatchRegex -NoSnapmirrorUpdate $NoSnapmirrorUpdate -NoSnapmirrorWait $NoSnapmirrorWait) -ne $True ) {
        Write-LogError "ERROR: update_vserver_dr failed" 
        clean_and_exit 1

    }
    if ( ( $ret = update_CIFS_server_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR ) -ne $True ) {
        Write-Warning "Some CIFS options has not been set on [$VserverDR]"
    }
    if ( ( $ret = svmdr_db_switch_datafiles -myController $NcPrimaryCtrl -myVserver $Vserver -secondaryVserver $VserverDR) -eq $false ) {
        Write-LogError "ERROR: Failed to switch SVMTOOL_DB datafiles" 
        clean_and_exit 1
    }
    if ( ( $ret = save_vol_options_to_voldb -myController $NcPrimaryCtrl -myVserver $Vserver -mySecondaryVserver $VserverDR) -ne $True ) {
        Write-LogError "ERROR: save_vol_options_to_voldb failed"
        clean_and_exit 1
    }
    if ( $AllowQuotaDR -eq "True" ) {
        Write-Log "[$VserverDR] Save quota policy rules to SVMTOOL_DB [$SVMTOOL_DB]" -firstValueIsSpecial
        if ( ( $ret = save_quota_rules_to_quotadb -myPrimaryController $NcPrimaryCtrl -myPrimaryVserver $Vserver -mySecondaryController $NcSecondaryCtrl -mySecondaryVserver $VserverDR ) -ne $True ) {
            Write-LogError "ERROR: save_quota_rules_to_quotadb failed"
            clean_and_exit 1
        }
    }
    clean_and_exit 0
}
####################################################################################################

if ( $CloneDR ) {
    $Global:Run_Mode = "CloneDR"
    Write-LogOnly "SVMTOOL CloneDR"
    $Global:PreserveIdentity=$False

    if( ( $Global:NonInteractive.IsPresent ) `
    -and ( -not ($Global:ForceCloneOriginal.IsPresent) ) `
    -and ( ( $SecondaryCifsLifMaster.Length -eq 0 ) -or ( $TemporarySecondaryCifsIp.length -eq 0 ) ) `
    ){
        Write-LogError "ERROR: With CloneDR in NonInteractive Mode you must provide a SecondaryCifsLifMaster and TemporarySecondaryCifsIp"
        clean_and_exit 1
    }
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    $CloneVserverDR = $($VserverDR + "_clone")
    $ListCloneVserver = Get-NcVserver -Query @{VserverName = $($CloneVserverDR + "*") } -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
    if ( $? -ne $True ) {
        $Return = $False ; throw "ERROR: Get-NcVserver failed [$ErrorVar]" 
    }
    if ($null -eq $ListCloneVserver) {
        $CloneVserverDR += ".0"	
    }
    else {
        $ListCloneVserver = $ListCloneVserver | Sort-Object
        $newNumber = ([Int]($ListCloneVserver[-1].Vserver.split(".")[-1])) + 1
        $CloneVserverDR += $("." + $newNumber)	
        if($Global:ForceCloneOriginal.IsPresent){
            Write-LogError "ERROR: ForceCloneOriginal can only be used if no clone exists. Delete your clones and restart the command"
            clean_and_exit 0
        }
    }
    Write-Log "Create Clone SVM [$CloneVserverDR]"
    if ( ( $ret = create_clonevserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $CloneVserverDR -aggrMatchRegEx $AggrMatchRegex -nodeMatchRegEx $NodeMatchRegex -RootAggr $RootAggr -TemporarySecondaryCifsIp $TemporarySecondaryCifsIp -SecondaryCifsLifMaster $SecondaryCifsLifMaster -SecondaryCifsLifCustomVlan $SecondarCifsLifCustomVlan -ActiveDirectoryCustomOU $ActiveDirectoryCustomOU)[-1] -ne $True ) {
        Write-LogDebug "ERROR: create_clonevserver_dr failed"
        clean_and_exit 1
    }
    if ( ( enable_network_protocol_vserver_dr -myNcController $NcSecondaryCtrl -myVserver $CloneVserverDR ) -ne $True ) {
        Write-LogError "ERROR: Unable to Start all NetWork Protocols in Vserver $mySecondaryVserver $myController"
        $Return = $False
    }
    # if ( ($ret=restore_quota -myController $NcSecondaryCtrl -myVserver $SourceVserver) -ne $True){
    # 	Write-LogDebug "restore_quota return False [$ret]"
    # 	#return $False
    # }
    if ( ( $ret = set_vol_options_from_voldb -myController $NcSecondaryCtrl -myVserver $VserverDR -CloneDR $CloneVserverDR) -ne $True ) {
        Write-LogError "ERROR: set_vol_options_from_voldb failed"
    }
    if ( $AllowQuotaDR -eq "True" ) {
        if ( ( $ret = create_quota_rules_from_quotadb -myController $NcSecondaryCtrl -myVserver $VserverDR -CloneDR $CloneVserverDR) -ne $True ) {
            Write-LogError "ERROR: create_quota_rules_from_quotadb failed"
        }
    }
    clean_and_exit 0
}
####################################################################################################

if ( $SplitCloneDR ) {
    $Global:Run_Mode = "SplitCloneDR"
    Write-LogOnly "SVMTOOL SplitCloneDR"
    # Connect to the Cluster
}
####################################################################################################

if ( $DeleteCloneDR ) {
    $Global:Run_Mode = "DeleteCloneDR"
    Write-LogOnly "SVMTOOL DeleteCloneDR"
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    if ($CloneName.length -gt 1) {
        $CloneVserverList = $CloneName	
    }
    elseif ( $null -eq ( $CloneVserverList = get_vserver_clone -DestinationVserver $VserverDR -mySecondaryController $NcSecondaryCtrl) ) {
        Write-Log "No Vserver Clone from [$VserverDR] found on Cluster [$SECONDARY_CLUSTER]" 
        clean_and_exit 0
    }
    foreach ($CloneVserver in $CloneVserverList) {
        $ANS = Read-HostOptions "[$SECONDARY_CLUSTER] Are you sure you want to delete Vserver Clone [$CloneVserver] ?" "y/n" -default "y"
        if ( $ANS -eq 'y' ) {
            if ( ( $ret = remove_vserver_clone_dr -mySecondaryController $NcSecondaryCtrl -mySecondaryVserver $CloneVserver ) -eq $False ) {
                Write-LogError "ERROR: remove_vserver_dr: Unable to remove Vserver [$VserverDR]" 
                clean_and_exit 1
            }	
        }
    }
    clean_and_exit 0
}
####################################################################################################

if ( $ActivateDR ) {
    $Global:Run_Mode = "ActivateDR"
    Write-LogOnly "SVMTOOL ActivateDR"
    
    if ( test_primary_alive -PrimaryCluster $PRIMARY_CLUSTER -SecondaryCluster $SECONDARY_CLUSTER -PrimaryVserver $Vserver -SecondaryVserver $VserverDR ) {
        $ForceActivate = $False
        Write-Log "[$PRIMARY_CLUSTER] is alive"
    }
    else {
        $ForceActivate = $True
        Write-Warning "[$PRIMARY_CLUSTER] is not alive"
    }
    $ProgressPreference = 'Continue'
    #$ForceActivate = $True
    if ( ( $ret = activate_vserver_dr -currentActiveController $PRIMARY_CLUSTER -currentPassiveController $SECONDARY_CLUSTER -currentActiveVserver $Vserver -currentPassiveVserver $VserverDR -ForceActivate $ForceActivate) -ne $True ) {
        Write-LogError "ERROR: activate_vserver_dr failed"
        clean_and_exit 1
    }
    clean_and_exit 0
}
####################################################################################################

if ( $CreateQuotaDR ) {
    $Global:Run_Mode = "CreateQuotaDR"
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }

    if ( ( $ret = create_quota_rules_from_quotadb -myController $NcSecondaryCtrl -myVserver $VserverDR  ) -ne $True ) {
        Write-LogError "ERROR: create_quota_rules_from_quotadb failed"
        clean_and_exit 1
    }
    clean_and_exit 0
}
####################################################################################################

if ( $ReCreateQuota ) {
    $Global:Run_Mode = "ReCreateQuota"
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }

    if ( ( $ret = create_quota_rules_from_quotadb -myController $NcPrimaryCtrl -myVserver $Vserver  ) -ne $True ) {
        Write-LogError "ERROR: create_quota_rules_from_quotadb failed"
        clean_and_exit 1
    }
    clean_and_exit 0
}
####################################################################################################

if ( $ReActivate ) {
    $Global:Run_Mode = "ReActivate"
    Write-LogOnly "SVMTOOL ReActivate"
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }

    # start primary vserver
    if ( ( (Get-NcVserver -Vserver $Vserver -controller $NcPrimaryCtrl).State) -ne "running") {
        Write-Log "[$Vserver] Start Vserver"
        Write-LogDebug "Start-NcVserver -Name $Vserver -Controller $NcPrimaryCtrl"
        $ret = Start-NcVserver -Name $Vserver -Controller $NcPrimaryCtrl -ErrorVariable ErrorVar
        if ($? -ne $True) {
            Return=$False; Write-Error "Failed to start Vserver [$Vserver] reason [$ErrorVar]"
        }
    }
    if ( ( $XDPPolicy -ne "" ) -and ( $XDPPolicy -ne "MirrorAllSnapshots" ) ) {
        $ret = Get-NcSnapmirrorPolicy -Name $XDPPolicy -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            Write-Warning "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            $Global:XDPPolicy = ""
        }
    }

    # stop secondary cifs server
    # remove secondary cifs server
    $NeedCIFS = $False
    if ( $null -ne (Get-NcCifsServer -VserverContext $VserverDR -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar) ) {
        $NeedCIFS = $True	
    }

    # register secondary cifs with temporary info previously backed
    Write-LogDebug "NeedCIFS = $NeedCIFS"
    if ($NeedCIFS) {
        #add new secondary cifs with primary identity
        Write-Log "[$VserverDR] Restore CIFS server with DR configuration"
        if ( ($ret = Set_CIFS_from_JSON -ToNcController $NcSecondaryCtrl -ToVserver $VserverDR) -eq $False ) {
            Throw "ERROR: Failed to add new CIFS server on [$VserverDR]"
        }
    }

    # restore all secondary LIF address with info previously backed
    Write-Log "[$VserverDR] Restore LIF with DR configuration"
    if ( ($ret = Set_LIF_from_JSON -ToNcController $NcSecondaryCtrl -ToVserver $VserverDR) -eq $False ) {
        Throw "ERROR: Failed to set IP address on [$VserverDR]"	
    }

    # disable all services on secondary SVM
    Write-Log "[$VserverDR] Disable services"
    if ( ($ret = disable_network_protocol_vserver_dr -myController $NcSecondaryCtrl -myVserver $VserverDR -ForceDisable) -eq $False) {
        Throw "ERROR: Failed to disable all services on [$VserverDR]"
    }

    # restore all LIF address on Primary with info previously backed
    Write-Log "[$Vserver] Restore LIF with Primary configuration"
    if ( ($ret = Set_LIF_from_JSON -ToNcController $NcPrimaryCtrl -ToVserver $Vserver -fromSrc) -eq $False ) {
        Throw "ERROR: Failed to set IP address on [$Vserver]"	
    }

    if($null -ne ($CurrentPrimaryCIFSServer=Get-NcCifsServer -VserverContext $Vserver -Controller $NcPrimaryCtrl)){
        Write-Log "[$Vserver] Primary already have a CIFS server [$($CurrentPrimaryCIFSServer.CifsServer)] in state [$($CurrentPrimaryCIFSServer.AdministrativeStatus)]"
        #add new secondary cifs with primary identity
        Write-Log "[$Vserver] Restore CIFS server with previous configuration"
        if ( ($ret = Set_CIFS_from_JSON -ToNcController $NcPrimaryCtrl -ToVserver $Vserver -fromSrc) -eq $False ) {
            Throw "ERROR: Failed to add new CIFS server on [$Vserver]"
        }
    }else{
        Write-Log "No CIFS server on Primary Vserver [$Vserver]"
        # register primary cifs server with info previously backed
        if ($NeedCIFS) {
            #add primary cifs with primary identity
            Write-Log "[$Vserver] Restore CIFS server with Primary configuration"
            if ( ($ret = Add_CIFS_from_JSON -ToNcController $NcPrimaryCtrl -ToVserver $Vserver -fromSrc) -eq $False ) {
                Throw "ERROR: Failed to add new CIFS server on [$Vserver]"
            }
        }
    }

    # create reverse relationship to update data on primary with data presents on secondary
    Write-Log "[$Vserver] Resync data from [$VserverDR]"
    if ( ( $ret = resync_reverse_vserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR) -ne $True ) {
        Write-LogError "ERROR: Resync Reverse error"
        clean_and_exit 1
    }
    if ( ( $ret = wait_snapmirror_dr -NoInteractive -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver ) -ne $True ) { 
        Write-Error "wait_snapmirror_dr failed"  
    }

    # Once data from destination updated on source, we can remove reversed relationships
    if ( ( $ret = remove_snapmirror_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver	 ) -ne $True ) { 
        Write-LogError "ERROR: remove_snapmirror_dr failed" 
        clean_and_exit 1
    }

    # then recreate snapmirror relationship in original direction
    Write-Log "[$Vserver] Restore original SnapMirror relationship to [$VserverDR]"
    $Global:ForceRecreate=$True
    if ( ( $ret = resync_vserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR ) -ne $True ) { 
        Write-LogError "ERROR: Resync failed" 
        clean_and_exit 1
    }
    if ( ( $ret = set_vol_options_from_voldb -myController $NcPrimaryCtrl -myVserver $Vserver ) -ne $True ) {
        Write-LogError "ERROR: set_vol_options_from_voldb failed"
    }
    # enable service on Primary
    if ( ( $ret = enable_network_protocol_vserver_dr -myNcController $NcPrimaryCtrl -myVserver $Vserver ) -ne $True ) {
        Write-LogError "ERROR: Unable to Start all NetWork Protocols in Vserver [$Vserver] on [$NcPrimaryCtrl]"
        $Return = $False
    }
    
    # This will set $Global:NEED_CIFS_SERVER
    $ret=check_update_CIFS_server_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver
    
    $Global:NonInteractive = $true
    if ( ( $ret = update_vserver_dr -myDataAggr $DataAggr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver -DDR ($DRfromDR.IsPresent) -aggrMatchRegEx $AggrMatchRegex -nodeMatchRegEx $NodeMatchRegex -FromReactivate -InReverse) -ne $True ) { 
        Write-LogError "ERROR: update_vserver_dr" 
        clean_and_exit 1 

    }
	
    if ( ( $ret = update_CIFS_server_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver ) -ne $True ) {
        Write-Warning "Some CIFS options has not been set on [$Vserver]"
    }
    if ( $AllowQuotaDR -eq "True" ) {
        if ( ( $ret = create_quota_rules_from_quotadb -myController $NcPrimaryCtrl -myVserver $Vserver  ) -ne $True ) {
            Write-LogError "ERROR: create_quota_rules_from_quotadb failed"
        }
    }

    if ( ($ret = disable_network_protocol_vserver_dr -myController $NcSecondaryCtrl -myVserver $VserverDR -ForceDisable) -eq $False) {
        Throw "ERROR: Failed to disable all services on [$VserverDR]"
    }
    clean_and_exit 0
}
####################################################################################################

if ( $CleanReverse ) {
    $Global:Run_Mode = "CleanReverse"
    Write-LogOnly "SVMTOOL CleanReverse"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    if ($Global:ForceClean -eq $False) {
        if ( ( $ret = check_snapmirror_broken_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver ) -ne $True ) { 
            Write-LogError "ERROR: Failed snapmirror relations bad status unable to clean" 
            clean_and_exit 1
        }
    }
    if ( ( $ret = remove_snapmirror_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver ) -ne $True ) { 
        Write-LogError "ERROR: remove_snapmirror_dr failed" 
        clean_and_exit 1
    }
    clean_and_exit 0
}
####################################################################################################

if ( $Resync ) {
    $Global:Run_Mode = "Resync"
    Write-LogOnly "SVMTOOL Resync"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    $ANS = Read-HostOptions -question "Do you want to update data on vserver [$VserverDR] [$SECONDARY_CLUSTER] with new data available on [$Vserver] [$PRIMARY_CLUSTER] ?" -options "y/n" -default "y"

    if ( $ANS -ne 'y' ) {
        clean_and_exit 0
    }
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred  -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    if ( $XDPPolicy -ne "" -and $XDPPolicy -ne "MirrorAllSnapshots" ) {
        $ret = Get-NcSnapmirrorPolicy -Name $XDPPolicy -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            Write-Warning "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            $Global:XDPPolicy = ""
        }
    }
    $numDestVolRW=(get-ncvol -Controller $NcSecondaryCtrl -VserverContext $VserverDR -Query @{VolumeStateAttributes=@{IsVserverRoot=$false};VolumeIdAttributes=@{Type="rw";StyleExtended="flexvol|flexgroup"}}).count
    if ( ( $numDestVolRW -eq 0 ) -or ( $ForceResync -eq $True -and $numDestVolRW -ge 1 ) -or ( $ForceResync -eq $True )){
        if ( ( $ret = resync_vserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR ) -ne $True ) {
            Write-LogError "ERROR: Resync error"
            clean_and_exit 1
        }
    }else{
        Write-LogWarn "Some volume on [$VserverDR] are Read-Write enable. You must add -ForceResync if you want to forcibly resync a destination volume"
        clean_and_exit 1
    }
    clean_and_exit 0 
}
####################################################################################################

if ( $ResyncReverse ) {
    $Global:Run_Mode = "ResyncReverse"
    Write-LogOnly "SVMTOOL ResyncReverse"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName

    $ANS = Read-HostOptions -question "Do you want to update data on vserver [$Vserver] [$PRIMARY_CLUSTER] ?" -options "y/n" -default "y"
    if ( $ANS -ne 'y' ) {
        clean_and_exit 0
    }

    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    if ( $XDPPolicy -ne "" -and $XDPPolicy -ne "MirrorAllSnapshots" ) {
        $ret = Get-NcSnapmirrorPolicy -Name $XDPPolicy -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            Write-Warning "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            $Global:XDPPolicy = ""
        }
    }
    if ( ( $ret = resync_reverse_vserver_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR) -ne $True ) {
        Write-LogError "ERROR: Resync Reverse error"
        clean_and_exit 1
    }
    clean_and_exit 0 
}
####################################################################################################

if ( $UpdateReverse ) {
    $Global:NonInteractive = $true
    $Global:Run_Mode = "UpdateReverse"
    Write-LogOnly "SVMTOOL UpdateReverse"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    if ( $XDPPolicy -ne "" -and $XDPPolicy -ne "MirrorAllSnapshots" ) {
        $ret = Get-NcSnapmirrorPolicy -Name $XDPPolicy -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            Write-Warning "XDPPolicy [$XDPPolicy] does not exist on [$SECONDARY_CLUSTER]. Will not change XDPPolicy"
            $Global:XDPPolicy = ""
        }
    }
    # if ( ( $ret=analyse_junction_path -myController $NcPrimaryCtrl -myVserver $Vserver) -ne $True ) {
    # Write-LogError "ERROR: analyse_junction_path" 
    # clean_and_exit 1
    # }
    if ( ( $ret = check_cluster_peer -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl ) -ne $True ) {
        Write-LogError "ERROR: check_cluster_peer" 
        clean_and_exit 1
    }

    # This will set $Global:NEED_CIFS_SERVER
    $ret=check_update_CIFS_server_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver

    if ( ( $ret = update_vserver_dr -myDataAggr $DataAggr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver -DDR ($DRfromDR.IsPresent) -TemporarySecondaryCifsIp $TemporarySecondaryCifsIp -SecondaryCifsLifMaster $SecondaryCifsLifMaster -SecondaryCifsLifCustomVlan $SecondaryCifsLifCustomVlan -aggrMatchRegEx $AggrMatchRegex -nodeMatchRegEx $NodeMatchRegex -NoSnapmirrorUpdate $NoSnapmirrorUpdate -NoSnapmirrorWait $NoSnapmirrorWait -InReverse) -ne $True ) { 
        Write-LogError "ERROR: update_vserver_dr" 
        clean_and_exit 1 

    }

    if ( ( $ret = update_CIFS_server_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver ) -ne $True ) {
        Write-Warning "Some CIFS options has not been set on [$Vserver]"
    }
    #if ( ( update_cifs_usergroup -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver ) -ne $True ) {
    #    Write-LogError "ERROR: update_cifs_usergroup failed"
    #	clean_and_exit 1
    #}
    if ( ( $ret = svmdr_db_switch_datafiles -myController $NcSecondaryCtrl -myVserver $VserverDR -secondaryVserver $VserverDR) -eq $false ) {
        Write-LogError "ERROR: Failed to switch SVMTOOL_DB datafiles" 
        clean_and_exit 1
    }
    if ( ( $ret = save_vol_options_to_voldb -myController $NcSecondaryCtrl -myVserver $VserverDR -mySecondaryVserver $Vserver) -ne $True ) {
        Write-LogError "ERROR: save_vol_options_to_voldb failed"
        clean_and_exit 1
    }
    if ( ( $ret = create_update_cron_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl ) -ne $True ) {
        Write-LogError "ERROR: create_update_cron_dr"
    }
    if ( ( $ret = create_update_snap_policy_dr -myPrimaryController $NcSecondaryCtrl -mySecondaryController $NcPrimaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver) -ne $True ) {
        Write-LogError "ERROR: create_update_snap_policy_dr"
    }
    if ( $AllowQuotaDR -eq "True" ) {
        Write-Log "[$VserverDR] Save quota policy rules to SVMTOOL_DB [$SVMTOOL_DB]" -firstValueIsSpecial
        if ( ( $ret = save_quota_rules_to_quotadb -myPrimaryController $NcSecondaryCtrl -myPrimaryVserver $VserverDR -mySecondaryController $NcPrimaryCtrl -mySecondaryVserver $Vserver ) -ne $True ) {
            Write-LogError "ERROR: save_quota_rules_to_quotadb failed"
            clean_and_exit 1
        }
    }
    <# if ( $MirrorSchedule ) {
		Write-LogDebug "Flag MirrorSchedule"
	} else {
		clean_and_exit 0
	} #>
    clean_and_exit 0
}
####################################################################################################

if ( $MirrorSchedule ) {
    $Global:Run_Mode = "MirrorSchedule"
    Write-LogOnly "SVMTOOL MirrorSchedule"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
	
    if ($MirrorSchedule -ne "none") {
        $ret = Get-NcJobCronSchedule -Name $MirrorSchedule -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "MirrorSchedule [$MirrorSchedule] does not exist on [$SECONDARY_CLUSTER]."
            Write-Warning "MirrorSchedule [$MirrorSchedule] does not exist on [$SECONDARY_CLUSTER]."
            clean_and_exit 1
        }
    }

    if ( ( $ret = set_snapmirror_schedule_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $Vserver -mySecondaryVserver $VserverDR -mySchedule $MirrorSchedule ) -ne $True ) {
        Write-LogError "ERROR: set_snapmirror_schedule_dr error"
        clean_and_exit 1
    }
    clean_and_exit 0
}
####################################################################################################

if ( $MirrorScheduleReverse ) {
    $Global:Run_Mode = "MirrorScheduleReverse"
    Write-LogOnly "SVMTOOL MirrorScheduleReverse"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-LogDebug "Connect to cluster [$SECONDARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
	
    if ($MirrorScheduleReverse -ne "none") {
        $ret = Get-NcJobCronSchedule -Name $MirrorScheduleReverse -Controller $NcSecondaryCtrl -ErrorVariable ErrorVar
        if ( $? -ne $True -or $ret.count -eq 0 ) {
            Write-LogDebug "MirrorSchedule [$MirrorScheduleReverse] does not exist on [$SECONDARY_CLUSTER]."
            Write-Warning "MirrorSchedule [$MirrorScheduleReverse] does not exist on [$SECONDARY_CLUSTER]."
            clean_and_exit 1
        }
    }

    if ( ( $ret = set_snapmirror_schedule_dr -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl -myPrimaryVserver $VserverDR -mySecondaryVserver $Vserver -mySchedule $MirrorScheduleReverse ) -ne $True ) {
        Write-LogError "ERROR: set_snapmirror_schedule_dr error"
        clean_and_exit 1
    }
    clean_and_exit 0
}
####################################################################################################

if ( $InternalTest ) {
    Write-LogOnly "SVM InternalTest"
    # Connect to the Cluster
    $myCred = get_local_cDotcred ($PRIMARY_CLUSTER) 
    $tmp_str = $MyCred.UserName
    Write-Log "[test] Connect to cluster [$PRIMARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcPrimaryCtrl = connect_cluster $PRIMARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$PRIMARY_CLUSTER]" 
        clean_and_exit 1
    }
    $myCred = get_local_cDotcred ($SECONDARY_CLUSTER)
    $tmp_str = $myCred.Username
    Write-Log "[test] Connect to cluster [$SECONDARY_CLUSTER] with login [$tmp_str]"
    Write-LogDebug "connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout"
    if ( ( $NcSecondaryCtrl = connect_cluster $SECONDARY_CLUSTER -myCred $MyCred -myTimeout $Global:Timeout ) -eq $False ) {
        Write-LogError "ERROR: Unable to Connect to NcController [$SECONDARY_CLUSTER]" 
        clean_and_exit 1
    }
    Write-Log "[test] Cluster Peer from cluster [$NcPrimaryCtrl] to cluster [$NcSecondaryCtrl]" 
    if ( ( $ret = check_cluster_peer -myPrimaryController $NcPrimaryCtrl -mySecondaryController $NcSecondaryCtrl) -ne $True ) {
        Write-LogError "ERROR: check_cluster_peer failed"
        clean_and_exit 1
    }
    Write-Log "Tests completed successfully" -color green
    # _ADD TEST
    # _ADD TEST
    clean_and_exit 0 
}

Write-LogError "ERROR: No options selected: Use Help Options for more information" 
clean_and_exit 1
