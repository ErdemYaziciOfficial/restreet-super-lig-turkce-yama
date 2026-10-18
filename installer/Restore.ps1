param([Parameter(Mandatory=$true)][string]$GameRoot,[Parameter(Mandatory=$true)][string]$BackupFolder)
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $GameRoot).Path
$backup=(Resolve-Path -LiteralPath $BackupFolder).Path
if (!$backup.StartsWith((Join-Path $root 'SuperLigBackup')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Backup must belong to this installation.' }
if (Get-Process fifastreet,FifaStreetLauncher -ErrorAction SilentlyContinue) { throw 'Close game and launcher first.' }
$records=@(Get-Content -LiteralPath (Join-Path $backup 'restore.json') -Raw | ConvertFrom-Json)
foreach($r in $records) {
 $target=[IO.Path]::GetFullPath((Join-Path $root $r.path))
 $saved=[IO.Path]::GetFullPath((Join-Path $backup $r.path))
 if (!$target.StartsWith($root.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase) -or !$saved.StartsWith($backup.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid restore path.' }
 if ($r.existed -and !(Test-Path -LiteralPath $saved)) { throw "Missing backup: $($r.path)" }
}
foreach($r in $records) {
 $target=Join-Path $root $r.path
 if ($r.existed) { Copy-Item -LiteralPath (Join-Path $backup $r.path) -Destination $target -Force }
 elseif(Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target }
}
Write-Host 'Restored previous files.'
