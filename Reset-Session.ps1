if ( $VerbosePreference -ne 'Continue') {
    $VerbosePreference = 'Continue'
}

Clear-Host
Write-Host "Cleaning house" -ForegroundColor Green

Write-Host "`tRemoving vtPowerShell Module (if loaded)" -ForegroundColor Yellow
Get-Module -Name vtPowerShell | Remove-Module -Verbose

Write-Host "`tRemoving any 'vt' functions (if loaded)" -ForegroundColor Yellow
Get-ChildItem -Path Function: | Where-Object { $_.Noun -like "vt*" } | Remove-Item -Confirm:$false -Verbose

Write-Host "`tRemoving any 'vt' variables (if exist)" -ForegroundColor Yellow
Get-Variable -Name "vt*" | Remove-Variable -ErrorAction SilentlyContinue -Verbose

Write-Host "`tLoading the vtPowerShell Module (if exist)" -ForegroundColor Yellow
if ( -not ( Get-Module -Name vtPowerShell -ListAvailable ) ) {
    Import-Module .\vtPowerShell.psd1 -Force

}
else {
    Get-Module -Name vtPowerShell -ListAvailable | Import-Module -Force -Verbose
}



Write-Host "All done" -ForegroundColor Green
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