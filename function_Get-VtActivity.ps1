function Get-VtActivity {
    <#
    
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'All Activity with Connection File',
        SupportsShouldProcess = $true,     
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64494/list-activity-story-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Username to use for lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Username with Authentication Header')]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Username with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Username with Connection File'
        )]
        [string[]]$Username,
    
        # User ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'User Id with Authentication Header'
        )]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Connection File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int64[]]$UserId,

        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Connection File')]
        [Alias("AllUsers")]
        [switch]$All,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Username with Connection File')]
        [Parameter(ParameterSetName = 'User Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),
    
        # Should we return all details?
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$ReturnDetails,
        
        # Size of the call each time
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,

        # Sort By
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateSet(' LastUpdatedDate', 'CreatedDate', 'StoryIdsOrder')]
        [string]$SortBy = 'LastUpdatedDate',

        # Sort Order (defaults to descending)
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$Descending,

        # Filter for Start Date of Activity
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [datetime]$StartDate,

        # Filter for Start Date of Activity
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [datetime]$EndDate,

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

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

        # Set other Parameters
        $UriParameters["SortBy"] = $SortBy
        if ( $Descending ) {
            $UriParameters["SortOrder"] = 'Descending'
        } # else leave as default
        
        if ( $StartDate ) {
            $UriParameters["StartDate"] = $StartDate
        }
        if ( $EndDate ) {
            $UriParameters["EndDate"] = $EndDate
        }

        # Uri for Query
        $Uri = 'api.ashx/v2/stories.json'

        $PropertiesToReturn = @(
            @{ Name = "UserId"; Expression = { $_.id } }
            @{ Name = "Username"; Expression = { $_.Username } }
            @{ Name = "EmailAddress"; Expression = { $_.PrivateEmail } }
            @{ Name = "Status"; Expression = { $_.AccountStatus } }
            @{ Name = "ModerationStatus"; Expression = { $_.ModerationLevel } }
            @{ Name = "IsIgnored"; Expression = { $_.IsIgnored -eq "true" } }
            @{ Name = "CurrentPresence"; Expression = { $_.Presence } }
            @{ Name = "JoinedDate"; Expression = { $_.JoinDate } }
            @{ Name = "LastLoginDate"; Expression = { $_.LastLoginDate } }
            @{ Name = "LastVisitedDate"; Expression = { $_.LastVisitedDate } }
            @{ Name = "LifetimePoints"; Expression = { $_.Points } }
            @{ Name = "EmailEnabled"; Expression = { $_.ReceiveEmails -eq "true" } }
        )
    
    }
    PROCESS {
        switch -wildcard ( $PSCmdlet.ParameterSetName ) {
            'Username *' { 
                Write-Verbose -Message "Detected Search by Username"
                $UriParameters["UserId"] = Get-VtUser -Username $Username | Select-Object -ExpandProperty UserId
            }
            
            'User Id *' {
                Write-Verbose -Message "Detected Search by User ID"
                $UriParameters["UserId"] = $UserId
            }
            'All Users *' {
                Write-Verbose -Message "Detected Search for All Users"
                Write-Warning -Message "Collecting all activities can be time consuming.  You've been warned."
                $BatchSize = 100
                $UriParameters["PageSize"] = $BatchSize
            }
        }
        
        $Operations = @()
        $UriParameters.GetEnumerator() | Where-Object { $_.Key -notlike "*Page*" } | ForEach-Object { $Operations += "$( $_.Key ) is '$( $_.Value )'" }
        $Operations = "Query for Users with: $( $Operations -join " AND " )"
        if ( $PSCmdlet.ShouldProcess( $Operations ) ) {

            $TotalReturned = 0
            do {
                Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                if ( $TotalReturned -and -not $SuppressProgressBar ) {
                    Write-Progress -Activity "Retrieving Activities from $Community" -CurrentOperation ( "Retrieving $BatchSize records of $( $ActivityResponse.TotalCount )" ) -Status "[$TotalReturned/$( $ActivityResponse.TotalCount )] records retrieved" -PercentComplete ( ( $TotalReturned / $ActivityResponse.TotalCount ) * 100 )
                }
                $ActivityResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                if ( $ActivityResponse ) {
                    $TotalReturned += $ActivityResponse.ActivityStories.Count
                    if ( $ReturnDetails ) {
                        $ActivityResponse.ActivityStories
                    }
                    else {
                        $ActivityResponse.ActivityStories | Select-Object -Property $PropertiesToReturn
                    }
                }
                $UriParameters["PageIndex"]++
            } while ($TotalReturned -lt $ActivityResponse.TotalCount)
            #endregion
            

            # Either process kicks off the progress bar, so shut it down here
            if ( -not $SuppressProgressBar ) {
                Write-Progress -Activity "Retrieving Users from $Community" -Completed
            }
        }
    }
    END {
        # Nothing to see here
    }
}