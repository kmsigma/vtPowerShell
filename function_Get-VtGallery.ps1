function Get-VtGallery {
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
