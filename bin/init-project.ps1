# Bootstrap a project with spec-kit convention by copying assets/specify -> ./.specify
# Usage: init-project.ps1 [-TargetDir <path>] [-Force]
param(
    [string]$TargetDir = (Get-Location).Path,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$pluginRoot = if ($env:CLAUDE_PLUGIN_ROOT) { $env:CLAUDE_PLUGIN_ROOT } else { Split-Path -Parent $PSScriptRoot }
$sourceDir = Join-Path $pluginRoot 'assets/specify'
$targetSpecify = Join-Path $TargetDir '.specify'

if (-not (Test-Path $sourceDir)) {
    Write-Error "Source payload not found at $sourceDir"
    exit 1
}

if ((Test-Path $targetSpecify) -and -not $Force) {
    Write-Output "INFO: $targetSpecify already exists - leaving it untouched. Use -Force to overwrite."
    exit 0
}

New-Item -ItemType Directory -Path $targetSpecify -Force | Out-Null
Copy-Item -Path (Join-Path $sourceDir '*') -Destination $targetSpecify -Recurse -Force
Write-Output "OK: bootstrapped .specify at $targetSpecify (from $sourceDir)"
