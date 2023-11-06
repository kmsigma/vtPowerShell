#region Helper Output
<#
$Output = @'
----------------------------------------------------------------------------------------------------
Each call with a Vertint/Telligent Function requires the Community's URL (VtCommunity) and an
authentication packet passed as the header (VtAuthHeader) to the REST endpoint.

    The Community URL must be in the format:
        http(s)://sitename.domain.local/
           ^                           ^
    Protocol (http/https)              |
                                Trailing Slash

PS > Get-VtUser -Username "MyUsername" `
        -VtCommunity 'https://myCommunityName.telligenthosting.com/' `
        -VtAuthHeader @{ 'Rest-User-Token' = 'TokenizedString' }

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
For ease of use, you can globally define a VtCommunity and VtAuthHeader and they will be available
for any function called within that session.

PS > $Global:VtAuthHeader = New-VtAuthHeader -Username "myUsername" -ApiKey '1234567890abcdefghi'
PS > $Global:VtCommunity  = 'https://myCommunityName.telligenthosting.com/'
# Further calls *inherit* the community and authentication
PS > Get-VtUser -Username "MyUsername"
----------------------------------------------------------------------------------------------------
'@
Write-Host -ForegroundColor Yellow $Output
Remove-Variable -Name Output -ErrorAction SilentlyContinue
#endregion Helper Output
#>

#region HTML Utility Functions
function ConvertTo-QueryString {
    <#
.Synopsis
    Convert a hashtable to a query string
.DESCRIPTION
    Converts a passed hashtable to a query string based on the key:value pairs.
.EXAMPLE
    $UriParameters = @{}
    PS > $UriParameters.Add("PageSize", 20)
    PS > $UriParameters.Add("PageIndex", 1)

    PS > $UriParameters

Name                           Value
----                           -----
PageSize                       20
PageIndex                      1

    PS > $UriParameters | ConvertTo-QueryString

    PageSize=20&PageIndex=1
.OUTPUTS
    string object in the form of "key1=value1&key2=value2..."  Does not include the preceeding '?' required for many URI calls
.NOTES
    This is bascially the reverse of [System.Web.HttpUtility]::ParseQueryString

    This is included here just to have a reference for it.  It'll typically be defined 'internally' within the `begin` blocks of functions
#>
    param (
        # Hashtable containing segmented query details
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$Parameters
    )
    $ParameterStrings = @()
    $Parameters.GetEnumerator() | ForEach-Object {
        $ParameterStrings += "$( $_.Key )=$( [System.Web.HttpUtility]::UrlEncode( $_.Value ) )"
    }
    $ParameterStrings -join "&"
}

function ConvertFrom-HtmlString {
    <#
.Synopsis
    Strips HTML Content from a string
.DESCRIPTION
    Removes all tags and decodes any HTML from a string
.OUTPUTS
    string containing only the plain text of the input string
.NOTES
    This is included here just to have a reference for it.  It'll typically be defined 'internally' within the `begin` blocks of functions
#>
    [CmdletBinding()]
    param (
        # string with HTML content
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$HtmlString
    )
    
    BEGIN {
        
    }
    
    PROCESS {
        [System.Web.HttpUtility]::HtmlDecode( ( ( $HtmlString -replace "<br />", "`n" ) -replace "<[^>]*?>|<[^>]*>", "" ) )
    }
    
    END {
        
    }
}
#endregion HTML Utility Functions

#Export-ModuleMember -Function ConvertTo-QueryString
#Export-ModuleMember -Function ConvertFrom-VtHtmlString