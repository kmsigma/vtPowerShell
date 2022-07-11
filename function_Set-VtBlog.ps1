function Set-VtBlog {
    <#
    .Synopsis
        Update a Verint Blog
    .DESCRIPTION
        This uses the REST API to update a blog.  It can update the Name, Description, Key (slug used in URL), Authors, and enable/disable the blog.
    .EXAMPLE
        $Global:VtCommunity = 'https://myCommunityDomain.domain.local/'
    PS > $Global:VtAuthHeader = ConvertTo-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    
    PS > $Blog = Get-VtBlog | Where-Object { $_.Name -eq "My Community Blog" } 
    PS > $Blog | Set-VtBlog -GroupId 11
    
    Storing the VtCommunity and VtAuthHeader as Global variables, we do not need to include in the parameter sets.
    We retrieve any blog with the name "My Community Blog" from the API.
    Then we set that Blog (or multiple blogs if the names match) to be part of Group with ID 11. (Move the Blog)
    
    .EXAMPLE
        $Authors = "displayName1", "displayName2", "displayName3"
    PS > Set-VtBlog -BlogId 6 -Authors $Authors -Community "https://mycommunity.telligenthosting.com/" -AuthHeader $VtAuthHeader
    PS > $NewAuthors = "displayName4", "displayName5", "displayName6"
    PS > Set-VtBlog -BlogId 6 -Authors $Authors -Community "https://mycommunity.telligenthosting.com/" -AuthHeader $VtAuthHeader
    
    This will update the list of authors to be displayName1, 2, and 3 on the blog with ID 6.
    Then it will update the list of authors to be displayName4, 5, and 6 on the blog with ID 6.
    
    When completed, only displayName4, 5, and 6 will be listed as authors.
    .EXAMPLE
        Set-VtBlog -BlogId 11 -AddAuthors "me", "myself", "I" -Community "https://mycommunity.telligenthosting.com/" -AuthHeader $VtAuthHeader
    
    This will take the existing authors and add the above 3 to the list.
    .EXAMPLE
        Set-VtBlog -BlogId 13 -RemoveAuthors "removeMe", "removeHim", "removeHer" -Community "https://mycommunity.telligenthosting.com/" -AuthHeader $VtAuthHeader
    
    This will take the existing authors and remove the above 3 from the list.
    .INPUTS
        System.Int64
            You can pipeline in the blog id on which to operate
    .OUTPUTS
        Custom PowerShell Object containing the blog information
    .NOTES
        Refer to https://community.telligent.com/community/11/w/api-documentation/64540/update-blog-rest-endpoint for more information.
    
        You can optionally store the VtCommunity and the VtAuthHeader as global variables and omit passing them as parameters
        Eg: $Global:VtCommunity = 'https://myCommunityDomain.domain.local/'
            $Global:VtAuthHeader = ConvertTo-VtAuthHeader -Username "CommAdmin" -Key "absgedgeashdhsns"
    .COMPONENT
        TBD
    .ROLE
        TBD
    .LINK
        Online REST API Documentation: https://community.telligent.com/community/11/w/api-documentation/64540/update-blog-rest-endpoint
    #>
    [CmdletBinding(DefaultParameterSetName = 'Blog By Id with Connection File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64540/update-blog-rest-endpoint',
        ConfirmImpact = 'High')]
    Param
    (
        # Blog Id for Lookup
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Blog By Id with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Blog By Id with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Blog By Id with Connection File'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Blog By Id (Authors List) with Authentication Header'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Blog By Id (Authors List) with Connection Profile'
        )]
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Blog By Id (Authors List) with Connection File'
        )]
        [ValidateRange("Positive")]
        [Alias("Id")] 
        [int64[]]$BlogId,
    
        # Update the key/slug used in the URL.  No spaces accepted.  Will automatically be converted to lowercase
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection File')]
        [ValidateLength(1, 255)]
        [ValidateScript( {
                if ( $_ -match '^[a-zA-Z\d-]*$' ) {
                    $true
                }
                else {
                    throw "'$_' is invalid. Keys must contain alpha-numeric and dashes only. (Example: 'tech docs' is invalid, but 'tech-docs' or 'techdocs' is ok."
                }
            }
        )]
        [Alias("Slug")] 
        [string]$Key,
    
        # Update the blog name
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection File')]
        [ValidateLength(1, 255)]
        [string]$Name,
    
        # Update the blog's decription
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection File')]
        [ValidateLength(0, 999)] # Just noticed that the blog description is limited to 1000 characters
        [string]$Description,

        # Update the blog's default image
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection File')]
        [ValidateLength(0, 999)] # Just noticed that the blog description is limited to 1000 characters
        [string]$DefaultPostImageUrl,
    
        # Update the blog's parent group (move the blog)
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection File')]
        [int64]$GroupId,
    
        # Flag the blog as disabled
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection File')]
        [Parameter(ParameterSetName = 'Blog By Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id with Connection File')]
        [switch]$Disabled,
            
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [string[]]$AddAuthor,
    
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [string[]]$RemoveAuthor,
    
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection Profile')]
        [Parameter(ParameterSetName = 'Blog By Id (Authors List) with Connection File')]
        [string[]]$Authors,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id (Authors List) with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id (Add/Remove Author) with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id (Authors List) with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id (Add/Remove Author) with Connection File')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id (Authors List) with Connection File')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Blog By Id with Connection File')]
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
    
        # Check the authentication header for any 'Rest-Method' and revert to a traditional "get"
        $AuthHeaders = $AuthHeaders | Update-VtAuthHeader -RestMethod Get -Verbose:$false -WhatIf:$false

        $UriParameters = @{}
        if ( $GroupId ) { $UriParameters["GroupId"] = $GroupId }
        if ( $Key ) { $UriParameters["Key"] = $Key.ToLower() }
        if ( $Name ) { $UriParameters["Name"] = $Name }
        if ( $Description ) { $UriParameters["Description"] = $Description }
        if ( $DefaultPostImageUrl ) { $UriParameters["DefaultPostImageUrl"] = $DefaultPostImageUrl }
    }
    PROCESS {
        ForEach ( $b in $BlogId ) {
            # Get the blog because we'll want it for some later things
            $Blog = Get-VtBlog -BlogId $b -VtCommunity $Community -VtAuthHeader $AuthHeaders -Verbose:$false -WhatIf:$false
    
            # Is the blog enabled and so we want to disable it?
            if ( $Blog.Enabled -and $Disabled ) {
                $UriParameters["Enabled"] = $false
            }
            # How about currently disabled and we want to enable it?
            elseif ( ( -not ( $Blog.Enabled ) ) -and ( -not ( $Disabled ) ) ) {
                $UriParameters["Enabled"] = $true
            }

    
            switch -Wildcard ( $PSCmdlet.ParameterSetName ) {
                '*(Add/Remove Author)*' { 
                    # Get Current List of Authors - we must use an ArrayList type or the .Add and .Remove methods are blocked
                    $WorkingAuthorList = New-Object -TypeName System.Collections.ArrayList
                    $OriginalAuthorList = New-Object -TypeName System.Collections.ArrayList
                    $Blog.Authors | ForEach-Object { $WorkingAuthorList.Add($_) | Out-Null }
                    $Blog.Authors | ForEach-Object { $OriginalAuthorList.Add($_) | Out-Null }
                    ForEach ( $R in $RemoveAuthor ) {
                        if ( $WorkingAuthorList -contains $R ) {
                            Write-Verbose -Message "Removing '$R' from the author list"
                            $WorkingAuthorList.Remove($R) | Out-Null
                        }
                        else {
                            Write-Verbose -Message "Account '$R' is not listed as an author"
                        }
                    }
                    ForEach ( $A in $AddAuthor ) {
                        if ( $WorkingAuthorList -contains $A ) {
                            Write-Verbose -Message "Account '$A' already listed as an author"
                        }
                        else {
                            Write-Verbose -Message "Adding '$A' to the author list"
                            $WorkingAuthorList.Add($A) | Out-Null
                        }
                    }
                    # Build the list of authors as a comma separated list (sorted is not necessary, but nice)
                    $AuthorList = ( $WorkingAuthorList | Sort-Object ) -join ","
                    # Add it to the parameter list for the URI
                    if ( Compare-Object -ReferenceObject $OriginalAuthorList -DifferenceObject $WorkingAuthorList  ) {
                        $UriParameters["Authors"] = $AuthorList
                    }
                    else {
                        Write-Warning -Message "Processed Authors: No change detected"
                    }
        
                }
                '*(Authors List)*' {
                    $Authors = $Authors | Sort-Object
                    if ( Compare-Object -ReferenceObject $Blog.Authors -DifferenceObject $Authors ) {
                        # Build the list of authors as a comma separated list (sorted is not necessary, but nice)
                        $AuthorList = ( $Authors | Sort-Object ) -join ","
                        # Add it to the parameter list for the URI
                        $UriParameters["Authors"] = $AuthorList
                    }
                    else {
                        Write-Warning -Message "Processed Authors: No change detected"
                    }
                }
                Default { Write-Verbose -Message "No author change detected" }
            }
    
            if ( $UriParameters.Count -gt 0 ) {
                if ( $PSCmdlet.ShouldProcess("Blog: '$( $Blog.Name )' in '$( $Blog.GroupName )'", "Update $( $UriParameters.Keys -join ", " )") ) {
                    $Uri = "api.ashx/v2/blogs/$BlogId.json"
    
                    $Result = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Method "Post" -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod "Put" -WhatIf:$false )
                    if ( $Result ) {
                        $Result.Blog | Select-Object -Property @{ Name = "BlogId"; Expression = { $_.Id } }, Name, Key, Url, Description, Enabled, PostCount, CommentCount, @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }, @{ Name = "GroupId"; Expression = { $_.Group.Id } }, @{ Name = "GroupType"; Expression = { $_.Group.GroupType } }, @{ Name = "Authors"; Expression = { ( $_.Authors | ForEach-Object { $_ | Select-Object -ExpandProperty DisplayName } ) } }
                    }
                }
            }
            else {
                Write-Warning -Message "No changes detected, not processing request"
            }
        }
    }
    END {
        # Nothing to see here
    }
}