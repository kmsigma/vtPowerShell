function Get-VtSysNotification {
    [CmdletBinding(
        DefaultParameterSetName = 'ContentId',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64865/system-notification-rest-endpoints',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        <#
        # Content ID to use for lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'ContentId')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [guid]$ContentId,
        #>
        # Content URL to use for lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateRange(1, 1000)]
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
        $Uri = 'api.ashx/v2/systemnotifications.json'

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageSize"] = $BatchSize
        $UriParameters["PageIndex"] = 0

    }
    process {

        $TotalNotifications = 0
        do {
            $NotificationsResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
            if ( $NotificationsResponse ) {
                $TotalNotifications += $NotificationsResponse.SystemNotifications.Count
                $NotificationsResponse.SystemNotifications
                $UriParameters["PageIndex"]++
            }
        } while ( $TotalNotifications -lt $NotificationsResponse.TotalCount )
    }

    end {
        # Nothing to see here
    }
}
