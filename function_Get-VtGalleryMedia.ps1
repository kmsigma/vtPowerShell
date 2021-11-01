function Get-VtGalleryMedia {
    <#
    .Synopsis
        List the media in a media gallery
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
        Online REST API Documentation: https://community.telligent.com/community/11/w/api-documentation/64766/list-media-rest-endpoint
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'All Galleries with Connection File',    
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64763/media-rest-endpoints',
        ConfirmImpact = 'Low'
    )]
    Param
    (

        # Gallery Id and File Id for Media Lookup
        [Parameter(
            ParameterSetName = 'Gallery Id and File Id with Authentication Header',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and File Id with Connection Profile',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and File Id with Connection File',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Alias("Id")]
        [int64[]]$FileId,
    
        # Gallery Id for Media Lookup
        [Parameter(
            ParameterSetName = 'All Galleries with Connection File',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id with Connection Profile',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id with Connection File',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and File Id with Authentication Header',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and File Id with Connection Profile',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and File Id with Connection File',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and Group Id with Authentication Header',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and Group Id with Connection Profile',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and Group Id with Connection File',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            Position = 0
        )]

        [int64[]]$GalleryId,
    
        # Group Id for Media Lookup
        [Parameter(
            ParameterSetName = 'Group Id with Authentication Header',
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [Parameter(
            ParameterSetName = 'Group Id with Connection Profile',
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [Parameter(
            ParameterSetName = 'Group Id with Connection File',
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and Group Id with Authentication Header',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and Group Id with Connection Profile',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and Group Id with Connection File',
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [int64[]]$GroupId,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id and File Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id and Group Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Galleries with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,

        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id and File Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id and Group Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Galleries with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,

        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id and File Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id and Group Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Galleries with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,

        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Gallery Id and File Id with Connection File')]
        [Parameter(ParameterSetName = 'Gallery Id and Group Id with Connection File')]
        [Parameter(ParameterSetName = 'Group Id with Connection File')]
        [Parameter(ParameterSetName = 'Gallery Id with Connection File')]
        [Parameter(ParameterSetName = 'All Galleries with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),

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
        [switch]$ReturnFileInfo,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$HideProgress
    
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
    
        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize
    
        $PropertiesToReturn = @(
            @{ Name = "FileId"; Expression = { $_.Id } }
            @{ Name = "GalleryId"; Expression = { $_.MediaGalleryId } }
            'GroupId'
            @{ Name = "Author"; Expression = { $_.Author.Username } }
            'Date'
            @{ Name = "Title"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Title ) } }
            @{ Name = "Tags"; Expression = { ( $_.Tags | ForEach-Object { [System.Web.HttpUtility]::HtmlDecode( $_.Value ) } ) } }
            'Url'
            'CommentCount'
            'Views'
            'Downloads'
            'RatingCount'
            'RatingSum'
        )
        
        if ( $ReturnFileInfo ) {
            $PropertiesToReturn += @{ Name = "FileName"; Expression = { $_.File.FileName } }
            $PropertiesToReturn += @{ Name = "FileType"; Expression = { $_.File.ContentType } }
            $PropertiesToReturn += @{ Name = "FileSize"; Expression = { $_.File.FileSize } }
            $PropertiesToReturn += @{ Name = "FileUrl"; Expression = { $_.File.FileUrl } }
        }
        if ( $IncludeDescription ) {
            @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }
        }

    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess( $Community, "Query Media Gallery Files" ) ) {
            
            if ( $GalleryID -and $FileId ) {
                $Uri = "api.ashx/v2/media/$GalleryId/files/$FileId.json"
                $DoSingleCall = $true
            }
            elseif ( $GalleryId -and $GroupId ) {
                $Uri = "api.ashx/v2/media/$GalleryId/files.json"
                if ( $GroupId ) {
                    $UriParameters["GroupId"] = $GroupId 
                }
            }
            elseif ( $GalleryId -and -not $GroupId ) {
                $Uri = "api.ashx/v2/media/$GalleryId/files.json"
            }
            elseif ( -not $GalleryId -and $GroupId ) {
                $Uri = "api.ashx/v2/groups/$GroupId/media/files.json"
            }
            else { $Uri = 'api.ashx/v2/media/files.json' }

            
            if ( -not $DoSingleCall ) {
                $TotalReturned = 0
                do {
                    if ( $TotalReturned -and -not $HideProgress ) {
                        Write-Progress -Activity "Querying for Media Gallery Items" -Status "Retrieved $TotalReturned of $( $MediaResponse.TotalCount ) items" -CurrentOperation "Making call #$( $UriParameters["PageIndex"] + 1 )" -PercentComplete ( 100 * ( $TotalReturned / $MediaResponse.TotalCount ) )
                    }
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $MediaResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $MediaResponse ) {
                        $TotalReturned += $MediaResponse.MediaPosts.Count
                        if ( $ReturnDetails ) {
                            $MediaResponse.MediaPosts
                        }
                        else {
                            $MediaResponse.MediaPosts | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ( $TotalReturned -lt $MediaResponse.TotalCount )
                if ( -not $HideProgress ) {
                    Write-Progress -Activity "Querying for Media Gallery Items" -Completed
                }
            } else {
                $MediaResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders
                if ( $MediaResponse ) {
                    $TotalReturned += $MediaResponse.Media.Count
                    if ( $ReturnDetails ) {
                        $MediaResponse.Media
                    }
                    else {
                        $MediaResponse.Media | Select-Object -Property $PropertiesToReturn
                    }
                }
                else {
                    Write-Error -Message "Unable to find media for $GalleryId and $FileId"
                }
            }
            
        } #end of 'should process'
    }
    END {
        # Nothing to see here
    }
}