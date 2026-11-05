# Schemas

Machine-readable validation schemas that define what a valid proposal/spec looks like for a given
project profile. `openspec/config.yaml` selects which schemas are active.

## Files

| Schema | Profile | Purpose |
| - | - | - |
| [`csharp-api.yaml`](./csharp-api.yaml) | `csharp-api` | Required sections, requirement/scenario grammar, C# code standards, tests, verification gate. |

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
