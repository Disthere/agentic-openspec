#requires -Version 5.1
<#
.SYNOPSIS
    Собирает метрики пилота из артефактов репозитория — без ручного учёта.

.DESCRIPTION
    Владелец не должен ничего записывать руками. Всё, что нужно для ретроспективы,
    уже лежит в файлах процесса; скрипт их читает и печатает сводку.

    Откуда берётся каждая метрика:
      * требования / сценарии      — "### Requirement:" и "#### Scenario:" в proposal.md
      * задачи проекта             — "- [x]" и "- [ ]" в tasks.md
      * фаза предложения           — поле Status в proposal.md + наличие файлов
      * открытые вопросы на человека — строки OQ-N без решения в DECISIONS.md
      * принятые решения           — строки D-NNN в DECISIONS.md
      * заполненность приёмки      — непустые строки матрицы в acceptance.md
      * вердикт ревьюера           — "VERDICT: Pass|Fail" в acceptance.md / отчёте
      * время фаз                  — по датам коммитов, затрагивающих предложение
      * трассировка                — сколько требований упомянуто в acceptance.md
      * гейты репозитория          — запуск tools/*.ps1 и dotnet (опционально, -WithGates)

    Ничего не изменяет. Только чтение и вывод.

.PARAMETER Proposal
    Проверить одно предложение (путь или имя каталога). По умолчанию — все активные.

.PARAMETER Json
    Вывести машинночитаемый JSON вместо таблиц.

.PARAMETER WithGates
    Дополнительно прогнать машинные гейты (валидатор, канон, шаблон) и записать результат.

.PARAMETER OutFile
    Записать отчёт в файл (Markdown). По умолчанию — только консоль.

.EXAMPLE
    ./tools/collect-metrics.ps1 -OutFile METRICS.md

.EXAMPLE
    ./tools/collect-metrics.ps1 -Json
#>
[CmdletBinding()]
param(
    [string]$Proposal,
    [switch]$Json,
    [switch]$WithGates,
    [string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$proposalsRoot = Join-Path $repoRoot 'openspec/proposals'
$archiveRoot = Join-Path $proposalsRoot 'archive'

function Read-Text {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return Get-Content -LiteralPath $Path -Raw -Encoding utf8
}

function Get-Count {
    param([string]$Text, [string]$Pattern)
    if ($null -eq $Text) { return 0 }
    return [regex]::Matches($Text, $Pattern, 'Multiline').Count
}

# --- Анализ одного предложения ------------------------------------------------------------
function Get-ProposalMetrics {
    param([string]$Dir)

    $name = Split-Path -Leaf $Dir
    $proposalPath = Join-Path $Dir 'proposal.md'
    $tasksPath = Join-Path $Dir 'tasks.md'
    $acceptancePath = Join-Path $Dir 'acceptance.md'

    $proposal = Read-Text $proposalPath
    $tasks = Read-Text $tasksPath
    $acceptance = Read-Text $acceptancePath

    # Статус из шапки: "- **Status:** Approved <!-- ... -->"
    $status = 'неизвестно'
    if ($null -ne $proposal) {
        $m = [regex]::Match($proposal, '(?im)^\s*[-*]?\s*\**\s*Status:?\**\s*([A-Za-z]+)')
        if ($m.Success) { $status = $m.Groups[1].Value }
    }

    # Требования и сценарии
    $requirements = Get-Count $proposal '^###\s+Requirement:'
    $scenarios = Get-Count $proposal '^####\s+Scenario:'

    # Задачи
    $tasksDone = Get-Count $tasks '^\s*-\s*\[[xX]\]'
    $tasksTodo = Get-Count $tasks '^\s*-\s*\[ \]'
    $tasksTotal = $tasksDone + $tasksTodo

    # Приёмка: считаем строки матрицы "| R..." с заполненным результатом
    $acceptanceRows = 0
    $acceptanceFilled = 0
    if ($null -ne $acceptance) {
        foreach ($line in ($acceptance -split "`r?`n")) {
            if ($line -match '^\|\s*R\d+') {
                $acceptanceRows++
                # Заполнено, если в строке есть Pass/Fail/N/A, а не пустая ячейка или плейсхолдер
                if ($line -match '(?i)\b(Pass|Fail|N/A|✅|❌)\b') { $acceptanceFilled++ }
            }
        }
    }

    # Вердикт ревьюера
    $verdict = $null
    foreach ($t in @($acceptance, (Read-Text (Join-Path $Dir 'review.md')))) {
        if ($null -eq $t) { continue }
        $v = [regex]::Match($t, '(?im)VERDICT:\s*(Pass|Fail)')
        if ($v.Success) { $verdict = $v.Groups[1].Value; break }
    }

    # Трассировка: сколько ID требований упомянуто в acceptance.md
    $traced = 0
    if ($null -ne $acceptance) {
        $ids = [regex]::Matches($proposal, '(?m)^###\s+Requirement:.*?\b(R\d+|[A-Z][A-Z0-9]*-\d+)\b') |
            ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        foreach ($id in $ids) {
            if ($acceptance -match [regex]::Escape($id)) { $traced++ }
        }
    }

    # Время фаз: даты коммитов, затрагивающих каталог предложения
    $firstCommit = $null
    $lastCommit = $null
    $commitCount = 0
    Push-Location $repoRoot
    try {
        $rel = $Dir.Substring($repoRoot.Length + 1) -replace '\\', '/'
        $log = & git log --format='%aI' -- $rel 2>$null
        if ($LASTEXITCODE -eq 0 -and $log) {
            $dates = @($log | Where-Object { $_ })
            if ($dates.Count -gt 0) {
                $commitCount = $dates.Count
                $firstCommit = ($dates | Select-Object -Last 1)
                $lastCommit = ($dates | Select-Object -First 1)
            }
        }
    }
    catch { }
    finally { Pop-Location }

    # Файлы предложения (признаки пройденных фаз)
    $hasDesign = Test-Path -LiteralPath (Join-Path $Dir 'design.md')
    $hasPerformance = Test-Path -LiteralPath (Join-Path $Dir 'performance.md')
    $hasSpecs = Test-Path -LiteralPath (Join-Path $Dir 'specs')
    $hasContracts = Test-Path -LiteralPath (Join-Path $Dir 'contracts')

    [pscustomobject]@{
        id              = $name
        status          = $status
        requirements    = $requirements
        scenarios       = $scenarios
        tasksDone       = $tasksDone
        tasksTotal      = $tasksTotal
        acceptanceRows  = $acceptanceRows
        acceptanceFilled = $acceptanceFilled
        verdict         = $verdict
        traced          = $traced
        hasDesign       = $hasDesign
        hasSpecs        = $hasSpecs
        hasContracts    = $hasContracts
        hasPerformance  = $hasPerformance
        commits         = $commitCount
        firstCommit     = $firstCommit
        lastCommit      = $lastCommit
    }
}

# --- Открытые вопросы и решения -----------------------------------------------------------
function Get-QuestionMetrics {
    $oqText = Read-Text (Join-Path $repoRoot 'OPEN_QUESTIONS.md')
    $dText = Read-Text (Join-Path $repoRoot 'DECISIONS.md')

    # Реальные строки (не плейсхолдеры шаблона)
    $oqRows = @()
    if ($null -ne $oqText) {
        foreach ($m in [regex]::Matches($oqText, '(?m)^\|\s*(OQ-\d+)\s*\|[^\r\n]*$')) {
            if ($m.Value -notmatch '<[^>]*>') { $oqRows += $m.Groups[1].Value }
        }
    }
    $dRows = @()
    if ($null -ne $dText) {
        foreach ($m in [regex]::Matches($dText, '(?m)^\|\s*(D-\d{3})\s*\|[^\r\n]*$')) {
            if ($m.Value -notmatch '<[^>]*>' -and $m.Value -notmatch 'YYYY-MM-DD') { $dRows += $m.Groups[1].Value }
        }
    }

    # Открытые: OQ без парного "закрыт" в своей строке
    $open = 0
    foreach ($m in [regex]::Matches($oqText, '(?m)^\|\s*(OQ-\d+)\s*\|[^\r\n]*$')) {
        if ($m.Value -match '<[^>]*>') { continue }
        if ($m.Value -notmatch '(?i)закрыт|✅') { $open++ }
    }

    [pscustomobject]@{
        openQuestions = $open
        totalQuestions = $oqRows.Count
        decisions = $dRows.Count
    }
}

# --- Сборка ------------------------------------------------------------------------------
$proposalDirs = @()
if ($Proposal) {
    $p = if ([System.IO.Path]::IsPathRooted($Proposal)) { $Proposal } else { Join-Path $repoRoot $Proposal }
    $proposalDirs += (Get-Item -LiteralPath $p)
}
else {
    $proposalDirs += @(Get-ChildItem -LiteralPath $proposalsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'archive' -and $_.Name -notmatch '^000-' })
}

$items = @()
foreach ($d in $proposalDirs) { $items += (Get-ProposalMetrics -Dir $d.FullName) }

$archived = @()
if (Test-Path -LiteralPath $archiveRoot) {
    foreach ($d in (Get-ChildItem -LiteralPath $archiveRoot -Directory -ErrorAction SilentlyContinue)) {
        $archived += (Get-ProposalMetrics -Dir $d.FullName)
    }
}

$q = Get-QuestionMetrics

$gates = @()
if ($WithGates) {
    $checks = @(
        @{ Name = 'validate-proposals'; Script = 'tools/validate-proposals.ps1'; Args = @('-All', '-CheckLinks') }
        @{ Name = 'check-canon-parity'; Script = 'tools/check-canon-parity.ps1'; Args = @() }
        @{ Name = 'check-template-clean'; Script = 'tools/check-template-clean.ps1'; Args = @() }
    )
    foreach ($c in $checks) {
        $scriptPath = Join-Path $repoRoot $c.Script
        if (-not (Test-Path -LiteralPath $scriptPath)) { continue }
        $hostExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh' } else { Join-Path $PSHOME 'powershell.exe' }
        if (-not (Test-Path -LiteralPath $hostExe)) { $hostExe = 'pwsh' }
        & $hostExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath @($c.Args) *> $null
        $gates += [pscustomobject]@{ name = $c.Name; exit = $LASTEXITCODE }
    }
}

# --- Вывод -------------------------------------------------------------------------------
if ($Json) {
    $payload = [pscustomobject]@{
        generatedAt = (Get-Date -Format 'o')
        active      = $items
        archived    = $archived
        questions   = $q
        gates       = $gates
    }
    $payload | ConvertTo-Json -Depth 6
    exit 0
}

$sb = [System.Text.StringBuilder]::new()
function W { param([string]$Line) [void]$sb.AppendLine($Line) }

W '# METRICS — сводка по процессу'
W ''
W ("> Собрано автоматически {0}. Руками ничего заполнять не нужно." -f (Get-Date -Format 'yyyy-MM-dd HH:mm'))
W '> Источник — артефакты репозитория: `proposal.md`, `tasks.md`, `acceptance.md`, `OPEN_QUESTIONS.md`, `DECISIONS.md`, история git.'
W ''
W '## 1. Активные предложения'
W ''
if ($items.Count -eq 0) {
    W '_Нет активных предложений._'
}
else {
    W '| Предложение | Статус | Требований | Сценариев | Задачи | Приёмка заполнена | Трассировка | Вердикт |'
    W '| - | - | - | - | - | - | - | - |'
    foreach ($i in $items) {
        $acc = if ($i.acceptanceRows -gt 0) { "$($i.acceptanceFilled)/$($i.acceptanceRows)" } else { '—' }
        $tr = if ($i.requirements -gt 0) { "$($i.traced)/$($i.requirements)" } else { '—' }
        W ("| {0} | {1} | {2} | {3} | {4}/{5} | {6} | {7} | {8} |" -f $i.id, $i.status,
            $i.requirements, $i.scenarios, $i.tasksDone, $i.tasksTotal, $acc, $tr, $(if ($i.verdict) { $i.verdict } else { '—' }))
    }
}
W ''
W '## 2. Вопросы и решения'
W ''
W ("- Открытых вопросов: **{0}** (всего в реестре: {1})" -f $q.openQuestions, $q.totalQuestions)
W ("- Зафиксированных решений: **{0}**" -f $q.decisions)
W ''
if ($items.Count -gt 0) {
    W '## 3. Время по предложениям (по коммитам)'
    W ''
    W '| Предложение | Коммитов | Первый | Последний |'
    W '| - | - | - | - |'
    foreach ($i in $items) {
        $f = if ($i.firstCommit) { ([datetime]$i.firstCommit).ToString('yyyy-MM-dd HH:mm') } else { '—' }
        $l = if ($i.lastCommit) { ([datetime]$i.lastCommit).ToString('yyyy-MM-dd HH:mm') } else { '—' }
        W ("| {0} | {1} | {2} | {3} |" -f $i.id, $i.commits, $f, $l)
    }
    W ''
}
W '## 4. Архив завершённых'
W ''
if ($archived.Count -eq 0) {
    W '_Архив пуст._'
}
else {
    W '| Предложение | Требований | Задачи | Приёмка | Вердикт |'
    W '| - | - | - | - | - |'
    foreach ($a in $archived) {
        $acc = if ($a.acceptanceRows -gt 0) { "$($a.acceptanceFilled)/$($a.acceptanceRows)" } else { '—' }
        W ("| {0} | {1} | {2}/{3} | {4} | {5} |" -f $a.id, $a.requirements, $a.tasksDone, $a.tasksTotal, $acc, $(if ($a.verdict) { $a.verdict } else { '—' }))
    }
}
W ''

if ($gates.Count -gt 0) {
    W '## 5. Машинные гейты'
    W ''
    W '| Гейт | Код возврата |'
    W '| - | - |'
    foreach ($g in $gates) {
        $mark = if ($g.exit -eq 0) { '✅ 0' } else { "❌ $($g.exit)" }
        W ("| {0} | {1} |" -f $g.name, $mark)
    }
    W ''
}

W '## Что эти числа значат'
W ''
W '- **Трассировка** — какая доля требований упомянута в приёмке. Низкая = спецификация и проверка разошлись.'
W '- **Приёмка заполнена** — сколько строк матрицы имеют результат. Незаполненные = непроверенное.'
W '- **Вердикт** — `Pass`/`Fail` ревьюера. Отсутствует = независимого ревью не было.'
W '- **Открытых вопросов** — сколько решений ждёт человек. Прямой индикатор того, сколько модель взяла на себя.'
W ''

$report = $sb.ToString()

if ($OutFile) {
    $outPath = if ([System.IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path $repoRoot $OutFile }
    [System.IO.File]::WriteAllText($outPath, $report, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Отчёт записан: $outPath" -ForegroundColor Green
}

Write-Host $report
