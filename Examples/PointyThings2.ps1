$BB2023Points = Get-ChildItem -Path "C:\Users\kevin.sparenberg\Solarwinds\THWACK Community Team - Documents\Missions\2023\04_Apr_BracketBattle\Reports\Votes_Raw\_Working\2023*.csv" | Import-Csv | Sort-Object -Property AwardDate, Username | Where-Object { $_.TransactionID -eq 0 }

ForEach ( $Transaction in $BB2023Points ) {
    if ( $Transaction.UserID) {
        $Result = New-VtPointTransaction -UserId $Transaction.UserID -Points $Transaction.Points -Description $Transaction.Description -AwardDateTime ( Get-Date $Transaction.AwardDate )
    }
    else {
        $Result = New-VtPointTransaction -Username $Transaction.Username -Points $Transaction.Points -Description $Transaction.Description -AwardDateTime ( Get-Date $Transaction.AwardDate )
    }

    if ( $Result ) {
        $Transaction.TransactionID = $Result.Transaction
        $Transaction | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File -Append "C:\Users\kevin.sparenberg\Solarwinds\THWACK Community Team - Documents\Missions\2023\04_Apr_BracketBattle\Reports\Votes_Raw\TransactionLog.txt"
    }
    else {
        Write-Error -Message "Error Processing: $( $Transaction | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 )"
    }
}