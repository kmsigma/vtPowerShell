function Get-VtAbuseReport {
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
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader

    )

    begin {

        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }

        <#
        .Synopsis
            Convert a hashtable to a query string
        .DESCRIPTION
            Converts a passed hashtable to a query string based on the key:value pairs.
        .EXAMPLE
            $UriParameters = @{}
            PS > $UriParameters.Add("PageSize", 20)
            PS > $UriParameters.Add("PageIndex", 1)

            PS > $UriParameters

        Name                           Value
        ----                           -----
        PageSize                       20
        PageIndex                      1

            PS > $UriParameters | ConvertTo-QueryString

            PageSize=20&PageIndex=1
        .OUTPUTS
            string object in the form of "key1=value1&key2=value2..."  Does not include the preceeding '?' required for many URI calls
        .NOTES
            This is bascially the reverse of [System.Web.HttpUtility]::ParseQueryString

            This is included here just to have a reference for it.  It'll typically be defined 'internally' within the `begin` blocks of functions
        #>
        function ConvertTo-QueryString {
            param (
                # Hashtable containing segmented query details
                [Parameter(
                    Mandatory = $true, 
                    ValueFromPipeline = $true)]
                [ValidateNotNull()]
                [ValidateNotNullOrEmpty()]
                [System.Collections.Hashtable]$Parameters
            )
            $ParameterStrings = @()
            $Parameters.GetEnumerator() | ForEach-Object {
                $ParameterStrings += "$( $_.Key )=$( $_.Value )"
            }
            $ParameterStrings -join "&"
        }

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeader = $AuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false

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
    process {

        $TotalAbuseReports = 0
        do {
            $AbuseReportsResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
            if ( $AbuseReportsResponse ) {
                $TotalAbuseReports += $AbuseReportsResponse.SystemNotifications.Count
                $AbuseReportsResponse.Reports
                $UriParameters["PageIndex"]++
            }
        } while ( $TotalAbuseReports -lt $AbuseReportsResponse.TotalCount )
    }

    end {
        # Nothing to see here
    }
}
