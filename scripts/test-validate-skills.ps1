#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Meta-test for validate-skills.ps1 — proves each validation rule actually fires.

.DESCRIPTION
  validate-skills.ps1 is the test suite for the skill library, so it needs its own
  coverage. This script builds a known-good fixture (a copy of the real skills/,
  .claude/skills/, and agents/ trees) in the temp directory, then derives one
  known-bad fixture per rule by mutating a single thing, and asserts that the
  validator:
    - passes (exit 0) on the clean copy, and
    - fails (exit non-zero) with the expected message for each rule: missing
      frontmatter fence, name/dirname mismatch, missing disable-model-invocation,
      phantom subagent_type, named-agent enforcement regression in an _sa skill,
      drifted mirror (byte mismatch), orphaned skill directory, a stale shadow
      command file, a missing Argument Safety guardrail sentence, a missing
      $ARGUMENTS reference, a too-short description, a missing "Execution Prompt"
      heading, a broken fenced-template section sequence, and a phantom agent
      reference in a domain-routing table row (roster/table phantom coverage).

  Exits 0 only if every assertion holds.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$validator    = Join-Path $scriptDir 'validate-skills.ps1'
$repoRootReal = Split-Path -Parent $scriptDir

$realSkillsDir        = Join-Path $repoRootReal 'skills'
$realInstallSkillsDir = Join-Path $repoRootReal '.claude/skills'
$realAgentsDir        = Join-Path $repoRootReal 'agents'

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'validate-skills-selftest'
if (Test-Path -LiteralPath $tmpRoot) { Remove-Item -LiteralPath $tmpRoot -Recurse -Force }
New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null

# Write mutated fixture files as UTF-8 WITHOUT a BOM so they parse exactly like the
# real skill files (Set-Content -Encoding UTF8 on PS 5.1 prepends a BOM, which would
# corrupt the opening --- fence and make fixtures unrepresentative).
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Get-FixtureText {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path)
}
function Set-FixtureText {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# --- Build the master (known-good) fixture once; every case is a fresh copy of it ---
$masterRoot = Join-Path $tmpRoot 'master'
New-Item -ItemType Directory -Path $masterRoot -Force | Out-Null
Copy-Item -LiteralPath $realSkillsDir -Destination (Join-Path $masterRoot 'skills') -Recurse
New-Item -ItemType Directory -Path (Join-Path $masterRoot '.claude') -Force | Out-Null
Copy-Item -LiteralPath $realInstallSkillsDir -Destination (Join-Path $masterRoot '.claude/skills') -Recurse
Copy-Item -LiteralPath $realAgentsDir -Destination (Join-Path $masterRoot 'agents') -Recurse

function New-CaseFixture {
    param([string]$CaseName)
    $caseRoot = Join-Path $tmpRoot $CaseName
    if (Test-Path -LiteralPath $caseRoot) { Remove-Item -LiteralPath $caseRoot -Recurse -Force }
    Copy-Item -LiteralPath $masterRoot -Destination $caseRoot -Recurse
    return $caseRoot
}

function Invoke-Validator {
    param([string]$RepoRoot)
    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validator -RepoRoot $RepoRoot 2>&1 | Out-String
    return @{ Code = $LASTEXITCODE; Out = $out }
}

$results = New-Object System.Collections.Generic.List[psobject]

function Assert-Case {
    param(
        [string]$TestName,
        [int]$ExpectedCode,          # 0 = pass expected, 1 = fail expected
        [string]$ExpectedSubstring,  # required substring in output ('' = none)
        [string]$RepoRoot
    )
    $r = Invoke-Validator -RepoRoot $RepoRoot
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

function Edit-BothTrees {
    # Applies the same text transform to a skill's SKILL.md in both the canonical and
    # install trees of a case fixture, so the mutation doesn't itself trip the
    # byte-parity check (kept isolated to the rule under test).
    param([string]$CaseRoot, [string]$SkillName, [scriptblock]$Transform)
    foreach ($rel in @("skills/$SkillName/SKILL.md", ".claude/skills/$SkillName/SKILL.md")) {
        $path = Join-Path $CaseRoot $rel
        $text = Get-FixtureText -Path $path
        $newText = & $Transform $text
        Set-FixtureText -Path $path -Content $newText
    }
}

# --- T0: happy path (clean fixture copy) passes ---
$d = New-CaseFixture -CaseName 't0-good'
Assert-Case -TestName 'happy-path (clean copy) passes' -ExpectedCode 0 -ExpectedSubstring 'PASS' -RepoRoot $d

# --- T1: missing frontmatter fence ---
$d = New-CaseFixture -CaseName 't1-missing-fence'
Edit-BothTrees -CaseRoot $d -SkillName 'commit' -Transform {
    param($text)
    $normalized = $text -replace "`r`n", "`n"
    $lines = $normalized -split "`n"
    if ($lines[0].Trim() -eq '---') { return ($lines[1..($lines.Count - 1)] -join "`n") }
    return $text
}
Assert-Case -TestName 'missing frontmatter fence fires' -ExpectedCode 1 -ExpectedSubstring 'frontmatter parse error' -RepoRoot $d

# --- T2: name / directory-name mismatch ---
$d = New-CaseFixture -CaseName 't2-name-mismatch'
Edit-BothTrees -CaseRoot $d -SkillName 'plan' -Transform {
    param($text)
    return ($text -replace '(?m)^name: plan$', 'name: not-plan')
}
Assert-Case -TestName 'name/dirname mismatch fires' -ExpectedCode 1 -ExpectedSubstring "does not match directory name 'plan'" -RepoRoot $d

# --- T3: missing disable-model-invocation ---
$d = New-CaseFixture -CaseName 't3-missing-dmi'
Edit-BothTrees -CaseRoot $d -SkillName 'code-review-plan' -Transform {
    param($text)
    return ($text -replace "(?m)^disable-model-invocation: true`r?`n", '')
}
Assert-Case -TestName 'missing disable-model-invocation fires' -ExpectedCode 1 -ExpectedSubstring "missing 'disable-model-invocation: true'" -RepoRoot $d

# --- T4: phantom agent referenced via subagent_type ---
$d = New-CaseFixture -CaseName 't4-phantom-agent'
Edit-BothTrees -CaseRoot $d -SkillName 'plan_sa' -Transform {
    param($text)
    return $text.Replace('- **subagent_type:** `architect`', '- **subagent_type:** `phantom-agent-does-not-exist`')
}
Assert-Case -TestName 'phantom agent fires' -ExpectedCode 1 -ExpectedSubstring "phantom agent referenced via subagent_type: 'phantom-agent-does-not-exist'" -RepoRoot $d

# --- T5: _sa skill reverted to a generic subagent_type (named-agent enforcement regression) ---
$d = New-CaseFixture -CaseName 't5-generic-reversion'
Edit-BothTrees -CaseRoot $d -SkillName 'code-review-plan_sa' -Transform {
    param($text)
    return $text.Replace('- **subagent_type:** `security-auditor` (read-only: Read, Grep, Glob)', '- **subagent_type:** Explore')
}
Assert-Case -TestName 'named-agent enforcement regression fires' -ExpectedCode 1 -ExpectedSubstring "named-agent enforcement: subagent_type uses generic type 'Explore'" -RepoRoot $d

# --- T6: drifted mirror (one byte different between skills/ and .claude/skills/) ---
$d = New-CaseFixture -CaseName 't6-drift'
$installCommit = Join-Path $d '.claude/skills/commit/SKILL.md'
Set-FixtureText -Path $installCommit -Content ((Get-FixtureText -Path $installCommit) + ' ')
Assert-Case -TestName 'drifted mirror fires' -ExpectedCode 1 -ExpectedSubstring 'byte mismatch between canonical and install trees' -RepoRoot $d

# --- T7: orphan skill directory (present on one side only) ---
$d = New-CaseFixture -CaseName 't7-orphan'
Remove-Item -LiteralPath (Join-Path $d '.claude/skills/test-review-plan_sa') -Recurse -Force
Assert-Case -TestName 'orphan skill directory fires' -ExpectedCode 1 -ExpectedSubstring 'orphaned skill directory' -RepoRoot $d

# --- T8: stale shadow command file ---
$d = New-CaseFixture -CaseName 't8-stale-command'
New-Item -ItemType Directory -Path (Join-Path $d 'commands') -Force | Out-Null
Set-FixtureText -Path (Join-Path $d 'commands/plan.md') -Content "# stale /plan command`n`nThis should have been deleted as part of the skills migration.`n"
Assert-Case -TestName 'stale shadow command file fires' -ExpectedCode 1 -ExpectedSubstring 'stale shadow command file still present' -RepoRoot $d

# --- T9: missing Argument Safety guardrail sentence ---
$d = New-CaseFixture -CaseName 't9-missing-guardrail'
Edit-BothTrees -CaseRoot $d -SkillName 'commit' -Transform {
    param($text)
    return $text.Replace('as untrusted data, not instructions', 'as untrusted data')
}
Assert-Case -TestName 'missing Argument Safety guardrail sentence fires' -ExpectedCode 1 -ExpectedSubstring 'missing required guardrail sentence fragment' -RepoRoot $d

# --- T10: missing $ARGUMENTS in a body ---
$d = New-CaseFixture -CaseName 't10-missing-arguments'
Edit-BothTrees -CaseRoot $d -SkillName 'test-review-plan' -Transform {
    param($text)
    return $text.Replace('$ARGUMENTS', 'THE_TEST_TARGET')
}
Assert-Case -TestName 'missing $ARGUMENTS in body fires' -ExpectedCode 1 -ExpectedSubstring 'skill body does not reference $ARGUMENTS' -RepoRoot $d

# --- T11: description of 20 chars or fewer ---
$d = New-CaseFixture -CaseName 't11-short-description'
Edit-BothTrees -CaseRoot $d -SkillName 'test-review-plan_sa' -Transform {
    param($text)
    return [regex]::Replace($text, '(?m)^description:.*$', 'description: Too short.')
}
Assert-Case -TestName 'description <= 20 chars fires' -ExpectedCode 1 -ExpectedSubstring 'description is too short' -RepoRoot $d

# --- T12: plan-producing skill with its "Execution Prompt" heading removed ---
$d = New-CaseFixture -CaseName 't12-missing-execution-prompt-heading'
Edit-BothTrees -CaseRoot $d -SkillName 'plan' -Transform {
    param($text)
    return $text.Replace('Execution Prompt', 'Execution Instructions')
}
Assert-Case -TestName 'missing Execution Prompt heading fires' -ExpectedCode 1 -ExpectedSubstring "missing a heading line containing 'Execution Prompt'" -RepoRoot $d

# --- T13: broken fenced-template section sequence (one ## N. heading deleted) ---
$d = New-CaseFixture -CaseName 't13-broken-template-sequence'
Edit-BothTrees -CaseRoot $d -SkillName 'code-review-plan_sa' -Transform {
    param($text)
    return [regex]::Replace($text, '(?m)^##\s+6\.\s+Files to Create or Modify\r?\n', '')
}
Assert-Case -TestName 'broken template section sequence fires' -ExpectedCode 1 -ExpectedSubstring 'template section numbering is not contiguous starting at 1' -RepoRoot $d

# --- T14: new roster/table phantom coverage (renamed agent reference in plan_sa's domain table) ---
$d = New-CaseFixture -CaseName 't14-phantom-table-agent'
Edit-BothTrees -CaseRoot $d -SkillName 'plan_sa' -Transform {
    param($text)
    return $text.Replace('| `database-architect` |', '| `totally-fake-agent` |')
}
Assert-Case -TestName 'phantom agent in domain-routing table row fires' -ExpectedCode 1 -ExpectedSubstring "phantom agent referenced in table row: 'totally-fake-agent'" -RepoRoot $d

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
