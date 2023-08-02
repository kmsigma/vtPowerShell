$AllFeedback = "C:\Users\kevin.sparenberg\Solarwinds\SolarWinds User Groups (SWUG) - Documents\2023-05-10 - Minneapolis, MN\Poll Results\Session Feedback\thwackPoints.csv" | Import-Csv
$AllFeedback | Add-Member -MemberType ScriptProperty -Name UsernameLookup -Value { Get-VtUser -Username $this.Username -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select-Object -ExpandProperty Username } -Force
$AllFeedback | Add-Member -MemberType ScriptProperty -Name EmailLookup -Value { Get-VtUser -EmailAddress $this.Username -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select-Object -ExpandProperty Username } -Force
$AllFeedback | Add-Member -MemberType ScriptProperty -Name FinalUsername -Value {
    if ( $this.UsernameLookup ) {
        $this.UsernameLookup
    }
    elseif ( $this.EmailLookup ) {
        $this.EmailLookup
    }
    else {
        $this.Username
    }
}
$AllFeedback | Select-Object -Property Description, @{ Name = "Username"; Expression = { $_.FinalUsername } } | ConvertTo-Csv | Out-File "C:\Users\kevin.sparenberg\Solarwinds\SolarWinds User Groups (SWUG) - Documents\2023-05-10 - Minneapolis, MN\Poll Results\Session Feedback\thwackPoints_clean.csv" -Force