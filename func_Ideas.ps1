# funct_Ideas.ps1
function Get-VtIdea {
    [CmdletBinding(
        DefaultParameterSetName = 'Thread By Idea Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64723/list-idea-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    param (
        
        # Idea ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Idea Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int64[]]$IdeaId,
        
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'All Ideas'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("All")]
        [switch]$AllIdeas,

        [Parameter()]
        [int64]$GroupId,

        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Details")]
        [switch]$ReturnDetails,

        # Number of entries to get per batch (default of 20)
        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20, 
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [string]$CommunityDomain = $Global:CommunityDomain,

        # Authentication Header for the community
        [Parameter(
            Mandatory = $false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$AuthHeader = $Global:AuthHeader
    )
    
    begin {
        # Validate that the authentication header function is available
        if ( -not ( Get-Command -Name Get-VtAuthHeader -ErrorAction SilentlyContinue ) ) {
            . .\func_Telligent.ps1
        }
        if ( -not ( Get-Command -Name ConvertTo-QueryString -ErrorAction SilentlyContinue ) ) {
            . .\func_Utilities.ps1
        }
        
        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeader = $AuthHeader | Set-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false
        $UriParameters = @{}
        $UriParameters['PageSize'] = $BatchSize
        $UriParameters['PageIndex'] = 0

        if ( $GroupId ) {
            $UriParameters['GroupId'] = $GroupId
        }
        
    }
    process {
        if ( $AllIdeas ) {
            if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Get info about all Ideas'") ) {
                $Uri = 'api.ashx/v2/ideas/ideas.json'
                $IdeaCount = 0
                do {
                    if ( $UriParameters["PageIndex"] -gt 0 ) {
                        Write-Progress -Activity "Querying for Ideas" -Status "Making call #$( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"] ) ideas of $( $IdeaResponse.TotalCount ) total ideas" -PercentComplete ( $IdeaCount / $IdeaResponse.TotalCount * 100 )
                    } else {
                        Write-Progress -Activity "Querying for Ideas" -Status "Making first call for first $( $UriParameters["PageSize"] ) ideas"
                    }
                    $IdeaResponse = Invoke-RestMethod -Uri ( $CommunityDomain + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeader
                    if ( $IdeaResponse ) {
                        if ( -not $ReturnDetails ) {
                            $IdeaResponse.Ideas | Select-Object -Property @{ Name = "IdeaId"; Expression = { $_.Id } }, @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } }, @{ Name = "Status"; Expression = { $_.Status.Name } }, @{ Name = "Author"; Expression = { $_.AuthorUser.Username } }, CreatedDate, LastUpdatedDate, Url, Score, @{ Name = "StatusNote"; Expression = { $_.CurrentStatus.Note } }
                        }
                        else {
                            $IdeaResponse.Ideas
                        }
                        $IdeaCount += $IdeaResponse.Ideas.Count
                    }
                    $UriParameters["PageIndex"]++
                } while ($IdeaCount -lt $IdeaResponse.TotalCount )
                Write-Progress -Activity "Querying for Ideas" -Completed
            }
        }
        else {
            if ( $pscmdlet.ShouldProcess("$CommunityDomain", "Get info about Idea ID: $IdeaId'") ) {
                $Uri = "api.ashx/v2/Ideas/$IdeaId.json"
            }
        }
    }
    
    end {
        
    }
}