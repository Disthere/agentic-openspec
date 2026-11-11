# Батч 4 — канон, стандарты, противоречия (G4)

**Дата:** 2026-11-11 · **Основание:** [`PLAN.md`](../../PLAN.md) §7 · **Гейт:** G4

## Что сделано

| ID | Задача | Результат |
| - | - | - |
| 4.1 | `AGENTS.md` — настоящий канон | **217 строк** (было 59): C#-минимум, тесты, ASP.NET, guardrails, перечень стандартов, протокол из 8 пунктов, карта репозитория |
| 4.2 | `.clinerules` → зеркало | **46 строк** (было 185): только шапка + таблица источников + 3 правила + guardrails. «Cline выступает Оркестратором» → «главная сессия DSH» (P1-*) |
| 4.3 | Один жизненный цикл | Канон — `constitution.md` §7 + `config.yaml:lifecycle`; `.clinerules` ссылается, а не переписывает |
| 4.4 | Скрипт сверки канона | `tools/check-canon-parity.ps1`: 12 якорных пунктов, размеры, запрет другого оркестратора, запрет дублирования команд. **Доказан негативным тестом** (12 расхождений, exit 1) |
| 4.5 | `s_` и `var` | `01-code-style.md` — единственный источник: `s_` внесён как правило, `var` — `true:suggestion` |
| 4.6 | «01–11» | `README.md` → «01–12» с упоминанием `12-desktop.md`; `DECISIONS.md` D-002 помечен как заменённый D-015 |
| 4.7 | Обещанная механика | `MA0141`, `MA0142`, `S103` = warning; `<GenerateDocumentationFile>true</GenerateDocumentationFile>`; CS1591 глушится только в тестах (`tests/Directory.Build.props`) |
| 4.8 | Уязвимости не глушить | `NU1901..NU1904` убраны из `NoWarn` → в `WarningsAsErrors`; `NuGetAudit=true`, уровень `moderate` |
| 4.9 | FluentAssertions | Правило в `01-code-style.md` и DoD 5.2: ≤ 7.2.2, 8.x запрещён, альтернатива AwesomeAssertions |
| 4.13 | Владение `acceptance.md` | Архитектор — **только пустая матрица**; заполняет QA (P1-18) |
| 4.14 | Стоп архитектора | `BLOCKED: Discovery gate not closed` при отсутствии `IN-NNN`/критерия успеха |
| 4.15 | `THIRD-PARTY.md` | Создан: OpenSpec (MIT, полный текст), Wikipedia (CC BY-SA 4.0, помечено как удалённое) |
| 4.17 | `ai-writing-tells` убран | Скилл удалён (D-06); ссылки вычищены из `.agents/README.md`, `skills/README.md`, `dsh/README.md`, `THIRD-PARTY.md` |
| 4.31 | Мёртвая настройка | `SuppressNETCoreSdkPreviewMessage` удалён из `Directory.Build.props` |
| 4.38 | Moq убран | `AGENTS.md` и `01-code-style.md` — только NSubstitute; Moq прямо запрещён |
| 5.2 | `docs/CLEANUP.md` | Чек-лист развёртывания за 10 минут + `tools/check-template-clean.ps1` |
| 5.8 | Проверка «шаблон чист» | Скрипт создан и **корректно показывает 10 нарушений** текущего состояния (сброс — батч 5) |

## Проверка выхода (G4) — ВЫПОЛНЕН

| # | Проверка | Результат |
| - | - | - |
| 1 | `tools/check-canon-parity.ps1` | **exit 0** — канон 217 строк, зеркало 46, правила не только в зеркале |
| 2 | `tools/validate-proposals.ps1 -All -CheckLinks` | **exit 0** |
| 3 | `Select-String AGENTS.md,.clinerules -Pattern 'Cline'` как оркестратор | **0 совпадений** |
| 4 | «стандарты 01–11» как полный список | **0** |
| 5 | `dotnet build -c Release` | **exit 0**, 0 ошибок |
| 6 | `dotnet test` (standalone MTP) | **1/1 succeeded** |
| 7 | `dotnet format --verify-no-changes` | **exit 0** |

## Найденное и исправленное сверх плана

**`tests/Directory.Build.props` ломал сборку.** MSBuild берёт **ближайший** `Directory.Build.props`
и не наследует родительский: тесты теряли `UseArtifactsOutput`, анализаторы и `LangVersion`, из-за
чего `build` падал `NETSDK1004` (не находил `obj/project.assets.json`). Исправлено явным
`<Import Project="$([MSBuild]::GetPathOfFileAbove(...))" />` — теперь корневой файл наследуется.

## Критерий выхода

| Требование | Статус |
| - | - |
| G4 выполнен | ✅ |
| Ни одно правило не существует только в зеркале | ✅ (проверяется скриптом) |
| Повторный аудит дублей даёт 0 расхождений | ✅ (`check-canon-parity.ps1`) |

## Откат

`git revert` коммита. `AGENTS.md` и `.clinerules` меняются парой — откатывать вместе.
