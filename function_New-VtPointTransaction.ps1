function New-VtPointTransaction {
    <#
    .Synopsis
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        New-VtPointTransaction -Username KMSigma -Description "Say hi to your wife for me." -AwardDateTime "09/14/2019" -Points 43 -Community $VtCommunity -AuthHeader $VtAuthHeader
    .EXAMPLE
        New-VtPointTransaction -Username KMSigma -Description "Will confirm if you ask for more for 5,000 points" -Points 5001 -Community $VtCommunity -AuthHeader $VtAuthHeader
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
    [CmdletBinding(
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64799/point-transaction-rest-endpoints',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param(
        # The username of the account who is getting the points
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,
    
        # The number of points to award to an account.  This does not support removing points.
        [Parameter(
            Mandatory = $true, 
            Position = 1
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 100000)]
        [int]$Points,
    
        # Description of the points award.  Should try and keep the description to less than 120 characters if possible.
        [Parameter(
            Mandatory = $true, 
            Position = 2
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(0, 250)]
        [string]$Description,
    
    
        # The date/time you want to have the awards added - defaults to 'now'
        [Parameter(
            Mandatory = $false, 
            Position = 3
        )]
        [datetime]$AwardDateTime = ( Get-VtDate ),
    
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
    
        $Uri = "api.ashx/v2/pointtransactions.json"
    
        $RestMethod = "GET"
    }
    PROCESS {
    
        ForEach ( $U in $Username ) {
            $Proceed = $true
    
            # Convert the username to a userid
            $User = Get-VtUser -Username $U -AuthHeader $VtAuthHeader -Community $VtCommunity -ReturnDetails -WhatIf:$false
            # Since point transactions require a ContentId and ContentTypeId, we should pull those from the user's profile
            if ( -not $User ) {
                Write-Error -Message "Unable to add point because we didn't find a matching user for [$U]"
                $Proceed = $false
            }
            else {
                $Userid = $User.Id
                $ContentId = $User.ContentId
                $ContentTypeId = $User.ContentTypeId
            }
            
            if ($PSCmdlet.ShouldProcess("User: $( $User.DisplayName )", "Add $Points points") -and $Proceed) {
                if ( $Points -gt 5000 ) {
                    Write-Host "====LARGE POINT DISTRIBUTION VALIDATION====" -ForegroundColor Yellow
                    $BigPoints = Read-Host -Prompt "You are about to add $Points to $( $U.DisplayName  )'s account.  Are you sure you want to do this?  [Enter 'Yes' to confirm]"
                    $Proceed = ( $BigPoints.ToLower() -eq 'yes' )
                }
                if ( $Proceed ) {
                    # Build the body to send to the account
                    # For proper display, the description needs to be wrapped in HTML paragraph tags.
                    $Body = @{
                        Description   = "<p>$Description</p>";
                        UserId        = $UserId;
                        Value         = $Points;
                        ContentID     = $ContentId; # We'll just use the ContentID from the user
                        ContentTypeId = $ContentTypeId; # We'll just use the ContentID from the user
                        CreatedDate   = $AwardDateTime;
                    }
                    try {
                        $PointsRequest = Invoke-RestMethod -Uri ( $Community + $Uri ) -Method Post -Body $Body -Headers ( $VtAuthHeader | Set-VtAuthHeader -RestMethod $RestMethod -Verbose:$False -WhatIf:$false )
                        $PointsRequest.PointTransaction
                    }
                    catch {
                        Write-Error -Message "Something didn't work"
                    }
                }
            }
        }
    }
    END {
        # Nothing to see here
    }
}