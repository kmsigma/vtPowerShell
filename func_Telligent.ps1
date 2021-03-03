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
.EXAMPLE
   Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns" -ReadWrite

   Name                           Value
   ----                           -----
   Rest-Method                    PUT
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
    [CmdletBinding()]
    param (
        # Username for the call to the REST endpoint
        [Parameter(Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true, 
        ValueFromRemainingArguments=$false, 
        Position=0)]
        [Alias("User")] 
        [string]$Username,

        # API Key for the associated user
        [Parameter(Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true, 
        ValueFromRemainingArguments=$false, 
        Position=1)]
        [Alias("Key")] 
        [string]$ApiKey,

        # Do we want this as a read-write or a read-only (default) header
        [Parameter(Mandatory=$false,
        ValueFromPipeline=$false,
        ValueFromPipelineByPropertyName=$false,
        ValueFromRemainingArguments=$false,
        Position=2)]
        [switch]$ReadWrite=$false
    )
    
    begin {
        # Nothing here
    }
    
    process {
        $Base64Key = [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes( "$( $ApiKey ):$( $Username )" ) )
        if ( $ReadWrite ){
            # Return the header with token and the put key
            @{
                'Rest-User-Token' = $Base64Key;
                'Rest-Method' = 'PUT';
            }
        } else {
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
Function used to request all "things."  Currently the API restricts to 100 elements, so this uses pagination to do things.
#>
function Get-VtAll
{
   [CmdletBinding(
         PositionalBinding=$false,
         ConfirmImpact='Medium')]

   Param
   (
         # Uri to Call
         [Parameter(
            Mandatory=$true, 
            Position=1)]
         [string]$Uri,
         # Authentication header to use
         [Parameter(
            Mandatory=$true, 
            Position=2)]
         [Alias("Headers")]
         [hashtable]$VtAuthHeader
   )

   # Determine the Item Type (groups, ideas, etc.) from the URI
   $ItemType = ( Get-Culture ).TextInfo.ToTitleCase( ( ( [System.Uri]$Uri ).Segments[-1] ).Split(".")[0].ToLower() )
   
   # Since we want to return the correct item (if singular) or multiple (if plural), we need the 'name' of the thing and its pluralization
      # Check to see if it ends with an "s"
   if ( $ItemType -match 's$' ) {
      # ItemType is plural ('groups')
      $ItemTypePlural = $ItemType
      # Remove the final characer (the "s") for singular
      $ItemType = $ItemTypePlural.Remove($ItemTypePlural.Length - 1, 1 )
   } else {
      # ItemType is singular ('group')
      # Just add an 's' to make it plural
      $ItemTypePlural = $ItemType + "s"
   }

   Write-Verbose -Message "Making call to $Uri"
   $Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $VtAuthHeader
   if ( $Response ) {
         if ( $Response | Get-Member -Name $ItemType -ErrorAction SilentlyContinue ) {
            # Single Response Only - just return the thing (group, idea, challenge, whatever)
            Write-Verbose "Single entry only for '$ItemType'"
            $Response.$ItemType
         } else { # implies '$Response.Things' (plural) exists
            # Multiple Responses
            $CurrentCount = 0
            $CurrentCount += $Response.$ItemTypePlural.Count
            $Response.$ItemTypePlural
            $NextIndex = 1
            while ( $CurrentCount -lt $Response.TotalCount ) {
               Write-Verbose "Current Count/Total Count/Index: $CurrentCount / $( $Response.TotalCount ) / $( $NextIndex - 1 )"
               Write-Progress -Activity "Querying for $ItemTypePlural" -CurrentOperation "Making request #$( $NextIndex ) of $( [Math]::Ceiling($Response.TotalCount / 20) )" -PercentComplete ( ( $CurrentCount / $Response.TotalCount ) * 100 )
               if ( $Uri -like "*.json?*" ) {
                  # Need to add with ampersand and not question mark
                  $NextCallUri = "$( $Uri )&PageIndex=$( $NextIndex )"
               } else {
                  # Need to add with question mark
                  $NextCallUri = "$( $Uri )?PageIndex=$( $NextIndex )"
                  
               }
               Write-Progress -Activity "Querying for $ItemTypePlural" -CurrentOperation "Calling $NextCallUri" -PercentComplete ( ( $CurrentCount / $Response.TotalCount ) * 100 )
               $Response = Invoke-RestMethod -Uri $NextCallUri -Method Get -Headers $VtAuthHeader
               $CurrentCount += $Response.$ItemTypePlural.Count
               $Response.$ItemTypePlural
               $NextIndex++
            }
            Write-Progress -Activity "Querying for $ItemTypePlural" -Completed
         }
   } else {
      Write-Error -Message "No Response received from $Uri"
   }
   
}