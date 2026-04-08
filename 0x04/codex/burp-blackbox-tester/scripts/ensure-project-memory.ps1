param(
    [string]$MemoryFile = "memory.md",
    [string]$StartPath = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
    param([string]$Path)

    $current = (Resolve-Path -LiteralPath $Path).Path

    while ($true) {
        if (
            (Test-Path (Join-Path $current ".git")) -or
            (Test-Path (Join-Path $current "package.json")) -or
            (Test-Path (Join-Path $current "pyproject.toml")) -or
            (Test-Path (Join-Path $current "go.mod")) -or
            (Test-Path (Join-Path $current "Cargo.toml")) -or
            (Test-Path (Join-Path $current "pom.xml"))
        ) {
            return $current
        }

        $parent = Split-Path -Path $current -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) {
            return (Resolve-Path -LiteralPath $StartPath).Path
        }
        $current = $parent
    }
}

if (-not $MemoryFile.EndsWith(".md")) {
    throw "MemoryFile must end with .md"
}

if (-not (Test-Path -LiteralPath $StartPath)) {
    $StartPath = (Get-Location).Path
}

$projectRoot = Get-ProjectRoot -Path $StartPath
$githubDir = Join-Path $projectRoot ".github"
$templatePath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\references\memory-template.md"))
$memoryPath = Join-Path $githubDir $MemoryFile

if (-not (Test-Path $templatePath)) {
    throw "Template not found: $templatePath"
}

if (-not (Test-Path $githubDir)) {
    New-Item -Path $githubDir -ItemType Directory -Force | Out-Null
    Write-Output "CREATED_DIR=$githubDir"
}

if (Test-Path $memoryPath) {
    Write-Output "MEMORY_EXISTS=$memoryPath"
    exit 0
}

Copy-Item -Path $templatePath -Destination $memoryPath -Force
Write-Output "MEMORY_CREATED=$memoryPath"
