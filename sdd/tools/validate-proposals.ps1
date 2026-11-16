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
    [switch]$CheckLinks,

    # Проверка шаблонов 000-*: их ссылки обязаны быть верны ПОСЛЕ копирования в <NNN-slug>/.
    # В обычном -All шаблоны исключены (это не предложения), но именно они — первый файл,
    # который трогает новый пользователь, поэтому проверяются отдельным режимом и в CI.
    [Parameter(ParameterSetName = 'Templates', Mandatory = $true)]
    [switch]$Templates
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Корень репозитория: на уровень выше tools/ -------------------------------------------
# Раскладка: всё SDD живёт в `sdd/`, в корне проекта — только то, что инструменты
# ищут строго там (AGENTS.md, .clinerules, .agents/skills, global.json, Directory.*.props).
# Поэтому корней два: $sddRoot — каталог набора, $repoRoot — корень проекта.
$sddRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $sddRoot
$proposalsRoot = Join-Path $sddRoot 'openspec/proposals'
$specsRoot = Join-Path $sddRoot 'openspec/specs'

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

# --- Минимальный YAML-ридер -----------------------------------------------------------------
# Зачем свой: схемы (`openspec/schemas/*.yaml`) и `openspec/config.yaml` — источник истины о том,
# какие разделы обязательны и каков формат задач. Модуля powershell-yaml в наборе нет, а
# хардкодить списки разделов в скрипте — ровно дефект N-6: валидатор игнорировал
# `project.profile`, и предложение, верное для десктопной схемы, отклонялось.
#
# Поддерживается подмножество, которое реально есть в этих файлах:
#   `key: value`, `key:` + вложенный блок, `- scalar`, `- key: value`, комментарии `#`.
# Чего нет: якорей, `|`/`>`-скаляров, flow-коллекций. Если нужный ключ не прочитался,
# это сообщается явно (см. Get-ActiveSchema) — молчаливого «прочиталось пусто» не будет.

function ConvertTo-YamlScalar {
    param([string]$Raw)

    $v = $Raw.Trim()
    if ($v -eq '') { return '' }

    # Двойные кавычки: снимаем и разэкранируем \\ и \" (YAML-escape).
    if ($v -match '^"(?<b>.*)"$') {
        $b = $matches['b']
        $b = $b.Replace('\\', '[BSLASH]')
        $b = $b.Replace('\"', '"')
        $b = $b.Replace('[BSLASH]', '\')
        return $b
    }
    if ($v -match "^'(?<b>.*)'$") {
        return ($matches['b'] -replace "''", "'")
    }
    return $v
}

function Read-YamlBlock {
    param($State, [int]$ParentIndent)

    $map = [ordered]@{}
    while ($State.Pos -lt $State.Entries.Count) {
        $e = $State.Entries[$State.Pos]
        if ($e.Indent -le $ParentIndent) { break }

        # Список: "- ..." на одном отступе
        if ($e.Body.Length -gt 0 -and $e.Body[0] -eq '-') {
            $listIndent = $e.Indent
            $list = [System.Collections.Generic.List[object]]::new()
            while ($State.Pos -lt $State.Entries.Count) {
                $le = $State.Entries[$State.Pos]
                if ($le.Indent -ne $listIndent) { break }
                if ($le.Body.Length -eq 0 -or $le.Body[0] -ne '-') { break }

                $itemBody = $le.Body.Substring(1).Trim()
                $State.Pos++

                $kv = [regex]::Match($itemBody, '^(?<k>[A-Za-z0-9_.\-]+):\s*(?<v>.*)$')
                if ($kv.Success) {
                    $sub = [ordered]@{}
                    $sub[$kv.Groups['k'].Value] = ConvertTo-YamlScalar $kv.Groups['v'].Value
                    $mapIndent = $listIndent + 2
                    while ($State.Pos -lt $State.Entries.Count) {
                        $ne = $State.Entries[$State.Pos]
                        if ($ne.Indent -ne $mapIndent) { break }
                        $nkv = [regex]::Match($ne.Body, '^(?<k>[A-Za-z0-9_.\-]+):\s*(?<v>.*)$')
                        if (-not $nkv.Success) { break }
                        $sub[$nkv.Groups['k'].Value] = ConvertTo-YamlScalar $nkv.Groups['v'].Value
                        $State.Pos++
                    }
                    $list.Add($sub)
                }
                else {
                    $list.Add((ConvertTo-YamlScalar $itemBody))
                }
            }
            return ,$list
        }

        $km = [regex]::Match($e.Body, '^(?<k>[A-Za-z0-9_.\-]+):\s*(?<v>.*)$')
        if (-not $km.Success) { $State.Pos++; continue }

        $key = $km.Groups['k'].Value
        $rest = $km.Groups['v'].Value
        $State.Pos++
        if ($rest -eq '') { $map[$key] = Read-YamlBlock -State $State -ParentIndent $e.Indent }
        else { $map[$key] = ConvertTo-YamlScalar $rest }
    }
    return $map
}

function ConvertFrom-SimpleYaml {
    param([string]$Text)

    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($rawLine in ($Text -split "`r?`n")) {
        if ($rawLine -match '^\s*$') { continue }

        # Снимаем комментарий вне кавычек.
        $line = $rawLine
        $inS = $false; $inD = $false
        for ($i = 0; $i -lt $line.Length; $i++) {
            $ch = $line[$i]
            if ($ch -eq "'" -and -not $inD) { $inS = -not $inS }
            elseif ($ch -eq '"' -and -not $inS) { $inD = -not $inD }
            elseif ($ch -eq '#' -and -not $inS -and -not $inD -and
                    ($i -eq 0 -or $line[$i - 1] -match '\s')) {
                $line = $line.Substring(0, $i)
                break
            }
        }
        if ($line -match '^\s*$') { continue }

        $indent = $line.Length - $line.TrimStart().Length
        $entries.Add([pscustomobject]@{ Indent = $indent; Body = $line.Trim() })
    }

    $state = @{ Pos = 0; Entries = $entries }
    return Read-YamlBlock -State $state -ParentIndent -1
}

function Read-YamlFile {
    param([string]$FilePath)
    $text = Read-Text $FilePath
    if ($null -eq $text) { return $null }
    return ConvertFrom-SimpleYaml -Text $text
}

# --- Разбор markdown-ссылок ----------------------------------------------------------------
# Раньше здесь стояло `($text -replace '`[^`\n]*', "''")`: класс исключал закрывающий бэктик,
# поэтому матч обрывался ПЕРЕД ним, а сам бэктик стартовал новый матч и стирал остаток строки.
# Следствие (находка аудита N-2): любая ссылка после inline-кода в строке не проверялась вовсе —
# в живых документах это сотни ссылок, включая реально битые.
#
# Теперь inline-код удаляется только вместе с ЗАКРЫВАЮЩИМ бэктиком и только в пределах строки
# (`(?m)` + точка без \n), а блоки кода вырезаются отдельно: ссылки внутри примеров — не ссылки.

function Remove-CodeFromMarkdown {
    param([string]$Text)

    # 1. Блоки кода (``` ... ``` и ~~~ ... ~~~) — построчно, чтобы не зависеть от жадности.
    $sb = New-Object System.Text.StringBuilder
    $inFence = $false
    foreach ($line in ($Text -split "`r?`n")) {
        if ($line -match '^\s*(```|~~~)') {
            $inFence = -not $inFence
            [void]$sb.AppendLine('')
            continue
        }
        if ($inFence) { [void]$sb.AppendLine('') } else { [void]$sb.AppendLine($line) }
    }
    $body = $sb.ToString()

    # 2. Inline-код: пара бэктиков с непустым содержимым, точка не переходит через перевод строки.
    #    Двойные бэктики (``a`b``) обрабатываем первыми — иначе внутренний бэктик ломает парность.
    $body = [regex]::Replace($body, '(?m)``[^`]*?``', ' ')
    $body = [regex]::Replace($body, '(?m)`[^`\r\n]+`', ' ')
    return $body
}

function Get-MarkdownLinks {
    param([string]$Text)

    # Code spans/fences убраны; ищем [текст](цель). Скобки в тексте ссылки допускаются.
    $clean = Remove-CodeFromMarkdown -Text $Text
    $pattern = '\[(?<text>(?:[^\[\]]|\[[^\[\]]*\])*)\]\((?<link>[^()\s]*(?:\([^()]*\)[^()\s]*)*)\)'
    foreach ($m in [regex]::Matches($clean, $pattern)) {
        $link = $m.Groups['link'].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($link)) { continue }
        [pscustomobject]@{ Text = $m.Groups['text'].Value; Link = $link }
    }
}

# Область проверки ссылок: живые документы. `docs/legacy/` — замороженная история набора, её ссылки
# устарели намеренно (D-010: ничего не удаляется, оригинал остаётся указателем на старую структуру);
# `openspec/proposals/archive/` — архивные предложения, которые не редактируются (guardrail);
# `docs/session/` — рабочая тетрадь, не коммитится.
function Test-LinkScopeExcluded {
    param([string]$FullName)

    # Приводим разделители к '/' — иначе фильтр работает только на Windows, а CI гоняется
    # на ubuntu: там legacy-история не исключилась бы, и гейт упал бы на её устаревших ссылках.
    $p = $FullName -replace '\\', '/'

    # Шаблоны 000-*.md исключены намеренно: их ссылки написаны для места КОПИРОВАНИЯ
    # (<NNN-slug>/), поэтому «на месте» они выглядят битыми. Их проверяет отдельный режим
    # `-Templates`, который симулирует копию — см. Test-ProposalTemplates.
    $isTemplate = ($p -match '/openspec/proposals/000-[^/]+\.md$')

    return ($p -match '/docs/legacy/' -or
            $p -match '/openspec/proposals/archive/' -or
            $p -match '/docs/session/' -or
            $p -match '/artifacts/|/\.git/|/node_modules/' -or
            $isTemplate)
}

# --- Схема активного профиля ---------------------------------------------------------------
# N-6: раньше списки разделов были захардкожены здесь, поэтому `project.profile` ни на что не
# влиял, а `csharp-desktop.yaml` (где `API / Contract Changes` — optional) не исполнялся:
# предложение, верное для десктопной схемы, отклонялось с «отсутствует обязательный раздел».
#
# Теперь источник истины — файл схемы. Значения по умолчанию сохранены ровно на случай, если
# схема не найдена или повреждена: тогда гейт честно падает с явной ошибкой, а не подставляет
# молча другой профиль.

$script:defaultRequiredSections = @(
    'Context'
    'Requirements'
    'C# Implementation Plan'
    'API / Contract Changes'
    'Test Strategy'
    'Capabilities'
    'Impact'
    'Changelog'
)

function Get-ActiveSchema {
    param([string]$Where = 'schema')

    $configPath = Join-Path $sddRoot 'openspec/config.yaml'
    $schema = [pscustomobject]@{
        Source            = 'built-in fallback'
        Profile           = 'unknown'
        RequiredSections  = $script:defaultRequiredSections
        OptionalSections  = @()
        SectionPattern    = '^##\s+\d+\.\s+.+'
        ItemPattern       = '^\s*-\s+\[[ xX]\]\s+\d+\.\d+\s+.+'
        Found             = $false
    }

    $config = $null
    try { $config = Read-YamlFile $configPath } catch { $config = $null }
    if ($null -eq $config -or $null -eq $config['project']) {
        Add-Error $Where 'не удалось прочитать openspec/config.yaml — активный профиль неизвестен'
        return $schema
    }

    $profile = [string]$config['project']['profile']
    if ([string]::IsNullOrWhiteSpace($profile)) {
        Add-Error $Where 'openspec/config.yaml: не задан project.profile'
        return $schema
    }
    $schema.Profile = $profile

    # Путь схемы: schemas/<profile>.yaml (соглашение, зафиксированное в config.yaml → schemas).
    $schemaPath = Join-Path $sddRoot ("openspec/schemas/{0}.yaml" -f $profile)
    if (-not (Test-Path -LiteralPath $schemaPath)) {
        Add-Error $Where "нет файла схемы для активного профиля '$profile' (ожидался sdd/openspec/schemas/$profile.yaml)"
        return $schema
    }

    $doc = $null
    try { $doc = Read-YamlFile $schemaPath } catch { $doc = $null }
    if ($null -eq $doc) {
        Add-Error $Where "не удалось разобрать схему '$profile'"
        return $schema
    }

    $req = @($doc['required_sections'] | Where-Object { $_ -ne '' })
    if ($req.Count -eq 0) {
        Add-Error $Where "схема '$profile' не содержит required_sections — проверять нечего"
        return $schema
    }

    $schema.RequiredSections = $req
    $schema.OptionalSections = @($doc['optional_sections'] | Where-Object { $_ -ne '' })
    # N-D: `required_files:` объявлен в обеих схемах, но не исполнялся — V8 держал хардкод.
    $schema | Add-Member -NotePropertyName RequiredFiles -NotePropertyValue (@($doc['required_files'] | Where-Object { $_ -ne '' })) -Force
    $schema.Found = $true
    $schema.Source = "openspec/schemas/$profile.yaml"

    if ($null -ne $doc['tasks']) {
        if ($doc['tasks']['section_pattern']) { $schema.SectionPattern = [string]$doc['tasks']['section_pattern'] }
        if ($doc['tasks']['item_pattern'])    { $schema.ItemPattern    = [string]$doc['tasks']['item_pattern'] }
    }

    return $schema
}

function Get-LiteSchema {
    param([string]$Where = 'schema')

    # Лёгкий маршрут описан отдельной схемой (config.yaml → schemas.lite).
    $config = $null
    try { $config = Read-YamlFile (Join-Path $sddRoot 'openspec/config.yaml') } catch { $config = $null }
    $liteFile = if ($config -and $config['schemas'] -and $config['schemas']['lite']) {
        [string]$config['schemas']['lite']
    } else { 'lite.yaml' }
    if ($liteFile -notmatch '\.ya?ml$') { $liteFile = "$liteFile.yaml" }

    $path = Join-Path $sddRoot ("openspec/schemas/{0}" -f $liteFile)
    $schema = $null
    try { $schema = Read-YamlFile $path } catch { $schema = $null }

    $result = [pscustomobject]@{
        Source           = "openspec/schemas/$liteFile"
        RequiredSections = @('Context', 'Change', 'Test Strategy', 'Impact', 'Changelog')
        SectionPattern   = '^##\s+\d+\.\s+.+'
        ItemPattern      = '^\s*-\s+\[[ xX]\]\s+\d+\.\d+\s+.+'
        Found            = $false
    }
    if ($null -eq $schema) {
        Add-Error $Where "не удалось прочитать схему lite ('openspec/schemas/$liteFile')"
        return $result
    }
    $req = @($schema['required_sections'] | Where-Object { $_ -ne '' })
    if ($req.Count -gt 0) { $result.RequiredSections = $req }
    if ($null -ne $schema['tasks']) {
        if ($schema['tasks']['section_pattern']) { $result.SectionPattern = [string]$schema['tasks']['section_pattern'] }
        if ($schema['tasks']['item_pattern'])    { $result.ItemPattern    = [string]$schema['tasks']['item_pattern'] }
    }
    $result.Found = $true
    return $result
}

function Test-ProposalSections {
    param([string]$ProposalPath, [string]$Where)

    $text = Read-Text $ProposalPath
    if ($null -eq $text) {
        Add-Error $Where 'proposal.md отсутствует'
        return
    }

    # Лёгкий маршрут: `skip_specs: true` в шапке переключает набор обязательных разделов (D-020).
    $isLite = $text -match '(?im)^\s*[-*]?\s*\**\s*skip_specs:?\**\s*true'
    $schema = if ($isLite) { Get-LiteSchema -Where $Where } else { Get-ActiveSchema -Where $Where }
    $sections = @($schema.RequiredSections)
    if ($isLite) { Write-Verbose "$Where : lite-маршрут (skip_specs: true), схема $($schema.Source)" }
    else { Write-Verbose "$Where : профиль $($schema.Profile), схема $($schema.Source)" }

    foreach ($section in $sections) {
        # Раздел ищется как '## <Section>' в любом регистре.
        $pattern = '(?im)^##\s+' + [regex]::Escape($section) + '\s*$'
        if ($text -notmatch $pattern) {
            Add-Error $Where "V1: отсутствует обязательный раздел '## $section'"
        }
    }

    # V11: Status: Approved требует подписи.
    # Проверяется ДО раннего выхода для lite: иначе `skip_specs: true` обходил проверку
    # подписи, и предложение могло быть помечено Approved без человека (находка аудита N-8).
    #
    # Значение проверяется по существу, а не по факту «там что-то есть»: плейсхолдеры шаблона
    # (`<человек, не агент>`, `<YYYY-MM-DD>`) подписью не считаются. Без этого правило обходилось
    # копированием шаблона: поля есть, человека нет (найдено регресс-тестом той же правки).
    if ($text -match '(?im)^\s*[-*]?\s*\**\s*Status:?\**\s*Approved\b') {
        $approvedBy = [regex]::Match($text, '(?im)^\s*[-*]?\s*\**\s*Approved by:?\**\s*(?<v>.+)$')
        $approvedAt = [regex]::Match($text, '(?im)^\s*[-*]?\s*\**\s*Approved at:?\**\s*(?<v>.+)$')

        $placeholder = '^\s*<[^>]*>\s*$'   # целиком плейсхолдер шаблона
        $byValue = if ($approvedBy.Success) { ($approvedBy.Groups['v'].Value -replace '<!--.*$', '').Trim() } else { '' }
        $atValue = if ($approvedAt.Success) { ($approvedAt.Groups['v'].Value -replace '<!--.*$', '').Trim() } else { '' }

        if ([string]::IsNullOrWhiteSpace($byValue) -or $byValue -match $placeholder -or
            $byValue -match '(?i)^(агент|agent|tbd|todo|xxx+)\.?$') {
            Add-Error $Where 'V11: Status: Approved без "Approved by:" (нужно имя человека, не плейсхолдер)'
        }
        if ([string]::IsNullOrWhiteSpace($atValue) -or $atValue -match $placeholder -or
            $atValue -notmatch '^\d{4}-\d{2}-\d{2}$') {
            Add-Error $Where 'V11: Status: Approved без "Approved at:" (нужна дата YYYY-MM-DD, не плейсхолдер)'
        }
    }

    # V12: пороги маршрута lite проверяются машиной (находка N-C / N-9).
    # Раньше `config.yaml → schemas.lite_thresholds` (`max_files: 2`, `max_changed_lines: 50`)
    # не читал никто: предложение на 160 строк с заявленными 40 файлами проходило с exit 0,
    # а схема `lite.yaml` утверждала, будто порог «проверяется валидатором как предупреждение».
    # Правило держалось на честности. Теперь считается то, что объявлено в самом предложении.
    if ($isLite) {
        $liteThresholds = $null
        try {
            $cfgText = Read-Text (Join-Path $sddRoot 'openspec/config.yaml')
            if ($null -ne $cfgText) {
                $maxFilesM = [regex]::Match($cfgText, '(?m)^\s+max_files:\s*(?<v>\d+)')
                $maxLinesM = [regex]::Match($cfgText, '(?m)^\s+max_changed_lines:\s*(?<v>\d+)')
                if ($maxFilesM.Success -or $maxLinesM.Success) {
                    $liteThresholds = [pscustomobject]@{
                        MaxFiles = if ($maxFilesM.Success) { [int]$maxFilesM.Groups['v'].Value } else { 2 }
                        MaxLines = if ($maxLinesM.Success) { [int]$maxLinesM.Groups['v'].Value } else { 50 }
                        Declared = $false
                    }
                }
            }
        }
        catch { $liteThresholds = $null }

        if ($null -eq $liteThresholds) {
            Add-Warning $Where 'V12: пороги lite не найдены в config.yaml → schemas.lite_thresholds — применимость маршрута не проверена'
        }
        else {
            # Явное объявление объёма: `Changed files: N` / `Changed lines: N` (регистр и оформление свободны).
            $cfM = [regex]::Match($text, '(?im)^\s*[-*]?\s*\**\s*(?:changed[_ ]files|файлов)\s*:?\**\s*(?<v>\d+)')
            $clM = [regex]::Match($text, '(?im)^\s*[-*]?\s*\**\s*(?:changed[_ ]lines|строк)\s*:?\**\s*(?<v>\d+)')

            if ($cfM.Success) {
                $cf = [int]$cfM.Groups['v'].Value
                if ($cf -gt $liteThresholds.MaxFiles) {
                    Add-Warning $Where ("V12: lite заявлен на {0} файлов при пороге {1} — маршрут неприменим (AGENTS.md §2, D-020)" -f $cf, $liteThresholds.MaxFiles)
                }
            }
            if ($clM.Success) {
                $cl = [int]$clM.Groups['v'].Value
                if ($cl -gt $liteThresholds.MaxLines) {
                    Add-Warning $Where ("V12: lite заявлен на {0} строк при пороге {1} — маршрут неприменим (AGENTS.md §2, D-020)" -f $cl, $liteThresholds.MaxLines)
                }
            }
            if (-not $cfM.Success -and -not $clM.Success) {
                Add-Warning $Where 'V12: lite без объявленного объёма ("Changed files:" / "Changed lines:") — применимость проверить нечем'
            }
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

    # V10: [NEEDS CLARIFICATION] должен иметь парный OQ-N, и этот OQ-N должен СУЩЕСТВОВАТЬ.
    # Раньше `$oqBlock` читался и тут же выбрасывался (`if ($null -eq $oqBlock) { continue }` —
    # единственное использование переменной), поэтому проверялось лишь наличие подстроки `OQ-N`
    # рядом с маркером. Вопрос, на который нет записи в реестре, для процесса не существует
    # (конституция §1 п. 5), а гейт это пропускал (находка N-E).
    $clarifications = [regex]::Matches($text, '\[NEEDS CLARIFICATION[^\]]*\]')
    if ($clarifications.Count -gt 0) {
        $oqBlock = Read-Text (Join-Path $sddRoot 'OPEN_QUESTIONS.md')
        $knownOq = @()
        if ($null -ne $oqBlock) {
            $knownOq = @([regex]::Matches($oqBlock, '(?m)^\s*\|\s*(?<id>OQ-\d+)\s*\|') |
                ForEach-Object { $_.Groups['id'].Value })
        }

        foreach ($m in $clarifications) {
            $context = Get-SurroundingText -Text $text -Index $m.Index -Radius 200
            if ($context -notmatch 'OQ-\d+') {
                Add-Error $Where "V10: '[NEEDS CLARIFICATION]' без OQ-N рядом: '$($m.Value)'"
                continue
            }

            # Каждый упомянутый рядом OQ-N обязан быть в реестре.
            foreach ($oq in [regex]::Matches($context, 'OQ-\d+')) {
                $id = $oq.Value
                if ($knownOq -notcontains $id) {
                    Add-Error $Where "V10: '$id' упомянут рядом с '[NEEDS CLARIFICATION]', но отсутствует в OPEN_QUESTIONS.md"
                }
            }
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
# Паттерны берутся из схемы (tasks.section_pattern / tasks.item_pattern), а не из констант:
# так формат задач следует за профилем и за маршрутом lite, и схема перестаёт быть декоративной.
function Test-TasksFormat {
    param([string]$TasksPath, [string]$Where, $Schema = $null)

    $text = Read-Text $TasksPath
    if ($null -eq $text) {
        Add-Error $Where 'tasks.md отсутствует'
        return
    }

    if ($null -eq $Schema) { $Schema = Get-ActiveSchema -Where $Where }
    $sectionRx = $Schema.SectionPattern
    $itemRx    = $Schema.ItemPattern
    if ([string]::IsNullOrWhiteSpace($sectionRx)) { $sectionRx = '^##\s+\d+\.\s+.+' }
    if ([string]::IsNullOrWhiteSpace($itemRx))    { $itemRx    = '^\s*-\s+\[[ xX]\]\s+\d+\.\d+\s+.+' }

    $lines = $text -split "`r?`n"
    $sectionCount = 0
    $itemCount = 0
    $badItems = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match $sectionRx) { $sectionCount++; continue }

        # Пункт задачи: "- [ ] 1.1 ..." или "- [x] 1.1 ..." — форма из схемы.
        if ($line -match '^\s*-\s+\[[ xX]\]') {
            if ($line -match $itemRx) { $itemCount++ }
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

    # N-7: раньше отсутствие дельты было только предупреждением, поэтому Spec First держался на
    # честности: предложение с требованиями проходило гейт без единой спецификации. Для
    # утверждённого предложения (Status: Approved) это уже не «недоделка», а разрыв конституции
    # §1 п. 3 (трассируемость): человек утвердил требования, которых нет в specs/.
    # Для черновика предупреждение сохраняется — на этапе Draft дельта может ещё не быть.
    $isApproved = $proposalText -match '(?im)^\s*[-*]?\s*\**\s*Status:?\**\s*Approved\b'
    $missingDeltaIsBlocking = $isApproved

    $specsDir = Join-Path $ProposalDir 'specs'
    if (-not (Test-Path -LiteralPath $specsDir)) {
        if ($proposalIds.Count -gt 0) {
            $msg = 'V5: есть требования, но каталог specs/ отсутствует (дельта не сформирована)'
            if ($missingDeltaIsBlocking) {
                Add-Error $Where "$msg — для Status: Approved это блокирует (конституция §1 п. 3)"
            }
            else { Add-Warning $Where $msg }
        }
        return
    }

    $specFiles = @(Get-ChildItem -LiteralPath $specsDir -Recurse -Filter 'spec.md' -File)
    if ($specFiles.Count -eq 0) {
        $msg = 'V5: каталог specs/ есть, но spec.md не найден'
        if ($missingDeltaIsBlocking -and $proposalIds.Count -gt 0) {
            Add-Error $Where "$msg — для Status: Approved это блокирует (конституция §1 п. 3)"
        }
        else { Add-Warning $Where $msg }
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

    # N-F: архивные предложения (`proposals/archive/`) по guardrail не редактируются, поэтому их
    # устаревшие ссылки — ожидаемое состояние, а не дефект. Общий скан это учитывает
    # (Test-LinkScopeExcluded), но `-Path <архивное>` шёл сюда напрямую и давал 7 ложных V6.
    # Проверка на архив должна быть одна и та же во всех режимах.
    if ((($File -replace '\\', '/') -match '/openspec/proposals/archive/')) {
        Write-Verbose "V6: $File — архив, ссылки не проверяются (guardrail)"
        return
    }

    $text = Read-Text $File
    if ($null -eq $text) { return }

    foreach ($m in @(Get-MarkdownLinks -Text $text)) {
        $link = $m.Link
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
    param([string]$ProposalDir, [string]$Where, $Schema)

    # N-D: список обязательных файлов берётся из СХЕМЫ активного профиля (`required_files:`),
    # если он там объявлен. Раньше здесь стоял хардкод трёх файлов, и ключ `required_files`
    # в обеих схемах был объявлен, но не исполнялся: допишите в схему `design.md` — гейт
    # этого не заметит, схема останется декоративной. Дефолт сохраняется на случай схемы
    # без ключа (обратная совместимость со старыми профилями).
    $requiredFiles = @('proposal.md', 'tasks.md', 'acceptance.md')
    if ($null -ne $Schema -and $null -ne $Schema.PSObject.Properties['RequiredFiles'] -and
        $null -ne $Schema.RequiredFiles -and @($Schema.RequiredFiles).Count -gt 0) {
        $requiredFiles = @($Schema.RequiredFiles)
    }

    foreach ($required in $requiredFiles) {
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

    # Схема определяется один раз и передаётся дальше: V1 (разделы), V7 (формат задач) и V5
    # (дельта specs/) обязаны смотреть на один и тот же профиль — иначе проверки расходятся.
    $schema = Get-ActiveSchema -Where $where

    Test-RequiredFiles -ProposalDir $ProposalDir -Where $where -Schema $schema
    Test-ProposalSections -ProposalPath (Join-Path $ProposalDir 'proposal.md') -Where $where
    Test-TasksFormat -TasksPath (Join-Path $ProposalDir 'tasks.md') -Where $where -Schema $schema
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
        $legacySpecsRoot = Join-Path $sddRoot 'docs/legacy/set-history/specs'
        foreach ($capDir in (Get-ChildItem -LiteralPath $specsDir -Directory)) {
            $liveSpec = Join-Path $specsRoot (Join-Path $capDir.Name 'spec.md')
            $legacySpec = Join-Path $legacySpecsRoot (Join-Path $capDir.Name 'spec.md')
            if (-not (Test-Path -LiteralPath $liveSpec) -and -not (Test-Path -LiteralPath $legacySpec)) {
                Add-Error $where "V-архив: дельта '$($capDir.Name)' не влита ни в openspec/specs/$($capDir.Name)/spec.md, ни в docs/legacy/set-history/specs/"
            }
        }
    }

    # --- V-архив: Review gate оставил артефакт ------------------------------------------------
    # Конституция §3 п. 4 и §7 требуют для фазы Review АРТЕФАКТ — вердикт ревью с `VERDICT: Pass`.
    # На реальном кейсе (DeliveryServisePilot, 2026-11-16) ревью прошло десять проходов, находки
    # были закрыты, но файла вердикта не осталось: STATUS.md утверждал "Review Pass", acceptance.md —
    # "вердикт не выносился", а гейт этого не видел, потому что проверял только чекбоксы, статус
    # и дельту. Доказательство фазы — файл, а не упоминание в CHANGELOG.
    #
    # Форма: любой `*.md` в каталоге предложения (обычно `review.md`), содержащий первую строку
    # вида `VERDICT: Pass` — контракт из скилла `code-review`. Ищем по всему тексту, но требуем,
    # чтобы Pass не был частью меню вариантов (`Pass / Fail`) — так же, как в проверке приёмки.
    $reviewFile = $null
    $reviewVerdict = $null
    foreach ($md in @(Get-ChildItem -LiteralPath $ProposalDir -Filter '*.md' -File)) {
        if ($md.Name -in @('proposal.md', 'tasks.md', 'acceptance.md', 'performance.md')) { continue }
        $mdText = Read-Text $md.FullName
        if ($null -eq $mdText) { continue }
        $vm = [regex]::Match($mdText, '(?im)^\s*\**\s*VERDICT:\s*(?<v>Pass|Fail)\b')
        if ($vm.Success) {
            $reviewFile = $md.Name
            $reviewVerdict = $vm.Groups['v'].Value
            break
        }
    }

    if ($null -eq $reviewVerdict) {
        # Обратная совместимость: старые предложения набора (до введения гейта) вердикта не имели.
        # Их история заморожена (D-010), поэтому для них — предупреждение; для любых НОВЫХ
        # архивных предложений это ошибка: гейт вводится с этого момента.
        if ($name -match '^(2026-11-09|2026-11-10)-') {
            Add-Warning $where 'V-архив: артефакт вердикта ревью (VERDICT: Pass|Fail) не найден — для замороженной истории допустимо, для новых предложений это блокер'
        }
        else {
            Add-Error $where 'V-архив: нет артефакта вердикта ревью — нужен `*.md` с первой строкой `VERDICT: Pass|Fail` (конституция §3 п. 4, §7 фаза Review)'
        }
    }
    elseif ($reviewVerdict -ne 'Pass') {
        Add-Error $where "V-архив: вердикт ревью '$reviewVerdict' в $reviewFile — в архив уходит только 'Pass'"
    }
    else {
        Write-Verbose "$where : вердикт ревью Pass найден в $reviewFile"
    }
}

# --- Проверка ссылок по всему репозиторию -------------------------------------------------
function Test-RepositoryLinks {
    # Область сканирования: `*.md` плюс файлы правил без расширения `.md`, которые агентные
    # инструменты читают как разметку. Раньше здесь стоял только `-Filter '*.md'`, поэтому
    # `.clinerules` (зеркало правил в корне) был СТРУКТУРНО невидим для гейта ссылок: после
    # переноса в `sdd/` в нём осталось 10 мёртвых ссылок, а гейт рапортовал успех (находка N-A).
    # `check-canon-parity` ссылки не резолвит, так что этот файл не проверял никто.
    $extraRuleFiles = @(
        (Join-Path $repoRoot '.clinerules')
    )

    $mdFiles = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.md' -File |
        Where-Object { -not (Test-LinkScopeExcluded -FullName $_.FullName) })

    # `-Force` обязателен: на Linux имена, начинающиеся с точки, считаются скрытыми, и
    # `Get-Item -LiteralPath` без `-Force` их не находит — `Could not find item .../.clinerules`.
    # На Windows этого не видно (там скрытость задаётся атрибутом, а не именем), поэтому регресс
    # поймал только CI на ubuntu.
    $ruleFiles = @($extraRuleFiles | Where-Object {
        $p = $_ -replace '\\', '/'
        (Test-Path -LiteralPath $_) -and
        -not ($p -match '/docs/legacy/' -or $p -match '/proposals/archive/' -or $p -match '/docs/session/')
    } | ForEach-Object { Get-Item -LiteralPath $_ -Force })

    $filesToScan = @($mdFiles) + @($ruleFiles)

    $checked = 0
    $links = 0
    foreach ($file in $filesToScan) {
        $text = Read-Text $file.FullName
        if ($null -eq $text) { continue }
        $checked++
        foreach ($m in @(Get-MarkdownLinks -Text $text)) {
            $link = $m.Link
            if ($link -match '^(https?:|mailto:|#)') { continue }
            $target = ($link -split '#')[0]
            if ([string]::IsNullOrWhiteSpace($target)) { continue }
            if ($target -match '[\x00-\x1f<>|"?*]') { continue }
            $links++
            try {
                $resolved = Join-Path $file.DirectoryName $target
            } catch {
                continue
            }
            if (-not (Test-Path -LiteralPath $resolved)) {
                $rel = $file.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/'
                Add-Error "$rel" "V6: битая ссылка '$link'"
            }
        }
    }
    Write-Verbose "ссылки: проверено файлов $checked, ссылок $links"
}

# --- Проверка шаблонов 000-* ---------------------------------------------------------------
# Шаблон — файл, который КОПИРУЮТ в <NNN-slug>/. Значит, относительные ссылки в нём обязаны
# быть верны на один уровень глубже, чем он лежит. Раньше они были верны «на своём месте»,
# и после копирования 13 ссылок указывали в пустоту: первый же шаг нового пользователя
# давал 11 FAIL на ссылках, которые он не ломал. Обычный -All шаблоны не проверяет
# (он исключает ^000-), поэтому дефект жил незамеченным.
function Test-ProposalTemplates {
    $templates = @(Get-ChildItem -LiteralPath $proposalsRoot -Filter '000-*.md' -File)
    if ($templates.Count -eq 0) {
        Add-Error 'templates' 'в openspec/proposals/ нет ни одного шаблона 000-*.md'
        return
    }

    # Симуляция места копирования: <proposals>/000-probe-copy/
    $copyDir = Join-Path $proposalsRoot '000-probe-copy'
    foreach ($tpl in $templates) {
        $where = "templates/$($tpl.Name)"
        $links = @(Get-MarkdownLinks -Text (Read-Text $tpl.FullName))
        if ($links.Count -eq 0) {
            Add-Warning $where 'шаблон не содержит ни одной ссылки — проверять нечего'
            continue
        }

        foreach ($m in $links) {
            $link = $m.Link
            if ($link -match '^(https?:|mailto:|#)') { continue }
            $target = ($link -split '#')[0]
            if ([string]::IsNullOrWhiteSpace($target)) { continue }
            if ($target -match '[\x00-\x1f<>|"?*]') { continue }

            # Ссылка разрешается от каталога, КУДА шаблон скопируют.
            $resolved = Join-Path $copyDir $target
            if (-not (Test-Path -LiteralPath $resolved)) {
                Add-Error $where "V6-шаблон: ссылка '$link' не резолвится после копирования в <NNN-slug>/ (искали: $resolved)"
            }
        }
    }
}

# --- Точка входа --------------------------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'Templates') {
    Test-ProposalTemplates
}
elseif ($PSCmdlet.ParameterSetName -eq 'One') {    $resolved = if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $repoRoot $Path }
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
