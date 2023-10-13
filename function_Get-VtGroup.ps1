function Get-VtGroup {
    <#
    .Synopsis
        Get groups from Verint / Telligent communities
    .DESCRIPTION
        Long description
    .EXAMPLE
        Example of how to use this cmdlet
    .EXAMPLE
        Another example of how to use this cmdlet
    .INPUTS
        Inputs to this cmdlet (if any)
    .OUTPUTS
        Output from this cmdlet (if any)
    .NOTES
        https://community.telligent.com/community/11/w/api-documentation/64702/list-group-rest-endpoint
    .COMPONENT
        The component this cmdlet belongs to
    .ROLE
        The role this cmdlet belongs to
    .FUNCTIONALITY
        The functionality that best describes this cmdlet
    .NOTES
        First attempted update for v12 API

    #>
    [CmdletBinding(DefaultParameterSetName = 'All groups with Connection File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/12/w/api-documentation/71308/list-group-rest-endpoint',
        ConfirmImpact = 'Low')]
    [Alias()]
    [OutputType()]
    Param
    (
        # Get group by container id
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Group by Container Id with Authentication Header',
            Position = 0
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Group by Container Id with Connection Profile',
            Position = 0
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Group by Container Id with Connection File',
            Position = 0
        )]
        [Alias("Id")]
        [guid[]]$ContainerId,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory=$true, ParameterSetName = 'All groups with Authentication Header')]
        [Parameter(Mandatory=$true, ParameterSetName = 'Group by Container Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory=$true, ParameterSetName = 'All groups with Authentication Header')]
        [Parameter(Mandatory=$true, ParameterSetName = 'Group by Container Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory=$true, ParameterSetName = 'All groups with Connection Profile')]
        [Parameter(Mandatory=$true, ParameterSetName = 'Group by Container Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'All groups with Connection File')]
        [Parameter(ParameterSetName = 'Group by Container Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),
    
        # Should we return all details?
        [Parameter()]
        [switch]$ReturnDetails,
    
        # Number of entries to get per batch (default of 20)
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
    
        # Get all groups
        [Parameter(ParameterSetName = 'All groups with Authentication Header')]
        [Parameter(ParameterSetName = 'All groups with Connection File')]
        [Parameter(ParameterSetName = 'All groups with Connection Profile')]
        [ValidateSet("Joinless", "PublicOpen", "PublicClosed", "PrivateUnlisted", "PrivateListed", "All")]
        [Alias("Type")]
        [string]$GroupType = "All",
    
        # Should we resolve the Parent Container ID (to use in other elements)
        [Switch]$ResolveParentContainerId,

        # Sort By
        [Parameter()]
        [ValidateSet('Name', 'SortOrder', 'LastUpdate', 'ContentIdsOrder')]
        [string]$SortBy = 'Name',
        
        # Sort Order
        [Parameter()]
        [switch]$Descending

        # Sort Order
        #[Parameter()]
        #[ValidateSet('Ascending', 'Descending')]
        #[string]$SortOrder = 'Ascending'

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
        $VtAuthHeader = $AuthHeaders | Update-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false
        $UriParameters = @{}
        $UriParameters['PageSize'] = $BatchSize
        $UriParameters['PageIndex'] = 0
        $UriParameters['GroupTypes'] = $GroupType

        $UriParameters['SortBy'] = $SortBy
        if ( $Descending ) {
            $UriParameters['SortOrder'] = 'Descending'
        }
        else {
            $UriParameters['SortOrder'] = 'Ascending'
        }

        $PropertiesToReturn = @(
            @{ Name = "GroupId"; Expression = { $_.Id } }
            @{ Name = "ContainerId"; Expression = { $_.ContainerId } }
            @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } }
            "Key"
            @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }
            "DateCreated"
            "Url"
            "GroupType"
            "ParentGroupId"
        )

        if ( $ResolveParentContainerId ) {
            $PropertiesToReturn += @{ Name = 'ParentContainerId'; Expression = { 'ParentContainerIdGoesHere' } }
        }
    }
        
    PROCESS {
        switch -Wildcard ( $PSCmdlet.ParameterSetName ) {
            'Group by Container Id*' {
                ForEach ( $Id in $ContainerId ) {
                    # Setup the URI
                    $Uri = "api.ashx/v2/groups/$Id.json"
                    # Because everything is encoded in the URI, we don't need to send any $UriParameters
                    Write-Verbose -Message "Making call with '$Uri'"
                    if ( $PSCmdlet.ShouldProcess($Community, "Retrieve group with container id: '$id'") ) {
                        $GroupsResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders -Verbose:$false
                        
                        if ( $GroupsResponse.Group ) {
                            if ( $ReturnDetails ) {
                                $GroupsResponse.Group
                            }
                            else {
                                $GroupsResponse.Group | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        else {
                            Write-Warning -Message "No matching groups found for Container ID: $Id"
                        }
                    }
                }
            }
            default {
                # No ForEach loop needed here because we are pulling all groups
                $Uri = 'api.ashx/v2/groups.json'
                $GroupCount = 0
                if ( $PSCmdlet.ShouldProcess($Community, "Retrieve all groups") ) {
                    do {
                        $GroupsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -Verbose:$false
    
                        if ( $GroupsResponse ) {
                            $GroupCount += $GroupsResponse.Groups.Count
                            if ( $ReturnDetails ) {
                                $GroupsResponse.Groups
                            }
                            else {
                                $GroupsResponse.Groups | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        $UriParameters['PageIndex']++
                        Write-Verbose -Message "Incrementing Page Index :: $( $UriParameters['PageIndex'] )"
                    } while ( $GroupCount -lt $GroupsResponse.TotalCount )
                }
            }
        }
    }
        
    END {
        # Nothing to see here
    }
}