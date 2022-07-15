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
        DefaultParameterSetName = 'All Transactions with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64803/list-point-transactions-point-transaction-rest-endpoint',
        ConfirmImpact = 'Low')
    ]
    Param
    (
        # Username to use for lookup
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Username with Authentication Header')]
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Username with Connection Profile')]
        [Parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Username with Connection File')]
        [string[]]$Username,
    
        # Email address to use for lookup
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Email Address with Authentication Header')]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Email Address with Connection Profile')]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Email Address with Connection File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$EmailAddress,
    
        # User ID address to use for lookup
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'User Id with Authentication Header')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'User Id with Connection Profile')]
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'User Id with Connection File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64[]]$UserId,
    
        # Email address to use for lookup
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Connection File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64[]]$TransactionId,
    
        # Start Date of Transaction Search
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [datetime]$StartDate,
    
        # End Date of Transaction Search - defaults to 'now'
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [datetime]$EndDate,
    
        # Sort type for the results'
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("CreateDate", "Value")]
        [string]$SortBy = 'CreatedDate',

        # Optional page size grab for the call to the API. (Script defaults to 100 per batch)
        # Larger page sizes generally complete faster, but consume more memory
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(10, 10000)]
        [int]$BatchSize = 100,

        # Should we return all details?
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$ReturnDetails,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Email Address with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Transactions with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Email Address with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Transactions with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("AuthHeader")]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Email Address with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Transactions with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(Mandatory = $false, ParameterSetName = 'Username with Connection File')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Email Address with Connection File')]
        [Parameter(Mandatory = $false, ParameterSetName = 'User Id with Connection File')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Transaction ID with Connection File')]
        [Parameter(Mandatory = $false, ParameterSetName = 'All Transactions with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),

        # Suppress the progress bar
        [Parameter()]
        [switch]$SuppressProgressBar
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

        $RestMethod = "GET"
    
        # Create an collection for the UriParameters
        $UriParameters = @{}
        $UriParameters.Add("PageIndex", 0)
        $UriParameters.Add("PageSize", $BatchSize)
        $UriParameters.Add("SortBy", $SortBy)
        if ( $EndDate ) {
            $UriParameters.Add("EndDate", $EndDate)
        }
        if ( $StartDate ) {
            $UriParameters.Add("StartDate", $StartDate)
        }
    
        $PropertiesToReturn = @(
            @{ Name = "TransactionId"; Expression = { [int]( $_.id ) } },
            @{ Name = "Username"; Expression = { $_.User.Username } },
            @{ Name = "UserId"; Expression = { $_.User.Id } },
            'Value',
            @{ Name = "Action"; Expression = { $_.Description | ConvertFrom-HtmlString } },
            @{ Name = "Date"; Expression = { $_.CreatedDate } },
            @{ Name = "Item"; Expression = { $_.Content.HtmlName | ConvertFrom-HtmlString } },
            @{ Name = "ItemUrl"; Expression = { $_.Content.Url } }
        )
    }
        
    
    PROCESS {
            
        switch -wildcard ( $PSCmdlet.ParameterSetName ) {
            'User ID *' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the user id for the lookup"
                # Points Lookup requires the UserID, not the username
                $Users = $UserId
                $ProcessMethod = "List"
            }
            'Username *' { 
                Write-Verbose -Message "Get-VtPointTransaction: Using the username for the lookup"
                # Points Lookup requires the UserID, not the username
                $Users = Get-VtUser -Username $Username -Community $Community -AuthHeader ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false ) | Select-Object -ExpandProperty UserId
                $ProcessMethod = "List"
            }
            'Email Address *' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the email for the lookup"
                # Points Lookup requires the UserID, not the email address
                $Users = Get-VtUser -EmailAddress $EmailAddress -Community $Community -AuthHeader ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false ) | Select-Object -ExpandProperty UserId
                $ProcessMethod = "List"
            }
            'Transaction ID *' {
                Write-Verbose -Message "Get-VtPointTransaction: Using the TransactionID for the lookup"
                # Points Lookup requires the UserID, not the email address
                $ProcessMethod = "Show"
            }
            default {
                Write-Verbose -Message "Request all points for the lookup"
                $ProcessMethod = "List"
            }
        }
    

        if ( $ProcessMethod -eq "List ") {
            # Cycle through each transaction ID
        }
        else {
            # cycle through something else (everything, or users)
            $Uri = 'api.ashx/v2/pointtransactions.json'
            if ( $Users ) {
                # We are doing repeated transactions with provided UserID
                ForEach ( $U in $Users ) {
                    $UriParameters["UserId"] = $U
                    # Reset the index for each user
                    $UriParameters["PageIndex"] = 0
                    $TotalReturned = 0
                    do {
                        Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                        if ( $TotalReturned -and -not $SuppressProgressBar ) {
                            Write-Progress -Activity "Retrieving Point transactions from $Community [UserID: $U]" -CurrentOperation ( "Retrieving $BatchSize records of $( $PointsResponse.TotalCount )" ) -Status "[$TotalReturned/$( $PointsResponse.TotalCount )] records retrieved" -PercentComplete ( ( $TotalReturned / $PointsResponse.TotalCount ) * 100 )
                        }
                        $PointsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                        if ( $PointsResponse ) {
                            $TotalReturned += $PointsResponse.PointTransactions.Count
                            if ( $ReturnDetails ) {
                                $PointsResponse.PointTransactions
                            }
                            else {
                                $PointsResponse.PointTransactions | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        $UriParameters["PageIndex"]++
                    } while ( $TotalReturned -lt $PointsResponse.TotalCount )
                }
            }
            else {
                # We are pulling everything
                $TotalReturned = 0
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    if ( $TotalReturned -and -not $SuppressProgressBar ) {
                        Write-Progress -Activity "Retrieving Point transactions from $Community" -CurrentOperation ( "Retrieving $( $UriParameters["PageSize"]) records of $( $PointsResponse.TotalCount )" ) -Status "[$TotalReturned/$( $PointsResponse.TotalCount )] records retrieved" -PercentComplete ( ( $TotalReturned / $PointsResponse.TotalCount ) * 100 )
                    }
                    $PointsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $PointsResponse ) {
                        $TotalReturned += $PointsResponse.PointTransactions.Count
                        if ( $ReturnDetails ) {
                            $PointsResponse.PointTransactions
                        }
                        else {
                            $PointsResponse.PointTransactions | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ( $TotalReturned -lt $PointsResponse.TotalCount )
            }
        }
        # Either process kicks off the progress bar, so shut it down here
        if ( -not $SuppressProgressBar ) {
            Write-Progress -Activity "Retrieving Users from $Community" -Completed
        }


    }
    END {
        # Nothing to see here
    }
}