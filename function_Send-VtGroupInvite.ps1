function Send-VtGroupInvite {
    <#
    .Synopsis
    
    .DESCRIPTION
    
    .EXAMPLE
    
    .EXAMPLE
    
    .EXAMPLE
    
    .EXAMPLE
    
    .INPUTS
    
    .OUTPUTS
    
    .NOTES
        You can optionally store the VtCommunity and the VtAuthHeader as global variables and omit passing them as parameters
        Eg: $Global:VtCommunity = 'https://myCommunityDomain.domain.local/'
            $Global:VtAuthHeader = ConvertTo-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: https://community.telligent.com/community/12/w/api-documentation/71540/create-user-invitation-rest-endpoint
    .NOTES
        This API call wants the GroupID, but the get/list groups API retrieves the containerID.  This will cause some ...interesting... workarounds.
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Send Group Invite with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/12/w/api-documentation/71540/create-user-invitation-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        # Usernames on which to send the invitation
        [Parameter(
            Mandatory = $true
        )]
        [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
        [string[]]$Email,

        # Send the invitation for this group ID
        [Parameter(
            Mandatory = $true
        )]
        [int]$GroupId,

        # Group Membership Type
        [Parameter()]
        [ValidateSet("Member", "Manager", "Owner", "PendingMember", "EffectiveMember")]
        [string]$GroupMembershipType = 'Member',

        # Set the title of the achievement
        [Parameter(Mandatory = $true)]
        [string]$Message,

        # Should we return all details?
        [Parameter()]
        [switch]$ReturnDetails,

        # Should we hide the progress?
        [Parameter()]
        [switch]$HideProgress,

        #region community authorization - put at bottom of paramter block
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Send Group Invite with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
    
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Send Group Invite with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,

        [Parameter(Mandatory = $true, ParameterSetName = 'Send Group Invite with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,

        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Send Group Invite with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )
        #endregion community authorization - put at bottom of paramter block
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
        
        $PropertiesToReturn = @(
            @{ Name = "InvitationID"; Expression = { $_.Id } }
            @{ Name = "SendingUserID"; Expression = { [int]( $_.UserId ) } }
            @{ Name = "SendingUser"; Expression = { ( Get-VtUser -UserId $_.UserId ) } }
            @{ Name = "GroupID"; Expression = { [int]( $_.GroupId ) } }
            @{ Name = "ContainerID"; Expression = { $Group.ContainerId } }
            @{ Name = 'GroupName'; Expression = { $Group.Name } }
            "Email"
            "GroupMembershipType"
            @{ Name = "Message"; Expression = { [System.Web.HttpUtility]::HtmlDecode($_.Message ) } }
        )

        $Group = Get-VtGroup -ErrorAction SilentlyContinue | Where-Object { $_.GroupId -eq $GroupId }
        if ( -not $Group ) {
            Write-Error -Message "No group found for group id: $GroupID"
            break
        }

        # REST Basics
        $HttpMethod = 'POST'
        $Uri = 'api.ashx/v2/users/invitations.json'
        # Static Parameters
        $UriParameters = @{}
        $UriParameters["GroupId"] = $Group.GroupId
        $UriParameters["GroupMembershipType"] = $GroupMembershipType
        $UriParameters["Message"] = $Message
    }
    PROCESS {
        ForEach ( $e in $Email ) {

            if ( $PSCmdlet.ShouldProcess($Community, "Send invitation to '$( $Group.Name )' to '$e'") ) {

                if ( -not $HideProgress ) {
                    Write-Progress -Activity "Sending group invitations" -CurrentOperation "Sending to '$e'" -Status "[$( $i + 1 )/$( $Email.Count )]" -PercentComplete ( ( $i / $Email.Count ) * 100 )
                }

                $UriParameters["Email"] = $e
                $InvitationResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -Method $HttpMethod
                if ( $InvitationResponse ) {
                    if ( $ReturnDetails ) {
                        $InvitationResponse.UserInvitation
                    }
                    else {
                        $InvitationResponse.UserInvitation | Select-Object -Property $PropertiesToReturn
                    }
                }
            }
        }
    }
    END {
        # Clean up any progress bars
        if ( -not $HideProgress ) {
            Write-Progress -Activity "Sending group invitations" -Completed
        }
    }
}