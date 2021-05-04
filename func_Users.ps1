<#
.Synopsis
    Get a user (or more information) from a Telligent Community
.DESCRIPTION
    Query the REST endpoint to get user account information.
.EXAMPLE
    Get-VtUser -Username "JoeSmith" -CommunityDomain "https://mycommunity.teligenthosted.net" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }
    PS > Get-VtUser -UserId 112233 -CommunityDomain "https://mycommunity.teligenthosted.net" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }
    PS > Get-VtUser -EmailAddress "joseph.smith@company.com" -CommunityDomain "https://mycommunity.teligenthosted.net" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }

        Return a single user based on the their username, email address, or id
    
        --- All of the above returns the same output as below ---

    UserId           : 112233
    Username         : JoeSmith
    EmailAddress     : joseph.smith@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    CurrentPresence  : Offline
    JoinDate         : 3/14/2020 9:19:44 AM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 475

.EXAMPLE
    $Global:CommunityDomain = "https://mycommunity.telligenthosted.net"
    PS > $Global:AuthHeader       = Get-VtAuthHeader -Username "MyAdminAccount" -ApiKey "MyAdminApiKey"
    PS > Get-VtUser -Username "JoeSmith"
    
    UserId           : 112233
    Username         : JoeSmith
    EmailAddress     : joseph.smith@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    CurrentPresence  : Offline
    JoinDate         : 3/14/2020 9:19:44 AM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 475

    Make calls against the API with Community Domain and Authentication Header stored as global variables

.EXAMPLE
    Get-VtUser -EmailAddress "joseph.smith@company.com", "mary.jones@company.com", "jesse.storm@corp.com.au" -CommunityDomain "https://mycommunity.teligenthosted.net" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }

    UserId           : 112233
    Username         : JoeSmith
    EmailAddress     : joseph.smith@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    CurrentPresence  : Offline
    JoinDate         : 3/14/2020 9:19:44 AM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 475

    UserId           : 91478
    Username         : MJones
    EmailAddress     : mary.jones@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    CurrentPresence  : Offline
    JoinDate         : 4/11/2020 8:08:11 AM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 600

    UserId           : 94587
    Username         : StormJ
    EmailAddress     : jesse.storm@corp.com.au
    Status           : Approved
    ModerationStatus : Unmoderated
    CurrentPresence  : Offline
    JoinDate         : 5/11/2019 11:47:11 PM
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 404

    EmailAddress, UserId, or Username can take an array of values to process
.OUTPUTS
    Without the ReturnDetails parameter, the function returns a custom PowerShell object containing the user Id,
    the username, their email address, their account status, their moderation status, their last login, their last visit,
    and their lifetime points.

    With the ReturnDetails parameter, the function returns the entire JSON from the web call for each user.
.NOTES
    Tested with v11 of the Telligent Community platform using the User REST Endpoints
    Source Documentation: https://community.telligent.com/community/11/w/api-documentation/64921/user-rest-endpoints

    Relies on the Telligent and Utilities functions (defined in the 'begin' block )

    TBD: For doing a 'wildcard' search for a user, I really need to use the search endpoint and not the users endpoint.
    I've only just started experimenting with that in some scratch documents.
#>
function Get-VtUser {
    [CmdletBinding(
        DefaultParameterSetName = 'User Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64924/list-user-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Username to use for lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Username')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,

        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Email Address'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$EmailAddress,

        # User ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'User Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int64[]]$UserId,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$ReturnDetails,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader

    )

    begin {

        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }

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

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeader = $AuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}

    }
    process {
        switch ( $pscmdlet.ParameterSetName ) {
            'Username' { 
                if ( $Username -is [array] ) {
                    $Uri = "api.ashx/v2/user.json"
                    $UriParameterSet = @()
                    For ( $i = 0 ; $i -lt $Username.Count; $i++ ) {
                        $TempUriSet = $UriParameters.Clone()
                        $TempUriSet["Username"] = $Username[$i]
                        $UriParameterSet += $TempUriSet
                    }
                }
                else {
                    Write-Verbose -Message "Get-VtUser: Using the username [$Username] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = "Username: $Username"
                    $UriParameters["Username"] = $Username
                }
            }
            'Email Address' {
                if ( $EmailAddress -is [array] ) {
                    $Uri = "api.ashx/v2/user.json"
                    $UriParameterSet = @()
                    For ( $i = 0 ; $i -lt $EmailAddress.Count; $i++ ) {
                        $TempUriSet = $UriParameters.Clone()
                        $TempUriSet["EmailAddress"] = $EmailAddress[$i]
                        $UriParameterSet += $TempUriSet
                    }
                }
                else {
                    Write-Verbose -Message "Get-VtUser: Using the Email Address [$EmailAddress] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = "Email Address: $EmailAddress"
                    $UriParameters["EmailAddress"] = $EmailAddress
                }
            }
            'User Id' {
                if ( $UserId -is [array] ) {
                    $Uri = "api.ashx/v2/user.json"
                    $UriParameterSet = @()
                    For ( $i = 0 ; $i -lt $UserId.Count; $i++ ) {
                        $TempUriSet = $UriParameters.Clone()
                        $TempUriSet["Id"] = $UserId[$i]
                        $UriParameterSet += $TempUriSet
                    }
                }
                else {
                    Write-Verbose -Message "Get-VtUser: Using the UserId [$UserId] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = "UserId: $UserId"
                    $UriParameters["Id"] = $UserId
                }
                
            }

        }
        if ( $UriParameterSet ) {
            # Cycle through things
            ForEach ( $ParameterSet in $UriParameterSet ) {
                try {
                    $UserResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $ParameterSet | ConvertTo-QueryString ) ) -Headers $AuthHeader
                    if ( $UserResponse -and $ReturnDetails ) {
                        # We found a matching user, return everything with no pretty formatting
                        $UserResponse.User
                    }
                    elseif ( $UserResponse ) {
                        #implies '-not $ReturnDetails'
                        # Return abbreviated data
                        # We found a matching user, build a custom PowerShell Object for it
                        [PSCustomObject]@{
                            UserId           = $UserResponse.User.id;
                            Username         = $UserResponse.User.Username;
                            EmailAddress     = $UserResponse.User.PrivateEmail;
                            Status           = $UserResponse.User.AccountStatus;
                            ModerationStatus = $UserResponse.User.ModerationLevel
                            CurrentPresence  = $UserResponse.User.Presence;
                            JoinDate         = $UserResponse.User.JoinDate;
                            LastLogin        = $UserResponse.User.LastLoginDate;
                            LastVisit        = $UserResponse.User.LastVisitedDate;
                            LifetimePoints   = $UserResponse.User.Points;
                            EmailEnabled     = $UserResponse.User.ReceiveEmails;
                            MentionText      = "[mention:$( $UserResponse.User.ContentId ):$( $UserResponse.User.ContentTypeId )]"
                        }
                    }
                    else {
                        Write-Warning -Message "No results returned for users matching [$LookupKey]"
                    }
                }
                catch {
                    Write-Warning -Message "No results returned for users matching [$LookupKey]"
                }
            }
        }
        else {
            $UserResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
            if ( $UserResponse -and $ReturnDetails ) {
                # We found a matching user, return everything with no pretty formatting
                $UserResponse.User
            }
            elseif ( $UserResponse ) {
                #implies '-not $ReturnDetails'
                # Return abbreviated data
                # We found a matching user, build a custom PowerShell Object for it
                [PSCustomObject]@{
                    UserId           = $UserResponse.User.id;
                    Username         = $UserResponse.User.Username;
                    EmailAddress     = $UserResponse.User.PrivateEmail;
                    Status           = $UserResponse.User.AccountStatus;
                    ModerationStatus = $UserResponse.User.ModerationLevel
                    CurrentPresence  = $UserResponse.User.Presence;
                    JoinDate         = $UserResponse.User.JoinDate;
                    LastLogin        = $UserResponse.User.LastLoginDate;
                    LastVisit        = $UserResponse.User.LastVisitedDate;
                    LifetimePoints   = $UserResponse.User.Points;
                    EmailEnabled     = $UserResponse.User.ReceiveEmails;
                    MentionText      = "[mention:$( $UserResponse.User.ContentId ):$( $UserResponse.User.ContentTypeId )]"
                }
            }
            else {
                Write-Warning -Message "No results returned for users matching [$LookupKey]"
            }
        }
    }
    end {
        # Nothing to see here
    }
}

<#
.Synopsis
    Delete an account (completely) from a Verint/Telligent community
.DESCRIPTION
    Delete an account (completely) from a Verint/Telligent community.  Optionally, delete all the user's content or assign to another user/userid
.EXAMPLE
    Get-VtUser -EmailAddress "myAccountEmail@company.corp" -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader | Remove-VtUser -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader
    Find and then remove the account with email "myAccountEmail@company.corp" and will request confirmation for each deletion
.EXAMPLE
    Remove-VtUser -UserId 11332, 5362, 420 -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -Confirm:$false
    Remove users with id 113322, 5362, or 420 without confirmation
.INPUTS
    Either integters of the user id or a user object like those returned by Get-VtUser
.NOTES
    General notes
#>
function Remove-VtUser {
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
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader
    )

    Begin {

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
            $UserId = Get-VtUser -Username $ReassignedUsername -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false | Select-Object -ExpandProperty UserId
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

    Process {

        switch ( $pscmdlet.ParameterSetName ) {
            'User Id' {
                Write-Verbose -Message "Processing account deletion using User Ids"
                $User = $UserId | Get-VtUser -UserId $_ -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false
            }
            'Username' { 
                Write-Verbose -Message "Processing account deletion using Usernames"
                $User = $Username | Get-VtUser -Username $_ -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false 
            }

            'Email Address' { 
                Write-Verbose -Message "Processing account deletion using Email Addresses - must perform lookup first"
                $User = $EmailAddress | Get-VtUser -EmailAddress $_ -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false
            }
        }
        if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Delete User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>") ) {
            $Uri = "api.ashx/v2/users/$( $User.UserId ).json"
            $DeleteResponse = Invoke-RestMethod -Method POST -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $AuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -WarningAction SilentlyContinue )
            Write-Verbose -Message "User Deleted: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>"
            if ( $DeleteResponse ) {
                Write-Host "Account: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )> - $( $DeleteResponse.Info )" -ForegroundColor Red
            }
        }
    }
    End {
        # Nothing to see here
    }
}

<#
.Synopsis
    Changes setting for a Verint/Telligent user account on your community
.DESCRIPTION
    Change settings (Username, Email Address, Account Status, Moderation Status, is email enabled?) for a Verint/Telligent user account
.EXAMPLE
    $CommunityDomain = 'https://community.domain.local/'
    PS > $AuthHeader      = @{ 'Test-User-Token' = 'bG1[REDACTED]tYQ==' }
    PS > Set-VtUser -UserId 112233 -NewUsername 'MyNewUsername' -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader
    
    Set a new username for an account
.EXAMPLE
    $CommunityDomain = 'https://community.domain.local/'
    PS > $AuthHeader      = @{ 'Test-User-Token' = 'bG1[REDACTED]tYQ==' }

    PS > $UserToUpdate = Get-VtUser -Username 'CurrentlyBannedUser' -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader
    -- Ban the user --
    PS > $UserToUpdate | Set-VtUser -AccountStatus Banned -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader
    -- 'Un'-Ban the user --
    PS > $UserToUpdate | Set-VtUser -AccountStatus Approved -ModerationLevel Unmoderated -EmailBlocked:$false -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -PassThru

        UserId           : 181222
        Username         : CurrentlyBannedUser
        EmailAddress     : banned@new-email.com
        Status           : Approved
        ModerationStatus : Unmoderated
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
function Set-VtUser {
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
        [datetime]$BannedUntil = ( Get-Date ).AddYears(1),

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

        # Do you want to return the new user object back to the original call?
        [Parameter(Mandatory = $false)]
        [switch]$PassThru = $false,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader
    )

    Begin {

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

        # Rest-Method to use for the change
        $RestMethod = "Put"

        # Parameter Check
        # I can't provide a new Username or a new Email Address if there are multiple input objects
        


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

        # Add Banned Until date (and other things) only if the status is been defined as 'Banned'
        if ( $UriParameters["AccountStatus"] -eq "Banned" ) {
            $UriParameters.Add("BannedUntil", $BannedUntil )
            $UriParameters.Add("BanReason", $BanReason)
            $UriParameters["ModerationLevel"] = 'Moderated'
            $UriParameters["AcceptTermsOfService"] = 'false'
            $UriParameters["ForceLogin"] = 'true'
        }

    }
    Process {
        
        if ( $NewUsername ) {
            # Check to see if the username already exists in the community
            $CheckUser = Get-VtUser -Username $NewUsername -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
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
            $CheckUser = Get-VtUser -EmailAddress $NewEmailAddress -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue
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
        
        $User = $UserId | Get-VtUser -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -Verbose:$false
        if ( $UriParameters.Keys.Count ) {
            if ( $User ) {
                $Uri = "api.ashx/v2/users/$( $User.UserId ).json"
                # Imples that we found a user on which to operate
                if ( $pscmdlet.ShouldProcess($CommunityDomain, "Update User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>") ) {
                    # Execute the Update
                    Write-Verbose -Message "Updating User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>"
                    $UpdateResponse = Invoke-RestMethod -Method Post -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $AuthHeader | Set-VtAuthHeader -RestMethod $RestMethod ) -Verbose:$false
                    if ( $UpdateResponse ) {
                        $UserObject = [PSCustomObject]@{
                            UserId           = $UpdateResponse.User.id;
                            Username         = $UpdateResponse.User.Username;
                            EmailAddress     = $UpdateResponse.User.PrivateEmail;
                            Status           = $UpdateResponse.User.AccountStatus;
                            ModerationStatus = $UpdateResponse.User.ModerationLevel
                            CurrentPresence  = $UpdateResponse.User.Presence;
                            JoinDate         = $UpdateResponse.User.JoinDate;
                            LastLogin        = $UpdateResponse.User.LastLoginDate;
                            LastVisit        = $UpdateResponse.User.LastVisitedDate;
                            LifetimePoints   = $UpdateResponse.User.Points;
                            EmailEnabled     = $UpdateResponse.User.ReceiveEmails;
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

    End {
        # Nothing here
    }
}