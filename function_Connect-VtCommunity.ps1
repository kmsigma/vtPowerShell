function Connect-VtCommunity {
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

.COMPONENT
    TBD
.ROLE
    TBD
.LINK
    Online REST API Documentation: 
#>
    [CmdletBinding(
        DefaultParameterSetName = 'Authehtication Header',
        SupportsShouldProcess = $true, 
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/',
        ConfirmImpact = 'Low'
    )]
    Param (

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Authentication Header',
            Position = 0
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Username/API Key',
            Position = 0
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
    
        # Authentication Header for the community
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Authentication Header',
            Position = 1
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,

        # Username for Connection to Community
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Username/API Key',
            Position = 1
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        # API Key for Connection to Community
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Username/API Key',
            Position = 2
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(20, 20)]
        [string]$ApiKey,

        # Should we store the credentials as global variables
        [Parameter(ParameterSetName = 'Authentication Header')]
        [Parameter(ParameterSetName = 'Username/API Key')]
        [switch]$StoreAsGlobal
    )
    BEGIN { 
        $Uri = 'api.ashx/v2/groups/root.json'
    }
    PROCESS { 
        if ( $PSCmdlet.ParameterSetName -eq 'Username/API Key' ) {
            $VtAuthHeader = Get-VtAuthHeader -Username $Username -ApiKey $ApiKey 
        }

        if ( $PSCmdlet.ShouldProcess("Vertint/Telligent Community", "Build connection variables to use") ) {
            Write-Verbose -Message "Connecting to $VtCommunity"
            try {
                $ConnectionResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri ) -Headers $VtAuthHeader
            }
            catch {
                $_
            }
            finally {
                if ( $ConnectionResponse ) {
                    Write-Verbose -Message "Connected successfully!"
                    if ( $StoreAsGlobal ) {
                        Write-Verbose -Message "Storing `$VtCommunity and `$VtAuthHeader"
                        $Global:VtCommunity = $VtCommunity
                        $Global:VtAuthHeader = $VtAuthHeader
                    }
                }
                else {
                    Write-Warning -Message "Unable to connect to the community at '$VtCommunity'"
                }

            }
        }
    }
    END {
        # Nothing to see here
    }
}