function Get-VtForum {
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
        Online REST API Documentation: 
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'All Forums with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64656/Show-Vtforum-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    param (
            
        # Forum ID for the lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Forum Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Forum Id with Connection Profile'
        )]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Forum Id with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int64[]]$ForumId,
            
        [Parameter()]
        [Alias("Details")]
        [switch]$ReturnDetails,
    
        # Number of entries to get per batch (default of 20)
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
        
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Forum Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Forums with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
                
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Forum Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Forums with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Forum Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'All Forums with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
            
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Forum Id with Connection File')]
        [Parameter(ParameterSetName = 'All Forums with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),

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

        $PropertiesToReturn = @(
            @{ Name = "ForumId"; Expression = { $_.Id } }
            'Name'
            @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }
            'Url'
            'Enabled'
            'ThreadCount'
            'ReplyCount'
            'AutoLockingEnabled'
            'AutoLockingDefaultInterval'
            @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }
            @{ Name = "GroupId"; Expression = { $_.Group.Id } }
            @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }
            'LatestPostDate'
        )
    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess( $Community, "Get Forums on" ) ) {
            If ( $ForumId ) {
                # Single call to the API
                $Uri = "api.ashx/v2/forums/$ForumId.json"
                $ForumResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders
                if ( $ForumResponse -and $ReturnDetails ) {
                    $ForumResponse.Forum
                }
                elseif ( $ForumResponse ) {
                    $ForumResponse.Forum | Select-Object -Property $PropertiesToReturn
                }
                
                else {
                    Write-Error -Message "Unable to find a matching gallery"
                }
            

            } else {
                # Get all forums
                $TotalReturned = 0
                $Uri = 'api.ashx/v2/forums.json'
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $ForumResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $ForumResponse ) {
                        $TotalReturned += $ForumResponse.Forums.Count
                        if ( $ReturnDetails ) {
                            $ForumResponse.Forums
                        }
                        else {
                            $ForumResponse.Forums | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $ForumResponse.TotalCount)
            }
        }
    }
        
    END {
        # Nothing to see here
    }
}