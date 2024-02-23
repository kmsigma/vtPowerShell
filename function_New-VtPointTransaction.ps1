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
        DefaultParameterSetName = 'Username with Connection File',
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
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Username with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Username with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Username with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username,
        
        # The username of the account who is getting the points
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'User ID with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'User ID with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'User ID with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64[]]$UserId,
    
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
        [string]$Description,
    
        # The date/time you want to have the awards added - defaults to 'now'
        [Parameter(
            Mandatory = $false, 
            Position = 3
        )]
        [datetime]$AwardDateTime = ( Get-Date ),

        # Optional ContentId
        [Parameter(
            Mandatory = $false, 
            Position = 4
        )]
        [guid]$ContentId,

        # Optional ContentTypeId
        [Parameter(
            Mandatory = $false,
            Position = 5
        )]
        [guid]$ContentTypeId,

        [Parameter()]
        [switch]$ReturnDetails,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User ID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("AuthHeader")]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Username with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'User ID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Username with Connection File')]
        [Parameter(ParameterSetName = 'User ID with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )
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

        $Uri = "api.ashx/v2/pointtransactions.json"

        $PropertiesToReturn = @(
            @{ Name = "UserId"; Expression = { $_.User.id } }
            @{ Name = "Username"; Expression = { $_.User.Username } }
            'CreatedDate'
            'Value'
            @{ Name = 'Content'; Expression = { $_.Content.HtmlName | ConvertFrom-VtHtmlString } }
            @{ Name = 'Transaction'; Expression = { $_.id } }
        )
    }
    
    PROCESS {
    
        if ( $PSCmdlet.ParameterSetName -like 'Username *' ) {
            # By Username
            # Convert Usernames to User IDs

            $UserId = $Username | ForEach-Object { Get-VtUser -Username $_ -Community $Community -AuthHeader $AuthHeaders -ErrorAction SilentlyContinue | Select-Object -ExpandProperty UserId }
        }

        ForEach ( $U in $UserId ) {
            if ( -not $ContentId -or $ContentTypeId ) {
                $User = Get-VtUser -UserId $U -Community $Community -AuthHeader $AuthHeaders -ReturnDetails -ErrorAction SilentlyContinue
            }

            if ( -not $ContentId ) {
                $ContentId = $User.ContentId
            }

            if ( -not $ContentTypeId ) {
                $ContentTypeId = $User.ContentTypeId
            }

            if ( $PSCmdlet.ShouldProcess("User: $( $User.DisplayName )", "Add $Points points") ) {

                $PointsBody = @{
                    Description   = '<p>' + $Description + '</p>'
                    UserId        = $U
                    Value         = $Points
                    ContentId     = $ContentId
                    ContentTypeId = $ContentTypeId
                    CreatedDate   = $AwardDateTime
                }

                try {
                    $PointsRequest = Invoke-RestMethod -Uri ( $Community + $Uri ) -Method 'Post' -Body $PointsBody -Headers $AuthHeaders
                    if ( $ReturnDetails ) {
                        $PointsRequest.PointTransaction
                    }
                    else {
                        $PointsRequest.PointTransaction | Select-Object -Property $PropertiesToReturn
                    }
                }
                catch {
                    Write-Error -Message "Something didn't work when trying to assign $Points to User ID: $U"
                }
            }
        }
    }
    END {
        # Nothing to see here
    }
}