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
function Get-VtGroup {
    [CmdletBinding(DefaultParameterSetName = 'By Name', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64699/group-rest-endpoints',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType()]
    Param
    (
        # Get group by name
        [Parameter(
            ParameterSetName = 'By Name')]
        [Alias("Name")]
        [string[]]$GroupName,

        # Group name exact match
        [Parameter(
            ParameterSetName = 'By Name')]
        [switch]$ExactMatch = $false,

        # Get group by id number
        [Parameter(
            ParameterSetName = 'By Group Id')]
        [Alias("Id")]
        [int[]]$GroupId,

        # Get group by parent id number
        [Parameter()]
        [Alias("ParentId")]
        [int]$ParentGroupId,

        # Return limited details
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Details")]
        [switch]$ReturnDetails,

        # Number of entries to get per batch (default of 20)
        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 

        # Get all groups
        [Parameter(
            ParameterSetName = 'All Groups')]
        [Alias("All")]
        [switch]$AllGroups,

        # Resolve the parent id to a name
        [switch]$ResolveParentName,

        # Get all groups
        [Parameter()]
        [ValidateSet("Joinless", "PublicOpen", "PublicClosed", "PrivateUnlisted", "PrivateListed", "All")]
        [Alias("Type")]
        [string]$GroupType = "All",

        <#
        # Should I recurse into child groups?  Default is false
        [Parameter(
            ParameterSetName = 'By Group Id'
        )]
        [Parameter(
            ParameterSetName = 'By Name'
        )]
        [switch]$Recurse,
        #>

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
        $UriParameters = @{}
        $UriParameters['PageSize'] = $BatchSize
        $UriParameters['PageIndex'] = 0
        $UriParameters['GroupTypes'] = $GroupType
        if ( $ParentGroupId ) {
            $UriParameters['ParentGroupId'] = $ParentGroupId
        }
        $OutputProperties = @{ Name = "GroupId"; Expression = { $_.Id } }, @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } }, "Key", @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }, "DateCreated", "Url", "GroupType", "ParentGroupId"
        if ( $ResolveParentName ) {
            $OutputProperties += "ParentGroupName"
        }
    }
    
    PROCESS {
        switch ( $pscmdlet.ParameterSetName ) {
            'By Name' {
                ForEach ( $Name in $GroupName ) {
                    $Uri = 'api.ashx/v2/groups.json'
                    $UriParameters['GroupNameFilter'] = $Name
                    $GroupCount = 0

                    do {
                        Write-Verbose -Message "Making call with '$Uri'"
                        # Get the list of groups with matching name from the call
                        $GroupsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader -Verbose:$false

                        if ( $GroupsResponse ) {
                            $GroupCount += $GroupsResponse.Groups.Count
                            # If we need an exact response on the name, then filter for only that exact group
                            if ( $ExactMatch ) {
                                $GroupsResponse.Groups = $GroupsResponse.Groups | Where-Object { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) -eq $Name }
                            }
                            if ( $ResolveParentName ) {
                                # This calls itself to get the parent group name
                                $GroupsResponse.Groups | Add-Member -MemberType ScriptProperty -Name "ParentGroupName" -Value { Get-VtGroup -GroupId $this.ParentGroupId -VtCommunity $VtCommunity -VtAuthHeader $VtAuthHeader | Select-Object -Property @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } } | Select-Object -ExpandProperty Name } -Force
                            }
                            # Should we return everything?
                            if ( $ReturnDetails ) {
                                $GroupsResponse.Groups
                            }
                            else {
                                $GroupsResponse.Groups | Select-Object -Property $OutputProperties
                            }
                        }
                    
                        $UriParameters['PageIndex']++
                        Write-Verbose -Message "Incrementing Page Index :: $( $UriParameters['PageIndex'] )"
                    } while ( $GroupCount -lt $GroupsResponse.TotalCount )
                    
                }
            }
            'By Group Id' {
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
                    $GroupsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers $VtAuthHeader -Verbose:$false
                    
                    if ( $ResolveParentName ) {
                        # This calls itself to get the parent group name
                        $GroupsResponse.Groups | Add-Member -MemberType ScriptProperty -Name "ParentGroupName" -Value { Get-VtGroup -GroupId $this.ParentGroupId | Select-Object -Property @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } } | Select-Object -ExpandProperty Name } -Force
                    }

                    # Filter if we are using the parent group id
                    if ( $ParentGroupId ) {
                        $GroupsResponse.Group = $GroupsResponse.Group | Where-Object { $_.ParentGroupId -eq $ParentGroupId }
                    }
                    
                    if ( $GroupsResponse.Group ) {
                        if ( $ReturnDetails ) {
                            $GroupsResponse.Group
                        }
                        else {
                            $GroupsResponse.Group | Select-Object -Property $OutputProperties
                        }
                    }
                    else {
                        Write-Warning -Message "No matching groups found."
                    }
                }
            }
            'All Groups' {
                # No ForEach loop needed here because we are pulling all groups
                $Uri = 'api.ashx/v2/groups.json'
                $GroupCount = 0
                do {
                    $GroupsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader -Verbose:$false

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
                            $GroupsResponse.Groups | Select-Object -Property $OutputProperties
                        }
                    }
                    $UriParameters['PageIndex']++
                    Write-Verbose -Message "Incrementing Page Index :: $( $UriParameters['PageIndex'] )"
                } while ( $GroupCount -lt $GroupsResponse.TotalCount )
            }
        }
        if ( $pscmdlet.ShouldProcess( "On this target --> Target", "Did this thing --> Operation" ) ) {
            
        }

    }
    
    END {
        # Nothing to see here
    }
}

