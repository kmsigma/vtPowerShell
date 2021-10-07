function Get-VtGalleryMedia {
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