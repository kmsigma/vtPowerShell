function Get-VtForumThead {
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
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader
    )
    begin {
        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        if ( -not ( Get-Command -Name Get-VtUser -ErrorAction SilentlyContinue ) ) {
            . .\func_Users.ps1
        }

        <#
        .Synopsis
            Convert a hashtable to a query string
        .DESCRIPTION
            Converts a passed hashtable to a query string based on the key:value pairs.
        .EXAMPLE
            $UriParameters = @{}
            PS > $UriParameters.Add("PageSize", 20)
            PS > $UriParameters.Add("PageIndex", 1)

            PS > $UriParameters

        Name                           Value
        ----                           -----
        PageSize                       20
        PageIndex                      1

            PS > $UriParameters | ConvertTo-QueryString

            PageSize=20&PageIndex=1
        .OUTPUTS
            string object in the form of "key1=value1&key2=value2..."  Does not include the preceeding '?' required for many URI calls
        .NOTES
            This is bascially the reverse of [System.Web.HttpUtility]::ParseQueryString

            This is included here just to have a reference for it.  It'll typically be defined 'internally' within the `begin` blocks of functions
        #>
        function ConvertTo-QueryString {
            param (
                # Hashtable containing segmented query details
                [Parameter(
                    Mandatory = $true, 
                    ValueFromPipeline = $true)]
                [ValidateNotNull()]
                [ValidateNotNullOrEmpty()]
                [System.Collections.Hashtable]$Parameters
            )
            $ParameterStrings = @()
            $Parameters.GetEnumerator() | ForEach-Object {
                $ParameterStrings += "$( $_.Key )=$( $_.Value )"
            }
            $ParameterStrings -join "&"
        }

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeader = $AuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}

        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

        if ( $UserId ) {
            $UriParameters["AuthorId"] = $UserId
        }
        elseif ( $Username ) {
            $UriParameters["AuthorId"] = Get-VtUser -Username $Username -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -Verbose:$false | Select-Object -ExpandProperty UserId
        }
        elseif ( $EmailAddress ) {
            $UriParameters["AuthorId"] = Get-VtUser -EmailAddress $EamilAddress -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -Verbose:$false | Select-Object -ExpandProperty UserId
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
    process {
        if ( -not $AllForums ) {
            $ActionName = "Enumerate Threads in Forum ID '$( $ForumId )'"
        }
        else {
            $ActionName = "Enumerate Threads for all forums"
        }
        if ( $pscmdlet.ShouldProcess("$CommunityDomain", $ActionName) ) {
            $TotalThreads = 0
            do {
                if ( -not $ThreadsResponse ) {
                    Write-Progress -Activity "Pulling Threads" -CurrentOperation "Pulling $BatchSize threads [initial call]" -PercentComplete 0
                }
                else {
                    Write-Progress -Activity "Pulling Threads" -CurrentOperation "Pulling $BatchSize threads [$( $TotalThreads )/$( $ThreadsResponse.TotalCount )]" -PercentComplete ( ( $TotalThreads / $ThreadsResponse.TotalCount ) * 100 )
                }
                if ( -not $AllForums ) {
                    $Uri = "api.ashx/v2/forums/$( $ForumId )/threads.json"
                }
                else {
                    $Uri = 'api.ashx/v2/forums/threads.json'
                }
                $ThreadsResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
                $TotalThreads += $ThreadsResponse.Threads.Count
                if ( $ReturnDetails ) {
                    $ThreadsResponse.Threads
                } else {
                $ThreadsResponse.Threads | Select-Object -Property Id, Url, Subject, Body, @{ Name = 'Author'; Expression = { $_.Author.DisplayName } }, Date, LatestPostDate, ThreadStatus, ThreadType, ViewCount, ReplyCount, @{ Name = "Tags"; Expression = { $_.Tags.Value -join ", " } }
                }
                $UriParameters["PageIndex"]++
            } while ( $TotalThreads -lt $ThreadsResponse.TotalCount )
            Write-Progress -Activity "Pulling Threads" -Completed
        }
    }
    end {
        # Nothing to see here
    }
}

function Get-VtForum {
    [CmdletBinding(
        DefaultParameterSetName = 'Thread By Forum Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64656/show-forum-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    param (
        
        # Forum ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Forum Id'
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
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader
    )
    
    begin {
        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        if ( -not ( Get-Command -Name Get-VtUser -ErrorAction SilentlyContinue ) ) {
            . .\func_Users.ps1
        }
        
        <#
        .Synopsis
            Convert a hashtable to a query string
        .DESCRIPTION
            Converts a passed hashtable to a query string based on the key:value pairs.
        .EXAMPLE
            $UriParameters = @{}
            PS > $UriParameters.Add("PageSize", 20)
            PS > $UriParameters.Add("PageIndex", 1)

            PS > $UriParameters

        Name                           Value
        ----                           -----
        PageSize                       20
        PageIndex                      1

            PS > $UriParameters | ConvertTo-QueryString

            PageSize=20&PageIndex=1
        .OUTPUTS
            string object in the form of "key1=value1&key2=value2..."  Does not include the preceeding '?' required for many URI calls
        .NOTES
            This is bascially the reverse of [System.Web.HttpUtility]::ParseQueryString

            This is included here just to have a reference for it.  It'll typically be defined 'internally' within the `begin` blocks of functions
        #>
        function ConvertTo-QueryString {
            param (
                # Hashtable containing segmented query details
                [Parameter(
                    Mandatory = $true, 
                    ValueFromPipeline = $true)]
                [ValidateNotNull()]
                [ValidateNotNullOrEmpty()]
                [System.Collections.Hashtable]$Parameters
            )
            $ParameterStrings = @()
            $Parameters.GetEnumerator() | ForEach-Object {
                $ParameterStrings += "$( $_.Key )=$( $_.Value )"
            }
            $ParameterStrings -join "&"
        }
        
        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeader = $AuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false
        $UriParameters = @{}
        $UriParameters['PageSize'] = $BatchSize
        $UriParameters['PageIndex'] = 0
        
    }
    process {
        if ( $AllForums ) {
            if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Get info about all forums'") ) {
                $Uri = 'api.ashx/v2/forums.json'
                $ForumCount = 0
                do {
                    $ForumResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
                    if ( $ForumResponse ) {
                        if ( -not $ReturnDetails ) {
                            $ForumResponse.Forums | Select-Object -Property ForumId, @{ Name = 'ThreadId'; Expression = { $_.Id } },  Title, Key, Url, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode($_.Group.Name) } }, @{ Name = "GroupKey"; Expression = { $_.Group.Key } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "AllowedThreadTypes"; Expression = { $_.AllowedThreadTypes.Value -join ", " } }, DefaultThreadType, LatestPostDate, Enabled, ThreadCount, ReplyCount
                        }
                        else {
                            $ForumResponse.Forums
                        }
                        $ForumCount += $ForumResponse.Forums.Count
                    }
                    $UriParameters["PageIndex"]++
                } while ($ForumCount -lt $ForumResponse.TotalCount )
            }
        }
        else {
            if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Get info about Forum ID: $ForumId'") ) {
                $Uri = "api.ashx/v2/forums/$ForumId.xml"
            }
        }
    }
    
    end {
        
    }
}

function Set-VtForumThread {
    [CmdletBinding(
        DefaultParameterSetName = 'Thread and Forum Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64666/update-forum-thread-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        # Forum ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64]$ForumId,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64]$ThreadId,

        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$LockThread,

        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$StickyThread,

        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [date]$StickyDate = ( Get-Date ).AddDays(7),

        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$FeatureThread,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader
    )
    
    begin {
        <#
        .Synopsis
            Convert a hashtable to a query string
        .DESCRIPTION
            Converts a passed hashtable to a query string based on the key:value pairs.
        .EXAMPLE
            $UriParameters = @{}
            PS > $UriParameters.Add("PageSize", 20)
            PS > $UriParameters.Add("PageIndex", 1)

            PS > $UriParameters

        Name                           Value
        ----                           -----
        PageSize                       20
        PageIndex                      1

            PS > $UriParameters | ConvertTo-QueryString

            PageSize=20&PageIndex=1
        .OUTPUTS
            string object in the form of "key1=value1&key2=value2..."  Does not include the preceeding '?' required for many URI calls
        .NOTES
            This is bascially the reverse of [System.Web.HttpUtility]::ParseQueryString

            This is included here just to have a reference for it.  It'll typically be defined 'internally' within the `begin` blocks of functions
        #>
        function ConvertTo-QueryString {
            param (
                # Hashtable containing segmented query details
                [Parameter(
                    Mandatory = $true, 
                    ValueFromPipeline = $true)]
                [ValidateNotNull()]
                [ValidateNotNullOrEmpty()]
                [System.Collections.Hashtable]$Parameters
            )
            $ParameterStrings = @()
            $Parameters.GetEnumerator() | ForEach-Object {
                $ParameterStrings += "$( $_.Key )=$( $_.Value )"
            }
            $ParameterStrings -join "&"
        }
        
        
        $UriParameters = @{}
        if ( $LockThread ) {
            $UriParameters["IsLocked"] = 'true'
        }
        if ( $StickyThread ) {
            $UriParameters["IsSticky"] = 'true'
            $UriParameters["StickyDate"] = $StickyDate
        }
        if ( $FeatureThread ) {
            $UriParameters["IsFeatured"] = 'true'
        }
        # Update the authentication header for to "Put"
        $AuthHeader = $AuthHeader | Set-VtAuthHeader -RestMethod Put -Verbose:$false -WhatIf:$false
        $HttpMethod = "Post"
    }
    
    process {
        <#
        HTTP Method: POST
        Auth Header: PUT
        Uri = api.ashx/v2/forums/{forumid}/threads/{threadid}.json
        #>

        if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Update Thread $ThreadId in Forum $ForumId'") ){
            $Uri = "api.ashx/v2/forums/$ForumId/threads/$ThreadId.json"
            $UpdateResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader -Method $HttpMethod
            if ( $UpdateResponse )
            {
                $UpdateResponse
            }
        }
    }
    
    end {
        # Nothing to see here
    }
}

