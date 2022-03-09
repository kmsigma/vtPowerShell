function Remove-VtUser {
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
        DefaultParameterSetName = 'Delete User by User ID with Connection File', 
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
            ParameterSetName = 'Delete User by User ID with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Delete User by User ID with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Delete User by User ID with Connection File'
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
            ParameterSetName = 'Delete User by Username with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Delete User by Username with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Delete User by Username with Connection File'
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
            ParameterSetName = 'Delete User by Email Address with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Delete User by Email Address with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Delete User by Email Address with Connection File'
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
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by User ID with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by Email Address with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
                
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by User ID with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by Email Address with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by User ID with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by Username with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Delete User by Email Address with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
            
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Delete User by User ID with Connection File')]
        [Parameter(ParameterSetName = 'Delete User by Username with Connection File')]
        [Parameter(ParameterSetName = 'Delete User by Email Address with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )
    )
    
    BEGIN {

        switch -wildcard ( $PSCmdlet.ParameterSetName ) {

            '* Connection File' {
                Write-Verbose -Message "Getting connection information from Connection File ($ProfilePath)"
                $VtConnection = Get-Content -Path $ProfilePath | ConvertFrom-Json
                $Community = $VtConnection.Community
                # Check to see if the VtAuthHeader is empty
                $AuthHeaders = @{ }
                $VtConnection.Authentication.PSObject.Properties | ForEach-Object { $AuthHeaders[$_.Name] = $_.Value }
            }
            '* Connection Profile' {
                Write-Verbose -Message "Getting connection information from Connection Profile"
                $Community = $Connection.Community
                $AuthHeaders = $Connection.Authentication
            }
            '* Authentication Header' {
                Write-Verbose -Message "Getting connection information from Parameters"
                $Community = $VtCommunity
                $AuthHeaders = $VtAuthHeader
            }
        }
            
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
            $UserId = Get-VtUser -Username $ReassignedUsername -Community $Community -AuthHeader $AuthHeaders -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false | Select-Object -ExpandProperty UserId
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
    
        switch -wildcard ( $PSCmdlet.ParameterSetName ) {
            'Delete User by User ID *' {
                Write-Verbose -Message "Processing account deletion using User Ids"
                $User = Get-VtUser -UserId $UserId -VtCommunity $Community -VtAuthHeader $AuthHeaders -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false
            }
            'Delete User by Username *' { 
                Write-Verbose -Message "Processing account deletion using Usernames"
                $User = Get-VtUser -Username $Username -VtCommunity $Community -VtAuthHeader $AuthHeaders -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false 
            }
    
            'Delete User by Email Address ' { 
                Write-Verbose -Message "Processing account deletion using Email Addresses - must perform lookup first"
                $User = Get-VtUser -EmailAddress $EmailAddress -Community $VtCommunity -VtAuthHeader $AuthHeaders -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false
            }
        }
        if ( $PSCmdlet.ShouldProcess("$Community", "Delete User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>") ) {
            $Uri = "api.ashx/v2/users/$( $User.UserId ).json"
            $DeleteResponse = Invoke-RestMethod -Method POST -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -WarningAction SilentlyContinue )
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