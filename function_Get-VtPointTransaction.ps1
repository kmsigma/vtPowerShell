function Get-VtPointTransaction {
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
            $Global:VtAuthHeader = ConvertTo-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: 
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64803/list-point-transactions-point-transaction-rest-endpoint',
        ConfirmImpact = 'Medium')
    ]
    Param
    (
        # Username to use for lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Username')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
    
        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Email Address'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$EmailAddress,
    
        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'User Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]$UserId,
    
        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Transaction Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]$TransactionId,
    
        # Get all transactions
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All Users'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$AllUsers = $false,
    
        # Start Date of Transaction Search
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [datetime]$StartDate,
    
        # End Date of Transaction Search - defaults to 'now'
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [datetime]$EndDate,
    
        # Should we return all details or just the simplified version
        [switch]$ReturnDetails = $false,
    
        # Optional Filter to set for the action.
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$ActionFilter,
    
        # Optional page size grab for the call to the API. (Script defaults to 1000 per batch)
        # Larger page sizes generally complete faster, but consume more memory
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(100, 10000)]
        [int]$BatchSize = 1000,
    
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
    
        $RestMethod = "GET"
    
        # Base Uri for calls
        $Uri = "api.ashx/v2/pointtransactions.json"
            
        # Create an collection for the UriParameters
        $UriParameters = @{}
        $UriParameters.Add("PageIndex", 0)
        $UriParameters.Add("PageSize", $BatchSize)
        if ( $EndDate ) {
            $UriParameters.Add("EndDate", $EndDate)
        }
        if ( $StartDate ) {
            $UriParameters.Add("StartDate", $StartDate)
        }
    }
        
    
    PROCESS {
            
        switch ( $PSCmdlet.ParameterSetName ) {
            'User Id' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the user id [$UserId] for the lookup"
                # Points Lookup requires the UserID, not the username
                $UriParameters.Add("UserId", $UserId)
                $LookupKey = "for User ID: [$UserId]"
            }
            'Username' { 
                Write-Verbose -Message "Get-VtPointTransaction: Using the username [$Username] for the lookup"
                # Points Lookup requires the UserID, not the username
                $User = Get-VtUser -Username $Username -Community $VtCommunity -AuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                $UriParameters.Add("UserId", $User.UserId)
                $LookupKey = "for Username: [$Username]"
            }
            'Email Address' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the email [$EmailAddress] for the lookup"
                # Points Lookup requires the UserID, not the email address
                $User = Get-VtUser -EmailAddress $EmailAddress -Community $VtCommunity -AuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                $UriParameters.Add("UserId", $User.UserId)
                $LookupKey = "for Email Address: [$EmailAddress]"
            }
            'Transaction Id' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the TransactionID [$TransactionId] for the lookup"
                # Points Lookup requires the UserID, not the email address
                $LookupKey = "for Transaction ID: [$TransactionId]"
            }
            'All Users' {
                Write-Verbose -Message "Request all points for the lookup"
                $LookupKey = "for [All Users]"
            }
        }
    
        if ( $UriParameters["UserId"] -or $PSCmdlet.ParameterSetName -eq 'All Users' ) {
            if ( $PSCmdlet.ShouldProcess("$VtCommunity", "Search for point transactions $LookupKey") ) {
                $PointsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                Write-Verbose -Message "Received $( $PointsResponse.PointTransactions.Count ) responses"
                Write-Progress -Activity "Querying $VtCommunity for Points Transactions" -CurrentOperation "Searching $LookupKey for the first $BatchSize entries" -PercentComplete 0
                $TotalResponseCount = $PointsResponse.PointTransactions.Count
                if ( $ActionFilter ) {
                    $PointTransactions = $PointsResponse.PointTransactions | Where-Object { ( $_.Description | ConvertFrom-HtmlString ) -like $ActionFilter }
                    Write-Verbose -Message "Keeping $( $PointTransactions.Count ) total responses"
                }
                else {
                    $PointTransactions = $PointsResponse.PointTransactions
                    Write-Verbose -Message "Keeping all $( $PointTransactions.Count ) responses"
                }
    
                while ( $TotalResponseCount -lt $PointsResponse.TotalCount ) {
                    # Bump the page index counter
                        ( $UriParameters.PageIndex )++
                    Write-Verbose -Message "Making call #$( $UriParameters.PageIndex ) to the API"
                    Write-Progress -Activity "Querying $VtCommunity for Points Transactions" -CurrentOperation "Making call #$( $UriParameters.PageIndex ) to the API [$TotalResponseCount / $( $PointsResponse.TotalCount )]" -PercentComplete ( ( $TotalResponseCount / $PointsResponse.TotalCount ) * 100 )
                    $PointsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                    Write-Verbose -Message "Received $( $PointsResponse.PointTransactions.Count ) responses"
                    $TotalResponseCount += $PointsResponse.PointTransactions.Count
                    if ( $ActionFilter ) {
                        $PointTransactions += $PointsResponse.PointTransactions | Where-Object { ( $_.Description | ConvertFrom-HtmlString ) -like $ActionFilter }
                        Write-Verbose -Message "Keeping $( $PointTransactions.Count ) total responses"
                    }
                    else {
                        $PointTransactions += $PointsResponse.PointTransactions
                        Write-Verbose -Message "Keeping all $( $PointTransactions.Count ) responses"
                    }
                }
                Write-Progress -Activity "Querying $VtCommunity for Points Transactions" -Completed
    
                # If we want details, return everything
                if ( $ReturnDetails ) {
                    $PointTransactions
                }
                else {
                    $PointTransactions | Select-Object -Property @{ Name = "TransactionId"; Expression = { [int]( $_.id ) } }, @{ Name = "Username"; Expression = { $_.User.Username } }, @{ Name = "UserId"; Expression = { $_.User.Id } }, Value, @{ Name = "Action"; Expression = { $_.Description | ConvertFrom-HtmlString } }, @{ Name = "Date"; Expression = { $_.CreatedDate } }, @{ Name = "Item"; Expression = { $_.Content.HtmlName | ConvertFrom-HtmlString } }, @{ Name = "ItemUrl"; Expression = { $_.Content.Url } }
                }
            }
        }
        elseif ( $PSCmdlet.ParameterSetName -eq 'Transaction Id' ) {
            $Uri = "api.ashx/v2/pointtransaction/$( $TransactionId ).json"
            $PointsResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false ) -Verbose:$false
            if ( $PointsResponse.PointTransaction.User ) {
                # If we want details, return everything
                if ( $ReturnDetails ) {
                    $PointsResponse.PointTransaction
                }
                else {
                    $PointsResponse.PointTransaction | Select-Object -Property @{ Name = "TransactionId"; Expression = { [int]( $_.id ) } }, @{ Name = "Username"; Expression = { $_.User.Username } }, @{ Name = "UserId"; Expression = { $_.User.Id } }, Value, @{ Name = "Action"; Expression = { $_.Description | ConvertFrom-HtmlString } }, @{ Name = "Date"; Expression = { $_.CreatedDate } }, @{ Name = "Item"; Expression = { $_.Content.HtmlName | ConvertFrom-HtmlString } }, @{ Name = "ItemUrl"; Expression = { $_.Content.Url } }
                }
            }
            else {
                Write-Verbose -Message "No points transaction found matching #$TransactionId"
            }
        }
    }
    END {
        # Nothing to see here
    }
}