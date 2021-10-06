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
        $Uri = 'api.ashx/v2/systemnotifications.json'

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageSize"] = $BatchSize
        $UriParameters["PageIndex"] = 0

    }
    PROCESS {

        $TotalNotifications = 0
        if ( $PSCmdlet.ShouldProcess("Target", "Operation") ) {
            do {
                $NotificationsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                if ( $NotificationsResponse ) {
                    $TotalNotifications += $NotificationsResponse.SystemNotifications.Count
                    $NotificationsResponse.SystemNotifications
                    $UriParameters["PageIndex"]++
                }
            } while ( $TotalNotifications -lt $NotificationsResponse.TotalCount )
        }
    }

    END {
        # Nothing to see here
    }
}
