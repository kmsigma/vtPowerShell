<#
Note: This is not ready for prime-time - still working on it
#>

<#
.Synopsis
   Get challenges from Verint / Telligent communities
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
   https://community.telligent.com/community/11/w/api-documentation/64558/list-challenge-rest-endpoint
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-VtChallenge
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

        # Get challenge by name
        [Parameter(
            ParameterSetName='By Name')]
        [string]$Name,

        # Challenge name exact match
        [Parameter(
            ParameterSetName='By Name')]
        [switch]$ExactMatch = $false,

        # Get challenges by group id number
        [Parameter(
            ParameterSetName='By Id')]
        [int]$GroupId,

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
    }
    
    process {
        switch ($pscmdlet.ParameterSetName) {
            "By Name" {
                Write-Verbose -Message "Querying for Challenge by Name"
                $UriSegment = "api.ashx/v2/ideas/challenges.json?Name=$( [System.Web.HTTPUtility]::UrlEncode( [System.Web.HTTPUtility]::HtmlEncode( $Name ) ) )"
                $Uri = $CommunityDomain + $UriSegment
                if ( $ExactMatch -and $Recurse ) {
                    $ChallengeId = Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader | Where-Object { $_.Name -eq [System.Web.HTTPUtility]::HtmlEncode( $Name ) } | Select-Object -ExpandProperty Id
                    if ( $ChallengeId ) {
                        Get-VtGroup -CommunityDomain $CommunityDomain -VtAuthHeader $VtAuthHeader -Id $GroupId -Recurse
                    }
                } elseif ( $ExactMatch -and -not $Recurse ) {
                    Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader | Where-Object { $_.Name -eq [System.Web.HTTPUtility]::HtmlEncode( $Name ) }
                } elseif ( $Recurse -and -not $ExactMatch ) {
                    #Request-Groups -Uri $Uri -VtAuthHeader $VtAuthHeader
                    $ChallengeIds = Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader | Select-Object -ExpandProperty Id
                    ForEach ( $ChallengeId in $ChallengeIds ) {
                        Get-VtChallenge -CommunityDomain $CommunityDomain -VtAuthHeader $VtAuthHeader -GroupId $GroupId -Recurse
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
                Write-Verbose -Message "Querying for Challenge by Group ID"
                $UriSegment = "api.ashx/v2/ideas/challenges.json?GroupId=$GroupId"
                $Uri = $CommunityDomain + $UriSegment
                Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader

                
                if ( $Recurse ) {
                    Write-Verbose -Message "`tQuerying for children of Group by ID"
                    $UriSegment = "api.ashx/v2/ideas/challenges.json?GroupId=$GroupId&IncludeAllSubGroups=true"
                    $Uri = $CommunityDomain + $UriSegment
                    Get-VtAll -Uri $Uri -VtAuthHeader $VtAuthHeader
                }
            }
            Default {
                Write-Verbose -Message "Querying for all challenges"
                $UriSegment = 'api.ashx/v2/ideas/challenges.json?IncludeAllSubGroups=true'
                $UriSegment = 'api.ashx/v2/ideas/challenges.json'
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