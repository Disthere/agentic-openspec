#requires -Version 5.1
<#
.SYNOPSIS
    Проверка «шаблон чист» — PLAN.md, задача 5.8 / P0-5.

.DESCRIPTION
    Ловит историю разработки самого набора, которая не должна уезжать в проект-получатель:
      * `PLAN.md` / `ASSESSMENT.md` в корне (журнал работы над набором);
      * `docs/baseline/` с отчётами батчей;
      * активные предложения `00[1-6]-*` (примеры должны быть в archive/);
      * живые спецификации набора (`independent-review`, `delivery-roles`, `product-lifecycle`);
      * реестры, не приведённые к шаблонам (эвристика: наличие `D-0NN`, `OQ-N` про сам набор).

    Скрипт осознанно НЕ требует удаления `src/Smoke` и `tests/Smoke.Tests`: они доказывают, что
    шаблон собирается (см. docs/CLEANUP.md §4).

.PARAMETER SkipBaseline
    Не считать `docs/baseline/` нарушением (полезно при работе над самим набором).

.EXAMPLE
    ./tools/check-template-clean.ps1

.EXAMPLE
    ./tools/check-template-clean.ps1 -SkipBaseline
#>
[CmdletBinding()]
param(
    [switch]$SkipBaseline
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Error { param([string]$m) $errors.Add($m) }
function Add-Warning { param([string]$m) $warnings.Add($m) }

# --- 1. Журнал работы над набором в корне -------------------------------------------------
foreach ($f in @('PLAN.md', 'ASSESSMENT.md')) {
    $p = Join-Path $repoRoot $f
    if (Test-Path -LiteralPath $p) {
        Add-Error "$f остался в корне — это журнал работы над набором, удалите его (docs/CLEANUP.md §5)"
    }
}

# --- 2. Baseline с отчётами батчей ---------------------------------------------------------
$baseline = Join-Path $repoRoot 'docs/baseline'
if ((Test-Path -LiteralPath $baseline) -and -not $SkipBaseline) {
    $files = @(Get-ChildItem -LiteralPath $baseline -File -ErrorAction SilentlyContinue)
    if ($files.Count -gt 0) {
        Add-Error "docs/baseline/ содержит $($files.Count) файл(ов) — отчёты работы над набором (docs/CLEANUP.md §5). Используйте -SkipBaseline, если это осознанно"
    }
}

# --- 3. Активные предложения-примеры ------------------------------------------------------
$proposals = Join-Path $repoRoot 'openspec/proposals'
if (Test-Path -LiteralPath $proposals) {
    foreach ($dir in @(Get-ChildItem -LiteralPath $proposals -Directory -ErrorAction SilentlyContinue)) {
        if ($dir.Name -match '^00[1-6]-' -and $dir.Name -ne 'archive') {
            Add-Error "активное предложение-пример '$($dir.Name)' — перенесите в archive/ или удалите (docs/CLEANUP.md §3)"
        }
    }
}

# --- 4. Живые спецификации набора ---------------------------------------------------------
$specs = Join-Path $repoRoot 'openspec/specs'
$setOwnSpecs = @('independent-review', 'delivery-roles', 'product-lifecycle')
foreach ($cap in $setOwnSpecs) {
    $p = Join-Path $specs $cap
    if (Test-Path -LiteralPath $p) {
        Add-Error "спецификация набора 'openspec/specs/$cap/' осталась — это не спецификация вашего продукта (docs/CLEANUP.md §3)"
    }
}

# --- 5. Реестры приведены к шаблонам ------------------------------------------------------
# После сброса DECISIONS.md содержит только шапку и шаблон — нет записей вида "| D-0".
$decisionsPath = Join-Path $repoRoot 'DECISIONS.md'
if (Test-Path -LiteralPath $decisionsPath) {
    $decisions = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
    # Реальные записи отличаются от строк-заполнителей шаблона (`<...>`) наличием содержательного текста.
    # Примеры вида "| D-001 | YYYY-MM-DD | <одна фраза…> |" — это шаблон, а не история набора.
    $setDecisions = @(
        [regex]::Matches($decisions, '(?m)^\|\s*D-0\d\d\s*\|[^\r\n]*$') |
            Where-Object { $_.Value -notmatch '<[^>]*>' -and $_.Value -notmatch 'YYYY-MM-DD' }
    )
    if ($setDecisions.Count -gt 0) {
        Add-Error "DECISIONS.md содержит $($setDecisions.Count) реальных записей D-0NN набора — замените на docs/DECISIONS-TEMPLATE.md (docs/CLEANUP.md §2)"
    }
}

$oqPath = Join-Path $repoRoot 'OPEN_QUESTIONS.md'
if (Test-Path -LiteralPath $oqPath) {
    $oq = Get-Content -LiteralPath $oqPath -Raw -Encoding UTF8
    $setOq = @(
        [regex]::Matches($oq, '(?m)^\|\s*OQ-\d+\s*\|[^\r\n]*$') |
            Where-Object { $_.Value -notmatch '<[^>]*>' }
    )
    if ($setOq.Count -gt 0) {
        Add-Warning "OPEN_QUESTIONS.md содержит $($setOq.Count) записей OQ-N — проверьте, что они про ваш проект, а не про набор (docs/CLEANUP.md §2)"
    }
}

# --- 6. Что обязано остаться --------------------------------------------------------------
$mustKeep = @(
    'AGENTS.md'
    '.clinerules'
    'LICENSE'
    'THIRD-PARTY.md'
    'global.json'
    'Directory.Build.props'
    'Directory.Packages.props'
    'openspec/constitution.md'
    'openspec/config.yaml'
    'openspec/standards/01-code-style.md'
    '.agents/analyst.md'
    '.agents/architect.md'
    '.agents/csharp-dev.md'
    '.agents/qa-engineer.md'
    '.agents/reviewer.md'
    '.agents/ops-release.md'
    'tools/validate-proposals.ps1'
    'docs/CLEANUP.md'
)
foreach ($rel in $mustKeep) {
    $p = Join-Path $repoRoot $rel
    if (-not (Test-Path -LiteralPath $p)) {
        Add-Error "обязательный файл шаблона отсутствует: $rel"
    }
}

# --- 7. Ссылки резолвятся (шаблон без битых путей) ----------------------------------------
# Вызываем валидатор в режиме проверки ссылок: на чистом шаблоне активных предложений нет,
# но относительные ссылки в документации обязаны работать (это ловило ../openspec из корня).
$validator = Join-Path $PSScriptRoot 'validate-proposals.ps1'
if (Test-Path -LiteralPath $validator) {
    $linkCheck = & powershell -NoProfile -ExecutionPolicy Bypass -File $validator -CheckLinks 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Add-Error 'битые относительные ссылки в репозитории — запустите tools/validate-proposals.ps1 -CheckLinks для деталей'
    }
}

# --- Вывод --------------------------------------------------------------------------------
foreach ($w in $warnings) { Write-Host "WARN  $w" -ForegroundColor Yellow }
foreach ($e in $errors) { Write-Host "FAIL  $e" -ForegroundColor Red }

Write-Host ''
if ($errors.Count -gt 0) {
    Write-Host "ИТОГ: ПРОВАЛ — шаблон не чист, нарушений: $($errors.Count)" -ForegroundColor Red
    Write-Host 'Прогоните docs/CLEANUP.md и запустите снова.'
    exit 1
}

Write-Host "ИТОГ: УСПЕХ — шаблон чист (предупреждений: $($warnings.Count))" -ForegroundColor Green
exit 0
