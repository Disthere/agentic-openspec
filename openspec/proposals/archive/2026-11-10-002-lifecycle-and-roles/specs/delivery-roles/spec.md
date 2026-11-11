# Spec delta — capability `delivery-roles`

Капабилити о ролях доставки и эксплуатации и о среде их исполнения (DeepSeek Harness).
Дельта вливается в [`openspec/specs/`](../../../../../specs) при архивации предложения.

## ADDED Requirements

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

#### Scenario: Content lands in the right place

- **WHEN** a proposed duty has no artefact and no gate
- **THEN** it is added to a standard, a DoD checklist or a skill instead of a new role file
