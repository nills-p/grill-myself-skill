<#
.SYNOPSIS
    Builds dist\grill-myself.zip for upload in claude.ai (or any app that accepts a skill ZIP).

.DESCRIPTION
    The ZIP must contain the FOLDER grill-myself\ with SKILL.md inside, not just the file.
    Compress-Archive keeps the folder when -Path points at the folder itself (not folder\*).

.EXAMPLE
    .\scripts\New-SkillPackage.ps1 -WhatIf
    .\scripts\New-SkillPackage.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\dist\grill-myself.zip')
)

$ErrorActionPreference = 'Stop'

$source = (Resolve-Path (Join-Path $PSScriptRoot '..\plugins\grill\skills\grill-myself')).Path
if (-not (Test-Path (Join-Path $source 'SKILL.md'))) { throw "SKILL.md not found at $source" }

# --- DRY-RUN / VERIFICATION ---
Write-Host "Source: $source"
Write-Host "Output: $OutputPath$(if (Test-Path $OutputPath) { ' (will be replaced)' })"

if ($PSCmdlet.ShouldProcess($OutputPath, 'Create skill ZIP')) {
    New-Item -ItemType Directory -Path (Split-Path $OutputPath) -Force | Out-Null
    Compress-Archive -Path $source -DestinationPath $OutputPath -Force
    Write-Host "Built: $OutputPath"
}
