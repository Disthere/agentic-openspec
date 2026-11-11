# `openspec/` — Spec-Driven Development artifacts

This folder holds every specification and SDD artifact for the project. Nothing in `src/` is written
before its spec lands here (see [`AGENTS.md`](../AGENTS.md) and [`.clinerules`](../.clinerules), rule 0 — *Spec First*).

## Layout

```text
openspec/
├── config.yaml              # project profile + active schemas
├── project.md               # project context for agents (stack, conventions)
├── proposals/               # feature proposals
│   ├── 000-template.md      # copy this to start a new proposal
│   ├── <NNN-slug>/          # per-feature folder
│   │   ├── proposal.md
│   │   ├── tasks.md
│   │   ├── design.md        # optional
│   │   └── specs/<capability>/spec.md
│   └── archive/             # <YYYY-MM-DD>-<NNN>-<slug>/ after completion
├── schemas/                 # machine-readable validation schemas
│   └── csharp-api.yaml
└── specs/                   # living specifications (folded from archives)
    └── <capability>/spec.md
```

## Workflow

```text
Explore ──▶ Propose ──▶ (human approves) ──▶ Apply ──▶ Review ──▶ Archive
            (000-template)   proposals/<id>/   code+tests  Pass?    move to
                                                                   archive/ + fold
                                                                   into specs/
```

## Requirement / scenario format

```markdown
## ADDED Requirements
### Requirement: <name>
The system SHALL <behavior>.
#### Scenario: <name>
- **WHEN** <trigger>
- **THEN** <observable result>
```

## Relationship to the OpenSpec reference

This mirrors the OpenSpec (Fission-AI) `openspec/` layout: per-change folders under a proposals area,
`ADDED/MODIFIED Requirements` deltas, and an `archive/` of completed changes whose deltas are folded
into living `specs/`. The only rename is `changes/` → `proposals/`.
