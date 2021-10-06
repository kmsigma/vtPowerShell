#
# Module manifest for module 'vtPowerShell'
#
# Generated by: Kevin M. Sparenberg (https://community.telligent.com/members/kmsigma)
#
# Generated on: 10/6/2021
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule        = '.\func_Telligent.psm1'

    # Version number of this module.
    ModuleVersion     = '0.0.1'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = '7923a153-6984-47ec-a6de-41469b8cdbcc'

    # Author of this module
    Author            = 'Kevin M. Sparenberg'

    # Company or vendor of this module
    CompanyName       = 'No Company, just me.'

    # Copyright statement for this module
    Copyright         = '(c) 2021 Kevin M. Sparenberg. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Collection of PowerShell Functions for working with Verint/Telligent Communities via their API'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

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
    FunctionsToExport = ''

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = 'Get-VtAuthHeader',
    'Set-VtAuthHeader',
    'Get-VtUser',
    'Set-VtUser',
    'Remove-VtUser',
    'Get-VtBlog',
    'Get-VtBlogPost',
    'Set-VtBlog',
    'Get-VtForum',
    'Get-VtForumThread',
    'Set-VtForumThread',
    'Add-VtPointTransaction',
    'Get-VtPointTransaction',
    'Remove-VtPointTransaction',
    'Get-VtSysNotification',
    'Get-VtIdea',
    'Get-VtGroup',
    'Get-VtGallery',
    'Set-VtGallery',
    'Get-VtGalleryMedia',
    'Set-VtGalleryMedia',
    'Get-VtChallenge',
    'Get-VtAbuseReport'

    # Variables to export from this module
    VariablesToExport = ''

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = ''

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    FileList          = @(
        'func_Utilities.psm1',
        'func_Abuse.psm1',
        'func_Blogs.psm1',
        'func_Challenges.psm1',
        'func_Galleries.psm1',
        'func_Groups.psm1',
        'func_Ideas.psm1',
        'func_Notifications.psm1',
        'func_Points.psm1',
        'func_Telligent.psm1',
        'func_Threads.psm1',
        'func_Users.psm1'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Vertint', 'Telligent', 'Online Community')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/kmsigma/vtPowerShell/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/kmsigma/vtPowerShell'

            # A URL to an icon representing this module.
            IconUri      = 'https://github.com/kmsigma/vtPowerShell/raw/main/vtPowerShell.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'First conversion of "bunch of scripts" to a module'

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

