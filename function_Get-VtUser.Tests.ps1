$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Write-Host "`$here: $here" -ForegroundColor Yellow
Write-Host "`$sut: $sut" -ForegroundColor Yellow

if ( Test-Path -Path $env:USERPROFILE\.vtPowerShell\DefaultCommunity.json -ErrorAction SilentlyContinue ) {
    Write-Host "Using stored credentials from Default Profile" -ForegroundColor Cyan
    $DefaultProfile = Get-Content -Path $env:USERPROFILE\.vtPowerShell\DefaultCommunity.json | ConvertFrom-Json
    $Self = ( [System.Text.Encoding]::ASCII.GetString( [Convert]::FromBase64String($DefaultProfile.Authentication.'Rest-User-Token') ) ).Split(":")[-1]
}

Describe -Tags ( 'Unit', 'Acceptance' ) "$sut function Tests" {
    Context 'Single User with Stored Credentials' {
        
        It "Get Single User by Username ($Self)" {
            $User = Get-VtUser -Username $Self -SuppressProgressBar
            $User.Count | Should -Be 1
        }
        It "Get Single User by User Id ($( $User.UserId ))" {
            $UserById = Get-VtUser -UserId ( $User.UserId ) -SuppressProgressBar
            $UserById.Count | Should -Be 1
        }
        It "Get Single User by Email Address ($Self)" {
            $UserByEmail = Get-VtUser -EmailAddress ( $User.EmailAddress ) -SuppressProgressBar
            $UserByEmail.Count | Should -Be 1
        }
    }

    Context 'Mutliple Users with Stored Credentials' {
        
        Mock -CommandName Get-VtUser -MockWith { returns 1 }
        
        It "Multiple Users by Username" {
            Get-VtUser -Username "user1", "user2" -SuppressProgressBar | Should -Be 2
        }
        It "Multiple Users by User ID" {
            Get-VtUser -UserId 2100, 2101 -SuppressProgressBar | Should -Be 2
        }
        It "Multiple Users by Email Address" {
            Get-VtUser -EmailAddress "me@here.com", "you@there.com" -SuppressProgressBar | Should -Be 2
        }

    }
}
