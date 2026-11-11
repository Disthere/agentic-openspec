# Proposal: Two-axis independent review with a finding lifecycle — двухосевое ревью и жизненный цикл находок

- **ID:** 001-two-axis-review
- **Status:** Done <!-- Draft | Approved | In Progress | Done | Rejected -->
  — утверждено владельцем 2026-11-09 командой «реализуй 001». `OQ-7` (обязательность двухосевого режима)
  остаётся открытым: реализован рекомендованный дефолт — двухосевой проход обязателен, для малых изменений
  допустим последовательный запуск осей.
- **Owner:** Disthere (владелец репозитория)
- **Date:** 2026-11-09
- **Profile:** csharp-api (see `openspec/config.yaml`)
- **Constitution:** [`openspec/constitution.md`](../../../constitution.md) (highest priority — read first)

## Context

Сейчас независимое ревью выполняет один проход `.agents/reviewer.md` и возвращает вердикт `Pass`/`Fail`.
Этого достаточно для простых изменений, но у процесса нет четырёх свойств, без которых ревью перестаёт
быть проверкой и становится мнением:

1. **Разделения осей.** Нарушение стандарта и недоделанное требование попадают в один список, и одна ось
   маскирует другую: код может идеально соответствовать стилю, но делать не то, — или делать ровно
   запрошенное, но ломать конвенции проекта.
2. **Идентичности находок.** Нарушения нумеруются внутри одного отчёта, поэтому после правок нельзя сказать,
   какие закрыты, какие перенесены, а какие появились.
3. **Правила сходимости.** Цикл «правки → повторное ревью» не ограничен: нет порога, после которого нужна
   свежая диагностика подхода вместо очередного прохода.
4. **Применимости улик.** Не фиксируется пара «база/head», поэтому нельзя определить, какие прежние
   проверки остались валидными после новых коммитов.

Целевой результат: ревью возвращает **два раздельных отчёта** (Standards и Spec), **находки с устойчивыми ID
и обязательными диспозициями**, **правило сходимости** и **зафиксированную применимость улик** — при этом
прежний контракт вердикта (`VERDICT: Pass|Fail`) сохраняется, чтобы не ломать `acceptance.md` и DoD 5.5.

Капабилити, которую затрагивает изменение: новая — `independent-review`
(живые спецификации в [`openspec/specs/`](../../../specs) пока пусты).

## Sources

None — изменение процесса, внешних материалов заказчика нет.

Источник требования — решение пользователя зафиксировать в шаблон двухосевое ревью
(вопрос [`OQ-7`](../../../../OPEN_QUESTIONS.md), предложение `001`); структурная идея заимствована из
референсного набора `KirillSachkov/ai-dev-kit` (скиллы `code-review`, `references/findings.md`),
формулировки не копируются. Обоснование и трассировка — в [`design.md`](./design.md).

## Requirements

Нумерованные, проверяемые; у каждого — минимум один сценарий. Дельты — в
[`specs/independent-review/spec.md`](./specs/independent-review/spec.md).

### Requirement: R1 — Two axes reported separately

The system SHALL review a change on two independent axes, `Standards` and `Spec`, and SHALL report
their findings as separate sections without merging or cross-axis reranking.

#### Scenario: Both axes reported

- **WHEN** a review of a change completes
- **THEN** the report contains a `## Standards` section and a `## Spec` section, and no finding is moved from one axis to the other

#### Scenario: No cross-axis winner

- **WHEN** the summary line is produced
- **THEN** it states the finding count per axis and the worst finding within each axis, and names no single winner across axes

### Requirement: R2 — Independent axis workers

The system SHALL run each axis in a fresh context with read-only repository access, and the reviewer
SHALL NOT be the author of the reviewed change.

#### Scenario: Fresh read-only context

- **WHEN** an axis worker starts
- **THEN** it holds no findings from the other axis and has no write access to the repository

### Requirement: R3 — Standards axis cites documented standards

The system SHALL cite the documented project standard (file and rule) for every hard Standards finding,
and SHALL treat the code-smell baseline as judgement calls that documented project standards override.

#### Scenario: Documented violation is hard

- **WHEN** the change violates a rule documented in `openspec/standards/`, `.clinerules` or `openspec/schemas/`
- **THEN** the finding is classified as hard and cites that standard as its evidence

#### Scenario: Repository standard overrides the baseline

- **WHEN** a documented project standard endorses a practice the smell baseline would flag
- **THEN** the smell finding is suppressed rather than reported as a violation

### Requirement: R4 — Spec axis checks requirement coverage and behaviour

The system SHALL check missing or partial requirement coverage, unintended scope, behavioural
regressions, and affected existing callers, and SHALL check whether a bug fix addresses the root cause
rather than one symptom.

#### Scenario: Requirement without implementing code

- **WHEN** a requirement in the proposal has no code satisfying it
- **THEN** the Spec axis reports a finding that cites that requirement

#### Scenario: Requirement without traceable source

- **WHEN** a requirement traces to neither the `## Sources` section nor `DECISIONS.md` / `OPEN_QUESTIONS.md`
- **THEN** the Spec axis reports it as a traceability violation

### Requirement: R5 — Stable findings with mandatory dispositions

The system SHALL give every finding a stable id, its axis, an affected location, a triggering scenario,
causal evidence and a class (`hard` or `judgement`), and SHALL assign exactly one disposition:
`fixed`, `rejected` or `deferred`.

#### Scenario: Validated before code changes

- **WHEN** a finding is returned to the developer
- **THEN** its evidence has been validated against the cited code, contract or a reproduction

#### Scenario: Deferred finding stays visible

- **WHEN** a finding is deferred
- **THEN** it links to a tracked item (`OQ-N` or a task) and carries an explicit delivery status

#### Scenario: Reopening requires new evidence

- **WHEN** a closed finding is raised again
- **THEN** the report includes new evidence that did not exist at the earlier revision

### Requirement: R6 — Evidence applicability is recorded

The system SHALL record the reviewed base and head revisions and the revision of the rules applied, and
SHALL recheck only the findings affected by later commits while retaining unaffected evidence at its
checked revision.

#### Scenario: New commits after a review

- **WHEN** commits land after a review
- **THEN** the report states which previous findings remain applicable and which were invalidated

### Requirement: R7 — Convergence rule for review cycles

The system SHALL limit the fix–review loop to three unsuccessful cycles, after which the approach is
diagnosed afresh and the question is escalated to the owner; the cycle threshold SHALL NOT clear an
unresolved blocker.

#### Scenario: Third unsuccessful cycle

- **WHEN** a third review cycle still returns blocking findings
- **THEN** the process proposes a diagnosis of the approach and requests an owner decision instead of a fourth identical pass

### Requirement: R8 — Aggregated verdict without reranking

The system SHALL produce one aggregated verdict per review, where a blocking finding on any axis yields
`Fail`; smell-baseline and style observations SHALL NOT block.

#### Scenario: Blocking finding on one axis only

- **WHEN** the Standards axis reports a documented-standard violation and the Spec axis reports nothing
- **THEN** the aggregated verdict is `Fail`

### Requirement: R9 — Output contract remains compatible

The review report SHALL keep `VERDICT: Pass` or `VERDICT: Fail` as its first line and SHALL keep the
per-finding `Where`, `Breaks` and `Fix` fields.

#### Scenario: Existing consumers keep working

- **WHEN** `acceptance.md` or the DoD checklist reads the review verdict
- **THEN** the verdict is available in the same first-line format as before

### Requirement: R10 — The reviewer stays read-only

The reviewer SHALL NOT modify code, tests or specifications; aggregation and the final verdict belong to
the orchestrator.

#### Scenario: Fix requested instead of applied

- **WHEN** a blocking finding requires a code change
- **THEN** the reviewer reports the required fix and the developer applies it

## C# Implementation Plan

None — изменение целиком документарное: новые и правленые Markdown-файлы под `.agents/`.

- **Layers touched:** none (harness/spec layer).
- **New types:** none.
- **DI registrations:** none.
- **NuGet packages:** none.
- **Guardrails:** не трогать `openspec/proposals/archive/**`; не менять контракт вердикта `VERDICT: Pass|Fail`;
  не копировать формулировки референсного набора; не заводить внешний issue tracker; не добавлять
  новых бизнес-требований.

## API / Contract Changes

None — HTTP/gRPC/событийные контракты не затрагиваются.

## Test Strategy

- **Unit (xUnit):** не применимо — исполняемого C#-кода предложение не добавляет.
- **Integration (`WebApplicationFactory<T>`):** не применимо.
- **Документарные проверки:**
  - состав предложения и сверка со схемой [`csharp-api.yaml`](../../../schemas/csharp-api.yaml)
    (обязательные разделы, ≥1 сценарий на требование);
  - конвенция скиллов ([`.agents/skills/README.md`](../../../../.agents/skills/README.md)): фронтматтер
    `name`/`description`/`argument-hint`, `name` = имя папки, рабочие относительные ссылки;
  - ручной прогон: две оси на реальном диффе — проверка исполнимости правил (см. «Непроверенные
    условия» в [`acceptance.md`](./acceptance.md)).
- **Command:** `dotnet build`/`dotnet test` не запускаются (кода нет); при появлении кода в репозитории
  гейт верификации обязателен.

## Capabilities

### New Capabilities

- `independent-review`: двухосевое независимое ревью изменения (Standards / Spec) с находками, имеющими
  устойчивые ID, обязательные диспозиции, правило сходимости и зафиксированную применимость улик.

### Modified Capabilities

- Нет — живые спецификации [`openspec/specs/`](../../../specs) пока содержат только `README.md`.

## Impact

**Добавляется:**

- `.agents/skills/code-review/SKILL.md` — процедура двухосевого ревью.
- `.agents/skills/code-review/references/findings.md` — жизненный цикл находки.
- `.agents/skills/code-review/references/smell-baseline.md` — базлайн запахов (judgement calls).
- `.agents/skills/code-review/agents/openai.yaml` — опциональный адаптер (по конвенции `agents/`).

**Изменяется:**

- `.agents/reviewer.md` — две оси, режим «только чтение», агрегация, сохранение контракта вердикта.
- `.agents/README.md`, `.agents/skills/README.md` — таблицы скиллов.
- `openspec/standards/05-definition-of-done.md` §5.5 — ссылка на двухосевой прогон.
- `CHANGELOG.md` — запись под `[Unreleased]`; `OPEN_QUESTIONS.md` — `OQ-7`.

**Риски и митигации:** см. [`design.md`](./design.md) §6 (стоимость ×2, дубли находок между осями,
лимит длины отчёта, отсутствие у Ревьюера права правки).

**Rollout:** изменение аддитивное и совместимое — вердикт `VERDICT: Pass|Fail` и формат находок сохранены,
поэтому ранее архивированные предложения и `acceptance.md` продолжают читаться без изменений.

**Rollback:** `git revert` коммита с правками `.agents/`; новых данных и миграций нет.

## Open Questions

- [ ] `OQ-7` — сделать двухосевое ревью обязательным режимом Ревьюера для всех предложений или оставить
  один проход для малых изменений? — _recommended default:_ обязателен для всех предложений; для малых
  изменений допускается последовательный запуск осей (независимость сохраняется, см. `design.md` §3, §6).

Закрытие вопроса = запись `D-NNN` в [`DECISIONS.md`](../../../../DECISIONS.md); сам вопрос ведётся в
[`OPEN_QUESTIONS.md`](../../../../OPEN_QUESTIONS.md).

## Performance & SLO

None — изменение не влияет на throughput, latency или ресурсы сервисов. Процессная цена (две оси вместо
одного прохода) отмечена и митигирована в [`design.md`](./design.md) §6; SLO не заявляются.

## Contracts

None — контракты черновиков (OpenAPI/gRPC/события) не меняются.

## Acceptance

[`acceptance.md`](./acceptance.md) — матрица «требование → проверка → результат» для `R1`..`R10`.
Все проверки сейчас в статусе `Not run`; непроверенные условия (живой прогон двух осей, стоимость процесса)
перечислены явно и имеют план проверки.

## Changelog

Планируемая запись в [`CHANGELOG.md`](../../../../CHANGELOG.md) под `[Unreleased]`:

- заголовок `## [0.3.0] — YYYY-MM-DD · Двухосевое ревью и жизненный цикл находок (001-two-axis-review)`;
- версия — **MINOR** (новое поведение процесса, обратная совместимость сохранена);
- секции по [`04-documentation.md` §4.6](../../../standards/04-documentation.md):
  - `### Добавлено` — скилл `code-review` и его `references/`;
  - `### Изменено` — `.agents/reviewer.md`, таблицы скиллов, DoD §5.5;
  - `### Не изменилось` — контракт `VERDICT: Pass|Fail`, формат находок `Where/Breaks/Fix`,
    скиллы `spec-first` и `implement-feature`;
  - `### Тесты` — документарные проверки; живой прогон двух осей — `Not run` до появления кода;
- привязка `(001-two-axis-review)` в заголовке обязательна;
- задача на запись — [`tasks.md`](./tasks.md) п. 7.3.

## Tasks

See [`tasks.md`](./tasks.md). Every task traces back to a requirement (`R1`..`R10`) above.
