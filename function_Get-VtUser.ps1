function Get-VtUser {
    <#
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
        PS > $Global:VtAuthHeader       = Get-VtAuthHeader -Username "MyAdminAccount" -ApiKey "MyAdminApiKey"
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
                ValueFromPipeline = $false,
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
                ValueFromPipeline = $false,
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
    
            # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
            $VtAuthHeader = $VtAuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false
    
            # Set default page index, page size, and add any other filters
            $UriParameters = @{}
    
        }
        PROCESS {
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
                        if ( $pscmdlet.ShouldProcess("Lookup User", $VtCommunity ) ) {
                            $UserResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $ParameterSet | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                            if ( $UserResponse -and $ReturnDetails ) {
                                # We found a matching user, return everything with no pretty formatting
                                $UserResponse.User
                            }
                            elseif ( $UserResponse ) {
                                #implies '-not $ReturnDetails'
                                # Return abbreviated data
                                # We found a matching user, build a custom PowerShell Object for it
                                [PSCustomObject]@{
                                    #[VtUser]@{
                                    UserId           = $UserResponse.User.id
                                    Username         = $UserResponse.User.Username
                                    EmailAddress     = $UserResponse.User.PrivateEmail
                                    Status           = $UserResponse.User.AccountStatus
                                    ModerationStatus = $UserResponse.User.ModerationLevel
                                    IsIgnored        = $UserResponse.User.IsIgnored -eq "true"
                                    CurrentPresence  = $UserResponse.User.Presence
                                    JoinDate         = $UserResponse.User.JoinDate
                                    LastLogin        = $UserResponse.User.LastLoginDate
                                    LastVisit        = $UserResponse.User.LastVisitedDate
                                    LifetimePoints   = $UserResponse.User.Points
                                    EmailEnabled     = $UserResponse.User.ReceiveEmails -eq "true"
                                    # Need to strip out the dashes from the GUIDs
                                    MentionText      = "[mention:$( $UserResponse.User.ContentId.Replace('-', '') ):$( $UserResponse.User.ContentTypeId.Replace('-', '') )]"
                                }
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
                $UserResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader
                if ( $UserResponse -and $ReturnDetails ) {
                    # We found a matching user, return everything with no pretty formatting
                    $UserResponse.User
                }
                elseif ( $UserResponse ) {
                    #implies '-not $ReturnDetails'
                    # Return abbreviated data
                    # We found a matching user, build a custom PowerShell Object for it
                    [PSCustomObject]@{
                        UserId           = $UserResponse.User.id
                        Username         = $UserResponse.User.Username
                        EmailAddress     = $UserResponse.User.PrivateEmail
                        Status           = $UserResponse.User.AccountStatus
                        ModerationStatus = $UserResponse.User.ModerationLevel
                        IsIgnored        = $UserResponse.User.IsIgnored
                        CurrentPresence  = $UserResponse.User.Presence
                        JoinDate         = $UserResponse.User.JoinDate
                        LastLogin        = $UserResponse.User.LastLoginDate
                        LastVisit        = $UserResponse.User.LastVisitedDate
                        LifetimePoints   = $UserResponse.User.Points
                        EmailEnabled     = $UserResponse.User.ReceiveEmails
                        MentionText      = "[mention:$( $UserResponse.User.ContentId ):$( $UserResponse.User.ContentTypeId )]"
                    }
                }
                else {
                    Write-Warning -Message "No results returned for users matching [$LookupKey]"
                }
            }
        }
        END {
            # Nothing to see here
        }
    }