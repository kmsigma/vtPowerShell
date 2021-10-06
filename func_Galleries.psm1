<#
Resources:
Galleries
https://community.telligent.com/community/11/w/api-documentation/64678/gallery-rest-endpoints

Media
https://community.telligent.com/community/11/w/api-documentation/64763/media-rest-endpoints

#>

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

    begin {

        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        if ( -not ( Get-Command -Name ConvertTo-QueryString -ErrorAction SilentlyContinue ) ) {
            . .\func_Utilities.ps1
        }

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $VtAuthHeader = $VtAuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

    }
    process {
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
    end {
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

    begin {
        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        if ( -not ( Get-Command -Name ConvertTo-QueryString -ErrorAction SilentlyContinue ) ) {
            . .\func_Utilities.ps1
        }
        
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
    process {

        $CurrentName = Get-VtGallery -GalleryId $GalleryId -VtCommunity $VtCommunity -VtAuthHeader $VtAuthHeader -ErrorAction SilentlyContinue -WhatIf:$false | Select-Object -Property @{ Name = "Gallery"; Expression = { "'$( $_.Name )' in '$( $_.GroupName )'" } } | Select-Object -ExpandProperty Gallery
        if ( $PSCmdlet.ShouldProcess( $VtCommunity, "Update Gallery '$CurrentName'" ) ) {
            $Response = Invoke-RestMethod -Method Post -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -ErrorAction SilentlyContinue -WhatIf:$false )
            if ( $Response ) {
                $Response.Gallery | Select-Object -Property @{ Name = "GalleryId"; Expression = { $_.Id } }, Name, Key, @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }, Url, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Owners"; Expression = { ( $_.Owners | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
            }
        }
    }
    end {
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

    begin {

        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        if ( -not ( Get-Command -Name ConvertTo-QueryString -ErrorAction SilentlyContinue ) ) {
            . .\func_Utilities.ps1
        }

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $VtAuthHeader = $VtAuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

        # Setup the other parameters
        if ( $AuthorName ) {
            # We need author ID's, so we'll look up this author and store the ID
            $AuthorId = Get-VtUser -Username $AuthorName -VtCommunity $VtCommunity -VtAuthHeader $AuthorId -Verbose:$false | Select-Object -ExpandProperty Id
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
    process {
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
    end {
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

    begin {

        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        if ( -not ( Get-Command -Name ConvertTo-QueryString -ErrorAction SilentlyContinue ) ) {
            . .\func_Utilities.ps1
        }

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

    process {
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
    end {
        # Nothing to see here
    }
}