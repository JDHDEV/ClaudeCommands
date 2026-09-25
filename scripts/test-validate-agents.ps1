#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Meta-test for validate-agents.ps1 — proves each validation rule actually fires.

.DESCRIPTION
  validate-agents.ps1 is the test suite for the agent library, so it needs its own
  coverage. This script builds known-good and known-bad fixture pairs in a temp
  directory and asserts that the validator:
    - passes (exit 0) on a clean pair, and
    - fails (exit non-zero) with the expected message for each rule: parse error,
      missing key, name/filename mismatch, invalid model, read-only tool violation,
      missing Subagent Contract, sync drift, orphaned install file, and
      exact-tool-set violation (extra or missing tool).

  Exits 0 only if every assertion holds.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$validator = Join-Path $scriptDir 'validate-agents.ps1'

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'validate-agents-selftest'
if (Test-Path -LiteralPath $tmpRoot) { Remove-Item -LiteralPath $tmpRoot -Recurse -Force }
New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null

# Write fixtures as UTF-8 WITHOUT a BOM so they parse exactly like the real agent
# files (Set-Content -Encoding UTF8 on PS 5.1 prepends a BOM, which would corrupt the
# opening --- fence and make fixtures unrepresentative).
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-FixtureFile {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$results = New-Object System.Collections.Generic.List[psobject]

function New-AgentContent {
    param(
        [string]$Name,
        [string]$Model = 'sonnet',
        [string[]]$Tools = @('Read', 'Grep'),
        [bool]$WithContract = $true,
        [bool]$WithDescription = $true,
        [bool]$WithFrontmatter = $true
    )
    if (-not $WithFrontmatter) {
        return "No frontmatter here.`n`n## Subagent Contract`n- fire-and-forget."
    }
    $lines = @('---', "name: $Name")
    if ($WithDescription) { $lines += 'description: "Test agent."' }
    $lines += 'tools:'
    $lines += ($Tools | ForEach-Object { "  - $_" })
    $lines += @("model: $Model", '---', '', 'You are a test agent.')
    if ($WithContract) { $lines += @('', '## Subagent Contract', '- Mode: fire-and-forget.') }
    return ($lines -join "`n")
}

function New-FixturePair {
    param(
        [string]$TestName,
        [string]$FileName,
        [string]$CanonicalContent,
        [string]$InstallContent,   # $null = do not create the install file
        [bool]$CreateInstall = $true
    )
    $base = Join-Path $tmpRoot $TestName
    $canon = Join-Path $base 'agents'
    $install = Join-Path $base 'install'
    New-Item -ItemType Directory -Path $canon -Force | Out-Null
    New-Item -ItemType Directory -Path $install -Force | Out-Null
    Write-FixtureFile -Path (Join-Path $canon $FileName) -Content $CanonicalContent
    if ($CreateInstall) {
        # An unbound [string] parameter is "" (not $null) in PowerShell, so detect an
        # explicit override via PSBoundParameters; otherwise mirror the canonical content.
        $ic = if ($PSBoundParameters.ContainsKey('InstallContent')) { $InstallContent } else { $CanonicalContent }
        Write-FixtureFile -Path (Join-Path $install $FileName) -Content $ic
    }
    return @{ Canon = $canon; Install = $install }
}

function Invoke-Validator {
    param([string]$Canon, [string]$Install)
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validator -CanonicalDir $Canon -InstallDir $Install 2>&1 | Out-String
    return @{ Code = $LASTEXITCODE; Out = $out }
}

function Assert-Case {
    param(
        [string]$TestName,
        [int]$ExpectedCode,          # 0 = pass expected, 1 = fail expected
        [string]$ExpectedSubstring,  # required substring in output ('' = none)
        [hashtable]$Dirs
    )
    $r = Invoke-Validator -Canon $Dirs.Canon -Install $Dirs.Install
    $codeOk = ($ExpectedCode -eq 0 -and $r.Code -eq 0) -or ($ExpectedCode -ne 0 -and $r.Code -ne 0)
    $msgOk = [string]::IsNullOrEmpty($ExpectedSubstring) -or ($r.Out -like "*$ExpectedSubstring*")
    $pass = $codeOk -and $msgOk
    $results.Add([pscustomobject]@{
        Test     = $TestName
        Pass     = $pass
        Code     = $r.Code
        Expected = "code$(if($ExpectedCode -eq 0){'=0'}else{'!=0'})$(if($ExpectedSubstring){" & '$ExpectedSubstring'"})"
    })
    if (-not $pass) {
        Write-Host "  [detail] $TestName output:" -ForegroundColor Yellow
        Write-Host ($r.Out.Trim())
    }
}

# --- T1: happy path (clean pair) passes ---
$d = New-FixturePair -TestName 't1-good' -FileName 'code-reviewer.md' `
    -CanonicalContent (New-AgentContent -Name 'code-reviewer')
Assert-Case -TestName 'happy-path passes' -ExpectedCode 0 -ExpectedSubstring 'PASS' -Dirs $d

# --- T2: missing required key (no description) ---
$d = New-FixturePair -TestName 't2-missing-key' -FileName 'devops-engineer.md' `
    -CanonicalContent (New-AgentContent -Name 'devops-engineer' -WithDescription $false)
Assert-Case -TestName 'missing key (description) fires' -ExpectedCode 1 -ExpectedSubstring 'missing required frontmatter key: description' -Dirs $d

# --- T3: name / filename mismatch ---
$d = New-FixturePair -TestName 't3-name-mismatch' -FileName 'architect.md' `
    -CanonicalContent (New-AgentContent -Name 'not-architect')
Assert-Case -TestName 'name/filename mismatch fires' -ExpectedCode 1 -ExpectedSubstring 'does not match filename stem' -Dirs $d

# --- T4: invalid model ---
$d = New-FixturePair -TestName 't4-bad-model' -FileName 'api-designer.md' `
    -CanonicalContent (New-AgentContent -Name 'api-designer' -Model 'gpt-4')
Assert-Case -TestName 'invalid model fires' -ExpectedCode 1 -ExpectedSubstring "invalid model 'gpt-4'" -Dirs $d

# --- T5: read-only agent granted Edit ---
$d = New-FixturePair -TestName 't5-readonly-edit' -FileName 'security-auditor.md' `
    -CanonicalContent (New-AgentContent -Name 'security-auditor' -Tools @('Read', 'Grep', 'Edit'))
Assert-Case -TestName 'read-only tool violation fires' -ExpectedCode 1 -ExpectedSubstring "read-only agent must not grant tool 'Edit'" -Dirs $d

# --- T6: missing Subagent Contract ---
$d = New-FixturePair -TestName 't6-no-contract' -FileName 'test-writer.md' `
    -CanonicalContent (New-AgentContent -Name 'test-writer' -WithContract $false)
Assert-Case -TestName 'missing Subagent Contract fires' -ExpectedCode 1 -ExpectedSubstring "missing '## Subagent Contract' section" -Dirs $d

# --- T7: sync drift (install content differs) ---
$d = New-FixturePair -TestName 't7-drift' -FileName 'tech-lead.md' `
    -CanonicalContent (New-AgentContent -Name 'tech-lead') `
    -InstallContent (New-AgentContent -Name 'tech-lead' -Model 'opus')
Assert-Case -TestName 'sync drift fires' -ExpectedCode 1 -ExpectedSubstring 'out of sync' -Dirs $d

# --- T8: missing counterpart in install ---
$d = New-FixturePair -TestName 't8-missing-counterpart' -FileName 'frontend-specialist.md' `
    -CanonicalContent (New-AgentContent -Name 'frontend-specialist') -CreateInstall $false
Assert-Case -TestName 'missing counterpart fires' -ExpectedCode 1 -ExpectedSubstring 'no counterpart' -Dirs $d

# --- T9: unparseable frontmatter ---
$d = New-FixturePair -TestName 't9-parse-error' -FileName 'debugger.md' `
    -CanonicalContent (New-AgentContent -Name 'debugger' -WithFrontmatter $false)
Assert-Case -TestName 'frontmatter parse error fires' -ExpectedCode 1 -ExpectedSubstring 'frontmatter parse error' -Dirs $d

# --- T10: exact tool set - extra tool fires ---
$d = New-FixturePair -TestName 't10-exact-tools-extra' -FileName 'taskmaster.md' `
    -CanonicalContent (New-AgentContent -Name 'taskmaster' -Tools @('Read', 'Grep', 'Glob', 'Bash'))
Assert-Case -TestName 'exact tool set: extra tool fires' -ExpectedCode 1 -ExpectedSubstring 'tool set must be exactly' -Dirs $d

# --- T11: exact tool set - exact set passes ---
$d = New-FixturePair -TestName 't11-exact-tools-ok' -FileName 'taskmaster.md' `
    -CanonicalContent (New-AgentContent -Name 'taskmaster' -Tools @('Read', 'Grep', 'Glob'))
Assert-Case -TestName 'exact tool set: exact set passes' -ExpectedCode 0 -ExpectedSubstring 'PASS' -Dirs $d

# --- T12: exact tool set - missing tool fires ---
$d = New-FixturePair -TestName 't12-exact-tools-missing' -FileName 'taskmaster.md' `
    -CanonicalContent (New-AgentContent -Name 'taskmaster' -Tools @('Read', 'Grep'))
Assert-Case -TestName 'exact tool set: missing tool fires' -ExpectedCode 1 -ExpectedSubstring 'tool set must be exactly' -Dirs $d

# --- Report ---
Write-Host ""
$failed = @($results | Where-Object { -not $_.Pass })
foreach ($r in $results) {
    $tag = if ($r.Pass) { 'PASS' } else { 'FAIL' }
    $color = if ($r.Pass) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} (validator exit {2}; expected {3})" -f $tag, $r.Test, $r.Code, $r.Expected) -ForegroundColor $color
}
Write-Host ""

# Clean up fixtures.
if (Test-Path -LiteralPath $tmpRoot) { Remove-Item -LiteralPath $tmpRoot -Recurse -Force }

if ($failed.Count -eq 0) {
    Write-Host "META-TEST PASS: all $($results.Count) validator rules fire as expected." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "META-TEST FAIL: $($failed.Count) of $($results.Count) assertions failed." -ForegroundColor Red
    exit 1
}
