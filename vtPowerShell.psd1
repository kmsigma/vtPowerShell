#
# Module manifest for module 'vtPowerShell'
#
# Generated by: Kevin M. Sparenberg (https://community.telligent.com/members/kmsigma)
#
# Generated on: 10/6/2021
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'vtPowerShell.psm1'

    # Version number of this module.
    ModuleVersion        = '0.0.1'

    # Supported PSEditions
    CompatiblePSEditions = @('Desk', 'Core')

    # ID used to uniquely identify this module
    GUID                 = '7923a153-6984-47ec-a6de-41469b8cdbcc'

    # Author of this module
    Author               = 'Kevin M. Sparenberg'

    # Company or vendor of this module
    CompanyName          = 'No company, just me.'

    # Copyright statement for this module
    Copyright            = '(c) 2023 Kevin M. Sparenberg. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Collection of PowerShell sunctions for working with Verint/Telligent Communities via their API'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '7.0.0'

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
    NestedModules        = @(
        'function_Get-VtAbuseReport.ps1'
        'function_Get-VtAbusiveContent.ps1'
        'function_Get-VtAchievement.ps1'
        'function_Get-VtAchievementSummary.ps1'
        'function_ConvertTo-VtAuthHeader.ps1'
        'function_Get-VtBlog.ps1'
        'function_Get-VtBlogPost.ps1'
        'function_Get-VtChallenge.ps1'
        'function_Get-VtForum.ps1'
        'function_Get-VtForumThread.ps1'
        'function_Get-VtGallery.ps1'
        'function_Get-VtGalleryMedia.ps1'
        'function_Get-VtGroup.ps1'
        'function_Get-VtGroupMembership.ps1'
        'function_Get-VtIdea.ps1'
        'function_Get-VtPointTransaction.ps1'
        'function_Get-VtSysNotification.ps1'
        'function_Get-VtUser.ps1'
        'function_Get-VtWiki.ps1'
        'function_New-VtPointTransaction.ps1'
        'function_New-VtConnection.ps1'
        'function_Remove-VtPointTransaction.ps1'
        'function_Remove-VtComment.ps1'
        'function_Remove-VtForumThread.ps1'
        'function_Remove-VtForumThreadReply.ps1'
        'function_Remove-VtUser.ps1'
        'function_Send-VtGroupInvite.ps1'
        'function_Update-VtAuthHeader.ps1'
        'function_Set-VtBlog.ps1'
        'function_Set-VtBlogPost.ps1'
        'function_Set-VtForumThread.ps1'
        'function_Set-VtGallery.ps1'
        'function_Set-VtGalleryMedia.ps1'
        'function_Set-VtGroup.ps1'
        'function_Set-VtUser.ps1'
        'function_Set-VtAchievement.ps1'
        'function_Test-VtConnection.ps1'
        'function_ConvertFrom-VtHtmlString.ps1'
        'vtPowerShell.psm1'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @(
        'ConvertFrom-VtHtmlString'
        'ConvertTo-QueryString'
        'ConvertTo-VtAuthHeader'
        'Get-VtAbuseReport'
        'Get-VtAbusiveContent'
        'Get-VtAchievement'
        'Get-VtAchievementSummary'
        'Get-VtBlog'
        'Get-VtBlogPost'
        'Get-VtChallenge'
        'Get-VtForum'
        'Get-VtForumThread'
        'Get-VtGallery'
        'Get-VtGalleryMedia'
        'Get-VtGroup'
        'Get-VtGroupMembership'
        'Get-VtIdea'
        'Get-VtPointTransaction'
        'Get-VtSysNotification'
        'Get-VtUser'
        'Get-VtWiki'
        'New-VtConnection'
        'New-VtPointTransaction'
        'Remove-VtComment'
        'Remove-VtForumThread'
        'Remove-VtForumThreadReply'
        'Remove-VtPointTransaction'
        'Remove-VtUser'
        'Send-VtGroupInvite'
        'Set-VtAchievement'
        'Set-VtAuthHeader'
        'Set-VtBlog'
        'Set-VtBlogPost'
        'Set-VtForumThread'
        'Set-VtGallery'
        'Set-VtGalleryMedia'
        'Set-VtGroup'
        'Set-VtUser'
        'Test-VtConnection'
        'Update-VtAuthHeader'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @( )

    # Variables to export from this module
    VariablesToExport    = @( )

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @( )

    # DSC resources to export from this module
    # DscResourcesToExport = @( )

    # List of all modules packaged with this module
    # ModuleList = @( )

    # List of all files packaged with this module
    <#
    FileList             = @( 
        'function_Get-VtAbuseReport.ps1',
        'function_Get-VtAbuseReport.ps1',
        'function_ConvertTo-VtAuthHeader.ps1',
        'function_Get-VtBlog.ps1',
        'function_Get-VtBlogPost.ps1',
        'function_Get-VtChallenge.ps1',
        'function_Get-VtForum.ps1',
        'function_Get-VtForumThread.ps1',
        'function_Get-VtGallery.ps1',
        'function_Get-VtGalleryMedia.ps1',
        'function_Get-VtGroup.ps1',
        'function_Get-VtIdea.ps1',
        'function_Get-VtPointTransaction.ps1',
        'function_Get-VtSysNotification.ps1',
        'function_Get-VtUser.ps1',
        'function_New-VtPointTransaction.ps1',
        'function_New-VtConnection.ps1',
        'function_Remove-VtPointTransaction.ps1',
        'function_Remove-VtUser.ps1',
        'function_Set-VtAuthHeader.ps1',
        'function_Set-VtBlog.ps1',
        'function_Set-VtForumThread.ps1',
        'function_Set-VtGallery.ps1',
        'function_Set-VtGalleryMedia.ps1',
        'function_Set-VtUser.ps1',
        'function_Test-VtConnection.ps1'
    )
    #>

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

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
    #DefaultCommandPrefix = ''

}

