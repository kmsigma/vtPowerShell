<#
Very rudimentary query check for possible spammers
#>

# Include the settings (URI, Authentication, other things) from a settings file
. .\myThings\Resources\StopForumSpam.ps1

# What's the minimal confidence where we want to block the user?
# Confidence here is %ChanceOfUsername + %ChanceOfEmailAddress
# Anything over the below number will be flagged as a potential spammer
$MinConfScore = 50

# What date span are we checking for spammers?
$StartDate = Get-Date "2022-12-27"
$EndDate   = Get-Date

<#
####################################
Notes to self:
 -  You should re-work this section so that you are making a user query and then a confidence check (in a ForEach-Object or the like) to be more memory efficient
 -  It would be better to have some type of output from this procedure (list of user Ids, usernames, email addresses, confidences, etc.) so they can be reviewed.
#>

$UserList = @()
# Get a list of all users based on join date and add it to a collection
For ( $Date = $StartDate; $Date -lt $EndDate ; $Date = $Date.AddDays(1) ) {
    Write-Host "Running for Day: $Date"
    $UserList += Get-VtUser -JoinedOn $Date -IncludeEmailDomain -WarningAction SilentlyContinue | Where-Object { $_.ModerationStatus -ne 'Moderated' -and $_.Status -eq 'Approved' } | Select-Object -Property @{ Name = 'SpamCheckDateUTC'; Expression = { ( Get-Date ).ToUniversalTime() } }, UserId, Username, EmailAddress, Status, ModerationStatus, ContentHidden, JoinedDate, @{ Name = 'SpamConfidenceUsername'; Expression = { [double]0 } }, @{ Name = 'SpamConfidenceEmail'; Expression = { [double]0 } }, @{ Name = 'FlaggedAsSpammer'; Expression = { [bool]$false } }

}
$UserList | Add-Member -MemberType ScriptProperty -Name 'SpamConfidence' -Value { $this.SpamConfidenceUsername + $this.SpamConfidenceEmail } -Force
# Filter off exceptions
Write-Host "Current List: $( $UserList.Count ) account(s)"
Write-Host "Filtering off members of excepted domains: $( $ExceptedEmailDomains -join '; ' )"
$FilteredUserList = $UserList | Where-Object { $ExceptedEmailDomains -notcontains $_.EmailDomain }
Write-Host "Filtered List: $( $FilteredUserList.Count ) account(s)"

# How many accounts were found
Write-Verbose -Message "Found $( $FilteredUserList.Count ) accounts to check"
# Check for spammers

For ( $i = 0; $i -lt $FilteredUserList.Count; $i++ ) {
    Write-Progress -Activity "Checking for spammers" -Status "Checking $( $FilteredUserList[$i].Username )/$( $FilteredUserList[$i].EmailAddress )" -PercentComplete ( ( $i / $FilteredUserList.Count ) * 100 )
    $UriParameters = @{
        email    = $FilteredUserList[$i].EmailAddress
        username = $FilteredUserList[$i].Username
    }
    # make a call to the URI to see if it's a possible spammer
    $UserQueryResults = Invoke-RestMethod -Uri ( $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) + '&json' ) -Method Post -Credential $ApiCreds -MaximumRetryCount 3
    if ( $UserQueryResults ) {
        if ( $UserQueryResults.username.appears ) {
            $FilteredUserList[$i].SpamConfidenceUsername = $UserQueryResults.username.confidence
        }
        if ( $UserQueryResults.email.appears ) {
            $FilteredUserList[$i].SpamConfidenceEmail = $UserQueryResults.email.confidence
        }
        $FilteredUserList[$i].SpamCheckDateUTC = ( Get-Date ).ToUniversalTime()
        # Check to see if the confidence is over 50% (combined)
        if ( $FilteredUserList[$i].SpamConfidence -gt $MinConfScore ) {
            Write-Host "Moderating $( $FilteredUserList[$i].Username ) / $( $FilteredUserList[$i].EmailAddress ) [Confidence Score: $( $FilteredUserList[$i].SpamConfidence )]" -ForegroundColor Red
            Write-Progress -Activity "Moderating User" -Status "Moderating $( $FilteredUserList[$i].Username )"
            Set-VtUser -UserId $FilteredUserList[$i].UserId -ModerationLevel Moderated -AccountStatus ApprovalPending -HideContent -Confirm:$false
            $FilteredUserList[$i].FlaggedAsSpammer = $true
            Write-Progress -Activity "Moderating User" -Completed
        }
    }

}
Write-Progress -Activity "Checking for spammers" -Completed
$FilteredUserList | Export-Csv -Path .\Exports\QueryForSpammers.csv -Append
