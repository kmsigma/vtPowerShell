<#
Very rudimentary query check for possible spammers
#>

# Include the settings (URI, Authentication, other things) from a settings file
. .\myThings\Resources\StopForumSpam.ps1

# What's the minimal confidence where we want to block the user?
# Confidence here is %ChanceOfUsername + %ChanceOfEmailAddress
$MinConfScore = 50
$StartDate = ( Get-Date ).AddDays(-7)
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
    $UserList += Get-VtUser -JoinedOn $Date -WarningAction SilentlyContinue | Select-Object UserId, Username, EmailAddress, Status, ModerationStatus, ContentHidden, JoinedDate, SpamConfidenceUsername, SpamConfidenceEmail | Where-Object { $_.ModerationStatus -ne 'Moderated' }

}

# How many accounts were found
Write-Verbose -Message "Found $( $UserList.Count ) accounts to check"
# Check for spammers

For ( $i = 0; $i -lt $UserList.Count; $i++ ) {
    Write-Progress -Activity "Checking for spammers" -Status "Checking $( $UserList[$i].Username )/$( $UserList[$i].EmailAddress )" -PercentComplete ( ( $i / $UserList.Count ) * 100 )
    $UriParameters = @{
        email    = $UserList[$i].EmailAddress
        username = $UserList[$i].Username
    }
    # make a call to the URI to see if it's a possible spammer
    $UserQueryResults = Invoke-RestMethod -Uri ( $Uri + '?' + ( $UriParameters | ConvertTo-QueryString ) + '&json' ) -Method Post -Credential $ApiCreds
    if ( $UserQueryResults ) {
        if ( $UserQueryResults.username.appears ) {
            $UserList[$i].SpamConfidenceUsername = $UserQueryResults.username.confidence
        }
        else {
            $UserList[$i].SpamConfidenceUsername = 0
        }
        if ( $UserQueryResults.email.appears ) {
            $UserList[$i].SpamConfidenceEmail = $UserQueryResults.email.confidence
        } else {
            $UserList[$i].SpamConfidenceEmail = 0
        }

        # Check to see if the confidence is over 50% (combined)
        if ( $UserList[$i].SpamConfidenceUsername + $UserList[$i].SpamConfidenceEmail -gt $MinConfScore ) {
            Write-Host "Moderating $( $UserList[$i].Username ) / $( $UserList[$i].EmailAddress ) [Confidence Score: $( $UserList[$i].SpamConfidenceUsername + $UserList[$i].SpamConfidenceEmail )]" -ForegroundColor Red
            Write-Progress -Activity "Moderating User" -Status "Moderating $( $UserList[$i].Username )"
            Set-VtUser -UserId $UserList[$i].UserId -ModerationLevel Moderated -AccountStatus ApprovalPending -HideContent -Confirm:$false
            Write-Progress -Activity "Moderating User" -Completed
        } else {
            Write-Host "Skipping $( $UserList[$i].Username ) / $( $UserList[$i].EmailAddress ) [Confidence Score: $( $UserList[$i].SpamConfidenceUsername + $UserList[$i].SpamConfidenceEmail )]" -ForegroundColor Yellow
        }
    }

}
Write-Progress -Activity "Checking for spammers" -Completed
