#requires -Version 5.1
<#
.SYNOPSIS
    Регистрирует входные материалы в inputs/INDEX.md — без ручного заполнения таблицы.

.DESCRIPTION
    Материал без записи в реестре для процесса не существует: Архитектор не может на него
    сослаться, Discovery-гейт не закрывается. Заполнять таблицу руками — механическая работа,
    значит её должен делать скрипт.

    Что делает:
      1. Сканирует inputs/ (все подкаталоги, кроме служебных).
      2. Читает уже зарегистрированные строки из INDEX.md.
      3. Для незарегистрированных файлов добавляет строки: ID (первый свободный IN-NNN),
         путь, тип (по каталогу), дата (по файлу), «Что задаёт» (первая содержательная строка
         файла или имя), статус, «Где учтён» = —.
      4. С -Rename приводит имя файла к конвенции IN-NNN-<slug>.<ext>.

    Режимы:
      по умолчанию — только показывает план, ничего не меняет;
      -Apply       — записывает изменения в INDEX.md (и переименовывает при -Rename);
      -Check       — проверка для гейта/CI: exit 1, если есть незарегистрированные файлы
                     или строки реестра без файла.

.PARAMETER Root
    Корень набора (по умолчанию — родитель tools/).

.PARAMETER Apply
    Записать изменения.

.PARAMETER Rename
    Переименовать файлы к конвенции IN-NNN-<slug>.<ext> (только вместе с -Apply).

.PARAMETER Status
    Статус для новых записей. По умолчанию '⏳ не разобран'.

.PARAMETER Check
    Режим проверки: ничего не меняет, exit 1 при проблемах.

.EXAMPLE
    ./tools/register-inputs.ps1
    Показать, что будет зарегистрировано.

.EXAMPLE
    ./tools/register-inputs.ps1 -Apply
    Зарегистрировать материалы.

.EXAMPLE
    ./tools/register-inputs.ps1 -Check
    Проверка для CI.
#>
[CmdletBinding()]
param(
    [string]$Root,
    [switch]$Apply,
    [switch]$Rename,
    [string]$Status = '⏳ не разобран',
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Root) { $Root = Split-Path -Parent $PSScriptRoot }
$inputsDir = Join-Path $Root 'inputs'
$indexPath = Join-Path $inputsDir 'INDEX.md'

if (-not (Test-Path -LiteralPath $inputsDir)) {
    Write-Host "FAIL: каталог inputs/ не найден: $inputsDir" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath $indexPath)) {
    Write-Host "FAIL: реестр не найден: $indexPath" -ForegroundColor Red
    exit 1
}

# Служебные файлы, которые не являются материалами.
$serviceFiles = @('README.md', 'INDEX.md', '.gitkeep')

# Тип материала по каталогу (расширяемо: можно добавить свои каталоги).
$typeByFolder = @{
    'briefs'   = 'ТЗ'
    'concepts' = 'концепция'
    'graphics' = 'макет'
    'samples'  = 'образец'
}

# --- Сбор файлов --------------------------------------------------------------------------
$files = @(Get-ChildItem -LiteralPath $inputsDir -Recurse -File |
    Where-Object { $serviceFiles -notcontains $_.Name })

# --- Чтение реестра -----------------------------------------------------------------------
$indexText = Get-Content -LiteralPath $indexPath -Raw -Encoding utf8

# Существующие ID в настоящей таблице реестра (до раздела «Пример заполнения»).
$exampleMarker = $indexText.IndexOf('## Пример заполнения')
$registryPart = if ($exampleMarker -gt 0) { $indexText.Substring(0, $exampleMarker) } else { $indexText }

$existingIds = @()
foreach ($m in [regex]::Matches($registryPart, '(?m)^\|\s*(IN-\d+)\s*\|')) {
    $existingIds += $m.Groups[1].Value
}

# Какие файлы уже упомянуты (по имени файла в строке реестра).
$registeredFiles = @()
foreach ($m in [regex]::Matches($registryPart, '(?m)^\|\s*IN-\d+\s*\|\s*`([^`]+)`')) {
    $registeredFiles += (Split-Path -Leaf $m.Groups[1].Value)
}

# --- Первая содержательная строка файла ---------------------------------------------------
function Get-Description {
    param([System.IO.FileInfo]$File)

    $ext = $File.Extension.ToLowerInvariant()
    if ($ext -in @('.md', '.txt', '.json', '.yaml', '.yml', '.csv')) {
        try {
            $lines = Get-Content -LiteralPath $File.FullName -TotalCount 40 -Encoding utf8 -ErrorAction Stop
            foreach ($line in $lines) {
                $t = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($t)) { continue }
                if ($t -match '^(---|#\s*$|\{|\}|\[|\])') { continue }
                # Убираем markdown-заголовок и обрамляющие решётки
                $t = $t -replace '^#+\s*', ''
                if ($t.Length -gt 110) { $t = $t.Substring(0, 107) + '...' }
                return $t
            }
        }
        catch { }
    }
    return ($File.BaseName -replace '^IN-\d+-', '' -replace '[-_]', ' ')
}

# --- Формирование новых записей -----------------------------------------------------------
function Get-NextId {
    param([int[]]$Used)
    $n = 1
    while ($true) {
        $candidate = 'IN-{0:D3}' -f $n
        if ($Used -notcontains $candidate) { return $candidate }
        $n++
    }
}

function ConvertTo-Slug {
    param([string]$Name)
    $s = $Name.ToLowerInvariant()
    $s = $s -replace '[^a-z0-9]+', '-'
    $s = $s.Trim('-')
    if ([string]::IsNullOrWhiteSpace($s)) { $s = 'material' }
    if ($s.Length -gt 40) { $s = $s.Substring(0, 40).Trim('-') }
    return $s
}

$usedIds = @($existingIds)
$planned = @()

foreach ($file in ($files | Sort-Object FullName)) {
    if ($registeredFiles -contains $file.Name) { continue }

    $newId = Get-NextId -Used $usedIds
    $usedIds += $newId

    $folder = Split-Path -Leaf (Split-Path -Parent $file.FullName)
    $type = if ($typeByFolder.ContainsKey($folder)) { $typeByFolder[$folder] } else { 'материал' }

    $relPath = $file.FullName.Substring($inputsDir.Length + 1) -replace '\\', '/'

    # Имя по конвенции: IN-NNN-<slug><ext>
    $newName = $null
    $newRelPath = $relPath
    if ($file.Name -notmatch '^IN-\d+-') {
        $slug = ConvertTo-Slug $file.BaseName
        $newName = "$newId-$slug$($file.Extension)"
        $newRelPath = (($relPath -replace '[^/]+$', '') + $newName)
    }

    $planned += [pscustomobject]@{
        Id          = $newId
        File        = $file
        RelPath     = $relPath
        NewRelPath  = $newRelPath
        NewName     = $newName
        Type        = $type
        Date        = $file.LastWriteTime.ToString('yyyy-MM-dd')
        Description = (Get-Description -File $file)
        Status      = $Status
    }
}

# --- Проверка: строки реестра без файла ---------------------------------------------------
$orphanRows = @()
foreach ($name in $registeredFiles) {
    $found = $false
    foreach ($f in $files) { if ($f.Name -eq $name) { $found = $true; break } }
    if (-not $found) { $orphanRows += $name }
}

# --- Режим проверки -----------------------------------------------------------------------
if ($Check) {
    $problems = 0
    if ($planned.Count -gt 0) {
        Write-Host ("FAIL  незарегистрированных материалов: {0}" -f $planned.Count) -ForegroundColor Red
        foreach ($p in $planned) {
            Write-Host ("      {0}  ({1})" -f $p.RelPath, $p.Id) -ForegroundColor Red
        }
        Write-Host '      Исправить: tools/register-inputs.ps1 -Apply'
        $problems += $planned.Count
    }
    if ($orphanRows.Count -gt 0) {
        Write-Host ("WARN  строк реестра без файла: {0}" -f $orphanRows.Count) -ForegroundColor Yellow
        foreach ($o in $orphanRows) { Write-Host "      $o" -ForegroundColor Yellow }
        Write-Host '      Материал мог быть переименован или помечен архивом — проверьте вручную.'
    }
    if ($problems -gt 0) {
        Write-Host ''
        Write-Host ("ИТОГ: ПРОВАЛ — нужно зарегистрировать {0} материал(ов)" -f $problems) -ForegroundColor Red
        exit 1
    }
    Write-Host ''
    Write-Host ("ИТОГ: УСПЕХ — все материалы зарегистрированы ({0} файл(ов))" -f $files.Count) -ForegroundColor Green
    exit 0
}

# --- Обычный режим / -Apply ---------------------------------------------------------------
if ($planned.Count -eq 0) {
    Write-Host ''
    Write-Host ("Все материалы зарегистрированы ({0} файл(ов))." -f $files.Count) -ForegroundColor Green
    exit 0
}

Write-Host ''
Write-Host ("Найдено незарегистрированных материалов: {0}" -f $planned.Count) -ForegroundColor Cyan
Write-Host ''
Write-Host '| ID | Файл | Тип | Дата | Что задаёт |'
Write-Host '| - | - | - | - | - |'
foreach ($p in $planned) {
    $shown = if ($p.NewName -and $Rename) { $p.NewRelPath } else { $p.RelPath }
    Write-Host ("| {0} | ``{1}`` | {2} | {3} | {4} |" -f $p.Id, $shown, $p.Type, $p.Date, $p.Description)
}
Write-Host ''

if ($orphanRows.Count -gt 0) {
    Write-Host ("ВНИМАНИЕ: строк реестра без файла: {0} — {1}" -f $orphanRows.Count, ($orphanRows -join ', ')) -ForegroundColor Yellow
    Write-Host ''
}

if (-not $Apply) {
    Write-Host 'Это план. Ничего не изменено. Применить: -Apply' -ForegroundColor Yellow
    if (-not $Rename) {
        Write-Host 'Файлы не будут переименованы. Добавьте -Rename, чтобы привести имена к IN-NNN-<slug>.<ext>.' -ForegroundColor Yellow
    }
    exit 0
}

# --- Запись: переименование (если просили) ------------------------------------------------
if ($Rename) {
    foreach ($p in $planned) {
        if (-not $p.NewName) { continue }
        $target = Join-Path (Split-Path -Parent $p.File.FullName) $p.NewName
        Move-Item -LiteralPath $p.File.FullName -Destination $target -Force
        Write-Host ("RENAME {0} -> {1}" -f $p.RelPath, $p.NewName) -ForegroundColor Yellow
    }
}

# --- Запись: строки в реестр --------------------------------------------------------------
$rows = @()
foreach ($p in $planned) {
    $shown = if ($p.NewName -and $Rename) { $p.NewRelPath } else { $p.RelPath }
    $rows += ('| {0} | `{1}` | {2} | {3} | {4} | {5} | — |' -f $p.Id, $shown, $p.Type, $p.Date, $p.Description, $p.Status)
}

$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $indexPath -Encoding utf8)

# Находим таблицу реестра: строка-шапка "| ID | Файл |" до раздела Пример.
$headerIdx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\|\s*ID\s*\|\s*Файл\s*\|') { $headerIdx = $i; break }
}
if ($headerIdx -lt 0) {
    Write-Host 'FAIL: не найдена таблица реестра (строка "| ID | Файл | ...")' -ForegroundColor Red
    exit 1
}

# Плейсхолдер "пока пусто" убираем.
$removedPlaceholder = $false
for ($i = $headerIdx; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'пока пусто') { $lines.RemoveAt($i); $removedPlaceholder = $true; break }
    if ($lines[$i] -match '^##\s') { break }
}

# Последняя строка таблицы (после шапки и разделителя), куда дописываем.
$lastRow = $headerIdx + 1
for ($i = $headerIdx + 2; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\|') { $lastRow = $i } else { break }
}

for ($k = 0; $k -lt $rows.Count; $k++) {
    $lines.Insert($lastRow + 1 + $k, $rows[$k])
}

[System.IO.File]::WriteAllLines($indexPath, $lines, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host ("OK  зарегистрировано в inputs/INDEX.md: {0}" -f $rows.Count) -ForegroundColor Green
if ($removedPlaceholder) { Write-Host '    (строка-плейсхолдер «пока пусто» удалена)' -ForegroundColor Green }
Write-Host ''
Write-Host 'Дальше: Аналитик разбирает материалы и меняет статус на «🔎 в разборе» -> «✅ учтён».' -ForegroundColor Cyan
exit 0
