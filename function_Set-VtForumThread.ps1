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
            $Global:VtAuthHeader = ConvertTo-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: 
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Thread and Forum Id with Connection File',
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
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64[]]$ForumId,
    
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Thread and Forum Id with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int64[]]$ThreadId,
    
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
        [datetime]$StickyDate = ( Get-Date ).AddDays(7),
    
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [switch]$FeatureThread,

        [Parameter()]
        [Alias("Details")]
        [switch]$ReturnDetails,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread and Forum Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
                
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread and Forum Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Thread and Forum Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
            
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Thread and Forum Id with Connection File')]
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
        $AuthHeaders = $AuthHeaders | Update-VtAuthHeader -RestMethod Put -Verbose:$false -WhatIf:$false
        $HttpMethod = "Post"

        $PropertiesToReturn = @(
            @{ Name = "ThreadId"; Expression = { $_.Id } }
            @{ Name = "GroupId"; Expression = { $_.GroupId } }
            @{ Name = "ForumId"; Expression = { $_.ForumId } }
            'ThreadStatus'
            'ThreadType'
            'Date'
            'LatestPostDate'
            'Url'
            'Subject'
            'IsLocked'
            @{ Name = 'Author'; Expression = { $_.Author.DisplayName } }
            'ViewCount'
            'ReplyCount'
            @{ Name = "Tags"; Expression = { $_.Tags.Value -join ", " } }
        )
    }
        
    PROCESS {
        <#
            HTTP Method: POST
            Auth Header: PUT
            Uri = api.ashx/v2/forums/{forumid}/threads/{threadid}.json
            #>
    
        if ( $PSCmdlet.ShouldProcess("$Community", "Update Threads") ) {
            if ( $ThreadId.Count -eq $ForumId.Count -and $ThreadId.Count -gt 1 ) {
                For ( $i = 0; $i -lt $ThreadId.Count; $i++ ) {
                    $Uri = "api.ashx/v2/forums/$( $ForumId[$i] )/threads/$( $ThreadId[$i] ).json"
                    Write-Host "Uri: $Uri"
                }
            }
            else {
                if ( $PSCmdlet.ShouldProcess("$Community", "Update Threads $ThreadId in Forum $ForumId'") ) {
                    $Uri = "api.ashx/v2/forums/$ForumId/threads/$ThreadId.json"
                    $UpdateResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -Method $HttpMethod
                    if ( $UpdateResponse ) {
                        if ( $ReturnDetails ) {
                            $UpdateResponse.Thread
                        }
                        else {
                            $UpdateResponse.Thread | Select-Object -Property $PropertiesToReturn
                        }
                    }
                }
            }
        }
    }
        
    END {
        # Nothing to see here
    }
}