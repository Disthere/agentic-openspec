# Proposal: <short imperative title>

- **ID:** <NNN>-<slug>
- **Status:** Draft <!-- Draft | Approved | In Progress | Done | Rejected -->
- **Owner:** <github handle / role>
- **Date:** <YYYY-MM-DD>
- **Profile:** csharp-api (see `openspec/config.yaml`)
- **Constitution:** [`openspec/constitution.md`](../constitution.md) (highest priority — read first)

> Copy this file into `openspec/proposals/<NNN>-<slug>/proposal.md` and fill every section.
> Delete guidance comments as you go. A proposal is approved only when a human flips `Status`.

## Context

Why this change exists. Current behaviour, the problem, and the outcome we want. Reference the
capability(s) in `openspec/specs/` this touches.

## Sources

Input materials from the customer ([`inputs/`](../../inputs/README.md)), with `IN-NNN` ids from
[`inputs/INDEX.md`](../../inputs/INDEX.md). List only what this change actually uses; anything unresolved
becomes an Open Question.

- `IN-001` — <what it defines> — `inputs/briefs/IN-001-<slug>.pdf`.

Write "None" when the change follows from the spec alone (no external input material).

## Requirements

Numbered, testable requirements. Each one carries at least one scenario.

### Requirement: <name>

The system SHALL <behavior>.

#### Scenario: <name>

- **WHEN** <trigger>
- **THEN** <observable, checkable result>

## C# Implementation Plan

- **Layers touched:** Domain / Application / Infrastructure / API.
- **New types:** `record XyzRequest`, `interface IXyzService`, `class XyzService`, ...
- **DI registrations:** `builder.Services.AddScoped<IXyzService, XyzService>();`
- **NuGet packages:** list any new packages **with justification** (default: none).
- **Guardrails:** what the implementation must NOT do.

## API / Contract Changes

| Method | Route | Request | Response | Status | Breaking? |
| - | - | - | - | - | - |
| POST | `/api/<resource>` | `<Dto>` | `<Dto>` | 201 Created | No |

State clearly if this is a breaking change and the migration path. Write "None" if no API change.

## Test Strategy

- **Unit (xUnit):** list the behaviours to assert (map to scenarios above).
- **Integration (`WebApplicationFactory<T>`):** endpoint/contract cases.
- **Edge cases:** validation failures, null/empty, concurrency, 404/409/422.
- **Command:** `dotnet test --filter "FullyQualifiedName~<Area>"`.

## Capabilities

### New Capabilities

- `<capability-name>`: one-line description.

### Modified Capabilities

- `<capability-name>`: what changes.

## Impact

- Files to add/change (paths).
- Risks and mitigations.
- Rollout / migration / rollback notes.

## Open Questions

- [ ] <question> — _recommended default:_ <default>.

Resolved items move to `OPEN_QUESTIONS.md` and `DECISIONS.md`
(see [`../standards/04-documentation.md`](../standards/04-documentation.md) §4.7–4.8).

## Performance & SLO

For changes affecting throughput, latency or resources, fill `performance.md` (request profile, targets,
environment, baseline vs candidate). **No SLO claim without a reproducible load test.**
See [`../standards/11-performance.md`](../standards/11-performance.md).

## Contracts

For changes touching HTTP/gRPC/event contracts, add them under `contracts/`
(OpenAPI, `*.proto`, event schemas) with version and compatibility notes.
See [`../standards/06-api.md`](../standards/06-api.md) and [`../standards/08-messaging.md`](../standards/08-messaging.md).

## Acceptance

Fill `acceptance.md`: a requirement → test → result matrix with explicitly marked untested conditions.

## Changelog

This change requires an entry in [`CHANGELOG.md`](../../CHANGELOG.md) under `[Unreleased]`:

- header `## [X.Y.Z] — YYYY-MM-DD · <summary> (<ID>)`, where `(<ID>)` is this proposal's id;
- version bump per SemVer: **MINOR** — new behaviour, **PATCH** — fix, **MAJOR** — breaking change;
- sections per [`../standards/04-documentation.md`](../standards/04-documentation.md) §4.6, including
  `Не изменилось` when the default behaviour is preserved and `Миграция` for breaking changes;
- add a task for the changelog entry to `tasks.md`.

Every proposal plans its changelog entry; the release DoD requires it
([`../standards/05-definition-of-done.md`](../standards/05-definition-of-done.md) §5.4).

## Tasks

See `tasks.md`. Every task must trace back to a requirement above.
