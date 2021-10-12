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
    Context 'Connection by Type' {
        It "Using Username/Password from Connection Profile file" {
            New-VtConnection -CommunityUrl $Community -Username $Self -ApiKey $SelfApi | Should -Be $true
        }
        It "Using Authentication Header from Connection Profile file" {
            $AuthHeader = @{ }
            $DefaultProfile.Authentication.PSObject.Properties | ForEach-Object { $AuthHeader[$_.Name] = $_.Value }
            New-VtConnection -CommunityUrl $Community -AuthHeader $AuthHeader | Should -Be $true
        }
    }
    Context "Saving new profile" {
        It "Using Username/API Key" {
            $ProfilePath = "$env:temp\Profile.json"
            New-VtConnection -CommunityUrl $Community -Username $Self -ApiKey $SelfApi -Save -ProfilePath $ProfilePath
            $ProfilePath | Should -Exist
            $ProfilePath | Remove-item -Confirm:$false -Force -ErrorAction SilentlyContinue
        }
        It "Using Authentication Header" {
            $ProfilePath = "$env:temp\Profile.json"
            $AuthHeader = @{ }
            $DefaultProfile.Authentication.PSObject.Properties | ForEach-Object { $AuthHeader[$_.Name] = $_.Value }
            New-VtConnection -CommunityUrl $Community -AuthHeader $AuthHeader -Save -ProfilePath $ProfilePath
            $ProfilePath | Should -Exist
            $ProfilePath | Remove-item -Confirm:$false -Force -ErrorAction SilentlyContinue
        }
        It "Using Username/API Key (with overwrite)" {
            $ProfilePath = "$env:temp\Profile.json"
            New-VtConnection -CommunityUrl $Community -Username $Self -ApiKey $SelfApi -Save -ProfilePath $ProfilePath
            $ProfilePath | Should -Exist
            New-VtConnection -CommunityUrl $Community -Username $Self -ApiKey $SelfApi -Save -ProfilePath $ProfilePath -Force
            $ProfilePath | Should -Exist
            $ProfilePath | Remove-item -Confirm:$false -Force -ErrorAction SilentlyContinue
        }
        It "Using Authentication Header (with overwrite)" {
            $ProfilePath = "$env:temp\Profile.json"
            $AuthHeader = @{ }
            $DefaultProfile.Authentication.PSObject.Properties | ForEach-Object { $AuthHeader[$_.Name] = $_.Value }
            New-VtConnection -CommunityUrl $Community -AuthHeader $AuthHeader -Save -ProfilePath $ProfilePath
            $ProfilePath | Should -Exist
            New-VtConnection -CommunityUrl $Community -AuthHeader $AuthHeader -Save -ProfilePath $ProfilePath -Force
            $ProfilePath | Should -Exist
            $ProfilePath | Remove-item -Confirm:$false -Force -ErrorAction SilentlyContinue
        }
    }
}