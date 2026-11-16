#requires -Version 5.1
<#
.SYNOPSIS
    Сверка канона (AGENTS.md) и зеркала (.clinerules) — PLAN.md, задача 4.4 / P0-2.

.DESCRIPTION
    Ловит расхождение, из-за которого правила живут только в одном из файлов. Проверяет
    «якорные» нормативные формулировки канона: для каждого пункта задан regex, который должен
    найтись в каноне, и проверяется, что зеркало либо содержит тот же якорь, либо явно
    ссылается на канон (тогда дублирование не требуется).

    Дополнительно:
      * запрещает упоминания другого оркестратора (Cline) в нормативной роли;
      * требует, чтобы командные строки не дублировались руками в зеркале, а шли ссылкой.

.EXAMPLE
    ./tools/check-canon-parity.ps1

.EXAMPLE
    ./tools/check-canon-parity.ps1 -Verbose
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$canonPath = Join-Path $repoRoot 'AGENTS.md'
$mirrorPath = Join-Path $repoRoot '.clinerules'

$errors = [System.Collections.Generic.List[string]]::new()

function Read-Utf8 {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

$canon = Read-Utf8 $canonPath
$mirror = Read-Utf8 $mirrorPath

if ($null -eq $canon) {
    Write-Host "FAIL  канон не найден: $canonPath" -ForegroundColor Red
    exit 1
}
if ($null -eq $mirror) {
    Write-Host "FAIL  зеркало не найдено: $mirrorPath" -ForegroundColor Red
    exit 1
}

# --- Якорные нормативные пункты канона ----------------------------------------------------
# Проверка идёт в одну сторону, и это осознанно: канон обязан содержать каждый пункт — если
# пункт пропал из AGENTS.md, зеркало ссылается в пустоту. Обратное направление проверяется
# отдельно и структурно (ниже), а не по наличию слова в файле.
$anchors = @(
    @{ Id = 'spec-first';        Canon = 'Spec First' }
    @{ Id = 'dotnet-cli';        Canon = 'dotnet CLI|dotnet restore' }
    @{ Id = 'net10';             Canon = 'net10\.0|\.NET 10' }
    @{ Id = 'nullable';          Canon = 'Nullable|nullable' }
    @{ Id = 'warnings-as-errors'; Canon = 'TreatWarningsAsErrors|warnings as errors' }
    @{ Id = 'xunit';             Canon = 'xUnit' }
    @{ Id = 'delegation';        Canon = 'Оркестратор|delegat' }
    @{ Id = 'preset-sdd';        Canon = 'sdd' }
    @{ Id = 'archive-guard';     Canon = 'archive/\*\*|proposals/archive' }
    @{ Id = 'secrets';           Canon = 'секрет|ROUTERAI_API_KEY' }
    @{ Id = 'inputs';            Canon = 'inputs/' }
    @{ Id = 'standards';         Canon = 'openspec/standards' }
)

foreach ($anchor in $anchors) {
    if ($canon -notmatch $anchor.Canon) {
        $errors.Add("канон AGENTS.md не содержит нормативный пункт '$($anchor.Id)' (regex: $($anchor.Canon))")
    }
    else {
        Write-Verbose "пункт '$($anchor.Id)': присутствует в каноне"
    }
}

# --- Зеркало: маршрутный лист, а не копия (обратное направление) ---------------------------
# Раньше здесь стояло `$mirror -match $anchor.Href` — «упоминание нужного файла где угодно в
# файле». Из-за этого засчитывалась любая строка со словом «AGENTS.md», включая строку 4, где
# сказано, что DSH этот файл НЕ читает: два якоря (nullable, warnings-as-errors) проходили,
# хотя правил в зеркале нет. И, главное, правило, добавленное ТОЛЬКО в зеркало, гейт не ловил
# вовсе — он печатал «правила не живут только в зеркале» (находка аудита N-1).
#
# Новая проверка смотрит на структуру, а не на слова. Зеркало — это маршрутный лист: каждая
# его содержательная единица (абзац, пункт списка, строка таблицы) обязана содержать ссылку,
# то есть маршрут к источнику истины. Единица без ссылки = правило, живущее только в зеркале.

function Get-MirrorUnits {
    param([string[]]$Lines, [int]$FromLine = 0)

    $units = [System.Collections.Generic.List[object]]::new()
    $i = $FromLine
    $inFence = $false
    while ($i -lt $Lines.Count) {
        $line = $Lines[$i]
        if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; $i++; continue }
        if ($inFence) { $i++; continue }
        if ([string]::IsNullOrWhiteSpace($line)) { $i++; continue }
        if ($line -match '^\s*#') { $i++; continue }      # заголовок — не правило
        if ($line -match '^\s*>') { $i++; continue }      # цитата — обоснование, не правило

        $kind = if ($line -match '^\s*\|') { 'table' }
                elseif ($line -match '^\s*([-*+]|\d+\.)\s') { 'item' }
                else { 'paragraph' }

        $start = $i + 1
        $buf = [System.Collections.Generic.List[string]]::new()
        $buf.Add($line)
        $i++
        while ($i -lt $Lines.Count) {
            $nxt = $Lines[$i]
            if ([string]::IsNullOrWhiteSpace($nxt)) { break }
            if ($nxt -match '^\s*#') { break }
            if ($kind -eq 'table' -and $nxt -notmatch '^\s*\|') { break }
            if ($kind -eq 'item' -and $nxt -match '^\s*([-*+]|\d+\.)\s') { break }
            if ($kind -eq 'paragraph' -and $nxt -match '^\s*\||^\s*([-*+]|\d+\.)\s') { break }
            $buf.Add($nxt.Trim())
            $i++
        }
        $units.Add([pscustomobject]@{ Kind = $kind; Line = $start; Text = ($buf -join ' ') })
    }
    return $units
}

$mirrorLinesArr = @($mirror -split "`r?`n")

# 1. Глобальный указатель: зеркало обязано сказать, где канон.
$hasPointer = $false
foreach ($line in $mirrorLinesArr) {
    if ($line -match '\]\(\.?/?AGENTS\.md\)' -and $line -match '(?i)канон') { $hasPointer = $true; break }
}
if (-not $hasPointer) {
    $errors.Add('зеркало .clinerules не содержит явного указателя «канон — AGENTS.md»')
}

# 2. Каждая содержательная единица должна указывать маршрут.
#    Преамбула (до первого заголовка) — описание самого файла и его читателей, а не правило;
#    она проверяется отдельно выше (наличие указателя на канон).
$firstHeading = 0
for ($i = 0; $i -lt $mirrorLinesArr.Count; $i++) {
    if ($mirrorLinesArr[$i] -match '^\s*##') { $firstHeading = $i; break }
}

$unlinked = 0
foreach ($unit in @(Get-MirrorUnits -Lines $mirrorLinesArr -FromLine $firstHeading)) {
    if ($unit.Kind -eq 'table' -and $unit.Text -match '^\s*\|[\s:\-|]+\|\s*$') { continue }  # разделитель
    if ($unit.Text -notmatch '\]\(') {
        $unlinked++
        $preview = $unit.Text
        if ($preview.Length -gt 110) { $preview = $preview.Substring(0, 110) + '…' }
        $errors.Add("зеркало .clinerules: строка $($unit.Line) ($($unit.Kind)) без ссылки — правило живёт только в зеркале: $preview")
    }
}
if ($unlinked -eq 0) {
    Write-Verbose 'все содержательные единицы зеркала содержат ссылку на источник'
}

# --- Другой оркестратор не должен быть нормативным ----------------------------------------
$clineNormalized = [regex]::Matches($canon + $mirror, '(?i)Cline[^.\r\n]{0,60}(Оркестратор|orchestrator)')
foreach ($m in $clineNormalized) {
    $errors.Add("найден другой оркестратор в нормативной роли: '$($m.Value)'")
}

# --- Зеркало не должно переписывать команды гейта руками ----------------------------------
$commandPattern = 'dotnet build --configuration Release --no-restore'
if ($mirror -match [regex]::Escape($commandPattern)) {
    $errors.Add('зеркало .clinerules дублирует команды гейта: единственный источник — openspec/config.yaml → commands')
}

# --- Размеры: канон должен быть содержательным, зеркало — коротким -------------------------
$canonLines = ($canon -split "`r?`n").Count
$mirrorLines = ($mirror -split "`r?`n").Count

if ($canonLines -lt 120) {
    $errors.Add("канон AGENTS.md слишком короткий ($canonLines строк) — это снова фиктивный канон (P0-2)")
}
if ($mirrorLines -gt 80) {
    $errors.Add("зеркало .clinerules разрослось ($mirrorLines строк) — оно должно ссылаться, а не дублировать")
}

# --- Вывод --------------------------------------------------------------------------------
foreach ($e in $errors) {
    Write-Host "FAIL  $e" -ForegroundColor Red
}

Write-Host ''
Write-Host ("канон: {0} строк · зеркало: {1} строк" -f $canonLines, $mirrorLines)

if ($errors.Count -gt 0) {
    Write-Host ("ИТОГ: ПРОВАЛ — расхождений: {0}" -f $errors.Count) -ForegroundColor Red
    exit 1
}

Write-Host 'ИТОГ: УСПЕХ — канон и зеркало согласованы, правила не живут только в зеркале' -ForegroundColor Green
exit 0
