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
    #>
    [CmdletBinding(DefaultParameterSetName = 'All groups with Connection File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64699/group-rest-endpoints',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType()]
    Param
    (
        # Get group by name
        [Parameter(ParameterSetName = 'Group by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Name with Connection Profile')]
        [Parameter(ParameterSetName = 'Group by Name with Connection File')]
        [Alias("Name")]
        [string[]]$GroupName,
    
        # Group name exact match
        [Parameter(ParameterSetName = 'Group by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Name with Connection Profile')]
        [Parameter(ParameterSetName = 'Group by Name with Connection File')]
        [switch]$ExactMatch,
    
        # Get group by id number
        [Parameter(ParameterSetName = 'Group by Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Group by Id with Connection File')]
        [Alias("Id")]
        [int[]]$GroupId,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(ParameterSetName = 'All groups with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(ParameterSetName = 'All groups with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(ParameterSetName = 'All groups with Connection Profile')]
        [Parameter(ParameterSetName = 'Group by Name with Connection Profile')]
        [Parameter(ParameterSetName = 'Group by Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'All groups with Connection File')]
        [Parameter(ParameterSetName = 'Group by Name with Connection File')]
        [Parameter(ParameterSetName = 'Group by Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),
    
        # Should we return all details?
        [Parameter()]
        [switch]$ReturnDetails,
    
        # Number of entries to get per batch (default of 20)
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
    
        # Get all groups
        [Parameter()]
        [ValidateSet("Joinless", "PublicOpen", "PublicClosed", "PrivateUnlisted", "PrivateListed", "All")]
        [Alias("Type")]
        [string]$GroupType = "All",
    
        
        # Should I recurse into child groups?  Default is false
        [Parameter(ParameterSetName = 'Group by Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Group by Id with Connection File')]
        [Parameter(ParameterSetName = 'Group by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Group by Name with Connection Profile')]
        [Parameter(ParameterSetName = 'Group by Name with Connection File')]
        [switch]$Recurse,

        # Sort By
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateSet('Name', 'SortOrder', 'LastUpdate', 'ContentIdsOrder')]
        [string]$SortBy = 'Name',
        
        # Sort Order
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateSet('Ascending', 'Descending')]
        [string]$SortOrder = 'Ascending'

    
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
        if ( $ParentGroupId ) {
            $UriParameters['ParentGroupId'] = $ParentGroupId
        }
        if ( $Recurse ) {
            $UriParameters['IncludeAllSubGroups'] = 'true'
        }

        if ( $SortOrder ) {
            $UriParameters['SortOrder'] = $SortOrder
        }
        if ( $SortBy ) {
            $UriParameters['SortBy'] = $SortBy
        }

        $PropertiesToReturn = @(
            @{ Name = "GroupId"; Expression = { $_.Id } },
            @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } },
            "Key",
            @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } },
            "DateCreated",
            "Url",
            "GroupType",
            "ParentGroupId"
        )

        
    }
        
    PROCESS {
        switch -Wildcard ( $PSCmdlet.ParameterSetName ) {
            'Group by Name *' {
                ForEach ( $Name in $GroupName ) {
                    $Uri = 'api.ashx/v2/groups.json'
                    $UriParameters['GroupNameFilter'] = $Name
                    $GroupCount = 0
    
                    do {
                        Write-Verbose -Message "Making call with '$Uri'"
                        # Get the list of groups with matching name from the call
                        $GroupsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
    
                        if ( $GroupsResponse ) {
                            $GroupCount += $GroupsResponse.Groups.Count
                            # If we need an exact response on the name, then filter for only that exact group
                            if ( $ExactMatch ) {
                                $GroupsResponse.Groups = $GroupsResponse.Groups | Where-Object { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) -eq $Name }
                            }
                            # Should we return everything?
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
            'Group by Id *' {
                ForEach ( $Id in $GroupId ) {
                    # Setup the URI - depends on if we are using a parent ID or not
                    if ( $ParentGroupId ) {
                        $Uri = "api.ashx/v2/groups/$ParentGroupId/groups/$Id.json"
                    }
                    else {
                        $Uri = "api.ashx/v2/groups/$Id.json"
                    }
    
                    # Because everything is encoded in the URI, we don't need to send any $UriParameters
                    Write-Verbose -Message "Making call with '$Uri'"
                    $GroupsResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders -Verbose:$false
                        
                    # Filter if we are using the parent group id
                    if ( $ParentGroupId ) {
                        $GroupsResponse.Group = $GroupsResponse.Group | Where-Object { $_.ParentGroupId -eq $ParentGroupId }
                    }
                        
                    if ( $GroupsResponse.Group ) {
                        if ( $ReturnDetails ) {
                            $GroupsResponse.Group
                        }
                        else {
                            $GroupsResponse.Group | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    else {
                        Write-Warning -Message "No matching groups found for ID: $Id"
                    }
                }
            }
            default {
                # No ForEach loop needed here because we are pulling all groups
                $Uri = 'api.ashx/v2/groups.json'
                $GroupCount = 0
                do {
                    $GroupsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -Verbose:$false
    
                    if ( $ResolveParentName ) {
                        # This calls itself to get the parent group name
                        $GroupsResponse.Groups | Add-Member -MemberType ScriptProperty -Name "ParentGroupName" -Value { Get-VtGroup -GroupId $this.ParentGroupId | Select-Object -Property @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } } | Select-Object -ExpandProperty Name } -Force
                    }
    
                    if ( $GroupsResponse ) {
                        $GroupCount += $GroupsResponse.Groups.Count
                        if ( $ParentGroupId ) {
                            $GroupsResponse.Groups = $GroupsResponse.Groups | Where-Object { $_.ParentGroupId -eq $ParentGroupId }
                        }
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
        if ( $PSCmdlet.ShouldProcess( "On this target --> Target", "Did this thing --> Operation" ) ) {
                
        }
    
    }
        
    END {
        # Nothing to see here
    }
}