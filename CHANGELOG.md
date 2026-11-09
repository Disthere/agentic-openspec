# Changelog — agentic-openspec

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/). Версионирование: [SemVer](https://semver.org/lang/ru/).
Каждая запись привязана к задаче: ID предложения (`openspec/proposals/<NNN-slug>`), `spec-id` (`PAY-001`) или issue (`#123`).

Правила ведения — [`openspec/standards/04-documentation.md` §4.6](openspec/standards/04-documentation.md#46-changelog).
Шаблон записи — [`docs/CHANGELOG-TEMPLATE.md`](docs/CHANGELOG-TEMPLATE.md).

## [Unreleased]

### Добавлено

- **`CHANGELOG.md` + [`docs/CHANGELOG-TEMPLATE.md`](docs/CHANGELOG-TEMPLATE.md)** — универсальный шаблон changelog
  (Keep a Changelog + SemVer, обязательная привязка к задачам). Правила ведения — в
  [`openspec/standards/04-documentation.md` §4.6](openspec/standards/04-documentation.md#46-changelog),
  DoD релиза обновлён ([`05-definition-of-done.md`](openspec/standards/05-definition-of-done.md) п. 5.4). (`docs-changelog`)
- **`OPEN_QUESTIONS.md` + `DECISIONS.md`** — открытые пункты (`OQ-N`) и журнал решений (`D-NNN`); шаблоны —
  [`docs/OPEN_QUESTIONS-TEMPLATE.md`](docs/OPEN_QUESTIONS-TEMPLATE.md),
  [`docs/DECISIONS-TEMPLATE.md`](docs/DECISIONS-TEMPLATE.md). Правила —
  [`04-documentation.md` §4.7–4.8](openspec/standards/04-documentation.md#47-open-questions). (`docs-open-questions`)

### Изменено

- **`openspec/standards/04-documentation.md`** — уровень «Changelog» в таблице 4.1 и новый раздел 4.6. (`docs-changelog`)
- **`README.md`, `AGENTS.md`** — CHANGELOG добавлен в карту и дерево. (`docs-changelog`)
- **`05-definition-of-done.md`** — DoD спеки: открытые вопросы вынесены в `OPEN_QUESTIONS.md`; DoD релиза: решения зафиксированы в `DECISIONS.md`. (`docs-open-questions`)
- **`openspec/proposals/000-template.md`, `openspec/project.md`** — ссылки на OPEN_QUESTIONS/DECISIONS. (`docs-open-questions`)
- **`openspec/proposals/000-template.md`** — новый раздел `## Changelog`: Архитектор обязан планировать запись в changelog. (`docs-changelog-process`)
- **`.agents/architect.md`** — план записи в CHANGELOG добавлен в результаты Архитектора и в его DoD. (`docs-changelog-process`)
- **`.agents/reviewer.md`** — в процедуру ревью добавлена проверка записи в CHANGELOG (шаг 9). (`docs-changelog-process`)
- **`docs/DECISIONS-TEMPLATE.md`, `DECISIONS.md`, `standards/04-documentation.md` §4.8** — формат журнала решений приведён к табличному виду (`# | Дата | Решение | Статус | Источник` + разделы «подробности»). (`docs-decisions-format`)

## [0.2.0] — 2026-11-09 · Обвязка DeepSeek Harness + скилл работы с текстами (dsh-profile, ai-writing-tells)

### Добавлено

- **`dsh/`** — обвязка SDD для **DeepSeek Harness**: `profile/` (Cordis-профиль `agentic-openspec`),
  `install.ps1`, `README.md`. Три роли (agent presets) — `architect`, `csharp-dev`, `reviewer` — каждая
  со своей персоной (`@deepseek-ai/dsh-persona`) и **своей моделью** (`@deepseek-ai/dsh-agent-default-model`);
  реестр `agent-preset-registry` с `default: csharp-dev`.
- **`.agents/skills/ai-writing-tells/`** — скилл аудита и правки «AI-признаков» в текстах (по Wikipedia
  «Signs of AI writing»): `SKILL.md` (+`whenToUse`), `references/signs-of-ai-writing.md`,
  `references/rewriting-playbook.md`, `scripts/ai_tells_check.py`.

### Не изменилось

- Навыки `spec-first` и `implement-feature` и их фронтматтер — без изменений.
- Обвязка Cline/VS Code (`.clinerules`, `AGENTS.md`, `openspec/`) не затронута: DSH читает `.agents/skills`
  и `AGENTS.md` как есть.

### Тесты

- Валидация YAML профиля (`cordis.yml`, `cordis.patch.yml`) и `package.json` — 0 ошибок.
  Порядок интерактивной проверки композиции — в [`dsh/README.md`](dsh/README.md).

## [0.1.0] — 2026-11-05 · Начальный SDD-шаблон

### Добавлено

- **`openspec/`** — конституция, `config.yaml`, схемы валидации, шаблоны предложений
  (`proposal`/`tasks`/`performance`/`acceptance`/`contracts`), стандарты `01`–`11`.
- **`.agents/`** — роли Архитектор / Разработчик / Ревьюер + скиллы `spec-first`, `implement-feature`.
- **Правила агента** — `.clinerules`, `AGENTS.md`, `.github/copilot-instructions.md`, `.github/instructions/`.
- **`docs/`** — границы сервисов, ADR, SLO, capacity, runbooks.
- **Сборка .NET** — `global.json`, `Directory.Build.props`, `Directory.Packages.props`, `.editorconfig`.
