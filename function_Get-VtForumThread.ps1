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
            $Global:VtAuthHeader = Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: 
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Thread By Forum Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64661/list-forum-thread-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Forum ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread By Forum Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int64[]]$ForumId,
    
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'All Forums'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("All")]
        [switch]$AllForums,
    
        # Username to use for filtering the lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
    
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
    
        # Query Type
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet('All', 'Moderated', 'Answered', 'Unanswered', 'AnsweredNotVerified', 'AnsweredWithNotVerified', 'Unread', 'MyThreads', 'Authored', 'NoResponse')]
        [string]$QueryType = 'All',
            
        # Number of entries to get per batch (default of 20)
        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
    
        # Created after this Date/time
        [Parameter(
            Mandatory = $false
        )]
        [datetime]$CreatedAfterDate,
    
        # Created before this Date/time
        [Parameter(
            Mandatory = $false
        )]
        [datetime]$CreatedBeforeDate,
            
        # Do we want to return everything?
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Details")]
        [switch]$ReturnDetails,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [string]$VtCommunity = $Global:VtCommunity,
    
        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader = $Global:VtAuthHeader
    )
    BEGIN {
    
        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $VtAuthHeader = $VtAuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false
    
        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
    
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize
    
        if ( $UserId ) {
            $UriParameters["AuthorId"] = $UserId
        }
        elseif ( $Username ) {
            $UriParameters["AuthorId"] = Get-VtUser -Username $Username -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -Verbose:$false | Select-Object -ExpandProperty UserId
        }
        elseif ( $EmailAddress ) {
            $UriParameters["AuthorId"] = Get-VtUser -EmailAddress $EamilAddress -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -Verbose:$false | Select-Object -ExpandProperty UserId
        }
        if ( $QueryType ) {
            $UriParameters['ForumThreadQueryType'] = $QueryType
        }
        if ( $CreatedAfterDate ) {
            $UriParameters['CreatedAfterDate'] = $CreatedAfterDate
        }
        if ( $CreatedBeforeDate ) {
            $UriParameters['CreatedBeforeDate'] = $CreatedBeforeDate
        }
    }
    PROCESS {
        if ( -not $AllForums ) {
            $ActionName = "Enumerate Threads in Forum ID '$( $ForumId )'"
        }
        else {
            $ActionName = "Enumerate Threads for all forums"
        }
        ForEach ( $f in $ForumId ) {
            if ( $pscmdlet.ShouldProcess("$VtCommunity", $ActionName) ) {
                # Reset the PageIndex
                $UriParameters["PageIndex"] = 0
                # Remove the ThreadsReponse
                Remove-VtVtVariable -Name ThreadsResponse -ErrorAction SilentlyContinue
    
                $TotalThreads = 0
                $ForumDetails = Get-VtForum -ForumId $f -Community $VtCommunity -AuthHeader $VtAuthHeader | Select-Object -Property Title, GroupName
                $ForumTitle = $ForumDetails.Title
                $GroupName = $ForumDetails.GroupName
                do {
                    if ( -not $ThreadsResponse ) {
                        Write-Progress -Activity "Pulling Threads in $GroupName / $ForumTitle" -CurrentOperation "Pulling $BatchSize threads [initial call]" -PercentComplete 0
                    }
                    else {
                        Write-Progress -Activity "Pulling Threads in $GroupName / $ForumTitle" -CurrentOperation "Pulling $BatchSize threads [$( $TotalThreads )/$( $ThreadsResponse.TotalCount )]" -PercentComplete ( ( $TotalThreads / $ThreadsResponse.TotalCount ) * 100 )
                    }
                    if ( -not $AllForums ) {
                        $Uri = "api.ashx/v2/forums/$( $f )/threads.json"
                    }
                    else {
                        $Uri = 'api.ashx/v2/forums/threads.json'
                    }
                    $ThreadsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                    $TotalThreads += $ThreadsResponse.Threads.Count
                    if ( $ReturnDetails ) {
                        $ThreadsResponse.Threads
                    }
                    else {
                        $ThreadsResponse.Threads | Select-Object -Property @{ Name = "GroupId"; Expression = { $_.GroupId } }, @{ Name = "GroupName"; Expression = { $GroupName } }, @{ Name = "ForumId"; Expression = { $_.ForumId } }, @{ Name = "ForumTitle"; Expression = { $ForumTitle } }, @{ Name = "ThreadId"; Expression = { $_.Id } }, Url, Subject, Body, @{ Name = 'Author'; Expression = { $_.Author.DisplayName } }, Date, LatestPostDate, ThreadStatus, ThreadType, ViewCount, ReplyCount, @{ Name = "Tags"; Expression = { $_.Tags.Value -join ", " } }
                    }
                    $UriParameters["PageIndex"]++
                } while ( $TotalThreads -lt $ThreadsResponse.TotalCount )
                Write-Progress -Activity "Pulling Threads in $GroupName / $ForumTitle" -Completed
    
            }
        }
    }
    END {
        # Nothing to see here
    }
}
