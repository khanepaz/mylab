# Scans the "records" folder next to this script and writes records.js
# Compatible with PowerShell 2.0 (Windows 7 and later)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$rec  = Join-Path $root "records"
if (-not (Test-Path -LiteralPath $rec)) {
  Write-Host "Folder 'records' was not found next to this script."
  exit 1
}
$script:count = 0

function Esc([string]$s) {
  $s = $s.Replace('\', '\\').Replace('"', '\"')
  return '"' + $s + '"'
}

function Walk([string]$dir) {
  $parts = @()
  $entries = @(Get-ChildItem -LiteralPath $dir | Sort-Object Name)
  foreach ($d in @($entries | Where-Object { $_.PSIsContainer })) {
    $parts += ('{"n":' + (Esc $d.Name) + ',"c":' + (Walk $d.FullName) + '}')
  }
  foreach ($f in @($entries | Where-Object { -not $_.PSIsContainer })) {
    if ($f.Name -eq 'Thumbs.db' -or $f.Name -eq 'desktop.ini' -or $f.Name.StartsWith('~$')) { continue }
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    $parts += ('{"n":' + (Esc $f.Name) + ',"p":' + (Esc $rel) + '}')
    $script:count++
  }
  return ('[' + ($parts -join ',') + ']')
}

$json = Walk $rec
$pc = New-Object System.Globalization.PersianCalendar
$now = Get-Date
$stamp = "{0}/{1:00}/{2:00}" -f $pc.GetYear($now), $pc.GetMonth($now), $pc.GetDayOfMonth($now)
$text = "window.RECORDS = " + $json + ";`r`nwindow.RECORDS_UPDATED = `"" + $stamp + "`";`r`n"
[System.IO.File]::WriteAllText((Join-Path $root "records.js"), $text, (New-Object System.Text.UTF8Encoding($false)))
if ($script:count -eq 0) {
  Write-Host "Warning: no files were found inside the 'records' folder."
} else {
  Write-Host ("Done. " + $script:count + " files listed in records.js")
}
