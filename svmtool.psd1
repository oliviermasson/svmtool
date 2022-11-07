#
# Module manifest for module 'svmtool'
#
# Authors : Mirko Van Colen & Olivier Masson
#
# Generated on: 2018-10-09
#
# Updated by : Olivier Masson
# Updated on : 2022-11-07
#
# Version Control :
#   1.0.0 : Initial version
#   1.0.1 : Add DefaultLDAPCredentials
#   1.0.2 : Add XDPPolicy, MirrorSchedule, NoSnapmirrorUpdate, NoSnapmirrorWait
#   1.0.3 : Fix update of XDPPolicy during ConfigureDR or UpdateDR
#   1.0.4 : Add custom AD OU & tmp cifs lif vlan to join in AD
#   1.0.5 : Fix check if CIFS server is running
#   1.0.6 : Added skipVscanFpolicy
#   1.0.7 : Added SnapmirrorType & ForceCloneOriginal option
#   1.0.8 : Introduce PreserveIdentity Mode
#   1.0.9 : Modify UpdateDR argument for PreserveIdentity mode and allow Update_CIFS_usergroup to works in this situation
#   1.1.0 : Add TieringPolicy option for ConfigureDR and UpdateDR wrapper
#   1.1.1 : Add wrapper for RemoveInstance
#   1.1.2 : Add wrapper for RestoreObject
#   1.1.3 : Fix some function's parameter
#   1.1.4 : Add NonInteractive parameter to Restore-SvmDr
#           Add ForceRestoreOriginal parameter to Restore-SvmDr
#   1.1.5 : Add ForceRestoreOriginal parameter to Restore-ObjectSvmDr
#   1.1.6 : Add DefaultChapCredentials paramater
#           
@{

    # Script module or binary module file associated with this manifest.
    RootModule        = '.\svmtool.psm1'

    # Version number of this module.
    ModuleVersion     = '1.1.6'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = 'ea918462-c6e7-49b9-bf79-1fa70df3fbba'

    # Author of this module
    Author            = 'Mirko Van Colen'

    # Company or vendor of this module
    CompanyName       = 'NetApp'

    # Copyright statement for this module
    Copyright         = '(c) 2020 Netapp. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'This module contains several tools (cmdlet) to work with SVM in order to perform SVMDR with Metrocluster on source or destination, Backup and Restore of configuration, etc...'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '3.0'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = '*-*SvmDr*'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = '*'

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    ModuleList        = @('svmtools')

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/CXO-Automation/svmtool'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI       = 'https://github.com/CXO-Automation/svmtool'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

