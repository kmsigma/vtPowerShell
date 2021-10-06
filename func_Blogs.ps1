<#
    New-VtBlog function (may be deferred because it's easier to do on the web)
    Remove-VtBlog function (may be deferred because it's easier to do on the web)
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
PS > Set-VtBlog -BlogId 6 -Authors $Authors -VtCommunity "https://mycommunity.telligenthosting.com/" -VtAuthHeader $VtAuthHeader
PS > $NewAuthors = "displayName4", "displayName5", "displayName6"
PS > Set-VtBlog -BlogId 6 -Authors $Authors -VtCommunity "https://mycommunity.telligenthosting.com/" -VtAuthHeader $VtAuthHeader

This will update the list of authors to be displayName1, 2, and 3 on the blog with ID 6.
Then it will update the list of authors to be displayName4, 5, and 6 on the blog with ID 6.

When completed, only displayName4, 5, and 6 will be listed as authors.
.EXAMPLE
    Set-VtBlog -BlogId 11 -AddAuthors "me", "myself", "I" -VtCommunity "https://mycommunity.telligenthosting.com/" -VtAuthHeader $VtAuthHeader

This will take the existing authors and add the above 3 to the list.
.EXAMPLE
    Set-VtBlog -BlogId 13 -RemoveAuthors "removeMe", "removeHim", "removeHer" -VtCommunity "https://mycommunity.telligenthosting.com/" -VtAuthHeader $VtAuthHeader

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
            $Blog = Get-VtBlog -BlogId $b -VtCommunity $VtCommunity -VtAuthHeader $VtAuthHeader -Verbose:$false -WhatIf:$false

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
                    $WorkingAuthorList = New-Object -TypeName System.Collections.ArrayList
                    $OriginalAuthorList = New-Object -TypeName System.Collections.ArrayList
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
            if ( -not ( Get-Command -Name "Get-VtUser" -ErrorAction SilentlyContinue) ) {
                . .\func_Users.ps1
            }
            $AuthorId = Get-VtUser -Username $Author -VtCommunity $VtCommunity -VtAuthHeader $VtAuthHeader -Confirm:$false -Verbose:$false -WhatIf:$false | Select-Object -ExpandProperty UserId
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

                #region Get the responses based on the parameters
                $TotalReturned = 0
                $UriParameters["PageIndex"] = 0
                Remove-Variable -Name BlogPostsResponse -ErrorAction SilentlyContinue
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
                

                #endregion Get the responses based on the parameters

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

                    #region Get the responses based on the parameters
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
            #region Get the responses based on the parameters
            $TotalReturned = 0
            $UriParameters["PageIndex"] = 0
            Remove-Variable -Name BlogPostsResponse -ErrorAction SilentlyContinue
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
                            
            
            #endregion Get the responses based on the parameters
        }
    }
            


    END {

    }
}