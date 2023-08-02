<#

$BB2023Points = Import-Csv -Path "C:\Users\kevin.sparenberg\Solarwinds\THWACK Community Team - Documents\Missions\2023\04_Apr_BracketBattle\Reports\Votes_Raw\_FinalTally.csv"

$BB2023Points | Add-Member -MemberType NoteProperty -Name "TransactionID" -Value 0 -Force
ForEach ( $Transaction in $BB2023Points ) {
    $Result = New-VtPointTransaction -Username $Transaction.Username -Points $Transaction.Points -Description $Transaction.Description -AwardDateTime ( Get-Date $Transaction.AwardDate )
    if ( $Result ) {
        $Transaction.TransactionID = $Result.Transaction
        $Transaction | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File -Append "C:\Users\kevin.sparenberg\Solarwinds\THWACK Community Team - Documents\Missions\2023\04_Apr_BracketBattle\Reports\Votes_Raw\TransactionLog.txt"
    }
    else {
        Write-Error -Message "Error Processing: $( $Transaction | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 )"
    }
}

#>
$Rounds = @{
    "PIR" = "Play-In Round"
    "R32" = "Round of 32"
    "R16" = "Round of 16"
    "QF"  = "Quaterfinals"
    "SF"  = "Semifinals"
    "FIN" = "Finals"
}
$RoundDates = @{
    "PIR" = Get-Date "11-APR-2023" -Format "MM/dd/yyyy"
    "R32" = Get-Date "14-APR-2023" -Format "MM/dd/yyyy"
    "R16" = Get-Date "18-APR-2023" -Format "MM/dd/yyyy"
    "QF"  = Get-Date "21-APR-2023" -Format "MM/dd/yyyy"
    "SF"  = Get-Date "25-APR-2023" -Format "MM/dd/yyyy"
    "FIN" = Get-Date "27-APR-2023" -Format "MM/dd/yyyy"
}

$Matchups = @"
RoundMatchPlayer,Contestant
pir-m1-p1,Sock'em Boppers
pir-m1-p2,Sky Dancers
r32-m1-p1,G. I. Joe
r32-m1-p2,Stretch Armstrong
r32-m2-p1,Slinky
r32-m2-p2,Furby
r32-m3-p1,Tamagotchi
r32-m3-p2,Rubik's Cube
r32-m4-p1,LEGO
r32-m4-p2,Yo-Yo
r32-m5-p1,View-Master
r32-m5-p2,Lite-Brite
r32-m6-p1,Easy-Bake Oven
r32-m6-p2,Etch A Sketch
r32-m7-p1,Simon
r32-m7-p2,Bop It
r32-m8-p1,Transformers
r32-m8-p2,Omnibots
r32-m9-p1,Calculator Watch
r32-m9-p2,Big Trak
r32-m10-p1,Spirograph
r32-m10-p2,Armatron
r32-m11-p1,Teddy Ruxpin
r32-m11-p2,Talkboy
r32-m12-p1,Tekno the Robot Puppy
r32-m12-p2,Sock'em Boppers
r32-m13-p1,Speak and Spell
r32-m13-p2,Chatty Cathy
r32-m14-p1,Thomas the Tank Engine
r32-m14-p2,Magic 8 Ball
r32-m15-p1,Lazer Tag
r32-m15-p2,Electric Quarterback
r32-m16-p1,Nerf Blaster
r32-m16-p2,Super Soaker
r16-m1-p1,G. I. Joe
r16-m1-p2,Slinky
r16-m2-p1,Rubik's Cube
r16-m2-p2,LEGO
r16-m3-p1,View-Master
r16-m3-p2,Etch A Sketch
r16-m4-p1,Simon
r16-m4-p2,Transformers
r16-m5-p1,Calculator Watch
r16-m5-p2,Spirograph
r16-m6-p1,Teddy Ruxpin
r16-m6-p2,Sock'em Boppers
r16-m7-p1,Speak and Spell
r16-m7-p2,Magic 8 Ball
r16-m8-p1,Lazer Tag
r16-m8-p2,Nerf Blaster
qf-m1-p1,G.I. Joe
qf-m1-p2,LEGO
qf-m2-p1,Etch A Sketch
qf-m2-p2,Transformers
qf-m3-p1,Spirograph
qf-m3-p2,Sock'em Boppers
qf-m4-p1,Magic 8 Ball
qf-m4-p2,Nerf Blaster
sf-m1-p1,LEGO
sf-m1-p2,Transformers
sf-m2-p1,Spirograph
sf-m2-p2,Nerf Blaster
fin-m1-p1,LEGO
fin-m1-p2,Nerf Blaster
"@ | ConvertFrom-Csv

$Matchups | Add-Member -MemberType ScriptProperty -Name Round -Value { $Rounds[$this.RoundMatchPlayer.split("-")[0]] } -Force
$Matchups | Add-Member -MemberType ScriptProperty -Name Match -Value { ( [int]( $this.RoundMatchPlayer.split("-")[1] ).Replace("m", "") ) } -Force
$Matchups | Add-Member -MemberType ScriptProperty -Name Player -Value { [int]( ( $this.RoundMatchPlayer.split("-")[2] ).Replace("p", "") ) } -Force

$UserIds = Import-Csv -Path "C:\Users\kevin.sparenberg\Solarwinds\THWACK Community Team - Documents\Missions\2023\04_Apr_BracketBattle\Reports\Votes_Raw\_Working\_UserIdXRef.csv"

$CsvPath = "C:\Users\kevin.sparenberg\Solarwinds\THWACK Community Team - Documents\Missions\2023\04_Apr_BracketBattle\Reports\Votes_Raw\"
$VoteFiles = Get-ChildItem -Path "$CsvPath\*.csv" | Where-Object { $_.BaseName -notlike "_*" }

$VoteFiles | Add-Member -MemberType ScriptProperty -Name 'Year' -Value { $this.BaseName.Split("_")[0] } -Force
$VoteFiles | Add-Member -MemberType ScriptProperty -Name 'RoundName' -Value { $Rounds[$this.BaseName.Split("_")[1]] } -Force
$VoteFiles | Add-Member -MemberType ScriptProperty -Name 'AwardDate' -Value { $RoundDates[$this.BaseName.Split("_")[1]] } -Force
$VoteFiles | Add-Member -MemberType ScriptProperty -Name 'Match' -Value { [int]( ( $this.BaseName.Split("_")[2] ).Replace("m", "") ) } -Force
$VoteFiles | Add-Member -MemberType ScriptProperty -Name 'MatchName' -Value { ( $Matchups | Where-Object { $_.Round -eq $this.RoundName -and $_.Match -eq $this.Match } | Sort-Object -Property Player | Select-Object -ExpandProperty Contestant ) -join ' vs. ' } -Force

if ( Test-Path -Path ( Join-Path -Path $CsvPath -ChildPath "_FinalTally.csv" ) ) {
    Remove-Item -Path ( Join-Path -Path $CsvPath -ChildPath "_FinalTally.csv" ) -Force -Confirm:$false
}
ForEach ( $File in ( $VoteFiles | Sort-Object -Property AwardDate, Match ) ) {
    Write-Host "Processing '$( $File.Name )'"
    # Description: [Play-In Round: Average Joe's v. '92 Dream Team] :: '92 Dream Team
    #              [$( $File.RoundName ): $( $File.MatchName ) ::

    # $RoundDetails = ( $Matchups | Where-Object { $_.Round -eq $File.RoundName -and $_.Match -eq $File.Match } | Sort-Object -Property Player | Select-Object -ExpandProperty Contestant ) -join ' vs. '

    $RoundVotes = Import-Csv -Path $File.FullName -Header "username", "username2", "blank", "Vote" | Select-Object -Property @{ Name = 'Username'; Expression = { $_.username } }, vote
    if ( ( $RoundVotes | Group-Object -Property Username, vote | Select-Object -ExpandProperty Count ) -gt 1 ) {
        Write-Error -Message "We found something sneaky in $( $File.FullName )"
        break
    }
    $RoundVotes | Add-Member -MemberType ScriptProperty -Name "Description" -Value { "[$( $File.RoundName ): $( $File.MatchName )] :: $( $this.vote )" } -Force
    $RoundVotes | Add-Member -MemberType NoteProperty -Name "Points" -Value ( [int](150) ) -Force
    $RoundVotes | Add-Member -MemberType NoteProperty -Name "AwardDate" -Value $File.AwardDate -Force
    $RoundVotes | Add-Member -MemberType ScriptProperty -Name 'UserID' -Value { $UserIds | Where-Object { $_.Username -eq $this.username } | Select-Object -ExpandProperty UserID } -Force
    $RoundVotes | Add-Member -MemberType NoteProperty -Name "TransactionID" -Value 0 -Force
    $RoundVotes | Select-Object -Property Username, UserID, Points, @{ Name = 'Description'; Expression = { [System.Web.HttpUtility]::HtmlDecode($_.Description) } }, AwardDate, TransactionID | Export-Csv -Path ( Join-Path $CsvPath -ChildPath "_Working\$( $File.Name )" ) -Force
}
