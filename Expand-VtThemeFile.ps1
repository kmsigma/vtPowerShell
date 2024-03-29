﻿$ThemeFile = "C:\Users\kevin.sparenberg\GitHub\thwack.custom.html\themes\Social-Site-Theme.xml"
$OutputPath = Get-Item -Path $ThemeFile | Select-Object -Property @{ Name = "DirPlusBase"; Expression = { Join-Path -Path $_.Directory -ChildPath $_.BaseName } } | Select-Object -ExpandProperty DirPlusBase
# Build the Output Folders
if ( -not ( Test-Path -Path $OutputPath -ErrorAction SilentlyContinue ) ) {
    Write-Warning -Message "Creating '$OutputPath' folder"
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}


function ConvertFrom-Base64 {
    [CmdletBinding()]
    param (
        # The string to decode    
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string[]]$String
    )
    BEGIN {
        # nothing to see here
    }
    PROCESS {
        ForEach ( $s in $String ) {
            [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($s))
        }
    }
    END {
        # nothing to see here
    }
}

# Read the XML File
$ThemeContents = [xml]( Get-Content -Path $ThemeFile )

#region Build a list of elements to export
$ItemsToExport = @()
$ItemsToExport += [PsCustomObject]@{ 
    Name        = "Header";
    Description = "Header Information";
    ParentName  = 'headScript';
    ChildName   = "#cdata-section"
    FileType    = "Detected"
}
$ItemsToExport += [PsCustomObject]@{ 
    Name        = "Body";
    Description = "Body Information";
    ParentName  = 'bodyScript';
    ChildName   = "#cdata-section"
    FileType    = "Detected"
}
$ItemsToExport += [PsCustomObject]@{ 
    Name        = "Configuration";
    Description = "Configuration Details";
    ParentName  = 'configuration';
    ChildName   = "#cdata-section"
    FileType    = "XML"
}
$ItemsToExport += [PsCustomObject]@{ 
    Name        = "Palette Types";
    Description = "Palette Information";
    ParentName  = 'paletteTypes';
    ChildName   = "#cdata-section"
    FileType    = "XML"
}
$ItemsToExport += [PsCustomObject]@{ 
    Name        = "Resources";
    Description = "Language Resources";
    ParentName  = 'languageResources';
    ChildName   = "#cdata-section"
    FileType    = "XML"
}
$ItemsToExport += [PsCustomObject]@{ 
    Name        = "Preview Image";
    Description = "Preview Image";
    ParentName  = 'previewImage';
    ChildName   = "#cdata-section"
    FileType    = "PNG"
}
#endregion Build a list of elements to export

#region Cycle through each element and export them
ForEach ( $ItemToExport in $ItemsToExport ) {
    # Grab the Current Node
    $CurrentNode = $ThemeContents.theme.$( $ItemToExport.ParentName )
    if ( $ItemToExport.FileType -eq "Detected" ) {
        # Detect and Export
        if ( $CurrentNode.language -eq 'Velocity' ) {
            # Detected as 'Velocity'
            Write-Host "Saving $( $ItemToExport.Description )..."
            $CurrentNode.$( $ItemToExport.ChildName ) | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "$( $ItemToExport.Name ).html" ) -Force -Confirm:$false
        }
        elseif ( $CurrentNode.language -eq 'JavaScript' ) {
            # Detected as 'JavaScript'
            Write-Host "Saving $( $ItemToExport.Description )..."
            $CurrentNode.$( $ItemToExport.ChildName ) | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "$( $ItemToExport.Name ).js" ) -Force -Confirm:$false
        }
        else {
            # Neither detected
            Write-Warning -Message "No valid $( $ItemToExport.Description ) found"
        }
    }
    elseif ( $ItemToExport.FileType -eq "Image" ) {
        Write-Host "Saving $( $ItemToExport.Description )..."
        if ( $CurrentNode.$( $ItemToExport.ChildName ) ) {
            ( $CurrentNode.$( $ItemToExport.ChildName ) | ConvertFrom-Base64 ) | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "$( $ItemToExport.Name ).$( $ItemToExport.FileType.ToLower() )" ) -Force -Confirm:$false 
        } else {
            Write-Host "$( $ItemToExport.Description ) is empty" -ForegroundColor Red
        }
    }
    else {
        # Export with extension
        Write-Host "Saving $( $ItemToExport.Description )..."
        $CurrentNode.$( $ItemToExport.ChildName ) | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "$( $ItemToExport.Name ).$( $ItemToExport.FileType.ToLower() )" ) -Force -Confirm:$false
    }
}
#endregion Cycle through each element and export them

#region Export 'Files'
# Build the output path for any files
$FileTypes = @()
$FileTypes += [PSCustomObject]@{
    Name       = "Files"
    Parent     = "files"
    ExportPath = "Files"
}
$FileTypes += [PSCustomObject]@{
    Name       = "Javascript Files"
    Parent     = "javascriptFiles"
    ExportPath = "Javascript Files"
}
$FileTypes += [PSCustomObject]@{
    Name       = "Style Files"
    Parent     = "styleFiles"
    ExportPath = "Style Files"
}

ForEach ( $FileType in $FileTypes ) {
    $FileOutputPath = Join-Path -Path $OutputPath -ChildPath $FileType.ExportPath

    if ( -not ( Test-Path -Path $FileOutputPath -ErrorAction SilentlyContinue ) ) {
        Write-Warning -Message "Creating '$FileOutputPath' folder"
        New-Item -ItemType Directory -Path $FileOutputPath | Out-Null
    }
    # Cycle through and export the files
    ForEach ( $FileEntry in $ThemeContents.theme.$( $FileType.Parent ).file ) {
        Write-Host "Saving [$( $FileType.ExportPath )\$( $FileEntry.Name )]"
        ( ConvertFrom-Base64 -String $FileEntry.'#cdata-section' ) | Out-File -FilePath ( Join-Path -Path $FileOutputPath -ChildPath $FileEntry.Name ) -Force -Confirm:$false
    }
}
#endregion Export 'Files'
