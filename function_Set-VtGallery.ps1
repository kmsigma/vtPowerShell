function Set-VtGallery {
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
                $Response = Invoke-RestMethod -Method Post -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -ErrorAction SilentlyContinue -WhatIf:$false )
                if ( $Response ) {
                    $Response.Gallery | Select-Object -Property @{ Name = "GalleryId"; Expression = { $_.Id } }, Name, Key, @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }, Url, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Owners"; Expression = { ( $_.Owners | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
                }
            }
        }
        END {
            # Nothing to see here
        }
    }