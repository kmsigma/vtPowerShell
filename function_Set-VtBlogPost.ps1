function Set-VtBlogPost {
    <#
    .Synopsis
        Update a Verint Blog Post
    .DESCRIPTION
        TBD
    .EXAMPLE
        TBD
    .EXAMPLE
        TBD
    .EXAMPLE
        TBD
    .EXAMPLE
        TBD
    .INPUTS
        TBD
    .OUTPUTS
        TBD
    .NOTES
        TBD
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: https://community.telligent.com/community/12/w/api-documentation/71161/update-blog-post-rest-endpoint
    #>
    [CmdletBinding(DefaultParameterSetName = 'Blog Post By Blog and Post Id with Connection File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/12/w/api-documentation/71161/update-blog-post-rest-endpoint',
        ConfirmImpact = 'High')]
    Param
    (
        # Source Blog ID for Post
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Blog Post By Blog and Post Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Blog Post By Blog and Post Id with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Blog Post By Blog and Post Id with Connection File'
        )]
        [ValidateRange("Positive")]
        [int64]$BlogId,

        # Source Post ID
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Blog Post By Blog and Post Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Blog Post By Blog and Post Id with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Blog Post By Blog and Post Id with Connection File'
        )]
        [ValidateRange("Positive")]
        [int64]$BlogPostId,

        # Update the key/slug used in the URL.  No spaces accepted.  Will automatically be converted to lowercase
        [Parameter(ParameterSetName = 'Blog Post By Blog and Post Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog Post By Blog and Post Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog Post By Blog and Post Id with Connection File')]
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
        [string]$Slug,
    
        # Update the blog post's title
        [ValidateLength(1, 255)]
        [string]$Title,
    
        # Update the blog post's body
        [string]$Body,
   
        # Flag the blog post as Draft - otherwise it's "IsApproved"
        [switch]$IsDraft,

        # Set the author of the blog post by userid
        [int]$AuthorId,

        <#
        # Set the author of the blog post by username
        [string]$Author,
        #>

        # Set the destination blog for the post
        [int]$DestinationBlogId,

        # Set the MetaDescription
        [string]$MetaDescription,
        
        # Set the MetaKeywords
        [string[]]$MetaKeywords,
        
        # Set the MetaKeywords
        [string]$MetaTitle,

        # Set the OpenGraphDescription
        [string]$OpenGraphDescription,
        
        # Set the OpenGraphKeywords
        [string]$OpenGraphTitle,

        # Set the Tags for the Post
        [string[]]$Tags,

        # Update the Post Image Url
        [string]$PostImageUrl,

        # Update the Post Image's Alt Text
        [string]$PostImageAlternateText,
        
        # Update the Published Date
        [datetime]$PublishedDate,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog Post By Blog and Post Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog Post By Blog and Post Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog Post By Blog and Post Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Blog Post By Blog and Post Id with Connection File')]
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
    
        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeaders = $AuthHeaders | Update-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false

        $Data = @{}
        if ( $Slug ) { $Data["Slug"] = $Slug }
        if ( $Title ) { $Data["Title"] = $Title }
        if ( $Body ) { $Data["Body"] = $Body } # Also need to De/Encode HTML (as URL?)
        if ( $IsDraft ) { $UriParmeters["IsApproved"] = $false }
        if ( $AuthorId ) { $Data["AuthorId"] = $AuthorId }
        if ( $DestinationBlogId ) { $Data["BlogId"] = $DestinationBlogId }
        if ( $MetaTitle ) { $Data["MetaTitle"] = $MetaTitle } # Need to strip all HTML and UrlEncode
        if ( $OpenGraphTitle ) { $Data["OpenGraphTitle"] = $OpenGraphTitle } # Need to strip all HTML and UrlEncode
        if ( $MetaDescription ) { $Data["MetaDescription"] = $MetaDesciption } # Need to strip all HTML and UrlEncode
        if ( $OpenGraphDescription ) { $Data["OpenGraphDescription"] = $OpenGraphDesciption } # Need to strip all HTML and UrlEncode
        if ( $MetaKeywords ) { $Data["MetaKeywords"] = $MetaKeywords.split(",") -join "," } # !!! this will need review [got to handle a string or a collection]
        if ( $Tags ) { $Data["Tags"] = $Tags.split(",") -join "," } # !!! this will need review [got to handle a string or a collection]
        if ( $PublishedDate ) { $Data["PublishedDate"] = $PublishedDate }
        if ( $PostImageUrl ) { $Data["PostImageUrl"] = $PostImageUrl }
        if ( $PostImageAlternateText ) { $Data["PostImageAlternateText"] = $PostImageAlternateText }

        $Uri = "api.ashx/v2/blogs/$BlogId/posts/$BlogPostId.json"
        # For the API Calls
        $RestMethod = "Put"; $HttpMethod = "Post"
    }
    PROCESS {
        
        $BlogPost = Get-VtBlogPost -BlogId $BlogId -BlogPostId $BlogPostId -ErrorAction SilentlyContinue -VtCommunity $Community -VtAuthHeader $AuthHeaders
        if ( $BlogPost ) {
            if ( $PSCmdlet.ShouldProcess($Community, "Update Blog Post: '$( $BlogPost.Title )'" ) ) {
                $Response = Invoke-RestMethod -Uri ( $Community + $Uri ) -Body $Data -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod ) -Method $HttpMethod
                if ( $Response ) {
                    $Response.BlogPost
                }
                
            }
        }
    }
    END {
        # Nothing to see here
    }
}


<#
$BlogId = 71
$BlogPostId = 6254
$BlogPost = Get-VtBlogPost -BlogId $BlogId -BlogPostId $BlogPostId -IncludeBody
$TextBody = @"
<p>The evolution of IT, the changing requirements for ensuring availability, the performance of critical applications, and the performance of the underlying infrastructure—no matter where it's running—are all part of the story of the application performance management (APM) story. Still, the transition and need for observability are much more than this.</p>
<p>The shift to observability includes delivering holistic business insights for full-stack infrastructure, applications, and data across on-premises and cloud environments, understanding the customer journey from start to finish, and becoming more proactive—taking action before issues arise.</p>
<p>During this session, we'll take you through the evolution of APM from a market perspective as hybrid and multi-cloud continue to grow. IT organizations are faced with newer technologies, which adds complexity, and modern and distributed applications are running as services across multiple locations. We'll also take you through the evolution of the SolarWinds<sup>&copy;</sup> APM solutions, how they address today's requirements, and a peek into what's next.</p>
"@
$Body = $BlogPost.Body.Replace('<hr /><div style="clear:both;"></div>', $TextBody)
# This isn't working, so I'll have to download and upload the PostImageFileData
$PostImageUrl = 'https://play.vidyard.com/i2bTch4YJ6jjXBAd4bRPn7.jpg'
$PostImageAlternateText = "APM's Evolution to Observability"

Set-VtBlogPost -BlogId $BlogId -BlogPostId $BlogPostId -PostImageUrl $PostImageUrl -PostImageAlternateText $PostImageAlternateText -Body $Body


#>