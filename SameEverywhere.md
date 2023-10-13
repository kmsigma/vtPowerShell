# Common things that should exist for scripts

There are a few things that we should be using everywhere.  Those will prevent the dreaded "Parameter set cannot be resolved using the specified named parameters." error.

## Parameters

``` powershell
    #region community authorization - put at bottom of paramter block
    # Community Domain to use (include trailing slash) Example: [https://yourdomain.telligenthosted.net/]
    [Parameter(Mandatory=$true, ParameterSetName = 'All THINGS with Authentication Header')]
    [Parameter(Mandatory=$true, ParameterSetName = 'THINGS by FILTER with Authentication Header')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$')]
    [Alias("Community")]
    [string]$VtCommunity,
    
    # Authentication Header for the community
    [Parameter(Mandatory=$true, ParameterSetName = 'All THINGS with Authentication Header')]
    [Parameter(Mandatory=$true, ParameterSetName = 'THINGS by FILTER with Authentication Header')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [System.Collections.Hashtable]$VtAuthHeader,

    [Parameter(Mandatory=$true, ParameterSetName = 'All THINGS with Connection Profile')]
    [Parameter(Mandatory=$true, ParameterSetName = 'THINGS by FILTER with Connection Profile')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.PSObject]$Connection,

    # File holding credentials.  By default is stores in your user profile \.vtPowerShell\DefaultCommunity.json
    [Parameter(ParameterSetName = 'All THINGS with Connection File')]
    [Parameter(ParameterSetName = 'THINGS by FILTER with Connection File')]
    [string]$ProfilePath = ( $env:USERPROFILE ? ( Join-Path -Path $env:USERPROFILE -ChildPath ".vtPowerShell\DefaultCommunity.json" ) : ( Join-Path -Path $env:HOME -ChildPath ".vtPowerShell/DefaultCommunity.json" ) )
    #endregion community authorization - put at bottom of paramter block
```

## `BEGIN` block

``` powershell
        #region retrieve authentication headers
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
        #endregion retrieve authentication headers
```
