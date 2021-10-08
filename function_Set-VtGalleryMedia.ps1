function Set-VtGalleryMedia {
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
                $Response = Invoke-RestMethod -Method Post -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -ErrorAction SilentlyContinue -WhatIf:$false )
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