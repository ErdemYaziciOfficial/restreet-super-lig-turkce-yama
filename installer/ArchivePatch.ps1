function Prepare-Archive([string]$Root, [string]$Package, [string]$TempDir) {
 $m = Get-Content -LiteralPath (Join-Path $Package 'data3-patch.json') -Raw | ConvertFrom-Json
 $current = Join-Path $Root 'Game/data3.big'
 $hash = (Get-FileHash -LiteralPath $current).Hash.ToLower()
 if ($hash -eq $m.targetSha256) { return $current }
 if ($hash -ne $m.baseSha256) { throw 'data3.big farkli bir surume veya baska bir moda ait. Orijinal oyun verisini geri yukleyin; kayitlarinizi silmeyin.' }
 $delta = Join-Path $Package 'data3.delta'
 if ((Get-FileHash -LiteralPath $delta).Hash.ToLower() -ne $m.deltaSha256) { throw 'Duzeltme dosyasi bozuk. ZIP dosyasini yeniden indirin.' }
 $staged = Join-Path $TempDir 'data3.big'
 Copy-Item -LiteralPath $current -Destination $staged
 $bytes = [IO.File]::ReadAllBytes($delta)
 $stream = [IO.File]::Open($staged,[IO.FileMode]::Open,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try {
  foreach($b in $m.blocks) {
   if ($b.offset -lt 0 -or $b.deltaOffset -lt 0 -or $b.length -le 0 -or ($b.deltaOffset+$b.length) -gt $bytes.Length -or ($b.offset+$b.length) -gt $m.targetSize) { throw 'Invalid patch range' }
   $stream.Position = [long]$b.offset
   $stream.Write($bytes,[int]$b.deltaOffset,[int]$b.length)
  }
  $stream.SetLength([long]$m.targetSize)
 } finally { $stream.Dispose() }
 if ((Get-FileHash -LiteralPath $staged).Hash.ToLower() -ne $m.targetSha256) { throw 'Forma arsivi dogrulanamadi. Oyun dosyalari degistirilmedi.' }
 return $staged
}
