# Spec delta — capability `independent-review`

Изменение процессное: capability описывает независимое ревью кода и его артефакты.
Дельта вливается в [`openspec/specs/`](../../../../../specs) при архивации предложения.

## ADDED Requirements

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

#### Scenario: Independence preserved without parallelism

- **WHEN** the two axes are executed sequentially because parallel capacity is unavailable
- **THEN** each axis still produces its conclusion before the other axis result is applied

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

#### Scenario: Bug fix checked against root cause

- **WHEN** the change fixes a defect
- **THEN** the review states whether the root cause or only one symptom is addressed

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
