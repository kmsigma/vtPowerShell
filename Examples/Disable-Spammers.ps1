. "myThings\Resources\StopForumSpam.ps1"

$SpammersCSVPath = "\\kms-nas\Documents\SolarWinds\THWACK\spammers.csv"
$Spammers = $SpammersCSVPath | Import-Csv


# Report the spammers to stop forum spam database
$Uri = 'https://www.stopforumspam.com/add.php'

For ( $i = 0; $i -lt $Spammers.Count; $i ++ ) {

    Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "" -PercentComplete ( ( $i / $Spammers.Count ) * 100 )
    if ( -not ( $Spammers[$i].status -eq 'data submitted successfully' ) ) {
        Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "Building Parameters to Send" -PercentComplete ( ( $i / $Spammers.Count ) * 100 )
        $UriParameters = @{}
        $UriParameters["ip_addr"] = $Spammers[$i].ip_addr
        $UriParameters["username"] = $Spammers[$i].username
        $UriParameters["email"] = $Spammers[$i].email
        $UriParameters["evidence"] = $Spammers[$i].evidence
        $UriParameters["api_key"] = $ApiKey

        $Parameters = ( $UriParameters.GetEnumerator() | ForEach-Object { "$( $_.Name )=$( [System.Web.HttpUtility]::UrlEncode($_.Value) )" } ) -join '&'

        Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "Reporting" -PercentComplete ( ( $i / $Spammers.Count ) * 100 )
        Write-Host "Reporting '$( $Spammers[$i].username )'"
        $Results = Invoke-RestMethod -Uri ( $Uri + '?' + $Parameters )

        if ( $Results ) {
            Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "Reporting Complete" -PercentComplete ( ( $i / $Spammers.Count ) * 100 )
            $Spammers[$i].status = $Results.p
        }
    }
    else {
        Write-Host "Spammer '$( $Spammers[$i].username )' has already been reported."
    }
}
Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "Exporting CSV" -PercentComplete ( ( $i / $Spammers.Count ) * 100 )
$Spammers | Export-Csv -Path $SpammersCSVPath -Force -Confirm:$false
Write-Progress -Activity "Reporting Spammers to StopForumSpam" -Completed

# Disable spammers on community
ForEach ( $Spammer in $Spammers | Select-Object -Property Username -Unique ) {
    Get-VtUser -Username $Spammer.Username | Where-Object { ( $_.Status -ne 'Disapproved' ) -or ( $_.ModerationStatus -ne 'Moderated' ) -or ( -not ( $_.ContentHidden ) ) } | Set-VtUser -AccountStatus Disapproved -ModerationLevel Moderated -RequiresTermsOfServiceAcceptance -HideContent -Confirm:$false
}

# Build a list of domains to block
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

# Building Disallowed Hosts Listing
$DisallowedHosts = Import-Csv -Path "\\kms-nas\Documents\SolarWinds\THWACK\DisallowedHosts.txt" -Header "Host"
$DisallowedHosts | Add-Member -MemberType ScriptProperty -Name "BaseHost" -Value { $this.Host.Replace("www.", '') } -Force

$HostList = $DisallowedHosts | Select-Object -ExpandProperty BaseHost -Unique
$HostList += $ToBlock | ForEach-Object { $_.BaseDomain }
$HostList | Select-Object -Unique | Sort-Object | ForEach-Object { $_; "www.$( $_ )" } | Out-File -FilePath "\\kms-nas\Documents\SolarWinds\THWACK\DisallowedHosts.txt" -Force -Confirm:$false

# Building Possible Banned IP Listing
$BlockIPs = $Spammers | Group-Object -Property ip_addr | Sort-Object -Property Count -Desc | Select-Object -Property @{ Name = "Occurrences"; Expression = { $_.Count } }, @{ Name = "IP"; Expression = { $_.Name } }
$BlockIPs | Export-Csv -Path "\\kms-nas\Documents\SolarWinds\THWACK\PossibleBannedIPs.csv" -Force -Confirm:$false