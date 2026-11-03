<#
.SYNOPSIS
    Installs the grill-myself skill for one or more AI tools (Windows / PowerShell 5.1+ or 7).

.DESCRIPTION
    Pipeline: resolve source folder -> resolve target skill roots -> verification report -> Copy-Item.
    Every target is just "<root>\grill-myself\SKILL.md", so the manual equivalent is
    Copy-Item -Recurse plugins\grill\skills\grill-myself <root>\  (see about_Copy-Item).

    -Target Agents  -> .agents\skills  (Codex, GitHub Copilot, Cursor, Gemini CLI, ...)
    -Target Claude  -> .claude\skills  (Claude Code)
    Default is both.

.EXAMPLE
    .\scripts\Install-Skill.ps1 -Scope Personal -WhatIf
    .\scripts\Install-Skill.ps1 -Scope Personal
    .\scripts\Install-Skill.ps1 -Scope Project -ProjectPath C:\repos\my-project -Target Agents
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Personal', 'Project')]
    [string]$Scope = 'Personal',

    [string]$ProjectPath,

    [ValidateSet('Agents', 'Claude')]
    [string[]]$Target = @('Agents', 'Claude')
)

$ErrorActionPreference = 'Stop'

$source = (Resolve-Path (Join-Path $PSScriptRoot '..\plugins\grill\skills\grill-myself')).Path
if (-not (Test-Path (Join-Path $source 'SKILL.md'))) {
    throw "SKILL.md not found at $source"
}

if ($Scope -eq 'Project') {
    if (-not $ProjectPath) { throw '-Scope Project needs -ProjectPath' }
    if (-not (Test-Path $ProjectPath -PathType Container)) { throw "Project path not found: $ProjectPath" }
    $base = (Resolve-Path $ProjectPath).Path
}
else {
    $base = $HOME
}

$folderFor = @{ Agents = '.agents\skills'; Claude = '.claude\skills' }
$roots = $Target | ForEach-Object { Join-Path $base $folderFor[$_] }

# --- DRY-RUN / VERIFICATION: read-only report of what will be created or replaced ---
Write-Host "Source: $source"
foreach ($root in $roots) {
    $dest = Join-Path $root 'grill-myself'
    $action = if (Test-Path $dest) { 'REPLACE' } else { 'CREATE ' }
    Write-Host "  $action $dest"
}

# --- Copy: ShouldProcess makes -WhatIf / -Confirm work for every destructive step ---
foreach ($root in $roots) {
    $dest = Join-Path $root 'grill-myself'
    if ($PSCmdlet.ShouldProcess($dest, 'Install grill-myself skill')) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        Copy-Item -Path $source -Destination $root -Recurse
        Write-Host "Installed: $dest"
    }
}
