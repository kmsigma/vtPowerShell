function Remove-VtPointTransaction {
    <#
    .Synopsis
        Remove a Point Transaction based on the Transaction ID
    .DESCRIPTION
        Remove one or more point transactions using the API
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
    [CmdletBinding(
        DefaultParameterSetName = 'Transaction ID with Connection File',    
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
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Transaction ID with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Transaction ID with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Transaction ID with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64[]]$TransactionId,

        [Parameter()]
        [switch]$ReturnDetails,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("AuthHeader")]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Transaction ID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Transaction ID with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )
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

        $RestMethod = "Delete"
        $HttpMethod = "Post"
    
    }
    PROCESS {
        # This is where things do stuff
        ForEach ( $id in $TransactionId ) {
            #if ( Get-VtPointTransaction -TransactionId $Id -Community $Community -AuthHeader ( $AuthHeaders | Update-VtAuthHeader -RestMethod Get -WhatIf:$false -Verbose:$false ) -Verbose:$false ) {
                if ( $PSCmdlet.ShouldProcess("$Community", "Delete Point Transaction $id") ) {
                    
                    $Uri = "api.ashx/v2/pointtransaction/$( $id ).json"
                    # Method: Post
                    # Rest-Method: Delete
                    try {
                        $RemovePointsResponse = Invoke-RestMethod -Method $HttpMethod -Uri ( $Community + $Uri ) -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                        if ( $RemovePointsResponse ) {
                            Write-Verbose -Message "Points Transaction #$id removed"
                        }
                    }
                    catch {
                        Write-Error -Message "Error purging Points Transaction #$id"
                    }
                }
                    
            #}
            #else {
            #    Write-Verbose -Message "No points transaction found matching #$id.  Unable to delete."
            #}
        }
    
    }
    END {
        # nothing here
    }
}
    