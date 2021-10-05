enum Status {
    Approved
    ApprovalPending
    Banned
    Disapproved
}

enum ModerationStatus {
    Unmoderated
    Moderated
}

enum BanReason {
    Profanity
    Advertising
    Spam
    Aggressive
    BadUsername
    BadSignature
    BanDodging
    Other
}

class VtUser {
    [long]$UserID
    [string]$Username
    [string]$EmailAddress
    [Status]$Status
    [ModerationStatus] hidden $ModerationStatus
    [bool] hidden $IsIgnored
    [string] hidden $CurrentPresence
    [datetime] hidden $JoinDate
    [datetime] hidden $LastLogin
    [datetime]$LastVisit
    [long] hidden $LifetimePoints
    [bool] hidden $EmailEnabled
    [string] hidden $MentionText

    VtUser() {
        # Default Constructor
    }
    VtUser(
        [long]$intUserID,
        [string]$strUsername,
        [string]$strEmailAddress,
        [string]$strStatus,
        [string]$strModerationStatus,
        [bool]$boolIsIgnored,
        [string]$strCurrentPresence,
        [datetime]$dtJoinDate,
        [datetime]$dtLastLogin,
        [datetime]$dtLastVisit,
        [long]$intLifetimePoints,
        [bool]$boolEmailEnabled,
        [string]$strMentionText
    ) {
        $this.UserId = $intUserID
        $this.Username = $strUsername
        $this.EmailAddress = $strEmailAddress
        $this.Status = $strStatus
        $this.ModerationStatus = $strModerationStatus
        $this.IsIgnored = $boolIsIgnored
        $this.CurrentPresence = $strCurrentPresence
        $this.JoinDate = $dtJoinDate
        $this.LastLogin = $dtLastLogin
        $this.LastVisit = $dtLastVisit
        $this.LifetimePoints = $intLifetimePoints
        $this.EmailEnabled = $boolEmailEnabled
        $this.MentionText = $strMentionText
    }
    VtUser( [int]$intUserId, [string]$strUsername, [string]$strEmailAddress ) {
        $this.UserId = $intUserId
        $this.Username = $strUsername
        $this.EmailAddress = $strEmailAddress
    }
}

<#
$defaultProperties = @("Name", "Property2", "Property4")

$defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet",[string[]]$defaultProperties)

$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

$myObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers
#>