param([Parameter(Mandatory=$true)][string]$GameRoot)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $GameRoot).Path
$manifest = Get-Content -LiteralPath "$PSScriptRoot/manifest.json" -Raw | ConvertFrom-Json
$dll = Join-Path $root 'Binaries/fifastreet_fifadllzf_xex.dll'
$expected = '82538e789ba970c3f7634e8929eecf12b8a161167f260ceac4949b44f75c2643'
$patched = 'ec111a723fb0874ffbc7f613fb23290f8605e2338a36e56a307f4bccccb16d58'
if (!(Test-Path -LiteralPath (Join-Path $root 'Game/data0.big'))) { throw 'ReStreet 1.5.5 new folder layout required (Binaries + Game).' }
$hash = (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash.ToLower()
if ($hash -ne $patched) { throw 'Unsupported game DLL. Install official ReStreet 1.5.5 Online Beta first.' }
$exeHash = (Get-FileHash -LiteralPath (Join-Path $root 'Binaries/fifastreet.exe')).Hash.ToLower()
if ($exeHash -ne 'ca08bebe843648ba1896dfe403e0c6f5176bdab7e794294100809ff4cbd1fdf4') { throw 'Unsupported game executable.' }
if (Get-Process fifastreet,FifaStreetLauncher -ErrorAction SilentlyContinue) { throw 'Close game and launcher first.' }
$tempDir = Join-Path ([IO.Path]::GetTempPath()) ('SuperLig-'+[guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir | Out-Null
try {
 . "$PSScriptRoot/ArchivePatch.ps1"
 $archiveSource = Prepare-Archive $root $PSScriptRoot $tempDir
 function Get-PayloadSource([string]$RelativePath) {
  if ($RelativePath -eq 'Game/data3.big') { return $archiveSource }
  return (Join-Path "$PSScriptRoot/payload" $RelativePath)
 }
if ((Get-FileHash -LiteralPath (Join-Path $root 'Game/data0.big')).Hash.ToLower() -ne '8b0e12c874c2a756f5add28f8c2723564a36618571f2862f97394ad1f160e4d3') { throw 'Once v1.0 ana yamayi kurun. Bu dosya yalnizca forma duzeltmesidir.' }
# Validate the entire payload and containment before changing the installation.
foreach ($f in $manifest.files) {
 $target = [IO.Path]::GetFullPath((Join-Path $root $f.path))
 if (!$target.StartsWith($root.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid payload path.' }
 $source = Get-PayloadSource $f.path
 if ((Get-FileHash -LiteralPath $source).Hash.ToLower() -ne $f.sha256) { throw "Damaged package: $($f.path)" }
}
$backup = Join-Path $root ('SuperLigBackup/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$records = @()
try {
 foreach ($f in $manifest.files) {
  $target = Join-Path $root $f.path
  if ((Test-Path -LiteralPath $target) -and (Get-FileHash -LiteralPath $target).Hash.ToLower() -eq $f.sha256) { continue }
  $existed = Test-Path -LiteralPath $target
  if ($existed) {
   $save = Join-Path $backup $f.path
   New-Item -ItemType Directory -Path (Split-Path $save) -Force | Out-Null
   Copy-Item -LiteralPath $target -Destination $save
  }
  $records += [pscustomobject]@{path=$f.path;existed=$existed}
  ConvertTo-Json -InputObject @($records) -Depth 4 | Set-Content -LiteralPath (Join-Path $backup 'restore.json') -Encoding UTF8
  New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
  Copy-Item -LiteralPath (Get-PayloadSource $f.path) -Destination $target -Force
  if ((Get-FileHash -LiteralPath $target).Hash.ToLower() -ne $f.sha256) { throw "Copy check failed: $($f.path)" }
 }
 Write-Host "Installed. Backup: $backup"
 Write-Host 'Kurulum tamamlandi! Turkce icin launcher dilini English secin.'
} catch {
 foreach ($r in $records) {
  $target = Join-Path $root $r.path
  if ($r.existed) { Copy-Item -LiteralPath (Join-Path $backup $r.path) -Destination $target -Force }
  elseif (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target }
 }
 throw
}

} finally {
 $tempFile = Join-Path $tempDir "data3.big"
 if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile }
 Remove-Item -LiteralPath $tempDir
}
