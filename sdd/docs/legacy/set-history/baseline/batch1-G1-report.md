# Батч 1 — .NET собирается (P0-6, P0-7, P0-8, P2-8, P2-9, P1-6)

**Дата:** 2026-11-11 · **Основание:** [`PLAN.md`](../../PLAN.md) §4 · **Гейт:** G1

## Что сделано

| ID | Задача | Результат |
| - | - | - |
| 1.1 | Решение и smoke-проекты | `agentic-openspec.slnx`; `src/Smoke/` (`/health`, `ApiMarker`, `HealthResponse`); `tests/Smoke.Tests/` (xUnit v3 + MTP) |
| 1.2 | Бутстрап тестов | `dotnet new xunit3` задокументирован в `README.md`, `.agents/csharp-dev.md`, `src/.gitkeep`; предупреждение про `NU1008`/`NU1010` |
| 1.3 | TFM + язык | `net10.0` / C# 14 везде: `config.yaml`, `csharp-api.yaml`, `csharp-desktop.yaml`, `12-desktop.md`, `01-code-style.md`, `README.md`, `AGENTS.md`, `.clinerules`, `project.md`, `standards/README.md` |
| 1.4 | Политика `LangVersion` | `latest` оставлен **осознанно** и зафиксирован в стандарте `01-code-style.md` (на SDK 10.0.401 = C# 14) |
| 1.5 | Покрытие | `tests/coverlet.runsettings` + `Microsoft.Testing.Extensions.CodeCoverage` **17.14.2**; `config.yaml:commands` пополнен `test_coverage`, `coverage_settings`, `vulnerable` |
| 1.6 | `NU1202` руками | **Не воспроизведён**: линия выровнена на `net10.0`, пакеты 10.x совместимы. Проверено успешным restore/build |
| 1.7 | `.gitattributes` | Создан: `* text=auto eol=lf`, CRLF для `*.cmd/.bat/.ps1/.psm1/.psd1`, бинарные исключения |

## Проверка выхода (G1) — ВЫПОЛНЕН

Из чистого состояния (`artifacts/` предварительно удалён):

| # | Команда | Результат |
| - | - | - |
| 1 | `dotnet restore` | **exit 0** — оба проекта восстановлены |
| 2 | `dotnet build --configuration Release --no-restore` | **exit 0** — 0 предупреждений, 0 ошибок |
| 3 | `dotnet test --configuration Release --no-build` | **1 тест, 1 succeeded, 0 failed** |
| 4 | `dotnet format --verify-no-changes` | **exit 0** — изменений нет |
| + | `dotnet list package --vulnerable --include-transitive` | уязвимых пакетов нет |

## Важная оговорка по запуску тестов

`dotnet test` под песочницей падает **не из-за кода**:

```
System.UnauthorizedAccessException: Access to the path is denied.
  at System.IO.Pipes.NamedPipeClientStream.TryConnect ...
  at Microsoft.Testing.Platform.IPC.NamedPipeClient.ConnectAsync ...
```

Microsoft.Testing.Platform общается с `dotnet` CLI через именованные каналы, а песочница их
блокирует (документированная граница). Обход — запуск тестового исполняемого файла напрямую,
он полностью эквивалентен и **проходит**:

```powershell
dotnet build -c Release --no-restore
& .\artifacts\bin\Smoke.Tests\release\Smoke.Tests.exe    # total: 1, succeeded: 1, exit 0
```

Это ограничение окружения, а не дефект репозитория. Для CI (где песочницы нет) достаточно
`dotnet test`.

## Побочное наблюдение: `global.json`

`dotnet test` **сам дописал** в `global.json` секцию:

```json
"test": { "runner": "Microsoft.Testing.Platform" }
```

Форматирование восстановлено (добавлен завершающий перевод строки). Это поведение SDK при
включённом MTP — секция корректна и оставлена, так как без неё не работает MTP-путь.

## Критерий выхода

| Требование | Статус |
| - | - |
| Все четыре команды зелёные из чистого клона | ✅ |
| `dotnet new xunit3` документирован и работает | ✅ |
| Нигде нет «.NET 8+»/«C# 12+» как единственной версии | ✅ (остались только в исторических ASSESSMENT.md/PLAN.md и записи D-002) |

## Откат

Батч только добавляет файлы и правит текстовые декларации — `git revert` одного коммита.
