function Get-VtAbusiveContent {
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
        DefaultParameterSetName = 'Abusive Content with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64484/list-abusive-content-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # User ID to use for abuse lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Abusive Content by Author ID with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Abusive Content by Author ID with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Abusive Content by Author ID with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64]$UserId,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Abusive Content with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Abusive Content by Author ID with Authentication Header'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Abusive Content with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Abusive Content by Author ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Abusive Content with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Abusive Content by Author ID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Abusive Content with Connection File')]
        [Parameter(ParameterSetName = 'Abusive Content by Author ID with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),


        # What is the created start date for filtering the abusive content?
        [Parameter()]
        [datetime]$StartCreateDate,

        # What is the created end date for filtering the abusive content?
        [Parameter()]
        [datetime]$EndCreateDate,

        # What is the reported start date for filtering the abusive content?
        [Parameter()]
        [datetime]$StartReportDate,

        # What is the reported end date for filtering the abusive content?
        [Parameter()]
        [datetime]$EndReportDate,


        # Filter for any specific Abuse State?
        # (Abusive, Expunged, Moderated, NotAbusive, Reported)
        [Parameter()]
        [ValidateSet('Abusive', 'Expunged', 'Moderated', 'NotAbusive', 'Reported')]
        [string]$AbuseState,
        
        <#
        # Filter for any specific Appeal State?
        # [Options currently unknown]
        [Parameter()]
        [ValidateCount(0,5)]
        [ValidateSet("sun", "moon", "earth")]
        [string]$AppealState,
        #>

        # What should we sort by? (AbuseId [default], AuthorUserId, AuthorUsername)

        # What sort order? (Asc [default], Desc)

        # Should we return the raw HTML and not the normalized HTML
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$RawHtml,

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
        $Uri = 'api.ashx/v2/abusivecontent.json'
    
        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageSize"] = $BatchSize
        $UriParameters["PageIndex"] = 0
    
        Write-Verbose -Message "Assigning User ID for query"
        if ( $UserId ) {
            $UriParameters["AuthorUserId"] = $UserId
        }

        Write-Verbose -Message "Assigning Abuse State for query"
        if ( $AbuseState ) {
            $UriParameters["AbuseState"] = $AbuseState
        }

        Write-Verbose -Message "Assigning creation date for query"
        if ( $StartCreateDate ) {
            $UriParameters["StartCreateDate"] = $StartCreateDate
        }

        Write-Verbose -Message "Assigning ending date for query"
        if ( $EndCreateDate ) {
            $UriParameters["EndCreateDate"] = $EndCreateDate
        }

        Write-Verbose -Message "Assigning creation date for query"
        if ( $StartReportDate ) {
            $UriParameters["StartReportDate"] = $StartReportDate
        }

        Write-Verbose -Message "Assigning ending date for query"
        if ( $EndReportDate ) {
            $UriParameters["EndReportDate"] = $EndReportDate
        }
    
        $PropertiesToReturn = @(
            'AbusiveContentId',
            @{ Name = 'Author'; Expression = { $_.AuthorUser.DisplayName } },
            'AbuseState',
            'SpamScore',
            'HiddenDate',
            'ExpungeDate',
            'LastUpdatedDate',
            'ResolvedDate',
            'AppealsCount',
            'TotalReportCount',
            'IsAbusive',
            @{ Name = 'Url'; Expression = { $_.Content.Url } },
            'Notes'
            
        )
        if ( $RawHtml ) {
            $PropertiesToReturn += @(
                @{ Name = 'Name'; Expression = { $_.Content.HtmlName } },
                @{ Name = 'Body'; Expression = { $_.Content.HtmlDescription } }
            )
        }
        else {
            $PropertiesToReturn += @(
                @{ Name = 'Name'; Expression = { $_.Content.HtmlName | ConvertFrom-Html -Verbose:$false } },
                @{ Name = 'Body'; Expression = { $_.Content.HtmlDescription | ConvertFrom-Html -Verbose:$false } }
            )
        }
    }
    PROCESS {
    
        $TotalAbusiveContent = 0
        $Operations = @()
        $UriParameters.GetEnumerator() | Where-Object { $_.Key -notlike "*Page*" } | ForEach-Object { $Operations += "$( $_.Key ) is '$( $_.Value )'" }
        $Operations = "Query for Abuse Reports with: $( $Operations -join " AND " )"
        if ( $PSCmdlet.ShouldProcess($Operations) ) {
            do {
                Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                if ( $TotalAbusiveContent -and -not $SuppressProgressBar ) {
                    Write-Progress -Activity "Retrieving Abusive Content from $Community" -CurrentOperation ( "Retrieving $BatchSize records of $( $AbusiveContentResponse.TotalCount )" ) -Status "[$TotalAbusiveContent/$( $AbusiveContentResponse.TotalCount )] records retrieved" -PercentComplete ( ( $TotalAbusiveContent / $AbusiveContentResponse.TotalCount ) * 100 )
                }
                Write-Verbose -Message "Making call for Abusive Content"
                $AbusiveContentResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                if ( $AbusiveContentResponse ) {
                    $TotalAbusiveContent += $AbusiveContentResponse.AbusiveContents.Count
                    if ( $ReturnDetails ) {
                        $AbusiveContentResponse.AbusiveContents
                    }
                    else {
                        $AbusiveContentResponse.AbusiveContents | Select-Object -Property $PropertiesToReturn
                    }
                    
                    $UriParameters["PageIndex"]++
                }
            } while ( $TotalAbusiveContent -lt $AbusiveContentResponse.TotalCount )
            if ( -not $SuppressProgressBar ) {
                Write-Progress -Activity "Retrieving Users from $Community" -Completed
            }
        }
    }
    
    END {
        # Nothing to see here
    }
}