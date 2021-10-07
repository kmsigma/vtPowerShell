function Get-VtAbuseReport {
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
            $Global:VtAuthHeader = Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: 
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'UserGuid',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64478/abuse-report-rest-endpoints',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # User ID to use for abuse lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'UserGuid')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [guid]$UserGuid,
    
        # Content URL to use for lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,
    
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
    
        # Set the Uri for the target
        $Uri = 'api.ashx/v2/abusereports.json'
    
        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageSize"] = $BatchSize
        $UriParameters["PageIndex"] = 0
    
        if ( $UserId ) {
            $UriParameters["AuthorUserId"] = $UserGuid
        }
    
    }
    PROCESS {
    
        $TotalAbuseReports = 0
        if ( $PSCmdlet.ShouldProcess("Target", "Operation") ) {
            do {
                $AbuseReportsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                if ( $AbuseReportsResponse ) {
                    $TotalAbuseReports += $AbuseReportsResponse.SystemNotifications.Count
                    $AbuseReportsResponse.Reports
                    $UriParameters["PageIndex"]++
                }
            } while ( $TotalAbuseReports -lt $AbuseReportsResponse.TotalCount )
        }
    }
    
    END {
        # Nothing to see here
    }
}