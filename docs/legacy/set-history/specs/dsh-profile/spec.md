# Spec delta — capability `dsh-profile`

Капабилити об обвязке DeepSeek Harness: корректен ли патч-слой профиля и собирается ли он.
Дельта вливается в [`openspec/specs/`](../../../../../specs) при архивации предложения.

## ADDED Requirements

### Requirement: R1 — Patch entries follow DSH patch semantics

The profile patch layer SHALL override existing plugin ids by their id and SHALL declare new plugins only
through an `insert` list; it SHALL NOT declare a new plugin as a top-level id-targeted entry.

#### Scenario: Existing id is overridden

- **WHEN** the patch targets a plugin id that a bundle already declares
- **THEN** the entry carries only `config` (and optionally `name`), without declaring a new plugin

#### Scenario: New plugin is inserted

- **WHEN** the profile needs a plugin id that no bundle declares
- **THEN** the entry lives inside a top-level `insert` list

### Requirement: R2 — Unique ids and a resolvable default

The profile SHALL keep every plugin id unique in the composed tree, and the preset registry default SHALL
name a preset that the profile itself declares.

#### Scenario: No duplicate registry

- **WHEN** the composed tree is inspected
- **THEN** exactly one `agent-preset-registry` entry exists

#### Scenario: Default names a declared preset

- **WHEN** the registry default is read
- **THEN** it matches the `config.id` of one of the declared presets

### Requirement: R3 — Presets declare the canonical fields

Every preset SHALL declare `config.id`, `name`, `description`, `order` and a `plugins` list, and its persona
row SHALL be mounted inside the preset composition rather than globally.

#### Scenario: Preset is complete

- **WHEN** a preset entry is read
- **THEN** it carries `config.id`, `name`, `description`, `order` and a non-empty `plugins` list

#### Scenario: Persona is scoped to the preset

- **WHEN** a persona row appears
- **THEN** it is nested inside a preset `plugins` list, never at the top level of the patch

### Requirement: R4 — Model binding is one explicit, replaceable block

The profile SHALL keep provider and model binding in one clearly marked block, SHALL state that the values
must exist in the target environment, and SHALL NOT invent a provider the owner has not confirmed.

#### Scenario: Binding is marked replaceable

- **WHEN** the profile is read
- **THEN** the model block names the provider and states how to change it

#### Scenario: Unconfirmed provider is not invented

- **WHEN** the owner has not confirmed a provider for this profile
- **THEN** the presets inherit the session model selection instead of hard-coding an unverified provider

### Requirement: R5 — Installer runs on Windows PowerShell 5.1

`dsh/install.ps1` SHALL parse and run under Windows PowerShell 5.1, and SHALL print the real verification
command for the installed app.

#### Scenario: Script parses under PS 5.1

- **WHEN** the script is started by Windows PowerShell 5.1
- **THEN** it completes without a parser error

#### Scenario: Verification command is printed

- **WHEN** the install succeeds
- **THEN** the output names the CLI location and the `--dump-config` check

### Requirement: R6 — Documentation matches the installed product

`dsh/README.md` SHALL document how the CLI is invoked in the shipped app, that the `desktop` profile is
managed exclusively by the Electron application, the patch semantics (override vs insert), and the
acceptance check for the profile.

#### Scenario: CLI path is documented

- **WHEN** the README is read
- **THEN** it names the CLI inside the installed app and the Electron-managed profile restriction

#### Scenario: Semantics are documented

- **WHEN** a maintainer edits the patch
- **THEN** the README explains when to override an id and when to insert
