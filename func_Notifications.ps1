
<#

$NotificationsResponse = Invoke-RestMethod -Uri ( $CommunityDomain + 'api.ashx/v2/systemnotifications.json' ) -Headers $AuthHeader
$NotificationsResponse.PageSize
$NotificationsResponse.TotalCount
$NotificationsResponse.SystemNotifications
$NotificationsResponse.SystemNotifications | Select-Object Id, Subject, FirstOccurredDate, LastOccurredDate, TotalOccurrences, IsResolved | Out-gridView

Invoke-RestMethod -Method Post -Uri ( $CommunityDomain + 'api.ashx/v2/systemnotifications.json?id=523?IsResolved=true') -Header ( $AuthHeader | Set-VtAuthHeader -RestMethod Put )
$Body = @{
    "id" = 523;
    "IsResolved" = "true"
}
Invoke-RestMethod -Method Post -Uri ( $CommunityDomain + 'api.ashx/v2/systemnotifications.json') -Body $Body -Header ( $AuthHeader | Set-VtAuthHeader -RestMethod Put )

Invoke-RestMethod -Method Post -Uri ( $CommunityDomain + 'api.ashx/v2/systemnotifications.json?id=523') -Header ( $AuthHeader | Set-VtAuthHeader -RestMethod Delete )
#>