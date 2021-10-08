function Set-VtAuthHeader {
    <#
    .Synopsis
        Update an existing authentication header for Verint | Telligent Community
    .DESCRIPTION
        Add an optional REST Method for use with Update and Delete type calls
    .EXAMPLE
        $VtAuthHeader | Set-VtAuthHeader -Method "Delete"
    
        Name                           Value
        ----                           -----
        Rest-User-Token                bG1[omitted]dtYQ==
        Rest-Method                    DELETE
    
        Take an existing header and add "Delete" as the rest method
    
    .EXAMPLE
        $VtAuthHeader
    
        Name                           Value
        ----                           -----
        Rest-User-Token                bG1[omitted]dtYQ==
        Rest-Method                    DELETE
    
        PS > $VtAuthHeader | Set-VtAuthHeader -Method "Get"
    
        Name                           Value
        ----                           -----
        Rest-User-Token                bG1[omitted]dtYQ==
    
        "Get" style queries do not require a 'Rest-Mehod' in the header, so it is removed.  This is the same functionality as passing no RestMethod parameter.
    
    .EXAMPLE
        $VtAuthHeader
    
        Name                           Value
        ----                           -----
        Rest-User-Token                bG1[omitted]dtYQ==
    
        PS > $DeleteHeader = $VtAuthHeader | Set-VtAuthHeader -Method "Delete"
        PS > $DeleteHeader
    
        Name                           Value
        ----                           -----
        Rest-User-Token                bG1[omitted]dtYQ==
        Rest-Method                    DELETE
    
        PS > $UpdateHeader = $VtAuthHeader | Set-VtAuthHeader -Method "Put"
        PS > $UpdateHeader
    
        Name                           Value
        ----                           -----
        Rest-User-Token                bG1[omitted]dtYQ==
        Rest-Method                    PUT
    
        Create two new headers ($DeleteHeader and $UpdateHeader) based on the original header ($VtAuthHeader)
    
    .INPUTS
        Existing Authentication Header (as Hashtable)
    .OUTPUTS
        Hashtable with necessary headers
    .NOTES
        https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests
    
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests',
        ConfirmImpact = 'Medium')
    ]
    param (
        # Existing authentication header
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        [Alias("Header")] 
        [System.Collections.Hashtable[]]$VtAuthHeader,
    
        # Rest-Method to invoke
        [Parameter(Mandatory = $false, 
            Position = 1)]
        [ValidateSet("Get", "Put", "Delete")] # There may be others
        [Alias("Method")] 
        [string]$RestMethod = "Get"
    )
    
    begin {
        # Nothing to see here
    }
    
    process {
        # Support multiple tokens (this should be rare)
        ForEach ( $h in $VtAuthHeader ) {
            if ( $h["Rest-User-Token"] ) {
                if ( $PSCmdlet.ShouldProcess("Header with 'Rest-User-Token: $( $h["Rest-User-Token"] )'", "Update Rest-Method to $RestMethod type") ) {
                    if ( $RestMethod -ne "Get" ) {
                        # Add a Rest-Method to the Token
                        $h["Rest-Method"] = $RestMethod.ToUpper()
                    }
                    else {
                        # 'Get' does not require the additional Rest-Method, so we'll remove it
                        if ( $h["Rest-Method"] ) {
                            $h.Remove("Rest-Method")
                        }
                    }
                }
                $h
            }
            else {
                Write-Error -Message "Header does not contain the 'Rest-User-Token'" -RecommendedAction "Please generate a valid header with ConvertTo-VtAuthHeader"
            }
        }
    }
    
    end {
        #Nothing to see here        
    }
}