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
# Каждый пункт: что проверяем и как оно опознаётся. Зеркало может не дублировать текст,
# если оно ссылается на канон — тогда достаточно наличия ссылки.
$anchors = @(
    @{ Id = 'spec-first';        Canon = 'Spec First';                     Href = 'AGENTS\.md' }
    @{ Id = 'dotnet-cli';        Canon = 'dotnet CLI|dotnet restore';       Href = 'AGENTS\.md|config\.yaml' }
    @{ Id = 'net10';             Canon = 'net10\.0|\.NET 10';               Href = 'AGENTS\.md|DECISIONS\.md' }
    @{ Id = 'nullable';          Canon = 'Nullable|nullable';               Href = 'AGENTS\.md' }
    @{ Id = 'warnings-as-errors'; Canon = 'TreatWarningsAsErrors|warnings as errors'; Href = 'AGENTS\.md' }
    @{ Id = 'xunit';             Canon = 'xUnit';                          Href = 'AGENTS\.md' }
    @{ Id = 'delegation';        Canon = 'Оркестратор|delegat';             Href = 'AGENTS\.md|\.agents' }
    @{ Id = 'preset-sdd';        Canon = 'sdd';                            Href = 'AGENTS\.md|presets-bundle' }
    @{ Id = 'archive-guard';     Canon = 'archive/\*\*|proposals/archive';  Href = 'AGENTS\.md' }
    @{ Id = 'secrets';           Canon = 'секрет|ROUTERAI_API_KEY';          Href = 'AGENTS\.md' }
    @{ Id = 'inputs';            Canon = 'inputs/';                        Href = 'AGENTS\.md' }
    @{ Id = 'standards';         Canon = 'openspec/standards';              Href = 'AGENTS\.md' }
)

foreach ($anchor in $anchors) {
    $inCanon = $canon -match $anchor.Canon
    if (-not $inCanon) {
        $errors.Add("канон AGENTS.md не содержит нормативный пункт '$($anchor.Id)' (regex: $($anchor.Canon))")
        continue
    }

    $inMirror = $mirror -match $anchor.Canon
    $mirrorPointsToCanon = $mirror -match $anchor.Href

    if (-not $inMirror -and -not $mirrorPointsToCanon) {
        $errors.Add("пункт '$($anchor.Id)' есть в каноне, но зеркало .clinerules ни не содержит его, ни ссылается на источник")
    }
    elseif ($inMirror) {
        Write-Verbose "пункт '$($anchor.Id)': продублирован в зеркале"
    }
    else {
        Write-Verbose "пункт '$($anchor.Id)': зеркало ссылается на источник"
    }
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
