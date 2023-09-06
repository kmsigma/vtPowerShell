function Set-VtAchievement {
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
        You can optionally store the VtCommunity and the VtAuthHeader as global variables and omit passing them as parameters
        Eg: $Global:VtCommunity = 'https://myCommunityDomain.domain.local/'
            $Global:VtAuthHeader = ConvertTo-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: https://community.telligent.com/community/11/w/api-documentation/64491/update-achievement-rest-endpoint
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Update achievements with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64488/list-achievement-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        # Achievements on which to operate
        [Parameter(
            Mandatory = $true
        )]
        [guid[]]$AchievementId,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Update achievements with Authentication Header'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Update achievements with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Update achievements with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Update achievements with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),


        # Set the achievement to enabled or disabled?
        # Default to enabled
        [Parameter()]
        [switch]$Disabled,

        # Set the title of the achievement
        [Parameter()]
        [string]$Title,
        
        # Set the criteria of the achievement
        [Parameter()]
        [string]$Criteria

        # To be added:
        # BadgeIconData [byte[]]
        # BadgeIconUploadContext [string]
        # RemoveAutomation [bool]
        # AutomationId [guid]
        # AutomationConfiguration [string]
    )
    
    BEGIN {
    
        switch -wildcard ( $PSCmdlet.ParameterSetName ) {

            '* Connection File' {
                Write-Verbose -Message "Getting connection information from Connection File ($ProfilePath)"
                $VtConnection = Get-Content -Path $ProfilePath | ConvertFrom-Json
                $Community = $VtConnection.Community
                # Check to see if the VtAuthHeader is empty
                $AuthHeaders = @{ }
                $VtConnection.Authentication.PSObject.Properties | ForEach-Object { $AuthHeaders[$_.Name] = $_.Value }
            }
            '* Connection Profile' {
                Write-Verbose -Message "Getting connection information from Connection Profile"
                $Community = $Connection.Community
                $AuthHeaders = $Connection.Authentication
            }
            '* Authentication Header' {
                Write-Verbose -Message "Getting connection information from Parameters"
                $Community = $VtCommunity
                $AuthHeaders = $VtAuthHeader
            }

        }
        # Build the Uri Parameters
        $Body = @{}
        if ( $Title ) {
            $Body["Title"] = $Title
        }
        if ( $Criteria ) {
            $Body["Criteria"] = $Criteria
        }

        $HttpMethod = 'POST'
        $RestMethod = 'PUT'


            $PropertiesToReturn = @(
                @{ Name = 'AchievementId'; Expression = { $_.Id } },
                @{ Name = 'Title'; Expression = { $_.Title | ConvertFrom-Html -Verbose:$false } },
                @{ Name = 'Criteria'; Expression = { $_.Criteria | ConvertFrom-Html -Verbose:$false } },
                'BadgeIconUrl',
                'DateCreated',
                'Enabled'
            )
        
        
    }
    PROCESS {
        ForEach ( $a in $AchievementId ) {

            # Build the URI
            $Uri = "api.ashx/v2/achievement/$( $a ).json"

            # Get the achievement because we'll want it for some later things
            $Achievement = Get-VtAchievement -AchievementID $a -VtCommunity $Community -VtAuthHeader $AuthHeaders -Verbose:$false -WhatIf:$false
            if ( $PSCmdlet.ShouldProcess($Community, "Update Achievement: $( $Achievement.Title )") ) {
            
                $Body["Id"] = $a
                
                # Is the achievement enabled and so we want to disable it?
                if ( $Achievement.Enabled -and $Disabled ) {
                    $Body["Enabled"] = $false
                }
                # How about currently disabled and we want to enable it?
                elseif ( ( -not ( $Achievement.Enabled ) ) -and ( -not ( $Disabled ) ) ) {
                    $Body["Enabled"] = $true
                }

                $Results = Invoke-WebRequest -Uri ( $Community + $Uri ) -Method $HttpMethod -Headers ( $AuthHeaders | Update-VtAuthHeader -Method $RestMethod ) -Body $Body
                if ( $Results ) {
                    ( $Results | ConvertFrom-Json ).Achievement | Select-Object -Property $PropertiesToReturn
                }
            }

        }
    }
    
    END {
        # Nothing to see here
    }
}