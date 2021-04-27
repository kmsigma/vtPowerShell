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
        } elseif ( $Username ) {
            $UriParameters["AuthorId"] = Get-VtUser -Username $Username -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -Verbose:$false | Select-Object -ExpandProperty UserId
        } elseif ( $EmailAddress ) {
            $UriParameters["AuthorId"] = Get-VtUser -EmailAddress $EamilAddress -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -Verbose:$false | Select-Object -ExpandProperty UserId
        }
        if ( $QueryType ) {
            $UriParameters['ForumThreadQueryType'] = $QueryType
        }
    }
    process {
        if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Enumerate Threads in Forum ID '$( $ForumId )'") ) {
            $TotalThreads = 0
            do {
                Write-Progress -Activity "Pulling Threads for Forum with ID: $ForumID" -CurrentOperation "Pulling $BatchSize threads" -PercentComplete ( ( $TotalThreads / $ThreadsResponse.TotalCount ) * 100 )
                $Uri = "api.ashx/v2/forums/$( $ForumId )/threads.json"
                $ThreadsResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
                $TotalThreads += $ThreadsResponse.Threads.Count
                $ThreadsResponse.Threads | Select-Object -Property Id, Url, Subject, @{ Name = 'Author'; Expression = { $_.Author.DisplayName } }, Date, ThreadStatus, ThreadType, ViewCount, ReplyCount
                $UriParameters["PageSize"]++
            } while ( $TotalThreads -lt $ThreadsResponse.TotalCount )
            Write-Progress -Activity "Pulling Threads for Forum with ID: $ForumID" -Completed
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
        
    }
    
    process {
        if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Get info about Forum ID '$( $ForumId )'") ) {
        }
    }
    
    end {
        
    }
}