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
function Get-VtUsers {
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

        # Should we return more than just the user ID?
        [switch]$ReturnDetails = $false,

        # Should we pull all users
        [Parameter(ParameterSetName='All Users')]
        [switch]$All = $false,

        # Authentication Header for the community
        [Parameter(
            Mandatory=$false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory=$false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$CommunityDomain = $Global:CommunityDomain
    )

    begin {
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . ".\func_Telligent.ps1"
        }
    }
    process {
        switch ( $pscmdlet.ParameterSetName ) {
            'All Users' {
                Write-Host "Not implemented yet - sorry" -ForegroundColor Red 
                Write-Verbose -Message "Pulling a list of all users can take a significant amount of time"

            }
            'Username' { 
                Write-Verbose -Message "Using the username [$Username] for the lookup"
                $Uri = "api.ashx/v2/users.json?Usernames=$Username"
                $LookupKey = $Username
            }
            'Email Address' {
                Write-Verbose -Message "Using the email [$EmailAddress] for the lookup"
                $Uri = "api.ashx/v2/users.json?EmailAddress=$EmailAddress"
                $LookupKey = $EmailAddress
            }
        }
        if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Search for user with [$LookupKey]") ) {
            $Users = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri ) -Headers $AuthHeader
            if ( $Users.TotalCount -eq 1 ){
                # We found a single user - this is expected
                if ( $ReturnDetails ) {
                    $Users.Users
                } else {
                    [PSCustomObject]@{
                        UserId = $Users.Users.id;
                        Username = $Users.Users.Username;
                        EmailAddress = $Users.Users.PrivateEmail;
                        Status = $Users.Users.AccountStatus;
                        CurrentPresence = $Users.Users.Presence;
                        LastLogin = $Users.Users.LastLoginDate;
                        LastVisit = $Users.Users.LastVisitedDate;
                    }
                }
            } elseif ( $Users.TotalCount -gt 1 ) {
                # We found multiple users, which is bad
                Write-Error -Message "Multiple Users found with matching $( $pscmdlet.ParameterSetName )"
            } else {
                Write-Warning -Message "No users found matching [$LookupKey]"
            }
        }
    }
    end {
    }
}
