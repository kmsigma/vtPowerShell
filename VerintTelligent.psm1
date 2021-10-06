#region Community Authentication Functions
<#
.Synopsis
    Get the necessary authentication header for Verint | Telligent Community
.DESCRIPTION
    Using the username and API key, we'll build an authentication header required to access Verint | Telligent Communities.
    Note this creation does NOT validate that the authentication works - it just builds the header.
.EXAMPLE
    Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"

    Name                           Value
    ----                           -----
    Rest-User-Token                bG1[omitted]dtYQ==
.INPUTS
    Username and API key.  Your API key is distinct, but as powerful as your password.  Guard it similarly.
    API Keys can be obtained from https://community.domain.here/user/myapikeys
.OUTPUTS
    Hashtable with necessary headers
.NOTES
    https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Get-VtAuthHeader {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests',
        ConfirmImpact = 'Medium')
    ]
    [Alias("New-VtAuthHeader")]
    param (
        # Username for the call to the REST endpoint
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        [Alias("User")] 
        [string]$Username,

        # API Key for the associated user
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 1)]
        [Alias("Key")] 
        [string]$ApiKey
    )

    begin {
        # Nothing here
    }

    process {
        if ( $pscmdlet.ShouldProcess("", "Generate Authentication Header") ) {
            $Base64Key = [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes( "$( $ApiKey ):$( $Username )" ) )
            # Return the header with the token only
            @{
                'Rest-User-Token' = $Base64Key
            }
        }
    }
    
    end {
        #Nothing to see here        
    }
}

<#
.Synopsis
    Update an existing authentication header for Verint | Telligent Community
.DESCRIPTION
    Add an optional REST Method for use with Update and Delete type calls
.EXAMPLE
    $VtAuthHeader | Set-VtAuthHeader -Method "Delete"

    Name                           Value
    ----                           -----
    Rest-User-Token                bG1[omitted]dtYQ==
    Rest-Method                    DELETE

    Take an existing header and add "Delete" as the rest method

.EXAMPLE
    $VtAuthHeader

    Name                           Value
    ----                           -----
    Rest-User-Token                bG1[omitted]dtYQ==
    Rest-Method                    DELETE

    PS > $VtAuthHeader | Set-VtAuthHeader -Method "Get"

    Name                           Value
    ----                           -----
    Rest-User-Token                bG1[omitted]dtYQ==

    "Get" style queries do not require a 'Rest-Mehod' in the header, so it is removed.  This is the same functionality as passing no RestMethod parameter.

.EXAMPLE
    $VtAuthHeader

    Name                           Value
    ----                           -----
    Rest-User-Token                bG1[omitted]dtYQ==

    PS > $DeleteHeader = $VtAuthHeader | Set-VtAuthHeader -Method "Delete"
    PS > $DeleteHeader

    Name                           Value
    ----                           -----
    Rest-User-Token                bG1[omitted]dtYQ==
    Rest-Method                    DELETE

    PS > $UpdateHeader = $VtAuthHeader | Set-VtAuthHeader -Method "Put"
    PS > $UpdateHeader

    Name                           Value
    ----                           -----
    Rest-User-Token                bG1[omitted]dtYQ==
    Rest-Method                    PUT

    Create two new headers ($DeleteHeader and $UpdateHeader) based on the original header ($VtAuthHeader)

.INPUTS
    Existing Authentication Header (as Hashtable)
.OUTPUTS
    Hashtable with necessary headers
.NOTES
    https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests

#>
function Set-VtAuthHeader {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests',
        ConfirmImpact = 'Medium')
    ]
    param (
        # Existing authentication header
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        [Alias("Header")] 
        [System.Collections.Hashtable[]]$VtAuthHeader,

        # Rest-Method to invoke
        [Parameter(Mandatory = $false, 
            Position = 1)]
        [ValidateSet("Get", "Put", "Delete")] # There may be others
        [Alias("Method")] 
        [string]$RestMethod = "Get"
    )
    begin {
        # Nothing to see here
    }

    process {
        # Support multiple tokens (this should be rare)
        ForEach ( $h in $VtAuthHeader ) {
            if ( $h["Rest-User-Token"] ) {
                if ( $pscmdlet.ShouldProcess("Header with 'Rest-User-Token: $( $h["Rest-User-Token"] )'", "Update Rest-Method to $RestMethod type") ) {
                    if ( $RestMethod -ne "Get" ) {
                
                        # Add a Rest-Method to the Token
                        $h["Rest-Method"] = $RestMethod.ToUpper()
                    }
                    else {
                        # 'Get' does not require the additional Rest-Method, so we'll remove it
                        if ( $h["Rest-Method"] ) {
                            $h.Remove("Rest-Method")
                        }
                    }
                }
                $h
            }
            else {
                Write-Error -Message "Header does not contain the 'Rest-User-Token'" -RecommendedAction "Please generate a valid header with Get-VtAuthHeader"
            }
        }
    }
    end {
        #Nothing to see here        
    }
}
#endregion Community Authentication Functions

#region Abuse Functions
function Get-VtAbuseReport {
    [CmdletBinding(
        DefaultParameterSetName = 'UserGuid',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64478/abuse-report-rest-endpoints',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # User ID to use for abuse lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'UserGuid')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [guid]$UserGuid,

        # Content URL to use for lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
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

        # Set the Uri for the target
        $Uri = 'api.ashx/v2/abusereports.json'

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageSize"] = $BatchSize
        $UriParameters["PageIndex"] = 0

        if ( $UserId ) {
            $UriParameters["AuthorUserId"] = $UserGuid
        }

    }
    PROCESS {

        $TotalAbuseReports = 0
        if ( $PSCmdlet.ShouldProcess("Target", "Operation") ) {
            do {
                $AbuseReportsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                if ( $AbuseReportsResponse ) {
                    $TotalAbuseReports += $AbuseReportsResponse.SystemNotifications.Count
                    $AbuseReportsResponse.Reports
                    $UriParameters["PageIndex"]++
                }
            } while ( $TotalAbuseReports -lt $AbuseReportsResponse.TotalCount )
        }
    }

    END {
        # Nothing to see here
    }
}
#endregion Abuse Functions

#region Blog Functions
<#
    New-VtBlog function (may be deferred because it's easier to do on the web)
    Remove-VtVtBlog function (may be deferred because it's easier to do on the web)
#>
<#
.Synopsis
    Get blog from a Verint Community
.DESCRIPTION
    Get a single or multiple blogs from a Verint Community
.EXAMPLE
    Get-VtBlog -BlogId 6

    BlogId       : 6
    Name         : Generic Blog
    Key          : generic-blog
    Url          : https://mycommunity.com/company-blogs/b/generic-blog
    Enabled      : True
    PostCount    : 134
    CommentCount : 281
    GroupName    : Company Blogs
    GroupId      : 11
    GroupType    : Joinless
    Authors      : {displayName1, displayName3, displayName42, displ…}
.EXAMPLE
    Get-VtBlog -BlogId 6 -ReturnDetails

    Similar to above example, except all the data is returned and it not presented in 'clean' way
.EXAMPLE
    Get-VtBlog | Where-Object { $_.Authors -contains 'displayName1' }

    Returns an array of all blogs where 'displayName1' is listed as an author of the blog
.EXAMPLE
    $Blogs = Get-VtBlog | Where-Object { $_.Authors }
    PS > $Blogs.Authors | Select-Object -Unique | Get-VtUser

    Retrieves a list of blogs where authors are defined, then gets the information on said author based on their Username

    .OUTPUTS

    .NOTES
#>
function Get-VtBlog {
    [CmdletBinding(
        #DefaultParameterSetName = 'Blog Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64538/list-blog-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Blog Id for Lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        #[ValidateNotNull()]
        #[ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64]$BlogId,

        # Group Id for Lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        #[ValidateNotNull()]
        #[ValidateNotNullOrEmpty()]
        [int64]$GroupId,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$ReturnDetails,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
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

    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess( $VtCommunity, "Query Blogs on" ) ) {
        
            if ( $BlogId -and -not $GroupId) {
                # If we have a BlogId and NOT a GroupId, return the single blog
                $Uri = "api.ashx/v2/blogs/$BlogId.json"
                $Type = 'Single'
            }
            elseif ( $BlogId -and $GroupId ) {
                # If we have a BlogId and a GroupId, return the single blog within that group
                $Uri = "api.ashx/v2/groups/$GroupId/blogs/$BlogId.json"
                $Type = 'Single'
            }
            elseif ( -not $BlogId -and $GroupId ) {
                # If we do NOT have a BlogId but we have a GroupId, return all blogs within that group
                $Uri = "api.ashx/v2/groups/$GroupId/blogs.json"
                $Type = 'Multiple'
            }
            else {
                # If we have neither a BlogId nor a GroupId, list all the blogs
                $Uri = "api.ashx/v2/blogs.json"
                $Type = 'Multiple'
            }
        
            if ( $Type -eq 'Single' ) {
                $BlogsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers $VtAuthHeader
                if ( $BlogsResponse ) {
                    if ( $ReturnDetails ) {
                        $BlogsResponse.Blog
                    }
                    else {
                        $BlogsResponse.Blog | Select-Object -Property @{ Name = "BlogId"; Expression = { $_.Id } }, Name, Key, Url, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Authors"; Expression = { ( $_.Authors | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
                    }
                }
                else {
                    Write-Error -Message "No blogs matching ID $BlogId found."
                }
            }
            else {
                # Multiple returns
            
                $TotalReturned = 0
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $BlogsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                    if ( $BlogsResponse ) {
                        $TotalReturned += $BlogsResponse.Blogs.Count
                        if ( $ReturnDetails ) {
                            $BlogsResponse.Blogs
                        }
                        else {
                            $BlogsResponse.Blogs | Select-Object -Property @{ Name = "BlogId"; Expression = { $_.Id } }, Name, Key, Description, Url, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Authors"; Expression = { ( $_.Authors | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $BlogsResponse.TotalCount)
            }
        
        } #end of 'should process'
    }
    END {
        # Nothing to see here
    }
}

<#
.Synopsis
    Update a Verint Blog
.DESCRIPTION
    This uses the REST API to update a blog.  It can update the Name, Description, Key (slug used in URL), Authors, and enable/disable the blog.
.EXAMPLE
    $Global:VtCommunity = 'https://myCommunityDomain.domain.local/'
PS > $Global:VtAuthHeader = Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"

PS > $Blog = Get-VtBlog | Where-Object { $_.Name -eq "My Community Blog" } 
PS > $Blog | Set-VtBlog -GroupId 11

Storing the VtCommunity and VtAuthHeader as Global variables, we do not need to include in the parameter sets.
We retrieve any blog with the name "My Community Blog" from the API.
Then we set that Blog (or multiple blogs if the names match) to be part of Group with ID 11. (Move the Blog)

.EXAMPLE
    $Authors = "displayName1", "displayName2", "displayName3"
PS > Set-VtBlog -BlogId 6 -Authors $Authors -Community "https://mycommunity.telligenthosting.com/" -AuthHeader $VtAuthHeader
PS > $NewAuthors = "displayName4", "displayName5", "displayName6"
PS > Set-VtBlog -BlogId 6 -Authors $Authors -Community "https://mycommunity.telligenthosting.com/" -AuthHeader $VtAuthHeader

This will update the list of authors to be displayName1, 2, and 3 on the blog with ID 6.
Then it will update the list of authors to be displayName4, 5, and 6 on the blog with ID 6.

When completed, only displayName4, 5, and 6 will be listed as authors.
.EXAMPLE
    Set-VtBlog -BlogId 11 -AddAuthors "me", "myself", "I" -Community "https://mycommunity.telligenthosting.com/" -AuthHeader $VtAuthHeader

This will take the existing authors and add the above 3 to the list.
.EXAMPLE
    Set-VtBlog -BlogId 13 -RemoveAuthors "removeMe", "removeHim", "removeHer" -Community "https://mycommunity.telligenthosting.com/" -AuthHeader $VtAuthHeader

This will take the existing authors and remove the above 3 from the list.
.INPUTS
    System.Int64
        You can pipeline in the blog id on which to operate
.OUTPUTS
    Custom PowerShell Object containing the blog information
.NOTES
    Refer to https://community.telligent.com/community/11/w/api-documentation/64540/update-blog-rest-endpoint for more information.

    You can optionally store the VtCommunity and the VtAuthHeader as global variables and omit passing them as parameters
    Eg: $Global:VtCommunity = 'https://myCommunityDomain.domain.local/'
        $Global:VtAuthHeader = Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
.COMPONENT
    TBD
.ROLE
    TBD
.LINK
    Online REST API Documentation: https://community.telligent.com/community/11/w/api-documentation/64540/update-blog-rest-endpoint
#>
function Set-VtBlog {
    [CmdletBinding(DefaultParameterSetName = 'Default', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64540/update-blog-rest-endpoint',
        ConfirmImpact = 'High')]
    Param
    (
        # Blog Id for Lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateRange("Positive")]
        [Alias("Id")] 
        [int64[]]$BlogId,

        # Update the key/slug used in the URL.  No spaces accepted.  Will automatically be converted to lowercase
        [Parameter()]
        [ValidateLength(1, 255)]
        [ValidateScript( {
                if ( $_ -match '^[a-zA-Z\d-]*$' ) {
                    $true
                }
                else {
                    throw "'$_' is invalid. Keys must contain alpha-numeric and dashes only. (Example: 'tech docs' is invalid, but 'tech-docs' or 'techdocs' is ok."
                }
            }
        )]
        [Alias("Slug")] 
        [string]$Key,

        # Update the blog name
        [Parameter()]
        [ValidateLength(1, 255)]
        [string]$Name,

        # Update the blog's decription
        [Parameter()]
        [ValidateLength(0, 999)] # Just noticed that the blog description is limited to 1000 characters
        [string]$Description,

        # Update the blog's parent group (move the blog)
        [Parameter()]
        [int64]$GroupId,

        # Flag the blog as disabled
        [Parameter()]
        [switch]$Disabled,

        
        [Parameter(
            ParameterSetName = "Add/Remove Authors"
        )]
        [string[]]$AddAuthor,

        [Parameter(
            ParameterSetName = "Add/Remove Authors"
        )]
        [string[]]$RemoveAuthor,

        [Parameter(
            ParameterSetName = "Authors List"
        )]
        [string[]]$Authors,

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

        $UriParameters = @{}
        if ( $GroupId ) { $UriParameters["GroupId"] = $GroupId }
        if ( $Key ) { $UriParameters["Key"] = $Key.ToLower() }
        if ( $Name ) { $UriParameters["Name"] = $Name }
        if ( $Description ) { $UriParameters["Description"] = $Description }
    }
    PROCESS {
        ForEach ( $b in $BlogId ) {
            # Get the blog because we'll want it for some later things
            $Blog = Get-VtBlog -BlogId $b -Community $VtCommunity -AuthHeader $VtAuthHeader -Verbose:$false -WhatIf:$false

            # Is the blog enabled and so we want to disable it?
            if ( $Blog.Enabled -and $Disabled ) {
                $UriParameters["Enabled"] = $false
            }
            # How about currently disabled and we want to enable it?
            elseif ( ( -not ( $Blog.Enabled ) ) -and ( -not ( $Disabled ) ) ) {
                $UriParameters["Enabled"] = $true
            }

            switch ( $pscmdlet.ParameterSetName ) {
                'Add/Remove Authors' { 
                    # Get Current List of Authors - we must use an ArrayList type or the .Add and .Remove methods are blocked
                    $WorkingAuthorList = New-VtObject -TypeName System.Collections.ArrayList
                    $OriginalAuthorList = New-VtObject -TypeName System.Collections.ArrayList
                    $Blog.Authors | ForEach-Object { $WorkingAuthorList.Add($_) | Out-Null }
                    $Blog.Authors | ForEach-Object { $OriginalAuthorList.Add($_) | Out-Null }
                    ForEach ( $R in $RemoveAuthor ) {
                        if ( $WorkingAuthorList -contains $R ) {
                            Write-Verbose -Message "Removing '$R' from the author list"
                            $WorkingAuthorList.Remove($R) | Out-Null
                        }
                        else {
                            Write-Verbose -Message "Account '$R' is not listed as an author"
                        }
                    }
                    ForEach ( $A in $AddAuthor ) {
                        if ( $WorkingAuthorList -contains $A ) {
                            Write-Verbose -Message "Account '$A' already listed as an author"
                        }
                        else {
                            Write-Verbose -Message "Adding '$A' to the author list"
                            $WorkingAuthorList.Add($A) | Out-Null
                        }
                    }
                    # Build the list of authors as a comma separated list (sorted is not necessary, but nice)
                    $AuthorList = ( $WorkingAuthorList | Sort-Object ) -join ","
                    # Add it to the parameter list for the URI
                    if ( Compare-Object -ReferenceObject $OriginalAuthorList -DifferenceObject $WorkingAuthorList  ) {
                        $UriParameters["Authors"] = $AuthorList
                    }
                    else {
                        Write-Warning -Message "Processed Authors: No change detected"
                    }
    
                }
                'Authors List' {
                    $Authors = $Authors | Sort-Object
                    if ( Compare-Object -ReferenceObject $Blog.Authors -DifferenceObject $Authors ) {
                        # Build the list of authors as a comma separated list (sorted is not necessary, but nice)
                        $AuthorList = ( $Authors | Sort-Object ) -join ","
                        # Add it to the parameter list for the URI
                        $UriParameters["Authors"] = $AuthorList
                    }
                    else {
                        Write-Warning -Message "Processed Authors: No change detected"
                    }
                }
                Default { Write-Verbose -Message "No author change detected" }
            }

            if ( $UriParameters.Count -gt 0 ) {
                if ( $pscmdlet.ShouldProcess("Blog: '$( $Blog.Name )' in '$( $Blog.GroupName )'", "Update $( $UriParameters.Keys -join ", " )") ) {
                    $Uri = "api.ashx/v2/blogs/$BlogId.json"

                    $Result = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Method "Post" -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod "Put" -WhatIf:$false )
                    if ( $Result ) {
                        $Result.Blog | Select-Object -Property @{ Name = "BlogId"; Expression = { $_.Id } }, Name, Key, Url, Description, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Authors"; Expression = { ( $_.Authors | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
                    }
                }
            }
            else {
                Write-Warning -Message "No changes detected, not processing request"
            }
        }
    }
    END {
        # Nothing to see here
    }
}

function Get-VtBlogPost {
    [CmdletBinding(DefaultParameterSetName = 'Filter By Blog Id', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64540/update-blog-rest-endpoint',
        ConfirmImpact = 'Low')]
    Param
    (

        # Blog Post Id for Lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Filter By Blog Post Id'
        )]
        [ValidateRange("Positive")]
        [Alias("Id")] 
        [int64[]]$BlogPostId,

        # Blog Id for Lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Filter By Blog Id'
        )]
        [Parameter(
            ParameterSetName = 'Filter By Author Name'
        )]
        [Parameter(
            ParameterSetName = 'Filter By Blog Post Id'
        )]
        [ValidateRange("Positive")]
        [int64[]]$BlogId,

        # Filter to a specific group
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Filter By Group Id'
        )]
        [Parameter(
            ParameterSetName = 'Filter By Author Name'
        )]
        [ValidateRange("Positive")]
        [int64]$GroupId,

        # Filter to a specific author (by id)
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Filter By Author Id'
        )]
        [ValidateRange("Positive")]
        [int64]$AuthorId,

        # Filter to a specific author name
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Filter By Author Name'
        )]
        [string]$Author,

        # Do we want to include the Body of posts?
        [Parameter()]
        [switch]$IncludeBody,

        # Do we want to include the OpenGraph and Meta Information?
        [Parameter()]
        [switch]$IncludeMetaInfo,

        # Do we want to include unpublished posts?
        [Parameter()]
        [switch]$IncludeUnpublished,



        # Do we want to return the entire JSON entry?
        [Parameter()]
        [switch]$ReturnDetails,

        # Page size for retrieving information
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
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

        # List of properties we'd like to pull
        $PropertyList = @{ Name = "BlogPostId"; Expression = { $_.Id } },
        "BlogId",
        "GroupId",
        @{ Name = "Title"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Title ) } },
        "Slug",
        "PublishedDate",
        "Url",
        "IsApproved",
        "IsFeatured",
        "Views",
        "CommentCount",
        @{ Name = "PostImageFileName"; Expression = { $_.PostImageFile.FileName } },
        @{ Name = "PostImageFileUrl"; Expression = { $_.PostImageFile.FileUrl } },
        @{ Name = "Author"; Expression = { $_.Author.DisplayName } },
        @{ Name = "Tags"; Expression = { ( $_.Tags | ForEach-Object { $_ | Select-Object -ExpandProperty Value } ) } }

        $UriParameters = @{}
        if ( -not $BlogPostId ) {
            $UriParameters["PageSize"] = $BatchSize
            $UriParameters["PageIndex"] = 0
        }
    
        if ( $IncludeBody ) {
            # if we want the body of the post, then we'll add those fields to the property list to return
            $PropertyList += "Body"
        }

        if ( $IncludeUnpublished ) {
            $UriParameters["IncludeUnpublished"] = 'true'
            # If we also want unpublished, then we'll add that field to the property list to return
            $PropertyList += "IsPostEnabled"
        }
        if ( $IncludeMetaInfo ) {
            # if we want the meta info, then we'll add those fields to the property list to return
            $PropertyList += "OpenGraphTitle",
            "OpenGraphDescription",
            "OpenGraphImage",
            "MetaKeywords",
            "MetaDescription",
            "MetaTitle"
        }

        if ( $Author ) {
            if ( -not ( Get-VtCommand -Name "Get-VtUser" -ErrorAction SilentlyContinue) ) {
                . .\func_Users.ps1
            }
            $AuthorId = Get-VtUser -Username $Author -Community $VtCommunity -AuthHeader $VtAuthHeader -Confirm:$false -Verbose:$false -WhatIf:$false | Select-Object -ExpandProperty UserId
        }

        if ( $AuthorId ) {
            $UriParameters["AuthorId"] = $AuthorId
        }
        #if ( $BlogPostId -and ( $BlogId -is [System.Array] ) ) {
        #    Write-Error -Message "When retrieving multiple blogs by id, you cannot send multiple blog Id numbers"
        #}
    }

    PROCESS {
        if ( $BlogId -and -not $BlogPostId ) {
            
            ForEach ( $B in $BlogId ) {
                # Add confirmation here

                $Uri = "api.ashx/v2/blogs/$B/posts.json"

                $BlogTitle = Get-VtBlog -BlogId $B | Select-Object -Property @{ Name = "Title"; Expression = { "'$( $_.Name )' in '$($_.GroupName )'" } } | Select-Object -ExpandProperty Title

                $TotalReturned = 0
                $UriParameters["PageIndex"] = 0
                Remove-VtVtVariable -Name BlogPostsResponse -ErrorAction SilentlyContinue
                do {
                    if ( $BlogPostsResponse ) {
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records [$TotalReturned / $( $BlogPostsResponse.TotalCount )]"
                        Write-Progress -Activity "Retrieving Posts from $BlogTitle" -PercentComplete ( $TotalReturned / $BlogPostsResponse.TotalCount * 100 ) -CurrentOperation "Retrieving Blog Posts [$TotalReturned posts / $( $BlogPostsResponse.TotalCount ) total posts]"
                    }
                    $BlogPostsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader -ErrorAction SilentlyContinue
                    if ( $BlogPostsResponse ) {
                        $TotalReturned += $BlogPostsResponse.BlogPosts.Count
                        if ( $ReturnDetails ) {
                            $BlogPostsResponse.BlogPosts
                        }
                        else {
                            $BlogPostsResponse.BlogPosts | Select-Object -Property $PropertyList
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $BlogPostsResponse.TotalCount)
                Write-Progress -Activity "Retrieving Posts from $BlogTitle" -Completed
                # Reset the Total Returned and Page Index in case we need to make further calls
                


            }
        
            if ( $pscmdlet.ShouldProcess("Target", "Operation") ) {
                # Real stuff should be in here
            }
        }
        elseif ( $BlogId -and $BlogPostId) {
            # Individual Blog Posts
            ForEach ( $Bp in $BlogPostId ) {
                ForEach ( $B in $BlogId ) {
                    # Add confirmation here
                    $Uri = "api.ashx/v2/blogs/$B/posts/$Bp.json"

                    # no parameters needed for getting a single blog post
                    try {
                        $BlogPostsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers $VtAuthHeader 
                        if ( $BlogPostsResponse ) {
                            #$BlogPostsResponse
                            $TotalReturned += $BlogPostsResponse.BlogPost.Count
                            if ( $ReturnDetails ) {
                                $BlogPostsResponse.BlogPost
                            }
                            else {
                                $BlogPostsResponse.BlogPost | Select-Object -Property $PropertyList
                            }
                        }
                    }
                    
                    catch {
                        Write-Warning -Message "No blog post found for Blog Id: $b and Blog Post ID: $bp"
                    }
                }
            }
        }
        else {
            # Everything
            $Uri = "api.ashx/v2/blogs/posts.json"

            $TotalReturned = 0
            $UriParameters["PageIndex"] = 0
            Remove-VtVtVariable -Name BlogPostsResponse -ErrorAction SilentlyContinue
            do {
                if ( $BlogPostsResponse ) {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records [$TotalReturned / $( $BlogPostsResponse.TotalCount )]"
                    Write-Progress -Activity "Retrieving All Posts" -PercentComplete ( $TotalReturned / $BlogPostsResponse.TotalCount * 100 ) -CurrentOperation "Retrieving Blog Posts [$TotalReturned posts / $( $BlogPostsResponse.TotalCount ) total posts]"
                }
                $BlogPostsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader -ErrorAction SilentlyContinue
                if ( $BlogPostsResponse ) {
                    $TotalReturned += $BlogPostsResponse.BlogPosts.Count
                    if ( $ReturnDetails ) {
                        $BlogPostsResponse.BlogPosts
                    }
                    else {
                        $BlogPostsResponse.BlogPosts | Select-Object -Property $PropertyList
                    }
                }
                $UriParameters["PageIndex"]++
            } while ($TotalReturned -lt $BlogPostsResponse.TotalCount)
            Write-Progress -Activity "Retrieving All Posts" -Completed
            # Reset the Total Returned and Page Index in case we need to make further calls
                            
            
        }
    }
            


    END {

    }
}
#endregion Blog Functions

#region Challenge Functions
<#
.Synopsis
    Get challenges from Verint / Telligent communities
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    https://community.telligent.com/community/11/w/api-documentation/64558/list-challenge-rest-endpoint
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Get-VtChallenge {
    [CmdletBinding(DefaultParameterSetName = 'All Groups', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64699/group-rest-endpoints',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType()]
    Param
    (
        # Community where you'll query for groups.  Protocol is required.
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            Position = 0,
            HelpMessage = 'Provide your community URL including the "http://" or "https://" and trailing slash' )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community", "Domain")]
        [string]$VtCommunity = $Global:VtCommunity,

        # Required authentication header
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("Header")]
        [hashtable]$VtAuthHeader = $Global:VtAuthHeader,

        # Get challenge by name
        [Parameter(
            ParameterSetName = 'By Name')]
        [string]$Name,

        # Challenge name exact match
        [Parameter(
            ParameterSetName = 'By Name')]
        [switch]$ExactMatch = $false,

        # Get challenges by group id number
        [Parameter(
            ParameterSetName = 'By Id')]
        [int]$GroupId,

        # Should I recurse into child groups?  Default is false
        [Parameter(
            Mandatory = $false
        )]
        [switch]$Recurse = $false

    
    )
    
    BEGIN {
        # Nothing to see here
    }
    
    PROCESS {
        switch ($pscmdlet.ParameterSetName) {
            "By Name" {
                Write-Verbose -Message "Querying for Challenge by Name"
                $UriSegment = "api.ashx/v2/ideas/challenges.json?Name=$( [System.Web.HTTPUtility]::UrlEncode( [System.Web.HTTPUtility]::HtmlEncode( $Name ) ) )"
                $Uri = $VtCommunity + $UriSegment
                if ( $ExactMatch -and $Recurse ) {
                    $ChallengeId = Get-VtAll -Uri $Uri -AuthHeader $VtAuthHeader | Where-Object { $_.Name -eq [System.Web.HTTPUtility]::HtmlEncode( $Name ) } | Select-Object -ExpandProperty Id
                    if ( $ChallengeId ) {
                        Get-VtGroup -Community $VtCommunity -AuthHeader $VtAuthHeader -Id $GroupId -Recurse
                    }
                }
                elseif ( $ExactMatch -and -not $Recurse ) {
                    Get-VtAll -Uri $Uri -AuthHeader $VtAuthHeader | Where-Object { $_.Name -eq [System.Web.HTTPUtility]::HtmlEncode( $Name ) }
                }
                elseif ( $Recurse -and -not $ExactMatch ) {
                    #Request-Groups -Uri $Uri -AuthHeader $VtAuthHeader
                    $ChallengeIds = Get-VtAll -Uri $Uri -AuthHeader $VtAuthHeader | Select-Object -ExpandProperty Id
                    ForEach ( $ChallengeId in $ChallengeIds ) {
                        Get-VtChallenge -Community $VtCommunity -AuthHeader $VtAuthHeader -GroupId $GroupId -Recurse
                    }
                }
                else {
                    Get-VtAll -Uri $Uri -AuthHeader $VtAuthHeader
                }
                <#
                if ( $Recurse ) {
                    $UriSegment += "&IncludeAllSubGroups=true"
                }
                $Uri = $VtCommunity + $UriSegment
                if ( -not $ExactMatch ) {
                    Request-Groups -Uri $Uri -AuthHeader $VtAuthHeader
                } else {
                    Request-Groups -Uri $Uri -AuthHeader $VtAuthHeader | Where-Object { $_.Name -eq [System.Web.HTTPUtility]::HtmlEncode( $Name ) } | Select-Object -ExpandProperty Id
                }
                #>

            }
            "By Id" {
                Write-Verbose -Message "Querying for Challenge by Group ID"
                $UriSegment = "api.ashx/v2/ideas/challenges.json?GroupId=$GroupId"
                $Uri = $VtCommunity + $UriSegment
                Get-VtAll -Uri $Uri -AuthHeader $VtAuthHeader

                
                if ( $Recurse ) {
                    Write-Verbose -Message "`tQuerying for children of Group by ID"
                    $UriSegment = "api.ashx/v2/ideas/challenges.json?GroupId=$GroupId&IncludeAllSubGroups=true"
                    $Uri = $VtCommunity + $UriSegment
                    Get-VtAll -Uri $Uri -AuthHeader $VtAuthHeader
                }
            }
            Default {
                Write-Verbose -Message "Querying for all challenges"
                $UriSegment = 'api.ashx/v2/ideas/challenges.json?IncludeAllSubGroups=true'
                $UriSegment = 'api.ashx/v2/ideas/challenges.json'
                $Uri = $VtCommunity + $UriSegment
                Get-VtAll -Uri $Uri -AuthHeader $VtAuthHeader
            }
        }
        if ($pscmdlet.ShouldProcess("On this target --> Target", "Did this thing --> Operation")) {
            

        }

    }
    
    END {
        
    }
}
#endregion Challenge Functions

#region Media Gallery Functions
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
function Get-VtGallery {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64678/gallery-rest-endpoints',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Gallery Id for Lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        #[ValidateNotNull()]
        #[ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64]$GalleryId,

        # Group Id for Lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        #[ValidateNotNull()]
        #[ValidateNotNullOrEmpty()]
        [int64]$GroupId,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$ReturnDetails,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
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

    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess( $VtCommunity, "Query Blogs on" ) ) {
        
            if ( $GalleryId -and -not $GroupId) {
                # If we have a GalleryId and NOT a GroupId, return the single blog
                $Uri = "api.ashx/v2/galleries/$GalleryId.json"
                $Type = 'Single'
            }
            elseif ( $GalleryId -and $GroupId ) {
                # If we have a GalleryId and a GroupId, return the single blog within that group
                $Uri = "api.ashx/v2/groups/$GroupId/blogs/$GalleryId.json"
                $Type = 'Single'
            }
            elseif ( -not $GalleryId -and $GroupId ) {
                # If we do NOT have a GalleryId but we have a GroupId, return all blogs within that group
                $Uri = "api.ashx/v2/groups/$GroupId/galleries.json"
                $Type = 'Multiple'
            }
            else {
                # If we have neither a GalleryId nor a GroupId, list all the blogs
                $Uri = "api.ashx/v2/galleries.json"
                $Type = 'Multiple'
            }
        
            if ( $Type -eq 'Single' ) {
                $GalleriesResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers $VtAuthHeader
                if ( $GalleriesResponse ) {
                    if ( $ReturnDetails ) {
                        $GalleriesResponse.Gallery
                    }
                    else {
                        $GalleriesResponse.Gallery | Select-Object -Property @{ Name = "GalleryId"; Expression = { $_.Id } }, Name, Key, @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }, Url, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Owners"; Expression = { ( $_.Owners | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
                    }
                }
                else {
                    Write-Error -Message "No blogs matching ID $GalleryId found."
                }
            }
            else {
                # Multiple returns
            
                $TotalReturned = 0
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $GalleriesResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                    if ( $GalleriesResponse ) {
                        $TotalReturned += $GalleriesResponse.Galleries.Count
                        if ( $ReturnDetails ) {
                            $GalleriesResponse.Galleries
                        }
                        else {
                            $GalleriesResponse.Galleries | Select-Object -Property @{ Name = "GalleryId"; Expression = { $_.Id } }, Name, Key, @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }, Url, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Owners"; Expression = { ( $_.Owners | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $GalleriesResponse.TotalCount)
            }
        
        } #end of 'should process'
    }
    END {
        # Nothing to see here
    }
}

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
function Set-VtGallery {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64683/update-gallery-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        # Gallery ID on which to Operate
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64]$GalleryId,

        # The name of the Gallery
        [Parameter(
            Mandatory = $false
        )]
        [string]$Name,

        # The slug in the URL
        [Parameter(
            Mandatory = $false 
        )]
        [Alias("Slug")] 
        [string]$Key,

        # Gallery Description (60-200 characters is best)
        [Parameter(
            Mandatory = $false 
        )]
        [string]$Description,

        # Disable the gallery?
        [Parameter(
            Mandatory = $false 
        )]
        [switch]$Disabled,

        # Comma separated list of owner usernames
        [Parameter(
            Mandatory = $false 
        )]
        [string]$Owners,

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
        $VtAuthHeader = $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -Verbose:$false -WhatIf:$false
        
        # Build URI Parameters
        $UriParameters = @{}
        if ( $Name ) { $UriParameters["Name"] = [System.Web.HttpUtility]::UrlEncode($Name) }
        if ( $Key ) { $UriParameters["Key"] = $Key }
        if ( $Description ) { $UriParameters["Description"] = [System.Web.HttpUtility]::UrlEncode($Description) }
        if ( $Disabled ) { $UriParameters["Enabled"] = $false }
        if ( $Owners ) { $UriParameters["Owners"] = $Owners }

        $Uri = "api.ashx/v2/galleries/$GalleryId.json"
    }
    PROCESS {

        $CurrentName = Get-VtGallery -GalleryId $GalleryId -Community $VtCommunity -AuthHeader $VtAuthHeader -ErrorAction SilentlyContinue -WhatIf:$false | Select-Object -Property @{ Name = "Gallery"; Expression = { "'$( $_.Name )' in '$( $_.GroupName )'" } } | Select-Object -ExpandProperty Gallery
        if ( $PSCmdlet.ShouldProcess( $VtCommunity, "Update Gallery '$CurrentName'" ) ) {
            $Response = Invoke-RestMethod -Method Post -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -ErrorAction SilentlyContinue -WhatIf:$false )
            if ( $Response ) {
                $Response.Gallery | Select-Object -Property @{ Name = "GalleryId"; Expression = { $_.Id } }, Name, Key, @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }, Url, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Owners"; Expression = { ( $_.Owners | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
            }
        }
    }
    END {
        # Nothing to see here
    }
}

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
function Get-VtGalleryMedia {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64763/media-rest-endpoints',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Gallery Id for Media Lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'By Gallery ID'
        )]
        #[ValidateNotNull()]
        #[ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64]$GalleryId,

        # Group Id for Lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'By Group ID'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64]$GroupId,

        # All Media (Use with caution)
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'All Media'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$AllMedia,
                

        # Filter for a an Author by ID
        [Parameter(
            Mandatory = $false
        )]
        [int]$AuthorId,

        # Filter for a an Author by Name
        [Parameter(
            Mandatory = $false
        )]
        [string]$AuthorName,

        # Filter for minimum download count
        [Parameter(
            Mandatory = $false
        )]
        [int]$MinimumDownloadCount,

        # Filter for maximum download count
        [Parameter(
            Mandatory = $false
        )]
        [int]$MaximumDownloadCount,

        # Sort by type (Post Date is default)
        [Parameter(
            Mandatory = $false
        )]
        [ValidateSet("Author", "Comments", "Downloads", "PostDate", "Rating", "Subject", "Views", "Score:SCORE_ID", "ContentIdsOrder")]
        [string]$SortBy = "PostDate",

        # Sort Order (Ascending is default for all except Scores)
        [Parameter(
            Mandatory = $false
        )]
        [switch]$Descending,

        # Hide the progress bar
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$HideProgress,

        # Return all details in the JSON call?
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$ReturnDetails,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
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

        # Setup the other parameters
        if ( $AuthorName ) {
            # We need author ID's, so we'll look up this author and store the ID
            $AuthorId = Get-VtUser -Username $AuthorName -Community $VtCommunity -AuthHeader $AuthorId -Verbose:$false | Select-Object -ExpandProperty Id
        }

        if ( $AuthorId ) {
            $UriParameters["AuthorId"] = $AuthorId
        }

        if ( $MinimumDownloadCount ) {
            $UriParameters["MinimumDownloadCount"] = $MinimumDownloadCount
        }

        if ( $MaximumDownloadCount ) {
            $UriParameters["MaximumDownloadCount"] = $MaximumDownloadCount
        }

        $UriParameters["SortBy"] = $SortBy

        if ( $Descending ) {
            $UriParameters["SortOrder"] = "Descending"
        }
        else {
            $UriParameters["SortOrder"] = "Ascending"
        }
    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess( $VtCommunity, "Query Media Gallery Files on" ) ) {
        
            switch ( $PSCmdlet.ParameterSetName ) {
            
                'All Media' { $Uri = "api.ashx/v2/media/files.json" }
                'By Group ID' { $Uri = "api.ashx/v2/groups/$GroupId/media/files.json" }
                'By Gallery ID' { $Uri = "api.ashx/v2/media/$GalleryId/files.json" }
            }
        
            $TotalReturned = 0
            do {
                if ( $TotalReturned -and -not $HideProgress ) {
                    Write-Progress -Activity "Querying for Media Gallery Items" -Status "Retrieved $TotalReturned of $( $MediaResponse.TotalCount ) items" -CurrentOperation "Making call #$( $UriParameters["PageIndex"] + 1 )" -PercentComplete ( 100 * ( $TotalReturned / $MediaResponse.TotalCount ) )
                }
                Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                $MediaResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                if ( $MediaResponse ) {
                    $TotalReturned += $MediaResponse.MediaPosts.Count
                    if ( $ReturnDetails ) {
                        $MediaResponse.MediaPosts
                    }
                    else {
                        $MediaResponse.MediaPosts | Select-Object -Property @{ Name = "MediaFileId"; Expression = { $_.Id } }, @{ Name = "GalleryId"; Expression = { $_.MediaGalleryId } }, GroupId, @{ Name = "Author"; Expression = { $_.Author.Username } }, Date, @{ Name = "Name"; Expression = { $_.Title } }, Description, @{ Name = "Tags"; Expression = { ( $_.Tags | ForEach-Object { $_ | Select-Object -ExpandProperty Value } ) } }, Url, @{ Name = "FileName"; Expression = { $_.File.FileName } }, @{ Name = "FileType"; Expression = { $_.File.ContentType } }, @{ Name = "FileSize"; Expression = { $_.File.FileSize } }, @{ Name = "FileUrl"; Expression = { $_.File.FileUrl } }, CommentCount, Views, Downloads, RatingCount, RatingSum
                    }
                }
                $UriParameters["PageIndex"]++
            } while ($TotalReturned -lt $MediaResponse.TotalCount)
            if ( -not $HideProgress ) {
                Write-Progress -Activity "Querying for Media Gallery Items" -Completed
            }
        
        } #end of 'should process'
    }
    END {
        # Nothing to see here
    }
}

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
function Set-VtGalleryMedia {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64768/update-media-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        # File Id on which to Operate
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("FileId", "MediaId")] 
        [int64]$MediaFileId,

        # Gallery Id on which to operate
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [int64]$GalleryId,

        # The Title of the media
        [Parameter(
            Mandatory = $false 
        )]
        [Alias("Title")] 
        [string]$Name,

        # Media Description [HTML formatted]
        [Parameter(
            Mandatory = $false 
        )]
        [string]$Description,

        # Comma-separated list of tags
        [Parameter(
            Mandatory = $false 
        )]
        [string[]]$Tags,

        # If enabled, then return the new object, otherwise return nothing
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$PassThru,

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

        # Setup the parameters
        $UriParameters = @{}

        if ( $Name ) {
            $UriParameters["Name"] = $Name
        }

        if ( $Description ) {
            $UriParameters["Description"] = $Description
        }

        if ( $Tags ) {
            if ( $Tags -is [System.Array] ) {
                $UriParameters["Tags"] = $Tags -join "," 
            }
            else { $UriParameters["Tags"] = $Tags }
        } 

    }

    PROCESS {
        if ( -not $UriParameters ) {
            # If we have no parameters to change, then there's nothing to do
            Write-Error -Message "Function requires Name, Description, or Tags parameter" -RecommendedAction "Pass -Name, -Description, or -Tags parameters."
        }
        else {
            if ( $PSCmdlet.ShouldProcess( $VtCommunity, "Update Media ID '$MediaFileId' in Gallery ID '$( $GalleryId )'" ) ) {
                $Uri = "api.ashx/v2/media/$GalleryId/files/$MediaFileId.json"
                $Response = Invoke-RestMethod -Method Post -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -ErrorAction SilentlyContinue -WhatIf:$false )
                if ( $Response -and $PassThru ) {
                    $Response.Media | Select-Object -Property @{ Name = "MediaFileId"; Expression = { $_.Id } }, @{ Name = "GalleryId"; Expression = { $_.MediaGalleryId } }, GroupId, @{ Name = "Author"; Expression = { $_.Author.Username } }, Date, @{ Name = "Name"; Expression = { $_.Title } }, Description, @{ Name = "Tags"; Expression = { ( $_.Tags | ForEach-Object { $_ | Select-Object -ExpandProperty Value } ) } }, Url, @{ Name = "FileName"; Expression = { $_.File.FileName } }, @{ Name = "FileType"; Expression = { $_.File.ContentType } }, @{ Name = "FileSize"; Expression = { $_.File.FileSize } }, @{ Name = "FileUrl"; Expression = { $_.File.FileUrl } }, CommentCount, Views, Downloads, RatingCount, RatingSum
                }
            }
        }
        
    }
    END {
        # Nothing to see here
    }
}
#endregion Media Gallery Functions

#region Group Functions
<#
.Synopsis
    Get groups from Verint / Telligent communities
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    https://community.telligent.com/community/11/w/api-documentation/64702/list-group-rest-endpoint
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Get-VtGroup {
    [CmdletBinding(DefaultParameterSetName = 'By Name', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64699/group-rest-endpoints',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType()]
    Param
    (
        # Get group by name
        [Parameter(
            ParameterSetName = 'By Name')]
        [Alias("Name")]
        [string[]]$GroupName,

        # Group name exact match
        [Parameter(
            ParameterSetName = 'By Name')]
        [switch]$ExactMatch = $false,

        # Get group by id number
        [Parameter(
            ParameterSetName = 'By Group Id')]
        [Alias("Id")]
        [int[]]$GroupId,

        # Get group by parent id number
        [Parameter()]
        [Alias("ParentId")]
        [int]$ParentGroupId,

        # Return limited details
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

        # Get all groups
        [Parameter(
            ParameterSetName = 'All Groups')]
        [Alias("All")]
        [switch]$AllGroups,

        # Resolve the parent id to a name
        [switch]$ResolveParentName,

        # Get all groups
        [Parameter()]
        [ValidateSet("Joinless", "PublicOpen", "PublicClosed", "PrivateUnlisted", "PrivateListed", "All")]
        [Alias("Type")]
        [string]$GroupType = "All",

        <#
        # Should I recurse into child groups?  Default is false
        [Parameter(
            ParameterSetName = 'By Group Id'
        )]
        [Parameter(
            ParameterSetName = 'By Name'
        )]
        [switch]$Recurse,
        #>

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
        $UriParameters = @{}
        $UriParameters['PageSize'] = $BatchSize
        $UriParameters['PageIndex'] = 0
        $UriParameters['GroupTypes'] = $GroupType
        if ( $ParentGroupId ) {
            $UriParameters['ParentGroupId'] = $ParentGroupId
        }
        $OutputProperties = @{ Name = "GroupId"; Expression = { $_.Id } }, @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } }, "Key", @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }, "DateCreated", "Url", "GroupType", "ParentGroupId"
        if ( $ResolveParentName ) {
            $OutputProperties += "ParentGroupName"
        }
    }
    
    PROCESS {
        switch ( $pscmdlet.ParameterSetName ) {
            'By Name' {
                ForEach ( $Name in $GroupName ) {
                    $Uri = 'api.ashx/v2/groups.json'
                    $UriParameters['GroupNameFilter'] = $Name
                    $GroupCount = 0

                    do {
                        Write-Verbose -Message "Making call with '$Uri'"
                        # Get the list of groups with matching name from the call
                        $GroupsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader -Verbose:$false

                        if ( $GroupsResponse ) {
                            $GroupCount += $GroupsResponse.Groups.Count
                            # If we need an exact response on the name, then filter for only that exact group
                            if ( $ExactMatch ) {
                                $GroupsResponse.Groups = $GroupsResponse.Groups | Where-Object { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) -eq $Name }
                            }
                            if ( $ResolveParentName ) {
                                # This calls itself to get the parent group name
                                $GroupsResponse.Groups | Add-VtMember -MemberType ScriptProperty -Name "ParentGroupName" -Value { Get-VtGroup -GroupId $this.ParentGroupId -Community $VtCommunity -AuthHeader $VtAuthHeader | Select-Object -Property @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } } | Select-Object -ExpandProperty Name } -Force
                            }
                            # Should we return everything?
                            if ( $ReturnDetails ) {
                                $GroupsResponse.Groups
                            }
                            else {
                                $GroupsResponse.Groups | Select-Object -Property $OutputProperties
                            }
                        }
                    
                        $UriParameters['PageIndex']++
                        Write-Verbose -Message "Incrementing Page Index :: $( $UriParameters['PageIndex'] )"
                    } while ( $GroupCount -lt $GroupsResponse.TotalCount )
                    
                }
            }
            'By Group Id' {
                ForEach ( $Id in $GroupId ) {
                    # Setup the URI - depends on if we are using a parent ID or not
                    if ( $ParentGroupId ) {
                        $Uri = "api.ashx/v2/groups/$ParentGroupId/groups/$Id.json"
                    }
                    else {
                        $Uri = "api.ashx/v2/groups/$Id.json"
                    }

                    # Because everything is encoded in the URI, we don't need to send any $UriParameters
                    Write-Verbose -Message "Making call with '$Uri'"
                    $GroupsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers $VtAuthHeader -Verbose:$false
                    
                    if ( $ResolveParentName ) {
                        # This calls itself to get the parent group name
                        $GroupsResponse.Groups | Add-VtMember -MemberType ScriptProperty -Name "ParentGroupName" -Value { Get-VtGroup -GroupId $this.ParentGroupId | Select-Object -Property @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } } | Select-Object -ExpandProperty Name } -Force
                    }

                    # Filter if we are using the parent group id
                    if ( $ParentGroupId ) {
                        $GroupsResponse.Group = $GroupsResponse.Group | Where-Object { $_.ParentGroupId -eq $ParentGroupId }
                    }
                    
                    if ( $GroupsResponse.Group ) {
                        if ( $ReturnDetails ) {
                            $GroupsResponse.Group
                        }
                        else {
                            $GroupsResponse.Group | Select-Object -Property $OutputProperties
                        }
                    }
                    else {
                        Write-Warning -Message "No matching groups found."
                    }
                }
            }
            'All Groups' {
                # No ForEach loop needed here because we are pulling all groups
                $Uri = 'api.ashx/v2/groups.json'
                $GroupCount = 0
                do {
                    $GroupsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader -Verbose:$false

                    if ( $ResolveParentName ) {
                        # This calls itself to get the parent group name
                        $GroupsResponse.Groups | Add-VtMember -MemberType ScriptProperty -Name "ParentGroupName" -Value { Get-VtGroup -GroupId $this.ParentGroupId | Select-Object -Property @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } } | Select-Object -ExpandProperty Name } -Force
                    }

                    if ( $GroupsResponse ) {
                        $GroupCount += $GroupsResponse.Groups.Count
                        if ( $ParentGroupId ) {
                            $GroupsResponse.Groups = $GroupsResponse.Groups | Where-Object { $_.ParentGroupId -eq $ParentGroupId }
                        }
                        if ( $ReturnDetails ) {
                            $GroupsResponse.Groups
                        }
                        else {
                            $GroupsResponse.Groups | Select-Object -Property $OutputProperties
                        }
                    }
                    $UriParameters['PageIndex']++
                    Write-Verbose -Message "Incrementing Page Index :: $( $UriParameters['PageIndex'] )"
                } while ( $GroupCount -lt $GroupsResponse.TotalCount )
            }
        }
        if ( $pscmdlet.ShouldProcess( "On this target --> Target", "Did this thing --> Operation" ) ) {
            
        }

    }
    
    END {
        # Nothing to see here
    }
}
#endregion Group Functions

#region Idea Functions
# This still needs some significant work, but is sufficient for us at the moment to pull what *we* need.
# If you are using other statuses, you may need to change the allow list of status names for the [string]$Status parameter line
function Get-VtIdea {
    [CmdletBinding(
        DefaultParameterSetName = 'Thread By Idea Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64723/list-idea-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    param (
        
        # Idea ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Idea Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [guid]$IdeaId,
        
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'All Ideas'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("All")]
        [switch]$AllIdeas,

        # Filter for only Ideas in a specific group
        [Parameter()]
        [int64]$GroupId,

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
        
        
    }
    PROCESS {
        if ( $AllIdeas ) {
            if ( $pscmdlet.ShouldProcess("$VtCommunity", "Get info about all Ideas'") ) {
                $Uri = 'api.ashx/v2/ideas/ideas.json'
                $IdeaCount = 0
                do {
                    if ( $UriParameters["PageIndex"] -gt 0 ) {
                        Write-Progress -Activity "Querying for Ideas" -Status "Making call #$( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"] ) ideas of $( $IdeaResponse.TotalCount ) total ideas" -PercentComplete ( $IdeaCount / $IdeaResponse.TotalCount * 100 )
                    }
                    else {
                        Write-Progress -Activity "Querying for Ideas" -Status "Making first call for first $( $UriParameters["PageSize"] ) ideas"
                    }
                    $IdeaResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                    if ( $IdeaResponse ) {
                        if ( -not $ReturnDetails ) {
                            $IdeaResponse.Ideas | Select-Object -Property @{ Name = "IdeaId"; Expression = { $_.Id } }, @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } }, @{ Name = "Status"; Expression = { $_.Status.Name } }, @{ Name = "Author"; Expression = { $_.AuthorUser.Username } }, CreatedDate, LastUpdatedDate, Url, Score, @{ Name = "StatusNote"; Expression = { $_.CurrentStatus.Note } }
                        }
                        else {
                            $IdeaResponse.Ideas
                        }
                        $IdeaCount += $IdeaResponse.Ideas.Count
                    }
                    $UriParameters["PageIndex"]++
                } while ($IdeaCount -lt $IdeaResponse.TotalCount )
                Write-Progress -Activity "Querying for Ideas" -Completed
            }
        }
        else {
            if ( $pscmdlet.ShouldProcess("$VtCommunity", "Get info about Idea ID: $IdeaId'") ) {
                $Uri = "api.ashx/v2/Ideas/$IdeaId.json"
            }
        }
    }
    
    END {
        
    }
}
#endregion Idea Functions

#region Notification Functions
function Get-VtSysNotification {
    [CmdletBinding(
        DefaultParameterSetName = 'ContentId',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64865/system-notification-rest-endpoints',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        <#
        # Content ID to use for lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'ContentId')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [guid]$ContentId,
        #>
        # Content URL to use for lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 20,

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

        # Set the Uri for the target
        $Uri = 'api.ashx/v2/systemnotifications.json'

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageSize"] = $BatchSize
        $UriParameters["PageIndex"] = 0

    }
    PROCESS {

        $TotalNotifications = 0
        if ( $PSCmdlet.ShouldProcess("Target", "Operation") ) {
            do {
                $NotificationsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                if ( $NotificationsResponse ) {
                    $TotalNotifications += $NotificationsResponse.SystemNotifications.Count
                    $NotificationsResponse.SystemNotifications
                    $UriParameters["PageIndex"]++
                }
            } while ( $TotalNotifications -lt $NotificationsResponse.TotalCount )
        }
    }

    END {
        # Nothing to see here
    }
}
#endregion Notification Functions

#region Points Functions
<#
.Synopsis
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    New-VtPointTransaction -Username KMSigma -Description "Say hi to your wife for me." -AwardDateTime "09/14/2019" -Points 43 -Community $VtCommunity -AuthHeader $VtAuthHeader
.EXAMPLE
    New-VtPointTransaction -Username KMSigma -Description "Will confirm if you ask for more for 5,000 points" -Points 5001 -Community $VtCommunity -AuthHeader $VtAuthHeader
.OUTPUTS
    PowerShell Custom Object Containing the Content, CreateDate, Description, Transaction ID, User Custom Object, and point Value
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function New-VtPointTransaction {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64799/point-transaction-rest-endpoints',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param(
        # The username of the account who is getting the points
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,

        # The number of points to award to an account.  This does not support removing points.
        [Parameter(
            Mandatory = $true, 
            Position = 1
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 100000)]
        [int]$Points,

        # Description of the points award.  Should try and keep the description to less than 120 characters if possible.
        [Parameter(
            Mandatory = $true, 
            Position = 2
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(0, 250)]
        [string]$Description,


        # The date/time you want to have the awards added - defaults to 'now'
        [Parameter(
            Mandatory = $false, 
            Position = 3
        )]
        [datetime]$AwardDateTime = ( Get-VtDate ),

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

        $Uri = "api.ashx/v2/pointtransactions.json"

        $RestMethod = "GET"
    }
    PROCESS {

        ForEach ( $U in $Username ) {
            $Proceed = $true

            # Convert the username to a userid
            $User = Get-VtUser -Username $U -AuthHeader $VtAuthHeader -Community $VtCommunity -ReturnDetails -WhatIf:$false
            # Since point transactions require a ContentId and ContentTypeId, we should pull those from the user's profile
            if ( -not $User ) {
                Write-Error -Message "Unable to add point because we didn't find a matching user for [$U]"
                $Proceed = $false
            }
            else {
                $Userid = $User.Id
                $ContentId = $User.ContentId
                $ContentTypeId = $User.ContentTypeId
            }
        
            if ($pscmdlet.ShouldProcess("User: $( $User.DisplayName )", "Add $Points points") -and $Proceed) {
                if ( $Points -gt 5000 ) {
                    Write-Host "====LARGE POINT DISTRIBUTION VALIDATION====" -ForegroundColor Yellow
                    $BigPoints = Read-Host -Prompt "You are about to add $Points to $( $U.DisplayName  )'s account.  Are you sure you want to do this?  [Enter 'Yes' to confirm]"
                    $Proceed = ( $BigPoints.ToLower() -eq 'yes' )
                }
                if ( $Proceed ) {
                    # Build the body to send to the account
                    # For proper display, the description needs to be wrapped in HTML paragraph tags.
                    $Body = @{
                        Description   = "<p>$Description</p>";
                        UserId        = $UserId;
                        Value         = $Points;
                        ContentID     = $ContentId; # We'll just use the ContentID from the user
                        ContentTypeId = $ContentTypeId; # We'll just use the ContentID from the user
                        CreatedDate   = $AwardDateTime;
                    }
                    try {
                        $PointsRequest = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Method Post -Body $Body -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -Verbose:$False -WhatIf:$false )
                        $PointsRequest.PointTransaction
                    }
                    catch {
                        Write-Error -Message "Something didn't work"
                    }
                }
            }
        }
    }
    END {
        # Nothing to see here
    }
}

<#

I think I want to change the logic here to a do..while at a later date

#>
function Get-VtPointTransaction {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64803/list-point-transactions-point-transaction-rest-endpoint',
        ConfirmImpact = 'Medium')
    ]
    Param
    (
        # Username to use for lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Username')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Email Address'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$EmailAddress,

        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'User Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]$UserId,

        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Transaction Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]$TransactionId,

        # Get all transactions
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All Users'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$AllUsers = $false,

        # Start Date of Transaction Search
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [datetime]$StartDate,

        # End Date of Transaction Search - defaults to 'now'
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [datetime]$EndDate,

        # Should we return all details or just the simplified version
        [switch]$ReturnDetails = $false,

        # Optional Filter to set for the action.
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$ActionFilter,

        # Optional page size grab for the call to the API. (Script defaults to 1000 per batch)
        # Larger page sizes generally complete faster, but consume more memory
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(100, 10000)]
        [int]$BatchSize = 1000,

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

        $RestMethod = "GET"

        # Base Uri for calls
        $Uri = "api.ashx/v2/pointtransactions.json"
        
        # Create an collection for the UriParameters
        $UriParameters = @{}
        $UriParameters.Add("PageIndex", 0)
        $UriParameters.Add("PageSize", $BatchSize)
        if ( $EndDate ) {
            $UriParameters.Add("EndDate", $EndDate)
        }
        if ( $StartDate ) {
            $UriParameters.Add("StartDate", $StartDate)
        }
    }
    

    PROCESS {
        
        switch ( $pscmdlet.ParameterSetName ) {
            'User Id' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the user id [$UserId] for the lookup"
                # Points Lookup requires the UserID, not the username
                $UriParameters.Add("UserId", $UserId)
                $LookupKey = "for User ID: [$UserId]"
            }
            'Username' { 
                Write-Verbose -Message "Get-VtPointTransaction: Using the username [$Username] for the lookup"
                # Points Lookup requires the UserID, not the username
                $User = Get-VtUser -Username $Username -Community $VtCommunity -AuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                $UriParameters.Add("UserId", $User.UserId)
                $LookupKey = "for Username: [$Username]"
            }
            'Email Address' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the email [$EmailAddress] for the lookup"
                # Points Lookup requires the UserID, not the email address
                $User = Get-VtUser -EmailAddress $EmailAddress -Community $VtCommunity -AuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                $UriParameters.Add("UserId", $User.UserId)
                $LookupKey = "for Email Address: [$EmailAddress]"
            }
            'Transaction Id' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the TransactionID [$TransactionId] for the lookup"
                # Points Lookup requires the UserID, not the email address
                $LookupKey = "for Transaction ID: [$TransactionId]"
            }
            'All Users' {
                Write-Verbose -Message "Request all points for the lookup"
                $LookupKey = "for [All Users]"
            }
        }

        if ( $UriParameters["UserId"] -or $pscmdlet.ParameterSetName -eq 'All Users' ) {
            if ( $pscmdlet.ShouldProcess("$VtCommunity", "Search for point transactions $LookupKey") ) {
                $PointsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                Write-Verbose -Message "Received $( $PointsResponse.PointTransactions.Count ) responses"
                Write-Progress -Activity "Querying $VtCommunity for Points Transactions" -CurrentOperation "Searching $LookupKey for the first $BatchSize entries" -PercentComplete 0
                $TotalResponseCount = $PointsResponse.PointTransactions.Count
                if ( $ActionFilter ) {
                    $PointTransactions = $PointsResponse.PointTransactions | Where-Object { ( $_.Description | ConvertFrom-HtmlString ) -like $ActionFilter }
                    Write-Verbose -Message "Keeping $( $PointTransactions.Count ) total responses"
                }
                else {
                    $PointTransactions = $PointsResponse.PointTransactions
                    Write-Verbose -Message "Keeping all $( $PointTransactions.Count ) responses"
                }

                while ( $TotalResponseCount -lt $PointsResponse.TotalCount ) {
                    # Bump the page index counter
                    ( $UriParameters.PageIndex )++
                    Write-Verbose -Message "Making call #$( $UriParameters.PageIndex ) to the API"
                    Write-Progress -Activity "Querying $VtCommunity for Points Transactions" -CurrentOperation "Making call #$( $UriParameters.PageIndex ) to the API [$TotalResponseCount / $( $PointsResponse.TotalCount )]" -PercentComplete ( ( $TotalResponseCount / $PointsResponse.TotalCount ) * 100 )
                    $PointsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                    Write-Verbose -Message "Received $( $PointsResponse.PointTransactions.Count ) responses"
                    $TotalResponseCount += $PointsResponse.PointTransactions.Count
                    if ( $ActionFilter ) {
                        $PointTransactions += $PointsResponse.PointTransactions | Where-Object { ( $_.Description | ConvertFrom-HtmlString ) -like $ActionFilter }
                        Write-Verbose -Message "Keeping $( $PointTransactions.Count ) total responses"
                    }
                    else {
                        $PointTransactions += $PointsResponse.PointTransactions
                        Write-Verbose -Message "Keeping all $( $PointTransactions.Count ) responses"
                    }
                }
                Write-Progress -Activity "Querying $VtCommunity for Points Transactions" -Completed

                # If we want details, return everything
                if ( $ReturnDetails ) {
                    $PointTransactions
                }
                else {
                    $PointTransactions | Select-Object -Property @{ Name = "TransactionId"; Expression = { [int]( $_.id ) } }, @{ Name = "Username"; Expression = { $_.User.Username } }, @{ Name = "UserId"; Expression = { $_.User.Id } }, Value, @{ Name = "Action"; Expression = { $_.Description | ConvertFrom-HtmlString } }, @{ Name = "Date"; Expression = { $_.CreatedDate } }, @{ Name = "Item"; Expression = { $_.Content.HtmlName | ConvertFrom-HtmlString } }, @{ Name = "ItemUrl"; Expression = { $_.Content.Url } }
                }
            }
        }
        elseif ( $pscmdlet.ParameterSetName -eq 'Transaction Id' ) {
            $Uri = "api.ashx/v2/pointtransaction/$( $TransactionId ).json"
            $PointsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false ) -Verbose:$false
            if ( $PointsResponse.PointTransaction.User ) {
                # If we want details, return everything
                if ( $ReturnDetails ) {
                    $PointsResponse.PointTransaction
                }
                else {
                    $PointsResponse.PointTransaction | Select-Object -Property @{ Name = "TransactionId"; Expression = { [int]( $_.id ) } }, @{ Name = "Username"; Expression = { $_.User.Username } }, @{ Name = "UserId"; Expression = { $_.User.Id } }, Value, @{ Name = "Action"; Expression = { $_.Description | ConvertFrom-HtmlString } }, @{ Name = "Date"; Expression = { $_.CreatedDate } }, @{ Name = "Item"; Expression = { $_.Content.HtmlName | ConvertFrom-HtmlString } }, @{ Name = "ItemUrl"; Expression = { $_.Content.Url } }
                }
            }
            else {
                Write-Verbose -Message "No points transaction found matching #$TransactionId"
            }
        }
    }
    END {
        # Nothing to see here
    }
}

<#
.Synopsis
    Remove a Point Transaction based on the Transaction ID
.DESCRIPTION
    Remove one or more point transactions using the 
.EXAMPLE
    
.EXAMPLE
    
.OUTPUTS
    PowerShell Custom Object Containing the Content, CreateDate, Description, Transaction ID, User Custom Object, and point Value
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Remove-VtVtPointTransaction {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64801/delete-point-transaction-point-transaction-rest-endpoint',
        ConfirmImpact = 'High')
    ]
    Param
    (
        # TransactionIDs to use for lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int[]]$TransactionId,

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

        $RestMethod = "Delete"

    }
    PROCESS {
        # This is where things do stuff
        ForEach ( $id in $TransactionId ) {
            if ( Get-VtPointTransaction -TransactionId $Id -Community $VtCommunity -AuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod Get -WhatIf:$false -Verbose:$false ) -Verbose:$false ) {
                if ( $pscmdlet.ShouldProcess("$VtCommunity", "Delete Point Transaction $id") ) {
                
                    $Uri = "api.ashx/v2/pointtransaction/$( $id ).json"
                    # Method: Post
                    # Rest-Method: Delete
                    try {
                        $RemovePointsResponse = Invoke-RestMethod -Method Post -Uri ( $VtCommunity + $Uri ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                        if ( $RemovePointsResponse ) {
                            Write-Verbose -Message "Points Transaction #$id removed"
                        }
                    }
                    catch {
                        Write-Error -Message "Error purging Points Transaction #$id"
                    }
                }
                
            }
            else {
                Write-Verbose -Message "No points transaction found matching #$id.  Unable to delete."
            }
        }

    }
    END {
        # nothing here
    }
}


<#
.Synopsis
   Get the necessary authentication header for Verint | Telligent Community
.DESCRIPTION
   Using the username and API key, we'll build an authentication header required to access Verint | Telligent Communities.
   Note this creation does NOT validate that the authentication works - it just builds the header.
.EXAMPLE
   Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"

   Name                           Value
   ----                           -----
   Rest-User-Token                bG1[omitted]dtYQ==
.INPUTS
   Username and API key.  Your API key is distinct, but as powerful as your password.  Guard it similarly.
   API Keys can be obtained from https://community.domain.here/user/myapikeys
.OUTPUTS
   Hashtable with necessary headers
.NOTES
   https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-VtAuthHeader {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests',
        ConfirmImpact = 'Medium')
    ]
    [Alias("New-VtAuthHeader")]
    param (
        # Username for the call to the REST endpoint
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        [Alias("User")] 
        [string]$Username,

        # API Key for the associated user
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 1)]
        [Alias("Key")] 
        [string]$ApiKey
    )

    begin {
        # Nothing here
    }

    process {
        if ( $pscmdlet.ShouldProcess("", "Generate Authentication Header") ) {
            $Base64Key = [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes( "$( $ApiKey ):$( $Username )" ) )
            # Return the header with the token only
            @{
                'Rest-User-Token' = $Base64Key
            }
        }
    }
   
    end {
        #Nothing to see here        
    }
}

<#
.Synopsis
   Update an existing authentication header for Verint | Telligent Community
.DESCRIPTION
   Add an optional REST Method for use with Update and Delete type calls
.EXAMPLE
   $VtAuthHeader | Set-VtAuthHeader -Method "Delete"

   Name                           Value
   ----                           -----
   Rest-User-Token                bG1[omitted]dtYQ==
   Rest-Method                    DELETE

   Take an existing header and add "Delete" as the rest method

.EXAMPLE
   $VtAuthHeader

   Name                           Value
   ----                           -----
   Rest-User-Token                bG1[omitted]dtYQ==
   Rest-Method                    DELETE

   PS > $VtAuthHeader | Set-VtAuthHeader -Method "Get"

   Name                           Value
   ----                           -----
   Rest-User-Token                bG1[omitted]dtYQ==

   "Get" style queries do not require a 'Rest-Mehod' in the header, so it is removed.  This is the same functionality as passing no RestMethod parameter.

.EXAMPLE
   $VtAuthHeader

   Name                           Value
   ----                           -----
   Rest-User-Token                bG1[omitted]dtYQ==

   PS > $DeleteHeader = $VtAuthHeader | Set-VtAuthHeader -Method "Delete"
   PS > $DeleteHeader

   Name                           Value
   ----                           -----
   Rest-User-Token                bG1[omitted]dtYQ==
   Rest-Method                    DELETE

   PS > $UpdateHeader = $VtAuthHeader | Set-VtAuthHeader -Method "Put"
   PS > $UpdateHeader

   Name                           Value
   ----                           -----
   Rest-User-Token                bG1[omitted]dtYQ==
   Rest-Method                    PUT

   Create two new headers ($DeleteHeader and $UpdateHeader) based on the original header ($VtAuthHeader)

.INPUTS
   Existing Authentication Header (as Hashtable)
.OUTPUTS
   Hashtable with necessary headers
.NOTES
   https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests

#>
function Set-VtAuthHeader {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests',
        ConfirmImpact = 'Medium')
    ]
    param (
        # Existing authentication header
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        [Alias("Header")] 
        [System.Collections.Hashtable[]]$VtAuthHeader,

        # Rest-Method to invoke
        [Parameter(Mandatory = $false, 
            Position = 1)]
        [ValidateSet("Get", "Put", "Delete")] # There may be others
        [Alias("Method")] 
        [string]$RestMethod = "Get"
    )

    begin {
        # Nothing to see here
    }

    process {
        # Support multiple tokens (this should be rare)
        ForEach ( $h in $VtAuthHeader ) {
         
            if ( $h["Rest-User-Token"] ) {
                if ( $pscmdlet.ShouldProcess("Header with 'Rest-User-Token: $( $h["Rest-User-Token"] )'", "Update Rest-Method to $RestMethod type") ) {
                    if ( $RestMethod -ne "Get" ) {
               
                        # Add a Rest-Method to the Token
                        $h["Rest-Method"] = $RestMethod.ToUpper()
                    }
                    else {
                        # 'Get' does not require the additional Rest-Method, so we'll remove it
                        if ( $h["Rest-Method"] ) {
                            $h.Remove("Rest-Method")
                        }
                    }
                }
                $h
            }
            else {
                Write-Error -Message "Header does not contain the 'Rest-User-Token'" -RecommendedAction "Please generate a valid header with Get-VtAuthHeader"
            }
        }
    }

    end {
        #Nothing to see here        
    }
}

function Get-VtForumThread {
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

function Get-VtForum {
    [CmdletBinding(
        DefaultParameterSetName = 'Thread By Forum Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64656/Show-Vtforum-rest-endpoint',
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
        $UriParameters = @{}
        $UriParameters['PageSize'] = $BatchSize
        $UriParameters['PageIndex'] = 0
        
    }
    PROCESS {
        if ( $AllForums ) {
            if ( $pscmdlet.ShouldProcess("$VtCommunity", "Get info about all forums'") ) {
                $Uri = 'api.ashx/v2/forums.json'
                $ForumCount = 0
                do {
                    $ForumResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                    if ( $ForumResponse ) {
                        if ( -not $ReturnDetails ) {
                            $ForumResponse.Forums | Select-Object -Property @{ Name = 'ForumId'; Expression = { $_.Id } }, Title, Key, Url, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode($_.Group.Name) } }, @{ Name = "GroupKey"; Expression = { $_.Group.Key } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "AllowedThreadTypes"; Expression = { ( $_.AllowedThreadTypes.Value | Sort-Object ) -join ", " } }, DefaultThreadType, LatestPostDate, Enabled, ThreadCount, ReplyCount
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
            if ( $pscmdlet.ShouldProcess("$VtCommunity", "Get info about Forum ID: $ForumId'") ) {
                $Uri = "api.ashx/v2/forums/$ForumId.json"
                $ForumResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers $VtAuthHeader
                if ( $ForumResponse ) {
                    if ( -not $ReturnDetails ) {
                        $ForumResponse.Forum | Select-Object -Property @{ Name = 'ForumId'; Expression = { $_.Id } }, Title, Key, Url, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode($_.Group.Name) } }, @{ Name = "GroupKey"; Expression = { $_.Group.Key } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "AllowedThreadTypes"; Expression = { ( $_.AllowedThreadTypes.Value | Sort-Object ) -join ", " } }, DefaultThreadType, LatestPostDate, Enabled, ThreadCount, ReplyCount
                    }
                    else {
                        $ForumResponse.Forum
                    }
                }
            }
        }
    }
    
    END {
        
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
        [date]$StickyDate = ( Get-VtDate ).AddDays(7),

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
        $VtAuthHeader = $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -Verbose:$false -WhatIf:$false
        $HttpMethod = "Post"
    }
    
    PROCESS {
        <#
        HTTP Method: POST
        Auth Header: PUT
        Uri = api.ashx/v2/forums/{forumid}/threads/{threadid}.json
        #>

        if ( $pscmdlet.ShouldProcess("$VtCommunity", "Update Thread $ThreadId in Forum $ForumId'") ) {
            $Uri = "api.ashx/v2/forums/$ForumId/threads/$ThreadId.json"
            $UpdateResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader -Method $HttpMethod
            if ( $UpdateResponse ) {
                $UpdateResponse
            }
        }
    }
    
    END {
        # Nothing to see here
    }
}


<#
.Synopsis
    Get a user (or more information) from a Telligent Community
.DESCRIPTION
    Query the REST endpoint to get user account information.
.EXAMPLE
    Get-VtUser -Username "JoeSmith" -Community "https://mycommunity.teligenthosted.net/" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }
    PS > Get-VtUser -UserId 112233 -Community "https://mycommunity.teligenthosted.net/" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }
    PS > Get-VtUser -EmailAddress "joseph.smith@company.com" -Community "https://mycommunity.teligenthosted.net/" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }

        Return a single user based on the their username, email address, or id
    
        --- All of the above returns the same output as below ---

    UserId           : 112233
    Username         : JoeSmith
    EmailAddress     : joseph.smith@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    IsIgnored        : True
    CurrentPresence  : Offline
    JoinDate         : 3/14/2020 9:19:44 AM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 475

.EXAMPLE
    $Global:VtCommunity = "https://mycommunity.telligenthosted.net/"
    PS > $Global:VtAuthHeader       = Get-VtAuthHeader -Username "MyAdminAccount" -ApiKey "MyAdminApiKey"
    PS > Get-VtUser -Username "JoeSmith"
    
    UserId           : 112233
    Username         : JoeSmith
    EmailAddress     : joseph.smith@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    IsIgnored        : True
    CurrentPresence  : Offline
    JoinDate         : 3/14/2020 9:19:44 AM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 475

    Make calls against the API with Community Domain and Authentication Header stored as global variables

.EXAMPLE
    Get-VtUser -EmailAddress "joseph.smith@company.com", "mary.jones@company.com", "jesse.storm@corp.com.au" -Community "https://mycommunity.teligenthosted.net/" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }

    UserId           : 112233
    Username         : JoeSmith
    EmailAddress     : joseph.smith@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    IsIgnored        : True
    CurrentPresence  : Offline
    JoinDate         : 3/14/2020 9:19:44 AM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 475

    UserId           : 91478
    Username         : MJones
    EmailAddress     : mary.jones@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    IsIgnored        : True
    CurrentPresence  : Offline
    JoinDate         : 4/11/2020 8:08:11 AM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 600

    UserId           : 94587
    Username         : StormJ
    EmailAddress     : jesse.storm@corp.com.au
    Status           : Approved
    ModerationStatus : Unmoderated
    IsIgnored        : True
    CurrentPresence  : Offline
    JoinDate         : 5/11/2019 11:47:11 PM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 404

    EmailAddress, UserId, or Username can take an array of values to process
.OUTPUTS
    Without the ReturnDetails parameter, the function returns a custom PowerShell object containing the user Id,
    the username, their email address, their account status, their moderation status, their last login, their last visit,
    and their lifetime points.

    With the ReturnDetails parameter, the function returns the entire JSON from the web call for each user.
.NOTES
    Tested with v11 of the Telligent Community platform using the User REST Endpoints
    Source Documentation: https://community.telligent.com/community/11/w/api-documentation/64921/user-rest-endpoints

    Relies on the Telligent and Utilities functions (defined in the 'begin' block )

    TBD: For doing a 'wildcard' search for a user, I really need to use the search endpoint and not the users endpoint.
    I've only just started experimenting with that in some scratch documents.
#>
function Get-VtUser {
    [CmdletBinding(
        DefaultParameterSetName = 'User Id',
        SupportsShouldProcess = $true,     
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64924/list-user-rest-endpoint',
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
            ParameterSetName = 'Username')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,

        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Email Address'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$EmailAddress,

        # User ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'User Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int64[]]$UserId,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
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

    }
    PROCESS {
        switch ( $pscmdlet.ParameterSetName ) {
            'Username' { 
                if ( $Username -is [array] ) {
                    $Uri = "api.ashx/v2/user.json"
                    $UriParameterSet = @()
                    For ( $i = 0 ; $i -lt $Username.Count; $i++ ) {
                        $TempUriSet = $UriParameters.Clone()
                        $TempUriSet["Username"] = $Username[$i]
                        $UriParameterSet += $TempUriSet
                    }
                }
                else {
                    Write-Verbose -Message "Get-VtUser: Using the username [$Username] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = "Username: $Username"
                    $UriParameters["Username"] = $Username
                }
            }
            'Email Address' {
                if ( $EmailAddress -is [array] ) {
                    $Uri = "api.ashx/v2/user.json"
                    $UriParameterSet = @()
                    For ( $i = 0 ; $i -lt $EmailAddress.Count; $i++ ) {
                        $TempUriSet = $UriParameters.Clone()
                        $TempUriSet["EmailAddress"] = $EmailAddress[$i]
                        $UriParameterSet += $TempUriSet
                    }
                }
                else {
                    Write-Verbose -Message "Get-VtUser: Using the Email Address [$EmailAddress] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = "Email Address: $EmailAddress"
                    $UriParameters["EmailAddress"] = $EmailAddress
                }
            }
            'User Id' {
                if ( $UserId -is [array] ) {
                    $Uri = "api.ashx/v2/user.json"
                    $UriParameterSet = @()
                    For ( $i = 0 ; $i -lt $UserId.Count; $i++ ) {
                        $TempUriSet = $UriParameters.Clone()
                        $TempUriSet["Id"] = $UserId[$i]
                        $UriParameterSet += $TempUriSet
                    }
                }
                else {
                    Write-Verbose -Message "Get-VtUser: Using the UserId [$UserId] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = "UserId: $UserId"
                    $UriParameters["Id"] = $UserId
                }
                
            }

        }
        if ( $UriParameterSet ) {
            # Cycle through things
            ForEach ( $ParameterSet in $UriParameterSet ) {
                try {
                    if ( $pscmdlet.ShouldProcess("Lookup User", $VtCommunity ) ) {
                        $UserResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $ParameterSet | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                        if ( $UserResponse -and $ReturnDetails ) {
                            # We found a matching user, return everything with no pretty formatting
                            $UserResponse.User
                        }
                        elseif ( $UserResponse ) {
                            #implies '-not $ReturnDetails'
                            # Return abbreviated data
                            # We found a matching user, build a custom PowerShell Object for it
                            [PSCustomObject]@{
                                #[VtUser]@{
                                UserId           = $UserResponse.User.id
                                Username         = $UserResponse.User.Username
                                EmailAddress     = $UserResponse.User.PrivateEmail
                                Status           = $UserResponse.User.AccountStatus
                                ModerationStatus = $UserResponse.User.ModerationLevel
                                IsIgnored        = $UserResponse.User.IsIgnored -eq "true"
                                CurrentPresence  = $UserResponse.User.Presence
                                JoinDate         = $UserResponse.User.JoinDate
                                LastLogin        = $UserResponse.User.LastLoginDate
                                LastVisit        = $UserResponse.User.LastVisitedDate
                                LifetimePoints   = $UserResponse.User.Points
                                EmailEnabled     = $UserResponse.User.ReceiveEmails -eq "true"
                                # Need to strip out the dashes from the GUIDs
                                MentionText      = "[mention:$( $UserResponse.User.ContentId.Replace('-', '') ):$( $UserResponse.User.ContentTypeId.Replace('-', '') )]"
                            }
                        }
                    }
                    else {
                        Write-Warning -Message "No results returned for users matching [$LookupKey]"
                    }
                }
                catch {
                    Write-Warning -Message "No results returned for users matching [$LookupKey]"
                }
            }
        }
        else {
            $UserResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
            if ( $UserResponse -and $ReturnDetails ) {
                # We found a matching user, return everything with no pretty formatting
                $UserResponse.User
            }
            elseif ( $UserResponse ) {
                #implies '-not $ReturnDetails'
                # Return abbreviated data
                # We found a matching user, build a custom PowerShell Object for it
                [PSCustomObject]@{
                    UserId           = $UserResponse.User.id
                    Username         = $UserResponse.User.Username
                    EmailAddress     = $UserResponse.User.PrivateEmail
                    Status           = $UserResponse.User.AccountStatus
                    ModerationStatus = $UserResponse.User.ModerationLevel
                    IsIgnored        = $UserResponse.User.IsIgnored
                    CurrentPresence  = $UserResponse.User.Presence
                    JoinDate         = $UserResponse.User.JoinDate
                    LastLogin        = $UserResponse.User.LastLoginDate
                    LastVisit        = $UserResponse.User.LastVisitedDate
                    LifetimePoints   = $UserResponse.User.Points
                    EmailEnabled     = $UserResponse.User.ReceiveEmails
                    MentionText      = "[mention:$( $UserResponse.User.ContentId ):$( $UserResponse.User.ContentTypeId )]"
                }
            }
            else {
                Write-Warning -Message "No results returned for users matching [$LookupKey]"
            }
        }
    }
    END {
        # Nothing to see here
    }
}

<#
.Synopsis
    Delete an account (completely) from a Verint/Telligent community
.DESCRIPTION
    Delete an account (completely) from a Verint/Telligent community.  Optionally, delete all the user's content or assign to another user/userid
.EXAMPLE
    Get-VtUser -EmailAddress "myAccountEmail@company.corp" -Community $VtCommunity -AuthHeader $VtAuthHeader | Remove-VtVtUser -Community $VtCommunity -AuthHeader $VtAuthHeader
    Find and then remove the account with email "myAccountEmail@company.corp" and will request confirmation for each deletion
.EXAMPLE
    Remove-VtVtUser -UserId 11332, 5362, 420 -Community $VtCommunity -AuthHeader $VtAuthHeader -Confirm:$false
    Remove users with id 113322, 5362, or 420 without confirmation
.INPUTS
    Either integters of the user id or a user object like those returned by Get-VtUser
.NOTES
    General notes
#>
function Remove-VtVtUser {
    [CmdletBinding(
        DefaultParameterSetName = 'User Id', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64923/delete-user-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
    
        # Delete account by User Id
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'User Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64[]]$UserId,

        # Delete account by Username
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Username'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,

        # Delete account by email address
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Email Address'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$EmailAddress,

        # Delete all content from the user? (Do not reassign to the 'Former Member' account)
        [Parameter(
            Mandatory = $false
        )]
        [switch]$DeleteAllContent = $false,

        # If not deleting content, reassign to this username (If nothing is provided, then the 'Former Member' account will be used)
        [Parameter(
            Mandatory = $false
        )]
        [string]$ReassignedUsername,

        # If not deleting content, reassign to this user id (If nothing is provided, then the 'Former Member' account will be used)
        [Parameter(
            Mandatory = $false
        )]
        [int]$ReassignedUserId,

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
        
        # Build up the URI parameter set 
        $UriParameters = @{}
        if ( $DeleteAllContent ) {
            $UriParameters.Add("DeleteAllContent", "true")
        }
        else {
            $UriParameters.Add("DeleteAllContent", "false")
        }
        if ( $ReassignedUserId -and $ReassignedUsername ) {
            Write-Error -Message "Cannot specify a reassigned username *and* reassigned user id." -RecommendedAction "Select one or the other"
            break
        }
        if ( $ReassignedUserId ) {
            $UriParameters.Add("ReassignedUserId", $ReassignedUserId)
        }
        if ( $ReassignedUsername ) {
            $UserId = Get-VtUser -Username $ReassignedUsername -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false | Select-Object -ExpandProperty UserId
            if ( $UserId ) {
                $UriParameters.Add("ReassignedUserId", $UserId)
            }
            else {
                Write-Error -Message "Unable to find a user Id for '$ReassignedUsername'"
                break
            }
        }

        # Rest-Method to use for the change
        $RestMethod = "Delete"
    }

    PROCESS {

        switch ( $pscmdlet.ParameterSetName ) {
            'User Id' {
                Write-Verbose -Message "Processing account deletion using User Ids"
                $User = Get-VtUser -UserId $UserId -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false
            }
            'Username' { 
                Write-Verbose -Message "Processing account deletion using Usernames"
                $User = Get-VtUser -Username $Username -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false 
            }

            'Email Address' { 
                Write-Verbose -Message "Processing account deletion using Email Addresses - must perform lookup first"
                $User = Get-VtUser -EmailAddress $EmailAddress -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false
            }
        }
        if ( $pscmdlet.ShouldProcess("$VtCommunity", "Delete User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>") ) {
            $Uri = "api.ashx/v2/users/$( $User.UserId ).json"
            $DeleteResponse = Invoke-RestMethod -Method POST -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -WarningAction SilentlyContinue )
            Write-Verbose -Message "User Deleted: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>"
            if ( $DeleteResponse ) {
                Write-Host "Account: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )> - $( $DeleteResponse.Info )" -ForegroundColor Red
            }
        }
    }
    END {
        # Nothing to see here
    }
}

<#
.Synopsis
    Changes setting for a Verint/Telligent user account on your community
.DESCRIPTION
    Change settings (Username, Email Address, Account Status, Moderation Status, is email enabled?) for a Verint/Telligent user account
.EXAMPLE
    $VtCommunity = 'https://community.domain.local/'
    PS > $VtAuthHeader      = @{ 'Test-User-Token' = 'bG1[REDACTED]tYQ==' }
    PS > Set-VtUser -UserId 112233 -NewUsername 'MyNewUsername' -Community $VtCommunity -AuthHeader $VtAuthHeader
    
    Set a new username for an account
.EXAMPLE
    $VtCommunity = 'https://community.domain.local/'
    PS > $VtAuthHeader      = @{ 'Test-User-Token' = 'bG1[REDACTED]tYQ==' }

    PS > $UserToUpdate = Get-VtUser -Username 'CurrentlyBannedUser' -Community $VtCommunity -AuthHeader $VtAuthHeader
    -- Ban the user --
    PS > $UserToUpdate | Set-VtUser -AccountStatus Banned -Community $VtCommunity -AuthHeader $VtAuthHeader
    -- 'Un'-Ban the user --
    PS > $UserToUpdate | Set-VtUser -AccountStatus Approved -ModerationLevel Unmoderated -EmailBlocked:$false -Community $VtCommunity -AuthHeader $VtAuthHeader -PassThru

        UserId           : 181222
        Username         : CurrentlyBannedUser
        EmailAddress     : banned@New-Vtemail.com
        Status           : Approved
        ModerationStatus : Unmoderated
        IsIgnored        : True
        CurrentPresence  : Offline
        JoinDate         : 11/1/2016 12:23:01 PM
        LastLogin        : 2/22/2021 2:38:29 PM
        LastVisit        : 2/22/2021 2:58:57 PM
        LifetimePoints   : 2954
        EmailEnabled     : True
.INPUTS
    Accepts either a user id (because that is unique) or a User Object (as is returned from Get-VtUser)
.OUTPUTS
    No outputs unless using -PassThru which returns a PowerShell Custom Object with the user account details after updating
.NOTES
    I haven't been able to test every single feature, but the logic should hold
#>
function Set-VtUser {
    [CmdletBinding(DefaultParameterSetName = 'User Id', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64926/update-user-rest-endpoint',
        ConfirmImpact = 'High')]
    Param
    (

        # The user id on which to operate.  Because this operation can change the username and email address, neither should be considered authorotative
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64[]]$UserId,

        # New Username for the Account
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$NewUsername,

        # Updated email address for the account
        [Parameter(Mandatory = $false)]
        [ValidatePattern("(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|`"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*`")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])")]
        # Regex for email:
        # (?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])
        [string]$NewEmailAddress,

        # New status for the account: ApprovalPending, Approved, Banned, or Disapproved
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet('ApprovalPending', 'Approved', 'Banned', 'Disapproved')]
        [string]$AccountStatus,

        # if the account status is updated to 'Banned', when are they allowed back - defaults to 1 year from now
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [datetime]$BannedUntil = ( Get-VtDate ).AddYears(1),

        # the reason the user was banned
        [Parameter(Mandatory = $false)]
        [ValidateSet('Profanity', 'Advertising', 'Spam', 'Aggressive', 'BadUsername', 'BadSignature', 'BanDodging', 'Other')]
        [string]$BanReason = 'Other',

        # New Moderation Level for the account: Unmoderated, Moderated
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet('Unmoderated', 'Moderated')]
        [string]$ModerationLevel,

        # Is the account blocked from receiving email?
        [Parameter(Mandatory = $false)]
        [switch]$EmailBlocked = $false,
        
        # Does the user need to accept the terms of service?
        [Parameter(Mandatory = $false)]
        [switch]$RequiresTermsOfServiceAcceptance,

        # Do we want to ignore the user's content?
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreUser,

        # Do you want to return the new user object back to the original call?
        [Parameter(Mandatory = $false)]
        [switch]$PassThru = $false,

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

        # Rest-Method to use for the change
        $RestMethod = "Put"


        # Parameters to pass to the URI
        $UriParameters = @{}

        if ( $AccountStatus ) {
            $UriParameters.Add("AccountStatus", $AccountStatus )
        }
        if ( $ModerationLevel ) {
            $UriParameters.Add("ModerationLevel", $ModerationLevel )
        }
        if ( $RequiresTermsOfServiceAcceptance ) {
            $UriParameters.Add("AcceptTermsOfService", ( -not $RequiresTermsOfServiceAcceptance ).ToString() )
        }
        if ( $EmailBlocked ) {
            $UriParameters.Add("ReceiveEmails", 'false')
        }
        else {
            $UriParameters.Add("ReceiveEmails", 'true')
        }
        if ( $IgnoreUser ) {
            $UriParameters.Add("IsIgnored", 'true')
        }

        # Add Banned Until date (and other things) only if the status is been defined as 'Banned'
        if ( $UriParameters["AccountStatus"] -eq "Banned" ) {
            $UriParameters.Add("BannedUntil", $BannedUntil )
            $UriParameters.Add("BanReason", $BanReason)
            $UriParameters["ModerationLevel"] = 'Moderated'
            $UriParameters["AcceptTermsOfService"] = 'false'
            $UriParameters["ForceLogin"] = 'true'
        }

    }
    PROCESS {
        
        if ( $NewUsername ) {
            # Check to see if the username already exists in the community
            $CheckUser = Get-VtUser -Username $NewUsername -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if ( -not ( $CheckUser ) ) {
                $UriParameters.Add("Username", $NewUsername)
            }
            # check to see if this username matches the current operating user
            elseif ( -not ( Compare-Object -ReferenceObject $PsItem -DifferenceObject $CheckUser ) ) {
                Write-Error -Message "The current user is already using this username."
            }
            else {
                Write-Error -Message "Another user with the username '$NewUsername' was detected.  Cannot complete." -RecommendedAction "Please choose another username or delete the conflicing user"
                break
            }
        }
        if ( $NewEmailAddress ) {
            # Check to see if the email address already exists in the community
            $CheckUser = Get-VtUser -EmailAddress $NewEmailAddress -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue
            if ( -not ( $CheckUser ) ) {
                $UriParameters.Add("PrivateEmail", $NewEmailAddress)
            }
            # check to see if this email matches the current operating user
            elseif ( -not ( Compare-Object -ReferenceObject $PsItem -DifferenceObject $CheckUser ) ) {
                Write-Warning -Message "The current user is already using this email address."
            }
            else {
                Write-Error -Message "Another user with the email address '$NewEmailAddress' was detected.  Cannot complete." -RecommendedAction "Please choose another email address or delete the conflicing user"
                break
            }
        }
        
        ForEach ( $U in $UserId ) {
            $User = Get-VtUser -UserId $U -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -Verbose:$false | Select-Object -ExcludeProperty MentionText
            if ( $UriParameters.Keys.Count ) {
                if ( $User ) {
                    $Uri = "api.ashx/v2/users/$( $User.UserId ).json"
                    # Imples that we found a user on which to operate
                    if ( $pscmdlet.ShouldProcess($VtCommunity, "Update User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>") ) {
                        # Execute the Update
                        Write-Verbose -Message "Updating User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>"
                        $UpdateResponse = Invoke-RestMethod -Method Post -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod ) -Verbose:$false
                        if ( $UpdateResponse ) {
                            $UserObject = [PSCustomObject]@{
                                UserId           = $UpdateResponse.User.id
                                Username         = $UpdateResponse.User.Username
                                EmailAddress     = $UpdateResponse.User.PrivateEmail
                                Status           = $UpdateResponse.User.AccountStatus
                                ModerationStatus = $UpdateResponse.User.ModerationLevel
                                IsIgnored        = $UpdateResponse.User.IsIgnored -eq "true"
                                CurrentPresence  = $UpdateResponse.User.Presence
                                JoinDate         = $UpdateResponse.User.JoinDate
                                LastLogin        = $UpdateResponse.User.LastLoginDate
                                LastVisit        = $UpdateResponse.User.LastVisitedDate
                                LifetimePoints   = $UpdateResponse.User.Points
                                EmailEnabled     = $UpdateResponse.User.ReceiveEmails -eq "true"
                            }
                        
                            if ( $User -match $UserObject ) {
                                Write-Warning -Message "Updates were sent, but no changes were detected on the user account."
                            }

                            if ( $PassThru ) {
                                $UserObject
                            }
                        }
                    }
                
                }
                else {
                    Write-Warning -Message "No user found."
                }
            }
            else {
                Write-Error -Message "No changes were requested for user with ID: $( $User.UserId )" -RecommendedAction "Include a parameter to make updates"
            }
        }
    }

    END {
        # Nothing here
    }
}
#endregion Points Functions

#region HTML Utility Functions
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

<#
.Synopsis
    Strips HTML Content from a string
.DESCRIPTION
    Removes all tags and decodes any HTML from a string
.OUTPUTS
    string containing only the plain text of the input string
.NOTES
    This is included here just to have a reference for it.  It'll typically be defined 'internally' within the `begin` blocks of functions
#>
function ConvertFrom-HtmlString {
    [CmdletBinding()]
    param (
        # string with HTML content
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$HtmlString
    )
    
    BEGIN {
        
    }
    
    PROCESS {
        [System.Web.HttpUtility]::HtmlDecode( ( $HtmlString -replace "<[^>]*?>|<[^>]*>", "" ) )
    }
    
    END {
        
    }
}
#endregion HTML Utility Functions