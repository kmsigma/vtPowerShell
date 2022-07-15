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
.NOTES
    This is included here just to have a reference for it.  It'll typically be defined 'internally' within the `begin` blocks of functions
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


<#
.Synopsis
    Calcuate the hash for a string
.DESCRIPTION
    Calcuate the hash for a string
.EXAMPLE
    Get-StringHash -String "I need this encoded in SHA256"

    Algorithm Hash                                                             String
    --------- ----                                                             ------
    SHA256    7c339cc3454632a82887dba8d2fe5f4d09d0cf4634b1da4661b821ae0d5c496f I need this encoded in SHA256

    Encodes a single string using the default algorithm (MD5)
.EXAMPLE
     "Can We Encode in SHA512?" | Get-StringHash -Algorithm SHA512

     Algorithm Hash                                                                                                                             String
     --------- ----                                                                                                                             ------
     SHA512    dad33df67684440440b9e5f0ce93b6518be876c3a01c9443cafbc5f1b434837b320eaaaeed88db73f5b624fd12b7b128a5383ecc1da066b29a643c7c8fed836f Can We Encode in SHA512?

     Pipeline example encoding to SHA512
.EXAMPLE
     "Can We Encode in SHA1?", "Do this one as well please." | Get-StringHash -Algorithm SHA1    

     Algorithm Hash                                     String
     --------- ----                                     ------
     SHA1      9c8c3ab1869f22a96efa4be14484d8c36ee5b72c Can We Encode in SHA1?
     SHA1      5ba38be8160fc9e57ac1e13992ab97535fa6a39f Do this one as well please.

     Encodes multiple strings (from the pipeline) using the prescribed algorithm
.INPUTS
    string, or an array of strings
.OUTPUTS
    Custom object with algorithm, hashed value, and string
.NOTES
    Inspired by https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/generating-md5-hashes-from-text   
#>
Function Get-StringHash 
{
    param
    (
        # string to encode
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$String,
        
        [ValidateSet('MD5', 'SHA', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        $Algorithm = "SHA256" # SHA256 is the default to match the Get-FileHash action
    )

    begin {
        $HashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    }

    process {
        ForEach ( $S in $String ) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($S)
            $StringBuilder = New-Object System.Text.StringBuilder 
            $HashAlgorithm.ComputeHash($bytes) | ForEach-Object { 
                $StringBuilder.Append($_.ToString("x2")) | Out-Null
            } 
  
            [PSCustomObject]@{
                Algorithm = $Algorithm
                Hash = $StringBuilder.ToString() 
                String = $S
            }
            
        }
    }

    end {
        # nothing to see here
    }
}