function Get-VtTag {
    [CmdletBinding(
        DefaultParameterSetName = 'All Tags with Connection File',
        SupportsShouldProcess = $true,     
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64511/list-aggregate-tags-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Tags to use for lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Tags with Authentication Header')]
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Tags with Connection Profile'
        )]
        [Parameter(
            Mandatory = $false, 
            ParameterSetName = 'Tags with Connection File'
        )]
        [string[]]$Tags,
    

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Tags with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Tags with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("AuthHeader")]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Tags with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Tags with Connection File')]
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
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateSet('Date')]
        [string]$SortBy = 'Date',

        # Sort Order (defaults to descending)
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$Descending,

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
        if ( $SortBy ) {
            $UriParameters["SortBy"] = $SortBy
            if ( $Descending ) {
                $UriParameters["SortOrder"] = 'Descending'
            }
            else {
                $UriParameters["SortOrder"] = 'Ascending'
            } # else leave as default
        }

        
        $PropertiesToReturn = @(
            @{ Name = "ContentCount"; Expression = { $_.ContentCount } }
            @{ Name = "Tag"; Expression = { $_.Name } }
            @{ Name = "TagFromHtml"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } }
            @{ Name = "LastUsed"; Expression = { $_.LatestTaggedDate } }
        )
    
    }
    PROCESS {
        switch -wildcard ( $PSCmdlet.ParameterSetName ) {
            'Tags *' { 
                Write-Verbose -Message "Detected Search by Tags"
                if ( $Tags ) {
                    Write-Verbose -Message "Tags detected, building list"
                    $UriParameters["Tags"] = $Tags -join ','
                } else {
                    Write-Verbose -Message "Tags not detected, increasing batch size"
                    $UriParameters["PageSize"] = 100
                }
            }
        }
        
        $Operations = @()
        $UriParameters.GetEnumerator() | Where-Object { $_.Key -notlike "*Page*" } | ForEach-Object { $Operations += "$( $_.Key ) is '$( $_.Value )'" }
        $Operations = "Query for Tags with: $( $Operations -join " AND " )"
        if ( $PSCmdlet.ShouldProcess( $Operations ) ) {

            # Using the "LIST" API
            #region process the calls
            $Uri = 'api.ashx/v2/aggregatetags.json'
            $TotalReturned = 0
            $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
            $StopWatch.Start()
            do {
                Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                if ( $TotalReturned -and -not $SuppressProgressBar ) {
                    $PbActivity = "Retrieving Tags from $Community"
                    $PbCurrentOperation = ( "Retrieving $BatchSize records of $( $TagsResponse.TotalCount )" )
                    $PbStatus = "[$TotalReturned/$( $TagsResponse.TotalCount )] records retrieved"
                    $PbPercent = ( ( $TotalReturned / $TagsResponse.TotalCount ) * 100 )
                    $PbSecondsRemaining = [int64]( ( $UriParameters["PageIndex"] / $StopWatch.Elapsed.TotalSeconds ) * ( [math]::Ceiling(( $TagsResponse.TotalCount / $UriParameters["PageSize"] )) - $UriParameters["PageIndex"] ) )
                    if ( $PbSecondsRemaining -gt 2147483647 ) {
                            $PbSecondsRemaining = -1
                    }
                    Write-Progress -Activity $PbActivity -CurrentOperation $PbCurrentOperation -Status $PbStatus -PercentComplete $PbPercent -SecondsRemaining $PbSecondsRemaining

                }
                $TagsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                if ( $TagsResponse ) {
                    $TotalReturned += $TagsResponse.AggregateTags.Count
                    if ( $ReturnDetails ) {
                        $TagsResponse.AggregateTags
                    }
                    else {
                        $TagsResponse.AggregateTags | Select-Object -Property $PropertiesToReturn
                    }
                }
                $UriParameters["PageIndex"]++
            } while ($TotalReturned -lt $TagsResponse.TotalCount)
            #endregion
            $StopWatch.Stop()
            Remove-Variable -Name StopWatch -ErrorAction SilentlyContinue
        }
        # Either process kicks off the progress bar, so shut it down here
        if ( -not $SuppressProgressBar ) {
            Write-Progress -Activity $PbActivity -Completed
        }

    }
    END {
        # Nothing to see here
    }
}