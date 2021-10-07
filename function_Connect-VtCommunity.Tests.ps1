$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = ( Split-Path -Leaf $MyInvocation.MyCommand.Path ) -replace '\.Tests\.', '.'
. "$here\$sut"

Write-Host "`$here: $here" -ForegroundColor Yellow
Write-Host "`$sut: $sut" -ForegroundColor Yellow

#region Get Connection Information
$CommunityPath = Join-Path -Path $here -ChildPath "myCommunity.txt" -Resolve -ErrorAction SilentlyContinue
$UsernamePath = Join-Path -Path $here -ChildPath "myUsername.txt" -Resolve -ErrorAction SilentlyContinue
$ApiKeyPath = Join-Path -Path $here -ChildPath "myApiKey.txt" -Resolve -ErrorAction SilentlyContinue

if ( $CommunityPath ) {
    $CommunityURL = Get-Content -Path $CommunityPath -Raw
}
else {
    $CommunityURL = Read-Host -Prompt "Enter your community URL (include trailing slash)"
}

if ( $UsernamePath ) {
    $Username = Get-Content -Path $UsernamePath -Raw
}
else {
    $Username = Read-Host -Prompt "Enter your community username"
}

if ( $ApiKeyPath ) {
    $ApiKey = Get-Content -Path $ApiKeyPath -Raw
}
else {
    $ApiKey = Read-Host -Prompt "Enter your API Key" -MaskInput
}
#endregion Get Connection Information

Describe -Tags ( 'Unit', 'Acceptance' ) "$sut function Tests" {
    Context 'Variable format' {
        
        # Community needs to contain the protocol and a trailing slash
        $RegexCommunity = '^(http:\/\/|https:\/\/)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])\/$'

        # Only lowercase letters and numbers for 20 total characters
        $RegexApiKey = '([a-z]|[0-9]){20}'
        
        # Username regex is found at Administration\Authentication\Authentication Options
        # 'Username Regular Expression Pattern' field coupled with 'Username Minimum/Maximum Length'
        $RegexUsername = '^[a-zA-Z0-9_\-\.]{3,64}$'

        # Regex for REST Token
        $RegexToken = '^[A-Za-z0-9\+\/=]{40}$'

        It "Validate community is proper format" {
            $CommunityURL -match $RegexCommunity | Should Be $true
        }
        It "Validate API key is proper format and length" {
            $ApiKey -match $RegexApiKey | Should Be $true
        }
        It "Validate username is proper format and length" {
            $Username -match $RegexUsername | Should Be $true
        }

        It "Validate community connection with Username & API Key ($Username)" {
            Connect-VtCommunity -VtCommunity $CommunityURL -Username $Username -ApiKey $ApiKey | Should Be $null
        }
            
        Connect-VtCommunity -VtCommunity $CommunityURL -Username $Username -ApiKey $ApiKey -StoreAsGlobal
        It "Validate community connection and save credentials ($CommunityURL)" {
            $Global:vtCommunity | Should Be $true
            $Global:VtAuthHeader.ContainsKey('Rest-User-Token') | Should Be $true
            $Global:VtAuthHeader['Rest-User-Token'] -match $RegexToken | Should Be $true
                
        }
        Remove-Variable -Name VtCommunity, VtAuthHeader -Scope Global -ErrorAction SilentlyContinue
        It "Validate failure on bad community URL ($CommunityURL)" {
            $CommunityUri = [Uri]( $CommunityURL )
            $CommunityUri.Scheme -in ( 'http', 'https' ) | Should Be $true
            $CommunityUri.LocalPath | Should Be '/'
        }
    }
    
    Context 'Connectivity' {

        It "Validate network connectivity ( $CommunityURL ) [simple test]" {
            $CommunityUri = [Uri]( $CommunityURL )
            Test-NetConnection -ComputerName $CommunityUri.Host -Port $CommunityUri.Port -InformationLevel Quiet | Should Be $true
        }
        It "Validate network connectivity ( $CommunityURL ) [detailed test]" {
            $CommunityUri = [Uri]( $CommunityURL )
            $NetCheck = Test-NetConnection -ComputerName $CommunityUri.Host -Port $CommunityUri.Port -InformationLevel Detailed
            $NetCheck.TcpTestSucceeded | Should Be $true
            $NetCheck.NameResolutionSucceeded | Should Be $true
            $NetCheck.AllNameResolutionResults.Count -ge 1 | Should Be $true
        }
    }
}
