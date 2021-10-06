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
function Get-VtAuthHeader {
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
function Set-VtAuthHeader {
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
            if ( $pscmdlet.ShouldProcess("Header with 'Rest-User-Token: $( $h["Rest-User-Token"] )'", "Update Rest-Method to $RestMethod type") ) {
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
            Write-Error -Message "Header does not contain the 'Rest-User-Token'" -RecommendedAction "Please generate a valid header with Get-VtAuthHeader"
         }
      }
   }

   end {
      #Nothing to see here        
   }
}
