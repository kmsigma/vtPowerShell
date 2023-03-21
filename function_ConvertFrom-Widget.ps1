<#
.Synopsis
   ConvertFrom-Widget
.DESCRIPTION
   Converts an XML file to a Widget breakdown
.EXAMPLE
   ConvertFrom-Widget -Path 'P:\ath\To\Widget\File.xml'
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
function ConvertFrom-Widget {
    [CmdletBinding(DefaultParameterSetName = 'Widget File', 
        SupportsShouldProcess = $true, 
        PositionalBinding = $false,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Path to the Widget File    
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Widget File')]
        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 1,
            ParameterSetName = 'Widget File with Export')]
        [Alias("FullName")] 
        $FilePath,

        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 1,
            ParameterSetName = 'Widget File with Export')]
        [System.IO.DirectoryInfo]$OutPath,

        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 2,
            ParameterSetName = 'Widget File with Export')]
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
            $WidgetContents = [xml]( Get-Content -Path $FilePath )
            $Details = $WidgetContents.scriptedContentFragments.scriptedContentFragment | Select-Object -Property name, version, description, instanceIdentifier, theme, isCacheable, varyCacheByUser, showHeaderByDefault, cssClass, lastModified
            
            #region Content Script
            if ( $WidgetContents.scriptedContentFragments.scriptedContentFragment.contentScript.language -eq "Velocity" ) {
                $ContentScriptExtension = ".htm"
            }
            else {
                # JavaScript
                $ContentScriptExtension = ".js"
            }
            $ContentScript = $WidgetContents.scriptedContentFragments.scriptedContentFragment.contentScript.InnerText
            #endregion Content Script
            
            #region Header Script
            if ( $WidgetContents.scriptedContentFragments.scriptedContentFragment.header.language -eq "Velocity" ) {
                $HeaderExtension = ".htm"
            }
            else {
                # JavaScript
                $HeaderExtension = ".js"
            }
            $HeaderScript = $WidgetContents.scriptedContentFragments.scriptedContentFragment.header.InnerText
            #endregion Header Script
            
            #region Configuration
            $Configuration = $WidgetContents.scriptedContentFragments.scriptedContentFragment.configuration.InnerText
            #endregion Configuration
            
            #region Language Resources
            $LanguageResources = $WidgetContents.scriptedContentFragments.scriptedContentFragment.languageResources.InnerText
            #endregion Language Resources

            #region Add'l CSS Script
            if ( $WidgetContents.scriptedContentFragments.scriptedContentFragment.additionalCssScript.language -eq "Velocity" ) {
                $AddlCssScriptExtension = ".htm"
            }
            else {
                # JavaScript
                $AddlCssScriptExtension = ".ja"
            }
            $AddlCssScript = $WidgetContents.scriptedContentFragments.scriptedContentFragment.additionalCssScript.InnerText
            #endregion Add'l CSS Script
            
            #region Capture Files
            $Files = $WidgetContents.scriptedContentFragments.scriptedContentFragment.files.file | ForEach-Object {
                $_ | Select-Object -Property @( 
                    @{ Name = 'FileName'; Expression = { $_.name } }, 
                    @{ Name = 'Data'; Expression = { $_.InnerText } }
                )
            }
            #endregion Capture Files
            
            $WidgetName = if ( $WidgetContents.scriptedContentFragments.scriptedContentFragment.name -like '${resource:*' ) {
                $LocalizedResources = ( [xml]($WidgetContents.scriptedContentFragments.scriptedContentFragment.languageResources.InnerText) ).language | Where-Object { $_.Key -eq $PsCulture }
                if ( $LocalizedResources ) {
                    $ResourceKey = $WidgetContents.scriptedContentFragments.scriptedContentFragment.name.Replace('${resource:', '').Replace('}', '')
                ( $LocalizedResources.resource | Where-Object { $_.name -eq $ResourceKey } ).InnerText
                }
                else {
                    Get-Item -Path $FilePath | Select-Object -ExpandProperty BaseName
                }
            }
            else {
                $Details.Name
            }
            
            if ( $OutPath ) {
                if ( -not ( Test-Path -Path ( Join-Path -Path $OutPath -ChildPath $WidgetName ) ) ) {
                    Write-Verbose -Message "Directory '$( ( Join-Path -Path $OutPath -ChildPath $WidgetName ) )' does not exist - creating"
                    $OutputPath = New-Item -ItemType Directory -Path ( Join-Path -Path $OutPath -ChildPath $WidgetName )

                }
                else {
                    Write-Verbose -Message "Directory '$( ( Join-Path -Path $OutPath -ChildPath $WidgetName ) )' exists - using"
                    $OutputPath = Join-Path -Path $OutPath -ChildPath $WidgetName
                }

                $Details | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath '_Details.txt' ) -Force:$Force
                $ContentScript | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "contentScript$( $ContentScriptExtension )" ) -Force:$Force
                $HeaderScript | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "headerScript$( $HeaderExtension )" ) -Force:$Force
                $Configuration | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "configuration.xml" ) -Force:$Force
                $LanguageResources | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "languageResources.xml" ) -Force:$Force
                $AddlCssScript | Out-File -FilePath ( Join-Path -Path $OutputPath -ChildPath "additionalCssScript$( $AddlCssScriptExtension )" ) -Force:$Force
                if ( $Files ) {
                    For ( $i = 0; $i -lt $Files.Count; $i++ ) {
                        if ( -not ( Test-Path -Path ( Join-Path -Path $OutputPath -ChildPath "files" ) ) ) {
                            $OutputFilesPath = New-Item -ItemType Directory -Path ( Join-Path -Path $OutputPath -ChildPath "files" )
                        }
                        else {
                            $OutputFilesPath = ( Join-Path -Path $OutputPath -ChildPath "files" )
                        }
                        Write-Progress -Activity "Extracting 'Files' from Widget" -PercentComplete ( 100 * ( $i / $Files.Count ) ) -Status "Exporting $( $Files[$i].FileName )"
                        [System.Convert]::FromBase64CharArray($Files[$i].Data, 0, $Files[$i].Data.Length ) | Set-Content -Path ( Join-Path -Path $OutputFilesPath -ChildPath "$( $Files[$i].FileName )" ) -AsByteStream -Force:$Force
                    }
                    Write-Progress -Activity "Extracting 'Files' from Widget" -Completed
                }
                else {
                    Write-Host "No additional files detected in Widget"
                }
            }
            else {

                # PassThru
                "" | Select-Object -Property @(
                    @{ Name = 'Details'; Expression = { $Details } }, 
                    @{ Name = 'ContentScript'; Expression = { $ContentScript } },
                    @{ Name = 'HeaderScript'; Expression = { $HeaderScript } },
                    @{ Name = 'Configuration'; Expression = { $Configuration } },
                    @{ Name = 'LanguageResources'; Expression = { $LanguageResources } },
                    @{ Name = 'Files'; Expression = { $Files } }
                )
            }
        }
    }
    End {
    }
}