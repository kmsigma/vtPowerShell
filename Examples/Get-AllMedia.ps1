$RootFolder = "\\kms-nas\Scratch\THWACK\Content Exchange"
$Galleries = Get-VtGallery | Where-Object { $_.Url -like "*/content-exchange/*" -and $_.Enabled }
# Build Folders for the Groups and Galleries
$Galleries | Add-Member -MemberType ScriptProperty -Name "LocalGalleryPath" -Value { Join-Path -Path $RootFolder -ChildPath "$( $this.GroupName )/$( $this.Name )" } -Force
$Galleries | ForEach-Object {
    if ( -not ( Test-Path -Path $_.LocalGalleryPath -ErrorAction SilentlyContinue ) ) {
        New-Item -ItemType Directory -Path $_.LocalGalleryPath | Out-Null
    }
}

#$Media = $Galleries | Get-VtGalleryMedia

$Media = $Galleries | Get-VtGalleryMedia -ReturnFileInfo
$Media | Add-Member -MemberType AliasProperty -Name "Source" -Value "FileUrl" -Force
$Media | Add-Member -MemberType ScriptProperty -Name "Destination" -Value { Join-Path -Path $LocalGalleryPath -ChildPath $this.FileId } -Force
$Media | Add-Member -MemberType AliasProperty -Name "Description" -Value "Title"
$Media | Sort-Object -Property GalleryId, FileId
For ( $i = 0; $i -lt $Media.Count; $i++ ) {
    Write-Progress -Activity "Leeching Media Galleries" -CurrentOperation "Downloading $( $Media[$i].FileName ) from $( $Media[$i].FileName )" -PercentComplete ( ( $I / $Media.Count ) * 100 )
    $i++
}
ForEach ( $Gallery in $Galleries | Sort-Object -Property Name ) { 
    $LocalGalleryPath = $Gallery.LocalGalleryPath
    $Gallery | Get-VtGalleryMedia -ReturnFileInfo | ForEach-Object {
        #check for child output folder
        $_ | Add-Member -MemberType AliasProperty -Name "Source" -Value "FileUrl" -Force
        $_ | Add-Member -MemberType ScriptProperty -Name "Destination" -Value { Join-Path -Path $LocalGalleryPath -ChildPath $this.FileId } -Force
        $_ | Add-Member -MemberType AliasProperty -Name "Description" -Value "Title"
        if ( -not ( Test-Path -Path $_.Destination ) ) {
            New-Item -ItemType Directory $_.Destination | Out-Null
        }
        Write-Host "Downloading $( $_.Source )`n`t $( $_.Destination )"
        $_ | Start-BitsTransfer -Description $_.Title
        $_ | Select-Object -Property FileId, GalleryId, GroupId, Author, Date, Title, Tags, Url, CommentCount, Views, Downloads, RatingCount, RatingSum, FileName, FileType, FileSize, FileUrl | ConvertTo-Json | Out-File -FilePath ( Join-Path -Path $_.Destination -ChildPath "_fileInfo.json") -Force -Confirm:$false
    }
}
