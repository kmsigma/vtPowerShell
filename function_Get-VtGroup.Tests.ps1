$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = ( Split-Path -Leaf $MyInvocation.MyCommand.Path ) -replace '\.Tests\.', '.'
. "$here\$sut"

Write-Host "`$here: $here" -ForegroundColor Yellow
Write-Host "`$sut: $sut" -ForegroundColor Yellow

Describe -Tags ( 'Unit', 'Acceptance' ) "$sut function Tests" {

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

    # Remove the Module
    Remove-Module -Name vtPowerShell -Force -Confirm:$false -ErrorAction SilentlyContinue
    
    # Import the Module
    Import-Module -Name vtPowerShell -Force

    Connect-VtCommunity -VtCommunity $CommunityURL -Username $Username -ApiKey $ApiKey -StoreAsGlobal

    Context 'Get-VtGroup Tests' {
        
        It "Get Root Group" {
            $Group = Get-VtGroup -GroupId 1
            $Group | Should -Be $true
            $Group.GroupId | Should -Be 1
            $Group.Key | Should -Be 'root'
        }
        It "Get Single Group by ID" {
            $GroupId = [int](10)
            $Group = Get-VtGroup -GroupId $GroupId
            $Group | Should -Be $true
            $Group.GroupId | Should -Be $GroupId
            ( $Group.Key -eq $null ) | Should -Be $false
        }
        It "Get Multiple Groups by IDs" {
            $GroupIds = [int](10), [int](20)
            $Groups = Get-VtGroup -GroupId $GroupIds
            $Groups -is [Array] | Should -Be $true
            $Groups.Count | Should -Be 2
            For ( $i = 0; $i -lt $GroupIds.Count; $i++ ) {
                $Groups[$i].GroupId | Should -Be $GroupIds[$i]
                ( $Groups[$i].Key -eq $null ) | Should -Be $false
            }
        }

        It "Get Single Group by Exact Name" {
            $GroupName = 'Resources'
            $Group = Get-VtGroup -GroupName $GroupName -ExactMatch
            $Group | Should -Be $true
            $Group.Name | Should -Be $GroupName
            ( $Group.Key -eq $null ) | Should -Be $false
        }

        It "Get Multiple Groups by Exact Name" {
            $GroupNames = 'Resources', 'Product Forums'
            $Groups = Get-VtGroup -GroupName $GroupNames -ExactMatch
            $Groups -is [Array] | Should -Be $true
            $Groups.Count | Should -Be 2
            For ( $i = 0; $i -lt $GroupIds.Count; $i++ ) {
                $Groups[$i].Name | Should -Be $GroupNames[$i]
                ( $Groups[$i].Key -eq $null ) | Should -Be $false
            }
        }

        It "Get Groups by Name Match" {
            $GroupName = 'Group'
            $Groups = Get-VtGroup -GroupName $GroupName
            $Groups -is [Array] | Should -Be $true
            ForEach ( $Group in $Groups ) {
                $Group.Name -like "*$GroupName*" | Should -Be $true
                ( $Group.Key -eq $null ) | Should -Be $false
            }
        }
        

        It "Group by Types Match Up" {
            $GroupTypes = "Joinless", "PublicOpen", "PublicClosed", "PrivateUnlisted", "PrivateListed", "All"
            $GroupCounts = $GroupTypes | ForEach-Object {
                [PSCustomObject]@{
                    GroupType = $_
                    Count     = -1
                }
            }
            ForEach ( $GroupCount in $GroupCounts ) {
                $GroupCount.Count = Get-VtGroup -GroupType $GroupCount.GroupType | Measure-Object | Select-Object -ExpandProperty Count
                $GroupCount.Count | Should -BeGreaterOrEqual 0
            }
            
            $NonAllCount = $GroupCounts | Where-Object { $_.GroupType -ne "All" } | Measure-Object -Property Count -Sum | Select-Object -ExpandProperty Sum
            $AllCount = $GroupCounts | Where-Object { $_.GroupType -eq "All" } | Measure-Object -Property Count -Sum | Select-Object -ExpandProperty Sum

            $NonAllCount | Should -Be $AllCount

        }
        
    }


}

# Remove the Module
if ( Get-Module -Name vtPowerShell ) {
    Remove-Module -Name vtPowerShell
}