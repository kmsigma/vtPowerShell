$WidgetFile = "C:\Path\To\Your\WidgetFile.xml"
$OutputPath = Get-Item -Path $WidgetFile | Select-Object -Property @{ Name = "DirPlusBase"; Expression = { Join-Path -Path $_.Directory -ChildPath $_.BaseName } } | Select-Object -ExpandProperty DirPlusBase
# Build the Output Folders
if ( -not ( Test-Path -Path $OutputPath -ErrorAction SilentlyContinue ) ) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

# Read the XML File
$WidgetContents = [xml]( Get-Content -Path $WidgetFile )

#region Build a list of elements to export
$ItemsToExport = @()
$ItemsToExport += [PsCustomObject]@{ 
                    Name        = "Content";
                    Description = "Content Script";
                    ParentName  = 'contentScript';
                    ChildName   = "#cdata-section"
                    FileType    = "Detected"
                }
$ItemsToExport += [PsCustomObject]@{ 
                    Name        = "Configuration";
                    Description = "Configuration Script";
                    ParentName  = 'configuration';
                    ChildName   = "#cdata-section"
                    FileType    = "XML"
                }
$ItemsToExport += [PsCustomObject]@{ 
                    Name        = "Header";
                    Description = "Header Script";
                    ParentName  = 'headerScript';
                    ChildName   = "#cdata-section"
                    FileType    = "XML"
                }
$ItemsToExport += [PsCustomObject]@{ 
                    Name        = "CSS Script";
                    Description = "Additional CSS Scripts";
                    ParentName  = 'additionalCssScript';
                    ChildName   = "#cdata-section"
                    FileType    = "Detected"
                }
$ItemsToExport += [PsCustomObject]@{ 
                    Name        = "Resources";
                    Description = "Language Resources";
                    ParentName  = 'languageResources';
                    ChildName   = "#cdata-section"
                    FileType    = "XML"
                }
#endregion Build a list of elements to export

#region Cycle through each element and export them
ForEach ( $ItemToExport in $ItemsToExport ) {
    # Grab the Current Node
    $CurrentNode = $WidgetContents.scriptedContentFragments.scriptedContentFragment.$( $ItemToExport.ParentName )
    if ( $ItemToExport.FileType -eq "Detected" ) {
        # Detect and Export
        if ( $CurrentNode.language -eq 'Velocity' ) {
            # Detected as 'Velocity'
            Write-Host "Saving $( $ItemToExport.Description )..."
            $CurrentNode.$( $ItemToExport.ChildName ) | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "$( $ItemToExport.Name ).html" ) -Force -Confirm:$false
        } elseif ( $CurrentNode.language -eq 'JavaScript' ) {
            # Detected as 'JavaScript'
            Write-Host "Saving $( $ItemToExport.Description )..."
            $CurrentNode.$( $ItemToExport.ChildName ) | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "$( $ItemToExport.Name ).js" ) -Force -Confirm:$false
        } else {
            # Neither detected
            Write-Warning -Message "No valid $( $ItemToExport.Description ) found"
        }
    } else {
        # Export with extension
        Write-Host "Saving $( $ItemToExport.Description )..."
        $CurrentNode.$( $ItemToExport.ChildName ) | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "$( $ItemToExport.Name ).$( $ItemToExport.FileType.ToLower() )" ) -Force -Confirm:$false
    }
}
#endregion Cycle through each element and export them

#region Export 'Files'
# Build the output path for any files
$FileOutputPath = Join-Path -Path $OutputPath -ChildPath "Files"

if ( -not ( Test-Path -Path $FileOutputPath -ErrorAction SilentlyContinue ) ) {
    New-Item -ItemType Directory -Path $FileOutputPath | Out-Null
}
# Cycle through and export the files
ForEach ( $FileEntry in $WidgetContents.scriptedContentFragments.scriptedContentFragment.files.file ) {
    Write-Host "Saving [Files\$( $FileEntry.Name )]"
    [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($FileEntry.'#text')) | Out-File -FilePath ( Join-Path -Path $FileOutputPath -ChildPath $FileEntry.Name ) -Force -Confirm:$false
}
#endregion Export 'Files'