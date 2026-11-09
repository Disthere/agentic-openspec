# Proposals

Feature proposals live here. A proposal is the **single source of truth** for a change and must be
approved before any code is written (see [`AGENTS.md`](../../AGENTS.md) and [`.clinerules`](../../.clinerules), rule 0).

## Naming

`<NNN>-<slug>` — zero-padded number + short kebab-case slug, e.g. `001-add-weather-endpoint`.

## Structure of a proposal

```text
proposals/
├── 000-template.md              # copy this to start
├── 001-add-weather-endpoint/
│   ├── proposal.md              # required — umbrella spec
│   ├── tasks.md                 # required
│   ├── performance.md           # required for perf-sensitive changes
│   ├── acceptance.md            # required — requirement → test → result matrix
│   ├── contracts/               # HTTP/gRPC/event contracts of the change
│   ├── design.md                # optional (non-trivial designs)
│   └── specs/
│       └── weather/spec.md      # requirement deltas for capability "weather"
└── archive/
    └── 2026-05-11-001-add-weather-endpoint/   # after completion
```

## Lifecycle

1. **Draft** — copy `000-template.md`, fill it in, set `Status: Draft`.
2. **Approved** — a human flips `Status: Approved` (required before implementation).
3. **In Progress** — Developer ticks `tasks.md`; code + tests land.
4. **Done** — Reviewer returns `Pass`.
5. **Archived** — move to `archive/<YYYY-MM-DD>-<NNN>-<slug>/` and fold deltas into
   [`../specs/`](../specs).

## Validation

Proposals are validated against [`../schemas/csharp-api.yaml`](../schemas/csharp-api.yaml): required
sections must be present and every requirement must have at least one scenario. Perf-sensitive changes
must also carry `performance.md`; every approved proposal carries `acceptance.md`. All of this is
subject to [`../constitution.md`](../constitution.md) (highest priority).

## Rule of thumb

One proposal ≈ one cohesive, reviewable change. If `tasks.md` has more than ~15 tasks or the
capability spans several systems, split it into multiple proposals.
