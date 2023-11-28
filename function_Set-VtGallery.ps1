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
        DefaultParameterSetName = 'Update Gallery by Gallery ID with Connection File',
        HelpUri = 'https://community.telligent.com/community/12/w/api-documentation/71302/update-gallery-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        # Gallery ID on which to Operate
        [Parameter(
            Mandatory = $true, 
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
        [int]$GroupId,

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
    
        #region community authorization - put at bottom of paramter block
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]

        [Parameter(Mandatory = $true, ParameterSetName = 'Update Gallery by Gallery ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
    
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Update Gallery by Gallery ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,


        [Parameter(Mandatory = $true, ParameterSetName = 'Update Gallery by Gallery ID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,

        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Update Gallery by Gallery ID with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )
        #endregion community authorization - put at bottom of paramter block
    
    )
    
    BEGIN {
    
        #region retrieve authentication headers
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

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        #$VtAuthHeader = $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -Verbose:$false -WhatIf:$false
            
        # Build URI Parameters
        $UriParameters = @{}
        if ( $Name ) { $UriParameters["Name"] = [System.Web.HttpUtility]::UrlEncode($Name) }
        if ( $Key ) { $UriParameters["Key"] = $Key }
        if ( $GroupId ) { $UriParameters["GroupId"] = $GroupId }
        if ( $Description ) { $UriParameters["Description"] = [System.Web.HttpUtility]::UrlEncode($Description) }
        if ( $Disabled ) { $UriParameters["Enabled"] = $false }
        if ( $Owners ) { $UriParameters["Owners"] = $Owners }
    
        $Uri = "api.ashx/v2/galleries/$GalleryId.json"

        $HttpMethod = "Post"
        $RestMethod = "Put"
    }
    PROCESS {
    
        $CurrentName = Get-VtGallery -GalleryId $GalleryId -VtCommunity $Community -VtAuthHeader $AuthHeaders -ErrorAction SilentlyContinue -WhatIf:$false | Select-Object -Property @{ Name = "Gallery"; Expression = { "'$( $_.Name )' in '$( $_.GroupName )'" } } | Select-Object -ExpandProperty Gallery
        if ( $CurrentName ) {
            if ( $PSCmdlet.ShouldProcess( $Community, "Update Gallery '$CurrentName'" ) ) {
                $Response = Invoke-RestMethod -Method $HttpMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod -ErrorAction SilentlyContinue -WhatIf:$false )
                if ( $Response ) {
                    $Response.Gallery | Select-Object -Property $PropertiesToReturn
                }
            }
        }
    }
    END {
        # Nothing to see here
    }
}