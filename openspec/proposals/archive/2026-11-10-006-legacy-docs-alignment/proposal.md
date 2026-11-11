# Proposal: Legacy docs alignment — привести существующую документацию проекта к нашей структуре

- **ID:** 006-legacy-docs-alignment
- **Status:** Done <!-- Draft | Approved | In Progress | Done | Rejected -->
  — утверждено владельцем 2026-11-10 командой «утверждаю 006».
- **Approved by:** Disthere (владелец репозитория)
- **Approved at:** 2026-11-10
- **Owner:** Disthere (владелец репозитория)
- **Date:** 2026-11-10
- **Profile:** любой (документ процесса)
- **Constitution:** [`openspec/constitution.md`](../../../constitution.md) (highest priority — read first)

## Context

Набор умеет разворачиваться в существующем проекте: [`docs/ADOPTION.md`](../../../../docs/ADOPTION.md) §3
(сценарий B) переносит набор, вливает конфиги (B1), восстанавливает поведение **по коду** (B2), оценивает
применимость стандартов (B3) и запускает первое мелкое изменение (B4). Но там же стоит честная оговорка
**«Пока не покрыто»**: если у проекта уже есть **своя документация иной структуры** — свои ADR, ТЗ,
wiki/Confluence/Google Docs вне репозитория, `docs/` с другой иерархией, свой `CHANGELOG.md`,
исторические/archived документы, документы, противоречащие коду — инструкция молчит. Такие проекты
разворачиваются «частично»: процесса вокруг продукта больше, а документация остаётся в прежнем виде.

Чем это плохо:

- **Два описания одного поведения.** Старая документация и наша спека/ADR говорят разное, и никто
  не знает, чему верить. Конституция §1 п. 3 (Traceability) и §1 п. 5 (никаких молчаливых решений)
  в такой ситуации не выполняются: ссылаться не на что, а расхождение не зафиксировано.
- **Baseline «по коду» без карты документов.** Архитектор на шаге B2 восстанавливает поведение по коду
  и README, но не знает, что в проекте уже есть ТЗ, ADR и runbook — и восстанавливает заново то, что
  можно было проверить и перенести.
- **Страх необратимости.** Перенос и тем более удаление чужих документов — решение владельца, а не агента;
  без реестра и гейта любое «приведение к структуре» рискует стереть историю проекта.
- **Внешняя документация вне поля зрения.** Wiki/Confluence/Google Docs живут вне репозитория, и агент
  их не видит; при этом часть из них задаёт требования, без которых спецификация «из воздуха».

Тема зафиксирована как `OQ-14` в [`OPEN_QUESTIONS.md`](../../../../OPEN_QUESTIONS.md) (таблица + разбор
с подвопросами) и как оговорка в [`docs/ADOPTION.md`](../../../../docs/ADOPTION.md) §3.

**Целевой результат:** процедура, которая (1) сначала **только читает** и строит реестр документов и карту
соответствий «их документ → наш артефакт», (2) затем — **по явному утверждению человека построчно** —
приводит документацию к нашей структуре, (3) оставляет один источник истины на каждое поведение и
(4) проверяется воспроизводимо: «новый участник находит ответ за один переход».

Капабилити: новая — `docs-alignment`.

Границы: предложение **не переписывает конституцию** и **не вводит новую роль**. По конституции §7 п. 4
роль допускается только с собственным артефактом и гейтом; здесь артефакт — реестр документов, гейт —
утверждение плана человеком, и он уже есть у Оркестратора. Это документ процесса: стандарт документации
(§4.10) + правки инструкции развёртывания + три готовых промпта.

## Sources

None — документ процесса; материалы заказчика (`inputs/`) не используются.

Источники требований:

- `OQ-14` в [`OPEN_QUESTIONS.md`](../../../../OPEN_QUESTIONS.md) — вопрос владельца 09.11.2026, семь
  подвопросов из разбора плюс восьмой («документы, противоречащие коду») из постановки задачи;
- [`docs/ADOPTION.md`](../../../../docs/ADOPTION.md) §0 (адресат промптов — Оркестратор), §3 (сценарий B
  и оговорка «Пока не покрыто»), §5 (список человеческих действий), §7 (проверка развёртывания);
- [`openspec/constitution.md`](../../../constitution.md) §1 п. 3 и 5 (трассируемость, никаких молчаливых
  решений), §3 (гейты), §7 п. 4 (допуск роли);
- [`openspec/standards/04-documentation.md`](../../../standards/04-documentation.md) §4.1 (уровни документации),
  §4.6 (changelog), §4.7–4.8 (`OQ-N` / `D-NNN`), §4.9 (`inputs/`: «неактуальное помечается, не удаляется»);
- [`openspec/standards/05-definition-of-done.md`](../../../standards/05-definition-of-done.md) §5.1, §5.4;
- [`openspec/proposals/005-adoption-guide/proposal.md`](../../005-adoption-guide/proposal.md) — R2 («только
  промпты»), формат и стиль, к которым это предложение продолжение.

## Requirements

Дельта — в [`specs/docs-alignment/spec.md`](./specs/docs-alignment/spec.md). Нумерация `R1`..`R7`
трассируется к подвопросам `OQ-14` — таблица в [`design.md`](./design.md) §5.1. Базовая карта соответствий
«их документ → наш артефакт», которую уточняет реестр, живёт в одном месте —
[`design.md`](./design.md) §5.2 (единый источник, без копии в этом файле).

### Requirement: R1 — Inventory and correspondence map

The session SHALL build, before any document is moved or rewritten, a registry of the project's existing
documents that records for each document where it lives (repository path or external URL), its owner, who
uses it, its actuality and which toolkit artifact it corresponds to; the registry SHALL be the single input
for every later document decision.

#### Scenario: Inventory is read-only

- **WHEN** the inventory step is run in a project that already has documentation
- **THEN** a registry file appears and no existing document is moved, renamed, rewritten or deleted

#### Scenario: Every registered document gets a counterpart and an action

- **WHEN** a document is entered in the registry
- **THEN** the row names the toolkit artifact it corresponds to (or an explicit "no counterpart") and one
  action: transfer, pointer, archive, external pointer, or open question

### Requirement: R2 — Single source of truth and pointer documents

The alignment SHALL leave exactly one description of each behaviour: either the document's content is moved
into a toolkit artifact, or the legacy document becomes a pointer document that carries no normative text and
links to that artifact; two parallel descriptions of one behaviour SHALL NOT remain.

#### Scenario: Transferred content leaves a pointer, not a copy

- **WHEN** a document row is approved for transfer
- **THEN** its content lands in the target artifact and the old location holds a pointer with a status marker
  and a link, and the pointer contains no rules of behaviour

#### Scenario: Duplicate description stops the row

- **WHEN** two documents describe the same behaviour
- **THEN** the step stops that row and reports the duplication instead of keeping both descriptions

### Requirement: R3 — Documents living outside the repository

The alignment SHALL decide for every external document (wiki, Confluence, Google Docs) whether its content is
exported into the repository or the document stays external behind a registry row with URL, owner and reason;
documents containing credentials, secrets or personal data SHALL NOT be copied into the repository.

#### Scenario: Content that defines behaviour is exported

- **WHEN** an external document defines behaviour or a decision that the project must obey and access rights
  allow copying it
- **THEN** its content lands in a toolkit artifact (`inputs/` as `IN-NNN`, an ADR, a spec or a runbook) and
  the registry points at both the artifact and the external URL

#### Scenario: Impossible export keeps a pointer row

- **WHEN** an external document cannot be exported (no rights, secrets, personal data, size)
- **THEN** the registry keeps its URL, owner and the reason, and the behaviour it describes is captured in a
  toolkit artifact or raised as an open question

### Requirement: R4 — Historical documents and a pre-existing changelog

The alignment SHALL NOT delete historical or archived documents: they SHALL stay in place with an archive
marker and a registry row; a document that a newer document has superseded SHALL be marked outdated with a
link to its replacement and SHALL NOT be duplicated; a pre-existing `CHANGELOG.md` SHALL be analysed rather
than frozen blindly — its entries that are still relevant SHALL be carried into `CHANGELOG.md` as dated
history with the source id, the remaining history SHALL stay in place as an appendix with a single pointer,
and new entries SHALL be written only to `CHANGELOG.md`.

#### Scenario: Archive is marked, not deleted

- **WHEN** a document is classified as historical or archived
- **THEN** it stays at its path with the archive marker, keeps its registry row and is reachable from it

#### Scenario: Foreign changelog is analysed, not copied blindly

- **WHEN** the project already has its own changelog
- **THEN** every entry is classified as still relevant or obsolete, the relevant ones are carried into
  `CHANGELOG.md` as dated history with the source id, the rest stays as an appendix behind one pointer line,
  and all new entries appear only in `CHANGELOG.md` with the change id

#### Scenario: Nothing is lost when the foreign changelog is dropped as a live file

- **WHEN** the foreign changelog stops being the live change history
- **THEN** its full original content is preserved (in the appendix or at its original path), so a reader can
  still reach every historical entry

#### Scenario: Document superseded without contradicting the code

- **WHEN** a document is outdated because a newer document replaced it, and the code does not contradict it
- **THEN** it gets the outdated/superseded marker and a registry row, its content is not duplicated into a
  toolkit artifact, and the row names the document that replaced it

### Requirement: R5 — Documents contradicting the code

When a document contradicts the implemented behaviour, the code SHALL be treated as the factual source of
behaviour, the document SHALL be marked outdated or superseded, and the discrepancy SHALL be recorded as an
open question with a recommended option instead of being resolved silently.

#### Scenario: Code wins as the fact

- **WHEN** a document describes behaviour that differs from the code
- **THEN** the code is recorded as the current fact and the document is marked outdated or superseded

#### Scenario: Discrepancy becomes a tracked question

- **WHEN** a discrepancy is found
- **THEN** it is recorded in `OPEN_QUESTIONS.md` as an `OQ-N` (or attached to an existing one) with a
  recommended default, and the registry row links to it

### Requirement: R6 — One-hop answer verification

The alignment SHALL be verified reproducibly: a fixed set of newcomer questions SHALL be answered from the
repository entry points within one link, and the result SHALL be reported as a pass/fail table rather than a
judgement by eye.

#### Scenario: Fixed question set and a ready-made prompt

- **WHEN** the verification is run
- **THEN** a defined question list and a ready-made prompt produce a per-question pass/fail table with hop
  counts

#### Scenario: Machine-checkable part of the check

- **WHEN** the verification is run
- **THEN** every registry link resolves, every row has a target artifact or an explicit action, archived
  documents carry a marker, and pointer documents match the template and carry no rules

### Requirement: R7 — Discoverability and change recording

The alignment procedure SHALL be discoverable from the repository entry points and recorded like any other
change: the adoption guide SHALL cover it as ready-made prompts, the documentation standard SHALL state the
rules, and the changelog entry SHALL carry the id of this proposal.

#### Scenario: Adoption guide covers legacy documentation

- **WHEN** the adoption guide is read for an existing project
- **THEN** it lists an inventory step before the code baseline step and an apply step after the first change,
  as ready-made prompts addressed to the orchestrator

#### Scenario: Registry is discoverable from the maps

- **WHEN** the repository maps in `AGENTS.md` or `README.md` are read
- **THEN** they point to the legacy documentation registry

#### Scenario: Change is recorded

- **WHEN** `CHANGELOG.md` is read
- **THEN** the entry carries `(006-legacy-docs-alignment)`

## C# Implementation Plan

None — документ процесса. C#-кода предложение не добавляет.

- **Layers touched:** none.
- **NuGet packages:** none.
- **Guardrails:** ничего не удалять и не перемещать без явного утверждения человека; промпты адресованы
  только Оркестратору и не содержат терминальных команд для человека; реестр не хранит копии документов
  (только путь/URL, владельца и соответствие); секреты и персональные данные в репозиторий не копируются.

## API / Contract Changes

None — контракты не затрагиваются. «Контракт» процедуры — формат реестра, шаблон документа-указателя,
маркеры статусов и три промпта; они зафиксированы в спецификации и дизайне.

## Test Strategy

- **Unit / Integration (C#):** не применимо — кода нет.
- **Проверки документа (машинные):**
  - обязательные разделы `proposal.md` по схеме активного профиля
    ([`schemas/csharp-api.yaml`](../../../schemas/csharp-api.yaml));
  - у каждого требования ≥ 1 сценарий с `**WHEN**`/`**THEN**`; паритет `R1`..`R7` между `proposal.md`
    и дельтой `specs/docs-alignment/spec.md` (те же ID и названия);
  - `tasks.md`: секции `## N. <Область>`, пункты `- [ ] N.N <задача> (R…)`, ≤ 15 задач, каждое требование
    покрыто хотя бы одной задачей;
  - ссылки резолвятся из папки предложения; пути ещё не созданных файлов даны текстом (обратные кавычки),
    а не ссылками;
  - черновики промптов: первая строка — «Ты — Оркестратор SDD этого проекта»; внутри блоков нет команд
    для человека (`powershell`, `dotnet `, `git `, `Copy-Item`, `npm`);
  - в черновике B5 есть гейт утверждения построчно и запрет удаления.
- **Граничные случаи:** проект без внешней документации; проект без своего changelog; документ без
  владельца; документ, который нельзя открыть (нет прав); пустой `docs/`.
- **Команда:** `dotnet test` не применима (кода нет). Проверки выполняются агентом по списку выше
  и фиксируются в [`acceptance.md`](./acceptance.md).

## Capabilities

### New Capabilities

- `docs-alignment`: процедура приведения существующей документации проекта иной структуры к структуре
  набора — реестр документов и карта соответствий, правило «источник истины один», указатели и маркеры
  архива, разбор чужого changelog, внешняя документация, расхождения «документ vs код», проверка
  «ответ за один переход».

### Modified Capabilities

- Нет.

## Impact

**Добавляется (в наборе — шаблоны, которые переезжают в проект вместе с `docs/`):**

- `docs/legacy/README.md` — правила ведения: назначение, статусы, шаблон строки реестра, шаблон
  документа-указателя, маркер архива, чек-лист «ответ за один переход»;
- `docs/legacy/INDEX.md` — реестр `LEG-NNN` с колонками «документ → где живёт → владелец → актуальность →
  наш артефакт → действие → статус» и примером заполнения;
- `docs/legacy/CHANGELOG-FROZEN.md` — приложение для той части чужой истории изменений, которая
  не переносится в проектный `CHANGELOG.md` (не дополняется).

**Изменяется:**

- [`docs/ADOPTION.md`](../../../../docs/ADOPTION.md) — §3: оговорка «Пока не покрыто» заменяется покрытием,
  добавляются шаг **B1a** (инвентаризация и карта, до B2) и шаг **B5** (применение, после B4) с готовыми
  промптами; §0 — строки B1a/B5 в таблице адресатов; §5 — «утвердить план приведения документации»
  в списке человеческих действий; §7 — промпт проверки «ответ за один переход»; §9 — ссылка на реестр;
- [`openspec/standards/04-documentation.md`](../../../standards/04-documentation.md) — новый подраздел
  §4.10 «Документация, существовавшая до внедрения SDD (чужая структура)» + перекрёстные ссылки из §4.1
  и §4.9;
- `AGENTS.md` и `.clinerules` (синхронно), [`README.md`](../../../../README.md),
  [`openspec/project.md`](../../../project.md), [`docs/SESSION-START.md`](../../../../docs/SESSION-START.md) —
  строка `docs/legacy/` в картах репозитория и готовая команда;
- [`OPEN_QUESTIONS.md`](../../../../OPEN_QUESTIONS.md) — `OQ-14` в «Закрытые», регистрация `OQ-15`…`OQ-20`;
- [`DECISIONS.md`](../../../../DECISIONS.md) — `D-NNN` по решениям владельца;
- [`CHANGELOG.md`](../../../../CHANGELOG.md) — запись под `[Unreleased]` с привязкой `(006-legacy-docs-alignment)`.

**Не меняется:** конституция; роли и пресеты (`.agents/`, `dsh/profile/`); стандарты кроме 04;
`docs/architecture/`, `docs/operations/`; `src/`, `tests/`, `*.cs`, `*.csproj`.

**Риски и митигации:** [`design.md`](./design.md) §4 — реестр как второй источник истины; агент
«улучшает» чужие документы; потеря владельца и контекста при переносе; указатель с нормативным текстом;
секреты и персональные данные в выгрузке; незамеченные дубли; молчаливое решение расхождения
«документ vs код»; расхождение ADOPTION и стандарта; стоимость инвентаризации на большом проекте.

**Rollout:** аддитивно и по гейту. Сначала только реестр (`docs/legacy/`), затем — по утверждённым
построчно строкам — указатели и переносы. Ни один документ не удаляется: оригинал либо остаётся
с маркером архива, либо превращается в документ-указатель.

**Rollback:** `git revert` правок набора; в целевом проекте — откат коммита приведения документации.
Если перенос строки утверждён и применён, обратный перенос делается отдельным решением владельца
(документы не теряются: указатель всегда указывает на наш артефакт).

## Open Questions

Все пункты закрыты ответами владельца 10.11.2026; решения — [`DECISIONS.md`](../../../../DECISIONS.md).

- [x] `OQ-14` — закрыт: владелец утвердил это предложение → `D-008`.
- [x] `OQ-15` — реестр ведётся **каталогом `docs/legacy/`** → `D-009`.
- [x] `OQ-16` — внешняя документация (wiki/Confluence/Google Docs): **только указатели**; выгружается
  лишь невыразимое указателем и в наш артефакт → `D-011`.
- [x] `OQ-17` — оригинал после переноса **всегда остаётся документом-указателем**, удаления нет → `D-010`.
- [x] `OQ-18` — чужой `CHANGELOG.md` **анализируется**: актуальные записи переносятся в проектный
  `CHANGELOG.md` с указанием источника, исторические — приложением `CHANGELOG-FROZEN.md` → `D-012`.
  Принято **не по рекомендованному дефолту** (была заморозка); R4 и §4.10 обновлены.
- [x] `OQ-19` — **код — факт** (он же baseline B2); расхождение → `OQ-N` → `D-013`.
- [x] `OQ-20` — **пока чек-лист и промпт** «ответ за один переход»; скрипт/CI — при росте реестра → `D-014`.

## Performance & SLO

None — изменение не влияет на производительность, задержки и ресурсы. `performance.md` не требуется
(схема: `performance.required_when` — изменение, влияющее на пропускную способность, задержку или ресурсы).

## Contracts

None — HTTP/gRPC/событийные контракты не затрагиваются; `contracts/` не создаётся.

## Acceptance

[`acceptance.md`](./acceptance.md) — матрица `R1`..`R7`, отдельно и честно отмечено непроверенное:
применение процедуры на реальном проекте с чужой документацией не выполнялось (нет второго проекта
под рукой), понятность промптов человеком машинно не проверяется.

## Changelog

Планируемая запись в [`CHANGELOG.md`](../../../../CHANGELOG.md) под `[Unreleased]`:

- **Добавлено** — `docs/legacy/` (реестр документов `LEG-NNN`, правила ведения, приложение
  истории изменений): инвентаризация существующей документации и карта соответствий «их документ → наш
  артефакт», правило «источник истины один», документы-указатели и маркеры архива (`006-legacy-docs-alignment`);
- **Добавлено** — три готовых промпта для Оркестратора: **B1a** (инвентаризация и карта, только чтение),
  **B5** (приведение документации к нашей структуре с построчным утверждением), проверка «ответ за один
  переход» (`006-legacy-docs-alignment`);
- **Изменено** — [`docs/ADOPTION.md`](../../../../docs/ADOPTION.md) §3: оговорка «Пока не покрыто» снята,
  добавлены шаги B1a и B5, §0/§5/§7 дополнены; [`openspec/standards/04-documentation.md`](../../../standards/04-documentation.md)
  §4.10 — правила для документации, существовавшей до внедрения SDD (`006-legacy-docs-alignment`);
- **Изменено** — `OQ-14` закрыт (`D-NNN`), карты репозитория и `docs/SESSION-START.md` указывают на реестр
  (`006-legacy-docs-alignment`);
- **Не изменилось** — шаги B1–B4 и сценарий A инструкции; конституция, роли и пресеты, стандарты кроме 04;
  поведение продукта не меняется (изменений кода нет);
- привязка `(006-legacy-docs-alignment)`; версия при срезе релиза — **MINOR** (новая процедура процесса,
  публичные контракты не меняются).

## Tasks

See [`tasks.md`](./tasks.md). Every task traces back to a requirement (`R1`..`R7`) above.
