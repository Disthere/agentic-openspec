#requires -Version 5.1
<#
.SYNOPSIS
    Проверка «шаблон чист» — PLAN.md, задача 5.8 / P0-5.

.DESCRIPTION
    Ловит историю разработки самого набора, которая не должна уезжать в проект-получатель:
      * `PLAN.md` / `ASSESSMENT.md` в корне (журнал работы над набором);
      * `sdd/docs/legacy/set-history/baseline/` с отчётами батчей;
      * активные предложения `00[1-6]-*` (примеры должны быть в archive/);
      * живые спецификации набора (`independent-review`, `delivery-roles`, `product-lifecycle`);
      * реестры, не приведённые к шаблонам (эвристика: наличие `D-0NN`, `OQ-N` про сам набор).

    Скрипт осознанно НЕ требует удаления `src/Smoke` и `tests/Smoke.Tests`: они доказывают, что
    шаблон собирается (см. sdd/docs/CLEANUP.md §4).

.PARAMETER SkipBaseline
    Не считать `sdd/docs/legacy/set-history/baseline/` нарушением (полезно при работе над самим набором).

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


# --- Запуск дочернего скрипта тем же хостом PowerShell (Windows: powershell, Linux: pwsh) ----
# Жёсткий вызов `powershell` падает на Linux-раннере (нет такого исполняемого файла).
function Invoke-PwshScript {
    param([string]$ScriptPath, [string[]]$Arguments = @())
    $hostExe = if ($PSVersionTable.PSEdition -eq 'Core') {
        Join-Path $PSHOME 'pwsh'
    } else {
        Join-Path $PSHOME 'powershell.exe'
    }
    if (-not (Test-Path -LiteralPath $hostExe)) { $hostExe = 'pwsh' }
    & $hostExe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments
}
# Раскладка: всё SDD живёт в `sdd/`, в корне проекта — только то, что инструменты
# ищут строго там (AGENTS.md, .clinerules, .agents/skills, global.json, Directory.*.props).
# Поэтому корней два: $sddRoot — каталог набора, $repoRoot — корень проекта.
$sddRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $sddRoot
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Error { param([string]$m) $errors.Add($m) }
function Add-Warning { param([string]$m) $warnings.Add($m) }

# --- 1. Журнал работы над набором в корне -------------------------------------------------
foreach ($f in @('PLAN.md', 'ASSESSMENT.md')) {
    $p = Join-Path $repoRoot $f
    if (Test-Path -LiteralPath $p) {
        Add-Error "$f остался в корне — это журнал работы над набором, удалите его (sdd/docs/CLEANUP.md §5)"
    }
}

# --- 2. Baseline с отчётами батчей ---------------------------------------------------------
# После переноса в `sdd/` эти файлы живут в замороженной истории набора, а не в `docs/baseline/`
# (этот путь больше не существует — находка M-8: проверка била в пустоту и никогда не срабатывала).
#
# В репозитории САМОГО набора история обязана присутствовать: конституция §1 п. 7 требует хранить
# её в `docs/legacy/set-history/`. Нарушением она становится только в РАЗДАВАЕМОЙ копии, где
# `docs/legacy/set-history/` по чек-листу CLEANUP удаляется. Поэтому здесь — ошибка только при
# явном запросе строгого режима, иначе предупреждение с точным путём и командой очистки.
$baseline = Join-Path $sddRoot 'docs/legacy/set-history/baseline'
if (Test-Path -LiteralPath $baseline) {
    $files = @(Get-ChildItem -LiteralPath $baseline -File -ErrorAction SilentlyContinue)
    if ($files.Count -gt 0) {
        if ($SkipBaseline) {
            Write-Verbose "docs/legacy/set-history/baseline/: $($files.Count) файл(ов) — история набора, осознанно оставлена (-SkipBaseline)"
        }
        else {
            Add-Warning "sdd/docs/legacy/set-history/baseline/ содержит $($files.Count) файл(ов) — это история НАБОРА, а не вашего продукта; в раздаваемой копии удалите каталог sdd/docs/legacy/set-history/ (docs/CLEANUP.md §5)"
        }
    }
}

# --- 3. Активные предложения-примеры ------------------------------------------------------
$proposals = Join-Path $sddRoot 'openspec/proposals'
if (Test-Path -LiteralPath $proposals) {
    foreach ($dir in @(Get-ChildItem -LiteralPath $proposals -Directory -ErrorAction SilentlyContinue)) {
        if ($dir.Name -match '^00[1-6]-' -and $dir.Name -ne 'archive') {
            Add-Error "активное предложение-пример '$($dir.Name)' — перенесите в archive/ или удалите (sdd/docs/CLEANUP.md §3)"
        }
    }
}

# --- 4. Живые спецификации набора ---------------------------------------------------------
$specs = Join-Path $sddRoot 'openspec/specs'
$setOwnSpecs = @('independent-review', 'delivery-roles', 'product-lifecycle')
foreach ($cap in $setOwnSpecs) {
    $p = Join-Path $specs $cap
    if (Test-Path -LiteralPath $p) {
        Add-Error "спецификация набора 'sdd/openspec/specs/$cap/' осталась — это не спецификация вашего продукта (sdd/docs/CLEANUP.md §3)"
    }
}

# --- 5. Реестры приведены к шаблонам ------------------------------------------------------
# После сброса DECISIONS.md содержит только шапку и шаблон — нет записей вида "| D-0".
$decisionsPath = Join-Path $sddRoot 'DECISIONS.md'
if (Test-Path -LiteralPath $decisionsPath) {
    $decisions = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
    # Реальные записи отличаются от строк-заполнителей шаблона (`<...>`) наличием содержательного текста.
    # Примеры вида "| D-001 | YYYY-MM-DD | <одна фраза…> |" — это шаблон, а не история набора.
    $setDecisions = @(
        [regex]::Matches($decisions, '(?m)^\|\s*D-0\d\d\s*\|[^\r\n]*$') |
            Where-Object { $_.Value -notmatch '<[^>]*>' -and $_.Value -notmatch 'YYYY-MM-DD' }
    )
    if ($setDecisions.Count -gt 0) {
        Add-Error "DECISIONS.md содержит $($setDecisions.Count) реальных записей D-0NN набора — замените на sdd/docs/DECISIONS-TEMPLATE.md (sdd/docs/CLEANUP.md §2)"
    }
}

$oqPath = Join-Path $sddRoot 'OPEN_QUESTIONS.md'
if (Test-Path -LiteralPath $oqPath) {
    $oq = Get-Content -LiteralPath $oqPath -Raw -Encoding UTF8
    $setOq = @(
        [regex]::Matches($oq, '(?m)^\|\s*OQ-\d+\s*\|[^\r\n]*$') |
            Where-Object { $_.Value -notmatch '<[^>]*>' }
    )
    if ($setOq.Count -gt 0) {
        Add-Warning "OPEN_QUESTIONS.md содержит $($setOq.Count) записей OQ-N — проверьте, что они про ваш проект, а не про набор (sdd/docs/CLEANUP.md §2)"
    }
}

# --- 6. Что обязано остаться --------------------------------------------------------------
# Обязательные файлы. Раскладка: SDD-содержимое — в `sdd/`, в корне проекта — только то,
# что инструменты ищут строго там. Поэтому пути делятся на две группы: корневые (проверяются
# от $repoRoot) и наборные (от $sddRoot).
$mustKeepRoot = @(
    'AGENTS.md'
    '.clinerules'
    'LICENSE'
    'THIRD-PARTY.md'
    'global.json'
    'Directory.Build.props'
    'Directory.Packages.props'
    '.agents/analyst.md'
    '.agents/architect.md'
    '.agents/csharp-dev.md'
    '.agents/qa-engineer.md'
    '.agents/reviewer.md'
    '.agents/ops-release.md'
    '.github/workflows/scaffold-check.yml'
)
$mustKeepSdd = @(
    'openspec/constitution.md'
    'openspec/config.yaml'
    'openspec/standards/01-code-style.md'
    'tools/validate-proposals.ps1'
    'docs/CLEANUP.md'
)
$mustKeep = @()
foreach ($rel in $mustKeepRoot) { $mustKeep += @{ Base = $repoRoot; Rel = $rel } }
foreach ($rel in $mustKeepSdd)  { $mustKeep += @{ Base = $sddRoot;  Rel = $rel } }
foreach ($item in $mustKeep) {
    $p = Join-Path $item.Base $item.Rel
    if (-not (Test-Path -LiteralPath $p)) {
        Add-Error "обязательный файл шаблона отсутствует: $($item.Rel)"
    }
}

# --- 7. Ссылки резолвятся (шаблон без битых путей) ----------------------------------------
# Вызываем валидатор в режиме проверки ссылок: на чистом шаблоне активных предложений нет,
# но относительные ссылки в документации обязаны работать (это ловило ../openspec из корня).
$validator = Join-Path $PSScriptRoot 'validate-proposals.ps1'
if (Test-Path -LiteralPath $validator) {
    $linkCheck = Invoke-PwshScript -ScriptPath $validator -Arguments @('-CheckLinks') 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Add-Error 'битые относительные ссылки в репозитории — запустите sdd/tools/validate-proposals.ps1 -CheckLinks для деталей'
    }
}

# --- 8. Материалы в inputs/ зарегистрированы ----------------------------------------------
# Материал без записи в реестре для процесса не существует: Архитектор не может на него
# сослаться, Discovery-гейт не закрывается. Проверяем автоматически, а не «на глаз».
$registrar = Join-Path $PSScriptRoot 'register-inputs.ps1'
if (Test-Path -LiteralPath $registrar) {
    $regCheck = Invoke-PwshScript -ScriptPath $registrar -Arguments @('-Check') 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Add-Error 'в sdd/inputs/ есть незарегистрированные материалы — запустите sdd/tools/register-inputs.ps1 -Apply'
    }
}

# --- 9. METRICS.md не протух --------------------------------------------------------------
# На реальном кейсе (DeliveryServisePilot, 2026-11-16) `METRICS.md` был собран 2026-11-12
# и утверждал «Архив пуст», хотя архив уже содержал завершённое предложение. Гейты этого
# не видели: метрики — генерируемый файл, и никто не сверял дату сборки с фактом.
# Дату сравниваем с самым свежим артефактом, из которого метрики считаются.
$metricsPath = Join-Path $sddRoot 'METRICS.md'
if (Test-Path -LiteralPath $metricsPath) {
    $metricsText = Get-Content -LiteralPath $metricsPath -Raw -Encoding UTF8
    $builtM = [regex]::Match($metricsText, '(?i)Собрано автоматически\s+(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2})')
    if ($builtM.Success) {
        $builtAt = [datetime]::ParseExact(
            ($builtM.Groups[1].Value + ' ' + $builtM.Groups[2].Value),
            'yyyy-MM-dd HH:mm',
            [System.Globalization.CultureInfo]::InvariantCulture)

        # Самый свежий источник метрик: реестры и архив предложений.
        $sources = @(
            (Join-Path $sddRoot 'DECISIONS.md'),
            (Join-Path $sddRoot 'OPEN_QUESTIONS.md'),
            (Join-Path $sddRoot 'STATUS.md')
        )
        $archiveRoot = Join-Path $sddRoot 'openspec/proposals/archive'
        if (Test-Path -LiteralPath $archiveRoot) {
            $sources += @(Get-ChildItem -LiteralPath $archiveRoot -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -File -Filter '*.md' -ErrorAction SilentlyContinue } |
                ForEach-Object { $_.FullName })
        }

        $newest = $builtAt
        $newestName = ''
        foreach ($src in $sources) {
            if (-not (Test-Path -LiteralPath $src)) { continue }
            $t = (Get-Item -LiteralPath $src).LastWriteTime
            if ($t -gt $newest) { $newest = $t; $newestName = (Split-Path -Leaf $src) }
        }

        if ($newest -gt $builtAt) {
            $msg = "sdd/METRICS.md устарел: собран {0:yyyy-MM-dd HH:mm}, а '{1}' изменён позже ({2:yyyy-MM-dd HH:mm}) — выполните sdd/tools/collect-metrics.ps1 -WithGates -OutFile sdd/METRICS.md" -f $builtAt, $newestName, $newest
            Add-Warning $msg
        }
        else {
            Write-Verbose ("METRICS.md актуален ({0:yyyy-MM-dd HH:mm})" -f $builtAt)
        }
    }
    else {
        Add-Warning 'sdd/METRICS.md не содержит шапки «Собрано автоматически <дата>» — свежесть не проверить'
    }
}

# --- Вывод --------------------------------------------------------------------------------
foreach ($w in $warnings) { Write-Host "WARN  $w" -ForegroundColor Yellow }
foreach ($e in $errors) { Write-Host "FAIL  $e" -ForegroundColor Red }

Write-Host ''
if ($errors.Count -gt 0) {
    Write-Host "ИТОГ: ПРОВАЛ — шаблон не чист, нарушений: $($errors.Count)" -ForegroundColor Red
    Write-Host 'Прогоните sdd/docs/CLEANUP.md и запустите снова.'
    exit 1
}

Write-Host "ИТОГ: УСПЕХ — шаблон чист (предупреждений: $($warnings.Count))" -ForegroundColor Green
exit 0
