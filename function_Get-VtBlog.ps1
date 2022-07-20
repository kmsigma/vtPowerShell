function Get-VtBlog {
    <#
    .Synopsis
        Get blog from a Verint Community
    .DESCRIPTION
        Get a single or multiple blogs from a Verint Community
    .EXAMPLE
        Get-VtBlog -BlogId 6
    
        BlogId       : 6
        Name         : Generic Blog
        Key          : generic-blog
        Url          : https://mycommunity.com/company-blogs/b/generic-blog
        Enabled      : True
        PostCount    : 134
        CommentCount : 281
        GroupName    : Company Blogs
        GroupId      : 11
        GroupType    : Joinless
        Authors      : {displayName1, displayName3, displayName42, displ…}
    .EXAMPLE
        Get-VtBlog -BlogId 6 -ReturnDetails
    
        Similar to above example, except all the data is returned and it not presented in 'clean' way
    .EXAMPLE
        Get-VtBlog | Where-Object { $_.Authors -contains 'displayName1' }
    
        Returns an array of all blogs where 'displayName1' is listed as an author of the blog
    .EXAMPLE
        $Blogs = Get-VtBlog | Where-Object { $_.Authors }
        PS > $Blogs.Authors | Select-Object -Unique | Get-VtUser
    
        Retrieves a list of blogs where authors are defined, then gets the information on said author based on their Username
    
        .OUTPUTS
    
        .NOTES
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Blog By Id with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64538/list-blog-rest-endpoint',
        ConfirmImpact = 'Low'
    )]
    Param
    (
        # Blog Id for Lookup
        [Parameter(Mandatory = $false, ParameterSetName = 'Blog By Name with Authentication Header')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Blog By Id with Connection Profile')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Blog By Id with Connection File')]
        [Alias("Id")] 
        [int64]$BlogId,
    
        # Group Id for Lookup
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [int64]$GroupId,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Name with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Name with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Name with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Blog By Name Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),
    
        # Should we return all details?
        [Parameter()]
        [switch]$ReturnDetails,
    
        # Number of entries to get per batch (default of 20)
        [Parameter()]
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

        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeaders = $AuthHeaders | Update-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false
    
        # Set default page index, page size, and add any other filters
        $UriParameters = @{}
        $UriParameters["PageIndex"] = 0
        $UriParameters["PageSize"] = $BatchSize

        $PropertiesToReturn = @(
            @{ Name = "BlogId"; Expression = { $_.Id } }
            'Name'
            'Description'
            'Key'
            'Url'
            'Enabled'
            'PostCount'
            'CommentCount'
            @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }
            @{ Name = "GroupId"; Expression = { $_.Group.Id } }
            @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }
            'DefaultPostImageUrl'
            @{ Name = "Authors"; Expression = { ( $_.Authors | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
        )
    
    }
    PROCESS {
        if ( $PSCmdlet.ShouldProcess( $VtCommunity, "Query Blogs on" ) ) {
            
            if ( $BlogId -and -not $GroupId) {
                # If we have a BlogId and NOT a GroupId, return the single blog
                $Uri = "api.ashx/v2/blogs/$BlogId.json"
                $Type = 'Single'
            }
            elseif ( $BlogId -and $GroupId ) {
                # If we have a BlogId and a GroupId, return the single blog within that group
                $Uri = "api.ashx/v2/groups/$GroupId/blogs/$BlogId.json"
                $Type = 'Single'
            }
            elseif ( -not $BlogId -and $GroupId ) {
                # If we do NOT have a BlogId but we have a GroupId, return all blogs within that group
                $Uri = "api.ashx/v2/groups/$GroupId/blogs.json"
                $Type = 'Multiple'
            }
            else {
                # If we have neither a BlogId nor a GroupId, list all the blogs
                $Uri = "api.ashx/v2/blogs.json"
                $Type = 'Multiple'
            }
            
            if ( $Type -eq 'Single' ) {
                $BlogsResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders
                if ( $BlogsResponse ) {
                    if ( $ReturnDetails ) {
                        $BlogsResponse.Blog
                    }
                    else {
                        $BlogsResponse.Blog | Select-Object -Property $PropertiesToReturn
                    }
                }
                else {
                    Write-Error -Message "No blogs matching ID $BlogId found."
                }
            }
            else {
                # Multiple returns
                
                $TotalReturned = 0
                do {
                    Write-Verbose -Message "Making call $( $UriParameters["PageIndex"] + 1 ) for $( $UriParameters["PageSize"]) records"
                    $BlogsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
                    if ( $BlogsResponse ) {
                        $TotalReturned += $BlogsResponse.Blogs.Count
                        if ( $ReturnDetails ) {
                            $BlogsResponse.Blogs
                        }
                        else {
                            $BlogsResponse.Blogs | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    $UriParameters["PageIndex"]++
                } while ($TotalReturned -lt $BlogsResponse.TotalCount)
            }
            
        } #end of 'should process'
    }
    END {
        # Nothing to see here
    }
}