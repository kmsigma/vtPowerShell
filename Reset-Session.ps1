Clear-Host
Write-Host "Cleaning house" -ForegroundColor Green

Write-Host "`tRemoving vtPowerShell Module (if loaded)" -ForegroundColor Yellow
Get-Module -Name vtPowerShell | Remove-Module

Write-Host "`tRemoving any 'vt' functions (if loaded)" -ForegroundColor Yellow
Get-ChildItem -Path Function: | Where-Object { $_.Noun-like "vt*" } | Remove-Item -Confirm:$false

Write-Host "`tRemoving any 'vt' variables (if exist)" -ForegroundColor Yellow
Get-Variable -Name "vt*" | Remove-Variable -ErrorAction SilentlyContinue

Write-Host "`tLoading the vtPowerShell Module (if exist)" -ForegroundColor Yellow
Get-Module -Name vtPowerShell -ListAvailable | Import-Module -Force

Write-Host "All done" -ForegroundColor Green

# Some simple tests
$ConnectionProfile = New-VtConnection -VtCommunity ( "https://staging-thwack.solarwinds.com/" ) -Username ( Get-Content -Path .\myUsername.txt -Raw ) -ApiKey ( Get-Content -Path .\myApiKey.txt -Raw )
New-VtConnection -VtCommunity ( "https://staging-thwack.solarwinds.com/" ) -Username ( Get-Content -Path .\myUsername.txt -Raw ) -ApiKey ( Get-Content -Path .\myApiKey.txt -Raw ) -Save
New-VtConnection -VtCommunity ( "https://staging-thwack.solarwinds.com/" ) -Username ( Get-Content -Path .\myUsername.txt -Raw ) -ApiKey ( Get-Content -Path .\myApiKey.txt -Raw ) -Save -ProfilePath "D:\source\_scratch\TestCreds.json"

Test-VtConnection -VtCommunity ( "https://staging-thwack.solarwinds.com/" ) -VtAuthHeader ( ConvertTo-VtAuthHeader -Username ( ( Get-Content -Path .\myUsername.txt -Raw ) ) -ApiKey ( Get-Content -Path .\myApiKey.txt -Raw ) ) -Verbose
Test-VtConnection -ConnectionProfile $ConnectionProfile -Verbose
Test-VtConnection -ProfilePath "D:\source\_scratch\TestCreds.json" -Verbose
Test-VtConnection -Verbose

Get-VtUser -Username "KMSigma"

