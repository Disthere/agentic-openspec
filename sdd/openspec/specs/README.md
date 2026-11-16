# Specifications (living)

This is where **current** specifications live — one folder per capability. When a proposal is
archived, its deltas are folded in here so `specs/` always describes what the system does *today*.

## Layout

```text
specs/
└── <capability>/
    └── spec.md
```

## Spec format (OpenSpec conventions)

```markdown
# <capability> Specification

## Purpose
What this capability is responsible for.

## Requirements

### Requirement: <name>
The system SHALL <behavior>.

#### Scenario: <name>
- **WHEN** <trigger>
- **THEN** <observable result>
```

## How specs evolve

- **Propose** — write deltas under `openspec/proposals/<id>/specs/<capability>/spec.md` using
  `## ADDED Requirements` / `## MODIFIED Requirements` / `## REMOVED Requirements`.
- **Archive** — when the proposal is Done, merge the deltas into the matching file here and keep the
  proposal snapshot under `openspec/proposals/archive/`.

This folder starts empty on purpose — it fills up as proposals are archived.
