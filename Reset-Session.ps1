if ( $VerbosePreference -ne 'Continue') {
    $VerbosePreference = 'Continue'
}

Clear-Host
Write-Verbose -Message "Cleaning house"

Write-Verbose -Message "Forcibly removing the vtPowerShell Module (if loaded)"
Remove-Module -Name 'vtPowerShell' -Force -ErrorAction SilentlyContinue

Write-Verbose -Message "`tRemoving vtPowerShell Module (if loaded)"
Get-Module -Name vtPowerShell | Remove-Module -Verbose

Write-Verbose -Message "`tRemoving any 'vt' functions (if loaded)"
Get-ChildItem -Path Function: | Where-Object { $_.Noun -like "vt*" } | Remove-Item -Confirm:$false -Verbose

Write-Verbose -Message "`tRemoving any 'vt' variables (if exist)"
Get-Variable -Name "vt*" | Remove-Variable -ErrorAction SilentlyContinue -Verbose

Write-Verbose -Message "`tLoading the vtPowerShell Module (if exist)"
if ( -not ( Get-Module -Name vtPowerShell -ListAvailable ) ) {
    Write-Warning -Message "Module is unlisted, importing vtPowerShell forcibly"
    Import-Module .\vtPowerShell.psd1 -Force
} else {
    Write-Warning -Message "Module is listed, importing vtPowerShell forcibly"
    Get-Module -Name vtPowerShell -ListAvailable | Import-Module -Force -Verbose
}



Write-Verbose -Message "All done"
if ( $VerbosePreference -ne 'SilentlyContinue') {
    $VerbosePreference = 'SilentlyContinue'
}

# Some simple tests
<#
$Connection = New-VtConnection -VtCommunity ( "https://staging-thwack.solarwinds.com/" ) -Username ( Get-Content -Path .\myUsername.txt -Raw ) -ApiKey ( Get-Content -Path .\myApiKey.txt -Raw )
New-VtConnection -VtCommunity ( "https://staging-thwack.solarwinds.com/" ) -Username ( Get-Content -Path .\myUsername.txt -Raw ) -ApiKey ( Get-Content -Path .\myApiKey.txt -Raw ) -Save
New-VtConnection -VtCommunity ( "https://staging-thwack.solarwinds.com/" ) -Username ( Get-Content -Path .\myUsername.txt -Raw ) -ApiKey ( Get-Content -Path .\myApiKey.txt -Raw ) -Save -ProfilePath "D:\source\_scratch\TestCreds.json"

Test-VtConnection -VtCommunity ( "https://staging-thwack.solarwinds.com/" ) -VtAuthHeader ( ConvertTo-VtAuthHeader -Username ( ( Get-Content -Path .\myUsername.txt -Raw ) ) -ApiKey ( Get-Content -Path .\myApiKey.txt -Raw ) ) -Verbose
Test-VtConnection -ConnectionProfile $Connection -Verbose
Test-VtConnection -ProfilePath "D:\source\_scratch\TestCreds.json" -Verbose
Test-VtConnection -Verbose

Get-VtUser -Username "KMSigma"
#>