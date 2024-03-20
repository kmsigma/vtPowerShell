function Set-VtGalleryMedia {
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
        DefaultParameterSetName = 'File Id and Gallery Id with Connection File',
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64768/update-media-rest-endpoint',
        ConfirmImpact = 'High'
    )]
    Param
    (
        # File Id on which to Operate
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id with Authentication Header'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id with Connection Profile'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id with Connection File'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Authentication Header'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection Profile'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection File'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Tags List) with Authentication Header'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection Profile'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("MediaFileId", "MediaId")] 
        [int64[]]$FileId,
    
        # Gallery Id on which to operate
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id with Authentication Header'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id with Connection Profile'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id with Connection File'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Authentication Header'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection Profile'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection File'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Tags List) with Authentication Header'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection Profile'
        )]
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection File'
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]        
        [int64[]]$GalleryId,
    
        # The Title of the media
        [Parameter(ParameterSetName = 'File Id and Gallery Id with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id with Connection File')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection File')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection File')]
        [Alias("Title")] 
        [string]$Name,
    
        # Media Description [HTML formatted]
        [Parameter(ParameterSetName = 'File Id and Gallery Id with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id with Connection File')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection File')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection File')]
        [Alias("Body")]
        [string]$Description,
    
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection File')]
        [string[]]$AddTag,
    
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection File')]
        [string[]]$RemoveTag,
    
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Authentication Header')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection Profile')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection File')]
        [string[]]$Tags,
    
        # If enabled, then return the new object, otherwise return nothing
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$PassThru,
    
        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id (Tags List) with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,

        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Authentication Header')]
        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id (Tags List) with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,

        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection Profile')]
        [Parameter(Mandatory = $true, ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,

        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'File Id and Gallery Id with Connection File')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Add/Remove Tags) with Connection File')]
        [Parameter(ParameterSetName = 'File Id and Gallery Id (Tags List) with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false
        )]
        [switch]$ReturnDetails
    
    )
    
    BEGIN {
        Write-Verbose -Message "Detected Parameter Set: $( $PSCmdlet.ParameterSetName )"
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

        $PropertiesToReturn = @(
            @{ Name = "FileId"; Expression = { $_.Id } }
            @{ Name = "GalleryId"; Expression = { $_.MediaGalleryId } }
            'GroupId'
            @{ Name = "Author"; Expression = { $_.Author.Username } }
            'Date'
            @{ Name = "Title"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Title ) } }
            @{ Name = "Tags"; Expression = { ( $_.Tags | ForEach-Object { [System.Web.HttpUtility]::HtmlDecode( $_.Value ) } ) } }
            'Url'
            'CommentCount'
            'Views'
            'Downloads'
            'RatingCount'
            'RatingSum'
        )


    
    }
    
    PROCESS {
        
        Write-Verbose -Message "Retrieving File Details"
        $File = Get-VtGalleryMedia -GalleryId $GalleryId -FileId $FileId -VtCommunity $Community -VtAuthHeader $AuthHeaders -WhatIf:$false
        
        Write-Verbose -Message "Current Tag List: $( $File.Tags -join ", " )"

        # Setup the parameters
        $UriParameters = @{}
    
        if ( $Name ) {
            Write-Verbose -Message "Writing '$Name' to 'Name' Uri Parameters"
            $UriParameters["Name"] = $Name
        }
            
        if ( $Description ) {
            Write-Verbose -Message "Writing '$Description' to 'Description' Uri Parameters"
            $UriParameters["Description"] = $Description
        }
            
        switch -Wildcard ( $PSCmdlet.ParameterSetName ) {
            '*(Add/Remove Tags)*' { 
                Write-Verbose -Message "Found Tags to Add/Remove"
                # Get Current List of Tags - we must use an ArrayList type or the .Add and .Remove methods are blocked
                $WorkingTagList = New-Object -TypeName System.Collections.ArrayList
                $OriginalTagList = New-Object -TypeName System.Collections.ArrayList
                $File.Tags | ForEach-Object { $WorkingTagList.Add($_) | Out-Null }
                $File.Tags | ForEach-Object { $OriginalTagList.Add($_) | Out-Null }
                Write-Verbose -Message "Current Tag List: $( $OriginalTagList -join ',' )"
                ForEach ( $R in $RemoveTag ) {
                    if ( $WorkingTagList -contains $R ) {
                        Write-Verbose -Message "Removing '$R' from the Tag list"
                        $WorkingTagList.Remove($R) | Out-Null
                    }
                    else {
                        Write-Verbose -Message "Account '$R' is not listed as an Tag"
                    }
                }
                ForEach ( $A in $AddTag ) {
                    if ( $WorkingTagList -contains $A ) {
                        Write-Verbose -Message "Account '$A' already listed as an Tag"
                    }
                    else {
                        Write-Verbose -Message "Adding '$A' to the Tag list"
                        $WorkingTagList.Add( [System.Web.HttpUtility]::UrlEncode($A) ) | Out-Null
                    }
                }
                # Build the list of Tags as a comma separated list (sorted is not necessary, but nice)
                $TagList = ( $WorkingTagList | Sort-Object ) -join ","
                # Add it to the parameter list for the URI
                if ( Compare-Object -ReferenceObject $OriginalTagList -DifferenceObject $WorkingTagList  ) {
                    Write-Verbose -Message "Updated Tag List: $( $WorkingTagList -join ',' )"
                    $UriParameters["Tags"] = $TagList
                }
                else {
                    Write-Warning -Message "Processed Tags: No change detected"
                }
    
            }
            '*(Tags List)*' {
                Write-Verbose -Message "Found Tags to Update"
                $Tags = $Tags | Sort-Object
                if ( Compare-Object -ReferenceObject $File.Tags -DifferenceObject $Tags ) {
                    # Build the list of Tags as a comma separated list (sorted is not necessary, but nice)
                    $TagList = ( $Tags | Sort-Object ) -join ','
                    # Add it to the parameter list for the URI
                    $UriParameters["Tags"] = $TagList
                }
                else {
                    Write-Warning -Message "Processed Tags: No change detected"
                }
            }
            Default { Write-Verbose -Message "No Tag change detected" }
        }
        
        $Uri = "api.ashx/v2/media/$GalleryId/files/$FileId.json"

        if ( -not $UriParameters ) {
            # If we have no parameters to change, then there's nothing to do
            Write-Error -Message "Function requires Name, Description, or Tags parameter" -RecommendedAction "Pass -Name, -Description, or -Tags parameters."
        }
        else {
            if ( $PSCmdlet.ShouldProcess("Update '$( $File.Title )'", "Update $( $UriParameters.Keys -join ", " )") ) {
                $Response = Invoke-RestMethod -Method Post -Uri ( $Community + $Uri ) -Body ( $UriParameters  ) -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod "Put" -WhatIf:$false )
                if ( $Response ) {
                    if ( $PassThru ) {
                        if ( $ReturnDetails ) {
                            $Response.Media
                        }
                        else {
                            $Response.Media | Select-Object -Property $PropertiesToReturn
                        }
                    }
                }
                else {
                    Write-Error -Message "Unable to update '$FileId' in Gallery ID '$GalleryId'"
                }
            }
        }
            
    }
    END {
        # Nothing to see here
    }
}