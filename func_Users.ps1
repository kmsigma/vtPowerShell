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
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 475

    UserId           : 91478
    Username         : MJones
    EmailAddress     : mary.jones@company.com
    Status           : Approved
    ModerationStatus : Unmoderated
    CurrentPresence  : Offline
    LastLogin        : 4/5/2021 9:44:21 PM
    LastVisit        : 4/5/2021 9:44:37 PM
    LifetimePoints   : 600

    UserId           : 94587
    Username         : StormJ
    EmailAddress     : jesse.storm@corp.com.au
    Status           : Approved
    ModerationStatus : Unmoderated
    CurrentPresence  : Offline
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
    This function pulls back a single account from a Verint/Tellident Community.  It's implemented internally-only for getting arrays of data
#>        function Get-VtSingleUser {
            [CmdletBinding()]
            param (
                [Parameter()]
                [string]$CommunityDomain,
                [string]$Uri,
                [System.Collections.Hashtable]$UriParameters,
                [switch]$ReturnDetails
            )
            try {
                Write-Verbose -Message "Executing in single user lookup mode"
                # Don't need page size or page index, so remove them from the UriParmeters
                Write-Verbose -Message "Uri: $( ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) )"
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
                        LastLogin        = $UserResponse.User.LastLoginDate;
                        LastVisit        = $UserResponse.User.LastVisitedDate;
                        LifetimePoints   = $UserResponse.User.Points;
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
        if ( $AuthHeader["Rest-Method"] ) {
            # Remove it because this is a 'GET' call - anything else will cause an error in Invoke-RestMethod
            $AuthHeader.Remove("Rest-Method")
        }

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
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "ModerationStatus" -Verbose ModerationLevel -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "CurrentPresence" -Value Presence  -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "LastLogin" -Value LastLoginDate -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "LastVisit" -Value LastVisitedDate -Force
                            $UserResponse.Users | Add-Member -MemberType AliasProperty -Name "LifetimePoints" -Value Points -Force
                        
                            # Output 
                            if ( $IsFiltered ) {
                                Write-Verbose -Message "FILTER: Filtering with: $FilterScript"
                                $UserResponse.Users | Where-Object -FilterScript $FilterScript | Select-Object -Property UserId, Username, EmailAddress, Status, ModerationStatus, CurrentPresence, LastLogin, LastVisit, LifetimePoints
                            }
                            else {
                                $UserResponse.Users | Select-Object -Property UserId, Username, EmailAddress, Status, ModerationStatus, CurrentPresence, LastLogin, LastVisit, LifetimePoints
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

This still needs to be done

.Synopsis
    Short description
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

        # Delete account by User Id
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
        # Check for proper parameterization

    }
    Process {
        switch ( $pscmdlet.ParameterSetName ) {
            'User Id' {
                Write-Verbose -Message "Processing account deletion using User Ids"
            }
            'Username' { 
                Write-Verbose -Message "Processing account deletion using Usernames"
            }
            'Email Address' { 
                Write-Verbose -Message "Processing account deletion using Email Addresses - must perform lookup first"
                $UserId = $EmailAddress | ForEach-Object {
                    Get-VtUser -EmailAddress $_ -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader | Select-Object -ExpandProperty UserId
                }
            }
        }
        ForEach ($U in $UserId) {
            if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Delete User with ID: $U from") ) {
            }
        }
    }
    End {
        # Nothing to see here
    }
}

<# Additional functions to complete:

Set-VtUser (based on https://community.telligent.com/community/11/w/api-documentation/64926/update-user-rest-endpoint)

#>


#Get-VtUser -Username "KMSigma" -Verbose