function Set-VtGroup {
    <#
    .Synopsis
        Updates a group
    .DESCRIPTION
        TBD
    .EXAMPLE
        TBD
    .EXAMPLE
        TBD
    .INPUTS
        TBD
    .OUTPUTS
        TDB
    .NOTES
        TDB
    #>
    [CmdletBinding(DefaultParameterSetName = 'Group Id with Connection File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/12/w/api-documentation/71310/update-group-rest-endpoint',
        ConfirmImpact = 'High')]
    Param
    (
    
        # The group ids on which to operate.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = 'Group Id with Authentication Header')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = 'Group Id with Connection Profile')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = 'Group Id with Connection File')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Id")] 
        [int64[]]$GroupId,
    
        # The full displayed name of the Group
        [Parameter(Mandatory = $false)]
        [string]$Name,

        # the key or "slug" of the group (appears in the URL).
        [Parameter(Mandatory = $false)]
        [string]$Key,

        # The description for the group.  Should be 256 characters or less
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        # Group Type
        [Parameter(Mandatory = $false)]
        [ValidateSet('Joinless', 'PublicOpen', 'PublicClosed', 'PrivateUnlisted', 'PrivateListed')]
        [string]$GroupType,

        # If we change the ParentGroupId, the group is "moved"
        [Parameter(Mandatory = $false)]
        [int64]$ParentGroupId,

        # Enable Group Messages ( Allows users to post status messages to the group. ) [Defaults to false]
        [Parameter(Mandatory = $false)]
        [switch]$EnableGroupMessages,
        
        # Key-Value pairs of extended attributes
        [Parameter(Mandatory = $false)]
        [hashtable]$ExtendedAttributes,
        
        # Do you want to return the details?
        [Parameter(Mandatory = $false)]
        [switch]$ReturnDetails = $false,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("AuthHeader")]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(Mandatory = $true, ParameterSetName = 'Group Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'Group Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )
    )
    
    BEGIN {
    
        # REST and HTTP methods to use for the change
        $HttpMethod = "Post"
        $RestMethod = "Put"
    
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

        # Build the empty body to contain the data
        $Body = @{}
        if ( $Name ) { $Body["Name"] = $Name }
        if ( $Description ) { $Body["Description"] = $Description }
        if ( $Key ) { $Body["Key"] = $Key }
        if ( $GroupType ) { $Body["GroupType"] = $GroupType }
        if ( $ParentGroupId ) { $Body["ParentGroupId"] = $ParentGroupId }
        if ( $EnableGroupMessages ) { $Body["EnableGroupMessages"] = $EnableGroupMessages }
        # Have zero clue how to get this to work.
        if ( $ExtendedAttributes ) { $Body["ExtendedAttributes"] = $ExtendedAttributes }

        if ( $ParentGroupId ) {
            $ParentGroup = Get-VtGroup -WhatIf:$false -Verbose:$false | Where-Object { $_.GroupId -eq $ParentGroupId }
            if ( -not $ParentGroup ) {
                Write-Error -Message "Unable to determine new parent group with id: $ParentGroupId" -RecommendedAction "Please validate the group to which you'd like to move this group"
                break
            }
        }

        # Build a lookup to xref the returned name with the "friendly" name
        $GroupTypeLookup = @{}
        $GroupTypeLookup['Joinless'] = 'Joinless'
        $GroupTypeLookup['PublicOpen'] = 'Public (Open Membership)'
        $GroupTypeLookup['PublicClosed'] = 'Public (Closed Membership)'
        $GroupTypeLookup['PrivateListed'] = 'Private (Listed)'
        $GroupTypeLookup['PrivateUnlisted'] = 'Private (Unlisted)'

        $PropertiesToReturn = @(
            @{ Name = "GroupId"; Expression = { [int64]( $_.Id ) } }
            @{ Name = "ContainerId"; Expression = { $_.ContainerId } }
            @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } }
            "Key"
            @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }
            "DateCreated"
            "Url"
            @{ Name = "GroupType"; Expression = { $GroupTypeLookup[$_.GroupType] } }
            "ParentGroupId"
        )
    }
    PROCESS {
        ForEach ( $g in $GroupId ) {
            $Group = Get-VtGroup -WhatIf:$false -Verbose:$false | Where-Object { $_.GroupId -eq $g }
            if ( $Group ) {
                $Uri = "api.ashx/v2/groups/$( $Group.GroupId ).json"
                # Should check to see if there's any actual change happening here

                if ( $PSCmdlet.ShouldProcess($Community, "Update Group: '$( $Group.Name )' [ID: $( $Group.GroupId )] [Updates:$( ( $Body.GetEnumerator() | ForEach-Object { " '$( $_.Name )' to '$( $_.Value )'" } ) -join "; " )]") ) {
                    $Response = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers ( $AuthHeaders | Update-VtAuthHeader -RestMethod $RestMethod ) -Method $HttpMethod -Body $Body
                    if ( $Response ) {
                        # Got a respose
                        if ( $ReturnDetails ) {
                            $Response.Group
                        } else {
                            $Response.Group | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    else {
                        Write-Error -Message "Error in call to API"
                    }
                }

            } else {
                Write-Error -Message "Unable to find group with ID: $g"
            }
            

        }
    }
    
    END {
        # Nothing here
    }
}