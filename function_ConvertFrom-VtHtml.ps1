function ConvertFrom-VtHtml {
    <#
    .Synopsis
        To be done
    .DESCRIPTION

    .EXAMPLE

    .EXAMPLE

    .EXAMPLE

    .EXAMPLE

    
        .OUTPUTS
    
        .NOTES
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'HTML Conversation with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64538/list-blog-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Html Content to Convert
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'HTML Conversation with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'HTML Conversation with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = 'HTML Conversation with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("String")]
        [string[]]$HtmlString,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'HTML Conversation with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,

        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'HTML Conversation with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,

        [Parameter(Mandatory = $true, ParameterSetName = 'HTML Conversation with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,

        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'HTML Conversation with Connection File')]
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

        # Set the URI for the conversion
        $Uri = 'api.ashx/v2/text/fromhtml.json'

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeaders = $AuthHeaders | Update-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false
    }
    PROCESS { 
        if ( $PSCmdlet.ShouldProcess( "Source", "Target" ) ) {
            ForEach ( $h in $HtmlString ) {
                $ConversionResults = Invoke-RestMethod -Uri ( $Community + $Uri ) -Method Post -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod "Put" ) -Body @{ 'html' = $h }
                if ( $ConversionResults ) {
                    $ConversionResults.TextConversion.Text
                }
                else {
                    Write-Error -Message "No conversion results for [$h]"
                }
            }
        }
    }
    END { }
}