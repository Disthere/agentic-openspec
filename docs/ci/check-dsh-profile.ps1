#requires -Version 5.1
<#
.SYNOPSIS
    Проверка композиции DSH-профиля (PLAN.md, задача 2.6).

.DESCRIPTION
    Ловит регресс P0-9: пресет роли без инструментов. Скрипт поднимает изолированный DSH_HOME
    (иначе profile-boot падает EPERM на живом профиле), ставит профиль scaffolds и проверяет
    по --dump-config, что у каждого пресета роли достаточно плагинов и непустой список пресетов
    для делегирования.

    Критерий из плана (G3): у пресета роли >= 8 плагинов, включая tool-fs, tool-pwsh,
    skill-filesystem, agent-instructions.

.PARAMETER MinPlugins
    Минимальное число плагинов у пресета роли. По умолчанию 8 (PLAN.md §6).

.PARAMETER DshPath
    Путь к dsh.cmd. По умолчанию — установленный DeepSeek Harness.

.EXAMPLE
    ./docs/ci/check-dsh-profile.ps1

.EXAMPLE
    ./docs/ci/check-dsh-profile.ps1 -MinPlugins 8 -Verbose
#>
[CmdletBinding()]
param(
    [int]$MinPlugins = 8,
    [string]$DshPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Запуск дочернего скрипта тем же хостом PowerShell (Windows: powershell, Linux: pwsh) ----
function Invoke-PwshScript {
    param([string]$ScriptPath)
    $hostExe = if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh' } else { Join-Path $PSHOME 'powershell.exe' }
    if (-not (Test-Path -LiteralPath $hostExe)) { $hostExe = 'pwsh' }
    & $hostExe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
}
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
# D-016 (гейт D-02(A)): роль доставляется ОДНИМ пресетом `sdd` с полной композицией
# standard. Шесть пресетов-ролей удалены — у них в plugins была только персона (P0-9).
$rolePresets = @('preset-sdd')

# Легаси-пресеты ролей: если они вернулись в конфигурацию — это регресс P0-9.
$legacyRolePresets = @(
    'preset-analyst'
    'preset-architect'
    'preset-csharp-dev'
    'preset-qa-engineer'
    'preset-reviewer'
    'preset-ops-release'
)

# Плагины, без которых роль не может работать (P0-9, P0-11).
$requiredPlugins = @('tool-fs', 'tool-pwsh', 'skill-filesystem', 'agent-instructions')

if (-not $DshPath) {
    $candidate = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\resources\runtime\cli\bin\dsh.cmd'
    if (-not (Test-Path -LiteralPath $candidate)) {
        Write-Host "SKIP: dsh.cmd не найден ($candidate) — проверка композиции невозможна" -ForegroundColor Yellow
        exit 0
    }
    $DshPath = $candidate
}

$tempHome = Join-Path ([System.IO.Path]::GetTempPath()) ("dsh-profile-check-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $tempHome | Out-Null

try {
    $originalHome = $env:DSH_HOME
    $env:DSH_HOME = $tempHome

    # install.ps1 ставит профиль scaffolds в изолированный DSH_HOME.
    $installer = Join-Path $repoRoot 'dsh/install.ps1'
    if (Test-Path -LiteralPath $installer) {
        Invoke-PwshScript -ScriptPath $installer *> $null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "FAIL: dsh/install.ps1 завершился с кодом $LASTEXITCODE" -ForegroundColor Red
            exit 1
        }
    }

    $dump = & $DshPath --profile agentic-openspec --dump-config 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAIL: --dump-config завершился с кодом $LASTEXITCODE" -ForegroundColor Red
        Write-Host $dump
        exit 1
    }

    $lines = $dump -split "`r?`n"
    $stats = @{}
    $currentPreset = $null
    $inPlugins = $false
    $pluginNames = @{}

    foreach ($line in $lines) {
        if ($line -match '^- id: (preset-[a-z0-9-]+)\s*$') {
            $currentPreset = $matches[1]
            $stats[$currentPreset] = 0
            $pluginNames[$currentPreset] = [System.Collections.Generic.List[string]]::new()
            $inPlugins = $false
            continue
        }
        if ($null -eq $currentPreset) { continue }

        if ($line -match '^    plugins:\s*$') { $inPlugins = $true; continue }
        if ($inPlugins -and $line -match '^\S') { $inPlugins = $false; continue }
        if (-not $inPlugins) { continue }

        if ($line -match "^      - (?:id|name): '?([^']+)'?\s*$") {
            $stats[$currentPreset] = $stats[$currentPreset] + 1
            $pluginNames[$currentPreset].Add($matches[1])
        }
    }

    $failed = 0
    foreach ($preset in $rolePresets) {
        if (-not $stats.ContainsKey($preset)) {
            Write-Host "FAIL  $preset : пресет отсутствует в dump-config" -ForegroundColor Red
            $failed++
            continue
        }

        $count = $stats[$preset]
        if ($count -lt $MinPlugins) {
            Write-Host "FAIL  $preset : плагинов $count, ожидалось >= $MinPlugins (P0-9)" -ForegroundColor Red
            $failed++
            continue
        }

        $names = $pluginNames[$preset] -join ' '
        $missing = @()
        foreach ($required in $requiredPlugins) {
            if ($names -notmatch [regex]::Escape($required)) { $missing += $required }
        }
        if ($missing.Count -gt 0) {
            Write-Host "FAIL  $preset : плагинов $count, но нет: $($missing -join ', ')" -ForegroundColor Red
            $failed++
            continue
        }

        Write-Host "OK    $preset : плагинов $count, обязательные на месте" -ForegroundColor Green
    }

    # Регресс: шесть тонких пресетов ролей не должны вернуться (P0-9).
    foreach ($legacy in $legacyRolePresets) {
        if ($stats.ContainsKey($legacy)) {
            Write-Host "FAIL  $legacy : легаси-пресет роли вернулся в конфигурацию (D-016, P0-9)" -ForegroundColor Red
            $failed++
        }
    }

    # Дефолт реестра — нейтральный `standard` (D-018 / D-07(A)), не персона роли.
    if ($dump -match '(?m)^\s*default:\s*(\S+)\s*$') {
        $defaultPreset = $matches[1]
        if ($defaultPreset -ne 'standard') {
            Write-Host "FAIL  agent-preset-registry.default = '$defaultPreset', ожидалось 'standard' (D-018)" -ForegroundColor Red
            $failed++
        }
        else {
            Write-Host 'OK    agent-preset-registry.default = standard (D-018)' -ForegroundColor Green
        }
    }

    # Делегирование (P0-10). Проверяем НЕ просто наличие строки, а что allowlist стоит на
    # правильном плагине ВНУТРИ пресета роли: по README @deepseek-ai/dsh-tool-subagent поле
    # allowedAgentPresets относится именно к нему. Установка его на tool-subagent-control
    # ломает загрузку пресета в приложении («Не удалось загрузить пользовательский пресет») —
    # так и случилось 2026-11-12.
    #
    # Важно: в дереве есть и другие tool-subagent (из preset-standard и др.), поэтому
    # проверяем блок именно нашего пресета, а не первое совпадение по файлу.
    $presetStart = [regex]::Match($dump, '(?m)^- id: preset-sdd\s*$')
    if (-not $presetStart.Success) {
        Write-Host 'FAIL  пресет preset-sdd не найден в дереве' -ForegroundColor Red
        $failed++
    }
    else {
        $fromPreset = $dump.Substring($presetStart.Index)
        $nextPreset = [regex]::Match($fromPreset.Substring(1), '(?m)^- id: preset-')
        $presetBlock = if ($nextPreset.Success) {
            $fromPreset.Substring(0, $nextPreset.Index + 1)
        } else {
            $fromPreset
        }

        $subagentBlock = [regex]::Match($presetBlock, '(?ms)^\s*- id: tool-subagent\s*\n(.*?)(?=^\s*- id: |\z)')
        if (-not $subagentBlock.Success) {
            Write-Host 'FAIL  в preset-sdd нет tool-subagent — делегирование не сконфигурировано (P0-10)' -ForegroundColor Red
            $failed++
        }
        else {
            $block = $subagentBlock.Groups[1].Value
            if ($block -notmatch 'allowedAgentPresets') {
                Write-Host 'FAIL  у tool-subagent в preset-sdd нет allowedAgentPresets — модель не адресует роль (P0-10)' -ForegroundColor Red
                $failed++
            }
            else {
                Write-Host 'OK    allowedAgentPresets стоит на tool-subagent внутри preset-sdd' -ForegroundColor Green
            }
            if ($block -notmatch 'agentPreset:') {
                Write-Host 'WARN  у tool-subagent нет agentPreset — субагент не получит пресет роли по умолчанию' -ForegroundColor Yellow
            }
        }

        # Антирегресс: allowlist НЕ должен стоять на tool-subagent-control внутри пресета.
        $controlBlock = [regex]::Match($presetBlock, '(?ms)^\s*- id: tool-subagent-control\s*\n(.*?)(?=^\s*- id: |\z)')
        if ($controlBlock.Success -and $controlBlock.Groups[1].Value -match 'allowedAgentPresets') {
            Write-Host 'FAIL  allowedAgentPresets стоит на tool-subagent-control — это ломает загрузку пресета' -ForegroundColor Red
            $failed++
        }
    }

    if ($failed -gt 0) {
        Write-Host ''
        Write-Host "ИТОГ: ПРОВАЛ — пресетов с дефектом: $failed" -ForegroundColor Red
        exit 1
    }

    # --- Детектор стейл-кэша запущенного приложения (найдено на живой проверке G3) ----------
    # Приложение читает бандл при старте. Если файл новее процесса, в UI будет СТАРАЯ картина
    # (например, шесть легаси-пресетов вместо sdd), хотя диск чист. Предупреждаем явно,
    # чтобы это не приняли за регресс P0-9.
    $bundlePatch = Join-Path $repoRoot 'dsh/presets-bundle/cordis.patch.yml'
    if (Test-Path -LiteralPath $bundlePatch) {
        $bundleTime = (Get-Item -LiteralPath $bundlePatch).LastWriteTime
        $appProcess = Get-Process -Name 'DeepSeek Harness' -ErrorAction SilentlyContinue |
            Sort-Object StartTime | Select-Object -First 1
        if ($null -ne $appProcess -and $appProcess.StartTime -lt $bundleTime) {
            Write-Host ''
            Write-Host 'WARN  запущенное приложение старше файла бандла — UI покажет устаревший набор пресетов' -ForegroundColor Yellow
            Write-Host ("      приложение: {0:yyyy-MM-dd HH:mm:ss} | бандл: {1:yyyy-MM-dd HH:mm:ss}" -f $appProcess.StartTime, $bundleTime) -ForegroundColor Yellow
            Write-Host '      диск чист; перезапустите DeepSeek Harness, чтобы приложение перечитало бандл.' -ForegroundColor Yellow
        }
    }

    Write-Host ''
    Write-Host "ИТОГ: УСПЕХ — все $($rolePresets.Count) пресетов ролей имеют >= $MinPlugins плагинов" -ForegroundColor Green
    exit 0
}
finally {
    if (Test-Path -LiteralPath $tempHome) {
        Remove-Item -LiteralPath $tempHome -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $originalHome) { $env:DSH_HOME = $originalHome }
}
