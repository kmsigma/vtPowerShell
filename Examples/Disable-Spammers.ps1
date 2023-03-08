$SpammersCSVPath = "\\kms-nas\Documents\SolarWinds\THWACK\spammers.csv"
$Spammers = $SpammersCSVPath | Import-Csv
ForEach ( $Spammer in $Spammers | Select-Object -Property Username -Unique ) {
    Get-VtUser -Username $Spammer.Username | Where-Object { ( $_.Status -ne 'Disapproved' ) -or ( $_.ModerationStatus -ne 'Moderated' ) -or ( -not ( $_.ContentHidden ) ) } | Set-VtUser -AccountStatus Disapproved -ModerationLevel Moderated -RequiresTermsOfServiceAcceptance -HideContent -Confirm:$false -Verbose
}

$BlockDomains = @()
ForEach ( $Spammer in $Spammers ) {
    if ( $Spammer.Evidence -like "*.*" ) {
    ( ( $Spammer.Evidence.Split(':') )[-1] ).Split(",") | ForEach-Object {
            if ( $BlockDomains -notcontains $_.Replace("[.]", ".") ) {
                $BlockDomains += $_.Replace("[.]", ".")
            }
        }
    }
}
$ToBlock = $BlockDomains | Select-Object -Property @{ Name = "DetectedDomain"; Expression = { $_.Trim() } } 
$ToBlock | Add-Member -MemberType ScriptProperty -Name "BaseDomain" -Value { if ( $this.DetectedDomain.Split('.').Count -gt 2 ) { ( ( $this.DetectedDomain.Split('.') )[1..( $this.DetectedDomain.Split('.').Count - 1 ) ] ) -join '.' } else { $this.DetectedDomain } } -Force
$ToBlock | Add-Member -MemberType ScriptProperty -Name "LongDomain" -Value { "www.$( $this.BaseDomain )" } -Force

$DisallowedHosts = Import-Csv -Path "\\kms-nas\Documents\SolarWinds\THWACK\DisallowedHosts.txt" -Header "Host"
$DisallowedHosts | Add-Member -MemberType ScriptProperty -Name "BaseHost" -Value { $this.Host.Replace("www.", '') } -Force

$HostList = $DisallowedHosts | Select-Object -ExpandProperty BaseHost -Unique
$HostList += $ToBlock | ForEach-Object { $_.BaseDomain }
$HostList | Select-Object -Unique | Sort-Object
$HostList | Select-Object -Unique | Sort-Object | ForEach-Object { $_; "www.$( $_ )" } | Out-File -FilePath "\\kms-nas\Documents\SolarWinds\THWACK\DisallowedHosts.txt" -Force -Confirm:$false

