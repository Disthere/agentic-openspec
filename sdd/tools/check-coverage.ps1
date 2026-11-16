#requires -Version 5.1
<#
.SYNOPSIS
    Гейт покрытия: проверяет пороги из конституции по cobertura-отчёту.

.DESCRIPTION
    MTP поддерживает сбор покрытия (`--coverage --coverage-output-format cobertura`), но НЕ умеет
    задавать порог: флага `--coverage-threshold` в 17.14.2 нет. Поэтому порог из конституции §3
    («покрытие >80%, Domain >90%») не проверялся ничем — заявленное правило было невозможно провалить.

    Этот скрипт закрывает разрыв: читает cobertura XML и падает, если покрытие ниже порога.
    Пороги берутся из схемы активного профиля (`openspec/schemas/<profile>.yaml` →
    `tests.coverage_min_percent` / `coverage_min_percent_domain`), а не зашиты здесь.

.PARAMETER Report
    Путь к cobertura XML. Обязателен, если не задан -Probe.

.PARAMETER Probe
    Самотест: прогоняет проверки на встроенных синтетических отчётах и выходит с 0,
    если логика верна. Нужен, потому что реальный отчёт в CI появляется только после тестов,
    а сам гейт обязан быть проверяем независимо.

.PARAMETER Minimum
    Переопределить общий порог (например, 80).

.PARAMETER MinimumDomain
    Переопределить порог для домена (например, 90).

.EXAMPLE
    ./tools/check-coverage.ps1 -Report artifacts/coverage.cobertura.xml

.EXAMPLE
    ./tools/check-coverage.ps1 -Probe
#>
[CmdletBinding(DefaultParameterSetName = 'Report')]
param(
    [Parameter(ParameterSetName = 'Report', Mandatory = $true)]
    [string]$Report,

    [Parameter(ParameterSetName = 'Probe', Mandatory = $true)]
    [switch]$Probe,

    [double]$Minimum = 0,
    [double]$MinimumDomain = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Раскладка: всё SDD живёт в `sdd/`, в корне проекта — только то, что инструменты
# ищут строго там (AGENTS.md, .clinerules, .agents/skills, global.json, Directory.*.props).
# Поэтому корней два: $sddRoot — каталог набора, $repoRoot — корень проекта.
$sddRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $sddRoot
# --- Пороги из схемы активного профиля ------------------------------------------------------
function Get-CoverageThresholds {
    $configPath = Join-Path $sddRoot 'openspec/config.yaml'
    $min = 80; $minDomain = 90      # значения конституции §3 как безопасный дефолт

    if (-not (Test-Path -LiteralPath $configPath)) { return @{ Min = $min; MinDomain = $minDomain } }

    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
    $m = [regex]::Match($config, '(?m)^\s+profile:\s*(?<p>[A-Za-z0-9_\-]+)')
    if (-not $m.Success) { return @{ Min = $min; MinDomain = $minDomain } }

    $schemaPath = Join-Path $repoRoot ("openspec/schemas/{0}.yaml" -f $m.Groups['p'].Value)
    if (-not (Test-Path -LiteralPath $schemaPath)) { return @{ Min = $min; MinDomain = $minDomain } }

    $schema = Get-Content -LiteralPath $schemaPath -Raw -Encoding UTF8
    $mm = [regex]::Match($schema, '(?m)^\s+coverage_min_percent:\s*(?<v>[\d.]+)')
    $md = [regex]::Match($schema, '(?m)^\s+coverage_min_percent_domain:\s*(?<v>[\d.]+)')
    if ($mm.Success) { $min = [double]$mm.Groups['v'].Value }
    if ($md.Success) { $minDomain = [double]$md.Groups['v'].Value }

    return @{ Min = $min; MinDomain = $minDomain }
}

# --- Разбор cobertura -----------------------------------------------------------------------
function Read-Cobertura {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "отчёт покрытия не найден: $Path"
    }
    [xml]$xml = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $node = $xml.coverage
    if ($null -eq $node) { throw "это не cobertura-отчёт: нет узла <coverage>" }

    $lineRate = 0.0
    if ($null -ne $node.'line-rate') { $lineRate = [double]::Parse($node.'line-rate', [cultureinfo]::InvariantCulture) }

    # Пакеты «домена»: имя содержит Domain (Clean Architecture: *.Domain, Project.Domain.*)
    $domainRates = @()
    if ($null -ne $node.packages -and $null -ne $node.packages.package) {
        foreach ($pkg in @($node.packages.package)) {
            $name = [string]$pkg.name
            if ($name -match '(?i)\.domain\b') {
                $r = 0.0
                if ($null -ne $pkg.'line-rate') { $r = [double]::Parse($pkg.'line-rate', [cultureinfo]::InvariantCulture) }
                $domainRates += $r
            }
        }
    }

    $domainRate = $null
    if (@($domainRates).Count -gt 0) {
        $domainRate = ($domainRates | Measure-Object -Average).Average
    }

    return [pscustomobject]@{
        LineRate   = $lineRate * 100
        DomainRate = if ($null -ne $domainRate) { $domainRate * 100 } else { $null }
        Packages   = if ($null -ne $node.packages) { @($node.packages.package).Count } else { 0 }
    }
}

# --- Проверка ------------------------------------------------------------------------------
function Test-Coverage {
    param([pscustomobject]$Data, [double]$Min, [double]$MinDomain, [string]$Where)

    $errors = [System.Collections.Generic.List[string]]::new()

    if ($Data.LineRate -lt $Min) {
        $errors.Add(("$Where : покрытие {0:N1}% ниже порога {1:N0}% (конституция §3)" -f $Data.LineRate, $Min))
    }
    if ($null -eq $Data.DomainRate) {
        # Домена может не быть в шаблоне (Smoke без Domain) — это предупреждение, не провал:
        # требовать Domain в продукте будет тест самого продукта, а не гейт набора.
        Write-Host ("WARN  $Where : сборок домена не найдено — порог Domain ({0:N0}%) не проверен" -f $MinDomain) -ForegroundColor Yellow
    }
    elseif ($Data.DomainRate -lt $MinDomain) {
        $errors.Add(("$Where : покрытие домена {0:N1}% ниже порога {1:N0}% (конституция §3)" -f $Data.DomainRate, $MinDomain))
    }
    return $errors
}

# --- Самотест ------------------------------------------------------------------------------
if ($Probe) {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cov-probe-" + [guid]::NewGuid().ToString('N') + '.xml')
    $failed = 0

    function New-CoberturaXml {
        param([double]$Rate, [string]$Pkg = 'App.Api', [double]$DomainRate = -1)
        $pkgs = "<package name=`"$Pkg`" line-rate=`"$Rate`" />"
        if ($DomainRate -ge 0) {
            $pkgs += "<package name=`"App.Domain`" line-rate=`"$DomainRate`" />"
        }
        return "<?xml version=`"1.0`"?><coverage line-rate=`"$Rate`"><packages>$pkgs</packages></coverage>"
    }

    function Run-Case {
        param([string]$Name, [string]$Xml, [double]$Min, [double]$MinDomain, [int]$WantFail)
        [System.IO.File]::WriteAllText($tmp, $Xml, (New-Object System.Text.UTF8Encoding($false)))
        $data = Read-Cobertura -Path $tmp
        # @() обязателен: пустой List при возврате из функции PowerShell разворачивает в $null,
        # а StrictMode запрещает брать .Count у $null.
        $errs = @(Test-Coverage -Data $data -Min $Min -MinDomain $MinDomain -Where 'probe')
        $failedNow = $errs.Count
        $ok = if ($failedNow -eq $WantFail) { 'OK  ' } else { 'BAD ' }
        Write-Host ("$ok $Name : провалов $failedNow (ожидалось $WantFail)")
        $errs | ForEach-Object { Write-Host "      $_" }
        if ($failedNow -ne $WantFail) { $script:failCount++ }
    }

    $script:failCount = 0
    try {
        Run-Case 'покрытие ниже порога (60% при 80%)' (New-CoberturaXml -Rate 0.60) 80 90 1
        Run-Case 'покрытие выше порога (85% при 80%)' (New-CoberturaXml -Rate 0.85) 80 90 0
        Run-Case 'ровно на пороге (80% при 80%)' (New-CoberturaXml -Rate 0.80) 80 90 0
        Run-Case 'домен ниже порога (85% общий, 70% домен)' (New-CoberturaXml -Rate 0.85 -DomainRate 0.70) 80 90 1
        Run-Case 'домен выше порога (95% домен)' (New-CoberturaXml -Rate 0.85 -DomainRate 0.95) 80 90 0
        Run-Case 'нет домена — только предупреждение' (New-CoberturaXml -Rate 0.85) 80 90 0
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }

    if ($script:failCount -gt 0) {
        Write-Host ("ИТОГ: ПРОВАЛ — самотест не пройден: {0} случаев" -f $script:failCount) -ForegroundColor Red
        exit 1
    }
    Write-Host 'ИТОГ: УСПЕХ — логика гейта покрытия верна' -ForegroundColor Green
    exit 0
}

# --- Основной режим ------------------------------------------------------------------------
$thresholds = Get-CoverageThresholds
if ($Minimum -gt 0) { $thresholds.Min = $Minimum }
if ($MinimumDomain -gt 0) { $thresholds.MinDomain = $MinimumDomain }

try {
    $data = Read-Cobertura -Path $Report
}
catch {
    Write-Host ("FAIL  {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

Write-Host ("отчёт: {0} (пакетов: {1})" -f $Report, $data.Packages)
Write-Host ("порогов: общий {0:N0}%, домен {1:N0}% (источник: схема активного профиля)" -f $thresholds.Min, $thresholds.MinDomain)

$errors = @(Test-Coverage -Data $data -Min $thresholds.Min -MinDomain $thresholds.MinDomain -Where 'coverage')
foreach ($e in $errors) { Write-Host ("FAIL  {0}" -f $e) -ForegroundColor Red }

Write-Host ''
if ($errors.Count -gt 0) {
    Write-Host ("ИТОГ: ПРОВАЛ — нарушений: {0}" -f $errors.Count) -ForegroundColor Red
    exit 1
}
Write-Host 'ИТОГ: УСПЕХ — покрытие в пределах порогов' -ForegroundColor Green
exit 0
