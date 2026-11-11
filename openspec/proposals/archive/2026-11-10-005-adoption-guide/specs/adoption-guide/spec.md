# Spec delta — capability `adoption-guide`

Капабилити о развёртывании набора в проектах и о цикле изменений после развёртывания.
Дельта вливается в [`openspec/specs/`](../../../../../specs) при архивации предложения.

## ADDED Requirements

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
