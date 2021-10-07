function Set-VtForumThread {
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
            $Global:VtAuthHeader = Get-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: 
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Thread and Forum Id',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64666/update-forum-thread-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        # Forum ID for the lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64]$ForumId,
    
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64]$ThreadId,
    
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$LockThread,
    
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$StickyThread,
    
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [date]$StickyDate = ( Get-VtDate ).AddDays(7),
    
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$FeatureThread,
    
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
            
        $UriParameters = @{}
        if ( $LockThread ) {
            $UriParameters["IsLocked"] = 'true'
        }
        if ( $StickyThread ) {
            $UriParameters["IsSticky"] = 'true'
            $UriParameters["StickyDate"] = $StickyDate
        }
        if ( $FeatureThread ) {
            $UriParameters["IsFeatured"] = 'true'
        }
        # Update the authentication header for to "Put"
        $VtAuthHeader = $VtAuthHeader | Set-VtAuthHeader -RestMethod Put -Verbose:$false -WhatIf:$false
        $HttpMethod = "Post"
    }
        
    PROCESS {
        <#
            HTTP Method: POST
            Auth Header: PUT
            Uri = api.ashx/v2/forums/{forumid}/threads/{threadid}.json
            #>
    
        if ( $pscmdlet.ShouldProcess("$VtCommunity", "Update Thread $ThreadId in Forum $ForumId'") ) {
            $Uri = "api.ashx/v2/forums/$ForumId/threads/$ThreadId.json"
            $UpdateResponse = Invoke-RestMethod -Uri ( $VtCommunity + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $VtAuthHeader -Method $HttpMethod
            if ( $UpdateResponse ) {
                $UpdateResponse
            }
        }
    }
        
    END {
        # Nothing to see here
    }
}