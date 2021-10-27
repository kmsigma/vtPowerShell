function Get-VtAbuseReport {
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
        DefaultParameterSetName = 'Abuse Report  with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64478/abuse-report-rest-endpoints',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # User ID to use for abuse lookup
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Abuse Report by Author GUID with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Abuse Report by Author GUID with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Abuse Report by Author GUID with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [guid]$UserGuid,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Abuse Report with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ParameterSetName = 'Abuse Report by Author GUID with Authentication Header'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Abuse Report with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Abuse Report by Author GUID with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Abuse Report with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Abuse Report by Author GUID with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Abuse Report with Connection File')]
        [Parameter(ParameterSetName = 'Abuse Report by Author GUID with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$NormalizeHtml,

        # Should we return all details?
        [Parameter()]
        [switch]$ReturnDetails,

        # Size of Batches to Query from the API
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20
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
    
        # Set the Uri for the target
        $Uri = 'api.ashx/v2/abusereports.json'
    
        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageSize"] = $BatchSize
        $UriParameters["PageIndex"] = 0
    
        Write-Verbose -Message "Assigning User GUID for query"
        if ( $UserGuid ) {
            $UriParameters["AuthorUserId"] = $UserGuid
        }
    
        $PropertiesToReturn = @(
            'AbuseReportId',
            'AbuseScore',
            'AbuseReasonId',
            'AppealId',
            @{ Name = 'Author'; Expression = { $_.AuthorUser.DisplayName } },
            @{ Name = 'Url'; Expression = { $_.Content.Url } },
            @{ Name = 'ReportedBy'; Expression = { $_.CreatedUser.DisplayName } },
            'CreatedDate',
            'LastUpdatedDate',
            'ProcessedDate'
        )
        if ( $NormalizeHtml ) {
            $PropertiesToReturn += @(
                @{ Name = 'Name'; Expression = { $_.Content.HtmlName | ConvertFrom-Html -Verbose:$false } },
                @{ Name = 'Body'; Expression = { $_.Content.HtmlDescription | ConvertFrom-Html -Verbose:$false } }
            )
        }
        else {
            $PropertiesToReturn += @(
                @{ Name = 'Name'; Expression = { $_.Content.HtmlName } },
                @{ Name = 'Body'; Expression = { $_.Content.HtmlDescription } }
            )
        }
    }
    PROCESS {
    
        $TotalAbusiveContent = 0
        if ( $PSCmdlet.ShouldProcess("Target", "Operation") ) {
            do {
                Write-Verbose -Message "Making call for Abuse Reports"
                $AbuseReportsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                if ( $AbuseReportsResponse ) {
                    $TotalAbusiveContent += $AbuseReportsResponse.Reports.Count
                    if ( $ReturnDetails ) {
                        $AbuseReportsResponse.Reports
                    }
                    else {
                        $AbuseReportsResponse.Reports | Select-Object -Property $PropertiesToReturn
                    }
                    
                    $UriParameters["PageIndex"]++
                }
            } while ( $TotalAbusiveContent -lt $AbuseReportsResponse.TotalCount )
        }
    }
    
    END {
        # Nothing to see here
    }
}