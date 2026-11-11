# Proposal: Full product lifecycle — фазы, гейты и роли в среде DeepSeek Harness

- **ID:** 002-lifecycle-and-roles
- **Status:** Done <!-- Draft | Approved | In Progress | Done | Rejected -->
  — утверждено владельцем 2026-11-09 командой «реализуй 002»: полный цикл (фазы + три роли) с учётом
  того, что рабочая среда — **DeepSeek Harness**, а не Cline.
- **Owner:** Disthere (владелец репозитория)
- **Date:** 2026-11-09
- **Profile:** csharp-api (see `openspec/config.yaml`)
- **Constitution:** [`openspec/constitution.md`](../../../constitution.md) (highest priority — read first)

## Context

Полный цикл продукта — от идеи до технической поддержки — сегодня покрыт частично. Роли
(Архитектор, Разработчик, Ревьюер) закрывают участок **Spec → Build → Review**, но у четырёх этапов
артефакты есть, а владельца и гейта нет:

| Этап | Артефакт | Владелец сегодня |
| - | - | - |
| Дискавери: разбор ТЗ, гипотеза ценности | `inputs/{briefs,concepts,graphics,samples}`, `INDEX.md` (`IN-NNN`) | нет — требования «берутся откуда-то» |
| Верификация: воспроизводимые улики | `acceptance.md`, `performance.md` | автор кода (конфликт: он же и судим) |
| Релиз: версия, миграции, откат | `CHANGELOG.md`, release-часть DoD 5.4 | нет |
| Эксплуатация и поддержка | `docs/operations/{slo,capacity,runbooks/}` | нет — документы заведены под пустого владельца |

Второй дефект — **рассинхрон со средой исполнения**. Авторитетные документы описывают Cline
(`spawn_agent`, Cline CLI, «тонкие правила в `.clinerules`»), тогда как рабочая среда — **DeepSeek Harness**:
делегирование идёт субагентами с `agentPreset`, роли объявляются пресетами в
[`dsh/profile/cordis.patch.yml`](../../../../dsh/profile/cordis.patch.yml), а `.clinerules` DSH **не читает**
(канон — `AGENTS.md` + `openspec/`). Из 15+ файлов агент получает инструкции про инструменты, которых
у него нет.

Целевой результат: у каждой фазы жизненного цикла есть **артефакт, гейт и владелец**; три новые роли
(аналитик, QA, Ops/Release) объявлены и **проведены в DSH как пресеты**; авторитетные документы
описывают реальную среду. Коммерческий контур (маркетинг, продажи) в объём не входит — он остаётся
вопросом [`OQ-8`](../../../../OPEN_QUESTIONS.md).

Капабилити: новые — `product-lifecycle`, `delivery-roles`. Существующие спецификации не меняются.

## Sources

None — изменение процесса и обвязки; внешних материалов заказчика оно не использует.

Источники требований:

- решение владельца 2026-11-09 «реализуй 002» — каркас фаз жизненного цикла + три роли
  (вариант «каркас + роли», а не «каркас без ролей»);
- решение владельца 2026-11-09 «Мы не работаем с Cline, среда — DeepSeek Harness» — из него следуют
  требования `R10`–`R11`;
- факты о среде — [`dsh/README.md`](../../../../dsh/README.md) (§«Роли и модели», §«Ограничения» п. 5–6);
- открытый вопрос [`OQ-8`](../../../../OPEN_QUESTIONS.md) — маркетингово-продуктовый контур (вне объёма).

## Requirements

Нумерованные и проверяемые; дельты — в [`specs/product-lifecycle/spec.md`](./specs/product-lifecycle/spec.md)
и [`specs/delivery-roles/spec.md`](./specs/delivery-roles/spec.md).

### Requirement: R1 — Lifecycle phases are declared

The system SHALL declare the product lifecycle phases (Discovery, Spec, Design, Build, Verify, Release,
Operate, Feedback) and SHALL list, for each phase, its artefact, its gate and its owning role.

#### Scenario: Phase map is present

- **WHEN** the constitution is read
- **THEN** every phase names its artefact, its gate and its owner

#### Scenario: No ownerless phase

- **WHEN** a phase has no artefact or no owner
- **THEN** it is reported as a gap rather than silently skipped

### Requirement: R2 — Gates block on a condition and are backed by an artefact

The system SHALL make every gate block on a stated condition, and SHALL NOT declare a gate whose condition
cannot be evidenced by an artefact.

#### Scenario: Gate without evidence is not introduced

- **WHEN** a proposed gate has no artefact proving it
- **THEN** it is not introduced as a gate (it becomes a checklist item or is dropped)

#### Scenario: Unmet condition blocks

- **WHEN** a gate condition is not met
- **THEN** the downstream phase does not start

### Requirement: R3 — Discovery gate

The system SHALL register every incoming material in `inputs/INDEX.md` with an `IN-NNN` identifier, record a
measurable success criterion, and route unresolved questions to `OPEN_QUESTIONS.md` before specification starts.

#### Scenario: Material is registered

- **WHEN** a customer material arrives
- **THEN** it gets an `IN-NNN` row with type, date, what it defines and a status

#### Scenario: Unmeasurable criterion becomes a question

- **WHEN** the success criterion cannot be measured
- **THEN** an `OQ-N` is opened instead of an invented default

### Requirement: R4 — Verification evidence is independent of the author

The system SHALL require that verification evidence (acceptance matrix, load-test results) is produced by a
role other than the author of the code, and SHALL require explicitly marked untested conditions.

#### Scenario: Evidence produced by another role

- **WHEN** `acceptance.md` is filled
- **THEN** the evidence producer is not the author of the code under verification

#### Scenario: Untested conditions are marked

- **WHEN** a condition was not tested
- **THEN** it appears in the "Непроверенные условия" table with a reason and a plan

### Requirement: R5 — Release gate

The system SHALL require, before a release, a changelog entry carrying the change identifier, a version bump
per SemVer, a verified migration and rollback path, and an updated runbook.

#### Scenario: Missing rollback path

- **WHEN** no rollback path exists for the release
- **THEN** the release gate fails

#### Scenario: Version follows SemVer

- **WHEN** the change set contains new behaviour or a breaking change
- **THEN** the version bump is MINOR or MAJOR respectively, and the changelog entry names the identifier

### Requirement: R6 — Support and feedback gate

The system SHALL require a health and alerting baseline plus a documented intake path, so that an incident or
support request becomes a tracked item (`OQ-N` or a proposal) rather than a lost message.

#### Scenario: Incident becomes a tracked item

- **WHEN** an incident is reported after release
- **THEN** an `OQ-N` or a proposal is opened with the observed impact

#### Scenario: Post-release review feeds the loop

- **WHEN** a release has been live long enough to observe it
- **THEN** the findings feed the Feedback phase and are routed back to Spec as questions or proposals

### Requirement: R7 — Handoffs cover the new transitions

The system SHALL document the transitions Brief → Spec, Build → Verify, Verify → Release, Release → Ops and
Ops → Spec, each with inputs, outputs and acceptance criteria.

#### Scenario: Transition has acceptance criteria

- **WHEN** `03-handoffs.md` §3.1 is read
- **THEN** each new transition lists its artefact and its acceptance criteria

### Requirement: R8 — DoD covers the new phases without renumbering

The system SHALL add Definition-of-Done checklists for the Discovery and Operate phases while keeping the
numbering of existing sections stable.

#### Scenario: Existing numbering is stable

- **WHEN** the DoD document is read
- **THEN** sections 5.1–5.5 keep their numbers and existing references remain valid

#### Scenario: New checklists exist

- **WHEN** the DoD document is read
- **THEN** §5.6 (Discovery) and §5.7 (Operate & Support) are present

### Requirement: R9 — Three delivery roles are declared

The system SHALL declare three roles — product analyst, verification engineer, operations and release — each
naming the artefacts it owns, the gate it closes and what it never does.

#### Scenario: Role owns artefacts

- **WHEN** a role file is read
- **THEN** it lists the artefacts the role produces and the gate it closes

#### Scenario: Role boundaries are explicit

- **WHEN** a role file is read
- **THEN** it lists what the role never does (for example, the verification engineer never authors the code it verifies)

### Requirement: R10 — Roles are DSH agent presets

The system SHALL register every role as a DeepSeek Harness agent preset with its own model binding and a
persona that references the role file instead of duplicating rules.

#### Scenario: Preset per role

- **WHEN** the composed DSH config is inspected
- **THEN** each role has an agent preset with a model plugin and a persona

#### Scenario: Model bindings are replaceable

- **WHEN** the composed profile is inspected
- **THEN** provider and model values are marked as placeholders to be replaced per installation

### Requirement: R11 — The orchestrator is the main DSH session

The system SHALL define the main DeepSeek Harness session as the orchestrator, SHALL name `AGENTS.md` as the
entry point DSH reads, and SHALL NOT keep operative instructions that depend on Cline-specific tooling.

#### Scenario: Canon reachable from DSH

- **WHEN** DSH opens this workspace
- **THEN** `AGENTS.md` is the declared entry point and the rules point to `openspec/` for detail

#### Scenario: No Cline tooling in operative documents

- **WHEN** authoritative documents are searched for `spawn_agent` or Cline CLI
- **THEN** no operative instruction remains (historical records in `CHANGELOG.md` are allowed)

### Requirement: R12 — Role admission rule

The system SHALL admit a new role only when the role owns an artefact and blocks a gate; otherwise the content
belongs in a standard, a checklist or a skill.

#### Scenario: Role without artefact is rejected

- **WHEN** a proposed role owns no artefact and closes no gate
- **THEN** it is not added as a role

## C# Implementation Plan

None — изменение документарное и конфигурационное (Markdown + YAML профиля DSH). C#-кода не добавляет.

- **Layers touched:** none (process/harness layer).
- **New types:** none.
- **DI registrations:** none.
- **NuGet packages:** none.
- **Guardrails:** не менять `.cs`/`.csproj`; не переименовывать `.clinerules` (нужен как совместимое зеркало),
  но убрать из него Cline-зависимые инструкции; не добавлять роли без артефакта и гейта; не трогать
  `openspec/proposals/archive/**`; состав фаз не расширять в этом предложении.

## API / Contract Changes

None — HTTP/gRPC/событийные контракты не затрагиваются. Контракт, который меняется, — **процессный**:
`dsh/profile/cordis.patch.yml` (композиция профиля). Его проверка описана в `## Test Strategy`.

## Test Strategy

- **Unit (xUnit):** не применимо — C#-код не добавляется.
- **Integration (`WebApplicationFactory<T>`):** не применимо.
- **Документарные и конфигурационные проверки:**
  - схема [`csharp-api.yaml`](../../../schemas/csharp-api.yaml): обязательные разделы `proposal.md`, ≥1 сценарий на требование;
  - паритет требований умбрелла-спеки и дельт капабилити (`product-lifecycle`, `delivery-roles`);
  - YAML-синтаксис `dsh/profile/cordis.patch.yml` и наличие шести пресетов (`analyst`, `architect`,
    `csharp-dev`, `qa-engineer`, `reviewer`, `ops-release`);
  - резолвинг относительных ссылок во всех затронутых Markdown-файлах;
  - поиск остаточных Cline-инструментов (`spawn_agent`, Cline CLI) в авторитетных документах.
- **Команды:** `dotnet`-гейт не применяется (нет C#-кода). Композиция профиля проверяется
  `npx @deepseek-ai/dsh --profile agentic-openspec --dump-config` — **после установки профиля**.

## Capabilities

### New Capabilities

- `product-lifecycle`: фазы полного цикла продукта (Discovery → Spec → Design → Build → Verify → Release →
  Operate → Feedback) с артефактом, гейтом и владельцем у каждой фазы; расширенные передачи и DoD фаз.
- `delivery-roles`: три роли доставки и эксплуатации (аналитик, инженер верификации, Ops/Release),
  их допуск по правилу «артефакт + гейт» и проводка ролей в DeepSeek Harness как agent presets.

### Modified Capabilities

- Нет — живые спецификации [`openspec/specs/`](../../../specs) пока содержат только `README.md`.

## Impact

**Добавляется:**

- `.agents/analyst.md`, `.agents/qa-engineer.md`, `.agents/ops-release.md` — три роли с артефактами и гейтами.
- `specs/product-lifecycle/spec.md`, `specs/delivery-roles/spec.md` — дельты требований (в этом предложении).

**Изменяется:**

- `openspec/constitution.md` — раздел «Фазы жизненного цикла» + DSH в канонических документах.
- `openspec/config.yaml` — `lifecycle`, `agents.orchestrator: dsh`, состав ролей и делегирование.
- `openspec/standards/05-definition-of-done.md` — §5.6 (Discovery), §5.7 (Operate & Support), правки §5.2 и §5.5.
- `openspec/standards/03-handoffs.md` — §3.1: пять новых переходов.
- `.agents/README.md` — таблица шести ролей, схема делегирования DSH, правило допуска роли.
- `dsh/profile/cordis.patch.yml` — пресеты `analyst`, `qa-engineer`, `ops-release`; `dsh/README.md` — состав профиля.
- `AGENTS.md`, `.clinerules` — канон и делегирование под DSH; роли: шесть.
- `README.md`, `.github/copilot-instructions.md`, `openspec/{project.md,README.md,proposals/README.md,standards/README.md}`
  — среда и запуск описывают DSH, а не Cline CLI.
- `OPEN_QUESTIONS.md` — `OQ-8` (маркетингово-продуктовый контур), `OQ-9` (условный security-проход).
- `docs/SESSION-START.md` — состояние сессии: среда, роли, открытые пункты.
- `CHANGELOG.md` — записи под `[Unreleased]`.

**Риски и митигации:** см. [`design.md`](./design.md) §5 (разрастание ролей и «гейт-театр», стоимость
пресетов, dev-preview DSH, риск вакуумных гейтов без прогонов).

**Rollout:** изменение аддитивное для процесса (новые файлы) и совместимое для артефактов (нумерация DoD
5.1–5.5 сохранена, контракт `VERDICT` не тронут). Профиль DSH переустанавливается одним
`dsh\install.ps1` — новые пресеты появляются в композиции.

**Rollback:** `git revert` коммита; для локальной среды — `npx @deepseek-ai/dsh --profile agentic-openspec
--from-default-profile web` с последующим `install.ps1` (сброс профиля).

## Open Questions

- [ ] `OQ-8` — нужен ли продуктово-маркетинговый контур (GTM, позиционирование, метрики) как
  `inputs/markets/` + владелец Product Owner? — _recommended default:_ да, но как **входной материал**,
  а не как роль в кодовом SDD; вводить при первом реальном маркетинговом документе.
- [ ] `OQ-9` — вводить ли условный security-проход по классификации риска (PII, аутентификация, платежи)? —
  _recommended default:_ да, отдельным предложением вместе с уровнями риска изменения; не постоянной ролью.

## Performance & SLO

None — изменение не влияет на throughput, latency или ресурсы сервисов. Процессная цена (три новых роли,
шесть пресетов, пять гейтов) описана и митигирована в [`design.md`](./design.md) §5.

## Contracts

None — контракты черновиков не меняются. Изменяемый «контракт» процесса — композиция профиля DSH,
проверяется `--dump-config` (см. `## Test Strategy`).

## Acceptance

[`acceptance.md`](./acceptance.md) — матрица «требование → проверка → результат» для `R1`..`R12`.
Непроверенные условия (живой прогон ролей, `--dump-config` до установки профиля) перечислены явно.

## Changelog

Планируемая запись в [`CHANGELOG.md`](../../../../CHANGELOG.md) под `[Unreleased]`:

- привязка `(002-lifecycle-and-roles)` в каждой строке; версия при срезе релиза — **MINOR** (новое поведение
  процесса, обратная совместимость артефактов сохранена);
- `### Добавлено` — три роли, фазы жизненного цикла, DoD 5.6/5.7, новые передаточные переходы, пресеты DSH;
- `### Изменено` — конституция, конфиг, DoD, handoffs, `.agents/README.md`, `dsh/*`, `AGENTS.md`, `.clinerules`,
  `README.md` и указатели в `openspec/`, `docs/SESSION-START.md`, `OPEN_QUESTIONS.md`;
- `### Не изменилось` — нумерация DoD 5.1–5.5, контракт `VERDICT: Pass|Fail`, двухосевое ревью (001),
  скиллы `spec-first`, `implement-feature`, `code-review`, `ai-writing-tells`;
- `### Тесты` — документарные и конфигурационные проверки; `--dump-config` — после установки профиля.

## Tasks

See [`tasks.md`](./tasks.md). Every task traces back to a requirement (`R1`..`R12`) above.
