# Proposal: Adoption guide — как развернуть набор в новом и в существующем проекте

- **ID:** 005-adoption-guide
- **Status:** Done <!-- Draft | Approved | In Progress | Done | Rejected -->
  — утверждено владельцем 2026-11-09 запросом на подробную инструкцию с готовыми промптами.
- **Approved by:** Disthere (владелец репозитория)
- **Approved at:** 2026-11-09
- **Owner:** Disthere (владелец репозитория)
- **Date:** 2026-11-09
- **Profile:** любой (документ процесса)
- **Constitution:** [`openspec/constitution.md`](../../../constitution.md) (highest priority — read first)

## Context

Набор умеет работать, но **развернуть** его в проекте сейчас описано «по кускам»: [`README.md`](../../../README.md)
даёт сценарии A/B с таблицами «что копировать» и командами `Copy-Item`, [`dsh/README.md`](../../../../dsh/README.md)
описывает установку профиля, [`docs/SESSION-START.md`](../../../../docs/SESSION-START.md) — состояние нашей сессии. Из этого
набора шагов человек вынужден: набирать команды, копировать по пять-шесть каталогов, руками править
`.editorconfig` и `Directory.*.props`, решать, что делать с конфликтами.

Требование владельца: **ручной работы минимум**. Промпты — единственный интерфейс; командных строк,
ручного редактирования файлов и «вставок в текст» быть не должно; из ручных каталоговых операций
допускается **ровно одна** — скопировать одну папку.

Целевой результат: [`docs/ADOPTION.md`](../../../../docs/ADOPTION.md) — инструкция с готовыми промптами для двух
сценариев (новый проект; существующий проект без SDD) и для последующих изменений; всё остальное делает
сессия DSH с ролями.

Капабилити: новая — `adoption-guide`.

## Sources

None — документ процесса; материалы заказчика не используются.

Источник требований — решение владельца 2026-11-09 (формат: только промпты, одно ручное копирование папки)
и фактическое состояние набора: `README.md` (сценарии A/B), `dsh/README.md` (профиль и проверка),
`AGENTS.md`/`.clinerules` (фазы и делегирование), `constitution.md` §7 (фазы и гейты).

## Requirements

Дельта — в [`specs/adoption-guide/spec.md`](./specs/adoption-guide/spec.md).

### Requirement: R1 — Adoption guide covers both scenarios

The guide SHALL describe adopting the toolkit into a new project and into an existing project that never
used a spec-driven process, and SHALL cover the follow-up change cycle in an already adopted project.

#### Scenario: New project path exists

- **WHEN** the guide is read for a new project
- **THEN** it lists the steps as ready-made prompts

#### Scenario: Existing project path exists

- **WHEN** the guide is read for an existing project
- **THEN** it includes a prompt that adapts the toolkit to that project's stack and current state

### Requirement: R2 — Prompts only, one folder at a time

The guide SHALL NOT require the reader to type commands or edit files by hand; the only manual filesystem
operations it may require SHALL be copying a single folder at a time (the toolkit folder, and later a folder
of customer materials).

#### Scenario: No command line

- **WHEN** the guide is followed step by step
- **THEN** no step asks the reader to run a command in a terminal

#### Scenario: Single folder operation

- **WHEN** the guide describes a manual filesystem action
- **THEN** it is copying one folder, and the remaining placement is done by the session

### Requirement: R3 — Adoption merges instead of overwriting

Adoption into an existing project SHALL merge conflicting build and style files rather than overwrite them,
SHALL preserve the product's sources and README, and SHALL NOT change product code as part of adoption.

#### Scenario: Conflicting files are merged

- **WHEN** the target project already has `.editorconfig`, `Directory.Build.props`, `Directory.Packages.props`
  or `global.json`
- **THEN** the session merges the toolkit rules into them and reports what changed

#### Scenario: Product is untouched

- **WHEN** adoption finishes
- **THEN** product sources, tests and the project README are unchanged, and no product code was edited

### Requirement: R4 — Human actions are listed explicitly

The guide SHALL list every action left to the human (approvals, answers to questions, secrets and keys,
physical checks) and SHALL state what the roles do instead.

#### Scenario: Human list is present

- **WHEN** the guide is read
- **THEN** it contains an explicit list of human-only actions

#### Scenario: Secrets stay outside the repository

- **WHEN** the guide describes credentials and keys
- **THEN** it states that they are never placed into the repository

### Requirement: R5 — The guide is discoverable and recorded

The guide SHALL be linked from the repository entry points and recorded in the changelog with the change id.

#### Scenario: Linked from entry points

- **WHEN** `README.md` or `AGENTS.md` is read
- **THEN** it points to the adoption guide

#### Scenario: Recorded in the changelog

- **WHEN** `CHANGELOG.md` is read
- **THEN** the entry carries the id of this proposal

## C# Implementation Plan

None — документ процесса. C#-кода предложение не добавляет.

- **Layers touched:** none.
- **NuGet packages:** none.
- **Guardrails:** в инструкции не должно быть команд для набора вручную и шагов «отредактируйте файл»;
  ровно одно ручное каталоговое действие; секреты не попадают в репозиторий.

## API / Contract Changes

None — контракты не затрагиваются. «Контракт» инструкции — список промптов и порядок гейтов.

## Test Strategy

- **Unit / Integration (C#):** не применимо — кода нет.
- **Проверки документа:**
  - обязательные разделы `proposal.md` по схеме активного профиля, паритет требований и дельты;
  - в `docs/ADOPTION.md` нет строк-команд для человека (поиск по признакам: `powershell`, `dotnet `,
    `git `, `Copy-Item`, `npm` вне блоков-промптов);
  - ровно одно ручное каталоговое действие описано явно;
  - ссылки резолвятся; промпты — в закрытых блоках и готовы к копированию.
- **Команды:** зафиксированы в [`acceptance.md`](./acceptance.md).

## Capabilities

### New Capabilities

- `adoption-guide`: инструкция по развёртыванию набора (новый проект, существующий проект) и по циклу
  изменений в уже развёрнутом проекте — только промптами, с одним ручным копированием папки.

### Modified Capabilities

- Нет.

## Impact

**Добавляется:**

- `docs/ADOPTION.md` — инструкция с готовыми промптами.

**Изменяется:**

- `README.md` — ссылка на инструкцию;
- `AGENTS.md` — строка в карте репозитория;
- `CHANGELOG.md`, `docs/SESSION-START.md` — запись и готовая команда.

**Риски и митигации:** [`design.md`](./design.md) — расхождение инструкции с README (сценарии A/B),
промпты без контекста, «тихое» перезаписывание конфигов чужого проекта.

**Rollout:** аддитивно; инструкция ссылается на существующие файлы, ничего не переопределяет.

**Rollback:** `git revert`.

## Open Questions

- [ ] OQ-11 — нужна ли отдельная роль `bootstrap` (пресет) для развёртывания набора во внешнем проекте? —
  _recommended default:_ пока нет; развёртывание делает главная сессия по промптам, а роль вводим только
  если процедура повторится и потребует своего гейта (правило допуска роли).
- [ ] OQ-12 — оставить инструкцию пошаговой или свести к «одной кнопке» (один промпт на весь сценарий)? —
  _recommended default:_ пошаговые промпты: на гейтах нужны ответы человека, «одна кнопка» их скрывает.
- [ ] OQ-13 — пресет главной сессии: оставить дефолт реестра `csharp-dev` или нейтральный (`standard`)? —
  _recommended default:_ нейтральный: главная сессия — Оркестратор, а не разработчик; роль разработчика
  вызывается явно на фазе Build.
- [ ] OQ-14 — как адаптировать набор в проекте, где уже есть документация иной структуры (свои ADR, wiki,
  `docs/` с другой иерархией, свой changelog)? — _recommended default:_ инвентаризация + карта соответствий
  «их документ → наш артефакт», правило «источник истины один», отдельное предложение с промптом
  «приведи документацию проекта к нашей структуре».

## Performance & SLO

None.

## Contracts

None.

## Acceptance

[`acceptance.md`](./acceptance.md) — матрица `R1`..`R5`; отдельно отмечено, что проверено машинно
(отсутствие команд, ссылки, паритет), а что — только ревью человеком (понятность промптов).

## Changelog

Планируемая запись в [`CHANGELOG.md`](../../../../CHANGELOG.md) под `[Unreleased]`:

- `### Добавлено` — `docs/ADOPTION.md`: развёртывание набора в новом и в существующем проекте
  готовыми промптами, одно ручное действие (копирование одной папки), список человеческих действий;
- привязка `(005-adoption-guide)`; версия при срезе релиза — **MINOR**.

## Tasks

See [`tasks.md`](./tasks.md). Every task traces back to a requirement (`R1`..`R5`) above.
