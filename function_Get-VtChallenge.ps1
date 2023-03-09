function Get-VtChallenge {
    <#
    .Synopsis
        Get challenges from Verint / Telligent communities
    .DESCRIPTION
        Long description
    .EXAMPLE
        Example of how to use this cmdlet
    .EXAMPLE
        Another example of how to use this cmdlet
    .INPUTS
        Inputs to this cmdlet (if any)
    .OUTPUTS
        Output from this cmdlet (if any)
    .NOTES
        https://community.telligent.com/community/11/w/api-documentation/64558/list-challenge-rest-endpoint
    .COMPONENT
        The component this cmdlet belongs to
    .ROLE
        The role this cmdlet belongs to
    .FUNCTIONALITY
        The functionality that best describes this cmdlet
    #>
    [CmdletBinding(DefaultParameterSetName = 'All ideations with Connection File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'https://community.telligent.com/community/11/w/api-documentation/64555/challenge-rest-endpoints',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType()]
    Param
    (

        # Get challenge by name
        [Parameter(ParameterSetName = 'Ideation by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Ideation by Name with Connection Profile')]
        [Parameter(ParameterSetName = 'Ideation by Name with Connection File')]
        [string]$Name,
        
        # Challenge name exact match
        [Parameter(ParameterSetName = 'Ideation by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Ideation by Name with Connection Profile')]
        [Parameter(ParameterSetName = 'Ideation by Name with Connection File')]
        [switch]$ExactMatch = $false,
        
        # Get challenges by group id number
        [Parameter(ParameterSetName = 'Ideation by Id with Authentication Header')]
        [Parameter(ParameterSetName = 'Ideation by Id with Connection Profile')]
        [Parameter(ParameterSetName = 'Ideation by Id with Connection File')]
        [guid[]]$IdeationId,
        
        # Should I recurse into child groups?  Default is false
        [switch]$Recurse = $false,

        # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
        [Parameter(ParameterSetName = 'All ideations with Authentication Header')]
        [Parameter(ParameterSetName = 'Ideation by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Ideation by Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
        [Alias("Community")]
        [string]$VtCommunity,
        
        # Authentication Header for the community
        [Parameter(ParameterSetName = 'All ideations with Authentication Header')]
        [Parameter(ParameterSetName = 'Ideation by Name with Authentication Header')]
        [Parameter(ParameterSetName = 'Ideation by Id with Authentication Header')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]$VtAuthHeader,
    
        [Parameter(ParameterSetName = 'All ideations with Connection Profile')]
        [Parameter(ParameterSetName = 'Ideation by Name with Connection Profile')]
        [Parameter(ParameterSetName = 'Ideation by Id with Connection Profile')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSObject]$Connection,
    
        # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
        [Parameter(ParameterSetName = 'All ideations with Connection File')]
        [Parameter(ParameterSetName = 'Ideation by Name with Connection File')]
        [Parameter(ParameterSetName = 'Ideation by Id with Connection File')]
        [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) ),

        # Suppress the progress bar
        [Parameter()]
        [switch]$SuppressProgressBar,

        [Parameter()]
        [Alias("Details")]
        [switch]$ReturnDetails
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
           @{ Name = "IdeationId"; Expression = { $_.Id } }
           'Name'
           @{ Name = "Description"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Description ) } }
           @{ Name = 'Url'; Expression = { "$( $_.Group.Url )/i/$( $_.ApplicationKey )"}}
           @{ Name = "Enabled"; Expression = { $_.IsEnabled } }
           'TotalPosts'
           'RequiresCategory'
           'AllowMultipleVotes'
           @{ Name = "GroupName"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Group.Name ) } }
           @{ Name = "GroupId"; Expression = { $_.Group.Id } }
           'LastPostDate'
       )
    }
        
    PROCESS {


        switch -Wildcard ( $PSCmdlet.ParameterSetName ) {
            'Ideation by Name *' {
                ForEach ( $Name in $GroupName ) {
                    $Uri = 'api.ashx/v2/ideas/challenge.json'
                    $UriParameters['GroupNameFilter'] = $Name
                    $IdeationCount = 0
    
                    do {
                        Write-Verbose -Message "Making call with '$Uri'"
                        # Get the list of groups with matching name from the call
                        $IdeationsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders
    
                        if ( $IdeationsResponse ) {
                            $IdeationCount += $IdeationsResponse.Challenges.Count
                            # If we need an exact response on the name, then filter for only that exact group
                            if ( $ExactMatch ) {
                                $IdeationsResponse.Challenges = $IdeationsResponse.Challenges | Where-Object { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) -eq $Name }
                            }
                            # Should we return everything?
                            if ( $ReturnDetails ) {
                                $IdeationsResponse.Challenges
                            }
                            else {
                                $IdeationsResponse.Challenges | Select-Object -Property $PropertiesToReturn
                            }
                        }
                        
                        $UriParameters['PageIndex']++
                        Write-Verbose -Message "Incrementing Page Index :: $( $UriParameters['PageIndex'] )"
                    } while ( $IdeationCount -lt $IdeationsResponse.TotalCount )
                        
                }
            }
            'Ideation by Id *' {
                ForEach ( $Id in $IdeationId ) {
                        $Uri = "api.ashx/v2/ideas/challenge.json"
                        $UriParameters['Id'] = $Id
                    }
    
                    # Because everything is encoded in the URI, we don't need to send any $UriParameters
                    Write-Verbose -Message "Making call with '$Uri'"
                    $IdeationsResponse = Invoke-RestMethod -Uri ( $Community + $Uri ) -Headers $AuthHeaders -Verbose:$false
                        
                    if ( $IdeationsResponse.Challenge ) {
                        if ( $ReturnDetails ) {
                            $IdeationsResponse.Challenge
                        }
                        else {
                            $IdeationsResponse.Challenge | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    else {
                        Write-Warning -Message "No matching groups found for ID: $Id"
                    }
                }
            default {
                # No ForEach loop needed here because we are pulling all groups
                $Uri = 'api.ashx/v2/ideas/challenges.json'
                $IdeationCount = 0
                do {
                    $IdeationsResponse = Invoke-RestMethod -Uri ( $Community + $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) ) -Headers $AuthHeaders -Verbose:$false
    
                    if ( $ResolveParentName ) {
                        # This calls itself to get the parent group name
                        $IdeationsResponse.Challenges | Add-Member -MemberType ScriptProperty -Name "ParentGroupName" -Value { Get-VtGroup -GroupId $this.ParentGroupId | Select-Object -Property @{ Name = "Name"; Expression = { [System.Web.HttpUtility]::HtmlDecode( $_.Name ) } } | Select-Object -ExpandProperty Name } -Force
                    }
    
                    if ( $IdeationsResponse ) {
                        $IdeationCount += $IdeationsResponse.Challenges.Count
                        if ( $ParentGroupId ) {
                            $IdeationsResponse.Challenges = $IdeationsResponse.Challenges | Where-Object { $_.ParentGroupId -eq $ParentGroupId }
                        }
                        if ( $ReturnDetails ) {
                            $IdeationsResponse.Challenges
                        }
                        else {
                            $IdeationsResponse.Challenges | Select-Object -Property $PropertiesToReturn
                        }
                    }
                    $UriParameters['PageIndex']++
                    Write-Verbose -Message "Incrementing Page Index :: $( $UriParameters['PageIndex'] )"
                } while ( $IdeationCount -lt $IdeationsResponse.TotalCount )
            }
        }

    }
    
        
    END {
            
    }
}