# Spec delta — capability `product-lifecycle`

Процессная капабилити: фазы полного цикла продукта, их гейты и передачи.
Дельта вливается в [`openspec/specs/`](../../../../../specs) при архивации предложения.

## ADDED Requirements

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
