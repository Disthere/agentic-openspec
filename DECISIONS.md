# DECISIONS — журнал решений agentic-openspec

Формат: номер · дата · решение · статус · обоснование/источник.
Статусы: **ACCEPTED** — принято; **PROPOSED** — предложено, ждёт подтверждения пользователя
(см. [`OPEN_QUESTIONS.md`](OPEN_QUESTIONS.md)); **SUPERSEDED (D-XXX)** — заменено; **REJECTED** — отклонено.

Парный документ: открытые вопросы — в [`OPEN_QUESTIONS.md`](OPEN_QUESTIONS.md).
Изменения поведения — в [`CHANGELOG.md`](CHANGELOG.md).

| # | Дата | Решение | Статус | Источник |
| - | - | - | - | - |
| D-001 | 2026-11-05 | Каталог предложений — `openspec/proposals/<NNN-slug>/` (вместо `changes/` у OpenSpec) | ACCEPTED | обсуждение структуры SDD |
| D-002 | 2026-11-05 | Стек и стандарты: C# 12+ / .NET 8+, `Nullable`, warnings-as-errors, анализаторы (NetAnalyzers + Sonar + Meziantou), `.editorconfig` по dotnet/runtime, покрытие >80% (Domain >90%) | ACCEPTED | `openspec/standards/01–11` |
| D-003 | 2026-11-09 | Обвязка DeepSeek Harness: роли — это agent presets, **модель на роль** — дочерним плагином `@deepseek-ai/dsh-agent-default-model`; профиль называется `agentic-openspec` (имя `desktop` зарезервировано под Electron) | ACCEPTED (OQ-4, 09.11.2026) | `dsh/profile/cordis.patch.yml` |
| D-004 | 2026-11-09 | Скиллы: общие — глобально (`~/.dsh/skills`, ранг 400), проектные — `<проект>/.agents/skills` (ранг 200); общие в проектах не дублировать | ACCEPTED (OQ-5, 09.11.2026) | `dsh/README.md`, OQ-5 |
| D-005 | 2026-11-09 | Changelog: Keep a Changelog + SemVer, обязательная привязка `(<ID>)` в заголовке; секции включая `Не изменилось` / `Миграция` / `Тесты` | ACCEPTED (OQ-6, 09.11.2026) | `standards/04-documentation.md §4.6` |
| D-006 | 2026-11-09 | Open Questions и Decisions — отдельные живые файлы в корне: источник вопросов — `## Open Questions` предложений, закрытие `OQ-N` = запись `D-NNN` | ACCEPTED | `standards/04-documentation.md §4.7–4.8` |

## D-003 — роли и модели в DeepSeek Harness (подробности)

DSH собирает профиль как композицию плагинов Cordis; роли объявляются декларативно.

| # | Механизм | Что даёт |
| - | - | - |
| a | `@deepseek-ai/dsh-agent-preset` (`config.id`, `plugins[]`) | именованная роль (Architect / csharp-dev / reviewer) со своей композицией |
| b | `@deepseek-ai/dsh-agent-default-model` внутри `plugins:` | **своя модель на роль** (архитектору — сильнее, ревьюеру — независимую) |
| c | `@deepseek-ai/dsh-persona` (`prefix`) | персона роли; текст короткий и ссылается на `.agents/*.md` (без дублирования правил) |
| d | `agent-preset-registry` (`default: csharp-dev`) | роль по умолчанию для новых сессий |

Следствия:
- профиль **глобальный** (`$DSH_HOME/profiles/agentic-openspec`), один на все проекты;
- имя `desktop` недоступно (зарезервировано под Electron) — отсюда `agentic-openspec`;
- корректность композиции проверяется через `--dump-config`.

## D-006 — Open Questions и Decisions как процесс (подробности)

| # | Механизм | Что даёт |
| - | - | - |
| a | `## Open Questions` в `proposal.md` | Архитектор обязан вынести нерешённое уже на этапе спецификации |
| b | `OPEN_QUESTIONS.md` | сквозная нумерация `OQ-N`, статусы, блок замера, ответ пользователя |
| c | `DECISIONS.md` | переход `OQ-N` → `D-NNN`; ссылки из `CHANGELOG.md`, кода и ADR |
| d | DoD 5.1 / 5.4 | открытые вопросы вынесены; решения зафиксированы; релиз не закрывается при открытых вопросах, влияющих на поведение |

Следствия:
- вопросы и решения перестали теряться в переписке;
- появился адресуемый след: `OQ-N` → `D-NNN` → версия в `CHANGELOG.md`.
