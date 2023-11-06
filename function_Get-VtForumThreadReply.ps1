function Get-VtForumThreadReply {
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
        DefaultParameterSetName = 'Thread Replies in all Forums with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/12/w/api-documentation/71276/list-forum-reply-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Forum ID for the lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Reply by Thread Id and Forum Id with Connection File'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Reply by Thread Id and Forum Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Reply by Thread Id and Forum Id with Connection Profile'
        )]
        [Alias("Id")]
        [int64[]]$ForumId,

        # Thread ID for the lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Reply by Thread Id and Forum Id with Connection File'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Reply by Thread Id and Forum Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Reply by Thread Id and Forum Id with Connection Profile'
        )]
        [int64[]]$ThreadId,
    
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
        [ValidateSet('All', 'verified-answers', 'non-verified-answers')]
        [string]$ForumReplyQueryType = 'All',

        # Sort Field
        [Parameter()]
        [ValidateSet('PostDate', 'UserID', 'SortOrder', 'TotalVotes', 'Score:SCORE_ID', 'ContentIdsOrder')]
        [string]$SortBy = 'PostDate',

        # Sort Order
        [Parameter()]
        [switch]$Descending,

        # Number of entries to get per batch (default of 20)
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
    
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

        # Do we want to include the formatted body in the simplified output?
        [Parameter()]
        [switch]$IncludeBodyFormatted,

        # Do we want to include the client's IP?
        [Parameter()]
        [switch]$IncludeClientIP,
        

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Reply by Thread Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Reply by Thread Id and Forum Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread Replies in all Forums with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
                
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Reply by Thread Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Reply by Thread Id and Forum Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread Replies in all Forums with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Reply by Thread Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Reply by Thread Id and Forum Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread Replies in all Forums with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
            
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Threads by Thread Id with Connection File')]
        [Parameter(ParameterSetName = 'Threads by Forum Id with Connection File')]
        [Parameter(ParameterSetName = 'Thread Replies in all Forums with Connection File')]
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

        if ( $Descending ) {
            $UriParameters["SortOrder"] = 'Descending'
        }
        else {
            $UriParameters["SortOrder"] = 'Ascending'
        }


        $PropertiesToReturn = @(
            @{ Name = "ReplyId"; Expression = { $_.Id } }
            @{ Name = "ThreadId"; Expression = { $_.ThreadId } }
            @{ Name = "ForumId"; Expression = { $_.ForumId } }
            'ThreadStatus'
            'ThreadType'
            'Date'
            'Url'
            'Subject'
            'IsLocked'
            @{ Name = 'Author'; Expression = { $_.Author.DisplayName } }
            'ReplyCount'
            'PostLevel'
            'ParentId'
        )

        if ( $IncludeHostAddress ) {
            $PropertiesToReturn += 'UserHostAddress'
        }

        if ( $IncludeBody ) {
            $PropertiesToReturn += 'Body'
        }
        if ( $IncludeBodyFormatted ) {
            $PropertiesToReturn += @{ Name = "BodyFormatted"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Body ) } }
        }

        if ( $IncludeClientIP ) {
            $PropertiesToReturn += @{ Name = "ClientIP"; Expression = { $_.UserHostAddress } }
        }

        <#
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
        #>

        $UriParameters["ForumReplyQueryType"] = $ForumReplyQueryType
        $UriParameters["SortBy"] = $SortBy

    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess($Community, "Get Forum Thread Replies from") ) {
            if ( $ForumId -and $ThreadId ) {
                ForEach ( $f in $ForumId ) {
                    ForEach ( $t in $ThreadId ) {
                        do {
                            if ( $TotalReturned -and -not $SuppressProgressBar) {
                                Write-Progress -Activity "Getting Threads for All Forums" -Status "Returned $( $TotalReturned ) / $( $ForumThreadResponse.TotalCount ) Records" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1 ) for $BatchSise records" -PercentComplete ( $TotalReturned / $ForumThreadResponse.TotalCount * 100 )
                            }
                            Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                            $Uri = "api.ashx/v2/forums/$f/threads/$t/replies.json"
                            $Response = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                            if ( $Response ) {
                                $TotalReturned += $Response.Replies.Count
                                if ( $ReturnDetails ) {
                                    $Response.Replies
                                }
                                else {
                                    $Response.Replies | Select-Object -Property $PropertiesToReturn
                                }
                            }
                            $UriParameters["PageIndex"]++
                        } while ( $TotalReturned -lt $Response.TotalCount )
                        <# 
                        $uri = "api.ashx/v2/forums/$f/threads/$t/replies.json"
                        $TotalReturned = 0
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                        $Response = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders
                        if ( $Response ) {
                            if ( $ReturnDetails ) {
                                $Response.Reply
                            }
                            else {
                                $Response.Reply | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        #>
                    }
                }
            }
            elseif ( $ForumID -and -not $ThreadId ) {
                Write-Host "Need to do this where the forum ID is provided, but the thread ID is not"
            }
            elseif ( -not $ForumId -and $ThreadId ) {
                Write-Host "Need to do this where forum is not provided, but the thread is"
            }
            
            else {
                # Get all forums and all threads and all replies
            
                # Logic
                #----------------------------------------------
                # $forums = Get all forums
                # $threads = Get all threads -ForumID $Forums
                # cycle through each of them
            
                <#
            $TotalReturned = 0
            do {
                if ( $TotalReturned -and -not $SuppressProgressBar) {
                    Write-Progress -Activity "Getting Threads for All Forums" -Status "Returned $( $TotalReturned ) / $( $Response.TotalCount ) Records" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1 ) for $BatchSise records" -PercentComplete ( $TotalReturned / $Response.TotalCount * 100 )
                }
                Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                $Response = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                if ( $Response ) {
                    $TotalReturned += $Response.Threads.Count
                    if ( $ReturnDetails ) {
                        $Response.Threads
                    }
                    else {
                        $Response.Threads | Select-Object -Property $PropertiesToReturn
                    }
                }
                $UriParameters["PageIndex"]++
            } while ($TotalReturned -lt $Response.TotalCount)
            Write-Progress -Activity "Getting Threads for All Forums" -Completed
            #>
            }
        }
    }
    END {
        # Nothing to see here
    }
}
