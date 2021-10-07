Clear-Host
Write-Host "Cleaning house" -ForegroundColor Green
Write-Host "`tRemoving vtPowerShell Module (if loaded)" -ForegroundColor Yellow
Get-Module -Name vtPowerShell | Remove-Module
Write-Host "`tRemoving any 'vt' functions (if loaded)" -ForegroundColor Yellow
Get-ChildItem -Path Function: | Where-Object { $_.Noun-like "vt*" } | Remove-Item -Confirm:$false
Write-Host "`tRemoving any 'vt' variables (if exist)" -ForegroundColor Yellow
Get-Variable -Name "vt*" | Remove-Variable -ErrorAction SilentlyContinue
Write-Host "`tLoading the vtPowerShell Module (if exist)" -ForegroundColor Yellow
Get-Module -Name vtPowerShell -ListAvailable | Import-Module
Write-Host "All done" -ForegroundColor Green