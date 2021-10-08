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
    BEGIN {
    
        $RestMethod = "Delete"
    
    }
    PROCESS {
        # This is where things do stuff
        ForEach ( $id in $TransactionId ) {
            if ( Get-VtPointTransaction -TransactionId $Id -Community $VtCommunity -AuthHeader ( $VtAuthHeader | Set-VtAuthHeader -RestMethod Get -WhatIf:$false -Verbose:$false ) -Verbose:$false ) {
                if ( $PSCmdlet.ShouldProcess("$VtCommunity", "Delete Point Transaction $id") ) {
                    
                    $Uri = "api.ashx/v2/pointtransaction/$( $id ).json"
                    # Method: Post
                    # Rest-Method: Delete
                    try {
                        $RemovePointsResponse = Invoke-RestMethod -Method Post -Uri ( $Community + $Uri ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
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
    END {
        # nothing here
    }
}
    