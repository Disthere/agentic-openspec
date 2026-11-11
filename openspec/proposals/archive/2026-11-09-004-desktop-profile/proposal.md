# Proposal: Desktop product profile — правила для Avalonia/LLamaSharp-стека рядом с микросервисным

- **ID:** 004-desktop-profile
- **Status:** Done <!-- Draft | Approved | In Progress | Done | Rejected -->
  — утверждено владельцем 2026-11-09 запросом «надо, чтобы и микросервисы остались, и под этот стек
  появились правила».
- **Approved by:** Disthere (владелец репозитория)
- **Approved at:** 2026-11-09
- **Owner:** Disthere (владелец репозитория)
- **Date:** 2026-11-09
- **Profile:** csharp-api (сам шаблон) → добавляется профиль `csharp-desktop`
- **Constitution:** [`openspec/constitution.md`](../../../constitution.md) (highest priority — read first)

## Context

Шаблон профилирован под **серверные** C#-приложения: `openspec/schemas/csharp-api.yaml`, стандарты 06–11
(API, persistence, messaging, security, observability, performance), DoD 5.3 (Dockerfile, k8s-манифесты,
health-checks) и DoD 5.4 (kubectl rollout, алерты). Для продукта уровня **Capsul-A** — десктопное
Windows-приложение («Цифровой Дом»: Avalonia 11+, локальные модели GGUF, всё на устройстве) — половина
этих пунктов неприменима, а нужных правил нет вовсе:

- нет правил на UI-стек (Avalonia + CommunityToolkit.Mvvm) и границы «UI ↔ ядро»;
- нет правил на локальный рантайм моделей (LLamaSharp/llama.cpp, ONNX Runtime GenAI, STT/TTS/VAD/OCR);
- нет правил на локальное хранилище (SQLite + sqlite-vec + SQLCipher, seed-фраза BIP39);
- нет правила «сеть — только через gateway с подписанным манифестом», аналитика запрещена;
- нет требования доказуемости приватности (архитектурные тесты NetArchTest + анализатор запрета сети);
- нет лицензионного инвентаря, хотя стек собран по лицензиям (без GPL-голосов, без NC);
- нет бюджетов ресурсов (старт, RAM/VRAM, latency инференса) вместо серверных SLO;
- нет десктопного релизного чек-листа (установщик без админа, подпись, откат версии, офлайн-режим).

При этом микросервисный профиль **остаётся рабочим**: он нужен и для серверной части, и для будущих
продуктов. Значит профиль должен быть **выбираемым**, а не заменой: один проект — один профиль,
схема и стандарты следуют за профилем.

Целевой результат: `openspec/config.yaml` описывает два профиля (`csharp-api`, `csharp-desktop`),
для десктопа появляются схема `openspec/schemas/csharp-desktop.yaml`, стандарт
[`openspec/standards/12-desktop.md`](../../../standards/12-desktop.md) и раздел DoD 5.8; Ревьюер сверяется
со стандартом **активного** профиля.

Капабилити: новые — `project-profiles`, `desktop-standards`. Живые спецификации `openspec/specs/` пусты.

## Sources

None — изменение процесса и стандартов; материалы заказчика (`inputs/`) здесь не разбираются.

Источник требований — решение владельца 2026-11-09 и зафиксированный им стек продукта Capsul-A
(раздел «6.2 Стек» концепции): UI — Avalonia 11+/CommunityToolkit.Mvvm; LLM — llama.cpp через LLamaSharp
(версия фиксируется), альтернатива ONNX Runtime GenAI (DirectML) для Lite-тира; STT — GigaAM/Whisper;
TTS — sherpa-onnx (Piper/VITS, без GPL и NC-голосов); VAD — Silero VAD (ONNX, MIT); Vision/OCR —
ONNX Runtime (PaddleOCR, Florence-2, CLIP/SigLIP, Apache-2.0/MIT); векторы — SQLite + sqlite-vec;
шифрование БД — SQLCipher; оркестрация — in-process шина (Channels) + named pipes, без HTTP-портов;
крипто — AES-256-GCM, HKDF, Ed25519; seed-фраза — BIP39 (24 слова); установщик — Velopack / Inno Setup
(офлайн); обновления — gateway с подписанным манифестом как единственная точка выхода в сеть;
аналитика — отсутствует; тесты архитектуры — NetArchTest + Roslyn-анализатор запрета сети.

## Requirements

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

## C# Implementation Plan

None — изменение процесса, стандартов, схемы и конфигов. C#-кода предложение не добавляет.

- **Layers touched:** none (spec/process layer).
- **NuGet packages:** none — стек продукта (LLamaSharp, Avalonia, SQLite/SQLCipher, ONNX Runtime) фиксируется
  правилами и будет подключаться в предложениях продукта, а не в шаблоне.
- **Guardrails:** не менять `csharp-api.yaml`, стандарты 01–11 и DoD 5.1–5.7 по содержанию; не добавлять
  правила, которые нельзя проверить (каждое правило — с проверкой или гейтом); не хранить модели и ключи
  в репозитории.

## API / Contract Changes

None — HTTP/gRPC-контракты не затрагиваются. Изменяется «контракт» выбора профиля:
`openspec/config.yaml` → `project.profile` → схема + стандарты.

## Test Strategy

- **Unit / Integration (C#):** не применимо — кода нет.
- **Проверки текста и конфигурации:**
  - YAML-синтаксис `openspec/config.yaml` и `openspec/schemas/csharp-desktop.yaml`;
  - паритет требований умбрелла-спеки и дельт `project-profiles` / `desktop-standards`;
  - наличие каждого из 8 требований в стандарте 12 / DoD 5.8 / схеме (трассировка R → файл);
  - резолвинг относительных ссылок;
  - сохранность стандартов 01–11 и нумерации DoD 5.1–5.7.
- **Команды:** зафиксированы в [`acceptance.md`](./acceptance.md).

## Capabilities

### New Capabilities

- `project-profiles`: два выбираемых профиля проекта (серверный и десктопный) со своими схемами и стандартами.
- `desktop-standards`: правила десктопного продукта — стек, хранилище, крипто, IPC, обновления, лицензии,
  бюджеты ресурсов, доказуемость приватности и DoD релиза.

### Modified Capabilities

- Нет.

## Impact

**Добавляется:**

- `openspec/schemas/csharp-desktop.yaml`, `openspec/standards/12-desktop.md`.

**Изменяется:**

- `openspec/config.yaml` — карта профилей и стек десктопа;
- `openspec/schemas/README.md`, `openspec/standards/README.md` — индексы и связь «профиль → схема/стандарты»;
- `openspec/standards/05-definition-of-done.md` — §5.8 (нумерация 5.1–5.7 не меняется);
- `.agents/reviewer.md`, `.agents/skills/code-review/SKILL.md` — ось Standards по активному профилю;
- `openspec/project.md` — как выбрать профиль;
- `CHANGELOG.md`, `docs/SESSION-START.md`.

**Риски и митигации:** [`design.md`](./design.md) §5 (расползание двух профилей, правила-декларации без
проверки, выбор профиля «на глаз», лицензионные риски стека).

**Rollout:** аддитивно для серверного профиля; десктоп-проект выбирает профиль одной строкой в `config.yaml`.

**Rollback:** `git revert`; выбор профиля возвращается на `csharp-api` одной правкой.

## Open Questions

- [ ] `OQ-10` — жёсткие значения бюджетов ресурсов десктопа (холодный старт, idle RAM, latency первого
  токена, размер установщика): _recommended default:_ зафиксировать после первого замера на целевом
  железе (walking skeleton), до этого стандарт требует «метрика + способ замера» без чисел.

## Performance & SLO

None для серверного профиля. Для десктопа стандарт 12 вводит **бюджеты ресурсов** вместо серверных SLO
(см. R5); числовые значения — `OQ-10` после первого замера.

## Contracts

None — контракты черновиков не меняются.

## Acceptance

[`acceptance.md`](./acceptance.md) — матрица `R1`..`R8`; отдельно отмечено, что проверено (структура,
трассировка, сохранность серверного профиля), а что осталось непроверенным (числовые бюджеты).

## Changelog

Планируемая запись в [`CHANGELOG.md`](../../../../CHANGELOG.md) под `[Unreleased]`:

- `### Добавлено` — профиль `csharp-desktop`: схема `openspec/schemas/csharp-desktop.yaml`, стандарт
  [`12-desktop.md`](../../../standards/12-desktop.md), DoD 5.8; серверный профиль сохранён без изменений;
- привязка `(004-desktop-profile)`; версия при срезе релиза — **MINOR**.

## Tasks

See [`tasks.md`](./tasks.md). Every task traces back to a requirement (`R1`..`R8`) above.
