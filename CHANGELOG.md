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
- **`inputs/` + [`docs/INPUTS-TEMPLATE.md`](docs/INPUTS-TEMPLATE.md)** — каталог входных материалов заказчика
  (`briefs/`, `concepts/`, `graphics/`, `samples/`), `README.md` (правила) и `INDEX.md` (реестр `IN-NNN`).
  Вшит в роли (Архитектор/Разработчик/Ревьюер), раздел `## Sources` предложения, схему и стандарт §4.9. (`docs-inputs`)
- **Handoff наружу:** [`03-handoffs.md` §3.5](openspec/standards/03-handoffs.md) + [`docs/HANDOFF-TEMPLATE.md`](docs/HANDOFF-TEMPLATE.md) —
  состав пакета для внешнего исполнителя, принципы, чек-лист вычистки (что НЕ уходит наружу). (`docs-handoff-external`)
- **`docs/SESSION-START.md`** — хендофф сессии: правило «старт без действий», текущее состояние, открытые
  пункты и меню готовых команд. Вшито в [`.clinerules`](.clinerules) и [`AGENTS.md`](AGENTS.md). (`docs-session-start`)
- **`.agents/skills/code-review/`** — двухосевое независимое ревью: `SKILL.md` (границы, источники стандартов,
  промпты осей, агрегация), `references/smell-baseline.md` (базлайн запахов, always judgement call),
  `references/findings.md` (жизненный цикл находки, диспозиции `fixed`/`rejected`/`deferred`, применимость улик).
  Спецификация — [`openspec/proposals/001-two-axis-review/`](openspec/proposals/001-two-axis-review/proposal.md). (`001-two-axis-review`)
- **Три роли полного цикла** — [`.agents/analyst.md`](.agents/analyst.md) (Discovery: `inputs/`, `IN-NNN`,
  измеримый критерий успеха), [`.agents/qa-engineer.md`](.agents/qa-engineer.md) (Verify: `acceptance.md`,
  `performance.md`, воспроизводимые улики), [`.agents/ops-release.md`](.agents/ops-release.md)
  (Release/Operate/Feedback: changelog и версия, откат, SLO/capacity/runbook, обратная связь из поддержки).
  (`002-lifecycle-and-roles`)
- **Фазы жизненного цикла** — [`openspec/constitution.md`](openspec/constitution.md) §7: карта
  «фаза → артефакт → гейт → владелец» и правила фаз (гейт без артефакта не вводится; допуск роли = артефакт + гейт). (`002-lifecycle-and-roles`)
- **DoD дискавери и эксплуатации** — [`05-definition-of-done.md`](openspec/standards/05-definition-of-done.md)
  §5.6 (Discovery) и §5.7 (Operate & Support). (`002-lifecycle-and-roles`)
- **Пять новых передач** — [`03-handoffs.md`](openspec/standards/03-handoffs.md) §3.1: Brief → Spec,
  Build → Verify, Verify → Release, Release → Ops, Ops → Spec. (`002-lifecycle-and-roles`)
- **Пресеты DSH** — [`dsh/profile/cordis.patch.yml`](dsh/profile/cordis.patch.yml): `analyst`, `qa-engineer`,
  `ops-release` добавлены к `architect`, `csharp-dev`, `reviewer` (шесть ролей). (`002-lifecycle-and-roles`)

### Изменено

- **`openspec/standards/04-documentation.md`** — уровень «Changelog» в таблице 4.1 и новый раздел 4.6. (`docs-changelog`)
- **`README.md`, `AGENTS.md`** — CHANGELOG добавлен в карту и дерево. (`docs-changelog`)
- **`05-definition-of-done.md`** — DoD спеки: открытые вопросы вынесены в `OPEN_QUESTIONS.md`; DoD релиза: решения зафиксированы в `DECISIONS.md`. (`docs-open-questions`)
- **`openspec/proposals/000-template.md`, `openspec/project.md`** — ссылки на OPEN_QUESTIONS/DECISIONS. (`docs-open-questions`)
- **`openspec/proposals/000-template.md`** — новый раздел `## Changelog`: Архитектор обязан планировать запись в changelog. (`docs-changelog-process`)
- **`.agents/architect.md`** — план записи в CHANGELOG добавлен в результаты Архитектора и в его DoD. (`docs-changelog-process`)
- **`.agents/reviewer.md`** — в процедуру ревью добавлена проверка записи в CHANGELOG (шаг 9). (`docs-changelog-process`)
- **`docs/DECISIONS-TEMPLATE.md`, `DECISIONS.md`, `standards/04-documentation.md` §4.8** — формат журнала решений приведён к табличному виду (`# | Дата | Решение | Статус | Источник` + разделы «подробности»). (`docs-decisions-format`)
- **`.agents/reviewer.md`** — переписан под двухосевое ревью: две независимые сессии (Standards и Spec),
  режим «только чтение», находки с устойчивыми ID и диспозициями, агрегированный вердикт. Контракт
  `VERDICT: Pass|Fail` и формат `Where/Breaks/Fix` сохранены; проверка записи в CHANGELOG (прежний шаг 9)
  перенесена в ось Standards. (`001-two-axis-review`)
- **`.agents/README.md`, `.agents/skills/README.md`** — таблицы скиллов дополнены `code-review` и
  `ai-writing-tells`; описаны соглашения по содержимому (`references/`, опциональный `agents/`). (`001-two-axis-review`)
- **`openspec/standards/05-definition-of-done.md` §5.5** — Ревьюер выполняет двухосевой проход, Оркестратор агрегирует вердикт; запахи кода не блокируют. (`001-two-axis-review`)
- **`OPEN_QUESTIONS.md`** — добавлен `OQ-7`: обязателен ли двухосевой режим для всех предложений. (`001-two-axis-review`)
- **Среда исполнения — DeepSeek Harness, а не Cline:** [`AGENTS.md`](AGENTS.md) закреплён как **канон правил**
  (DSH читает его), [`.clinerules`](.clinerules) — совместимое зеркало; делегирование — субагенты DSH с
  `agentPreset`; Cline CLI и `spawn_agent` убраны из авторитетных документов
  ([`README.md`](README.md), [`AGENTS.md`](AGENTS.md), [`.clinerules`](.clinerules),
  [`.github/copilot-instructions.md`](.github/copilot-instructions.md),
  [`openspec/`](openspec) — `project.md`, `README.md`, `proposals/README.md`, `standards/README.md`). (`002-lifecycle-and-roles`)
- **`openspec/config.yaml`** — блок `lifecycle` (фазы и гейты), `agents.orchestrator: dsh`, шесть ролей,
  правило допуска роли. (`002-lifecycle-and-roles`)
- **`openspec/standards/05-definition-of-done.md`** §5.2 — улики верификации добывает не автор кода
  (Инженер верификации); §5.5 — применение новых ролей. (`002-lifecycle-and-roles`)
- **`.agents/README.md`** — таблица шести ролей, схема делегирования на субагентах DSH, правило допуска
  (артефакт + гейт). (`002-lifecycle-and-roles`)
- **`dsh/README.md`** — состав профиля (шесть пресетов), цикл по фазам жизненного цикла. (`002-lifecycle-and-roles`)

### Не изменилось

- Контракт вердикта `VERDICT: Pass|Fail`, формат находок `Where/Breaks/Fix` и нумерация предложений —
  ранее архивированные предложения и их `acceptance.md` читаются без изменений.
- Нумерация DoD 5.1–5.5 сохранена: новые разделы добавлены как 5.6 и 5.7.
- Скиллы `spec-first`, `implement-feature`, `code-review`, `ai-writing-tells` — без изменений.
- Имя файла `.clinerules` сохранено (совместимость с другими инструментами), изменилось только содержимое.

### Тесты

- Документарные проверки: обязательные разделы `proposal.md` по схеме [`csharp-api.yaml`](openspec/schemas/csharp-api.yaml),
  ≥1 сценарий с `WHEN`/`THEN` на каждое требование, паритет требований умбрелла-спеки и дельт capability,
  резолвинг относительных ссылок в артефактах предложения, формат `tasks.md`.
- `dotnet build` / `dotnet test` / `dotnet format` не запускались: предложения 001 и 002 не добавляют C#-кода.
- Живой прогон двух осей на реальном диффе **не выполнялся** — предмета ревью не было; условие и план
  проверки зафиксированы в [`openspec/proposals/001-two-axis-review/acceptance.md`](openspec/proposals/001-two-axis-review/acceptance.md).
- `npx @deepseek-ai/dsh --profile agentic-openspec --dump-config` **не запускался** — профиль ещё не
  установлен; условие зафиксировано в [`openspec/proposals/002-lifecycle-and-roles/acceptance.md`](openspec/proposals/002-lifecycle-and-roles/acceptance.md).

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
