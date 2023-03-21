<#
.Synopsis
   ConvertFrom-Theme
.DESCRIPTION
   Converts an XML file to a theme breakdown
.EXAMPLE
   ConvertFrom-Theme -Path 'P:\ath\To\Theme\File.xml'
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   XML File Path
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function ConvertFrom-Theme {
    [CmdletBinding(DefaultParameterSetName = 'Theme File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Path to the Theme File    
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Theme File')]
        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 1,
            ParameterSetName = 'Theme File with Export')]
        [Alias("FullName")] 
        $FilePath,

        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 1,
            ParameterSetName = 'Theme File with Export')]
        [System.IO.DirectoryInfo]$OutPath,

        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 2,
            ParameterSetName = 'Theme File with Export')]
        [switch]$Force,

        # Param3 help description
        [Parameter(ParameterSetName = 'Another Parameter Set')]
        [ValidatePattern("[a-z]*")]
        [ValidateLength(0, 15)]
        [String]
        $Param3
    )

    Begin {
    }
    Process {
        
        if ($pscmdlet.ShouldProcess("Target", "Operation")) {
            $ThemeContents = [xml]( Get-Content -Path "C:\Users\kevin.sparenberg\Downloads\Social-Site-Theme.xml" )
            $Details = $ThemeContents.theme | Select-Object -Property name, version, description, id, themeTypeId, lastModified, mediaMaxHeightPixels, mediaMaxWidthPixels
            
            #region Head Script
            if ( $ThemeContents.theme.headScript.language -eq "Velocity" ) {
                $HeadExtension = ".htm"
            }
            else {
                # JavaScript
                $HeadExtension = ".js"
            }
            $HeadScript = $ThemeContents.theme.headScript.InnerText
            #endregion Head Script
            
            #region Body Script
            if ( $ThemeContents.theme.bodyScript.language -eq "Velocity" ) {
                $BodyExtension = ".htm"
            }
            else {
                # JavaScript
                $BodyExtension = ".js"
            }
            $BodyScript = $ThemeContents.theme.bodyScript.InnerText
            #endregion Body Script
            
            #region Configuration
            $Configuration = $ThemeContents.theme.configuration.InnerText
            #endregion Configuration
            
            #region Palettes
            $Palettes = $ThemeContents.theme.paletteTypes.InnerText
            #endregion Palettes
            
            #region Language Resources
            $LanguageResources = $ThemeContents.theme.languageResources.InnerText
            #endregion Language Resources
            
            $PreviewImage = "" | Select-Object -Property @{ Name = "FileName"; Expression = { $ThemeContents.theme.previewImage.name } }, @{ Name = 'Data'; Expression = { $ThemeContents.theme.previewImage.InnerText } }
            
            $Files = $ThemeContents.theme.files.file | ForEach-Object {
                $_ | Select-Object -Property @( 
                    @{ Name = 'FileName'; Expression = { $_.name } }, 
                    @{ Name = 'Data'; Expression = { $_.InnerText } },
                    @{ Name = 'Type'; Expression = {
                            switch ( $_.name.Split('.')[-1]) {
                                { $_ -in ( 'jpg', 'png', 'gif', 'svg', 'ico' ) }
                                { 'Images' }
                                { $_ -in ( 'eot', 'ttf', 'woff' ) }
                                { 'Fonts' }
                                { $_ -in ( 'css', 'less' ) }
                                { 'Style Sheet Includes' }
                                Default
                                { 'Other' }
                            }
                        }
                    } 
                )
            }
            
            $JavaScriptFiles = $ThemeContents.theme.javascriptFiles.file | ForEach-Object {
                $_ | Select-Object -Property @( 
                    @{ Name = 'FileName'; Expression = { $_.name } }, 
                    @{ Name = 'Data'; Expression = { $_.InnerText } } 
                )
            }
            
            $StyleFiles = $ThemeContents.theme.styleFiles.file | ForEach-Object {
                $_ | Select-Object -Property @( 
                    @{ Name = 'FileName'; Expression = { $_.name } },
                    @{ Name = 'Data'; Expression = { $_.InnerText } },
                    @{ Name = 'applyToAuthorizationRequests'; Expression = { $_.applyToAuthorizationRequests } },
                    @{ Name = 'applyToModals'; Expression = { $_.applyToModals } },
                    @{ Name = 'applyToNonModals'; Expression = { $_.applyToNonModals } },
                    @{ Name = 'internetExplorerMaxVersion'; Expression = { $_.internetExplorerMaxVersion } },
                    @{ Name = 'isRightToLeft'; Expression = { $_.isRightToLeft } },
                    @{ Name = 'mediaQuery'; Expression = { $_.mediaQuery } }
                )
            }
            
            # pageLayouts

            if ( $OutPath ) {
                if ( -not ( Test-Path -Path ( Join-Path -Path $OutPath -ChildPath $Details.Name ) ) ) {
                    Write-Verbose -Message "Directory '$( ( Join-Path -Path $OutPath -ChildPath $Details.Name ) )' does not exist - creating"
                    $OutputPath = New-Item -ItemType Directory -Path ( Join-Path -Path $OutPath -ChildPath $Details.Name )

                }
                else {
                    Write-Verbose -Message "Directory '$( ( Join-Path -Path $OutPath -ChildPath $Details.Name ) )' exists - using"
                    $OutputPath = Join-Path -Path $OutPath -ChildPath $Details.Name
                }

                $Details | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath '_Details.txt' ) -Force:$Force
                $HeadScript | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "headScript$( $HeadExtension )" ) -Force:$Force
                $BodyScript | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "bodyScript$( $BodyExtension )" ) -Force:$Force
                $Configuration | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "configuration.xml" ) -Force:$Force
                $Palettes | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "paletteTypes.xml" ) -Force:$Force
                if ( $PreviewImage ) {
                    [System.Convert]::FromBase64CharArray($PreviewImage.Data, 0, $PreviewImage.Data.Length ) | Set-Content -Path ( Join-Path -Path $OutputPath -ChildPath "$( $PreviewImage.FileName )" ) -AsByteStream
                }
                if ( $Files ) {
                    For ( $i = 0; $i -lt $Files.Count; $i++ ) {
                        if ( -not ( Test-Path -Path ( Join-Path -Path ( Join-Path -Path $OutputPath -ChildPath "files" ) -ChildPath "$( $Files[$i].Type )" )  ) ) {
                            $OutputFilesPath = New-Item -ItemType Directory -Path ( Join-Path -Path ( Join-Path -Path $OutputPath -ChildPath "files" ) -ChildPath "$( $Files[$i].Type )" ) 
                        }
                        else {
                            $OutputFilesPath = ( Join-Path -Path ( Join-Path -Path $OutputPath -ChildPath "files" ) -ChildPath "$( $Files[$i].Type )" )
                        }
                        Write-Progress -Activity "Extracting 'Files' from Theme" -PercentComplete ( 100 * ( $i / $Files.Count ) ) -Status "Exporting $( $Files[$i].FileName ) to $( $Files[$i].Type ) folder"
                        [System.Convert]::FromBase64CharArray($Files[$i].Data, 0, $Files[$i].Data.Length ) | Set-Content -Path ( Join-Path -Path $OutputFilesPath -ChildPath "$( $Files[$i].FileName )" ) -AsByteStream -Force:$Force
                    }
                    Write-Progress -Activity "Extracting 'Files' from Theme" -Completed
                }
                else {
                    Write-Host "No additional files detected in theme"
                }

                if ( $JavaScriptFiles ) {
                    if ( -not ( Test-Path -Path ( Join-Path -Path $OutputPath -ChildPath "javascriptFiles" ) ) ) {
                        $OutputFilesPath = New-Item -ItemType Directory -Path ( Join-Path -Path $OutputPath -ChildPath "javascriptFiles" )
                    }
                    else {
                        $OutputFilesPath = ( Join-Path -Path $OutputPath -ChildPath "javascriptFiles" )
                    }
                    For ( $i = 0; $i -lt $JavaScriptFiles.Count; $i++ ) {
                        Write-Progress -Activity "Extracting 'JavaScript Files' from Theme" -PercentComplete ( 100 * ( $i / $JavaScriptFiles.Count ) ) -Status "Exporting $( $JavaScriptFiles[$i].FileName )"
                        [System.Convert]::FromBase64CharArray($JavaScriptFiles[$i].Data, 0, $JavaScriptFiles[$i].Data.Length ) | Set-Content -Path ( Join-Path -Path $OutputFilesPath -ChildPath "$( $JavaScriptFiles[$i].FileName )" ) -AsByteStream -Force:$Force
                    }
                    Write-Progress -Activity "Extracting 'JavaScript Files' from Theme" -Completed
                }
                else {
                    Write-Host "No JavaScript files detected in theme"
                }
                if ( $StyleFiles ) {
                    if ( -not ( Test-Path -Path ( Join-Path -Path $OutputPath -ChildPath "styleFiles" ) ) ) {
                        $OutputFilesPath = New-Item -ItemType Directory -Path ( Join-Path -Path $OutputPath -ChildPath "styleFiles" )
                    }
                    else {
                        $OutputFilesPath = ( Join-Path -Path $OutputPath -ChildPath "styleFiles" )
                    }
                    For ( $i = 0; $i -lt $StyleFiles.Count; $i++ ) {
                        Write-Progress -Activity "Extracting 'Style Files' from Theme" -PercentComplete ( 100 * ( $i / $StyleFiles.Count ) ) -Status "Exporting $( $StyleFiles[$i].FileName )"
                        [System.Convert]::FromBase64CharArray($StyleFiles[$i].Data, 0, $StyleFiles[$i].Data.Length ) | Set-Content -Path ( Join-Path -Path $OutputFilesPath -ChildPath "$( $StyleFiles[$i].FileName )" ) -AsByteStream -Force:$Force
                        $StyleFiles[$i] | Select-Object -ExcludeProperty 'FileName', 'Data' | Out-File -FilePath ( Join-Path -Path $OutputFilesPath -ChildPath "$( $StyleFiles[$i].FileName )_settings.txt" ) -Force:$Force
                    }
                    Write-Progress -Activity "Extracting 'Style Files' from Theme" -Completed
                }
                else {
                    Write-Host "No style files detected in theme"
                }

            }
            else {

                # PassThru
                "" | Select-Object -Property @(
                    @{ Name = 'Details'; Expression = { $Details } }, 
                    @{ Name = 'HeadScript'; Expression = { $HeadScript } },
                    @{ Name = 'BodyScript'; Expression = { $BodyScript } },
                    @{ Name = 'Configuration'; Expression = { $Configuration } },
                    @{ Name = 'Palettes'; Expression = { $Palettes } },
                    @{ Name = 'LanguageResources'; Expression = { $LanguageResources } },
                    @{ Name = 'PreviewImage'; Expression = { $PreviewImage } },
                    @{ Name = 'Files'; Expression = { $Files } },
                    @{ Name = 'JavaScriptFiles'; Expression = { $JavaScriptFiles } },
                    @{ Name = 'StyleFiles'; Expression = { $StyleFiles } }
                )
            }
        }
    }
    End {
    }
}