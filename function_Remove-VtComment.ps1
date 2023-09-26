function Remove-VtComment {
    <#
    .Synopsis
        Remove a comment based on the Comment ID
    .DESCRIPTION
        Remove one or more comments using the API
    .EXAMPLE
        
    .EXAMPLE
        
    .OUTPUTS
        Nothing
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
        DefaultParameterSetName = 'Comment ID with Connection File',    
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64563/delete-comment-rest-endpoint',
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
            ParameterSetName = 'Comment ID with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Comment ID with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false,
            ParameterSetName = 'Comment ID with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [guid[]]$CommentId,

        [switch]$DeleteChildren,

        [Parameter()]
        [switch]$ReturnDetails,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Comment ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Comment ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("AuthHeader")]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Comment ID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Comment ID with Connection File')]
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
    
    }
    PROCESS {
        # This is where things do stuff
        ForEach ( $id in $CommentId ) {
            if ( $PSCmdlet.ShouldProcess("$Community", "Delete Comment ID: $id$( if ( $DeleteChildren ) { " (and child comments)" } ) ") ) {
                    
                $Uri = "api.ashx/v2/comments/$( $id ).json"
                if ( $DeleteChildren ) {
                    $Uri += "?DeleteChildren=true"
                }
                # Method: Post
                # Rest-Method: Delete
                try {
                    $RemovePointsResponse = Invoke-RestMethod -Method Post -Uri ( $Community + $Uri ) -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -Verbose:$false )
                    if ( $RemovePointsResponse ) {
                        Write-Verbose -Message "Comment ID #$id removed"
                    }
                }
                catch {
                    Write-Error -Message "Error purging Comment #$id"
                }
            }
        }
    
    }
    END {
        # nothing here
    }
}
    