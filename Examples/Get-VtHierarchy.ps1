#region Get Everything
if ( -not ( $AllGroups ) ) { $AllGroups = Get-VtGroup }
if ( -not ( $AllForums ) ) { $AllForums = Get-VtForum }
if ( -not ( $AllBlogs ) ) { $AllBlogs = Get-VtBlog }
if ( -not ( $AllGalleries ) ) { $AllGalleries = Get-VtGallery }
if ( -not ( $AllIdeations ) ) { $AllIdeations = Get-VtChallenge }
if ( -not ( $AllWikis ) ) { $AllWikis = Get-VtWiki }
#endregion Get Everything

#region Add Type Information
$AllGroups | Add-Member -MemberType NoteProperty -Name 'ElementType' -Value 'Group' -Force
$AllForums | Add-Member -MemberType NoteProperty -Name 'ElementType' -Value 'Forum' -Force
$AllBlogs | Add-Member -MemberType NoteProperty -Name 'ElementType' -Value 'Blog' -Force
$AllGalleries | Add-Member -MemberType NoteProperty -Name 'ElementType' -Value 'Gallery' -Force
$AllIdeations | Add-Member -MemberType NoteProperty -Name 'ElementType' -Value 'Ideation' -Force
$AllWikis | Add-Member -MemberType NoteProperty -Name 'ElementType' -Value 'Wiki' -Force
#endregion Add Type Information

#region Add Parent Group
$AllForums | Add-Member -MemberType AliasProperty -Name 'ParentGroupId' -Value 'GroupId' -Force
$AllBlogs | Add-Member -MemberType AliasProperty -Name 'ParentGroupId' -Value 'GroupId' -Force
$AllGalleries | Add-Member -MemberType AliasProperty -Name 'ParentGroupId' -Value 'GroupId' -Force
$AllIdeations | Add-Member -MemberType AliasProperty -Name 'ParentGroupId' -Value 'GroupId' -Force
$AllWikis | Add-Member -MemberType AliasProperty -Name 'ParentGroupId' -Value 'GroupId' -Force
#endregion Add Parent Group

#region Add Latest Activity
#$AllBlogs | Add-Member -MemberType ScriptProperty -Name 'LatestPostDate' -Value { Get-VtBlogPost -BlogId $this.BlogId -SortBy MostRecent | Select-Object -First 1 | Select-Object -ExpandProperty PublishedDate } -Force
#$AllGalleries | Add-Member -MemberType ScriptProperty -Name 'LatestPostDate' -Value { Get-VtGalleryMedia -GalleryId $this.GalleryId -SortBy PostDate -Ascending:$false | Select-Object -First 1 | Select-Object -ExpandProperty Date } -Force
#endregion Add Latest Activity

$Nodes = @()
$Nodes += $AllGroups | Select-Object -Property @(
    @{ Name = 'Parent'; Expression = { $_.ParentGroupId } }
    'ElementType'
    @{ Name = 'ID'; Expression = { $_.GroupId } }
    'Name'
    'Description'
    'Url'
    #'PostCount'
    #'CommentOrRepliesCount'
    #'LatestPostDate'
    @{ Name = 'Access'; Expression = { $_.'GroupType' } }
)

$Nodes += $AllBlogs | Select-Object -Property @(
    @{ Name = 'Parent'; Expression = { $_.GroupId } }
    'ElementType'
    @{ Name = 'ID'; Expression = { $_.BlogId } }
    'Name'
    'Description'
    'Url'
    #'PostCount'
    #'CommentOrRepliesCount'
    #'LatestPostDate'
    @{ Name = 'Access'; Expression = { if ( $_.Enabled ) { 'Enabled' } else { 'Disabled' } } }
)

$Nodes += $AllForums | Select-Object -Property @(
    @{ Name = 'Parent'; Expression = { $_.GroupId } }
    'ElementType'
    @{ Name = 'ID'; Expression = { $_.ForumId } }
    'Name'
    'Description'
    'Url'
    #@{ Name = 'PostCount'; Expression = { $_.ThreadCount } }
    #@{ Name = 'CommentOrRepliesCount'; Expression = { $_.ReplyCount } }
    #'LatestPostDate'
    @{ Name = 'Access'; Expression = { if ( $_.Enabled ) { 'Enabled' } else { 'Disabled' } } }
)

$Nodes += $AllGalleries | Select-Object -Property @(
    @{ Name = 'Parent'; Expression = { $_.GroupId } }
    'ElementType'
    @{ Name = 'ID'; Expression = { $_.GalleryId } }
    'Name'
    'Description'
    'Url'
    #'PostCount'
    #'CommentOrRepliesCount'
    #'LatestPostDate'
    @{ Name = 'Access'; Expression = { if ( $_.Enabled ) { 'Enabled' } else { 'Disabled' } } }
)

$Nodes += $AllIdeations | Select-Object -Property @(
    @{ Name = 'Parent'; Expression = { $_.GroupId } }
    'ElementType'
    @{ Name = 'ID'; Expression = { $_.IdeationId } }
    'Name'
    'Description'
    'Url'
    #@{ Name = 'PostCount'; Expression = { $_.TotalPosts } }
    #'CommentOrRepliesCount'
    #@{ Name = 'LatestPostDate'; Expression = { $_.LastPostDate } }
    @{ Name = 'Access'; Expression = { if ( $_.Enabled ) { 'Enabled' } else { 'Disabled' } } }
)

$Nodes += $AllWikis | Select-Object -Property @(
    @{ Name = 'Parent'; Expression = { $_.GroupId } }
    'ElementType'
    @{ Name = 'ID'; Expression = { $_.WikiId } }
    'Name'
    'Description'
    'Url'
    #@{ Name = 'PostCount'; Expression = { $_.TotalPosts } }
    #'CommentOrRepliesCount'
    #@{ Name = 'LatestPostDate'; Expression = { $_.LastPostDate } }
    @{ Name = 'Access'; Expression = { if ( $_.Enabled ) { 'Enabled' } else { 'Disabled' } } }
)

$Nodes | Add-Member -MemberType ScriptProperty -Name "Ancestors" -Value {
    $Ancestors = @()
    $CurrentParentId = $this.Parent
    while ( $CurrentParentId ) {
        $HasParent = $AllGroups | Where-Object { $_.GroupId -eq $CurrentParentId }
        if ( $HasParent ) {
            $CurrentParentId = $HasParent.ParentGroupId
            $Ancestors += $HasParent.Name
        }
        else {
            $CurrentParentId = $null
        }
    }
    if ( $Ancestors ) {
        For ( $i = $Ancestors.Length - 1; $i -ge 0; $i-- ) {
            $Ancestors[$i]
        }
    }
} -Force

$Nodes | Add-Member -MemberType ScriptProperty -Name "Path" -Value { $this.Ancestors -join ' / ' } -Force
$Nodes | Add-Member -MemberType ScriptProperty -Name "FullPath" -Value { if ( $this.Path ) { "$( $this.Path ) / $( $this.Name )" } else { "THWACK" } } -Force

$Nodes | Select-Object FullPath, Url, Access, ID, Name, ElementType, Description | Sort-Object -Property FullPath, ElementType | Out-GridView
$Nodes | Select-Object FullPath, Url, Access, ID, Name, ElementType, Description | Sort-Object -Property FullPath, ElementType | Export-Csv -Path ".\Scratch\Hierarchy.csv" -Force -Confirm:$false