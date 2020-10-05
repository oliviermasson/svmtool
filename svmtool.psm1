# A wrapper to quickly invoke the svmtool, without manually rebuilding the argument string
function invokeSvmtool{
    param(
        [ref]$ParameterList,
        [string]$Action,
        [string]$Add="",
        [string[]]$Drop=""
    )
    $strings = @()
    $switches = @()
    $others = @()
    $bools = @()
    $regexs = @()
    $creds = @()
    foreach ($Parameter in $ParameterList.Value) {
        foreach($v in $Parameter.Values){
            if($v.Name -notin @($Drop)){
                switch($v.ParameterType.Name){

                    "String" {
                        $strings += Get-Variable -Name $v.Name -ErrorAction SilentlyContinue;
                    }
                    # "String[]" {
                    #     $strings += $PSCmdlet.MyInvocation.BoundParameters.($v.Name)
                    # }
                    "Regex" {
                        $regexs += Get-Variable -Name $v.Name -ErrorAction SilentlyContinue;
                    }
                    "SwitchParameter"{
                        $switches += Get-Variable -Name $v.Name -ErrorAction SilentlyContinue;
                    }
                    "Boolean"{
                        $bools += Get-Variable -Name $v.Name -ErrorAction SilentlyContinue;
                    }
                    "PSCredential"{
                        $creds += Get-Variable -Name $v.Name -ErrorAction SilentlyContinue;
                    }
                    default{
                        $others += Get-Variable -Name $v.Name -ErrorAction SilentlyContinue;
                    }
                }
            }
        }
    }
    $args += $strings | ?{$_.Value} | %{if($_.Value -match "\s"){("-{0} `"{1}`"" -f $_.name,$_.value)}else{("-{0} {1}" -f $_.name,$_.value)}}
    $args += $regexs | ?{($null -ne $_.Value)} | ?{($_.Value.ToString())} | %{("-{0} `"{1}`"" -f $_.name,($_.value).ToString())}
    $args += $switches | ?{$_.Value} | %{("-{0}" -f $_.name)}
    $args += $bools | %{("-{0} `${1}" -f $_.name,$_.value)}
    $i=0
    foreach($c in $creds){
        if($null -ne $c.value){
            new-variable -name "cred$i" -value ($c.value)
            $args += ("-{0} `${1}" -f $c.name,"cred$i")
            $i++
        }
    }
    $args += $others | ?{$_.Value} | %{("-{0} {1}" -f $_.name,($_.value -join ","))}
    $arguments = ($args -join " ")
    if($Add){
        $arguments = $Add + " " + $arguments
    }
    if($Action){
        $arguments = "-$Action " + $arguments
    }
    $scriptPath = "$PSScriptRoot\svmtool.ps1"

    <# write-verbose "Invoking svmtool"
    write-verbose "Scriptpath : $scriptPath"
    write-verbose "Arguments : $arguments" #>

    Invoke-Expression "& `"$scriptPath`" $arguments"
}
<#
.Synopsis
    Creates & Updates a relationship between 2 clusters.
.DESCRIPTION
	Creates & Updates a relationship between 2 cluster
    Optionally, creates & updates a vserver relationship (source - destination)
.EXAMPLE
    New-SvmDrConfiguration -Instance c3po-r2d2 -PrimaryCluster r2d2 -SecondaryCluster c3po

    Please Enter your default Primary Cluster Name [r2d2] : 
    Please Enter your default Secondary Cluster Name [c3po] : 
    Please enter local DB directory where config files will be saved for this instance [] : 
    Default Primary Cluster Name:        [r2d2]
    Default Secondary Cluster Name:      [c3po]
    SVMTOOL Configuration DB directory:  []

    Apply new configuration ? [y/n/q] : y

.EXAMPLE
    This example runs the configuration in Non-Interactive mode, and we are also adding a vserver

    New-SvmDrConfiguration -Instance c3po-r2d2 -PrimaryCluster r2d2 -SecondaryCluster c3po -Vserver cifs -VserverDr cifs-dr -QuotaDR -NonInteractive

    Please Enter your default Primary Cluster Name [r2d2] : 
    Autoselecting default [r2d2]
    Please Enter your default Secondary Cluster Name [c3po] : 
    Autoselecting default [c3po]
    Please enter local DB directory where config files will be saved for this instance [] : 
    Autoselecting default []
    Default Primary Cluster Name:        [r2d2]
    Default Secondary Cluster Name:      [c3po]
    SVMTOOL Configuration DB directory:  []

    Apply new configuration ? [y/n/q] : 
    Autoselecting default [y]
    cifs has already existing vserver peer to the cluster [c3po]
    [cifs] -> [cifs-dr]
    Please Enter a Valid Vserver DR name for [cifs-dr] : 
    Autoselecting default [cifs-dr]
    Do you want to Backup Quota for cifs [cifs-dr] ? [y/n] : 
    Autoselecting default [y]
    Vserver DR Name :      [cifs-dr]
    QuotaDR :              [true]

    Apply new configuration ? [y/n/q] : 
    Autoselecting default [y]
#>
function New-SvmDrConfiguration {
    [alias("Update-SvmDrConfiguration")]
    [CmdletBinding()]
    param(
        # A unique name, referencing the relationship between 2 clusters.
        # An instance could manage one or several SVM DR relationships inside the corresponding cluster
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source cluster
        [string]$PrimaryCluster,

        # The destination cluster
        [string]$SecondaryCluster,

        # The source vserver (svm)
        [string]$Vserver,

        # The destination vserver (dr vserver)
        [string]$VserverDr,

        # Enables QuotaDr (backup / restore of quota rules)
        # QuotaDr uses an intermediate quota database
        [switch]$QuotaDR,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,

        [Int32]$Timeout = 60

    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "Setup"
}
<#
.Synopsis
    Initialize a new relationship between 2 vservers.
.DESCRIPTION
	Creates and initializes new relationship between 2 vservers
    This cmdlet can be run multiple times.
.NOTES
    If you want this cmdlet to run non-interactively, you must provide some of the optional parameters.
    Parameters that need to passed in Non-Interactive mode are :
    - credentials to join in AD.  
    - A temporary IP to join in AD.
    - A lif master template (to clone) to join in AD. (merged with the temp ip)
    - A combination of the aggregate options to have smart aggregate selection
    - The Node regex, to make smart node selection
    - 

    Aggregate Resource Selection is in the following order
    1) Regular Expression
    2) Default Aggregate
    3) Aggregate with most available space

    The AggrMatchRegex and NodeMatchRegex work like this :
    - Your regex is first applied to the primary resource
      Then all "regex groups" are replace by wildcards
        Example :
            Assume your source aggregates are :
                - aggr_src_01
                - aggr_src_02
                - ....
            Assume your destination aggregates are :
                - aggr_dst_01
                - aggr_dst_02

            In this case you would want to match the source aggregate to the destination aggregate, 
            but you want "src" replaced by "dst"

            In the case the regex is : aggr_(src)_[0-9]*
                this regex will be evaluated against the source aggregate
                for example : aggr_src_23
                because "src" is wrapped in brackets (= a regex group), it will be wildcarded.

            A new regex will be generated for the destination : aggr_(.*)_23
                this regex will now match the destination aggregate "aggr_dst_23"

        Other examples
            - 1 on 1 match : ".*" => (src = aggr1 ; dst = aggr1) 
            - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (src = ep*snas54_aggr1 ; dst = ep*snas54_aggr1)
            - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)

.EXAMPLE
    This will run interactively, asking for all resources (making suggestions)

    New-SvmDr -Instance c3po-r2d2 -Vserver my_cifs_svm

.EXAMPLE
    This will run interactively, it will use aggr1 for the roolvolume and aggr2 for the datavolumes

    New-SvmDr -Instance c3po-r2d2 -Vserver my_cifs_svm -RootAggr aggr1 -DataAggr aggr2

.EXAMPLE
    This will run interactively, it will use aggr1 for the roolvolume 
    The aggregate for the datavolumes will be asked for, but only once

    New-SvmDr -Instance c3po-r2d2 -Vserver my_cifs_svm -RootAggr aggr1

.EXAMPLE
    This will run interactively, it will use aggr1 for the roolvolume 
    The aggregate for the datavolumes will be asked for, for each volume

    New-SvmDr -Instance c3po-r2d2 -Vserver my_cifs_svm -RootAggr aggr1 -AlwaysChooseDataAggr

.EXAMPLE
    This will run Non-Interactively.  
    Aggregate-match will be 1-on-1 (ex. if volume is on aggr1, then it will search for the same on the secondary).  
    Node-match (for lif-port) will be 1-on-1 (ex. if node 2 is used for source, node 2 will be chose for secondary)
    Lif "cifs" will be cloned on the destination using temporary IP 172.16.123.123 to join in AD (lif will be removed after join)
    $mycreds will be passed as the credentials to join in AD

    New-SvmDr -Instance Default -Vserver cifs -AggrMatchRegex ".*" -NodeMatchRegex "(.*)-[0-9]{2}" -TemporarySecondaryCifsIp 172.16.123.123 -SecondaryCifsLifMaster cifs -ActiveDirectoryCredentials $mycreds -NonInteractive

    [cifs-dr] Check SVM configuration
    [cifs-dr] Create new vserver
    [cifs-dr] Please Select root aggregate on Cluster [c3po]:
            [1] : [aggr1]   [c3po-01]       [28 GB]
    Default found based on regex [aggr1]
    [c3po] Select Aggr 1-1 [1] : -> 1
    [c3po] You have selected the aggregate [aggr1] ? [y/n] : -> y
    [cifs-dr] create vserver dr: [svm_root] [c.utf_8] [c3po] [aggr1]
    [cifs-dr] Check SVM options
    [cifs-dr] Check SVM peering
    [cifs-dr] create vserver peer: [cifs] [r2d2] [cifs-dr] [c3po]
    [cifs-dr] Check Cluster Peering
    [r2d2] Check Cluster Cron configuration
    [cifs-dr] Check SVM Export Policy
    [cifs-dr] Export Policy [default] already exists
    [cifs-dr] Check SVM Efficiency Policy
    [cifs-dr] Sis Policy [auto] already exists and identical
    [cifs-dr] Sis Policy [default] already exists and identical
    [cifs-dr] Sis Policy [inline-only] already exists and identical
    [cifs-dr] Check SVM Firewall Policy
    [cifs-dr] Check Role
    [cifs-dr] Check SVM LIF
    [cifs-dr] Do you want to create the DRP LIF [cifs] [172.16.0.178] [255.255.0.0] [] [r2d2-01] [e0c-16] on cluster [c3po] ? [y/n] : -> y
    [cifs-dr] Please Enter a valid IP Address [172.16.0.178] : -> 172.16.0.178
    [cifs-dr] Please Enter a valid IP NetMask [255.255.0.0] : -> 255.255.0.0
    [cifs-dr] Please Enter a valid Default Gateway Address [] : ->
    Please select secondary node for LIF [cifs] :
            [1] : [c3po-01]
    Default found based on regex [(.*)-01]
    Select Node 1-1 [1] : -> 1
    Please select Port for LIF [cifs] on node [c3po-01]
            [1] : [e0a] role [data] status [up] broadcastdomain []
            [2] : [e0b] role [data] status [up] broadcastdomain []
            [3] : [e0c] role [node_mgmt] status [up] broadcastdomain []
            [4] : [e0c-16] role [node_mgmt] status [up] broadcastdomain [vlan-16]
            [5] : [e0c-17] role [node_mgmt] status [up] broadcastdomain [vlan-17]
            [6] : [e0c-18] role [node_mgmt] status [up] broadcastdomain [vlan-18]
            [7] : [e0c-19] role [node_mgmt] status [up] broadcastdomain [vlan-19]
            [8] : [e0d] role [data] status [up] broadcastdomain [thuis]
    Default found based on exact match [vlan-16][e0c-16]
    Select Port 1-8 [4] : -> 4
    [cifs-dr] Ready to create the LIF [cifs] [172.16.0.178] [255.255.0.0] [] [c3po-01] [e0c-16] ? [y/n] : -> y
    [cifs-dr] Create the LIF [cifs] [172.16.0.178] [255.255.0.0] [] [c3po-01] [e0c-16]
    [cifs-dr] Do you want to create the DRP LIF [cifs2] [192.168.96.178] [255.255.255.0] [] [r2d2-01] [e0d] on cluster [c3po] ? [y/n] : -> y
    [cifs-dr] Please Enter a valid IP Address [192.168.96.178] : -> 192.168.96.178
    [cifs-dr] Please Enter a valid IP NetMask [255.255.255.0] : -> 255.255.255.0
    [cifs-dr] Please Enter a valid Default Gateway Address [] : ->
    Please select secondary node for LIF [cifs2] :
            [1] : [c3po-01]
    Default found based on regex [(.*)-01]
    Select Node 1-1 [1] : -> 1
    Please select Port for LIF [cifs2] on node [c3po-01]
            [1] : [e0a] role [data] status [up] broadcastdomain []
            [2] : [e0b] role [data] status [up] broadcastdomain []
            [3] : [e0c] role [node_mgmt] status [up] broadcastdomain []
            [4] : [e0c-16] role [node_mgmt] status [up] broadcastdomain [vlan-16]
            [5] : [e0c-17] role [node_mgmt] status [up] broadcastdomain [vlan-17]
            [6] : [e0c-18] role [node_mgmt] status [up] broadcastdomain [vlan-18]
            [7] : [e0c-19] role [node_mgmt] status [up] broadcastdomain [vlan-19]
            [8] : [e0d] role [data] status [up] broadcastdomain [thuis]
    Default found based on exact match [thuis][e0d]
    Select Port 1-8 [8] : -> 8
    [cifs-dr] Ready to create the LIF [cifs2] [192.168.96.178] [255.255.255.0] [] [c3po-01] [e0d] ? [y/n] : -> y
    [cifs-dr] Create the LIF [cifs2] [192.168.96.178] [255.255.255.0] [] [c3po-01] [e0d]
    SKIPPING local user create/update in NonInteractive Mode with no default credentials
    [cifs-dr] Check SVM Name Mapping
    [cifs-dr] Check Local Unix User
    [cifs-dr] Modify Local Unix User [nobody] [65535] [65535] [] on [cifs-dr]
    [cifs-dr] Modify Local Unix User [pcuser] [65534] [65534] [] on [cifs-dr]
    [cifs-dr] Modify Local Unix User [root] [0] [1] [] on [cifs-dr]
    [cifs-dr] Check Local Unix Group
    [cifs-dr] Check User Mapping
    [cifs-dr] Check SVM DNS configuration
    SKIPPING LDAP config create/update in NonInteractive Mode
    [cifs-dr] Check SVM NIS configuration
    [cifs-dr] No NIS service found on Vserver [cifs]
    [cifs-dr] Check SVM NFS configuration
    [cifs-dr] No NFS services in vserver [cifs]
    [cifs-dr] Check SVM iSCSI configuration
    [cifs-dr] No ISCSI services in vserver [cifs]
    [cifs-dr] Check SVM CIFS Sever configuration
    [cifs-dr] Add CIFS Server in Vserver DR : [cifs-dr] [c3po]
    [cifs-dr] Please Enter your default Secondary CIFS server Name [CIFS-DR] : -> CIFS-DR
    [cifs-dr] Default Secondary CIFS Name:      [CIFS-DR]
    [cifs-dr] Apply new configuration ? [y/n] : -> y
    [cifs-dr] Create the LIF [tmp_lif_to_join_in_ad_cifs] (cloning from cifs)
    [cifs-dr] LIF [tmp_lif_to_join_in_ad_cifs] is the Temp Cifs LIF, it must be in Administrative up status
    [cifs-dr] Cifs server is joined, Removing tmp lif
    [cifs-dr] Check SVM CIFS Server options
    WARNING: 'KerberosKdcTimeout' parameter is not available for Data ONTAP 9.0 and up. Ignoring 'KerberosKdcTimeout'.
    [cifs-dr] Check SVM iGroup configuration
    [cifs-dr] No igroup found on cluster [r2d2]
    [cifs-dr] Check SVM VSCAN configuration
    [cifs-dr] Check SVM FPolicy configuration
    [cifs-dr] Check SVM Volumes
    [cifs-dr] Ignore volume [svm_root]
    [cifs-dr] Please Select a destination DATA aggregate for [vol1] on Cluster [c3po]:
            [1] : [aggr1]   [c3po-01]       [28 GB]
    Default found based on regex [aggr1]
    [c3po] Select Aggr 1-1 [1] : -> 1
    [c3po] You have selected the aggregate [aggr1] ? [y/n] : -> y
    [cifs-dr] Create new volume DR: [vol1]
    [cifs-dr] Check SVM Volumes options
    [cifs-dr] Check SVM QOS configuration
    [cifs-dr] Create SVM SnapMirror configuration
    [cifs-dr] VFR mode is set to [True]
    [cifs-dr] Create VF SnapMirror [cifs:vol1] -> [cifs-dr:vol1]
    [cifs-dr] Check SVM Snapshot Policy
    [cifs-dr] Do you want to wait the end of snapmirror transfers and mount all volumes and map LUNs cifs-dr now ? [y/n] : -> n
    WARNING: Do not forget to run UpdateDR (with -DataAggr and/or -AggrMatchRegex option) frequently to update SVM DR and mount all new volumes
    [cifs] Switch Datafiles
    [cifs] Save volumes options
    [cifs-dr] Save quota policy rules to SVMTOOL_DB [c:\jumpstart\svmtool]
    [cifs-dr] Save Quota rules

#>
function New-SvmDr {
    [alias("Initialize-SvmDr")]
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Destination Vserver Name
        [Parameter(Mandatory = $false)]
        [string]$VserverDR=$null,

        # Optional, makes an aggregate suggestion for the rootvolume
        [Parameter(Mandatory = $false)]
        [string]$RootAggr=$null,

        # Optional, makes an aggregate suggestion for the datavolumes
        [Parameter(Mandatory = $false)]
        [string]$DataAggr=$null,

        # Enables individual aggregate selection for each individual volume
        # Is default enabled in Non-Interactive Mode
        [switch]$AlwaysChooseDataAggr,

        # Enables individual volume selection, in case not every volume needs to be snapmirrored
        [switch]$SelectVolume,

        # Allows to create a second relation from a DR destination
        [switch]$DRfromDR,

        # Optional, sets the XDP Policy
        # Defaults to MirrorAllSnapshots
        [string]$XDPPolicy,

        # Optional, sets the Mirror schedule
        # Defaults to hourly
        # use "none" to have no schedule
        [string]$MirrorSchedule,        

        # Optional, A regular expression to map source aggregate to destination aggregate
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - 1 on 1 match : ".*" => (src = * ; dst = src)
        #   - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (src = ep*snas54_aggr1 ; dst = ep*snas54_aggr1)
        #   - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)
        [regex]$AggrMatchRegex,

        # Optional, A regular expression to map source node to destination node (for lif-port selection)
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)
        [regex]$NodeMatchRegex,

        # Enables intensive source quota error checking and (potential) correcting
        # before saving to the Quota Database (SVMTOOL_DB)
        [switch]$CorrectQuotaError,

        # Ignores Qtree Exports
        [switch]$IgnoreQtreeExportPolicy,

        # Used in combination with the CorrectQuotaError switch
        # Skips Quota checking for volumes with quota off
        [switch]$IgnoreQuotaOff,

        # Used in combination with the CorrectQuotaError switch
        # Deletes a quota rule with errors
        [switch]$ForceDeleteQuota,

        # Enables the force-recreation of snapmirror relations
        [switch]$ForceRecreate,

        # Optional, this SvmDr solution cannot transfer the passwords of local users (cifs, cluster)
        # In Non-Interactive Mode, the script cannot create missing users
        # If you pass this parameter, the password will used to create missing users
        [pscredential]$DefaultLocalUserCredentials,

        # Optional, this SvmDr solution cannot transfer the passwords for LDAP Binding
        # In Non-Interactive Mode, the script cannot bind to new LDAP server
        # If you pass this parameter, the password will be used to Bind LDAP server
        [pscredential]$DefaultLDAPCredentials,

        # Optional, when running in Non-Interactive mode, this script cannot prompt for AD credentials
        # Use this parameter to join the dr vserver in AD without interaction
        [pscredential]$ActiveDirectoryCredentials,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # By passing an temporary ip-address and in combination with parameter "SecondaryCifsLifMaster"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$TemporarySecondaryCifsIp,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif that is passed in this parameter (using same port and options)
        # Use this in combination with parameter "TemporarySecondaryCifsIp"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$SecondaryCifsLifMaster,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif used in the parameter SecondaryCifsLifMaster
        # A temporary lif will be created to join the vserver dr in AD
        # This parameter will override the vlan in which this temp lif is created
        [string]$SecondaryCifsLifCustomVlan,

        # When the dr cifs server is joined AD, you can override in which OU this happens with this parameter
        [string]$ActiveDirectoryCustomOU,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Force creation of DP Snapmirror relationship instead of default XDP
        [Parameter(Mandatory = $false)]
        [ValidateSet("DP", "XDP")]
        [string]$SnapmirrorType="XDP",
		
		# Allows to force a TieringPolicy on destination volume (when FabricPool available)
        [Parameter(Mandatory = $false)]
        [ValidateSet("auto", "snapshot-only", "all", "none")]
        [string]$TieringPolicy = $null,

        # Define Network Identity preservation mode on Destination
        # Default = True
        #         so IP addresses and CIFS server identity will be preserved on destination,
        #         so destination LIF will be created with APIPA addresses
        #         If identity is not preserved, then you must provide different IP addresses and CIFS server identity on Destination SVM
        [Parameter(Mandatory = $false)]
        [bool]$PreserveIdentity=$True,

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "ConfigureDR"
}
<#
.Synopsis
    Shows all registered relationships
.DESCRIPTION
	Shows all registered relationships
    Both cluster & vserver
.EXAMPLE
    Show-SvmDrConfiguration

    CONFBASEDIR [C:\Scripts\SVMTOOL\etc\]

    Instance [Default]: CLUSTER PRIMARY     [r2d2]
    Instance [Default]: CLUSTER SECONDARY   [c3po]
    Instance [Default]: LOCAL DB            [c:\jumpstart\svmtool]
    Instance [Default]: INSTANCE MODE       [DR]
    Instance [Default]: SVM DR Relation     [cifs -> cifs-dr]

.EXAMPLE
    This will reset all passwords and prompt for credentials

    Show-SvmDrConfiguration -ResetPassword

    CONFBASEDIR [C:\Scripts\SVMTOOL\etc\]

    Instance [Default]: CLUSTER PRIMARY     [r2d2]
    Instance [Default]: CLUSTER SECONDARY   [c3po]
    Instance [Default]: LOCAL DB            [c:\jumpstart\svmtool]
    Instance [Default]: INSTANCE MODE       [DR]
    Instance [Default]: SVM DR Relation     [cifs -> cifs-dr]

    Login for cluster [r2d2]
    Enter login: admin
    Login for cluster [c3po]
    Enter login: admin
    Do you really want to reset Credentials for SLASH.LOCAL ? [y/n] : y
    Login for [SLASH.LOCAL]
    [SLASH.LOCAL] Enter login: administrator

#>
function Show-SvmDrConfiguration {
    [CmdletBinding()]
    param(

        # Enables password reset (the script will prompt for new passwords)
        # If WfaIntegration is enabled, passwords will come from WFA server
        [switch]$ResetPassword,

        # Optional Credential Name
        # If provided, only this credential will be reseted if associated with ResetPassword switch parameter
        [Parameter(Mandatory = $false)]
        [string]$CredName=$null,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration

    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "ListInstance"
}
<#
.Synopsis
    Shows a vserver relationship
.DESCRIPTION
	Shows a vserver relationship
    Allong with the details, such as snapmirrors, ...
.EXAMPLE
    Show-SvmDr -Instance Default -Vserver cifs -Lag -Schedule

    PRIMARY SVM      :
    ------------------
    Cluster Name           : [r2d2]
    Vserver Name           : [cifs]
    Vserver Root Volume    : [svm_root]
    Vserver Root Security  : [unix]
    Vserver Language       : [c.utf_8]
    Vserver Protocols      : [nfs cifs fcp iscsi ndmp]
    Vserver NsSwitch       : [hosts] [files dns]
    Vserver NsSwitch       : [group] [files]
    Vserver NsSwitch       : [passwd] [files]
    Vserver NsSwitch       : [netgroup] [files]
    Vserver NsSwitch       : [namemap] [files]
    Logical Interface      : [up] [cifs] [172.16.0.178] [255.255.0.0] [] [r2d2-01] [e0c-16]
    Logical Interface      : [up] [cifs2] [192.168.96.178] [255.255.255.0] [] [r2d2-01] [e0d]
    NFS Services           : [no]
    CIFS Services          : [up]
    ISCSI Services         : [no]

    SECONDARY SVM (DR)   :
    ----------------------
    Cluster Name           : [c3po]
    Vserver Name           : [cifs-dr]
    Vserver Root Volume    : [svm_root]
    Vserver Root Security  : [unix]
    Vserver Language       : [c.utf_8]
    Vserver Protocols      : [nfs cifs fcp iscsi ndmp]
    Vserver NsSwitch       : [hosts] [files dns]
    Vserver NsSwitch       : [group] [files]
    Vserver NsSwitch       : [passwd] [files]
    Vserver NsSwitch       : [netgroup] [files]
    Vserver NsSwitch       : [namemap] [files]
    Logical Interface      : [down] [cifs] [172.16.0.178] [255.255.0.0] [] [c3po-01] [e0c-16]
    Logical Interface      : [down] [cifs2] [192.168.96.178] [255.255.255.0] [] [c3po-01] [e0d]
    NFS Services           : [no]
    CIFS Services          : [down]
    ISCSI Services         : [no]

    VOLUME LIST : 
    --------------
    Primary:   [vol1:unix:c.utf_8:default:/vol1] [rw]
    Secondary: [vol1:unix:c.utf_8:default:/vol1] [dp]

    SNAPMIRROR LIST :
    -----------------
    Status relation [cifs:vol1]   [cifs-dr:vol1]  [XDP] [MirrorAllSnapshots] [idle]  [snapmirrored]  [10/10/2018 00:10:04][daily]                              
 
    REVERSE SNAPMIRROR LIST :
    ---------------------------

#>
function Show-SvmDr {
    [CmdletBinding()]
    param(

        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,


        # Enables display of lag information
        [switch]$Lag,

        # Enables display of schedule information
        [switch]$Schedule,

        # Display only SVM informations
        [switch]$NoVolumeDetail,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "ShowDR"
}
<#
.Synopsis
    Updates relationships between 2 vservers.
.DESCRIPTION
	Updates relationships between 2 vserver.
    It creates missing parts when possible (just like New-SvmDr does)
    It triggers snapmirror updates
    This cmdlet always run in Non-Interactive Mode and is created to be scheduled.
.NOTES
    If new volumes or lifs are detected, the automated resource selection kicks in.

    Aggregate Resource Selection is in the following order
    1) Regular Expression
    2) Default Aggregate
    3) Aggregate with most available space

    The AggrMatchRegex and NodeMatchRegex work like this :
    - Your regex is first applied to the primary resource
      Then all "regex groups" are replace by wildcards
        Example :
            Assume your source aggregates are :
                - aggr_src_01
                - aggr_src_02
                - ....
            Assume your destination aggregates are :
                - aggr_dst_01
                - aggr_dst_02

            In this case you would want to match the source aggregate to the destination aggregate, 
            but you want "src" replaced by "dst"

            In the case the regex is : aggr_(src)_[0-9]*
                this regex will be evaluated against the source aggregate
                for example : aggr_src_23
                because "src" is wrapped in brackets (= a regex group), it will be wildcarded.

            A new regex will be generated for the destination : aggr_(.*)_23
                this regex will now match the destination aggregate "aggr_dst_23"

        Other examples
            - 1 on 1 match : ".*" => (src = aggr1 ; dst = aggr1) 
            - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (src = ep*snas54_aggr1 ; dst = ep*snas54_aggr1)
            - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)

.EXAMPLE

    Update-SvmDr -Instance Default -Vserver cifs

    [r2d2] Check Cluster Cron configuration
    [cifs-dr] Check SVM Snapshot Policy
    [cifs-dr] Check SVM options
    [cifs-dr] Update relation [cifs:vol1] [cifs-dr:vol1]
    [cifs-dr] Status relation [cifs:vol1] [cifs-dr:vol1]:[transferring] [snapmirrored] [4.9581642]
    [cifs-dr] Check SVM iGroup configuration
    [cifs-dr] No igroup found on cluster [r2d2]
    [cifs-dr] Check SVM Export Policy
    [cifs-dr] Export Policy [default] already exists
    [cifs-dr] Check SVM Efficiency Policy
    [cifs-dr] Sis Policy [auto] already exists and identical
    [cifs-dr] Sis Policy [default] already exists and identical
    [cifs-dr] Sis Policy [inline-only] already exists and identical
    [cifs-dr] Check SVM Firewall Policy
    [cifs-dr] Check SVM LIF
    [cifs-dr] Network Interface [cifs] already exists
    [cifs-dr] Network Interface [cifs2] already exists
    SKIPPING local user create/update in NonInteractive Mode with no default credentials
    SKIPPING local cifs user create/update in NonInteractive Mode with no default credentials
    [cifs-dr] Check SVM Name Mapping
    [cifs-dr] Check Local Unix User
    [cifs-dr] Modify Local Unix User [nobody] [65535] [65535] [] on [cifs-dr]
    [cifs-dr] Modify Local Unix User [pcuser] [65534] [65534] [] on [cifs-dr]
    [cifs-dr] Modify Local Unix User [root] [0] [1] [] on [cifs-dr]
    [cifs-dr] Check Local Unix Group
    [cifs-dr] Check User Mapping
    [cifs-dr] Check SVM VSCAN configuration
    [cifs-dr] Check SVM FPolicy configuration
    [cifs-dr] Check SVM Volumes options
    [cifs-dr] Check SVM Volumes Junction-Path configuration
    [cifs-dr] Modify Junction Path for [vol1]: from [] to [/vol1]
    [cifs-dr] Check SVM DNS configuration
    [cifs-dr] Check SVM NIS configuration
    [cifs-dr] No NIS service found on Vserver [cifs]
    [cifs-dr] Check SVM NFS configuration
    [cifs-dr] No NFS services in vserver [cifs]
    [cifs-dr] Check SVM iSCSI configuration
    [cifs-dr] No ISCSI services in vserver [cifs]
    [cifs-dr] Check SVM CIFS shares
    [cifs-dr] Create share [vol1]
    [cifs-dr] Check Cifs Symlinks
    [cifs-dr] Check LUN Mapping
    [cifs-dr] Check LUN Serial Number
    [cifs-dr] Check SVM QOS configuration
    [cifs-dr] Check Role
    [cifs-dr] Check Qtree Export Policy
    [cifs-dr] Check SVM CIFS Server options
    WARNING: 'KerberosKdcTimeout' parameter is not available for Data ONTAP 9.0 and up. Ignoring 'KerberosKdcTimeout'.
    [cifs] Switch Datafiles
    [cifs] Save volumes options
    [cifs-dr] Save quota policy rules to SVMTOOL_DB [c:\jumpstart\svmtool]
    [cifs-dr] Save Quota rules

#>
function Update-SvmDr {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Optional, makes an aggregate suggestion for the datavolumes
        [string]$DataAggr,

        # Optional, A regular expression to map source aggregate to destination aggregate
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - 1 on 1 match : ".*" => (src = * ; dst = src)
        #   - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (src = ep*snas54_aggr1 ; dst = ep*snas54_aggr1)
        [regex]$AggrMatchRegex,

        # Optional, A regular expression to map source node to destination node (for lif-port selection)
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)
        [regex]$NodeMatchRegex,

        # Optional, sets the XDP Policy
        # Defaults to MirrorAllSnapshots
        [string]$XDPPolicy,

        # Optional, sets the Mirror schedule
        # Defaults to hourly
        # use "none" to have no schedule
        [string]$MirrorSchedule,                

        # Enables intensive source quota error checking and (potential) correcting
        # before saving to the Quota Database (SVMTOOL_DB)
        [switch]$CorrectQuotaError,

        # Ignores Qtree Exports
        [switch]$IgnoreQtreeExportPolicy,

        # Used in combination with the CorrectQuotaError switch
        # Skips Quota checking for volumes with quota off
        [switch]$IgnoreQuotaOff,

        # Used in combination with the CorrectQuotaError switch
        # Deletes a quota rule with errors
        [switch]$ForceDeleteQuota,

        # Enables the force-recreation of snapmirror relations
        [switch]$ForceRecreate,

        # Omits snapmirror updates during the update cycle (=faster)
        # All snapmirror updates are assumed to be handles by the attached snapmirror schedule
        [switch]$NoSnapmirrorUpdate,

        # Omits snapmirror wait after snapmirror create and update (=faster)
        [switch]$NoSnapmirrorWait,

        # Skip vscan and fpolicy actions
        [switch]$SkipVscanFpolicy,

        # Optional, this SvmDr solution cannot transfer the passwords of local users (cifs, cluster)
        # In Non-Interactive Mode, the script cannot create missing users
        # If you pass this parameter, the password will used to create missing users
        [pscredential]$DefaultLocalUserCredentials,

        # Optional, when running in Non-Interactive mode, this script cannot prompt for AD credentials
        # Use this parameter to join the dr vserver in AD without interaction
        [pscredential]$ActiveDirectoryCredentials,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # By passing an temporary ip-address and in combination with parameter "SecondaryCifsLifMaster"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$TemporarySecondaryCifsIp,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif that is passed in this parameter (using same port and options)
        # Use this in combination with parameter "TemporarySecondaryCifsIp"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$SecondaryCifsLifMaster,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif used in the parameter SecondaryCifsLifMaster
        # A temporary lif will be created to join the vserver dr in AD
        # This parameter will override the vlan in which this temp lif is created
        [string]$SecondaryCifsLifCustomVlan,
		
		# Allows to force a TieringPolicy on destination volume (when FabricPool available)
        [Parameter(Mandatory = $false)]
        [ValidateSet("auto", "snapshot-only", "all", "none")]
        [string]$TieringPolicy = $null,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Force creation of DP Snapmirror relationship instead of default XDP
        [Parameter(Mandatory = $false)]
        [ValidateSet("DP", "XDP")]
        [string]$SnapmirrorType="XDP",

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "UpdateDR"
}
<#
.Synopsis
    Removes the relationships between 2 vservers.
.DESCRIPTION
	Removes the relationships between 2 vservers.
    It destroys the snapmirrors and the destination vserver

.EXAMPLE

    Remove-SvmDr -Instance Default -Vserver cifs

    Do you really want to delete SVM_DR [cifs-dr] from secondary cluster  [c3po] ? [y/n] : y
    remove snapmirror relation for volume [cifs:vol1] [cifs-dr:vol1]
    Release Relation [cifs:vol1] [cifs-dr:vol1]
    Remove volume [vol1] from [cifs-dr]
    Remove root volume [svm_root]

#>
function Remove-SvmDr {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "DeleteDR"
}
<#
.Synopsis
    Activates Svm Dr
.DESCRIPTION
    Activates Svm Dr
    Test if source vserver is still alive
    If still alive will prompt if you want to swith production from source to destination vserver
    If not alive will switch automaticaly production on DR with source identity
    It will break all snapmirror relations
    It will bring the DR vserver online (and the lifs) with source identity
    It will bring the source vserver offline

.EXAMPLE

    Invoke-SvmDrActivate -Instance COT3-AFF -Vserver OMSHIFT -NonInteractive

    [cot3] is alive
    Do You really want to activate SVM [OMSHIFT_DR] from cluster [aff] ? [y/n] : y
    [OMSHIFT_DR] Break relation [OMSHIFT:oc_140_wordpress_mysql_disk_ce4c3] ---> [OMSHIFT_DR:oc_140_wordpress_mysql_disk_ce4c3]
    [OMSHIFT_DR] Break relation [OMSHIFT:trident_demowordpress_mysql_disk_a8976] ---> [OMSHIFT_DR:trident_demowordpress_mysql_disk_a8976]
    [OMSHIFT_DR] Break relation [OMSHIFT:trident_demowordpress_wordpress_disk_a89e4] ---> [OMSHIFT_DR:trident_demowordpress_wordpress_disk_a89e4]
    [OMSHIFT_DR] Break relation [OMSHIFT:trident_etcd_trident] ---> [OMSHIFT_DR:trident_etcd_trident]
    [OMSHIFT] Remove LIF [data]
    [OMSHIFT] Remove LIF [iscsi]
    [OMSHIFT] stop Vserver
    [OMSHIFT_DR] Modify LIF
    [OMSHIFT_DR] Configure LIF [data] with [10.65.176.92] [255.255.255.0] [up]
    [OMSHIFT_DR] Configure LIF [iscsi] with [10.65.176.93] [255.255.255.0] [up]
    [OMSHIFT_DR] Start LIF [data]
    [OMSHIFT_DR] Start LIF [iscsi]
    [OMSHIFT_DR] Start iSCSI
    [OMSHIFT_DR] Start NFS
    [OMSHIFT_DR] No CIFS services in vserver
    [OMSHIFT_DR] Set volumes options from SVMTOOL_DB [C:\Scripts\SVMTOOL]
    [OMSHIFT_DR] Create Quota policy rules from SVMTOOL_DB [C:\Scripts\SVMTOOL]

#>
function Invoke-SvmDrActivate {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Enables Snapshot Policy Update
        # The destination will, after DR activation, inherit the original snapshot policies
        [switch]$ForceUpdateSnapPolicy,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Preserve or not Network Identity (IP addresses and CIFS server name) of Source on Destination
        [Parameter(Mandatory = $false)]
        [bool]$PreserveIdentity=$True,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Force to use CIFS modify method, instead of delete/recreate when CIFS server name need to be changed
        [switch]$NoCifsDeleteMethod,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "ActivateDR"
}
<#
.Synopsis
    Resyncs Svm Dr relations
.DESCRIPTION
	Resyncs Svm Dr relations
    Will try to re-establisch the snapmirrors relations
    If needed, a force recreate is possible

.NOTES
    This only reflects the snapmirror relations
    Not the status of the vserver nor the lifs
    If you want to reset the entire svm, use Invoke-SvmDrRecoverFromDr

.EXAMPLE

    Invoke-SvmDrResync -Instance Default -Vserver cifs

    Do you want to erase data on vserver [cifs-dr] [c3po] ? [y/n] : y
    Resync relationship [cifs:vol1] [cifs-dr:vol1] 

#>
function Invoke-SvmDrResync {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Enables the force-recreation of snapmirror relations
        [switch]$ForceRecreate,

        # Enables the force-resync of snapmirror relations
        # Even if some destination volume are Read/Write enabled
        [switch]$ForceResync,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Optional, sets the XDP Policy
        # Defaults to MirrorAllSnapshots
        [string]$XDPPolicy,

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "Resync"
}
<#
.Synopsis
    Resyncs Svm Dr relations in the opposite direction
.DESCRIPTION
	Resyncs Svm Dr relations in the opposite direction (destination -> source)
    Will try to re-establisch the snapmirrors relations
    If needed, a force recreate is possible

.NOTES
    This only reflects the snapmirror relations
    Not the status of the vserver nor the lifs

    This step is typically performed after an Invoke-SvmDrActivate
    Once the source is back up and running, we reverse the relations 
    Next step would be Update-SvmDrReverse

.EXAMPLE

    Invoke-SvmDrResyncReverse -Instance Default -Vserver cifs -NonInteractive

    Do you want to erase data on vserver [cifs] [r2d2] ? [y/n] : -> y
    Create Reverse VF SnapMirror [c3po://cifs-dr/vol1] -> [r2d2://cifs/vol1]
    Reverse resync [c3po://cifs-dr/vol1] -> [r2d2://cifs/vol1]

#>
function Invoke-SvmDrResyncReverse {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Enables the force-recreation of snapmirror relations
        [switch]$ForceRecreate,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Snapmirror Policy to use
        [Parameter(Mandatory = $false)]
        [string]$XDPPolicy,
        
        <# # Force creation of DP Snapmirror relationship instead of default XDP
        [Parameter(Mandatory = $false)]
        [ValidateSet("DP", "XDP")]
        [string]$SnapmirrorType="XDP", #>

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "ResyncReverse"
}
<#
.Synopsis
    Updates relationships between 2 vservers in the opposite direction.
.DESCRIPTION
	Updates relationships between 2 vserver in the opposite direction (destination -> source).
    It creates missing parts when possible
    It triggers snapmirror updates (reversed)
    This cmdlet always run in Non-Interactive Mode and is created to be scheduled after a disaster
    The idea is to copy the changes back to the source, during a disaster

    This command is a logical step after an Invoke-SvmDrResyncReverse
    The next logical step would be Invoke-SvmDrRecoverFromDr

.NOTES
    If new volumes or lifs are detected, the automated resource selection kicks in.

    Aggregate Resource Selection is in the following order
    1) Regular Expression
    2) Default Aggregate
    3) Aggregate with most available space

    The AggrMatchRegex and NodeMatchRegex work like this :
    - Your regex is first applied to the primary resource
      Then all "regex groups" are replace by wildcards
        Example :
            Assume your source aggregates are :
                - aggr_src_01
                - aggr_src_02
                - ....
            Assume your destination aggregates are :
                - aggr_dst_01
                - aggr_dst_02

            In this case you would want to match the source aggregate to the destination aggregate, 
            but you want "src" replaced by "dst"

            In the case the regex is : aggr_(src)_[0-9]*
                this regex will be evaluated against the source aggregate
                for example : aggr_src_23
                because "src" is wrapped in brackets (= a regex group), it will be wildcarded.

            A new regex will be generated for the destination : aggr_(.*)_23
                this regex will now match the destination aggregate "aggr_dst_23"

        Other examples
            - 1 on 1 match : ".*" => (src = aggr1 ; dst = aggr1) 
            - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (src = ep*snas54_aggr1 ; dst = ep*snas54_aggr1)
            - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)

.EXAMPLE

    Update-SvmDrReverse -Instance Default -Vserver cifs

    [cifs] Check SVM options
    [cifs] Update relation [cifs-dr:vol1] [cifs:vol1]
    [cifs] Status relation [cifs-dr:vol1] [cifs:vol1]:[transferring] [snapmirrored] [250.047052]
    [cifs] Check SVM iGroup configuration
    [cifs] No igroup found on cluster [c3po]
    [cifs] Check SVM Export Policy
    [cifs] Export Policy [default] already exists
    [cifs] Check SVM Efficiency Policy
    [cifs] Sis Policy [auto] already exists and identical
    [cifs] Sis Policy [default] already exists and identical
    [cifs] Sis Policy [inline-only] already exists and identical
    [cifs] Check SVM Firewall Policy
    [cifs] Check SVM LIF
    [cifs] Network Interface [cifs] already exists
    [cifs] Network Interface [cifs2] already exists
    SKIPPING local user create/update in NonInteractive Mode with no default credentials
    SKIPPING local cifs user create/update in NonInteractive Mode with no default credentials
    [cifs] Check SVM Name Mapping
    [cifs] Check Local Unix User
    [cifs] Modify Local Unix User [nobody] [65535] [65535] [] on [cifs]
    [cifs] Modify Local Unix User [pcuser] [65534] [65534] [] on [cifs]
    [cifs] Modify Local Unix User [root] [0] [1] [] on [cifs]
    [cifs] Check Local Unix Group
    [cifs] Check User Mapping
    [cifs] Check SVM VSCAN configuration
    [cifs] Check SVM FPolicy configuration
    [cifs] Check SVM Volumes options
    [cifs] Check SVM Volumes Junction-Path configuration
    [cifs] Check SVM DNS configuration
    [cifs] Check SVM NIS configuration
    [cifs] No NIS service found on Vserver [cifs-dr]
    [cifs] Check SVM NFS configuration
    [cifs] No NFS services in vserver [cifs-dr]
    [cifs] Check SVM iSCSI configuration
    [cifs] No ISCSI services in vserver [cifs-dr]
    [cifs] Check SVM CIFS shares
    [cifs] Check Cifs Symlinks
    [cifs] Check LUN Mapping
    [cifs] Check LUN Serial Number
    [cifs] Check SVM QOS configuration
    [cifs] Check Role
    [cifs] Check Qtree Export Policy
    [cifs] Check SVM CIFS Server options
    WARNING: 'KerberosKdcTimeout' parameter is not available for Data ONTAP 9.0 and up. Ignoring 'KerberosKdcTimeout'.
    [cifs-dr] Switch Datafiles
    [cifs-dr] Save volumes options
    [c3po] Check Cluster Cron configuration
    [cifs] Check SVM Snapshot Policy
    [cifs-dr] Save quota policy rules to SVMTOOL_DB [c:\jumpstart\svmtool]
    [cifs] Save Quota rules


#>
function Update-SvmDrReverse {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Optional, makes an aggregate suggestion for the datavolumes
        [string]$DataAggr,

        # Optional, A regular expression to map aggregate names
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - 1 on 1 match : ".*" => (src = dst)
        #   - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (ep*snas54_aggr1)
        [regex]$AggrMatchRegex,

        # Optional, A regular expression to map node-names (for lif-port selection)
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - node number match : "(.*)-[0-9]{2}" => (example : *-03)
        [regex]$NodeMatchRegex,

        # Enables intensive source quota error checking and (potential) correcting
        # before saving to the Quota Database (SVMTOOL_DB)
        [switch]$CorrectQuotaError,

        # Ignores Qtree Exports
        [switch]$IgnoreQtreeExportPolicy,

        # Used in combination with the CorrectQuotaError switch
        # Skips Quota checking for volumes with quota off
        [switch]$IgnoreQuotaOff,

        # Used in combination with the CorrectQuotaError switch
        # Deletes a quota rule with errors
        [switch]$ForceDeleteQuota,

        # Enables the force-recreation of snapmirror relations
        [switch]$ForceRecreate,

        # Omits snapmirror updates during the update cycle (=faster)
        # All snapmirror updates are assumed to be handles by the attached snapmirror schedule
        [switch]$NoSnapmirrorUpdate,

        # Omits snapmirror wait after snapmirror create and update (=faster)
        [switch]$NoSnapmirrorWait, 
        
        # Skip vscan and fpolicy actions
        [switch]$SkipVscanFpolicy,             

        # Optional, this SvmDr solution cannot transfer the passwords of local users (cifs, cluster)
        # In Non-Interactive Mode, the script cannot create missing users
        # If you pass this parameter, the password will used to create missing users
        [pscredential]$DefaultLocalUserCredentials,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Snapmirror Policy to use
        [Parameter(Mandatory = $false)]
        [string]$XDPPolicy,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "UpdateReverse"
}
<#
.Synopsis
    Re-establishes the orginal Svm Dr Relation
.DESCRIPTION
	Re-establishes the orginal Svm Dr Relation (ReActive)
    It will break all reverse snapmirror relations
    It will bring the source vserver back online (and the lifs)
    It will bring the destination (dr) vserver offline (unless ForceActivate is used)
    It will start a resync of the snapmirrors (source -> destination)

.NOTES
    The original action was called "ReActivate"
    But it has been rename to "RecoverFromDr"

    Since this step is important, a few aliases have been added 
    - Invoke-SvmDrReActivate
    - Invoke-SvmDrActivateReverse
    - Invoke-SvmDrRecover


.EXAMPLE

    Invoke-SvmDrRecoverFromDr -Instance Default -Vserver cifs -NonInteractive

    Ready to disable all Network Services in SVM [cifs-dr] from  cluster [c3po] ? [y/n] : -> y
    [cifs-dr] No ISCSI services in vserver
    [cifs-dr] No NFS services in vserver
    Do You really want to activate SVM [cifs] from cluster [r2d2] ? [y/n] : -> y
    [cifs] Break relation [cifs-dr:vol1] [cifs:vol1]
    [cifs] No ISCSI services in vserver
    [cifs] No NFS services in vserver
    Resync relationship [cifs:vol1] [cifs-dr:vol1]
    remove snapmirror relation for volume [cifs-dr:vol1] [cifs:vol1]
    Release Relation [cifs-dr:vol1] [cifs:vol1]
    Set volumes options for vserver [cifs] from SVMTOOL_DB [c:\jumpstart\svmtool]
    Create Quota policy rules from SVMTOOL_DB [c:\jumpstart\svmtool]
    WARNING: No quota activated on any Vserver's volume

#>
function Invoke-SvmDrRecoverFromDr {
    [alias("Invoke-SvmDrReActivate")]
    [alias("Invoke-SvmDrRecover")]
    [alias("Invoke-SvmDrActivateReverse")]
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Enables the force-recreation of snapmirror relations
        [switch]$ForceRecreate,

        # Enables the force-restart of the source svm (in case it's stopped)
        [switch]$ForceRestart,        

        # Enables Snapshot Policy Update
        # The source will inherit the snapshot policies from the destination
        [switch]$ForceUpdateSnapPolicy,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Force to use CIFS modify method, instead of delete/recreate when CIFS server name need to be changed
        [switch]$NoCifsDeleteMethod,

        # Optional, this SvmDr solution cannot transfer the passwords of local users (cifs, cluster)
        # In Non-Interactive Mode, the script cannot create missing users
        # If you pass this parameter, the password will used to create missing users
        [pscredential]$DefaultLocalUserCredentials,

        # Snapmirror Policy to use
        [Parameter(Mandatory = $false)]
        [string]$XDPPolicy,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "ReActivate"
}
<#
.Synopsis
    Removes the relationship-configuration-file between 2 vservers
.DESCRIPTION
	Removes the relationship-configuration-file between 2 vservers
    This is just an administrative removal
    The vservers are not touched

.EXAMPLE

    Remove-SvmDrConfiguration -Instance Default -Vserver cifs

    C:\Scripts\SVMTOOL\etc\Default\cifs.conf removed successfully...

#>
function Remove-SvmDrConfiguration {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "RemoveDRConf"
}
<#
.Synopsis
    Removes Instance configuration between two Clusters
.DESCRIPTION
	Completely remove an Instance between two Clusters

.EXAMPLE

    Remove-SvmDrInstance -Instance SOURCE-DEST

    Do you really want to remove this configuration instance [test] [y/n] : y
    [test] Removed

#>
function Remove-SvmDrInstance {
    [CmdletBinding()]
    param(
        # The name of the Instance to remove
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Add "-RemoveInstance $Instance" -Drop "Instance"
}
<#
.Synopsis
    Applies a snapmirror schedule on all snapmirror relations
.DESCRIPTION
	Applies a snapmirror schedule on all snapmirror relations

.EXAMPLE 
    Set-SvmDrSchedule -Instance Default -Vserver cifs -MirrorSchedule daily

    c3po::> snapmirror show -fields schedule
    source-path                  destination-path                     schedule
    ---------------------------- ------------------------------------ --------
    cifs:vol1                    cifs-dr:vol1                         daily


#>
function Set-SvmDrSchedule {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # The schedule name
        [Parameter(Mandatory = $true)]
        [string]$MirrorSchedule,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList)
}
<#
.Synopsis
    Applies a snapmirror schedule on all reversed snapmirror relations
.DESCRIPTION
	Applies a snapmirror schedule on all reversed snapmirror relations

.EXAMPLE 
    Set-SvmDrScheduleReverse -Instance Default -Vserver cifs -MirrorSchedule daily

    r2d2::> snapmirror show -fields schedule
    source-path                  destination-path                     schedule
    ---------------------------- ------------------------------------ --------
    cifs-dr:vol1                    cifs:vol1                         daily

#>
function Set-SvmDrScheduleReverse {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # The schedule name
        [Parameter(Mandatory = $true)]
        [string]$MirrorScheduleReverse,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList)
}
<#
.Synopsis
    Migrates the source svm to the desination svm
.DESCRIPTION
	Migrates the source svm to the desination svm
    The source vserver is taken down
    The snapmirrors are updated (final update)
    The snapmirrors are broken
    The destination vserver is brought online

    Optionally you can delete the source vserver

.NOTES
    Important to understand that a migrate action will try to rejoin the destination cifs server
    It will take over the CIFS identity of the source CIFS server

.EXAMPLE 

    Invoke-SvmDrMigrate -Instance Default -Vserver cifs -DefaultLocalUserCredentials default -NonInteractive

    WARNING: SVMTOOL script does not manage FCP configuration
    WARNING: You will have to backup and recreate all these configurations manually after the Migrate step
    WARNING: Files Locks are not migrated during the Migration process
    [cifs] Have all clients saved their work ? [y/n] : -> y
    [cifs-dr] Run last UpdateDR
    [r2d2] Check Cluster Cron configuration
    [cifs-dr] Check SVM Snapshot Policy
    [cifs-dr] Update CIFS Local User & Local Group
    [cifs-dr] Please Enter password for CIFS Local User [CIFS-DR\testuserke]
    [cifs-dr] Password extracted from default credentials [default]
    [cifs-dr] Please Enter password for CIFS Local User [CIFS-DR\useros1]
    [cifs-dr] Password extracted from default credentials [default]
    [cifs-dr] Check SVM options
    [cifs-dr] Update relation [cifs:vol1] [cifs-dr:vol1]
    [cifs-dr] Update relation [cifs:vol10] [cifs-dr:vol10]
    [cifs-dr] Update relation [cifs:vol2] [cifs-dr:vol2]
    [cifs-dr] Update relation [cifs:vol3] [cifs-dr:vol3]
    [cifs-dr] Update relation [cifs:vol4] [cifs-dr:vol4]
    [cifs-dr] Update relation [cifs:vol5] [cifs-dr:vol5]
    [cifs-dr] Update relation [cifs:vol6] [cifs-dr:vol6]
    [cifs-dr] Update relation [cifs:vol7] [cifs-dr:vol7]
    [cifs-dr] Update relation [cifs:vol8] [cifs-dr:vol8]
    [cifs-dr] Update relation [cifs:vol9] [cifs-dr:vol9]
    [cifs-dr] Status relation [cifs:vol1] [cifs-dr:vol1]:[transferring] [snapmirrored] [1218.5602695]
    [cifs-dr] Status relation [cifs:vol10] [cifs-dr:vol10]:[transferring] [snapmirrored] [1218.5763677]
    [cifs-dr] Status relation [cifs:vol2] [cifs-dr:vol2]:[transferring] [snapmirrored] [1219.5905137]
    [cifs-dr] Status relation [cifs:vol3] [cifs-dr:vol3]:[transferring] [snapmirrored] [1218.5995622]
    [cifs-dr] Status relation [cifs:vol4] [cifs-dr:vol4]:[transferring] [snapmirrored] [1218.6207377]
    [cifs-dr] Status relation [cifs:vol5] [cifs-dr:vol5]:[transferring] [snapmirrored] [1220.6267489]
    [cifs-dr] Status relation [cifs:vol6] [cifs-dr:vol6]:[transferring] [snapmirrored] [1218.6435619]
    [cifs-dr] Status relation [cifs:vol7] [cifs-dr:vol7]:[transferring] [snapmirrored] [1219.646622]
    [cifs-dr] Status relation [cifs:vol8] [cifs-dr:vol8]:[transferring] [snapmirrored] [1218.666756]
    [cifs-dr] Status relation [cifs:vol9] [cifs-dr:vol9]:[transferring] [snapmirrored] [1218.6667857]
    [cifs-dr] Check SVM iGroup configuration
    [cifs-dr] No igroup found on cluster [r2d2]
    [cifs-dr] Check SVM Export Policy
    [cifs-dr] Export Policy [default] already exists
    [cifs-dr] Check SVM Efficiency Policy
    [cifs-dr] Sis Policy [auto] already exists and identical
    [cifs-dr] Sis Policy [default] already exists and identical
    [cifs-dr] Sis Policy [inline-only] already exists and identical
    [cifs-dr] Check SVM Firewall Policy
    [cifs-dr] Check SVM LIF
    [cifs-dr] Network Interface [cifs] already exists
    [cifs-dr] Network Interface [cifs2] already exists
    [cifs-dr] Check SVM Users
    [cifs-dr] Add user [mirko] [http] [password] [vsadmin] [False]
    [cifs-dr] Please Enter password for user [mirko]
    [cifs-dr] Password extracted from default credentials [default]
    [cifs-dr] Update CIFS Local User & Local Group
    [cifs-dr] Do you want to reset Password for User [CIFS-DR\Administrator] on [cifs-dr]? [y/n] : -> n
    [cifs-dr] Do you want to reset Password for User [CIFS-DR\testuserke] on [cifs-dr]? [y/n] : -> n
    [cifs-dr] Do you want to reset Password for User [CIFS-DR\useros1] on [cifs-dr]? [y/n] : -> n
    [cifs-dr] Check SVM Name Mapping
    [cifs-dr] Check Local Unix User
    [cifs-dr] Modify Local Unix User [nobody] [65535] [65535] [] on [cifs-dr]
    [cifs-dr] Modify Local Unix User [pcuser] [65534] [65534] [] on [cifs-dr]
    [cifs-dr] Modify Local Unix User [root] [0] [1] [] on [cifs-dr]
    [cifs-dr] Check Local Unix Group
    [cifs-dr] Check User Mapping
    [cifs-dr] Check SVM VSCAN configuration
    [cifs-dr] Check SVM FPolicy configuration
    [cifs-dr] Check SVM Volumes options
    [cifs-dr] Check SVM Volumes Junction-Path configuration
    [cifs-dr] Modify Junction Path for [vol6]: from [] to [/vol6]
    [cifs-dr] Modify Junction Path for [vol5]: from [] to [/vol5]
    [cifs-dr] Modify Junction Path for [vol7]: from [] to [/vol7]
    [cifs-dr] Modify Junction Path for [vol9]: from [] to [/vol9]
    [cifs-dr] Modify Junction Path for [vol8]: from [] to [/vol8]
    [cifs-dr] Modify Junction Path for [vol10]: from [] to [/vol10]
    [cifs-dr] Modify Junction Path for [vol1]: from [] to [/vol1]
    [cifs-dr] Modify Junction Path for [vol2]: from [] to [/vol2]
    [cifs-dr] Modify Junction Path for [vol4]: from [] to [/vol4]
    [cifs-dr] Modify Junction Path for [vol3]: from [] to [/vol3]
    [cifs-dr] Check SVM DNS configuration
    [cifs-dr] Check SVM NIS configuration
    [cifs-dr] No NIS service found on Vserver [cifs]
    [cifs-dr] Check SVM NFS configuration
    [cifs-dr] No NFS services in vserver [cifs]
    [cifs-dr] Check SVM iSCSI configuration
    [cifs-dr] No ISCSI services in vserver [cifs]
    [cifs-dr] Check SVM CIFS shares
    [cifs-dr] Create share [vol6]
    [cifs-dr] Create share [vol5]
    [cifs-dr] Create share [vol7]
    [cifs-dr] Create share [vol9]
    [cifs-dr] Create share [vol8]
    [cifs-dr] Create share [vol10]
    [cifs-dr] Create share [vol1]
    [cifs-dr] Create share [vol2]
    [cifs-dr] Create share [vol4]
    [cifs-dr] Create share [vol3]
    [cifs-dr] Check Cifs Symlinks
    [cifs-dr] Check LUN Mapping
    [cifs-dr] Check LUN Serial Number
    [cifs-dr] Check SVM QOS configuration
    [cifs-dr] Check Role
    [cifs-dr] Check Qtree Export Policy
    [cifs-dr] Wait for snapMirror relationships to finish
    [cifs-dr] Please wait until all snapmirror transfers terminate
    [cifs-dr] All Snapmirror transfers terminated
    [cifs-dr] Break relation [cifs:vol1] [cifs-dr:vol1]
    [cifs-dr] Break relation [cifs:vol10] [cifs-dr:vol10]
    [cifs-dr] Break relation [cifs:vol2] [cifs-dr:vol2]
    [cifs-dr] Break relation [cifs:vol3] [cifs-dr:vol3]
    [cifs-dr] Break relation [cifs:vol4] [cifs-dr:vol4]
    [cifs-dr] Break relation [cifs:vol5] [cifs-dr:vol5]
    [cifs-dr] Break relation [cifs:vol6] [cifs-dr:vol6]
    [cifs-dr] Break relation [cifs:vol7] [cifs-dr:vol7]
    [cifs-dr] Break relation [cifs:vol8] [cifs-dr:vol8]
    [cifs-dr] Break relation [cifs:vol9] [cifs-dr:vol9]
    remove snapmirror relation for volume [cifs:vol1] [cifs-dr:vol1]
    remove snapmirror relation for volume [cifs:vol10] [cifs-dr:vol10]
    remove snapmirror relation for volume [cifs:vol2] [cifs-dr:vol2]
    remove snapmirror relation for volume [cifs:vol3] [cifs-dr:vol3]
    remove snapmirror relation for volume [cifs:vol4] [cifs-dr:vol4]
    remove snapmirror relation for volume [cifs:vol5] [cifs-dr:vol5]
    remove snapmirror relation for volume [cifs:vol6] [cifs-dr:vol6]
    remove snapmirror relation for volume [cifs:vol7] [cifs-dr:vol7]
    remove snapmirror relation for volume [cifs:vol8] [cifs-dr:vol8]
    remove snapmirror relation for volume [cifs:vol9] [cifs-dr:vol9]
    IP and Services will switch now for [cifs]. Ready to go ? [y/n] : -> y
    [cifs-dr] Set [cifs] down on [cifs]
    [cifs-dr] Set [cifs] up with address [172.16.0.178] and netmask [255.255.0.0] on [cifs-dr]
    [cifs-dr] Set [cifs2] down on [cifs]
    [cifs-dr] Set [cifs2] up with address [192.168.96.178] and netmask [255.255.255.0] on [cifs-dr]
    Set CIFS server down on [cifs]
    Set CIFS server up on [cifs-dr] with identity of [cifs] : [CIFS]
    [cifs-dr] No NFS services in vserver
    [cifs-dr] No iSCSI services in Vserver
    [cifs] has been migrated on destination cluster [c3po]
    [cifs] Users can now connect on destination
    Set volumes options for vserver [cifs-dr] from SVMTOOL_DB [c:\jumpstart\svmtool]
    Create Quota policy rules from SVMTOOL_DB [c:\jumpstart\svmtool]
    WARNING: No quota activated on any Vserver's volume
    Do you want to delete Vserver [cifs] on source cluster [r2d2] ? [y/n] : -> n
    User chose not to delete source Vserver [cifs] on Source Cluster [r2d2]
    Vserver [cifs] will only be stopped on [r2d2]
    In this case the SVM object name on Destination Cluster [c3po] is still [cifs-dr]
    But CIFS identity is correctly migrated to [cifs]
    Final rename will be done when [-DeleteSource] step will be executed, once you are ready to completely delete [cifs] on Source Cluster [r2d2]

#>
function Invoke-SvmDrMigrate {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Enables the removal of the source vserver
        [switch]$DeleteSource,

        # Optional, makes an aggregate suggestion for the datavolumes
        [string]$DataAggr,

        # Optional, A regular expression to map aggregate names
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - 1 on 1 match : ".*" => (src = dst)
        #   - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (ep*snas54_aggr1)
        [regex]$AggrMatchRegex,

        # Optional, A regular expression to map node-names (for lif-port selection)
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - node number match : "(.*)-[0-9]{2}" => (example : *-03)
        [regex]$NodeMatchRegex,

        # Enables Snapshot Policy Update
        # The source will inherit the snapshot policies from the destination
        [switch]$ForceUpdateSnapPolicy,

        # Optional, this SvmDr solution cannot transfer the passwords of local users (cifs, cluster)
        # In Non-Interactive Mode, the script cannot create missing users
        # If you pass this parameter, the password will used to create missing users
        [pscredential]$DefaultLocalUserCredentials,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # By passing an temporary ip-address and in combination with parameter "SecondaryCifsLifMaster"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$TemporarySecondaryCifsIp,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif that is passed in this parameter (using same port and options)
        # Use this in combination with parameter "TemporarySecondaryCifsIp"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$SecondaryCifsLifMaster,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif used in the parameter SecondaryCifsLifMaster
        # A temporary lif will be created to join the vserver dr in AD
        # This parameter will override the vlan in which this temp lif is created
        [string]$SecondaryCifsLifCustomVlan,

        # Preserve or not Network Identity (IP addresses and CIFS server name) of Source on Destination
        [Parameter(Mandatory = $false)]
        [bool]$PreserveIdentity=$True,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Force to use CIFS modify method, instead of delete/recreate when CIFS server name need to be changed
        [switch]$NoCifsDeleteMethod,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "Migrate"
}
<#
.Synopsis
    Removes a source vserver
.DESCRIPTION
	Removes a source vserver
    This is typically done after a succesful migrate action

.EXAMPLE 

    Remove-SvmDrSource -Instance Default -Vserver cifs -LogLevelLogFile debug

    WARNING: [cifs] Delete Source SVM can not be interrupted or rolled back
    Do you want to completely delete [cifs] on [r2d2] ? [y/n] : y
    Release Relation [cifs:vol1] [cifs-dr:vol1]
    Release Relation [cifs:vol10] [cifs-dr:vol10]
    Release Relation [cifs:vol2] [cifs-dr:vol2]
    Release Relation [cifs:vol3] [cifs-dr:vol3]
    Release Relation [cifs:vol4] [cifs-dr:vol4]
    Release Relation [cifs:vol5] [cifs-dr:vol5]
    Release Relation [cifs:vol6] [cifs-dr:vol6]
    Release Relation [cifs:vol7] [cifs-dr:vol7]
    Release Relation [cifs:vol8] [cifs-dr:vol8]
    Release Relation [cifs:vol9] [cifs-dr:vol9]
    [cifs-dr] Renamed to [cifs]
    [cifs] will be deleted on cluster [r2d2]
    Remove volume [vol1] from [cifs]
    Remove volume [vol10] from [cifs]
    Remove volume [vol2] from [cifs]
    Remove volume [vol3] from [cifs]
    Remove volume [vol4] from [cifs]
    Remove volume [vol5] from [cifs]
    Remove volume [vol6] from [cifs]
    Remove volume [vol7] from [cifs]
    Remove volume [vol8] from [cifs]
    Remove volume [vol9] from [cifs]
    Remove root volume [svm_root]
    [cifs] completely deleted on [r2d2]

#>
function Remove-SvmDrSource {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )

    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "DeleteSource"
}
<#
.Synopsis
    Restores quota's on the destination
.DESCRIPTION
	Restores quota's on the destination
    The snapmirror relations must be broken

.EXAMPLE 

    Set-SvmDrQuota -Instance reverse -Vserver cifs
    Create Quota policy rules from SVMTOOL_DB [c:\jumpstart\svmtool]
    Disable quota on [cifs-dr] Volume [vol10]
    Enable quota on [cifs-dr] Volume [vol10]
    Disable quota on [cifs-dr] Volume [vol5]
    Enable quota on [cifs-dr] Volume [vol5]
    Disable quota on [cifs-dr] Volume [vol6]
    Enable quota on [cifs-dr] Volume [vol6]
    Disable quota on [cifs-dr] Volume [vol7]
    Enable quota on [cifs-dr] Volume [vol7]
    Disable quota on [cifs-dr] Volume [vol8]
    Enable quota on [cifs-dr] Volume [vol8]
    Disable quota on [cifs-dr] Volume [vol9]
    Enable quota on [cifs-dr] Volume [vol9]

#>
function Set-SvmDrQuota {
    [alias("Invoke-SvmDrCreateQuota")]
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "CreateQuotaDR"
}
<#
.Synopsis
    Restores quota's in the reverse direction (destination -> source)
.DESCRIPTION
	Restores quota's in the reverse direction (destination -> source)
    The snapmirror relations must be broken
    The SvmDr relation must be reversed

.EXAMPLE 

    Set-SvmDrQuota -Instance reverse -Vserver cifs
    Create Quota policy rules from SVMTOOL_DB [c:\jumpstart\svmtool]
    Disable quota on [cifs] Volume [vol10]
    Enable quota on [cifs] Volume [vol10]
    Disable quota on [cifs] Volume [vol5]
    Enable quota on [cifs] Volume [vol5]
    Disable quota on [cifs] Volume [vol6]
    Enable quota on [cifs] Volume [vol6]
    Disable quota on [cifs] Volume [vol7]
    Enable quota on [cifs] Volume [vol7]
    Disable quota on [cifs] Volume [vol8]
    Enable quota on [cifs] Volume [vol8]
    Disable quota on [cifs] Volume [vol9]
    Enable quota on [cifs] Volume [vol9]

#>
function Set-SvmDrQuotaReverse {
    [alias("Invoke-SvmDrCreateQuotaReverse")]
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "ReCreateQuota"
}
<#
.Synopsis
    Makes some internal tests
.DESCRIPTION
	Makes soms internal tests
    Such as 
        - connect to both clusters
        - check cluster peering

.NOTES
    This cmdlet is a work in progress
    More tests can be added
    All suggestions are welcome

.EXAMPLE 

    Test-SvmDrConnection -Instance reverse -Vserver cifs

    [test] Connect to cluster [c3po] with login [admin]
    [test] Connect to cluster [r2d2] with login [admin]
    [test] Cluster Peer from cluster [c3po] to cluster [r2d2]
    Tests completed successfully

#>
function Test-SvmDrConnection {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "InternalTest"
}
<#
.Synopsis
    Removes all broken Reverse SnapMirror relations (after DR test or crash)
.DESCRIPTION
	Removes all broken Reverse SnapMirror relations (after DR test or crash)
.NOTES
    When an Invoke-SvmDrRecoverFromDr was run sucessfully
    all relations should already have been cleaned

.EXAMPLE 

    Clear-SvmDrReverse -Instance reverse -Vserver cifs

#>
function Clear-SvmDrReverse {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "CleanReverse"
}
<#
.Synopsis
    Backs up Cluster and Vserver information to Json-files
.DESCRIPTION
	Backs up Cluster and Vserver information to Json-files.
    The vserver is optional, if not provided, the full cluster is backed up.
.NOTES
    The backup process is ran in a runspace (parallel execution)
    Console logging wil not work in an Powershell ISE host

.EXAMPLE 

    Backup-SvmDr -Cluster c3po -Vserver cifs -NonInteractive

    SVMTOOL Run Backup
    use Config File [C:\Scripts\SVMTOOL\etc\c3po\svmtool.conf]
    Backup will be done inside [c:\jumpstart\svmtool\c3po]
    Backup SVM [cifs] on Cluster [c3po]
    Create Backup Job for [cifs]
    [cifs] FullPath = [C:\Scripts\SVMTOOL\log\c3po\cifs\svmtool.log]
    [cifs] Path = [C:\Scripts\SVMTOOL\log\c3po\cifs]
    [cifs] Log File is [C:\Scripts\SVMTOOL\log\c3po\cifs\svmtool.log]
    [cifs] FullPath = [c:\jumpstart\svmtool\c3po\cifs\20181011145450\backup.json]
    [cifs] Path = [c:\jumpstart\svmtool\c3po\cifs\20181011145450]
    [cifs] Create directory [c:\jumpstart\svmtool\c3po\cifs\20181011145450]
    [cifs] Check SVM configuration
    [cifs] Check SVM options
    [cifs] Check SVM peering
    [c3po] Check Cluster Cron configuration
    [cifs] Check SVM Export Policy
    [cifs] Check SVM Efficiency Policy
    [cifs] Check SVM Firewall Policy
    [cifs] Check Role
    [cifs] Check SVM LIF
    [cifs] Check SVM Users
    [cifs] Check SVM Name Mapping
    [cifs] Check Local Unix User
    [cifs] Check Local Unix Group
    [cifs] Check User Mapping
    [cifs] Check SVM DNS configuration
    [cifs] Check SVM LDAP configuration
    [cifs] Check SVM NIS configuration
    [cifs] No NIS service found on Vserver [cifs]
    [cifs] Check SVM NFS configuration
    [cifs] No NFS services in vserver [cifs]
    [cifs] Check SVM iSCSI configuration
    [cifs] No ISCSI services in vserver [cifs]
    [cifs] Check SVM CIFS Sever configuration
    [cifs] Check SVM CIFS Server options
    [cifs] Check SVM iGroup configuration
    [cifs] Check SVM VSCAN configuration
    [cifs] Check SVM FPolicy configuration
    [cifs] Check SVM Volumes
    [cifs] Check SVM Volumes options
    [cifs] Check SVM QOS configuration
    [cifs] Check SVM Snapshot Policy
    [cifs] Check SVM Volumes Junction-Path configuration
    [cifs] Update CIFS Local User & Local Group
    [cifs] Check SVM CIFS shares
    [cifs] Check Cifs Symlinks
    [cifs] Check LUN Mapping
    [cifs] Check LUN Serial Number
    [cifs] Check Qtree
    [cifs] Check Quota
    [cifs] Check Quota Policy
    Close log
    cifs finished
    Finished - Script ran for 00:00:04.4539205

#>
function Backup-SvmDr {
    [CmdletBinding()]
    param(
        # The name of the cluster to backup
        [Parameter(Mandatory = $true)]
        [string]$Cluster,

        # Optional, The vserver to backup
        [string]$Vserver,

        # Enables creation of the configuration file
        [switch]$Recreateconf,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Add "-Backup $Cluster" -Drop "Cluster"
}

<#
.Synopsis
    Makes a clone from the DR vserver.
.DESCRIPTION
	Makes a clone from the DR vserver.
    It tries to make an exact copy and use flexclone to clone the volumes
.NOTES
    If ran in non-interactive mode we will assume identical ip's
    However, that will result in duplicate ip's
    So, in that case, private APIPA ip's are generated

    The Aggregate Regex and/or RootAggr can be used for root aggregate selection
    And the Node Regex for lif ports, but since this is a clone, an exact match is always found

    Default credentials can also be passed when working in non-interactive mode

.EXAMPLE

    Invoke-SvmDrClone -Instance reverse -Vserver cifs -AggrMatchRegex ".*" -NodeMatchRegex "(.*)-[0-9]{2}" -DefaultLocalUserCredentials tmp -ActiveDirectoryCredentials administrator -TemporarySecondaryCifsIp 172.16.55.66 -SecondaryCifsLifMaster cifs -NonInteractive

    Windows PowerShell credential request
    Enter your credentials.
    Password for user tmp: ********

    Windows PowerShell credential request
    Enter your credentials.
    Password for user administrator: ********

    Create Clone SVM [cifs-dr_clone.0]
    [cifs-dr_clone.0] Check SVM configuration
    [cifs-dr_clone.0] Select an aggregate for the root volume
            [1] : [aggr2]   [r2d2-01]       [28 GB]
            [2] : [aggr1]   [r2d2-01]       [14 GB]
    Default found based on regex [aggr1]
    [r2d2] Select Aggr 1-2 [2] : -> 2
    [r2d2] You have selected the aggregate [aggr1] ? [y/n] : -> y
    [cifs-dr_clone.0] create Clone vserver : [svm_root] [c.utf_8] [r2d2] [aggr1]
    [cifs-dr_clone.0] Check SVM options
    [c3po] Check Cluster Cron configuration
    [cifs-dr_clone.0] Check SVM Export Policy
    [cifs-dr_clone.0] Export Policy [default] already exists
    [cifs-dr_clone.0] Check SVM Efficiency Policy
    [cifs-dr_clone.0] Sis Policy [auto] already exists and identical
    [cifs-dr_clone.0] Sis Policy [default] already exists and identical
    [cifs-dr_clone.0] Sis Policy [inline-only] already exists and identical
    [cifs-dr_clone.0] Check SVM Firewall Policy
    [cifs-dr_clone.0] Check Role
    [cifs-dr_clone.0] Check SVM LIF
    [cifs-dr_clone.0] Do you want to create the DRP LIF [cifs] [172.16.0.178] [255.255.0.0] [] [c3po-01] [e0c-16] on cluster [r2d2] ? [y/n] : -> y
    [cifs-dr_clone.0] Working in non interactive for clone - creating APIPA address [169.254.186.199]
    [cifs-dr_clone.0] Please Enter a valid IP Address [169.254.186.199] : -> 169.254.186.199
    [cifs-dr_clone.0] Please Enter a valid IP NetMask [255.255.0.0] : -> 255.255.0.0
    [cifs-dr_clone.0] Please Enter a valid Default Gateway Address [] : ->
    Please select secondary node for LIF [cifs] :
            [1] : [r2d2-01]
    Default found based on regex [(.*)-01]
    Select Node 1-1 [1] : -> 1
    Please select Port for LIF [cifs] on node [r2d2-01]
            [1] : [e0a] role [data] status [up] broadcastdomain []
            [2] : [e0b] role [data] status [up] broadcastdomain []
            [3] : [e0c] role [node_mgmt] status [up] broadcastdomain []
            [4] : [e0c-16] role [node_mgmt] status [up] broadcastdomain [vlan-16]
            [5] : [e0c-17] role [node_mgmt] status [up] broadcastdomain [vlan-17]
            [6] : [e0c-18] role [node_mgmt] status [up] broadcastdomain [vlan-18]
            [7] : [e0c-19] role [node_mgmt] status [up] broadcastdomain [vlan-19]
            [8] : [e0d] role [data] status [up] broadcastdomain [thuis]
    Default found based on exact match [vlan-16][e0c-16]
    Select Port 1-8 [4] : -> 4
    [cifs-dr_clone.0] Ready to create the LIF [cifs] [169.254.186.199] [255.255.0.0] [] [r2d2-01] [e0c-16] ? [y/n] : -> y
    [cifs-dr_clone.0] Create the LIF [cifs] [169.254.186.199] [255.255.0.0] [] [r2d2-01] [e0c-16]
    [cifs-dr_clone.0] Do you want to create the DRP LIF [cifs2] [192.168.96.178] [255.255.255.0] [] [c3po-01] [e0d]
    on cluster [r2d2] ? [y/n] : -> y
    [cifs-dr_clone.0] Working in non interactive for clone - creating APIPA address [169.254.235.89]
    [cifs-dr_clone.0] Please Enter a valid IP Address [169.254.235.89] : -> 169.254.235.89
    [cifs-dr_clone.0] Please Enter a valid IP NetMask [255.255.0.0] : -> 255.255.0.0
    [cifs-dr_clone.0] Please Enter a valid Default Gateway Address [] : ->
    [cifs-dr_clone.0] Check SVM Users
    [cifs-dr_clone.0] Add user [mirko] [http] [password] [vsadmin] [False]
    [cifs-dr_clone.0] Please Enter password for user [mirko]
    [cifs-dr_clone.0] Password extracted from default credentials [tmp]
    [cifs-dr_clone.0] Check SVM Name Mapping
    [cifs-dr_clone.0] Check Local Unix User
    [cifs-dr_clone.0] Modify Local Unix User [nobody] [65535] [65535] [] on [cifs-dr_clone.0]
    [cifs-dr_clone.0] Modify Local Unix User [pcuser] [65534] [65534] [] on [cifs-dr_clone.0]
    [cifs-dr_clone.0] Modify Local Unix User [root] [0] [1] [] on [cifs-dr_clone.0]
    [cifs-dr_clone.0] Check Local Unix Group
    [cifs-dr_clone.0] Check User Mapping
    [cifs-dr_clone.0] Check SVM DNS configuration
    [cifs-dr_clone.0] Check SVM LDAP configuration
    [cifs-dr_clone.0] Check SVM NIS configuration
    [cifs-dr_clone.0] No NIS service found on Vserver [cifs]
    [cifs-dr_clone.0] Check SVM NFS configuration
    [cifs-dr_clone.0] No NFS services in vserver [cifs]
    [cifs-dr_clone.0] Check SVM iSCSI configuration
    [cifs-dr_clone.0] No ISCSI services in vserver [cifs]
    [cifs-dr_clone.0] Check SVM CIFS Sever configuration
    [cifs-dr_clone.0] Add CIFS Server in Vserver DR : [cifs-dr_clone.0] [r2d2]
    [cifs-dr_clone.0] Clone CIFS server name set to [cifs-dr_clone.0]
    [cifs-dr_clone.0] Clone mode in non-interactive mode - getting netmask from primary
    [cifs-dr_clone.0] Create the LIF [tmp_lif_to_join_in_ad_cifs] (cloning from cifs)
    [cifs-dr_clone.0] LIF [tmp_lif_to_join_in_ad_cifs] is the Temp Cifs LIF, it must be in Administrative up status
    [cifs-dr_clone.0] Cifs server is joined, Removing tmp lif
    [cifs-dr_clone.0] Check SVM CIFS Server options
    WARNING: 'KerberosKdcTimeout' parameter is not available for Data ONTAP 9.0 and up. Ignoring 'KerberosKdcTimeout'.
    [cifs-dr_clone.0] Check SVM iGroup configuration[cifs-dr_clone.0] No igroup found on cluster [c3po]
    [cifs-dr_clone.0] Check SVM VSCAN configuration
    [cifs-dr_clone.0] Check SVM FPolicy configuration
    [cifs-dr_clone.0] Create Clones
    [cifs-dr_clone.0] Create Flexclone [vol1] from SVM [cifs-dr]
    [cifs-dr_clone.0] Check SVM Volumes options
    [cifs-dr_clone.0] Check SVM QOS configuration
    [cifs-dr_clone.0] Check SVM Snapshot Policy
    [cifs-dr_clone.0] Check SVM Volumes Junction-Path configuration
    [cifs-dr_clone.0] Modify Junction Path for [vol10]: from [] to [/vol10]
    [cifs-dr_clone.0] Modify Junction Path for [vol1]: from [] to [/vol1]
    [cifs-dr_clone.0] Update CIFS Local User & Local Group
    [cifs-dr_clone.0] Do you want to reset Password for User [CIFS-DR_CLONE.0\Administrator] on [cifs-dr_clone.0]? [y/n] : -> n
    [cifs-dr_clone.0] Please Enter password for CIFS Local User [CIFS-DR_CLONE.0\testuserke]
    [cifs-dr_clone.0] Password extracted from default credentials [tmp]
    [cifs-dr_clone.0] Please Enter password for CIFS Local User [CIFS-DR_CLONE.0\useros1]
    [cifs-dr_clone.0] Password extracted from default credentials [tmp]
    [cifs-dr_clone.0] Check SVM CIFS shares
    [cifs-dr_clone.0] Create share [vol1]
    [cifs-dr_clone.0] Check LUN Mapping
    [cifs-dr_clone.0] Check LUN Serial Number
    [cifs-dr_clone.0] Check Qtree
    [cifs-dr_clone.0] No ISCSI services in vserver
    [cifs-dr_clone.0] No NFS services in vserver
    [cifs-dr_clone.0] Set volumes options from SVMTOOL_DB [C:\Scripts\SVMTOOL]
    ERROR: Cluster [r2d2] not found in SVMTOOL_DB [C:\Scripts\SVMTOOL]
    ERROR: set_vol_options_from_voldb failed
    [cifs-dr] Create Quota policy rules from SVMTOOL_DB [C:\Scripts\SVMTOOL]
    ERROR: Cluster [r2d2] found in SVMTOOL_DB [C:\Scripts\SVMTOOL]
    ERROR: create_quota_rules_from_quotadb failed

#>
function New-SvmDrClone {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # Optional, makes an aggregate suggestion for the root volume
        [string]$RootAggr,

        # Optional, A regular expression to map source aggregate to destination aggregate
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - 1 on 1 match : ".*" => (src = * ; dst = src)
        #   - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (src = ep*snas54_aggr1 ; dst = ep*snas54_aggr1)
        [regex]$AggrMatchRegex,

        # Optional, A regular expression to map source node to destination node (for lif-port selection)
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)
        [regex]$NodeMatchRegex,

        # Optional, this SvmDr solution cannot transfer the passwords of local users (cifs, cluster)
        # In Non-Interactive Mode, the script cannot create missing users
        # If you pass this parameter, the password will used to create missing users
        [pscredential]$DefaultLocalUserCredentials,

        # Optional, this SvmDr solution cannot transfer the passwords for LDAP Binding
        # In Non-Interactive Mode, the script cannot bind to new LDAP server
        # If you pass this parameter, the password will be used to Bind LDAP server
        [pscredential]$DefaultLDAPCredentials,

        # Optional, when running in Non-Interactive mode, this script cannot prompt for AD credentials
        # Use this parameter to join the dr vserver in AD without interaction
        [pscredential]$ActiveDirectoryCredentials,

        # Optional, when the vserver clone is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # By passing an temporary ip-address and in combination with parameter "SecondaryCifsLifMaster"
        # A temporary lif will be created to join the vserver clone in AD
        [string]$TemporarySecondaryCifsIp,

        # Optional, when the vserver clone is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif that is passed in this parameter (using same port and options)
        # Use this in combination with parameter "TemporarySecondaryCifsIp"
        # A temporary lif will be created to join the vserver clone in AD
        [string]$SecondaryCifsLifMaster,

        # Optional, when the vserver clone is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif used in the parameter SecondaryCifsLifMaster
        # A temporary lif will be created to join the vserver clone in AD
        # This parameter will override the vlan in which this temp lif is created
        [string]$SecondaryCifsLifCustomVlan,

        # When the clone cifs server is joined AD, you can override in which OU this happens with this parameter
        [string]$ActiveDirectoryCustomOU,     
        
        # Skip vscan and fpolicy actions
        [switch]$SkipVscanFpolicy,
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceCloneOriginal,        

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "CloneDR"
}

<#
.Synopsis
    Deletes a Vserver Dr Clone
.DESCRIPTION
	Deletes a Vserver Dr Clone

.EXAMPLE

    Remove-SvmDrClone -Instance reverse -Vserver cifs -CloneName cifs-dr_clone.0 -NonInteractive
    
    Are you sure you want to delete Vserver Clone [cifs-dr_clone.0] from [r2d2] ? [y/n] : -> y
    [cifs-dr_clone.0] Remove volume [vol1]
    [cifs-dr_clone.0] Remove volume [vol10]
    [cifs-dr_clone.0] Remove volume [vol2]
    [cifs-dr_clone.0] Remove volume [vol3]
    [cifs-dr_clone.0] Remove volume [vol4]
    [cifs-dr_clone.0] Remove volume [vol5]
    [cifs-dr_clone.0] Remove volume [vol6]
    [cifs-dr_clone.0] Remove volume [vol7]
    [cifs-dr_clone.0] Remove volume [vol8]
    [cifs-dr_clone.0] Remove volume [vol9]
    [cifs-dr_clone.0] Remove root volume [svm_root]
    [cifs-dr_clone.0] Remove CIFS server
    [cifs-dr_clone.0] Stop SVM
    [cifs-dr_clone.0] Remove SVM

#>
function Remove-SvmDrClone {
    [CmdletBinding()]
    param(
        # The unique name, referencing the relationship between the 2 clusters.
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        # The source vserver
        [Parameter(Mandatory = $true)]
        [string]$Vserver,

        # The name of the clone to delete
        [Parameter(Mandatory = $true)]
        [string]$CloneName,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables Non-Interactive Mode
        # Is default enabled in Wfa-Integration Mode
        [switch]$NonInteractive,

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "DeleteCloneDR"
}

<#
.Synopsis
    Restores Vserver particular Objects configuration from previously created Json-files from a Backup
.DESCRIPTION
	Restores Cluster and Vserver information from previously created Json-files
    The vserver is optional, if not provided all vservers will be restored
.NOTES
    
    RestoreObject can be used to restore on source a list of mandatory CIFS Server, CIFS shares, volumes or Lifs
    But it can also beeing used to replicate a configuration (Volumes list, Cifs Server, Cifs Shares, etc) to a newly deployed SVM on another Cluster


.EXAMPLE 

    Restore-ObjectSvmDr -Cluster r2d2 -Vserver PSLAB -Objects Shares -Destination c3po -Vserver cifs

#>
function Restore-ObjectSvmDr {
    [CmdletBinding()]
    param(
        # The name of the cluster to restore
        [Parameter(Mandatory = $true)]
        [string]$Cluster,

        # Optional, the vserver to be restored
        [Parameter(Mandatory = $True)]
        [string]$Vserver,

        # Object to restore
        [Parameter(Mandatory = $true)]
        [ValidateSet("Lifs", "Volumes", "Exports", "CifsServer", "Shares", "Symlinks", "Quotas", "Users")]
        [string[]]$Objects=@(""),

        # The name of the destination cluster, if not provided, will restore on source cluster
        [Parameter(Mandatory = $false)]
        [string]$DestinationCluster,

        # The name of the destination vserver, if not provided, will restore on source vserver
        [Parameter(Mandatory = $false)]
        [string]$DestinationSVM,

        # When restoring volumes allow to choose hosting aggregate for each volume
        [Parameter(Mandatory = $false)]
        [switch]$AlwaysChooseDataAggr,
        
        # Enables the volumes to be restored as type RW (instead of DP)
        # Use this if you don't plan on using snapmirror technology to restore the data 
        # (host based copy for example)
        [switch]$RW,

        # Enables interactive choice of backup date
        # Does not work in Non-Interactive mode
        # If ommited, the last backup is used.
        [switch]$SelectBackupDate,

        # Optional, makes an aggregate suggestion for the rootvolume
        [string]$RootAggr,

        # Optional, makes an aggregate suggestion for the datavolumes
        [string]$DataAggr,

        # Optional, A regular expression to map source aggregate to destination aggregate
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - 1 on 1 match : ".*" => (src = * ; dst = src)
        #   - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (src = ep*snas54_aggr1 ; dst = ep*snas54_aggr1)
        #   - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)
        [regex]$AggrMatchRegex,

        # Optional, A regular expression to map source node to destination node (for lif-port selection)
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)
        [regex]$NodeMatchRegex,

        # Optional, this SvmDr solution cannot transfer the passwords of local users (cifs, cluster)
        # In Non-Interactive Mode, the script cannot create missing users
        # If you pass this parameter, the password will used to create missing users
        [pscredential]$DefaultLocalUserCredentials,

        # Optional, this SvmDr solution cannot transfer the passwords for LDAP Binding
        # In Non-Interactive Mode, the script cannot bind to new LDAP server
        # If you pass this parameter, the password will be used to Bind LDAP server
        [pscredential]$DefaultLDAPCredentials,

        # Optional, when running in Non-Interactive mode, this script cannot prompt for AD credentials
        # Use this parameter to join the dr vserver in AD without interaction
        [pscredential]$ActiveDirectoryCredentials,

        <# # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # By passing an temporary ip-address and in combination with parameter "SecondaryCifsLifMaster"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$TemporarySecondaryCifsIp,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif that is passed in this parameter (using same port and options)
        # Use this in combination with parameter "TemporarySecondaryCifsIp"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$SecondaryCifsLifMaster, #>

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Add "-RestoreObject $Cluster" -Drop "Cluster"
}

<#
.Synopsis
    Restores Cluster and Vserver information from previously created Json-files
.DESCRIPTION
	Restores Cluster and Vserver information from previously created Json-files
    The vserver is optional, if not provided all vservers will be restored
.NOTES
    The restore process is ran in a runspace (parallel execution)
    Console logging wil not work in an Powershell ISE host
    The restore process cannot be run in Non-Interactive Mode

    The restore process must be seen like this :
        - the vserver must not yet exist
        - the vserver will be created as complete as possible using information from json file
        - volumes will be created as DP volumes
        - the idea is then to resync volume data from snapvault locations

.EXAMPLE 

    Restore-SvmDr -Cluster r2d2 -Destination c3po -Vserver cifs

#>
function Restore-SvmDr {
    [CmdletBinding()]
    param(
        # The name of the cluster to restore
        [Parameter(Mandatory = $true)]
        [string]$Cluster,

        # The name of the destination cluster
        [Parameter(Mandatory = $true)]
        [string]$Destination,

        # Optional, the vserver to be restored
        [Parameter(Mandatory = $false)]
        [string]$Vserver,

        # Enables the volumes to be restored as type RW (instead of DP)
        # Use this if you don't plan on using snapmirror technology to restore the data 
        # (host based copy for example)
        [switch]$RW,

        # Enables interactive choice of backup date
        # Does not work in Non-Interactive mode
        # If ommited, the last backup is used.
        [switch]$SelectBackupDate,

        # Optional, makes an aggregate suggestion for the rootvolume
        [string]$RootAggr,

        # Optional, makes an aggregate suggestion for the datavolumes
        [string]$DataAggr,

        # Optional, A regular expression to map source aggregate to destination aggregate
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - 1 on 1 match : ".*" => (src = * ; dst = src)
        #   - string replace : "ep(.*)snas[0-9]*_aggr[0-9]*" => (src = ep*snas54_aggr1 ; dst = ep*snas54_aggr1)
        #   - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)
        [regex]$AggrMatchRegex,

        # Optional, A regular expression to map source node to destination node (for lif-port selection)
        # Use regex-groups (wrap in brackets) to create wildcards
        #   - node number match : "(.*)-[0-9]{2}" => (src = *-03 ; dst = *-03)
        [regex]$NodeMatchRegex,

        # Optional, this SvmDr solution cannot transfer the passwords of local users (cifs, cluster)
        # In Non-Interactive Mode, the script cannot create missing users
        # If you pass this parameter, the password will used to create missing users
        [pscredential]$DefaultLocalUserCredentials,

        # Optional, this SvmDr solution cannot transfer the passwords for LDAP Binding
        # In Non-Interactive Mode, the script cannot bind to new LDAP server
        # If you pass this parameter, the password will be used to Bind LDAP server
        [pscredential]$DefaultLDAPCredentials,

        # Optional, when running in Non-Interactive mode, this script cannot prompt for AD credentials
        # Use this parameter to join the dr vserver in AD without interaction
        [pscredential]$ActiveDirectoryCredentials,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # By passing an temporary ip-address and in combination with parameter "SecondaryCifsLifMaster"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$TemporarySecondaryCifsIp,

        # Optional, when the vserver dr is created, all lifs are taken offline (duplicate ip conflicts)
        # Hence if the vserver needs to be joined in AD, there is no lif available
        # So we will clone the lif that is passed in this parameter (using same port and options)
        # Use this in combination with parameter "TemporarySecondaryCifsIp"
        # A temporary lif will be created to join the vserver dr in AD
        [string]$SecondaryCifsLifMaster,

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info",

        # Enables OnCommand Workflow Automation (WFA) Integration
        [switch]$WfaIntegration,

        # Enables HTTP mode (default HTTPS)
        [switch]$HTTP,
        [Int32]$Timeout = 60
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Add "-Restore $Cluster" -Drop "Cluster"
}

<#
.Synopsis
    Imports instances from previous generations

#>
function Import-SvmDrConfiguration {
    [CmdletBinding()]
    param(

        # Loglevel of the console output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelConsole = "Info",

        # Loglevel of the logfile output
        [ValidateSet("Debug", "Info", "Warn", "Error", "Fatal", "Off")]
        [string]$LogLevelLogFile = "Info"
    )


    $CommandName = $PSCmdlet.MyInvocation.InvocationName;
    $ParameterList = (Get-Command -Name $CommandName).Parameters;

    invokeSvmtool -ParameterList ([ref]$ParameterList) -Action "ImportInstance"
}
<#
.Synopsis
    Shows the SvmDr Script version
.DESCRIPTION
	Shows the SvmDr Script version

.EXAMPLE 

    Show-SvmDrVersion

    Script Version [0.1.1]
    Module Version [1.0.9]

#>
function Show-SvmDrVersion {
    [CmdletBinding()]
    $scriptPath = "$PSScriptRoot\svmtool.ps1"
    Invoke-Expression "& `"$scriptPath`" -Version"
}