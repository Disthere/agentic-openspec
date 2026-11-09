# Устанавливает профиль «agentic-openspec» в $DSH_HOME/profiles/<name>.
# Запуск:  powershell -ExecutionPolicy Bypass -File .\dsh\install.ps1
$ErrorActionPreference = 'Stop'

$name  = 'agentic-openspec'
$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }
$src   = Join-Path $PSScriptRoot 'profile'
$dst   = Join-Path $dshHome "profiles\$name"

if (-not (Test-Path -LiteralPath $src)) { throw "Не найден каталог профиля: $src" }

New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force

Write-Host "OK  Профиль установлен: $dst" -ForegroundColor Green
Write-Host ''
Write-Host 'Дальше:' -ForegroundColor Cyan
Write-Host "  npx @deepseek-ai/dsh --profile $name --dump-config   # проверить композицию"
Write-Host "  npx @deepseek-ai/dsh --profile $name                  # запустить (Web UI при --web-app)"
Write-Host "  npx @deepseek-ai/dsh web                              # штатный Web UI"
Write-Host "  npx @deepseek-ai/dsh --profile headless `"run the tests`"  # one-shot для CI"
Write-Host ''
Write-Host 'Модель: provider/model задаётся в cordis.patch.yml ИЛИ через Web UI: Settings -> Models' -ForegroundColor Yellow
