function Test-VtConnection {
    <#
.Synopsis
    Tests the connection with the provided credentials to a community
.DESCRIPTION

.EXAMPLE

.EXAMPLE

.EXAMPLE

.EXAMPLE

.INPUTS

.OUTPUTS

.NOTES

.COMPONENT
    TBD
.ROLE
    TBD
.LINK
    Online REST API Documentation: 
#>
    [CmdletBinding(
        DefaultParameterSetName = 'Profile File',
        SupportsShouldProcess = $true, 
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/',
        ConfirmImpact = 'Low'
    )]
    Param (

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            ParameterSetName = 'Authentication Header',
            Position = 0
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity = $Global:VtCommunity,
    
        # Authentication Header for the community
        [Parameter(
            ParameterSetName = 'Authentication Header',
            Position = 1
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader = $Global:VtAuthHeader,

        [Parameter(
            ParameterSetName = 'Connection Profile',
            Position = 0
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$ConnectionProfile,

        # File holding credentials.  By default is stores in your user profile \.vtCommunity\vtCredentials.json
        [Parameter(
            ParameterSetName = 'Profile File',
            Position = 0)]
        [Alias('Path')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )

    )
    BEGIN { 
        $JsonDepth = 2
        $Uri = 'api.ashx/v2/groups/root.json'
    }

    PROCESS {

        switch ( $PSCmdlet.ParameterSetName ) {
            'Profile File' {
                Write-Verbose -Message "Extracting Community URL and Authentication Headers from '$ProfilePath'"
                try {
                    $VtConnection = Get-Content -Path $ProfilePath | ConvertFrom-Json -Depth $JsonDepth
                    $Community = $VtConnection.Community
                    # Check to see if the VtAuthHeader is empty
                    $AuthHeader = @{ }
                    $VtConnection.Authentication.PSObject.Properties | ForEach-Object { $AuthHeader[$_.Name] = $_.Value }
                }
                catch {
                    $_
                }
            }
            'Connection Profile' {
                Write-Verbose -Message "Extracing Community URL and Authentication headers from Connection Profile"
                $Community  = $ConnectionProfile.Community
                $AuthHeader = $ConnectionProfile.Authentication
            }
        
            'Authentication Header' {
                Write-Verbose -Message "Extracting Community URL and Authentication Headers from Parameters"
                $Community = $VtCommunity
                $Authheader = $VtAuthHeader
            }
        }

        if ( $PSCmdlet.ShouldProcess("$Community", "Test Connection") ) {
            try {
                Write-Verbose -Message "Attemtping to connect to '$Community'"
                Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeader | Out-Null
                # We 'Out-Null' this because we actually don't need anything.
                Write-Verbose -Message "Connected to '$Community' successfully!"
                $true
            }
            catch {
                $_
                Write-Error -Message "Connection to '$Community' failed!" -ErrorAction Stop
            }
        }
    }

    END {
        # Nothing to see here
    }
}