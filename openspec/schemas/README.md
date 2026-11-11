# Schemas

Machine-readable validation schemas that define what a valid proposal/spec looks like for a given
project profile. `openspec/config.yaml` selects which schemas are active.

## Files

| Schema | Profile | Purpose |
| - | - | - |
| [`csharp-api.yaml`](./csharp-api.yaml) | `csharp-api` | Server profile: required sections, requirement/scenario grammar, C# code standards, tests, verification gate. |
| [`csharp-desktop.yaml`](./csharp-desktop.yaml) | `csharp-desktop` | Desktop profile: stack rules (Avalonia, local model runtime, SQLite/SQLCipher, in-process IPC, no analytics), resource budgets, licence inventory, provable privacy, desktop release gate. |

## How profiles relate

- One project selects **one** active profile: `project.profile` in [`../config.yaml`](../config.yaml).
- The active profile decides the **schema**, the **standard set** and the **DoD sections**:
  `csharp-api` → `csharp-api.yaml` + standards 01–11 + DoD 5.1–5.7;
  `csharp-desktop` → `csharp-desktop.yaml` + standards 01–11 **and** [`12-desktop.md`](../standards/12-desktop.md)
  + DoD 5.1/5.2/5.5/5.6/5.8 (server 5.3/5.4 are replaced by the desktop release checklist).
- Switching the active profile is a decision, recorded in [`DECISIONS.md`](../../DECISIONS.md).
- The server profile is never weakened by desktop rules and vice versa: a proposal is validated only
  against the active profile.

## How schemas are used

- **Agents** self-validate a proposal against the active schema before hand-off.
- **Reviewer** uses the schema as the checklist for the `Pass` / `Fail` verdict.
- **CI (optional)** can parse the YAML to fail a build when a proposal is invalid.

## Adding a profile

1. Create `openspec/schemas/<profile>.yaml` following `csharp-api.yaml`.
2. Add it to `schemas.active` in [`../config.yaml`](../config.yaml).
3. Reference the profile from a proposal's `Profile:` header.

## Note

The `*_pattern` values are regular expressions (YAML-escaped). Keep them tolerant enough to match
real Markdown but strict enough to catch missing sections.
