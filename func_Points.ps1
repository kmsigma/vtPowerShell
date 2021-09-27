# Source Information: https://community.telligent.com/community/11/w/api-documentation/64799/point-transaction-rest-endpoints

<#
.Synopsis
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Add-VtPointTransaction -Username KMSigma -Description "Say hi to your wife for me." -AwardDateTime "09/14/2019" -Points 43 -VtCommunity $VtCommunity -VtAuthHeader $VtAuthHeader
.EXAMPLE
    Add-VtPointTransaction -Username KMSigma -Description "Will confirm if you ask for more for 5,000 points" -Points 5001 -VtCommunity $VtCommunity -VtAuthHeader $VtAuthHeader
.OUTPUTS
    PowerShell Custom Object Containing the Content, CreateDate, Description, Transaction ID, User Custom Object, and point Value
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Add-VtPointTransaction {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64799/point-transaction-rest-endpoints',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param(
        # The username of the account who is getting the points
        [Parameter(
            Mandatory = $true, 
            Position = 0
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        # The number of points to award to an account.  This does not support removing points.
        [Parameter(
            Mandatory = $true, 
            Position = 1
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 100000)]
        [int]$Points,

        # Description of the points award.  Should try and keep the description to less than 120 characters if possible.
        [Parameter(
            Mandatory = $true, 
            Position = 2
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(0, 250)]
        [string]$Description,


        # The date/time you want to have the awards added - defaults to 'now'
        [Parameter(
            Mandatory = $false, 
            Position = 3
        )]
        [datetime]$AwardDateTime = ( Get-Date ),

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

    begin {
        if ( -not ( Get-Command -Name Get-VtUser -ErrorAction SilentlyContinue ) ) {
            . .\func_Users.ps1
        }
        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        
        # Convert the username to a userid
        $User = Get-VtUser -Username $Username -VtAuthHeader $VtAuthHeader -VtCommunity $VtCommunity -ReturnDetails
        # Since point transactions require a ContentId and ContentTypeId, we should pull those from the user's profile
        if ( -not $User ) {
            Write-Error -Message "Unable to add point because we didn't find a matching user for [$Username]"
        }
        else {
            $Userid = $User.Id
            $ContentId = $User.ContentId
            $ContentTypeId = $User.ContentTypeId
        }
        $Uri = "api.ashx/v2/pointtransactions.json"

        $RestMethod = "GET"
    }
    process {
        $Proceed = $true
        if ($pscmdlet.ShouldProcess("$Username", "Add $Points to Account")) {
            if ( $Points -gt 5000 ) {
                Write-Host "====LARGE POINT DISTRIBUTION VALIDATION====" -ForegroundColor Yellow
                $BigPoints = Read-Host -Prompt "You are about to add $Points to $Username's account.  Are you sure you want to do this?  [Enter 'Yes' to confirm]"
                $Proceed = ( $BigPoints.ToLower() -eq 'yes' )
            }
            if ( $Proceed ) {
                # Build the body to send to the account
                # For proper display, the description needs to be wrapped in HTML paragraph tags.
                $Body = @{
                    Description   = "<p>$Description</p>";
                    UserId        = $UserId;
                    Value         = $Points;
                    ContentID     = $ContentId; # We'll just use the ContentID from the user
                    ContentTypeId = $ContentTypeId; # We'll just use the ContentID from the user
                    CreatedDate   = $AwardDateTime;
                }
                try {
                    $PointsRequest = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Method Post -Body $Body -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -Verbose:$False -WhatIf:$false )
                    $PointsRequest.PointTransaction
                }
                catch {
                    Write-Error -Message "Something didn't work"
                }
            }
        }
    }
    end {
        # Nothing to see here
    }
}

<#

I think I want to change the logic here to a do..while at a later date

#>
function Get-VtPointTransaction {
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
    
    begin {
        # Check for necessary functions
        if ( -not ( Get-Command -Name Get-VtUser -ErrorAction SilentlyContinue) ) {
            . .\func_Users.ps1
        }
        if ( -not ( Get-Command -Name ConvertTo-QueryString -ErrorAction SilentlyContinue ) ) {
            . .\func_Utilities.ps1
        }
        
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
    

    process {
        
        switch ( $pscmdlet.ParameterSetName ) {
            'User Id' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the user id [$UserId] for the lookup"
                # Points Lookup requires the UserID, not the username
                $UriParameters.Add("UserId", $UserId)
                $LookupKey = "for User ID: [$UserId]"
            }
            'Username' { 
                Write-Verbose -Message "Get-VtPointTransaction: Using the username [$Username] for the lookup"
                # Points Lookup requires the UserID, not the username
                $User = Get-VtUser -Username $Username -VtCommunity $VtCommunity -VtAuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                $UriParameters.Add("UserId", $User.UserId)
                $LookupKey = "for Username: [$Username]"
            }
            'Email Address' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the email [$EmailAddress] for the lookup"
                # Points Lookup requires the UserID, not the email address
                $User = Get-VtUser -EmailAddress $EmailAddress -VtCommunity $VtCommunity -VtAuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
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

        if ( $UriParameters["UserId"] -or $pscmdlet.ParameterSetName -eq 'All Users' ) {
            if ( $pscmdlet.ShouldProcess("$VtCommunity", "Search for point transactions $LookupKey") ) {
                $PointsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
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
                    $PointsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
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
        elseif ( $pscmdlet.ParameterSetName -eq 'Transaction Id' ) {
            $Uri = "api.ashx/v2/pointtransaction/$( $TransactionId ).json"
            $PointsResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false ) -Verbose:$false
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
    end {
        # Nothing to see here
    }
}

<#
.Synopsis
    Remove a Point Transaction based on the Transaction ID
.DESCRIPTION
    Remove one or more point transactions using the 
.EXAMPLE
    
.EXAMPLE
    
.OUTPUTS
    PowerShell Custom Object Containing the Content, CreateDate, Description, Transaction ID, User Custom Object, and point Value
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Remove-VtPointTransaction {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64801/delete-point-transaction-point-transaction-rest-endpoint',
        ConfirmImpact = 'High')
    ]
    Param
    (
        # TransactionIDs to use for lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int[]]$TransactionId,

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
    begin {
        $RestMethod = "Delete"

        if ( -not ( Get-Command -Name Set-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }

    }
    process {
        # This is where things do stuff
        ForEach ( $id in $TransactionId ) {
            if ( Get-VtPointTransaction -TransactionId $Id -VtCommunity $VtCommunity -VtAuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod Get -WhatIf:$false -Verbose:$false ) -Verbose:$false ) {
                if ( $pscmdlet.ShouldProcess("$VtCommunity", "Delete Point Transaction $id") ) {
                
                    $Uri = "api.ashx/v2/pointtransaction/$( $id ).json"
                    # Method: Post
                    # Rest-Method: Delete
                    try {
                        $RemovePointsResponse = Invoke-RestMethod -Method Post -Uri ( $VtCommunity + $Uri ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                        if ( $RemovePointsResponse ) {
                            Write-Verbose -Message "Points Transaction #$id removed"
                        }
                    }
                    catch {
                        Write-Error -Message "Error purging Points Transaction #$id"
                    }
                }
                
            }
            else {
                Write-Verbose -Message "No points transaction found matching #$id.  Unable to delete."
            }
        }

    }
    end {
        # nothing here
    }
}

