$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Write-Host "`$here: $here" -ForegroundColor Yellow
Write-Host "`$sut: $sut" -ForegroundColor Yellow

<#
$VtCommunity = Get-Content -Path ( Join-Path -Path $here -ChildPath "myCommunity.txt")
$VtUsername = Get-Content -Path ( Join-Path -Path $here -ChildPath "myUsername.txt")
$VtApiKey = Get-Content -Path ( Join-Path -Path $here -ChildPath "myApiKey.txt")
#>

Describe -Tags ( 'Unit', 'Acceptance' ) "$sut function Tests" {
    Context 'Group 1' {
        
        It "Group 1 - Test 1" {
            "Test 1" | Should -Be $true
        }
        It "Group 1 - Test 2" {
            "Test 2" | Should -Be $true
        }
    }

    Context 'Group 2' {
        
        Mock Run-Function { returns $true }
        
        It "Group 2 - Test 1" {
            "Test 1" | Should -Be $true
        }
        It "Group 2 - Test 2" {
            "Test 2" | Should -Be $true
        }

    }
}
