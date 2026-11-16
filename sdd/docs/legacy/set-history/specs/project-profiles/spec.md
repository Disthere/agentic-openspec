# Spec delta — capability `project-profiles`

Капабилити о выбираемых профилях проекта: один проект — один профиль, схема и стандарты следуют выбору.
Дельта вливается в [`openspec/specs/`](../../../../../specs) при архивации предложения.

## ADDED Requirements

### Requirement: R1 — Both profiles coexist

The workspace SHALL describe at least two project profiles (`csharp-api`, `csharp-desktop`) and SHALL keep
the server profile's schema, standards and DoD sections unchanged.

#### Scenario: Server profile untouched

- **WHEN** `openspec/schemas/csharp-api.yaml` and DoD 5.1–5.7 are read
- **THEN** their content and numbering are unchanged by this proposal

#### Scenario: Two profiles are declared

- **WHEN** `openspec/config.yaml` is read
- **THEN** both profiles are declared with their schema, standards and stack sections

### Requirement: R2 — A project selects exactly one profile

A project SHALL select exactly one active profile, and the active schema, standards references and reviewer
checklist SHALL follow that selection.

#### Scenario: Active profile drives validation

- **WHEN** `project.profile` names a profile
- **THEN** the active schema and the referenced standards are those of that profile

#### Scenario: Switching profile is explicit

- **WHEN** a project switches from one profile to another
- **THEN** the change is recorded as a decision rather than edited silently
