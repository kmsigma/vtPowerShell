function Set-VtUser {
    <#
    .Synopsis
        Changes setting for a Verint/Telligent user account on your community
    .DESCRIPTION
        Change settings (Username, Email Address, Account Status, Moderation Status, is email enabled?) for a Verint/Telligent user account
    .EXAMPLE
        $VtCommunity = 'https://community.domain.local/'
        PS > $VtAuthHeader      = @{ 'Test-User-Token' = 'bG1[REDACTED]tYQ==' }
        PS > Set-VtUser -UserId 112233 -NewUsername 'MyNewUsername' -Community $VtCommunity -AuthHeader $VtAuthHeader
        
        Set a new username for an account
    .EXAMPLE
        $VtCommunity = 'https://community.domain.local/'
        PS > $VtAuthHeader      = @{ 'Test-User-Token' = 'bG1[REDACTED]tYQ==' }
    
        PS > $UserToUpdate = Get-VtUser -Username 'CurrentlyBannedUser' -Community $VtCommunity -AuthHeader $VtAuthHeader
        -- Ban the user --
        PS > $UserToUpdate | Set-VtUser -AccountStatus Banned -Community $VtCommunity -AuthHeader $VtAuthHeader
        -- 'Un'-Ban the user --
        PS > $UserToUpdate | Set-VtUser -AccountStatus Approved -ModerationLevel Unmoderated -EmailBlocked:$false -Community $VtCommunity -AuthHeader $VtAuthHeader -PassThru
    
            UserId           : 181222
            Username         : CurrentlyBannedUser
            EmailAddress     : banned@New-Vtemail.com
            Status           : Approved
            ModerationStatus : Unmoderated
            IsIgnored        : True
            CurrentPresence  : Offline
            JoinDate         : 11/1/2016 12:23:01 PM
            LastLogin        : 2/22/2021 2:38:29 PM
            LastVisit        : 2/22/2021 2:58:57 PM
            LifetimePoints   : 2954
            EmailEnabled     : True
    .INPUTS
        Accepts either a user id (because that is unique) or a User Object (as is returned from Get-VtUser)
    .OUTPUTS
        No outputs unless using -PassThru which returns a PowerShell Custom Object with the user account details after updating
    .NOTES
        I haven't been able to test every single feature, but the logic should hold
    #>
    [CmdletBinding(DefaultParameterSetName = 'User Id', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64926/update-user-rest-endpoint',
        ConfirmImpact = 'High')]
    Param
    (
    
        # The user id on which to operate.  Because this operation can change the username and email address, neither should be considered authorotative
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64[]]$UserId,
    
        # New Username for the Account
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$NewUsername,
    
        # Updated email address for the account
        [Parameter(Mandatory = $false)]
        [ValidatePattern("(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|`"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*`")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])")]
        # Regex for email:
        # (?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])
        [string]$NewEmailAddress,
    
        # New status for the account: ApprovalPending, Approved, Banned, or Disapproved
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet('ApprovalPending', 'Approved', 'Banned', 'Disapproved')]
        [string]$AccountStatus,
    
        # if the account status is updated to 'Banned', when are they allowed back - defaults to 1 year from now
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [datetime]$BannedUntil = ( Get-VtDate ).AddYears(1),
    
        # the reason the user was banned
        [Parameter(Mandatory = $false)]
        [ValidateSet('Profanity', 'Advertising', 'Spam', 'Aggressive', 'BadUsername', 'BadSignature', 'BanDodging', 'Other')]
        [string]$BanReason = 'Other',
    
        # New Moderation Level for the account: Unmoderated, Moderated
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet('Unmoderated', 'Moderated')]
        [string]$ModerationLevel,
    
        # Is the account blocked from receiving email?
        [Parameter(Mandatory = $false)]
        [switch]$EmailBlocked = $false,
            
        # Does the user need to accept the terms of service?
        [Parameter(Mandatory = $false)]
        [switch]$RequiresTermsOfServiceAcceptance,
    
        # Do we want to ignore the user's content?
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreUser,
    
        # Do you want to return the new user object back to the original call?
        [Parameter(Mandatory = $false)]
        [switch]$PassThru = $false,
    
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
    
        # Rest-Method to use for the change
        $RestMethod = "Put"
    
    
        # Parameters to pass to the URI
        $UriParameters = @{}
    
        if ( $AccountStatus ) {
            $UriParameters.Add("AccountStatus", $AccountStatus )
        }
        if ( $ModerationLevel ) {
            $UriParameters.Add("ModerationLevel", $ModerationLevel )
        }
        if ( $RequiresTermsOfServiceAcceptance ) {
            $UriParameters.Add("AcceptTermsOfService", ( -not $RequiresTermsOfServiceAcceptance ).ToString() )
        }
        if ( $EmailBlocked ) {
            $UriParameters.Add("ReceiveEmails", 'false')
        }
        else {
            $UriParameters.Add("ReceiveEmails", 'true')
        }
        if ( $IgnoreUser ) {
            $UriParameters.Add("IsIgnored", 'true')
        }
    
        # Add Banned Until date (and other things) only if the status is been defined as 'Banned'
        if ( $UriParameters["AccountStatus"] -eq "Banned" ) {
            $UriParameters.Add("BannedUntil", $BannedUntil )
            $UriParameters.Add("BanReason", $BanReason)
            $UriParameters["ModerationLevel"] = 'Moderated'
            $UriParameters["AcceptTermsOfService"] = 'false'
            $UriParameters["ForceLogin"] = 'true'
        }
    
    }
    PROCESS {
            
        if ( $NewUsername ) {
            # Check to see if the username already exists in the community
            $CheckUser = Get-VtUser -Username $NewUsername -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if ( -not ( $CheckUser ) ) {
                $UriParameters.Add("Username", $NewUsername)
            }
            # check to see if this username matches the current operating user
            elseif ( -not ( Compare-Object -ReferenceObject $PsItem -DifferenceObject $CheckUser ) ) {
                Write-Error -Message "The current user is already using this username."
            }
            else {
                Write-Error -Message "Another user with the username '$NewUsername' was detected.  Cannot complete." -RecommendedAction "Please choose another username or delete the conflicing user"
                break
            }
        }
        if ( $NewEmailAddress ) {
            # Check to see if the email address already exists in the community
            $CheckUser = Get-VtUser -EmailAddress $NewEmailAddress -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -WarningAction SilentlyContinue
            if ( -not ( $CheckUser ) ) {
                $UriParameters.Add("PrivateEmail", $NewEmailAddress)
            }
            # check to see if this email matches the current operating user
            elseif ( -not ( Compare-Object -ReferenceObject $PsItem -DifferenceObject $CheckUser ) ) {
                Write-Warning -Message "The current user is already using this email address."
            }
            else {
                Write-Error -Message "Another user with the email address '$NewEmailAddress' was detected.  Cannot complete." -RecommendedAction "Please choose another email address or delete the conflicing user"
                break
            }
        }
            
        ForEach ( $U in $UserId ) {
            $User = Get-VtUser -UserId $U -Community $VtCommunity -AuthHeader $VtAuthHeader -WhatIf:$false -Verbose:$false | Select-Object -ExcludeProperty MentionText
            if ( $UriParameters.Keys.Count ) {
                if ( $User ) {
                    $Uri = "api.ashx/v2/users/$( $User.UserId ).json"
                    # Imples that we found a user on which to operate
                    if ( $PSCmdlet.ShouldProcess($VtCommunity, "Update User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>") ) {
                        # Execute the Update
                        Write-Verbose -Message "Updating User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>"
                        $UpdateResponse = Invoke-RestMethod -Method Post -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod ) -Verbose:$false
                        if ( $UpdateResponse ) {
                            $UserObject = [PSCustomObject]@{
                                UserId           = $UpdateResponse.User.id
                                Username         = $UpdateResponse.User.Username
                                EmailAddress     = $UpdateResponse.User.PrivateEmail
                                Status           = $UpdateResponse.User.AccountStatus
                                ModerationStatus = $UpdateResponse.User.ModerationLevel
                                IsIgnored        = $UpdateResponse.User.IsIgnored -eq "true"
                                CurrentPresence  = $UpdateResponse.User.Presence
                                JoinDate         = $UpdateResponse.User.JoinDate
                                LastLogin        = $UpdateResponse.User.LastLoginDate
                                LastVisit        = $UpdateResponse.User.LastVisitedDate
                                LifetimePoints   = $UpdateResponse.User.Points
                                EmailEnabled     = $UpdateResponse.User.ReceiveEmails -eq "true"
                            }
                            
                            if ( $User -match $UserObject ) {
                                Write-Warning -Message "Updates were sent, but no changes were detected on the user account."
                            }
    
                            if ( $PassThru ) {
                                $UserObject
                            }
                        }
                    }
                    
                }
                else {
                    Write-Warning -Message "No user found."
                }
            }
            else {
                Write-Error -Message "No changes were requested for user with ID: $( $User.UserId )" -RecommendedAction "Include a parameter to make updates"
            }
        }
    }
    
    END {
        # Nothing here
    }
}