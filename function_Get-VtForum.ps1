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
        DefaultParameterSetName = 'Thread By Forum Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64656/Show-Vtforum-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    param (
            
        # Forum ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Forum Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")]
        [int64[]]$ForumId,
            
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'All Forums'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("All")]
        [switch]$AllForums,
    
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
        $UriParameters = @{}
        $UriParameters['PageSize'] = $BatchSize
        $UriParameters['PageIndex'] = 0
            
    }
    PROCESS {
        if ( $AllForums ) {
            if ( $PSCmdlet.ShouldProcess("$VtCommunity", "Get info about all forums'") ) {
                $Uri = 'api.ashx/v2/forums.json'
                $ForumCount = 0
                do {
                    $ForumResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $ForumResponse ) {
                        if ( -not $ReturnDetails ) {
                            $ForumResponse.Forums | Select-Object -Property @{ Name = 'ForumId'; Expression = { $_.Id } }, Title, Key, Url, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode($_.Group.Name) } }, @{ Name = "GroupKey"; Expression = { $_.Group.Key } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "AllowedThreadTypes"; Expression = { ( $_.AllowedThreadTypes.Value | Sort-Object ) -join ", " } }, DefaultThreadType, LatestPostDate, Enabled, ThreadCount, ReplyCount
                        }
                        else {
                            $ForumResponse.Forums
                        }
                        $ForumCount += $ForumResponse.Forums.Count
                    }
                    $UriParameters["PageIndex"]++
                } while ($ForumCount -lt $ForumResponse.TotalCount )
            }
        }
        else {
            if ( $PSCmdlet.ShouldProcess("$VtCommunity", "Get info about Forum ID: $ForumId'") ) {
                $Uri = "api.ashx/v2/forums/$ForumId.json"
                $ForumResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders
                if ( $ForumResponse ) {
                    if ( -not $ReturnDetails ) {
                        $ForumResponse.Forum | Select-Object -Property @{ Name = 'ForumId'; Expression = { $_.Id } }, Title, Key, Url, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode($_.Group.Name) } }, @{ Name = "GroupKey"; Expression = { $_.Group.Key } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "AllowedThreadTypes"; Expression = { ( $_.AllowedThreadTypes.Value | Sort-Object ) -join ", " } }, DefaultThreadType, LatestPostDate, Enabled, ThreadCount, ReplyCount
                    }
                    else {
                        $ForumResponse.Forum
                    }
                }
            }
        }
    }
        
    END {
            
    }
}