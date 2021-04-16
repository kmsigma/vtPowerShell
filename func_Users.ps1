<#
.Synopsis
    Get a user (or more information) from a Telligent Community
.DESCRIPTION
    Query the REST endpoint to get user account information.  Using the -All
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
    Get-VtUser -All -JoinDate ( ( Get-Date ).AddDays(-30) ) -Force

    Get all users who have joined in the last 30 days.
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
#>
function Get-VtUser {
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64924/list-user-rest-endpoint',
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'User Id')
    ]
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
            ValueFromPipelineByPropertyName = $true, 
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
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'User Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int[]]$UserId,

        # Get all users (computationally expensive)
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$All,

        # Filter all users based on email (or portion thereof).  Use wildcard-based filter ( '*partial_email@domain.local' and not 'partial_email@domain.local' )
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$FilterEmail,

        # Filter all users based on username (or portion thereof).  Use wildcard-based filter ( '*munityUser' and not 'munityUser' )
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$FilterUsername,

        # Are you absolutely sure that you want to run for all users?  Required for -All parameter.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$Force = $false,

        # Batch size for API pulls for all users (1..100).  Defaults to API default of 20.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,

        # Return all details instead of an abbreviated set
        [switch]$ReturnDetails = $false,

        # Include hidden accounts (typically service accounts)
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [switch]$IncludeHidden = $false,

        # Include only accounts joined after this date/time
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [datetime]$JoinDate,

        # Include only accounts that have been updated after this date/time (automatically converts to UTC time)
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [datetime]$LastUpdated,

        # Filter for account status - default is "All"
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [ValidateSet('Approved', 'ApprovalPending', 'Disapproved', 'Banned', 'All')]
        [string]$AccountStatus = 'All',

        # Filter for current presence status - default is neither 'Offline' nor 'Online'
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [ValidateSet('Online', 'Offline')]
        [string]$Presence,

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

        <#
        .Synopsis
            Function to pull back a single acccount from Verint/Telligent Communities
        .DESCRIPTION
            This function pulls back a single account from a Verint/Tellident Community.  It's implemented internally-only for parsing through arrays of accounts
        #>
        function Get-VtSingleUser {
            [CmdletBinding()]
            param (
                [Parameter()]
                [string]$CommunityDomain,
                [string]$Uri,
                [System.Collections.Hashtable]$UriParameters,
                [switch]$ReturnDetails
            )
            try {
                Write-Verbose -Message "Executing in single user mode"
                # Don't need page size or page index, so remove them from the UriParmeters
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
        
        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }

        if ( -not ( Get-Command -Name ConvertTo-QueryString -ErrorAction SilentlyContinue) ) {
            . .\func_Utilities.ps1
        }

        # Check the authentication header for any 'Rest-Method'
        $AuthHeader = $AuthHeader | Set-VtAuthHeader -RestMethod Get

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        # We only need to paginate if we are getting all users
        if ( $All ) {
            $UriParameters.Add("PageIndex", 0)
            $UriParameters.Add("PageSize", $BatchSize)
            if ( $IncludeHidden ) {
                $UriParameters.Add("IncludeHidden", "true")
            }
            if ( $AccountStatus -ne 'All') {
                $UriParameters.Add("AccountStatus", $AccountStatus)
            }
            if ( $JoinDate ) {
                $UriParameters.Add("JoinDate", $JoinDate)
            }
            if ( $Presence ) {
                $UriParameters.Add("Presence", $Presence)
            }
            if ( $LastUpdated ) {
                $UriParameters.Add("LastUpdatedUtcDate", $LastUpdated.ToUniversalTime())
            }
        
            if ( -not $Force ) {
                Write-Warning -Message "Using the 'All' parameter requires the use of the 'Force' parameter.  This can take an incredible amount of time based on your environment."
                break
            }
        }

    }
    process {
        switch ( $pscmdlet.ParameterSetName ) {
            'Username' { 
                ForEach ( $U in $Username ) {
                    Write-Verbose -Message "Get-VtUser: Using the username [$U] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = $U
                    $UriParameters["Username"] = $U
                    Get-VtSingleUser -CommunityDomain $CommunityDomain -Uri $Uri -UriParameters $UriParameters -ReturnDetails:$ReturnDetails
                }

            }
            'Email Address' {
                ForEach ( $U in $EmailAddress ) {
                    Write-Verbose -Message "Get-VtUser: Using the email [$U] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = $U
                    $UriParameters["EmailAddress"] = $U
                    Get-VtSingleUser -CommunityDomain $CommunityDomain -Uri $Uri -UriParameters $UriParameters -ReturnDetails:$ReturnDetails
                }

            }
            'User Id' {
                ForEach ( $U in $UserId ) {
                    Write-Verbose -Message "Get-VtUser: Using the user id [$U] for the lookup"
                    $Uri = "api.ashx/v2/user.json"
                    $LookupKey = $U
                    $UriParameters["Id"] = $U
                    Get-VtSingleUser -CommunityDomain $CommunityDomain -Uri $Uri -UriParameters $UriParameters -ReturnDetails:$ReturnDetails
                }
                
            }
            'All' {
                Write-Verbose -Message "Get-VtUser: All Users"
                if ( $FilterEmail ) {
                    Write-Verbose -Message "`tFilter on Email: $FilterEmail"
                }
                elseif ( $FilterUsername ) {
                    Write-Verbose -Message "`tFilter on Username: $FilterUsername"
                }
                $Uri = "api.ashx/v2/users.json"
                $LookupKey = "All Users"

                if ( $FilterEmail ) {
                    $FilterScript = { $_.PrivateEmail -like $FilterEmail }
                    $IsFiltered = $true
                }
                elseif ( $FilterUsername ) {
                    $FilterScript = { $_.Username -like $FilterUsername }
                    $IsFiltered = $true
                }
                elseif ( $FilterEmail -and $FilterUsername ) {
                    $FilterScript = { ( $_.PrivateEmail -like $FilterEmail ) -and ( $_.Username -like $FilterUsername ) }
                    $IsFiltered = $true
                }

                if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Search for user with [$LookupKey]") ) {
                    # Get all vt users

                    $TotalUsersReturned = 0
                    Write-Progress -Activity "Getting All Users from $CommunityDomain" -CurrentOperation "Initial Call" -PercentComplete 0
                    $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
                    $StopWatch.Start()
                    do {
                        Write-Verbose -Message "Uri: $( $CommunityDomain + $Uri + "?" + ( $UriParameters | ConvertTo-QueryString ) )"
                        $UserResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + "?" + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
                        $UsersPerSecond = $UserResponse.Users.Count / $StopWatch.Elapsed.TotalSeconds
                        if ( $ReturnDetails ) {
                            if ( $IsFiltered ) {
                                Write-Verbose -Message "FILTER: Filtering with: $FilterScript"
                                $UserResponse.Users | Where-Object -FilterScript $FilterScript
                            }
                            else {
                                $UserResponse.Users
                            }
                        }
                        else {
                            # Alias fields we want in the simple output
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "UserId" -Value Id -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "EmailAddress" -Value PrivateEmail -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "Status" -Value AccountStatus  -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "ModerationStatus" -Value ModerationLevel -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "CurrentPresence" -Value Presence  -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "LastLogin" -Value LastLoginDate -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "LastVisit" -Value LastVisitedDate -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "LifetimePoints" -Value Points -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "EmailEnabled" -Value ReceiveEmails -Force
                        
                            # Output 
                            if ( $IsFiltered ) {
                                Write-Verbose -Message "FILTER: Filtering with: $FilterScript"
                                $UserResponse.Users | Where-Object -FilterScript $FilterScript | Select-Object -Property UserId, Username, EmailAddress, Status, ModerationStatus, CurrentPresence, JoinDate, LastLogin, LastVisit, LifetimePoints
                            }
                            else {
                                $UserResponse.Users | Select-Object -Property UserId, Username, EmailAddress, Status, ModerationStatus, CurrentPresence, JoinDate, LastLogin, LastVisit, LifetimePoints
                            }
                        }
                        $TotalUsersReturned += $UserResponse.Users.Count
                        if ( $TotalUsersReturned ) {
                            Write-Progress -Activity "Getting All Users from $CommunityDomain" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1) [$TotalUsersReturned results so far / $( $UserResponse.TotalCount ) total results]" -PercentComplete ( ( $TotalUsersReturned / $UserResponse.TotalCount ) * 100 ) -SecondsRemaining ( $UsersPerSecond * $UserResponse.TotalCount )
                        }

                        # Increment Page Index
                        ( $UriParameters.PageIndex )++

                    } while ( ( $TotalUsersReturned -lt $UserResponse.TotalCount ) )
                    Write-Progress -Activity "Getting All Users from $CommunityDomain" -Completed
                }

            } 

            
        }
    }
    end {
        # Nothing to see here
    }
}

<#
.Synopsis
    This function is not yet completed.  When complete, this block will be updated
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
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
        [int[]]$UserId,

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
        if ( $ReassignedUserId ) {
            $UriParameters.Add("ReassignedUserId", $ReassignedUserId)
        }
        if ( $ReassignedUsername ) {
            $UserId = Get-VtUser -Username $ReassignedUsername -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false | Select-Object -ExpandProperty UserId
            if ( $UserId ) {
                $UriParameters.Add("ReassignedUserId", $UserId)
            }
            else {
                Write-Error -Message "Unable to find a user Id for '$ReassignedUsername' - stopping"
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
                $Users = $UserId | ForEach-Object {
                    Get-VtUser -UserId $_ -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false }
            }
            'Username' { 
                Write-Verbose -Message "Processing account deletion using Usernames"
                $Users = $Username | ForEach-Object {
                    Get-VtUser -Username $_ -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false }
            }

            'Email Address' { 
                Write-Verbose -Message "Processing account deletion using Email Addresses - must perform lookup first"
                $Users = $EmailAddress | ForEach-Object {
                    Get-VtUser -EmailAddress $_ -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue -Verbose:$false }
            }
        }
        ForEach ( $U in $Users ) {
            if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Delete User: '$( $U.Username )' [ID: $( $U.UserId )] <$( $( $U.EmailAddress ) )>") ) {
                $Uri = "api.ashx/v2/users/$( $U.UserId ).json"
                $DeleteResponse = Invoke-RestMethod -Method POST -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $AuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -WhatIf:$false -WarningAction SilentlyContinue )
                Write-Verbose -Message "User Deleted: '$( $U.Username )' [ID: $( $U.UserId )] <$( $( $U.EmailAddress ) )>"
                if ( $DeleteResponse ) {
                    Write-Host "Account: '$( $U.Username )' [ID: $( $U.UserId )] <$( $( $U.EmailAddress ) )> $( $DeleteResponse.Info )" -ForegroundColor Red
                }
            }
        }
    }
    End {
        # Nothing to see here
    }
}

<# Additional functions to build:
Set-VtUser (based on https://community.telligent.com/community/11/w/api-documentation/64926/update-user-rest-endpoint)
#>

<#
.Synopsis
    To be completed when the function is ready
    Starting very simply with AccountStatus, BanReason, BannedUntil, ModerationLevel, EmailAddress (PrivateEmail), Username, RequiresTermsOfServiceAcceptance, ReceiveEmails
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Returns a PowerShell Custom object with the user account details after updating
.NOTES
    General notes - this really needs some better logic - like don't update something if is it's already set how you think.
    That'll be something for another day though

    Also should accept an array of User ID's if we are not doing new Email Address or new Username
    Still need to figure out the proper logic for that.

    VERY Rough Logic:
    if ( $UserId -is [System.Array] ) {
        Write-Warning -Message "Operating in multi-user mode - new Email Address and new Username are ignored"
        $NewUsername = $null
        $NewEmailAddress = $null
    }
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Set-VtUser {
    [CmdletBinding(DefaultParameterSetName = 'User Id', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64926/update-user-rest-endpoint',
        ConfirmImpact = 'High')]
    Param
    (
        # The user id on which to operate.  Because this operation can change the username and email address, 
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'User Id')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int]$UserId,

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
        [Parameter(Mandatory=$false)]
        [ValidateSet('Profanity', 'Advertising', 'Spam', 'Aggressive', 'BadUsername', 'BadSignature', 'BanDodging', 'Other')]
        [string]$BanReason = 'Other',

        # New Moderation Level for the account: Unmoderated, Moderated
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet('Unmoderated', 'Moderated')]
        [string]$ModerationLevel,

        [Parameter(Mandatory = $false)]
        [switch]$RequiresTermsOfServiceAcceptance = $false,

        [Parameter(Mandatory = $false)]
        [switch]$EmailBlocked = $false,

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

        # Parameters to pass to the URI
        $UriParameters = @{}
        if ( $NewUsername ) {
            # Check to see if the username already exists in the community
            if ( -not ( Get-VtUser -Username $NewUsername -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue ) ) {
                $UriParameters.Add("Username", $NewUsername)
            }
            else {
                Write-Error -Message "Another user with the username '$NewUsername' was detected.  Cannot complete." -RecommendedAction "Please choose another username or delete the conflicing user"
                break
            }
        }
        if ( $NewEmailAddress ) {
            # Check to see if the email address already exists in the community
            if ( -not ( Get-VtUser -EmailAddress $NewEmailAddress -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -WarningAction SilentlyContinue) ) {
                $UriParameters.Add("PrivateEmail", $NewEmailAddress)
            }
            else {
                Write-Error -Message "Another user with the email address '$NewEmailAddress' was detected.  Cannot complete." -RecommendedAction "Please choose another email address or delete the conflicing user"
            }
        }
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
        } else {
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
        if ( $UriParameters.Keys.Count ) {
            $Uri = "api.ashx/v2/users/$UserId.json"
            $User = Get-VtUser -UserId $UserId -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader -WhatIf:$false -Verbose:$false
            if ( $User ) {
                # Imples that we found a user on which to operate
                if ( $pscmdlet.ShouldProcess($CommunityDomain, "Update User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>") ) {
                    # Execute the Update
                    Write-Verbose -Message "Updating User: '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>"
                    $UpdateResponse = Invoke-RestMethod -Method Post -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers ( $AuthHeader | Set-VtAuthHeader -RestMethod $RestMethod ) -Verbose:$false
                    if ( $UpdateResponse ) {
                        [PSCustomObject]@{
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
                    }
                    else {
                        Write-Error -Message "Unable to update '$( $User.Username )' [ID: $( $User.UserId )] <$( $( $User.EmailAddress ) )>"
                    }
                }
            }
            else {
                Write-Warning -Message "No user found for ID: $UserId"
            }
        }
        else {
            Write-Error -Message "No changes were requested for user with ID: $UserId" -RecommendedAction "Include a parameter to make updates"
        }

    }
    End {

    }
}

<# === Begin Testing Block === #>
#Remove-VtUser -Username "kevinsparenberg" -WhatIf 
#Remove-VtUser -UserId 251954, 244830 -DeleteAllContent
<# ==== End Testing Block ==== #>