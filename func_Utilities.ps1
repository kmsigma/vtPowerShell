<#
.Synopsis
    Convert a hashtable to a query string
.DESCRIPTION
    Converts a passed hashtable to a query string based on the key:value pairs
.OUTPUTS
    string object in the form of "key1=value1&key2=value2..."  Does not include the preceeding '?' required for many URI calls
.NOTES
    This is bascially the reverse of [System.Web.HttpUtility]::ParseQueryString
#>
function ConvertTo-QueryString {
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
        $ParameterStrings += "$( $_.Key )=$( $_.Value )"
    }
    $ParameterStrings -join "&"
}

<#
.Synopsis
    Strips HTML Content from a string
.DESCRIPTION
    Removes all tags and decodes any HTML from a string
.OUTPUTS
    string containing only the plain text of the input string
#>
function ConvertFrom-HtmlString {
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
    
    begin {
        
    }
    
    process {
        [System.Web.HttpUtility]::HtmlDecode( ( $HtmlString -replace "<[^>]*?>|<[^>]*>", "" ) )
    }
    
    end {
        
    }
}