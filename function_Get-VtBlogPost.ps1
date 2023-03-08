function Get-VtBlogPost {
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
    [CmdletBinding(DefaultParameterSetName = 'All Blogs Posts with Connection File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64540/update-blog-rest-endpoint',
        ConfirmImpact = 'Low')]
    Param
    (

        # Blog Id for Lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'All Blogs Posts with Connection File'
        )]
        [ValidateRange("Positive")]
        [int64[]]$BlogId,

        # Filter to a specific group
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'All Blogs Posts with Connection File'
        )]
        [ValidateRange("Positive")]
        [int64]$GroupId,

        # Do we want to include the Body of posts?
        [Parameter()]
        [switch]$IncludeBody,

        # Do we want to include the OpenGraph and Meta Information?
        [Parameter()]
        [switch]$IncludeMetaInfo,

        # Do we want to include unpublished posts?
        [Parameter()]
        [switch]$IncludeUnpublished,

        # Sort Field
        [Parameter()]
        [ValidateSet('MostComments', 'MostRecent', 'MostViewed', 'Score:SCORE_ID', 'ContentIdsOrder')]
        [string]$SortBy = 'MostRecent',

        # Sort Order
        [Parameter()]
        [switch]$Ascending,

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
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog Post Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Blogs Posts with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,

        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog Post Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Blogs Posts with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,

        [Parameter(Mandatory = $true, ParameterSetName = 'Blog Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Blogs Posts with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,

        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Blog Id with Connection File')]
        [Parameter(ParameterSetName = 'All Blogs Posts with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )
        
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

<# TDB
        if ( $IncludeGroup ) {
            $UriParameters["IncludeUnpublished"] = 'true'
            # If we also want unpublished, then we'll add that field to the property list to return
            $PropertyList += @{ Name = "GroupId"; Expression = { } }
            $PropertyList += @{ Name = "GroupName"; Expression = { } }

        }
#>
        if ( $IncludeMetaInfo ) {
            # if we want the meta info, then we'll add those fields to the property list to return
            $PropertyList += "OpenGraphTitle",
            "OpenGraphDescription",
            "OpenGraphImage",
            "MetaKeywords",
            "MetaDescription",
            "MetaTitle"
        }

        if ( $Ascending ) {
            $UriParameters["SortOrder"] = 'Ascending'
        }
        else {
            $UriParameters["SortOrder"] = 'Descending'
        }

    }

    PROCESS {
        if ( $BlogId -and -not $BlogPostId ) {
            
            ForEach ( $B in $BlogId ) {
                # Add confirmation here

                $Uri = "api.ashx/v2/blogs/$B/posts.json"

                $BlogTitle = Get-VtBlog -BlogId $B | Select-Object -Property @{ Name = "Title"; Expression = { "'$( $_.Name )' in '$($_.GroupName )'" } } | Select-Object -ExpandProperty Title

                $TotalReturned = 0
                $UriParameters["PageIndex"] = 0
                Remove-Variable -Name BlogPostsResponse -ErrorAction SilentlyContinue
                do {
                    if ( $BlogPostsResponse ) {
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records [$TotalReturned / $( $BlogPostsResponse.TotalCount )]"
                        Write-Progress -Activity "Retrieving Posts from $BlogTitle" -PercentComplete ( $TotalReturned / $BlogPostsResponse.TotalCount * 100 ) -CurrentOperation "Retrieving Blog Posts [$TotalReturned posts / $( $BlogPostsResponse.TotalCount ) total posts]"
                    }
                    $BlogPostsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -ErrorAction SilentlyContinue
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
        
            if ( $PSCmdlet.ShouldProcess("Target", "Operation") ) {
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
                        $BlogPostsResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders 
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
            Remove-Variable -Name BlogPostsResponse -ErrorAction SilentlyContinue
            do {
                if ( $BlogPostsResponse ) {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records [$TotalReturned / $( $BlogPostsResponse.TotalCount )]"
                    Write-Progress -Activity "Retrieving All Posts" -PercentComplete ( $TotalReturned / $BlogPostsResponse.TotalCount * 100 ) -CurrentOperation "Retrieving Blog Posts [$TotalReturned posts / $( $BlogPostsResponse.TotalCount ) total posts]"
                }
                $BlogPostsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -ErrorAction SilentlyContinue
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