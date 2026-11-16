# Spec delta — capability `docs-alignment`

Капабилити о приведении **существующей документации проекта иной структуры** к структуре набора:
реестр документов и карта соответствий, правило «источник истины один», документы-указатели и маркеры
архива, заморозка чужого changelog, внешняя документация (wiki/Confluence/Google Docs), расхождения
«документ vs код», проверка «ответ за один переход».

Дельта вливается в [`openspec/specs/`](../../../../../specs) при архивации предложения.
Паритет с [`proposal.md`](../../../proposal.md) — 1:1 по ID и названиям требований.

## ADDED Requirements

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
