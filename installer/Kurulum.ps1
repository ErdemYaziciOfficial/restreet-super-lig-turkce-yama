$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Write-Host 'ReStreet Super Lig + Turkce Yama'
Write-Host 'Oyunu ve launcher uygulamasini kapatin.'
Write-Host 'Binaries ve Game klasorlerini iceren OYUN ANA KLASORUNU secin.'
$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = 'ReStreet oyun klasorunu secin (Binaries ve Game klasorlerinin bulundugu yer)'
$dialog.ShowNewFolderButton = $false
if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { Write-Host 'Kurulum iptal edildi.'; exit }
try { & "$PSScriptRoot/Install.ps1" -GameRoot $dialog.SelectedPath }
catch { Write-Host ('Kurulum yapilamadi: '+$_.Exception.Message) -ForegroundColor Red; exit 1 }
