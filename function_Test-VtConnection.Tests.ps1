$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Write-Host "`$here: $here" -ForegroundColor Yellow
Write-Host "`$sut: $sut" -ForegroundColor Yellow

if ( Test-Path -Path $env:USERPROFILE\.vtPowerShell\DefaultCommunity.json -ErrorAction SilentlyContinue ) {
    Write-Host "Using stored credentials from Default Profile" -ForegroundColor Cyan
    $DefaultProfile = Get-Content -Path $env:USERPROFILE\.vtPowerShell\DefaultCommunity.json | ConvertFrom-Json
    $Community = $DefaultProfile.Community
    $Self    = ( [System.Text.Encoding]::ASCII.GetString( [Convert]::FromBase64String($DefaultProfile.Authentication.'Rest-User-Token') ) ).Split(":")[-1]
    $SelfApi = ( [System.Text.Encoding]::ASCII.GetString( [Convert]::FromBase64String($DefaultProfile.Authentication.'Rest-User-Token') ) ).Split(":")[0]
}
Describe -Tags ( 'Unit' ) "$sut function tests" {
    Context 'Connection Test by Type' {
        It "Using Username/Password from Connection Profile file" {
            Test-VtConnection | Should -Be $true
        }
        It "Using Authentication Header from Connection Profile file" {
            $AuthHeader = @{ }
            $DefaultProfile.Authentication.PSObject.Properties | ForEach-Object { $AuthHeader[$_.Name] = $_.Value }
            Test-VtConnection -CommunityUrl $Community -AuthHeader $AuthHeader | Should -Be $true
        }
        It "Using Connection Profile from Connection Profile file" {
            $ConnProfile = New-VtConnection -CommunityUrl $Community -Username $Self -ApiKey $SelfApi
            Test-VtConnection -ConnectionProfile $ConnProfile | Should -Be $true
        }
    }
    Context "Connection Test by Type (Should Fail)" {
        It "Using Connection Profile (bad Url)" {
            $ConnProfile = New-VtConnection -CommunityUrl $Community -Username $Self -ApiKey $SelfApi
            $ConnProfile.Community = "https://garbage.community.domain.local/"
            Test-VtConnection -ConnectionProfile $ConnProfile  -ErrorAction SilentlyContinue | Should -Be $false
        }
        It "Using Authentication Header (bad URL)" {
            $AuthHeader = @{ }
            $DefaultProfile.Authentication.PSObject.Properties | ForEach-Object { $AuthHeader[$_.Name] = $_.Value }
            $Community = "https://garbage.community.domain.local/"
            Test-VtConnection -CommunityUrl $Community -AuthHeader $AuthHeader -ErrorAction SilentlyContinue| Should -Be $false
        }
        It "Using Connection Profile (bad token)" {
            $ConnProfile = New-VtConnection -CommunityUrl $Community -Username $Self -ApiKey $SelfApi
            $ConnProfile.Authentication.'Rest-User-Token' = "BadToken"
            Test-VtConnection -ConnectionProfile $ConnProfile  -ErrorAction SilentlyContinue | Should -Be $false
        }
        It "Using Authentication Header (bad token)" {
            $AuthHeader = @{ }
            $DefaultProfile.Authentication.PSObject.Properties | ForEach-Object { $AuthHeader[$_.Name] = $_.Value }
            $AuthHeader["Rest-User-Token"] = "BadToken"
            Test-VtConnection -CommunityUrl $Community -AuthHeader $AuthHeader -ErrorAction SilentlyContinue| Should -Be $false
        }
    }
}