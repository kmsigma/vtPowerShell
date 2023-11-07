function Get-VtGroupMembership {
    <#
    .Synopsis
        Get group members from Verint / Telligent communities
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
        https://community.telligent.com/community/12/w/api-documentation/71329/list-group-user-rest-endpoint
    .COMPONENT
        The component this cmdlet belongs to
    .ROLE
        The role this cmdlet belongs to
    .FUNCTIONALITY
        The functionality that best describes this cmdlet
    .NOTES
        First attempted update for v12 API

    #>
    [CmdletBinding(DefaultParameterSetName = 'All group members with Connection File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/12/w/api-documentation/71329/list-group-user-rest-endpoint',
        ConfirmImpact = 'Low')]
    [Alias()]
    [OutputType()]
    Param
    (
        # Get Group Members by group id (user type)
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Group Members by Group Id with Authentication Header',
            Position = 0
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Group Members by Group Id with Connection Profile',
            Position = 0
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Group Members by Group Id with Connection File',
            Position = 0
        )]
        [int[]]$GroupId,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'All group members with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Members by Group Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'All group members with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Members by Group Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'All group members with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Members by Group Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'All group members with Connection File')]
        [Parameter(ParameterSetName = 'Group Members by Group Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),
    
        # Should we return all details?
        [Parameter()]
        [switch]$ReturnDetails,
    
        # Number of entries to get per batch (default of 20)
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
    
        # Get group members by type
        [Parameter(ParameterSetName = 'All group members with Authentication Header')]
        [Parameter(ParameterSetName = 'All group members with Connection File')]
        [Parameter(ParameterSetName = 'All group members with Connection Profile')]
        [Parameter(ParameterSetName = 'Group Members by Group Id with Authentication Header')]

        [Parameter(ParameterSetName = 'Group Members by Group Id with Connection File')]
        
        [Parameter(ParameterSetName = 'Group Members by Group Id with Connection Profile')]
        [ValidateSet("Owner", "Manager", "Member", "PendingMember", "All")]
        [string]$MembershipType = "All",

        # Get users or roles
        [Parameter(ParameterSetName = 'All group members with Authentication Header')]
        [Parameter(ParameterSetName = 'All group members with Connection File')]
        [Parameter(ParameterSetName = 'All group members with Connection Profile')]

        [Parameter(ParameterSetName = 'Group Members by Group Id with Authentication Header')]

        [Parameter(ParameterSetName = 'Group Members by Group Id with Connection File')]

        [Parameter(ParameterSetName = 'Group Members by Group Id with Connection Profile')]
        [ValidateSet("User", "Role")]
        [string]$MemberType = "User",

        # Should we include members who are there via role assignment
        [Switch]$IncludeRoleMembers,

        # Sort By
        [Parameter(ParameterSetName = 'All group members with Authentication Header')]
        [Parameter(ParameterSetName = 'All group members with Connection File')]
        [Parameter(ParameterSetName = 'All group members with Connection Profile')]
        [Parameter(ParameterSetName = 'Group Members by Group Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Group Members by Group Id with Connection File')]
        [Parameter(ParameterSetName = 'Group Members by Group Id with Connection Profile')]
        [ValidateSet('GroupSortOrder', 'GroupName', 'UserJoinedDate', 'Username', 'DisplayName', 'UserLastActiveDate', 'UserPosts', 'UserEmail', 'MembershipType', 'MembershipDate', 'Score:SCORE_ID')]
        [string]$SortBy = 'GroupName',

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
        if ( $MembershipType -ne "All" ) {
            $UriParameters['MembershipType'] = $MembershipType
        }
        $UriParameters['MemberType'] = $MemberType

        $UriParameters['SortBy'] = $SortBy
        if ( $Descending ) {
            $UriParameters['SortOrder'] = 'Descending'
        }
        else {
            $UriParameters['SortOrder'] = 'Ascending'
        }

        $PropertiesToReturn = @(
            @{ Name = "GroupId"; Expression = { $_.Group.Id } }
            @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }
            @{ Name = "GroupKey"; Expression = { $_.Group.Key } }
            @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Description ) } }
            @{ Name = "DateCreated"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.DateCreated ) } }
            @{ Name = "Url"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Url ) } }
            @{ Name = "GroupType"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.GroupType ) } }
            @{ Name = "Username"; Expression = { $_.DisplayName } }
            @{ Name = "MembershipType"; Expression = { $_.MembershipType } }
        )
    }
        
    PROCESS {
        <#
        URI details: 
        query for users :: api.ashx/v2/groups/{groupid}/members/users.json
        query for roles :: api.ashx/v2/groups/{groupid}/members/roles.json <-- rare

        #>

        switch -Wildcard ( $PSCmdlet.ParameterSetName ) {
            'Group Members by Group Id*' {
                ForEach ( $g in $GroupId ) {
                    if ( $MemberType -eq "User" ) {
                        $Uri = "api.ashx/v2/groups/{GroupID}/members/users.json"
                    }
                    else {
                        $Uri = "api.ashx/v2/groups/{GroupID}/members/roles.json"
                    }
                    # Setup the URI
                    $Uri = $Uri.Replace("{GroupID}", $g)
                    # Because everything is encoded in the URI, we don't need to send any $UriParameters
                    Write-Verbose -Message "Making call with '$Uri'"
                    if ( $PSCmdlet.ShouldProcess($Community, "Retrieve group membership with group id: '$g'") ) {
                        $TotalResponses = 0
                        do {
                        $MemberResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -Verbose:$false
                        
                        if ( $MemberResponse."$( $MemberType )s" ) {
                            $TotalResponses += $MemberResponse."$( $MemberType )s".Count
                            if ( $ReturnDetails ) {
                                $MemberResponse."$( $MemberType )s"
                            }
                            else {
                                $MemberResponse."$( $MemberType )s" | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        else {
                            Write-Warning -Message "No $( $MemberType.ToLower() )-based members found for group ID: $g"
                        }
                        $UriParameters["PageIndex"]++
                    } while ( $TotalResponses -lt $MemberResponse.TotalCount )
                    }
                }
            }
            default {
                # Pulling all group memberships
                $Groups = Get-VtGroup
                $MembershipCount = 0
                if ( $PSCmdlet.ShouldProcess($Community, "Retrieve all groups") ) {
                    ForEach ( $Group in $Groups ) {
                        do {
                            $Uri = "api.ashx/v2/groups/$( $Group.GroupId )/members/users.json"
                            $MemberResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -Verbose:$false
    
                            if ( $MemberResponse ) {
                                $MembershipCount += $MemberResponse.Users.Count
                                if ( $ReturnDetails ) {
                                    $MemberResponse.Users
                                }
                                else {
                                    $MemberResponse.Users | Select-Object -Property $PropertiesToReturn
                                }
                            }
                            $UriParameters['PageIndex']++
                            Write-Verbose -Message "Incrementing Page Index :: $( $UriParameters['PageIndex'] )"
                        } while ( $MembershipCount -lt $MemberResponse.TotalCount )
                    }
                }
            }
        }
    }
        
    END {
        # Nothing to see here
    }
}