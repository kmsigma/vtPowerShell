$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Write-Host "`$here: $here" -ForegroundColor Yellow
Write-Host "`$sut: $sut" -ForegroundColor Yellow

$PsUserProfile = $env:USERPROFILE ? $env:USERPROFILE : $env:USER

if ( Test-Path -Path $PsUserProfile\.vtPowerShell\DefaultCommunity.json -ErrorAction SilentlyContinue ) {
    Write-Host "Using stored credentials from Default Profile" -ForegroundColor Cyan
    $DefaultProfile = Get-Content -Path $PsUserProfile\.vtPowerShell\DefaultCommunity.json | ConvertFrom-Json
    $Self = ( [System.Text.Encoding]::ASCII.GetString( [Convert]::FromBase64String($DefaultProfile.Authentication.'Rest-User-Token') ) ).Split(":")[-1]
    $Community = $DefaultProfile.Community
}

Describe -Tags ( 'Unit', 'Acceptance' ) "$sut function Tests" {

    $User = Get-VtUser -Username $Self -SuppressProgressBar
    
    Context "Single User with Stored Credentials with '$Community'" {
        
        It "Get Single User by Username ($Self)" {
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

    Context "Mutliple Users with Stored Credentials with '$Community'" {
        # For the purposes of 'Multiple user' tests, we'll suppress the progress bar
        It "Get Multiple Users by Username" {
            $Users = Get-VtUser -UserName $Self, "Anonymous" -IncludeHidden -SuppressProgressBar
            $Users.Count | Should -Be 2
        }
        It "Multiple Users by User ID" {
            $Users = Get-VtUser -UserId $User.UserId, 2102 -SuppressProgressBar
            $Users.Count | Should -Be 2
        }
        It "Multiple Users by Email Address" {
            if ( $Community -like "*staging*" ) {
                $Users = Get-VtUser -EmailAddress $User.EmailAddress, '__CommunityServer__Service__@localhost.com.bounce' -SuppressProgressBar
            }
            else {
                $Users = Get-VtUser -EmailAddress $User.EmailAddress, '__CommunityServer__Service__@localhost.com' -SuppressProgressBar
            }
            $Users.Count | Should -Be 2
        }
        # For the purposes of 'all' tests, we'll suppress the progress bar and the warnings
        It "Multiple Users (no filter)" {
            $Users = Get-VtUser -All -SuppressProgressBar -Warningaction SilentlyContinue | Select-Object -First 15
            $Users.Count | Should -Be 15
        }
        It "Multiple Users (Sorted by Join Date)" {
            $Users = Get-VtUser -All -SuppressProgressBar -SortBy JoinedDate -Descending -Warningaction SilentlyContinue | Select-Object -First 15
            $Users.Count | Should -Be 15
            $Users[0].JoinedDate -gt $Users[-1].JoinedDate | Should -Be $true
        }
        It "Multiple Users (Sorted by Last Visit Date)" {
            $Users = Get-VtUser -All -SuppressProgressBar -SortBy LastVisitedDate -Descending -Warningaction SilentlyContinue | Select-Object -First 15
            $Users.Count | Should -Be 15
            $Users[0].LastVisitedDate -gt $Users[-1].LastVisitedDate | Should -Be $true
        }
    }
    Context "Return Details with '$Community'" {
        It "Return a single user with details" {
            $NonDefaultField = 'DateFormat'
            $UserDetails = Get-VtUser -Username $Self -SuppressProgressBar -ReturnDetails
            if ( $UserDetails | Get-Member | Where-Object { $_.Name -eq $NonDefaultField } ) {
                $UserDetails.$NonDefaultField -is [string] | Should -Be $true
            }
        }
        It "Return multiple users with details" {
            $NonDefaultField = 'DateFormat'
            $UsersDetails = Get-VtUser -Username $Self, "Anonymous" -IncludeHidden -SuppressProgressBar -ReturnDetails
            $UsersDetails.Count | Should -Be 2
            if ( $UsersDetails | Get-Member | Where-Object { $_.Name -eq $NonDefaultField } ) {
                ForEach ( $UserDetails in $UsersDetails ) {
                    $UserDetails.$NonDefaultField -is [string] | Should -Be $true
                }
            }
        }
    }
}
