function Get-VtWiki {
    <#
    .Synopsis
        Get Wiki from a Verint Community
    .DESCRIPTION
        Get a single or multiple Wikis from a Verint Community
    .EXAMPLE
        Get-VtWiki -WikiId 6
    
        WikiId       : 6
        Name         : Generic Wiki
        Key          : generic-Wiki
        Url          : https://mycommunity.com/company-Wikis/b/generic-Wiki
        Enabled      : True
        PostCount    : 134
        CommentCount : 281
        GroupName    : Company Wikis
        GroupId      : 11
        GroupType    : Joinless
        Authors      : {displayName1, displayName3, displayName42, displ…}
    .EXAMPLE
        Get-VtWiki -WikiId 6 -ReturnDetails
    
        Similar to above example, except all the data is returned and it not presented in 'clean' way
    .EXAMPLE
        Get-VtWiki | Where-Object { $_.Authors -contains 'displayName1' }
    
        Returns an array of all Wikis where 'displayName1' is listed as an author of the Wiki
    .EXAMPLE
        $Wikis = Get-VtWiki | Where-Object { $_.Authors }
        PS > $Wikis.Authors | Select-Object -Unique | Get-VtUser
    
        Retrieves a list of Wikis where authors are defined, then gets the information on said author based on their Username
    
        .OUTPUTS
    
        .NOTES
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Wiki By Id with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64538/list-Wiki-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Wiki Id for Lookup
        [Parameter(Mandatory = $false, ParameterSetName = 'Wiki By Name with Authentication Header')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Wiki By Id with Connection Profile')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Wiki By Id with Connection File')]
        [Alias("Id")] 
        [int64]$WikiId,
    
        # Group Id for Lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [int64]$GroupId,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Wiki By Name with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Wiki By Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Wiki By Name with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Wiki By Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Wiki By Name with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Wiki By Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Wiki By Name Connection File')]
        [Parameter(ParameterSetName = 'Wiki By Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),
    
        # Should we return all details?
        [Parameter()]
        [switch]$ReturnDetails,
    
        # Number of entries to get per batch (default of 20)
        [Parameter()]
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

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeaders = $AuthHeaders | Update-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false
    
        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

        $PropertiesToReturn = @(
            @{ Name = "WikiId"; Expression = { $_.Id } }
            'Name'
            @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }
            'Key'
            'Url'
            'Enabled'
            'PostCount'
            'CommentCount'
            @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }
            @{ Name = "GroupId"; Expression = { $_.Group.Id } }
            @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }
            'DefaultPostImageUrl'
            @{ Name = "Authors"; Expression = { ( $_.Authors | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
        )
    
    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess( $VtCommunity, "Query Wikis on" ) ) {
            
            if ( $WikiId -and -not $GroupId) {
                # If we have a WikiId and NOT a GroupId, return the single Wiki
                $Uri = "api.ashx/v2/wikis/$WikiId.json"
                $Type = 'Single'
            }
            elseif ( $WikiId -and $GroupId ) {
                # If we have a WikiId and a GroupId, return the single Wiki within that group
                $Uri = "api.ashx/v2/groups/$GroupId/wikis/$WikiId.json"
                $Type = 'Single'
            }
            elseif ( -not $WikiId -and $GroupId ) {
                # If we do NOT have a WikiId but we have a GroupId, return all Wikis within that group
                $Uri = "api.ashx/v2/groups/$GroupId/wikis.json"
                $Type = 'Multiple'
            }
            else {
                # If we have neither a WikiId nor a GroupId, list all the Wikis
                $Uri = "api.ashx/v2/wikis.json"
                $Type = 'Multiple'
            }
            
            if ( $Type -eq 'Single' ) {
                $WikisResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders
                if ( $WikisResponse ) {
                    if ( $ReturnDetails ) {
                        $WikisResponse.Wiki
                    }
                    else {
                        $WikisResponse.Wiki | Select-Object -Property $PropertiesToReturn
                    }
                }
                else {
                    Write-Error -Message "No Wikis matching ID $WikiId found."
                }
            }
            else {
                # Multiple returns
                
                $TotalReturned = 0
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $WikisResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $WikisResponse ) {
                        $TotalReturned += $WikisResponse.Wikis.Count
                        if ( $ReturnDetails ) {
                            $WikisResponse.Wikis
                        }
                        else {
                            $WikisResponse.Wikis | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $WikisResponse.TotalCount)
            }
            
        } #end of 'should process'
    }
    END {
        # Nothing to see here
    }
}