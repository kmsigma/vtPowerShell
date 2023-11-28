function Get-VtGallery {
    <#
    .Synopsis
        Lists one or more media galleries on the Verint Community platform
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
        Online REST API Documentation: https://community.telligent.com/community/12/w/api-documentation/71300/list-gallery-rest-endpoint
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'All Galleries with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/12/w/api-documentation/71300/list-gallery-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Gallery Id for Lookup
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
        [Alias("Id")] 
        [int64[]]$GalleryId,
    
        # Group Id for Lookup
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
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and Group Id with Connection Profile',
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [Parameter(
            ParameterSetName = 'Gallery Id and Group Id with Connection File',
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [int64[]]$GroupId,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
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
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id and Group Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Galleries with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,

        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id and Group Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Gallery Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Galleries with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,

        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
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
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20
    
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
            @{ Name = "GalleryId"; Expression = { $_.Id } }
            'Name'
            'Key'
            @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }
            'Url'
            'Enabled'
            'PostCount'
            'CommentCount'
            @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }
            @{ Name = "GroupId"; Expression = { $_.Group.Id } }
            @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }
            @{ Name = "Owners"; Expression = { ( $_.Owners | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
        )
    
    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess( $Community, "Query Galleries on" ) ) {
            $ResultType = 'Single'            
            if ( $GalleryId -and $GroupId ) {
                Write-Verbose -Message "Galleries and Groups detected [$( $GalleryId.Count )] [$( $GroupId.Count)]"
                $Uri = "api.ashx/v2/groups/$GroupId/galleries/$GalleryId.json"
            }
            elseif ( $GalleryId ) {
                Write-Verbose -Message "Galleries detected [$( $GalleryId.Count )]"
                $Uri = "api.ashx/v2/galleries/$GalleryId.json"
            }
            elseif ( $GroupId ) {
                Write-Verbose -Message "Groups detected [$( $GroupId.Count )]"
                $Uri = "api.ashx/v2/groups/$GroupId/galleries.json"
                $ResultType = 'Multiple'
            }
            else {
                Write-Verbose -Message "Neither Galleries nor Groups detected"
                # Neither a gallery id nor a group id provided
                $Uri = "api.ashx/v2/galleries.json"
                $ResultType = 'Multiple'
            }
            
            
            if ( $ResultType -eq 'Single') {
                $GalleriesResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders
                if ( $GalleriesResponse -and $ReturnDetails ) {
                    $GalleriesResponse.Gallery
                }
                elseif ( $GalleriesResponse ) {
                    $GalleriesResponse.Gallery | Select-Object -Property $PropertiesToReturn
                }
                
                else {
                    Write-Error -Message "Unable to find a matching gallery"
                }
            }
            else {
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $GalleriesResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $GalleriesResponse ) {
                        $TotalReturned += $GalleriesResponse.Galleries.Count
                        if ( $ReturnDetails ) {
                            $GalleriesResponse.Galleries
                        }
                        else {
                            $GalleriesResponse.Galleries | Select-Object -Property $PropertiesToReturn
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
