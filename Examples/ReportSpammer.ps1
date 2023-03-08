. "myThings\Resources\StopForumSpam.ps1"

$SpammersCSVPath = "\\kms-nas\Documents\SolarWinds\THWACK\spammers.csv"

$SpammersToReport = Import-Csv -Path $SpammersCSVPath

$Uri = 'https://www.stopforumspam.com/add.php'

For ( $i = 0; $i -lt $SpammersToReport.Count; $i ++ ) {

    Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "" -PercentComplete ( ( $i / $SpammersToReport.Count ) * 100 )
    if ( -not ( $SpammersToReport[$i].status -eq 'data submitted successfully' ) ) {
        Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "Building Parameters to Send" -PercentComplete ( ( $i / $SpammersToReport.Count ) * 100 )
        $UriParameters = @{}
        $UriParameters["ip_addr"] = $SpammersToReport[$i].ip_addr
        $UriParameters["username"] = $SpammersToReport[$i].username
        $UriParameters["email"] = $SpammersToReport[$i].email
        $UriParameters["evidence"] = $SpammersToReport[$i].evidence
        $UriParameters["api_key"] = $ApiKey

        $Parameters = ( $UriParameters.GetEnumerator() | ForEach-Object { "$( $_.Name )=$( [System.Web.HttpUtility]::UrlEncode($_.Value) )" } ) -join '&'

        Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "Reporting" -PercentComplete ( ( $i / $SpammersToReport.Count ) * 100 )
        Write-Host "Reporting '$( $SpammersToReport[$i].username )'"
        $Results = Invoke-RestMethod -Uri ( $Uri + '?' + $Parameters )

        if ( $Results ) {
            Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "Reporting Complete" -PercentComplete ( ( $i / $SpammersToReport.Count ) * 100 )
            $SpammersToReport[$i].status = $Results.p
        }
    }
    else {
        Write-Host "Spammer '$( $SpammersToReport[$i].username )' has already been reported."
    }
}
Write-Progress -Activity "Reporting Spammers to StopForumSpam" -CurrentOperation "Exporting CSV" -PercentComplete ( ( $i / $SpammersToReport.Count ) * 100 )
$SpammersToReport | Export-Csv -Path $SpammersCSVPath -Force -Confirm:$false
Write-Progress -Activity "Reporting Spammers to StopForumSpam" -Completed