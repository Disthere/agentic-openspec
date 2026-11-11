# Spec delta — capability `desktop-standards`

Капабилити о правилах десктопного продукта: стек, хранилище, крипто, IPC, обновления, лицензии, бюджеты,
доказуемость приватности, релизный DoD.
Дельта вливается в [`openspec/specs/`](../../../../../specs) при архивации предложения.

## ADDED Requirements

### Requirement: R3 — Desktop stack rules exist

The workspace SHALL provide a desktop standard that fixes the stack rules: UI layer and its boundary, local
model runtime, local storage, cryptography, in-process messaging without open ports, packaging and updates.

#### Scenario: UI boundary is defined

- **WHEN** the desktop standard is read
- **THEN** it states which layer owns the UI toolkit and forbids the core from depending on UI types

#### Scenario: No open ports

- **WHEN** the desktop standard is read
- **THEN** it forbids HTTP listeners and requires in-process channels or named pipes for internal transport

#### Scenario: Model runtime is named

- **WHEN** the desktop standard is read
- **THEN** it names the inference runtime, the model format and the version-pinning rule

### Requirement: R4 — License inventory is mandatory

The desktop profile SHALL require a licence inventory artefact naming every shipped component, its licence
and the obligations it carries, and SHALL forbid copyleft and non-commercial components in the shipped bundle.

#### Scenario: Inventory exists

- **WHEN** a desktop release is prepared
- **THEN** the licence inventory lists components, licences and obligations

#### Scenario: Forbidden licence detected

- **WHEN** a shipped component is GPL/AGPL or non-commercial
- **THEN** the release gate fails

### Requirement: R5 — Resource budgets replace service SLOs

The desktop profile SHALL define measurable resource budgets (cold start, idle memory, inference latency,
installer size) and SHALL require them to be measured instead of declaring service-level objectives.

#### Scenario: Budgets are measurable

- **WHEN** the desktop standard is read
- **THEN** each budget names a metric, a target and the way it is measured

#### Scenario: No server SLO claim

- **WHEN** a desktop change claims performance
- **THEN** the claim is backed by a measurement, not by a service SLO target

### Requirement: R6 — Privacy is provable

The desktop profile SHALL require that network egress happens only through the update gateway with a signed
manifest, that analytics is absent, and that the prohibition is enforced by architecture tests and a
Roslyn analyser, with a no-egress scenario recorded as acceptance evidence.

#### Scenario: Single egress point

- **WHEN** the desktop standard is read
- **THEN** it names the update gateway as the only outbound path and requires a signed manifest check

#### Scenario: Analyser enforces the ban

- **WHEN** code outside the gateway references network types
- **THEN** the build fails on the Roslyn analyser or the architecture test

#### Scenario: Evidence is recorded

- **WHEN** a release is prepared
- **THEN** a no-egress scenario (offline run) is recorded in the acceptance matrix

### Requirement: R7 — Desktop release DoD exists

The workspace SHALL define a desktop-product definition of done covering installer without administrator
rights, signature, update with rollback to the previous version, offline operation, resource budgets,
absent telemetry and a filled licence inventory.

#### Scenario: Release checklist is applied

- **WHEN** a desktop release is prepared
- **THEN** the checklist is applied and its results are recorded

#### Scenario: Rollback exists

- **WHEN** an update is published
- **THEN** a path back to the previous version is documented

### Requirement: R8 — Review cites the active profile

The reviewer SHALL check the change against the standards of the active project profile and SHALL cite the
profile-specific standard in Standards-axis findings.

#### Scenario: Profile standard is cited

- **WHEN** a Standards finding concerns desktop-only rules
- **THEN** it cites the desktop standard rather than a server standard
