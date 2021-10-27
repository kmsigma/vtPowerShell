function New-VtConnection {
    <#
.Synopsis

.DESCRIPTION

.EXAMPLE

.EXAMPLE

.EXAMPLE

.EXAMPLE

.INPUTS

.OUTPUTS

.NOTES

.COMPONENT
    TBD
.ROLE
    TBD
.LINK
    Online REST API Documentation: 
#>
    [CmdletBinding(
        DefaultParameterSetName = 'Username/API Key',
        SupportsShouldProcess = $true, 
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/',
        ConfirmImpact = 'Medium'
    )]
    [Alias('Connect-VtCommunity')]
    
    Param (

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Authentication Header',
            Position = 0
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Username/API Key',
            Position = 0
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$CommunityUrl,
    
        # Authentication Header for the community
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Authentication Header',
            Position = 1
        )]
        [Parameter(ParameterSetName = 'Profile File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader,

        # Username for Connection to Community
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Username/API Key',
            Position = 1
        )]
        [Parameter(ParameterSetName = 'Profile File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        # API Key for Connection to Community
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Username/API Key',
            Position = 2
        )]
        [Parameter(ParameterSetName = 'Profile File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(20, 20)]
        [string]$ApiKey,

        # Store the credentials as a file?
        [Parameter(ParameterSetName = 'Authentication Header')]
        [Parameter(ParameterSetName = 'Username/API Key')]
        [Parameter(ParameterSetName = 'Profile File')]
        [switch]$Save,

        # File to Store.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Authentication Header')]
        [Parameter(ParameterSetName = 'Username/API Key')]
        [Parameter(ParameterSetName = 'Profile File')]
        [Alias('Path')]
        [string]$ProfilePath,

        # Overwrite the file if it exists
        [Parameter(ParameterSetName = 'Authentication Header')]
        [Parameter(ParameterSetName = 'Username/API Key')]
        [Parameter(ParameterSetName = 'Profile File')]
        [switch]$Force
    )
    BEGIN { 
        # Nothing to see here

    }
    PROCESS { 
        if ( $PSCmdlet.ParameterSetName -eq 'Username/API Key' ) {
            Write-Verbose -Message "Using Username ($Username) and API Key"
            $Authentication = ConvertTo-VtAuthHeader -Username $Username -ApiKey $ApiKey -WhatIf:$false
        }

        if ( $PSCmdlet.ShouldProcess("$CommunityUrl", "Build connection information") ) {
            Write-Verbose -Message "Building connection information for $CommunityUrl"
            # Build the Object
            $AuthObject = [PSCustomObject]@{
                Community      = $CommunityUrl
                Authentication = $Authentication
                CreateDate     = Get-Date
                CreatedBy      = $env:USERPROFILE ? "$( $env:USERDOMAIN )\$( $env:USERNAME )" : $env:USER
                CreatedOn      = $env:USERPROFILE ? $env:COMPUTERNAME : $env:NAME
            }
            
            if ( $Save ) {
                if ( -not $ProfilePath ) {
                    Write-Verbose -Message "Path not provided.  Using the default location (USERPROFILE)\.vtPowerShell\DefaultCommunity.json"
                    if ( $env:HOME ) {
                        # Linux
                        Write-Verbose -Message "Operating System Detection: Non-Windows (macOS / Linux)"
                        $ParentPath = ( Join-Path -Path $env:HOME -ChildPath '.vtPowerShell' )
                        $ProfilePath = Join-Path $ParentPath -ChildPath "DefaultCommunity.json"
                    }
                    elseif ( $env:USERPROFILE ) {
                        # Windows
                        Write-Verbose -Message "Operating System Detection: Windows"
                        $ParentPath = ( Join-Path -Path $env:USERPROFILE -ChildPath '.vtPowerShell' )
                        $ProfilePath = Join-Path $ParentPath -ChildPath "DefaultCommunity.json"
                    }
                    else {
                        Write-Error -Message "Unable to detect default location." -RecommendedAction "Provide a valid file path to the -ProfilePath parameter" -ErrorAction Stop
                    }
                }
                else {
                    Write-Verbose -Message "Path provided as '$ProfilePath'"
                    $ParentPath = Split-Path -Path $ProfilePath -Parent
                }
                if ( $ParentPath ) {
                    if ( Test-Path -Path $ParentPath -PathType Container -ErrorAction SilentlyContinue ) {
                        Write-Verbose -Message "Parent Path is a directory"
                    }
                    elseif ( Test-Path -Path $ParentPath -PathType Leaf -ErrorAction SilentlyContinue ) {
                        Write-Error -Message "Parent Path is a file" -RecommendedAction "Provide a valid path for the output" -ErrorAction Stop
                    }
                    else {
                        Write-Verbose -Message "Parent Path does not exist.  Creating..."
                        New-Item -ItemType Directory -Path $ParentPath | Out-Null
                        
                    }
                }
                
                
                # Check for file existence
                $ProfileExists = Test-Path $ProfilePath -ErrorAction SilentlyContinue
                if ( $ProfileExists -and -not $Force ) {
                    # Prompt for a Choice
                    Write-Warning -Message "File already exists at '$ProfilePath'"
                    $OverWriteTitle = "Profile File Already Exists"
                    $OverWriteInfo = "Do you wish to overwrite the existing file?"
                    $OverwriteOptions = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
                    $OverwriteDefault = [int]1
                    $OverwriteChoice = $host.UI.PromptForChoice($OverWriteTitle , $OverwriteInfo , $OverwriteOptions, $OverwriteDefault)
                    # If they answered "Yes", override the default $Force value
                    $Force = ( $OverwriteChoice -eq 0 )
                }
                
                if ( -not $ProfileExists -or $Force ) {
                    Write-Verbose -Message "Exporting Connection Profile to '$ProfilePath'"
                    $AuthObject | ConvertTo-Json | Out-File -Path $ProfilePath -Force:$Force
                }
                elseif ( $ProfileExists -and -not $Force ) {
                    Write-Error -Message "Existing connection profile file exists at '$ProfilePath'" -RecommendedAction "If you wish to overwrite, you can use the -Force parameter." -ErrorAction Stop
                }
                
            }
            else {
                Write-Verbose -Message "Not saving the connection information - output object"
                $AuthObject
            }
            
        }
    }
    END {
        # Nothing to see here
    }
}