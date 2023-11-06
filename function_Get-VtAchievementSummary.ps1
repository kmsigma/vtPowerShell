function Get-VtAchievementSummary {
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
        DefaultParameterSetName = 'Achievement Summaries with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64488/list-AchievementSummary-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        [Parameter(
            ParameterSetName = 'Achievement Summaries with Authentication Header'
        )]
        [Parameter(
            ParameterSetName = 'Achievement Summaries with Connection Profile'
        )]
        [Parameter(
            ParameterSetName = 'Achievement Summaries with Connection File'
        )]
        [guid[]]$AchievementId,


        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Achievement Summaries with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Achievement Summaries by Author ID with Authentication Header'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Achievement Summaries with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Achievement Summaries by Author ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Achievement Summaries with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Achievement Summaries by Author ID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Achievement Summaries with Connection File')]
        [Parameter(ParameterSetName = 'Achievement Summaries by Author ID with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),


        # Is the AchievementSummary enabled or disabled?
        # Default to enabled
        [Parameter()]
        [switch]$Disabled,

        # Sort order: Achievement Count, Display Name [default], or First Award Date
        [Parameter()]
        [ValidateSet('AchievementCount', 'DisplayName', 'FirstAwardDate')]
        [string]$SortBy = 'DisplayName',
        
        # Sort order
        # Default to descending
        [Parameter()]
        [switch]$Descending,

        [Parameter()]
        [datetime]$CreatedBeforeDate,

        [Parameter()]
        [datetime]$CreatedAfterDate,

        <#
        # Yet unimplemented
        [Paremeter()]
        [int]$GroupId
#>


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
    
        # Set the Uri for the target
        $Uri = 'api.ashx/v2/achievement/summaries.json'
    
        $UriParameters = @{}
        
        Write-Verbose -Message "Assigning Achievement ID"
        if ( $AchievementId ) {
            $UriParameters["AchievementId"] = $AchievementId
        }
        
        Write-Verbose -Message "Assigning sort field"
        if ( $SortBy ) {
            $UriParameters["SortBy"] = $SortBy
        }

        Write-Verbose -Message "Assigning sort order"
        if ( $Descending ) {
            $UriParameters["SortOrder"] = 'Descending'
        }
        else {
            $UriParameters["SortOrder"] = 'Ascending'
        }

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageSize"] = $BatchSize
        $UriParameters["PageIndex"] = 0

        $PropertiesToReturn = @(
            @{ Name = 'AchievementSummaryId'; Expression = { $_.Id } },
            @{ Name = 'Title'; Expression = { $_.Title | ConvertFrom-HtmlString -Verbose:$false } },
            @{ Name = 'Criteria'; Expression = { $_.Criteria | ConvertFrom-HtmlString -Verbose:$false } },
            'BadgeIconUrl',
            'DateCreated',
            'Enabled'
        )
    }
    PROCESS {
    
        $TotalAchievementSummarys = 0
        $Operations = @()
        $UriParameters.GetEnumerator() | Where-Object { $_.Key -notlike "*Page*" } | ForEach-Object { $Operations += "$( $_.Key ) is '$( $_.Value )'" }
        $Operations = "Query for Achievement Summarys with: $( $Operations -join " AND " )"
        if ( $PSCmdlet.ShouldProcess($Operations) ) {
            do {
                Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                if ( $TotalAchievementSummarys -and -not $SuppressProgressBar ) {
                    Write-Progress -Activity "Retrieving AchievementSummaries from $Community" -CurrentOperation ( "Retrieving $BatchSize records of $( $AchievementSummarysResponse.TotalCount )" ) -Status "[$TotalAchievementSummarys/$( $AchievementSummarysResponse.TotalCount )] records retrieved" -PercentComplete ( ( $TotalAchievementSummarys / $AchievementSummarysResponse.TotalCount ) * 100 )
                }
                Write-Verbose -Message "Making call for AchievementSummariess"
                $AchievementSummarysResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                if ( $AchievementSummarysResponse ) {
                    $TotalAchievementSummarys += $AchievementSummarysResponse.AchievementSummarys.Count
                    if ( $ReturnDetails ) {
                        $AchievementSummarysResponse.AchievementSummarys
                    }
                    else {
                        $AchievementSummarysResponse.AchievementSummarys | Select-Object -Property $PropertiesToReturn
                    }
                    
                    $UriParameters["PageIndex"]++
                }
            } while ( $TotalAchievementSummarys -lt $AchievementSummarysResponse.TotalCount )
            if ( -not $SuppressProgressBar ) {
                Write-Progress -Activity "Retrieving Users from $Community" -Completed
            }
        }
    }
    
    END {
        # Nothing to see here
    }
}