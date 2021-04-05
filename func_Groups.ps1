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
function Get-VtGroup
{
    [CmdletBinding(DefaultParameterSetName='All Groups', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64699/group-rest-endpoints',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType()]
    Param
    (
        # Community where you'll query for groups.  Protocol is required.
        [Parameter(
            Mandatory=$false,
            ValueFromPipeline=$true,
            Position=0,
            HelpMessage='Provide your community URL including the "http://" or "https://" and trailing slash' )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community", "Domain")]
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Required authentication header
        [Parameter(
            Mandatory=$false,
            Position=1
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("Header")]
        [hashtable]$VtAuthHeader = $Global:AuthHeader,

        # Get group by name
        [Parameter(
            ParameterSetName='By Name')]
        [string]$Name,

        # Group name exact match
        [Parameter(
            ParameterSetName='By Name')]
        [switch]$ExactMatch = $false,

        # Get group by id number
        [Parameter(
            ParameterSetName='By Id')]
        [Alias("GroupID")]
        [int]$Id,

        # Should I recurse into child groups?  Default is false
        [Parameter(
            Mandatory=$false
        )]
        [switch]$Recurse = $false

    
    )
    
    begin {
        if ( -not ( Get-Command -Name "Get-VtAll" -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        <#
        function Request-Groups
        {
            [CmdletBinding(
                PositionalBinding=$false,
                ConfirmImpact='Medium')]

            Param
            (
                # Uri to Call
                [Parameter(
                    Mandatory=$true, 
                    Position=0)]
                [string]$Uri,
                # Authentication header to use
                [Parameter(
                    Mandatory=$true, 
                    Position=1)]
                [hashtable]$VtAuthHeader
            )

            $Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $VtAuthHeader
            if ( $Response ) {
                if ( $Response | Get-Member -Name "Group" -ErrorAction SilentlyContinue ) {
                    # Single Response Only - just return the group
                    $Response.Group
                } else { # implies '$Response.Groups' exists
                    # Multiple Responses
                    $CurrentCount = 0
                    $CurrentCount += $Response.Groups.Count
                    $Response.Groups
                    $NextIndex = 1
                    while ( $CurrentCount -lt $Response.TotalCount ) {
                        $Response = Invoke-RestMethod -Uri "$( $Uri )?PageIndex=$( $NextIndex )" -Method Get -Headers $VtAuthHeader
                        $CurrentCount += $Response.Groups.Count
                        $Response.Groups
                        $NextIndex++
                    }
                }
            }

        }
        #>
        
    }
    
    process {
        switch ($pscmdlet.ParameterSetName) {
            "By Name" {
                Write-Verbose -Message "Querying for Group by Name"
                $UriSegment = "api.ashx/v2/groups.json?GroupNameFilter=$( [System.Web.HTTPUtility]::UrlEncode( [System.Web.HTTPUtility]::HtmlEncode( $Name ) ) )"
                $Uri = $CommunityDomain + $UriSegment
                if ( $ExactMatch -and $Recurse ) {
                    $GroupId = Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader | Where-Object { $_.Name -eq [System.Web.HTTPUtility]::HtmlEncode( $Name ) } | Select-Object -ExpandProperty Id
                    if ( $GroupId ) {
                        Get-VtGroup -CommunityDomain $CommunityDomain -VtAuthHeader $VtAuthHeader -Id $GroupId -Recurse
                    }
                } elseif ( $ExactMatch -and -not $Recurse ) {
                    Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader | Where-Object { $_.Name -eq [System.Web.HTTPUtility]::HtmlEncode( $Name ) }
                } elseif ( $Recurse -and -not $ExactMatch ) {
                    #Request-Groups -Uri $Uri -VtAuthHeader $VtAuthHeader
                    $GroupIds = Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader | Select-Object -ExpandProperty Id
                    ForEach ( $GroupId in $GroupIds ) {
                        Get-VtGroup -CommunityDomain $CommunityDomain -VtAuthHeader $VtAuthHeader -Id $GroupId -Recurse
                    }
                } else {
                    Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader
                }
                <#
                if ( $Recurse ) {
                    $UriSegment += "&IncludeAllSubGroups=true"
                }
                $Uri = $CommunityDomain + $UriSegment
                if ( -not $ExactMatch ) {
                    Request-Groups -Uri $Uri -VtAuthHeader $VtAuthHeader
                } else {
                    Request-Groups -Uri $Uri -VtAuthHeader $VtAuthHeader | Where-Object { $_.Name -eq [System.Web.HTTPUtility]::HtmlEncode( $Name ) } | Select-Object -ExpandProperty Id
                }
                #>

            }
            "By Id" {
                Write-Verbose -Message "Querying for Group by ID"
                $UriSegment = "api.ashx/v2/groups/$( $Id ).json"
                $Uri = $CommunityDomain + $UriSegment
                Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader

                
                if ( $Recurse ) {
                    Write-Verbose -Message "`tQuerying for children of Group by ID"
                    $UriSegment = "api.ashx/v2/groups/$( $Id )/groups.json?IncludeAllSubGroups=true"
                    $Uri = $CommunityDomain + $UriSegment
                    Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader
                }
            }
            Default {
                Write-Verbose -Message "Querying for all groups"
                $UriSegment = 'api.ashx/v2/groups.json?IncludeAllSubGroups=true'
                $UriSegment = 'api.ashx/v2/groups.json'
                $Uri = $CommunityDomain + $UriSegment
                Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader
            }
        }
        if ($pscmdlet.ShouldProcess("On this target --> Target", "Did this thing --> Operation")) {
            

        }

    }
    
    end {
        
    }
}

