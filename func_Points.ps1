# Source Information: https://community.telligent.com/community/11/w/api-documentation/64799/point-transaction-rest-endpoints

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Add-VtPoints -Username KMSigma -Description "Say hi to your wife for me." -AwardDateTime "09/14/2019" -Points 43 -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader
.EXAMPLE
    Add-VtPoints -Username KMSigma -Description "Will confirm if you ask for more for 5,000 points" -Points 5001 -CommunityDomain $CommunityDomain -AuthHeader $AuthHeader
.OUTPUTS
   PowerShell Custom Object Containing the Content, CreateDate, Description, Transaction ID, User Custom Object, and point Value
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Add-VtPoints {
    [CmdletBinding(
        SupportsShouldProcess=$true, 
        PositionalBinding=$false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param(
        # The username of the account who is getting the points
        [Parameter(
            Mandatory=$true, 
            Position=0
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        # The number of points to award to an account.  This does not support removing points.
        [Parameter(
            Mandatory=$true, 
            Position=1
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0,100000)]
        [int]$Points,

        # Description of the points award.  Should try and keep the description to less than 120 characters if possible.
        [Parameter(
            Mandatory=$true, 
            Position=2
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(0,250)]
        [string]$Description,


        # The date/time you want to have the awards added - defaults to 'now'
        [Parameter(
            Mandatory=$false, 
            Position=3
        )]
        [datetime]$AwardDateTime = ( Get-Date ),

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
        if ( -not ( Get-Command -Name Get-VtUsers -ErrorAction SilentlyContinue ) ) {
            . ".\func_Users.ps1"
        }
        # Convert the username to a userid
        $User = Get-VtUsers -Username $Username -AuthHeader $AuthHeader -CommunityDomain $CommunityDomain -ReturnDetails
        # Since point transactions require a ContentId and ContentTypeId, we should pull those from the user's profile
        if ( -not $User ) {
            Write-Error -Message "Unable to add point because we didn't find a matching user for [$Username]"
        } else {
            $Userid = $User.Id
            $ContentId = $User.ContentId
            $ContentTypeId = $User.ContentTypeId
        }
        $Uri = "api.ashx/v2/pointtransactions.json"
    }
    process
    {
        $Proceed = $true
        if ($pscmdlet.ShouldProcess("$Username", "Add $Points to Account")) {
            if ( $Points -gt 5000 ) {
                Write-Host "====LARGE POINT DISTRIBUTION VALIDATION====" -ForegroundColor Yellow
                $BigPoints = Read-Host -Prompt "You are about to add $Points to $Username's account.  Are you sure you want to do this?  [Enter 'Yes' to confirm]"
                $Proceed = ( $BigPoints.ToLower() -eq 'yes' )
            }
            if ( $Proceed ) {
                # Build the body to send to the account
                # For proper display, the description needs to be wrapped in HTML paragraph tags
                $Body = @{
                    Description = "<p>$Description</p>";
                    UserId = $UserId;
                    Value = $Points;
                    ContentID = $ContentId;
                    ContentTypeId = $ContentTypeId;
                    CreateDate = $AwardDateTime;
                }
                try {
                    $PointsRequest = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri ) -Method Post -Body $Body -Headers $AuthHeader
                    $PointsRequest.PointTransaction
                }
                catch {
                    Write-Error -Message "Something didn't work"
                }
            }
        }
    }
    end {
        # Nothing to see here
    }
}
