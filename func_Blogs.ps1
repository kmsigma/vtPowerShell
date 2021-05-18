<#
.Synopsis

.DESCRIPTION

.EXAMPLE

.EXAMPLE

.EXAMPLE

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
        if ( -not ( Get-Command -Name ConvertTo-QueryString -ErrorAction SilentlyContinue ) ) {
            . .\func_Utilities.ps1
        }

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeader = $AuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

    }
    process {
        if ( $PSCmdlet.ShouldProcess( $CommunityDomain, "Query Blogs on" ) ) {
        
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
                #single retrn only
            }
            else {
                # Multiple returns
            
                $TotalReturned = 0
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $BlogsResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
                    if ( $BlogsResponse ) {
                        $TotalReturned += $BlogsResponse.Blogs.Count
                        if ( $ReturnDetails ) {
                            $BlogsResponse.Blogs
                        } else {
                            $BlogsResponse.Blogs | Select-Object -Property @{ Name = "BlogId"; Expression = { $_.Id } }, Name, Key, Url, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $BlogsResponse.TotalCount)
            }
        
        } #end of 'should process'
    }
    end {
        # Nothing to see here
    }
}