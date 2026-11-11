# Installs the "agentic-openspec" DSH profile into $DSH_HOME/profiles/<name>.
# Run:  powershell -ExecutionPolicy Bypass -File .\dsh\install.ps1
#
# NOTE: keep this file pure ASCII. Windows PowerShell 5.1 reads a .ps1 file as ANSI
# when it has no BOM, and non-ASCII characters inside strings break the parser.
#
# Решение D-017 (гейт D-03(A) плана): ЕДИНСТВЕННЫЙ источник персон и пресета роли —
# presets-bundle/cordis.patch.yml. Каталог profile/ — тонкая обёртка: только scaffolding
# (cordis.yml + package.json), без копий персон. Патч профиля ПРОИЗВОДИТСЯ из бандла
# при установке, поэтому двух расходящихся копий персон не существует (P1-11).
#
# Решение D-016 (гейт D-02(A)): роль доставляется одним пресетом `sdd` с полной
# композицией standard (22 плагина). Раньше шесть пресетов-ролей имели в plugins
# ровно одну персону и не давали агенту ни одного инструмента (P0-9).
$ErrorActionPreference = 'Stop'

$name    = 'agentic-openspec'
$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
$profile = Join-Path $PSScriptRoot 'profile'
$bundle  = Join-Path $PSScriptRoot 'presets-bundle'
$dst     = Join-Path $dshHome "profiles\$name"

if (-not (Test-Path -LiteralPath $profile)) { throw "Profile scaffolding not found: $profile" }
if (-not (Test-Path -LiteralPath $bundle))  { throw "Presets bundle not found: $bundle" }

$bundlePatch = Join-Path $bundle 'cordis.patch.yml'
if (-not (Test-Path -LiteralPath $bundlePatch)) { throw "Bundle patch not found: $bundlePatch" }

New-Item -ItemType Directory -Force -Path $dst | Out-Null

# --- Backup before overwrite (PLAN.md, задача 3.14 / P1-16) -------------------
# The Electron app writes to the SAME cordis.patch.yml (ui-settings-general,
# welcomeNoticeVersion). Overwriting it silently loses UI settings, so any target
# that differs from what we are about to write is copied to .bak-<timestamp> first.
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$plan = @(
    @{ Source = $bundlePatch;                                  Dest = (Join-Path $dst 'cordis.patch.yml') },
    @{ Source = (Join-Path $profile 'cordis.yml');             Dest = (Join-Path $dst 'cordis.yml') },
    @{ Source = (Join-Path $profile 'package.json');           Dest = (Join-Path $dst 'package.json') }
)

foreach ($item in $plan) {
    if (-not (Test-Path -LiteralPath $item.Source)) { continue }
    if (-not (Test-Path -LiteralPath $item.Dest)) { continue }

    $same = $false
    try {
        $same = (Get-FileHash -LiteralPath $item.Source -Algorithm SHA256).Hash -eq `
                (Get-FileHash -LiteralPath $item.Dest -Algorithm SHA256).Hash
    }
    catch { $same = $false }

    if (-not $same) {
        $backup = "$($item.Dest).bak-$timestamp"
        Copy-Item -LiteralPath $item.Dest -Destination $backup -Force
        Write-Host "BACKUP $($item.Dest) -> $backup" -ForegroundColor Yellow
    }
}

# --- Install: scaffolding from profile/, patch derived from the bundle ---------
foreach ($item in $plan) {
    if (-not (Test-Path -LiteralPath $item.Source)) { continue }
    Copy-Item -LiteralPath $item.Source -Destination $item.Dest -Force
}

Write-Host "OK  Profile installed: $dst" -ForegroundColor Green
Write-Host ''

# The dsh CLI ships inside the Desktop app and is not on PATH by default.
$cli = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\resources\runtime\cli\bin\dsh.cmd'

Write-Host 'Next:' -ForegroundColor Cyan
if (Test-Path -LiteralPath $cli) {
    Write-Host "  CLI:    $cli"
    Write-Host "  Verify: $cli --profile $name --dump-config"
    Write-Host "  Boot:   $cli --profile $name"
} else {
    Write-Host '  dsh CLI not found at the default Desktop location:'
    Write-Host "    $cli"
    Write-Host '  Boot the profile from the Desktop app instead.'
}
Write-Host '  The "desktop" profile is owned by the Electron app: the CLI refuses to dump it.'
Write-Host '  Provider/model: routerai / deepseek/deepseek-v4.1-flash (see presets-bundle/cordis.patch.yml).'
Write-Host '  The routerai API key is read from the ROUTERAI_API_KEY environment variable.'
Write-Host '  Default preset: standard (neutral, D-018). Pick "sdd" in the UI to work as an SDD role.'
