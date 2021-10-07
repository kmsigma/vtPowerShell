function Remove-VtVtUser {
    <#
    .Synopsis
        Delete an account (completely) from a Verint/Telligent community
    .DESCRIPTION
        Delete an account (completely) from a Verint/Telligent community.  Optionally, delete all the user's content or assign to another user/userid
    .EXAMPLE
        Get-VtUser -EmailAddress "myAccountEmail@company.corp" -Community $VtCommunity -AuthHeader $VtAuthHeader | Remove-VtVtUser -Community $VtCommunity -AuthHeader $VtAuthHeader
        Find and then remove the account with email "myAccountEmail@company.corp" and will request confirmation for each deletion
    .EXAMPLE
        Remove-VtVtUser -UserId 11332, 5362, 420 -Community $VtCommunity -AuthHeader $VtAuthHeader -Confirm:$false
        Remove users with id 113322, 5362, or 420 without confirmation
    .INPUTS
        Either integters of the user id or a user object like those returned by Get-VtUser
    .NOTES
        General notes
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'User Id', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64923/delete-user-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        
        # Delete account by User Id
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'User Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64[]]$UserId,
    
        # Delete account by Username
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Username'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,
    
        # Delete account by email address
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Email Address'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$EmailAddress,
    
        # Delete all content from the user? (Do not reassign to the 'Former Member' account)
        [Parameter(
            Mandatory = $false
        )]
        [switch]$DeleteAllContent = $false,
    
        # If not deleting content, reassign to this username (If nothing is provided, then the 'Former Member' account will be used)
        [Parameter(
            Mandatory = $false
        )]
        [string]$ReassignedUsername,
    
        # If not deleting content, reassign to this user id (If nothing is provided, then the 'Former Member' account will be used)
        [Parameter(
            Mandatory = $false
        )]
        [int]$ReassignedUserId,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [string]$VtCommunity = $Global:VtCommunity,
    
        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader = $Global:VtAuthHeader
    )
    
    BEGIN {
            
        # Build up the URI parameter set 
        $UriParameters = @{}
        if ( $DeleteAllContent ) {
            $UriParameters.Add("DeleteAllContent", "true")
        }
        else {
            $UriParameters.Add("DeleteAllContent", "false")
        }
        if ( $ReassignedUserId -and $ReassignedUsername ) {
            Write-Error -Message "Cannot specify a reassigned username *and* reassigned user id." -RecommendedAction "Select one or the other"
            break
        }
        if ( $ReassignedUserId ) {
            $UriParameters.Add("ReassignedUserId", $ReassignedUserId)
        }
        if ( $ReassignedUsername ) {
            $UserId = Get-VtUser -Username $ReassignedUsername -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false | Select-Object -ExpandProperty UserId
            if ( $UserId ) {
                $UriParameters.Add("ReassignedUserId", $UserId)
            }
            else {
                Write-Error -Message "Unable to find a user Id for '$ReassignedUsername'"
                break
            }
        }
    
        # Rest-Method to use for the change
        $RestMethod = "Delete"
    }
    
    PROCESS {
    
        switch ( $pscmdlet.ParameterSetName ) {
            'User Id' {
                Write-Verbose -Message "Processing account deletion using User Ids"
                $User = Get-VtUser -UserId $UserId -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false
            }
            'Username' { 
                Write-Verbose -Message "Processing account deletion using Usernames"
                $User = Get-VtUser -Username $Username -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false 
            }
    
            'Email Address' { 
                Write-Verbose -Message "Processing account deletion using Email Addresses - must perform lookup first"
                $User = Get-VtUser -EmailAddress $EmailAddress -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false
            }
        }
        if ( $pscmdlet.ShouldProcess("$VtCommunity", "Delete User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>") ) {
            $Uri = "api.ashx/v2/users/$( $User.UserId ).json"
            $DeleteResponse = Invoke-RestMethod -Method POST -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -WarningAction SilentlyContinue )
            Write-Verbose -Message "User Deleted: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>"
            if ( $DeleteResponse ) {
                Write-Host "Account: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )> - $( $DeleteResponse.Info )" -ForegroundColor Red
            }
        }
    }
    END {
        # Nothing to see here
    }
}