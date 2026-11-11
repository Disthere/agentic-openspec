#requires -Version 5.1
<#
.SYNOPSIS
    Валидатор предложений OpenSpec (PLAN.md, задача 5.1 / P0-3).

.DESCRIPTION
    Гейт, который нельзя обойти словами "я проверил". Проверяет структуру предложений
    по схеме активного профиля и падает на заведомо битом входе.

    Проверки (V1-V11 из плана):
      V1  обязательные разделы proposal.md
      V2  есть >= 1 "### Requirement:"
      V3  у каждого требования >= 1 "#### Scenario:"
      V4  у каждого сценария есть **WHEN** и **THEN**
      V5  паритет ID требований (R*) между proposal.md и specs/<capability>/spec.md
      V6  все относительные ссылки резолвятся
      V7  tasks.md: разделы "## N." и пункты "- [ ] N.N" / "- [x] N.N"
      V8  обязательные файлы: proposal.md, tasks.md, acceptance.md
      V9  performance.md обязателен при упоминании throughput/latency/SLO
      V10 нет [NEEDS CLARIFICATION] без соответствующего OQ-N
      V11 Status: Approved требует "Approved by:" и "Approved at:"

.PARAMETER Path
    Путь к одному предложению (каталог с proposal.md).

.PARAMETER All
    Проверить все активные предложения (NNN-slug), кроме archive/ и 000-*.

.PARAMETER Archived
    Режим архива: все "- [x]", "Status: Done", дельты присутствуют в openspec/specs/.

.PARAMETER CheckLinks
    Дополнительно проверить ссылки во всех Markdown-файлах репозитория.

.EXAMPLE
    ./tools/validate-proposals.ps1 -All

.EXAMPLE
    ./tools/validate-proposals.ps1 -Path openspec/proposals/999-broken
#>
[CmdletBinding(DefaultParameterSetName = 'All')]
# Наборы: One (-Path), Archived (-Archived), All (-All / -CheckLinks).
param(
    [Parameter(ParameterSetName = 'One', Mandatory = $true)]
    [string]$Path,

    [Parameter(ParameterSetName = 'All')]
    [switch]$All,

    [Parameter(ParameterSetName = 'Archived', Mandatory = $true)]
    [switch]$Archived,

    # Проверка ссылок доступна в любом режиме (в т.ч. на шаблоне без активных предложений).
    [switch]$CheckLinks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Корень репозитория: на уровень выше tools/ -------------------------------------------
$repoRoot = Split-Path -Parent $PSScriptRoot
$proposalsRoot = Join-Path $repoRoot 'openspec/proposals'
$specsRoot = Join-Path $repoRoot 'openspec/specs'

$script:errors = [System.Collections.Generic.List[string]]::new()
$script:warnings = [System.Collections.Generic.List[string]]::new()

function Add-Error {
    param([string]$Where, [string]$Message)
    $script:errors.Add("${Where}: $Message")
}

function Add-Warning {
    param([string]$Where, [string]$Message)
    $script:warnings.Add("${Where}: $Message")
}

function Read-Text {
    param([string]$FilePath)
    if (-not (Test-Path -LiteralPath $FilePath)) { return $null }
    return Get-Content -LiteralPath $FilePath -Raw -Encoding utf8
}

# --- V1: обязательные разделы proposal.md -------------------------------------------------
# Полный цикл (схема csharp-api / csharp-desktop).
$requiredSections = @(
    'Context'
    'Requirements'
    'C# Implementation Plan'
    'API / Contract Changes'
    'Test Strategy'
    'Capabilities'
    'Impact'
    'Changelog'
)

# Лёгкий маршрут `lite` (D-020 / схема lite.yaml): предложение помечает себя `skip_specs: true`.
$liteRequiredSections = @(
    'Context'
    'Change'
    'Test Strategy'
    'Impact'
    'Changelog'
)

function Test-ProposalSections {
    param([string]$ProposalPath, [string]$Where)

    $text = Read-Text $ProposalPath
    if ($null -eq $text) {
        Add-Error $Where 'proposal.md отсутствует'
        return
    }

    # Лёгкий маршрут: `skip_specs: true` в шапке переключает набор обязательных разделов (D-020).
    $isLite = $text -match '(?im)^\s*[-*]?\s*\**\s*skip_specs:?\**\s*true'
    $sections = if ($isLite) { $liteRequiredSections } else { $requiredSections }
    if ($isLite) { Write-Verbose "$Where : lite-маршрут (skip_specs: true)" }

    foreach ($section in $sections) {
        # Раздел ищется как '## <Section>' в любом регистре.
        $pattern = '(?im)^##\s+' + [regex]::Escape($section) + '\s*$'
        if ($text -notmatch $pattern) {
            Add-Error $Where "V1: отсутствует обязательный раздел '## $section'"
        }
    }

    # В lite требований и сценариев нет по определению — V2/V3/V4 не применяются.
    if ($isLite) { return }

    # V2: хотя бы одно требование
    $requirementIds = @(Get-RequirementIds $text)
    if ($requirementIds.Count -eq 0) {
        Add-Error $Where 'V2: нет ни одного "### Requirement:"'
    }

    # V3/V4: сценарии внутри требований
    Test-RequirementScenarios -Text $text -Where $Where

    # V10: [NEEDS CLARIFICATION] должен иметь парный OQ-N
    $clarifications = [regex]::Matches($text, '\[NEEDS CLARIFICATION[^\]]*\]')
    if ($clarifications.Count -gt 0) {
        $oqBlock = Read-Text (Join-Path $repoRoot 'OPEN_QUESTIONS.md')
        foreach ($m in $clarifications) {
            $context = Get-SurroundingText -Text $text -Index $m.Index -Radius 200
            if ($context -notmatch 'OQ-\d+') {
                Add-Error $Where "V10: '[NEEDS CLARIFICATION]' без OQ-N рядом: '$($m.Value)'"
            }
            if ($null -eq $oqBlock) { continue }
        }
    }

    # V11: Status: Approved требует подписи
    if ($text -match '(?im)^\s*[-*]?\s*\**\s*Status:?\**\s*Approved\b') {
        if ($text -notmatch '(?im)^\s*[-*]?\s*\**\s*Approved by:?\**\s*\S') {
            Add-Error $Where 'V11: Status: Approved без "Approved by:"'
        }
        if ($text -notmatch '(?im)^\s*[-*]?\s*\**\s*Approved at:?\**\s*\S') {
            Add-Error $Where 'V11: Status: Approved без "Approved at:"'
        }
    }
}

function Get-SurroundingText {
    param([string]$Text, [int]$Index, [int]$Radius)
    $start = [Math]::Max(0, $Index - $Radius)
    $length = [Math]::Min($Text.Length - $start, $Radius * 2)
    return $Text.Substring($start, $length)
}

function Get-RequirementIds {
    param([string]$Text)
    $ids = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($Text, '(?im)^###\s+Requirement:\s*(.+?)\s*$')) {
        $title = $m.Groups[1].Value
        # ID берётся из "R1" / "R-1" / "PAY-001" в заголовке требования.
        $idMatch = [regex]::Match($title, '\b([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\d+|\bR\d+)\b')
        if ($idMatch.Success) { $ids.Add($idMatch.Groups[1].Value) }
        else { $ids.Add($title.Trim()) }
    }
    return $ids
}

function Test-RequirementScenarios {
    param([string]$Text, [string]$Where)

    $lines = $Text -split "`r?`n"
    $currentRequirement = $null
    $scenarioCount = 0
    $requirementStartLine = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^###\s+Requirement:\s*(.+)$') {
            if ($null -ne $currentRequirement -and $scenarioCount -eq 0) {
                Add-Error $Where "V3: у требования '$currentRequirement' (строка $requirementStartLine) нет ни одного '#### Scenario:'"
            }
            $currentRequirement = $matches[1].Trim()
            $requirementStartLine = $i + 1
            $scenarioCount = 0
            continue
        }
        if ($line -match '^####\s+Scenario:') {
            $scenarioCount++
            Test-ScenarioWhenThen -Lines $lines -ScenarioLine $i -Where $Where
        }
    }

    if ($null -ne $currentRequirement -and $scenarioCount -eq 0) {
        Add-Error $Where "V3: у требования '$currentRequirement' (строка $requirementStartLine) нет ни одного '#### Scenario:'"
    }
}

function Test-ScenarioWhenThen {
    param([string[]]$Lines, [int]$ScenarioLine, [string]$Where)

    # Сценарий читается до следующего заголовка #### или ###.
    $buffer = [System.Collections.Generic.List[string]]::new()
    for ($j = $ScenarioLine + 1; $j -lt $Lines.Count; $j++) {
        if ($Lines[$j] -match '^#{3,4}\s+') { break }
        $buffer.Add($Lines[$j])
    }
    $body = $buffer -join "`n"
    $scenarioName = $Lines[$ScenarioLine].Trim()

    if ($body -notmatch '(?i)\*\*WHEN\*\*') {
        Add-Error $Where "V4: в сценарии '$scenarioName' (строка $($ScenarioLine + 1)) нет **WHEN**"
    }
    if ($body -notmatch '(?i)\*\*THEN\*\*') {
        Add-Error $Where "V4: в сценарии '$scenarioName' (строка $($ScenarioLine + 1)) нет **THEN**"
    }
}

# --- V7: формат tasks.md -------------------------------------------------------------------
function Test-TasksFormat {
    param([string]$TasksPath, [string]$Where)

    $text = Read-Text $TasksPath
    if ($null -eq $text) {
        Add-Error $Where 'tasks.md отсутствует'
        return
    }

    $lines = $text -split "`r?`n"
    $sectionCount = 0
    $itemCount = 0
    $badItems = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^##\s+\d+\.\s+.+') { $sectionCount++; continue }

        # Пункт задачи: "- [ ] 1.1 ..." или "- [x] 1.1 ..."
        if ($line -match '^\s*-\s+\[[ xX]\]') {
            if ($line -match '^\s*-\s+\[[ xX]\]\s+\d+\.\d+\s+.+') { $itemCount++ }
            else { $badItems.Add("строка $($i + 1): $($line.Trim())") }
        }
    }

    if ($sectionCount -eq 0) {
        Add-Error $Where 'V7: в tasks.md нет ни одного раздела "## N."'
    }
    if ($itemCount -eq 0) {
        Add-Error $Where 'V7: в tasks.md нет ни одного пункта вида "- [ ] N.N ..."'
    }
    foreach ($bad in $badItems) {
        Add-Error $Where "V7: неверный формат пункта задачи — $bad"
    }
}

# --- V5: паритет R* между proposal.md и specs/ --------------------------------------------
function Test-RequirementParity {
    param([string]$ProposalDir, [string]$Where)

    $proposalText = Read-Text (Join-Path $ProposalDir 'proposal.md')
    if ($null -eq $proposalText) { return }

    # В lite дельты specs/ не требуются (D-020) — парность проверять не с чем.
    if ($proposalText -match '(?im)^\s*[-*]?\s*\**\s*skip_specs:?\**\s*true') {
        Write-Verbose "$Where : lite — V5 пропущен"
        return
    }

    $proposalIds = @(Get-RequirementIds $proposalText)
    $specsDir = Join-Path $ProposalDir 'specs'
    if (-not (Test-Path -LiteralPath $specsDir)) {
        if ($proposalIds.Count -gt 0) {
            Add-Warning $Where 'V5: есть требования, но каталог specs/ отсутствует (дельта не сформирована)'
        }
        return
    }

    $specFiles = @(Get-ChildItem -LiteralPath $specsDir -Recurse -Filter 'spec.md' -File)
    if ($specFiles.Count -eq 0) {
        Add-Warning $Where 'V5: каталог specs/ есть, но spec.md не найден'
        return
    }

    $specIds = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $specFiles) {
        $specText = Read-Text $file.FullName
        foreach ($id in @(Get-RequirementIds $specText)) { $specIds.Add($id) }
    }

    foreach ($id in $proposalIds) {
        if ($specIds -notcontains $id) {
            Add-Error $Where "V5: требование '$id' есть в proposal.md, но отсутствует в specs/"
        }
    }
    foreach ($id in $specIds) {
        if ($proposalIds -notcontains $id) {
            Add-Error $Where "V5: требование '$id' есть в specs/, но отсутствует в proposal.md"
        }
    }
}

# --- V6: относительные ссылки резолвятся --------------------------------------------------
function Test-RelativeLinks {
    param([string]$File, [string]$BaseDir, [string]$Where)

    $text = Read-Text $File
    if ($null -eq $text) { return }

    foreach ($m in [regex]::Matches(($text -replace '`[^`
]*', ''''), '\]\((?<link>[^)]+)\)')) {
        $link = $m.Groups['link'].Value.Trim()
        if ($link -match '^(https?:|mailto:|#)') { continue }
        $target = ($link -split '#')[0]
        if ([string]::IsNullOrWhiteSpace($target)) { continue }
        # Ссылки с пробелами/юникодом и недопустимыми символами просто пропускаем как
        # неразрешимые локально: цель — ловить опечатки в путях, а не падать на экзотике.
        if ($target -match '[\x00-\x1f<>|"?*]') { continue }
        try {
            $resolved = Join-Path $BaseDir $target
        } catch {
            continue
        }
        if (-not (Test-Path -LiteralPath $resolved)) {
            Add-Error $Where "V6: битая относительная ссылка '$link' (искали: $resolved)"
        }
    }
}

# --- V8/V9: обязательные файлы и performance.md -------------------------------------------
function Test-RequiredFiles {
    param([string]$ProposalDir, [string]$Where)

    foreach ($required in @('proposal.md', 'tasks.md', 'acceptance.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $ProposalDir $required))) {
            Add-Error $Where "V8: отсутствует обязательный файл '$required'"
        }
    }

    $proposalText = Read-Text (Join-Path $ProposalDir 'proposal.md')
    if ($null -eq $proposalText) { return }

    # V9 ловит ЗАЯВКУ на производительность, а не всякое упоминание слов.
    # Раздел "## Performance & SLO" со значением "None"/"не влияет"/"не заявляются" — это
    # корректный отказ, а не повод требовать performance.md.
    $perfRegex = '(?i)(throughput|latency|задержк|пропускн\w*\s+способн|\bSLO\b|RPS)'
    $mentionsPerf = $proposalText -match $perfRegex
    if ($mentionsPerf) {
        $perfSection = [regex]::Match(
            $proposalText,
            '(?ims)^##\s+Performance\s*(?:&|and)?\s*SLO\s*$(?<body>.*?)(?=^##\s|\z)')
        $declinesPerf = $false
        if ($perfSection.Success) {
            $declinesPerf = $perfSection.Groups['body'].Value -match '(?i)\b(none|не\s+влия|не\s+заяв|отсутству|n/?a\b)'
        }
        else {
            $declinesPerf = $proposalText -match '(?i)(не\s+влия\w*\s+на\s+throughput|SLO\s+не\s+заяв)'
        }

        if (-not $declinesPerf) {
            if (-not (Test-Path -LiteralPath (Join-Path $ProposalDir 'performance.md'))) {
                Add-Error $Where 'V9: заявлены throughput/latency/SLO, но performance.md отсутствует'
            }
        }
    }
}

# --- Проверка одного предложения ----------------------------------------------------------
function Test-Proposal {
    param([string]$ProposalDir)

    $name = Split-Path -Leaf $ProposalDir
    $where = $name
    $script:currentProposal = $name

    Test-RequiredFiles -ProposalDir $ProposalDir -Where $where
    Test-ProposalSections -ProposalPath (Join-Path $ProposalDir 'proposal.md') -Where $where
    Test-TasksFormat -TasksPath (Join-Path $ProposalDir 'tasks.md') -Where $where
    Test-RequirementParity -ProposalDir $ProposalDir -Where $where

    # V6 для всех md-файлов предложения
    foreach ($file in (Get-ChildItem -LiteralPath $ProposalDir -Recurse -Filter '*.md' -File)) {
        Test-RelativeLinks -File $file.FullName -BaseDir $file.DirectoryName -Where "$where/$($file.Name)"
    }
}

# --- Режим архива (задача 2.11) -----------------------------------------------------------
function Test-ArchivedProposal {
    param([string]$ProposalDir)

    $name = Split-Path -Leaf $ProposalDir
    $where = "archive/$name"

    $proposalText = Read-Text (Join-Path $ProposalDir 'proposal.md')
    if ($null -eq $proposalText) {
        Add-Error $where 'proposal.md отсутствует'
        return
    }

    if ($proposalText -notmatch '(?im)^\s*[-*]?\s*\**\s*Status:?\**\s*Done\b') {
        Add-Error $where 'V-архив: отсутствует "Status: Done"'
    }

    $tasksText = Read-Text (Join-Path $ProposalDir 'tasks.md')
    if ($null -ne $tasksText) {
        $unchecked = [regex]::Matches($tasksText, '- \[ \]')
        if ($unchecked.Count -gt 0) {
            Add-Error $where "V-архив: остались незакрытые пункты ($($unchecked.Count))"
        }
    }

    # Дельты должны присутствовать в живых спецификациях. Для ЧИСТОГО ШАБЛОНА дельты примеров
    # набора осознанно перенесены в docs/legacy/set-history/specs/ (D-010: ничего не теряется,
    # но и не выдаётся за спецификацию продукта). Поэтому засчитываем оба места.
    $specsDir = Join-Path $ProposalDir 'specs'
    if (Test-Path -LiteralPath $specsDir) {
        $legacySpecsRoot = Join-Path $repoRoot 'docs/legacy/set-history/specs'
        foreach ($capDir in (Get-ChildItem -LiteralPath $specsDir -Directory)) {
            $liveSpec = Join-Path $specsRoot (Join-Path $capDir.Name 'spec.md')
            $legacySpec = Join-Path $legacySpecsRoot (Join-Path $capDir.Name 'spec.md')
            if (-not (Test-Path -LiteralPath $liveSpec) -and -not (Test-Path -LiteralPath $legacySpec)) {
                Add-Error $where "V-архив: дельта '$($capDir.Name)' не влита ни в openspec/specs/$($capDir.Name)/spec.md, ни в docs/legacy/set-history/specs/"
            }
        }
    }
}

# --- Проверка ссылок по всему репозиторию -------------------------------------------------
function Test-RepositoryLinks {
    $mdFiles = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.md' -File |
        Where-Object { $_.FullName -notmatch '\\artifacts\\|\\.git\\|\\node_modules\\' })

    foreach ($file in $mdFiles) {
        $text = Read-Text $file.FullName
        if ($null -eq $text) { continue }
        foreach ($m in [regex]::Matches(($text -replace '`[^`
]*', ''''), '\]\((?<link>[^)]+)\)')) {
            $link = $m.Groups['link'].Value.Trim()
            if ($link -match '^(https?:|mailto:|#)') { continue }
            $target = ($link -split '#')[0]
            if ([string]::IsNullOrWhiteSpace($target)) { continue }
            if ($target -match '[\x00-\x1f<>|"?*]') { continue }
            try {
                $resolved = Join-Path $file.DirectoryName $target
            } catch {
                continue
            }
            if (-not (Test-Path -LiteralPath $resolved)) {
                $rel = $file.FullName.Substring($repoRoot.Length + 1)
                Add-Error "$rel" "V6: битая ссылка '$link'"
            }
        }
    }
}

# --- Точка входа --------------------------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'One') {
    $resolved = if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $repoRoot $Path }
    if (-not (Test-Path -LiteralPath $resolved)) {
        Write-Host "FAIL: путь не найден: $resolved" -ForegroundColor Red
        exit 1
    }
    Test-Proposal -ProposalDir $resolved
}
elseif ($Archived) {
    $archiveDir = Join-Path $proposalsRoot 'archive'
    if (-not (Test-Path -LiteralPath $archiveDir)) {
        Write-Host 'FAIL: каталог archive/ не найден' -ForegroundColor Red
        exit 1
    }
    $archivedDirs = @(Get-ChildItem -LiteralPath $archiveDir -Directory)
    if ($archivedDirs.Count -eq 0) {
        Write-Host 'FAIL: archive/ пуст — цикл не замкнут (P0-4)' -ForegroundColor Red
        exit 1
    }
    foreach ($dir in $archivedDirs) { Test-ArchivedProposal -ProposalDir $dir.FullName }
}
else {
    # -All: активные предложения
    $active = @(Get-ChildItem -LiteralPath $proposalsRoot -Directory |
        Where-Object { $_.Name -ne 'archive' -and $_.Name -notmatch '^000-' })

    # Нет активных предложений — это НОРМА для чистого шаблона: все примеры в archive/.
    # Ошибкой было бы считать это провалом гейта.
    if ($active.Count -eq 0) {
        Write-Host 'INFO: активных предложений нет (примеры перенесены в archive/) — проверяются только ссылки и specs' -ForegroundColor Cyan
    }

    foreach ($dir in $active) { Test-Proposal -ProposalDir $dir.FullName }

    if ($CheckLinks) { Test-RepositoryLinks }

    # Живые спецификации не должны быть пустыми (G2).
    $liveSpecs = @()
    if (Test-Path -LiteralPath $specsRoot) {
        $liveSpecs = @(Get-ChildItem -LiteralPath $specsRoot -Recurse -Filter 'spec.md' -File)
    }
    if ($liveSpecs.Count -eq 0) {
        Add-Warning 'openspec/specs' 'G2: specs/ пуст — это норма для чистого шаблона (спецификации набора перенесены в docs/legacy/set-history/). После первого архивного предложения каталог наполнится'
    }
}

# --- Вывод результата ---------------------------------------------------------------------
Write-Host ''
foreach ($w in $script:warnings) {
    Write-Host "WARN  $w" -ForegroundColor Yellow
}
foreach ($e in $script:errors) {
    Write-Host "FAIL  $e" -ForegroundColor Red
}

Write-Host ''
if ($script:errors.Count -gt 0) {
    Write-Host "ИТОГ: ПРОВАЛ — ошибок: $($script:errors.Count), предупреждений: $($script:warnings.Count)" -ForegroundColor Red
    exit 1
}

Write-Host "ИТОГ: УСПЕХ — предложений проверено, ошибок: 0, предупреждений: $($script:warnings.Count)" -ForegroundColor Green
exit 0
