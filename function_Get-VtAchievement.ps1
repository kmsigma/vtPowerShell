function Get-VtAchievement {
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
        Online REST API Documentation: 
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Achievements with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64488/list-achievement-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
    
        # What achievement IDs (if any) to we want to get
        [Parameter(ParameterSetName = 'Achievements by Achievement ID with Authentication Header')]
        [Parameter(ParameterSetName = 'Achievements by Achievement ID with Connection Profile')]
        [Parameter(ParameterSetName = 'Achievements by Achievement ID with Connection File')]
        [Alias("id")]
        [guid[]]$AchievementId,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Achievements with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Achievements by Achievement ID with Authentication Header'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Achievements with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Achievements by Achievement ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Achievements with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Achievements by Achievement ID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Achievements with Connection File')]
        [Parameter(ParameterSetName = 'Achievements by Achievement ID with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),


        # Is the achievement enabled or disabled?
        # Default to enabled
        [Parameter()]
        [switch]$Disabled,

        [Parameter()]
        [switch]$ShowHtmlEncoding,

        # Sort order: Title [default] or DateCreated
        [Parameter()]
        [ValidateSet('Title', 'DateCreated')]
        [string]$SortyBy = 'Title',
        
        # Sort order
        # Default to descending
        [Parameter()]
        [switch]$Descending,

        # Should we return all details?
        [Parameter()]
        [switch]$ReturnDetails,

        # Size of Batches to Query from the API
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,

        # Suppress the progress bar
        [Parameter()]
        [switch]$SuppressProgressBar
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
    
        if ( -not $AchievementId ) {
            # Set the Uri for the target (List Mode)
            $Uri = 'api.ashx/v2/achievements.json'

            # Set default page index, page size, and add any other filters
            $UriParameters = @{}
            $UriParameters["PageSize"] = $BatchSize
            $UriParameters["PageIndex"] = 0
        
            # Only applies for list mode
            Write-Verbose -Message "Assigning sort field"
            if ( $SortyBy ) {
                $UriParameters["SortyBy"] = $SortBy
            }
    
            Write-Verbose -Message "Assigning sort order"
            if ( $Descending ) {
                $UriParameters["SortOrder"] = 'Descending'
            }
            else {
                $UriParameters["SortOrder"] = 'Ascending'
            }
    
            Write-Verbose -Message "Assigning enabled/disabled"
            if ( $Disabled ) {
                $UriParameters["Enabled"] = 'false'
            }
            else {
                $UriParameters["enabled"] = 'true'
            }
        
        }

        if ( $ShowHtmlEncoding ) {
            $PropertiesToReturn = @(
                @{ Name = 'AchievementId'; Expression = { $_.Id } },
                'Title',
                'Criteria',
                'BadgeIconUrl',
                'DateCreated',
                'Enabled'
            )
        }
        else {
            $PropertiesToReturn = @(
                @{ Name = 'AchievementId'; Expression = { $_.Id } },
                @{ Name = 'Title'; Expression = { $_.Title | ConvertFrom-HtmlString -Verbose:$false } },
                @{ Name = 'Criteria'; Expression = { $_.Criteria | ConvertFrom-HtmlString -Verbose:$false } },
                'BadgeIconUrl',
                'DateCreated',
                'Enabled'
            )
        }
        
    }
    PROCESS {
    
        if ( $AchievementId ) {
            
            ForEach ( $a in $AchievementId ) {
                # Set the Uri for the target (Show Mode)
                $Uri = "api.ashx/v2/achievement/$( $a ).json"
                $HttpMethod = "GET"
                $RestMethod = "GET"
                $UriParameters = @{} 
                if ( $PSCmdlet.ShouldProcess($Community, "Get Achievement ID: $a") ) {
                    $AchievementResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod ) -Method $HttpMethod
                    if ( $AchievementResponse ) {
                        if ( $ReturnDetails ) {
                            $AchievementResponss.Achievement
                        }
                        else {
                            $AchievementResponse.Achievement | Select-Object -Property $PropertiesToReturn
                        }
                    }
                }
            }
            
        }
        else {
            $TotalAchievements = 0
            $Operations = @()
            $UriParameters.GetEnumerator() | Where-Object { $_.Key -notlike "*Page*" } | ForEach-Object { $Operations += "$( $_.Key ) is '$( $_.Value )'" }
            $Operations = "Query for Achievements with: $( $Operations -join " AND " )"
            if ( $PSCmdlet.ShouldProcess($Operations) ) {
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    if ( $TotalAchievements -and -not $SuppressProgressBar ) {
                        Write-Progress -Activity "Retrieving Achievements from $Community" -CurrentOperation ( "Retrieving $BatchSize records of $( $AchievementsResponse.TotalCount )" ) -Status "[$TotalAchievements/$( $AchievementsResponse.TotalCount )] records retrieved" -PercentComplete ( ( $TotalAchievements / $AchievementsResponse.TotalCount ) * 100 )
                    }
                    Write-Verbose -Message "Making call for Achievements"
                    $AchievementsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $AchievementsResponse ) {
                        $TotalAchievements += $AchievementsResponse.Achievements.Count
                        if ( $ReturnDetails ) {
                            $AchievementsResponse.Achievements
                        }
                        else {
                            $AchievementsResponse.Achievements | Select-Object -Property $PropertiesToReturn
                        }
                    
                        $UriParameters["PageIndex"]++
                    }
                } while ( $TotalAchievements -lt $AchievementsResponse.TotalCount )
                if ( -not $SuppressProgressBar ) {
                    Write-Progress -Activity "Retrieving Users from $Community" -Completed
                }
            }
        }
    }
    
    END {
        # Nothing to see here
    }
}