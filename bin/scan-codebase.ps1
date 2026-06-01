# Scan a git repository -> TSV manifest: path, token estimate (bytes/4), content
# hash (git hash-object), top-level module. .gitignore respected via git ls-files.
# Usage: scan-codebase.ps1 [-Scope <sub-path>] [-OutFile <path>]   (default scope: whole repo)
#   With -OutFile, writes the manifest there as UTF-8/no-BOM/LF. Without it, prints to stdout.
# Requires a git repository. No Python/uv. Emits LF line endings.
param([string]$Scope = '.', [string]$OutFile = '')

$ErrorActionPreference = 'Stop'

# Decode git's stdout as UTF-8 so non-ASCII filenames survive (Windows console
# defaults to an OEM codepage and would mangle them, mismatching the .sh output).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ($Scope -match '\.\.') { [Console]::Error.WriteLine("ERROR: scope must not contain '..': $Scope"); exit 2 }
if ($Scope.StartsWith('/')) { [Console]::Error.WriteLine("ERROR: scope must not be absolute: $Scope"); exit 2 }

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { [Console]::Error.WriteLine("ERROR: not a git repository -- scanner requires git ls-files"); exit 3 }

$sha = (git rev-parse --short HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $sha) { $sha = 'unknown' }

$prefix = ''
if ($Scope -ne '.') { $prefix = ($Scope.TrimEnd('/')) + '/' }

# Exclude docs/codebase/ — map-codebase's own generated output (the 8 docs + this
# manifest). Scanning it would make the map look changed on every regen and break the
# incremental no-op short-circuit.
$paths = (& git -c core.quotePath=false ls-files -- $Scope ':(exclude)docs/codebase/') | Where-Object { $_ -ne '' }

$lines = New-Object System.Collections.Generic.List[string]
foreach ($f in $paths) {
    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
    $bytes = (Get-Item -LiteralPath $f).Length
    $tokens = [int64][math]::Floor($bytes / 4)
    $hash = (git hash-object $f)
    $rel = $f
    if ($prefix -and $f.StartsWith($prefix)) { $rel = $f.Substring($prefix.Length) }
    if ($rel.Contains('/')) { $module = $rel.Substring(0, $rel.IndexOf('/')) } else { $module = '(root)' }
    $lines.Add(("{0}`t{1}`t{2}`t{3}" -f $f, $tokens, $hash, $module))
}

$arr = $lines.ToArray()
[System.Array]::Sort($arr, [System.StringComparer]::Ordinal)

$totalFiles = $arr.Count
$totalTokens = [int64]0
foreach ($l in $arr) { $totalTokens += [int64]($l -split "`t")[1] }

$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("# scan_version: 1`n")
[void]$sb.Append("# source_sha: $sha`n")
[void]$sb.Append("# scan_scope: $Scope`n")
[void]$sb.Append("# total_files: $totalFiles`n")
[void]$sb.Append("# total_tokens: $totalTokens`n")
[void]$sb.Append("path`ttokens`thash`tmodule`n")
foreach ($l in $arr) { [void]$sb.Append($l + "`n") }
$text = $sb.ToString()

if ($OutFile) {
    if (-not [System.IO.Path]::IsPathRooted($OutFile)) { $OutFile = Join-Path (Get-Location).Path $OutFile }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutFile, $text, $utf8NoBom)
} else {
    [Console]::Out.Write($text)
}
