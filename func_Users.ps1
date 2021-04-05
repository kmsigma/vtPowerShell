<#
.Synopsis
   Get a user id (or more information) from a Telligent Community
.DESCRIPTION
   TBD: Long description
.EXAMPLE
   TBD: Example of how to use this cmdlet
.EXAMPLE
   TBD: Another example of how to use this cmdlet
.INPUTS
   TBD: Inputs to this cmdlet (if any)
.OUTPUTS
   TBD: Output from this cmdlet (if any)
.NOTES
   TBD: General notes
   Source Documentation: https://community.telligent.com/community/11/w/api-documentation/64921/user-rest-endpoints
.COMPONENT
   TBD: The component this cmdlet belongs to
.ROLE
   TBD: The role this cmdlet belongs to
.FUNCTIONALITY
   TBD: The functionality that best describes this cmdlet
#>
function Get-VtUser {
    [CmdletBinding(
        SupportsShouldProcess=$true, 
        PositionalBinding=$false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64924/list-user-rest-endpoint',
        ConfirmImpact='Medium')
    ]
    Param
    (
        # Username to use for lookup
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            ParameterSetName='Username')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        # Email address to use for lookup
        [Parameter(
            Mandatory=$true,
            ParameterSetName='Email Address'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$EmailAddress,

        # User ID for the lookup
        [Parameter(
            Mandatory=$true,
            ParameterSetName='User Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]$UserId,

        # Get all users (computationally expensive)
        [Parameter(
            Mandatory=$true,
            ParameterSetName='All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$All,

        # Filter all users based on email (or portion thereof).  Use wildcard-based filter ( '*partial_email@domain.local' and not 'partial_email@domain.local' )
        [Parameter(
            Mandatory=$false,
            ParameterSetName='All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$FilterEmail,

        # Filter all users based on username (or portion thereof).  Use wildcard-based filter ( '*munityUser' and not 'munityUser' )
        [Parameter(
            Mandatory=$false,
            ParameterSetName='All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$FilterUsername,

        # Batch size for API pulls for all users (1..100).  Defaults to API default of 20.
        [Parameter(
            Mandatory=$false,
            ParameterSetName='All'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,

        # Return all details instead of an abbreviated set
        [switch]$ReturnDetails = $false,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory=$false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory=$false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader

    )

    begin {
        # Validate that the authentication header function  is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . ".\func_Telligent.ps1"
        }

        # Set default page index
        $UriParameters = @{}
        $UriParameters.Add("PageIndex", 0)
        $UriParameters.Add("PageSize", $BatchSize)
    }
    process {
        switch ( $pscmdlet.ParameterSetName ) {
            'Username' { 
                Write-Verbose -Message "Get-VtUser: Using the username [$Username] for the lookup"
                $Uri = "api.ashx/v2/user.json?Username=$Username"
                $LookupKey = $Username
            }
            'Email Address' {
                Write-Verbose -Message "Get-VtUser: Using the email [$EmailAddress] for the lookup"
                $Uri = "api.ashx/v2/user.json?EmailAddress=$EmailAddress"
                $LookupKey = $EmailAddress
            }
            'User Id' {
                Write-Verbose -Message "Get-VtUser: Using the user id [$UserId] for the lookup"
                $Uri = "api.ashx/v2/user.json?Id=$UserId"
                $LookupKey = $UserId
            }
            'All' {
                Write-Verbose -Message "Get-VtUser: All Users"
                if ( $FilterEmail ) {
                    Write-Verbose -Message "`tFilter on Email: $FilterEmail"
                } elseif ( $FilterUsername ) {
                    Write-Verbose -Message "`tFilter on Username: $FilterUsername"
                }
                $Uri = "api.ashx/v2/users.json"
                $LookupKey = "All Users"
            }
        }
        if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Search for user with [$LookupKey]") ) {
            if ( $All ) {
                Write-Warning -Message "Getting all users can take an incredible amount of time (even with a filter).  Use this functionality sparingly."
                if ( $FilterEmail ) {
                    $FilterScript = { $_.PrivateEmail -like $FilterEmail }
                    $IsFiltered = $true
                } elseif ( $FilterUsername ) {
                    $FilterScript = { $_.Username -like $FilterUsername }
                    $IsFiltered = $true
                } elseif ( $FilterEmail -and $FilterUsername ) {
                    $FilterScript = { ( $_.PrivateEmail -like $FilterEmail ) -and ( $_.Username -like $FilterUsername ) }
                    $IsFiltered = $true
                }

                # Get all vt users
                $TotalUsersReturned = 0
                Write-Progress -Activity "Getting All Users from $CommunityDomain" -CurrentOperation "Initial Call" -PercentComplete 0
                $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
                $StopWatch.Start()
                do {
                    $UserResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + "?" + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
                    $UsersPerSecond = $UserResponse.Users.Count / $StopWatch.Elapsed.TotalSeconds
                    if ( $ReturnDetails ) {
                        if ( $IsFiltered ) {
                            Write-Verbose -Message "FILTER: Filtering with: $FilterScript"
                            $UserResponse.Users | Where-Object -FilterScript $FilterScript
                        } else {
                            $UserResponse.Users
                        }
                    } else {
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
                        } else {
                            $UserResponse.Users | Select-Object -Property UserId, Username, EmailAddress, Status, ModerationStatus, CurrentPresence, LastLogin, LastVisit, LifetimePoints
                        }
                        #$UserResponse.Users | Select-Object -Property UserId, Username, EmailAddress, Status, CurrentPresence, LastLogin, LastVisit, Points
                    }
                    $TotalUsersReturned += $UserResponse.Users.Count
                    Write-Progress -Activity "Getting All Users from $CommunityDomain" -CurrentOperation "Making Call #$( $UriParameters["PageIndex"] + 1) [$TotalUsersReturned / $( $UserResponse.TotalCount )]" -PercentComplete ( ( $TotalUsersReturned / $UserResponse.TotalCount ) * 100 ) -SecondsRemaining ( $UsersPerSecond * $UserResponse.TotalCount )

                    # Increment Page Index
                    ( $UriParameters.PageIndex )++

                } while ( ( $TotalUsersReturned -lt $UserResponse.TotalCount ) -or ( $UriParameters["PageIndex"] -eq 5 ) )
                Write-Progress -Activity "Getting All Users from $CommunityDomain" -Completed
            } else {
                try {
                    $UserResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri ) -Headers $AuthHeader
                    if ( $UserResponse -and $ReturnDetails ) {
                        # We found a matching user, return everything with no pretty formatting
                        $UserResponse.User
                    } elseif ( $UserResponse ) { #implies '-not $ReturnDetails'
                        # We found a matching user, build a custom PowerShell Object for it
                        # Return abbreviated data
                        [PSCustomObject]@{
                            UserId = $UserResponse.User.id;
                            Username = $UserResponse.User.Username;
                            EmailAddress = $UserResponse.User.PrivateEmail;
                            Status = $UserResponse.User.AccountStatus;
                            ModerationStatus = $UserResponse.User.ModerationLevel
                            CurrentPresence = $UserResponse.User.Presence;
                            LastLogin = $UserResponse.User.LastLoginDate;
                            LastVisit = $UserResponse.User.LastVisitedDate;
                            LifetimePoints = $UserResponse.User.Points;
                        }
                    } else {
                        Write-Warning -Message "No results returned for users matching [$LookupKey]"
                    }
                } catch {
                    Write-Warning -Message "No results returned for users matching [$LookupKey]"
                }
            }
        }
    }
    end {
        # Nothing to see here
    }
}
