function Get-VtAuthHeader {
    <#
    .Synopsis
        Get the necessary authentication header for Verint | Telligent Community
    .DESCRIPTION
        Using the username and API key, we'll build an authentication header required to access Verint | Telligent Communities.
        Note this creation does NOT validate that the authentication works - it just builds the header.
    .EXAMPLE
        Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    
        Name                           Value
        ----                           -----
        Rest-User-Token                bG1[omitted]dtYQ==
    .INPUTS
        Username and API key.  Your API key is distinct, but as powerful as your password.  Guard it similarly.
        API Keys can be obtained from https://community.domain.here/user/myapikeys
    .OUTPUTS
        Hashtable with necessary headers
    .NOTES
        https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests
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
        HelpUri = 'https://community.telligent.com/community/10/w/developer-training/53138/authentication#Using_an_API_Key_and_username_to_authenticate_REST_requests',
        ConfirmImpact = 'Medium')
    ]
    [Alias("New-VtAuthHeader")]
    param (
        # Username for the call to the REST endpoint
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        [Alias("User")] 
        [string]$Username,
    
        # API Key for the associated user
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 1)]
        [Alias("Key")] 
        [string]$ApiKey
    )
    
    begin {
        # Nothing here
    }
    
    process {
        if ( $pscmdlet.ShouldProcess("", "Generate Authentication Header") ) {
            $Base64Key = [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes( "$( $ApiKey ):$( $Username )" ) )
            # Return the header with the token only
            @{
                'Rest-User-Token' = $Base64Key
            }
        }
    }
    
    end {
        #Nothing to see here        
    }
}