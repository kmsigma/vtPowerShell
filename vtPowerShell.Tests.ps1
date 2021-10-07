# Help File: https://www.red-gate.com/simple-talk/sysadmin/powershell/testing-powershell-modules-with-pester/
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Module = 'vtPowerShell'

#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
#. "$here\$sut"

Write-Host "`$here: $here" -ForegroundColor Yellow
#Write-Host "`$sut: $sut" -ForegroundColor Yellow

<#
Describe "Get-VtUser" {
    if ( -not ( Get-Module -Name 'vtPowerShell' ) ) {
        Import-Module -Name vtPowerShell | Out-Null
    }
    $VtCommunity = "https://staging-thwack.solarwinds.com/"
    $VtAuthHeader = @{ "Rest-User-Token" = ( Get-Content -Path ".\myToken.txt" -Raw ) }
    It "accepts a single user" {
        $User = Get-VtUser -Username "KMSigma" -VtCommunity $VtCommunity -VtAuthHeader $VtAuthHeader
        $User.Count | Should -Be 1
    }
}
#>

Describe -Tags ( 'Unit', 'Acceptance' ) "$Module Module Tests" {
    Context 'Module Setup' {
        It "has the root module $module.psm1" {
            "$here\$module.psd1" | Should -Exist
        }
        It "has a manifest file of $Module.psd1" {
            "$here\$module.psd1" | Should -Exist
            "$here\$module.psd1" | Should -FileContentMatch "$module.psm1"
        }
        It "$module folder has functions" {
            "$here\function_*.ps1" | Should -Exist
        }
        It "$module is valid PowerShell code" {
            $psFile = Get-Content -Path "$here\$module.psm1" `
                -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    } # 'Module Setup'

    $functions = @( 
        'Connect-VtCommunity',
        'Get-VtAbuseReport',
        'Get-VtAuthHeader',
        'Get-VtBlog',
        'Get-VtBlogPost',
        'Get-VtChallenge',
        'Get-VtForum',
        'Get-VtForumThread',
        'Get-VtGallery',
        'Get-VtGalleryMedia',
        'Get-VtGroup',
        'Get-VtIdea',
        'Get-VtPointTransaction',
        'Get-VtSysNotification',
        'Get-VtUser',
        'New-VtPointTransaction',
        'Remove-VtPointTransaction',
        'Remove-VtUser',
        'Set-VtAuthHeader',
        'Set-VtBlog',
        'Set-VtForumThread',
        'Set-VtGallery',
        'Set-VtGalleryMedia',
        'Set-VtUser'
    )
    
    ForEach ( $function in $functions ) {
        It "$function.ps1 should exist" {
            "$here\function_$function.ps1" | Should -Exist
        }
        It "$function.ps1 should have help block" {
            "$here\function_$function.ps1" | Should -FileContentMatch '<#'
            "$here\function_$function.ps1" | Should -FileContentMatch '#>'
        }

        It "$function.ps1 should have a SYNOPSIS section in the help block" {
            "$here\function_$function.ps1" | Should -FileContentMatch '.SYNOPSIS'
        }

        It "$function.ps1 should have a DESCRIPTION section in the help block" {
            "$here\function_$function.ps1" | Should -FileContentMatch '.DESCRIPTION'
        }

        It "$function.ps1 should have a EXAMPLE section in the help block" {
            "$here\function_$function.ps1" | Should -FileContentMatch '.EXAMPLE'
        }

        It "$function.ps1 should be an advanced function" {
            "$here\function_$function.ps1" | Should -FileContentMatch 'function'
            "$here\function_$function.ps1" | Should -FileContentMatch 'cmdletbinding'
            "$here\function_$function.ps1" | Should -FileContentMatch 'param'
        }

        It "$function.ps1 should contain Write-Verbose blocks" {
            "$here\function_$function.ps1" | Should -FileContentMatch 'Write-Verbose'
        }

        It "$function.ps1 is valid PowerShell code" {
            $psFile = Get-Content -Path "$here\function_$function.ps1" -ErrorAction Stop
            $errors = $null
            [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0
        }

        # Context "Test Function $function"
        Context "$function has tests" {
            It "function_$($function).Tests.ps1 should exist" {
                "$here\function_$($function).Tests.ps1" | Should -Exist
            }
        }
    }
}


#Get-Module -Name vtPowerShell -ErrorAction SilentlyContinue | Remove-Module
