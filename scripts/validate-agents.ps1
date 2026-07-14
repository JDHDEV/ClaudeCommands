#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Structural validator for Claude Code agent definition files.

.DESCRIPTION
  This is the "unit test" for a markdown-config repository. It checks every
  agents/*.md and .claude/agents/*.md for:
    (a) frontmatter that parses between --- fences
    (b) required keys: name, description, tools, model
    (c) name equals the filename stem
    (d) model in {haiku, sonnet, opus, fable, inherit}
    (e) read-only agents carry no Write/Edit tool
    (f) every agents/*.md has an identical counterpart in .claude/agents/
    (g) the body contains a "## Subagent Contract" heading

  Exits non-zero and prints a per-file, per-rule failure list on any violation.

.PARAMETER CanonicalDir
  The canonical agent library directory. Defaults to <repo>/agents. Overridable so
  the ruleset can be exercised against known-bad fixtures (see test-validate-agents.ps1).

.PARAMETER InstallDir
  The live-install agent directory. Defaults to <repo>/.claude/agents.

.EXAMPLE
  powershell -File scripts/validate-agents.ps1
#>

[CmdletBinding()]
param(
    [string]$CanonicalDir,
    [string]$InstallDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve the repo root as the parent of this script's directory so the defaults
# work regardless of the caller's current working directory.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir

if (-not $CanonicalDir) { $CanonicalDir = Join-Path $repoRoot 'agents' }
if (-not $InstallDir)   { $InstallDir   = Join-Path $repoRoot '.claude/agents' }

$ValidModels    = @('haiku', 'sonnet', 'opus', 'fable', 'inherit')
$ReadOnlyAgents = @('code-reviewer', 'security-auditor', 'tech-lead', 'architect', 'adversarial-verifier', 'workflow-author')

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$File, [string]$Message)
    $rel = $File
    if ($File.StartsWith($repoRoot)) {
        $rel = $File.Substring($repoRoot.Length).TrimStart('\', '/')
    }
    $script:failures.Add("$rel : $Message")
}

function Get-Frontmatter {
    param([string]$Path)

    $raw = Get-Content -LiteralPath $Path -Raw
    if ($null -eq $raw) { $raw = '' }
    $normalized = $raw -replace "`r`n", "`n"
    $lines = $normalized -split "`n"

    if ($lines.Count -lt 1 -or $lines[0].Trim() -ne '---') {
        return @{ ParseError = 'missing opening --- fence'; Keys = @{}; Tools = @(); Body = '' }
    }

    $closeIdx = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $closeIdx = $i; break }
    }
    if ($closeIdx -lt 0) {
        return @{ ParseError = 'missing closing --- fence'; Keys = @{}; Tools = @(); Body = '' }
    }

    $fmLines = @()
    if ($closeIdx -gt 1) { $fmLines = $lines[1..($closeIdx - 1)] }
    $body = ''
    if ($closeIdx + 1 -le $lines.Count - 1) {
        $body = ($lines[($closeIdx + 1)..($lines.Count - 1)] -join "`n")
    }

    $keys  = @{}
    $tools = New-Object System.Collections.Generic.List[string]
    $currentKey = $null

    foreach ($line in $fmLines) {
        if ($line -match '^([A-Za-z0-9_-]+):\s*(.*)$') {
            $currentKey = $Matches[1]
            $val = $Matches[2].Trim()
            $keys[$currentKey] = $val
            if ($currentKey -eq 'tools' -and $val -ne '') {
                # Inline form: tools: Read, Grep  OR  tools: [Read, Grep]
                $inline = $val.Trim('[', ']')
                foreach ($t in ($inline -split ',')) {
                    $t = $t.Trim().Trim('"', "'")
                    if ($t -ne '') { $tools.Add($t) }
                }
            }
        }
        elseif ($line -match '^\s*-\s+(.*)$') {
            if ($currentKey -eq 'tools') {
                $t = $Matches[1].Trim().Trim('"', "'")
                if ($t -ne '') { $tools.Add($t) }
            }
        }
    }

    return @{ ParseError = $null; Keys = $keys; Tools = $tools.ToArray(); Body = $body }
}

function Test-AgentFile {
    param([string]$Path)

    $stem = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $fm = Get-Frontmatter -Path $Path

    if ($fm.ParseError) {
        Add-Failure $Path "frontmatter parse error: $($fm.ParseError)"
        return
    }

    $keys = $fm.Keys

    # (b) required scalar keys must be present and non-empty
    foreach ($req in @('name', 'description', 'model')) {
        if (-not $keys.ContainsKey($req) -or [string]::IsNullOrWhiteSpace($keys[$req])) {
            Add-Failure $Path "missing required frontmatter key: $req"
        }
    }
    # (b) tools may be a block list (empty inline value) — check presence then non-empty
    if (-not $keys.ContainsKey('tools')) {
        Add-Failure $Path "missing required frontmatter key: tools"
    }
    elseif ($fm.Tools.Count -eq 0) {
        Add-Failure $Path "tools list is empty or could not be parsed"
    }

    # (c) name matches filename stem
    if ($keys.ContainsKey('name') -and $keys['name'] -ne $stem) {
        Add-Failure $Path "name '$($keys['name'])' does not match filename stem '$stem'"
    }

    # (d) model whitelist
    if ($keys.ContainsKey('model') -and -not [string]::IsNullOrWhiteSpace($keys['model'])) {
        if ($ValidModels -notcontains $keys['model']) {
            Add-Failure $Path "invalid model '$($keys['model'])' (allowed: $($ValidModels -join ', '))"
        }
    }

    # (e) read-only agents must not carry Write/Edit
    if ($ReadOnlyAgents -contains $stem) {
        foreach ($t in $fm.Tools) {
            if ($t -eq 'Write' -or $t -eq 'Edit') {
                Add-Failure $Path "read-only agent must not grant tool '$t'"
            }
        }
    }

    # (g) Subagent Contract section present
    if ($fm.Body -notmatch '(?m)^##\s+Subagent Contract\s*$') {
        Add-Failure $Path "missing '## Subagent Contract' section"
    }
}

function Get-NormalizedContent {
    param([string]$Path)
    $raw = Get-Content -LiteralPath $Path -Raw
    if ($null -eq $raw) { $raw = '' }
    return ($raw -replace "`r`n", "`n")
}

# --- Structural checks over both directories ---
$canonicalFiles = @()
if (Test-Path -LiteralPath $CanonicalDir) {
    $canonicalFiles = @(Get-ChildItem -LiteralPath $CanonicalDir -Filter '*.md' -File)
}
else {
    Add-Failure $CanonicalDir "canonical agents directory not found"
}

$installFiles = @()
if (Test-Path -LiteralPath $InstallDir) {
    $installFiles = @(Get-ChildItem -LiteralPath $InstallDir -Filter '*.md' -File)
}
else {
    Add-Failure $InstallDir ".claude/agents install directory not found"
}

foreach ($f in $canonicalFiles) { Test-AgentFile -Path $f.FullName }
foreach ($f in $installFiles)  { Test-AgentFile -Path $f.FullName }

# --- (f) Sync check: every agents/*.md has an identical counterpart in .claude/agents/ ---
foreach ($f in $canonicalFiles) {
    $counterpart = Join-Path $InstallDir $f.Name
    if (-not (Test-Path -LiteralPath $counterpart)) {
        Add-Failure $f.FullName "no counterpart in .claude/agents/ (install is out of sync)"
        continue
    }
    $a = Get-NormalizedContent -Path $f.FullName
    $b = Get-NormalizedContent -Path $counterpart
    if ($a -ne $b) {
        Add-Failure $f.FullName "content differs from .claude/agents/$($f.Name) (install is out of sync)"
    }
}

# Flag install-only files (drift in the other direction).
foreach ($f in $installFiles) {
    $counterpart = Join-Path $CanonicalDir $f.Name
    if (-not (Test-Path -LiteralPath $counterpart)) {
        Add-Failure $f.FullName "exists in .claude/agents/ but not in agents/ (orphaned install file)"
    }
}

# --- Report ---
$totalChecked = $canonicalFiles.Count + $installFiles.Count
if ($failures.Count -eq 0) {
    Write-Host "PASS: validated $totalChecked agent file(s) across agents/ and .claude/agents/ with 0 findings." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "FAIL: $($failures.Count) finding(s) across $totalChecked agent file(s):" -ForegroundColor Red
    foreach ($fail in $failures) {
        Write-Host "  - $fail" -ForegroundColor Red
    }
    exit 1
}
