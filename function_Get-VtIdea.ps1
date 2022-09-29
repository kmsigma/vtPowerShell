function Get-VtIdea {
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
        DefaultParameterSetName = 'Ideas by User ID with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64723/list-idea-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    param (
        
        # Idea ID for the lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Ideas by User ID with Authentication Header'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Ideas by User ID with Connection Profile'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Ideas by User ID with Connection File'
        )]
        [Alias("Id")]
        [int64[]]$UserId,
        
        # Filter for only Ideas in a specific group
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Ideas by Group ID Connection File'
        )]
        [int64[]]$GroupId,

        # Filter for only Ideas in a specific status (Default is "Any")
        [Parameter()]
        [ValidateSet("Any", "Open", "ComingSoon", "Implemented", "Closed")]
        [string]$Status = 'Any',

        # Sort ideas in a specific order (Default is "Date")
        [Parameter()]
        [ValidateSet("Date", "Topic", "Score", "TotalVotes", "YesVotes", "NoVotes", "lastUpdatedDate")]
        [string]$SortyBy = 'Date',

        # Sort ideas in a specific order (Default is "Descending")
        [Parameter()]
        [switch]$Descdencing,

        # Include the body
        [Parameter()]
        [switch]$IncludeDescription,

        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Details")]
        [switch]$ReturnDetails,

        # Number of entries to get per batch (default of 20)
        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Ideas by User ID with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Ideas by Group ID with Authentication Header'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Ideas by User ID Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Ideas by Group ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Ideas by User ID Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Ideas by Group ID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Ideas by User ID Connection File')]
        [Parameter(ParameterSetName = 'Ideas by Group ID with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),

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

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $UriParameters = @{}
        $UriParameters['PageSize'] = $BatchSize
        $UriParameters['PageIndex'] = 0

        if ( $GroupId ) {
            $UriParameters['GroupId'] = $GroupId
        }
        if ( $Status -ne 'Any' ) {
            $UriParameters['Status'] = $Status
        }
        if ( $SortyBy ) {
            $UriParameters['SortBy'] = $SortyBy
            if ( -not $Descdencing ) {
                $UriParameters['SortOrder'] = 'ascending'
            }
            else {
                $UriParameters['SortOrder'] = 'descending'
            }
        }
        
        $PropertiesToReturn = @(
            @{ Name = "IdeaId"; Expression = { $_.Id } },
            @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } },
            @{ Name = "Status"; Expression = { $_.Status.Name } },
            @{ Name = "Author"; Expression = { $_.AuthorUser.Username } },
            'CreatedDate',
            'LastUpdatedDate',
            'Url',
            'Score',
            @{ Name = "StatusNote"; Expression = { $_.CurrentStatus.Note | ConvertFrom-Html } }
        )

        if ( $IncludeDescription ) {
            $PropertiesToReturn += @{ Name = 'Description'; Expression = { $_.Description | ConvertFrom-Html } }
        }

        $Uri = 'api.ashx/v2/ideas/ideas.json'
        
    }
    PROCESS {

        switch -wildcard ( $PSCmdlet.ParameterSetName ) {
            'Ideas by User ID *' { 
                Write-Verbose -Message "Detected query by UserId"
                
            }
            
            'Ideas by Group ID *' {
                Write-Verbose -Message "Detected query by Group ID"

            }
            default {
                Write-Verbose -Message "Detected search for All Ideas"
                Write-Warning -Message "Collecting all users can be time consuming.  You've been warned."
                # Overriding the Batch File size to speed up processing
                $BatchSize = 100
                $UriParameters["PageSize"] = $BatchSize
            }
        }

        if ( $PSCmdlet.ShouldProcess($Community, "Get Ideas from") ) {
            if ( $UserId ) {
                ForEach ( $U in $UserId ) {
                    # If we have a User ID, we should pass it as a parameter
                    $UriParameters["UserID"] = $U
                    $TotalReturned = 0
                    do {
                        if ( $TotalReturned -and -not $SuppressProgressBar) {
                            Write-Progress -Activity "Getting Ideas for User: $U" -Status "Returned $( $TotalReturned ) / $( $IdeasResponse.TotalCount ) Records" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1 ) for $BatchSise records" -PercentComplete ( $TotalReturned / $IdeasResponse.TotalCount * 100 )
                        }
                        elseif ( -not $SuppressProgressBar ) {
                            Write-Progress -Activity "Getting Ideas for User: $U" -Status "Making first call for $BatchSize records" -CurrentOperation "Making first call for $BatchSize records"
                        }
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                        $IdeasResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                        if ( $IdeasResponse ) {
                            $TotalReturned += $IdeasResponse.Ideas.Count
                            if ( $ReturnDetails ) {
                                $IdeasResponse.Ideas
                            }
                            else {
                                $IdeasResponse.Ideas | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        $UriParameters["PageIndex"]++
                    } while ($TotalReturned -lt $IdeasResponse.TotalCount)
                    Write-Progress -Activity "Getting Ideas for User: $U" -Completed
                }
            }
            elseif ( $GroupId ) {
                ForEach ( $G in $GroupId ) {
                    # If we have a User ID, we should pass it as a parameter
                    $UriParameters["GroupID"] = $G
                    $TotalReturned = 0
                    do {
                        if ( $TotalReturned -and -not $SuppressProgressBar) {
                            Write-Progress -Activity "Getting Idease for Group: $G" -Status "Returned $( $TotalReturned ) / $( $IdeasResponse.TotalCount ) Records" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1 ) for $BatchSise records" -PercentComplete ( $TotalReturned / $IdeasResponse.TotalCount * 100 )
                        }
                        elseif ( -not $SuppressProgressBar ) {
                            Write-Progress -Activity "Getting Idease for Group: $G" -Status "Making first call for $BatchSize records" -CurrentOperation "Making first call for $BatchSize records"
                        }
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                        $IdeasResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                        if ( $IdeasResponse ) {
                            $TotalReturned += $IdeasResponse.Ideas.Count
                            if ( $ReturnDetails ) {
                                $IdeasResponse.Ideas
                            }
                            else {
                                $IdeasResponse.Ideas | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        $UriParameters["PageIndex"]++
                    } while ($TotalReturned -lt $IdeasResponse.TotalCount)
                    Write-Progress -Activity "Getting Idease for Group: $G" -Completed
                }
            }
            else {
                # Get everything with no filters
                $TotalReturned = 0
                    do {
                        if ( $TotalReturned -and -not $SuppressProgressBar) {
                            Write-Progress -Activity "Getting All Ideas" -Status "Returned $( $TotalReturned ) / $( $IdeasResponse.TotalCount ) Records" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1 ) for $BatchSise records" -PercentComplete ( $TotalReturned / $IdeasResponse.TotalCount * 100 )
                        }
                        elseif ( -not $SuppressProgressBar ) {
                            Write-Progress -Activity "Getting All Ideas" -Status "Making first call for $BatchSize records" -CurrentOperation "Making first call for $BatchSize records"
                        }
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                        $IdeasResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                        if ( $IdeasResponse ) {
                            $TotalReturned += $IdeasResponse.Ideas.Count
                            if ( $ReturnDetails ) {
                                $IdeasResponse.Ideas
                            }
                            else {
                                $IdeasResponse.Ideas | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        $UriParameters["PageIndex"]++
                    } while ($TotalReturned -lt $IdeasResponse.TotalCount)
                    Write-Progress -Activity "Getting All Ideas" -Completed
            }
        }
    }
    
    END {
        
    }
}