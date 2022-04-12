function Get-VtUser {
    <#
    #### Needs to be updated ####
    .Synopsis
        Get a user (or more information) from a Telligent Community
    .DESCRIPTION
        Query the REST endpoint to get user account information.
    .EXAMPLE
        Get-VtUser -Username "JoeSmith" -Community "https://mycommunity.teligenthosted.net/" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }
        PS > Get-VtUser -UserId 112233 -Community "https://mycommunity.teligenthosted.net/" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }
        PS > Get-VtUser -EmailAddress "joseph.smith@company.com" -Community "https://mycommunity.teligenthosted.net/" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }
    
            Return a single user based on the their username, email address, or id
        
            --- All of the above returns the same output as below ---
    
        UserId           : 112233
        Username         : JoeSmith
        EmailAddress     : joseph.smith@company.com
        Status           : Approved
        ModerationStatus : Unmoderated
        IsIgnored        : True
        CurrentPresence  : Offline
        JoinDate         : 3/14/2020 9:19:44 AM
        LastLogin        : 4/5/2021 9:44:21 PM
        LastVisit        : 4/5/2021 9:44:37 PM
        LifetimePoints   : 475
    
    .EXAMPLE
        $Global:VtCommunity = "https://mycommunity.telligenthosted.net/"
        PS > $Global:VtAuthHeader       = ConvertTo-VtAuthHeader -Username "MyAdminAccount" -ApiKey "MyAdminApiKey"
        PS > Get-VtUser -Username "JoeSmith"
        
        UserId           : 112233
        Username         : JoeSmith
        EmailAddress     : joseph.smith@company.com
        Status           : Approved
        ModerationStatus : Unmoderated
        IsIgnored        : True
        CurrentPresence  : Offline
        JoinDate         : 3/14/2020 9:19:44 AM
        LastLogin        : 4/5/2021 9:44:21 PM
        LastVisit        : 4/5/2021 9:44:37 PM
        LifetimePoints   : 475
    
        Make calls against the API with Community Domain and Authentication Header stored as global variables
    
    .EXAMPLE
        Get-VtUser -EmailAddress "joseph.smith@company.com", "mary.jones@company.com", "jesse.storm@corp.com.au" -Community "https://mycommunity.teligenthosted.net/" -AuthHeader @{ "Rest-User-Token" = "bG[REDACTED]]Q==" }
    
        UserId           : 112233
        Username         : JoeSmith
        EmailAddress     : joseph.smith@company.com
        Status           : Approved
        ModerationStatus : Unmoderated
        IsIgnored        : True
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
        IsIgnored        : True
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
        IsIgnored        : True
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
    [CmdletBinding(
        DefaultParameterSetName = 'All Users with Connection File',
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
            ParameterSetName = 'Username with Authentication Header')]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Username with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Username with Connection File'
        )]
        [string[]]$Username,
    
        # Email address to use for lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Email Address with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Email Address with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Email Address with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$EmailAddress,
    
        # User ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'User Id with Authentication Header'
        )]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Connection File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int64[]]$UserId,

        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Connection File')]
        [Alias("AllUsers")]
        [switch]$All,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Email Address with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Email Address with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("AuthHeader")]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Email Address with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Users with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Username with Connection File')]
        [Parameter(ParameterSetName = 'Email Address with Connection File')]
        [Parameter(ParameterSetName = 'User Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),
    
        # Should we return all details?
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$ReturnDetails,
        
        # Size of the call each time
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,

        # Filter for Account Status
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateSet('All', 'Approved', 'ApprovalPending', 'Disapproved', 'Banned')]
        [Alias('Status')]
        [string]$AccountStatus = 'All',

        # Sort By
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateSet('JoinedDate', 'Username', 'DisplayName', 'Website', 'LastVisitedDate', 'Posts', 'Email', 'RecentPosts', 'Score', 'ContentIdsOrder')]
        [string]$SortBy = 'JoinedDate',

        # Sort Order (defaults to descending)
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$Descending,

        # Include Hidden Users
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$IncludeHidden,

        # Include 'Mention' HTML Code
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$IncludeMentionCode,

        # Filter for Recent
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [datetime]$UpdatedAfter,

        # Filter for Presence
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateSet('All', 'Online', 'Offline')]
        [string]$Presence = 'All',

        # Suppress the progress bar
        [Parameter()]
        [switch]$SuppressProgressBar
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

        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

        # Set other Parameters
        $UriParameters["SortBy"] = $SortBy
        if ( $Descending ) {
            $UriParameters["SortOrder"] = 'Descending'
        } # else leave as default
        
        if ( $IncludeHidden ) {
            $UriParameters["IncludeHidden"] = 'true'
        }
        if ( $UpdatedAfter ) {
            $UriParameters["LastUpdatedUtcDate"] = $UpdatedAfter
        }
        if ( $Presence -ne 'All' ) {
            $UriParameters["Presence"] = $Presence
        }
        $UriParameters["AccountStatus"] = $AccountStatus

        # Possible Uris based on the lookup type
        $Uris = @{
            'List' = 'api.ashx/v2/users.json'
            'Show' = 'api.ashx/v2/user.json'
        }

        


        $PropertiesToReturn = @(
            @{ Name = "UserId"; Expression = { $_.id } }
            @{ Name = "Username"; Expression = { $_.Username } }
            @{ Name = "EmailAddress"; Expression = { $_.PrivateEmail } }
            @{ Name = "Status"; Expression = { $_.AccountStatus } }
            @{ Name = "ModerationStatus"; Expression = { $_.ModerationLevel } }
            @{ Name = "IsIgnored"; Expression = { $_.IsIgnored -eq "true" } }
            @{ Name = "CurrentPresence"; Expression = { $_.Presence } }
            @{ Name = "JoinedDate"; Expression = { $_.JoinDate } }
            @{ Name = "LastLoginDate"; Expression = { $_.LastLoginDate } }
            @{ Name = "LastVisitedDate"; Expression = { $_.LastVisitedDate } }
            @{ Name = "LifetimePoints"; Expression = { $_.Points } }
            @{ Name = "EmailEnabled"; Expression = { $_.ReceiveEmails -eq "true" } }
        )
    
        if ( $IncludeMentionCode ) {
            $PropertiesToReturn += @{ Name = "MentionHtml"; Expression = { "[mention:$( $_.ContentId.Replace('-', '') ):$( $_.ContentTypeId.Replace('-', '') )]" } }
        }
    }
    PROCESS {
        switch -wildcard ( $PSCmdlet.ParameterSetName ) {
            'Username *' { 
                Write-Verbose -Message "Detected Search by Username"
                $UriParameters["Usernames"] = $Username -join ','
                $ProcessMethod = 'List'
            }
            
            'Email Address *' {
                Write-Verbose -Message "Detected Search by Email Address"
                $ProcessMethod = 'Show'
            }
            'User Id *' {
                Write-Verbose -Message "Detected Search by User ID"
                # Different URI for by ID number
                $ProcessMethod = 'Show'
            }
            'All Users *' {
                Write-Verbose -Message "Detected Search for All Users"
                Write-Warning -Message "Collecting all users can be time consuming.  You've been warned."
                $ProcessMethod = 'List'
                # Overriding the Batch File size to speed up processing
                $BatchSize = 100
                $UriParameters["PageSize"] = $BatchSize
            }
        }
        
        $Operations = @()
        $UriParameters.GetEnumerator() | Where-Object { $_.Key -notlike "*Page*" } | ForEach-Object { $Operations += "$( $_.Key ) is '$( $_.Value )'" }
        $Operations = "Query for Users with: $( $Operations -join " AND " )"
        if ( $PSCmdlet.ShouldProcess( $Operations ) ) {
            if ( $ProcessMethod -eq "Show" ) {
                # Using the "SHOW" API
                $Uri = $Uris[$ProcessMethod]
                if ( $UserId ) {
                    $RecordType = "Id"
                    $Records = $UserId
                }
                else {
                    $RecordType = "EmailAddress"
                    $Records = $EmailAddress
                }
                For ( $i = 0; $i -lt $Records.Count; $i++ ) {
                    # Use none of the 'filtering' parameters
                    if ( -not ( $SuppressProgressBar ) ) {
                        Write-Progress -Activity "Retrieving Users from $Community" -CurrentOperation "Retrieving User with ID: $( $Records[$i] )" -Status "[$i/$( $Records.Count)] records retrieved" -PercentComplete ( ( $i / $Records.Count ) * 100 )
                    }
                    Write-Verbose -Message "Making call for: $( $Records[$i] )"
                    $UserResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + "$RecordType=$( $Records[$i])" ) -Headers $AuthHeaders
                    if ( $UserResponse ) {
                        if ( $ReturnDetails ) {
                            $UserResponse.User
                        }
                        else {
                            $UserResponse.User | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    else {
                        Write-Warning -Message "No record found for $( $Records[$i] )"
                    }
                }
            }
        
            else {
                # Using the "LIST" API
                #region process the calls
                $Uri = $Uris[$ProcessMethod]
                $TotalReturned = 0
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    if ( $TotalReturned -and -not $SuppressProgressBar ) {
                        Write-Progress -Activity "Retrieving Users from $Community" -CurrentOperation ( "Retrieving $BatchSize records of $( $UsersResponse.TotalCount )" ) -Status "[$TotalReturned/$( $UsersResponse.TotalCount )] records retrieved" -PercentComplete ( ( $TotalReturned / $UsersResponse.TotalCount ) * 100 )
                    }
                    $UsersResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $UsersResponse ) {
                        $TotalReturned += $UsersResponse.Users.Count
                        if ( $ReturnDetails ) {
                            $UsersResponse.Users
                        }
                        else {
                            $UsersResponse.Users | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $UsersResponse.TotalCount)
                #endregion
            
            }
            # Either process kicks off the progress bar, so shut it down here
            if ( -not $SuppressProgressBar ) {
                Write-Progress -Activity "Retrieving Users from $Community" -Completed
            }
        }
    }
    END {
        # Nothing to see here
    }
}