function Get-VtForumThread {
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
        DefaultParameterSetName = 'Threads in all Forums with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64661/list-forum-thread-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (

        # Thread ID for the lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread by Thread Id with Connection File'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread by Thread Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread by Thread Id with Connection Profile'
        )]
        [int64[]]$ThreadId,


       # Forum ID for the lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread by Forum Id with Connection File'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread by Forum Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread by Forum Id with Connection Profile'
        )]
        [Alias("Id")]
        [int64[]]$ForumId,
    
        <# Filtering to add later
        # Username to use for filtering the lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,
    
        # Email address to use for filtering the lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false 
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$EmailAddress,
    
        # User ID for the filtering the lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false 
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64]$UserId,
        #>

        # Query Type
        [Parameter()]
        [ValidateSet('All', 'Moderated', 'Answered', 'Unanswered', 'AnsweredNotVerified', 'AnsweredWithNotVerified', 'Unread', 'MyThreads', 'Authored', 'NoResponse')]
        [string]$QueryType = 'All',

        # Sort Field
        [Parameter()]
        [ValidateSet('LastPost', 'ThreadAuthor', 'TotalReplies', 'TotalViews', 'TotalRatings', 'FirstPost', 'Subject', 'Votes', 'TotalQualityVotes', 'QualityScore', 'Score', 'ContentIdsOrder')]
        [string]$SortBy = 'LastPost',

        # Sort Order
        [Parameter()]
        [switch]$Descending,

        # Number of entries to get per batch (default of 20)
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
    
        # Created after this Date/time
        [Parameter()]
        [datetime]$CreatedAfterDate,
    
        # Created before this Date/time
        [Parameter()]
        [datetime]$CreatedBeforeDate,


        # Do we want to return the thread's SPAM details?
        [Parameter()]
        [switch]$IncludeSpamMetrics,

        # Do we want to return the poster's IP?
        [Parameter()]
        [switch]$IncludeHostAddress,
            
        # Do we want to return everything?
        [Parameter()]
        [Alias("Details")]
        [switch]$ReturnDetails,

        # Do we want to include the body in the simplified output?
        [Parameter()]
        [switch]$IncludeBody,

        # Do we want to include the body in the simplified output?
        [Parameter()]
        [switch]$IncludeBodyFormatted,

        
        # Do we want to include the details about any attached files?
        [Parameter()]
        [switch]$IncludeFileAttachment,

        # Do we want to include the client's IP?
        [Parameter()]
        [switch]$IncludeClientIP,
        

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread by Thread Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread by Forum Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Threads in all Forums with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
                
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread by Thread Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread by Forum Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Threads in all Forums with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread by Thread Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread by Forum Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Threads in all Forums with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
            
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Threads by Thread Id with Connection File')]
        [Parameter(ParameterSetName = 'Threads by Forum Id with Connection File')]
        [Parameter(ParameterSetName = 'Threads in all Forums with Connection File')]
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
        
        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

        # Additional Parameters
        if ( $CreatedBeforeDate ) {
            $UriParameters["CreatedBeforeDate"] = $CreatedBeforeDate
        }

        if ( $CreatedAfterDate ) {
            $UriParameters["CreatedAfterDate"] = $CreatedAfterDate
        }

        if ( $Descending ) {
            $UriParameters["SortOrder"] = 'desc'
        }
        else {
            $UriParameters["SortOrder"] = 'asc'
        }


        $PropertiesToReturn = @(
            @{ Name = "ThreadId"; Expression = { $_.Id } }
            @{ Name = "GroupId"; Expression = { $_.GroupId } }
            @{ Name = "ForumId"; Expression = { $_.ForumId } }
            'ThreadStatus'
            'ThreadType'
            'Date'
            @{ Name = "LastPostDate"; Expression = { $_.LatestPostDate } }
            'Url'
            'Subject'
            'IsLocked'
            @{ Name = 'Author'; Expression = { $_.Author.DisplayName } }
            'ViewCount'
            'ReplyCount'
            @{ Name = "Tags"; Expression = { $_.Tags.Value -join ", " } }
        )

        if ( $IncludeHostAddress ) {
            $PropertiesToReturn += 'UserHostAddress'
        }
        if ( $IncludeFileAttachment ) {
            $PropertiesToReturn += @{ Name = "Files"; Expression = { $_.File | ForEach-Object { $_ | Select-Object -Property FileName, ContentType, FileUrl } } }
        }
        if ( $IncludeBody ) {
            $PropertiesToReturn += 'Body'
        }
        if ( $IncludeBodyFormatted ) {
            $PropertiesToReturn += @{ Name = "BodyFormatted"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Body ) } }
        }
        if ( $IncludeSpamMetrics ) {
            $PropertiesToReturn += 'SpamStatus', 'SpamScore'
        }

        if ( $IncludeClientIP ) {
            $PropertiesToReturn += @{ Name = "ClientIP"; Expression = { $_.UserHostAddress } }
        }

        if ( $IncludeGroupName -or $IncludeForumName ) {
            $ForumList = @{}
            $GroupList = @{}
            Get-VtForum -VtCommunity $Community -VtAuthHeader $AuthHeaders | ForEach-Object {
                $ForumList[$_.ForumId] = $_.Name
                $GroupList[$_.GroupId] = $_.GroupName
            }
            if ( $IncludeGroupName ) {
                $PropertiesToReturn += @{ Name = "GroupName"; Expression = { $GroupList[$_.GroupId] } }
            }
            if ( $IncludeForumName ) {
                $PropertiesToReturn += @{ Name = "ForumName"; Expression = { $ForumList[$_.ForumId] } }
            }
        }

        $UriParameters["ForumThreadQueryType"] = $QueryType
        $UriParameters["SortBy"] = $SortBy

        #Uses the same URI for everything
        $Uri = 'api.ashx/v2/forums/threads.json'

    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess($Community, "Get Forum Threads from") ) {
            if ( $ThreadId ) {
                ForEach ( $t in $ThreadId ) {
                    $Uri = "api.ashx/v2/forums/threads/$t.json"
                    $UriParameters.Remove("SortOrder")
                    $UriParameters.Remove("SortBy")
                    $UriParameters.Remove("PageIndex")
                    $UriParameters.Remove("PageSize")
                    $UriParameters.Remove("ForumThreadQueryType")
                    $TotalReturned = 0
                        <#
                        if ( $TotalReturned -and -not $SuppressProgressBar) {
                            Write-Progress -Activity "Getting Threads with ID: $t" -Status "Returned $( $TotalReturned ) / $( $ForumThreadResponse.TotalCount ) Records" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1 ) for $BatchSise records" -PercentComplete ( $TotalReturned / $ForumThreadResponse.TotalCount * 100 )
                        } elseif ( -not $SuppressProgressBar ) {
                            Write-Progress -Activity "Getting Threads with ID: $t" -Status "Making first call for $BatchSize records" -CurrentOperation "Making first call for $BatchSize records"
                        }
                        #>
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                        $ForumThreadResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders
                        if ( $ForumThreadResponse ) {
                            if ( $ReturnDetails ) {
                                $ForumThreadResponse.Thread
                            }
                            else {
                                $ForumThreadResponse.Thread | Select-Object -Property $PropertiesToReturn
                            }
                        }
                }
            }
            elseif ( $ForumId ) {
                ForEach ( $f in $ForumId ) {
                    # If we have a forum ID, we should pass it as a parameter
                    $UriParameters["ForumID"] = $f
                    $ForumName = Get-VtForum -ForumId $f -VtCommunity $Community -VtAuthHeader $AuthHeaders | Select-Object -Property @{ Name = "FullName"; Expression = { "'$( $_.Name )' in '$( $_.GroupName)'" } } | Select-Object -ExpandProperty FullName
                    $TotalReturned = 0
                    do {
                        if ( $TotalReturned -and -not $SuppressProgressBar) {
                            Write-Progress -Activity "Getting Threads for $ForumName" -Status "Returned $( $TotalReturned ) / $( $ForumThreadResponse.TotalCount ) Records" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1 ) for $BatchSise records" -PercentComplete ( $TotalReturned / $ForumThreadResponse.TotalCount * 100 )
                        } elseif ( -not $SuppressProgressBar ) {
                            Write-Progress -Activity "Getting Threads for $ForumName" -Status "Making first call for $BatchSize records" -CurrentOperation "Making first call for $BatchSize records"
                        }
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                        $ForumThreadResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                        if ( $ForumThreadResponse ) {
                            $TotalReturned += $ForumThreadResponse.Threads.Count
                            if ( $ReturnDetails ) {
                                $ForumThreadResponse.Threads
                            }
                            else {
                                $ForumThreadResponse.Threads | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        $UriParameters["PageIndex"]++
                    } while ($TotalReturned -lt $ForumThreadResponse.TotalCount)
                    Write-Progress -Activity "Getting Threads for $ForumName" -Completed
                }
            }
            else {
                # Get all forums
                $TotalReturned = 0
                do {
                    if ( $TotalReturned -and -not $SuppressProgressBar) {
                        Write-Progress -Activity "Getting Threads for All Forums" -Status "Returned $( $TotalReturned ) / $( $ForumThreadResponse.TotalCount ) Records" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1 ) for $BatchSise records" -PercentComplete ( $TotalReturned / $ForumThreadResponse.TotalCount * 100 )
                    }
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $ForumThreadResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $ForumThreadResponse ) {
                        $TotalReturned += $ForumThreadResponse.Threads.Count
                        if ( $ReturnDetails ) {
                            $ForumThreadResponse.Threads
                        }
                        else {
                            $ForumThreadResponse.Threads | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $ForumThreadResponse.TotalCount)
                Write-Progress -Activity "Getting Threads for All Forums" -Completed
            }
        }
    }
    END {
        # Nothing to see here
    }
}
