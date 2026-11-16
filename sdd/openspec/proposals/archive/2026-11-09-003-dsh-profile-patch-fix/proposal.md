# Proposal: Fix the DSH profile patch layer for DeepSeek Harness 0.2.2-rc.1

- **ID:** 003-dsh-profile-patch-fix
- **Status:** Done <!-- Draft | Approved | In Progress | Done | Rejected -->
  — утверждено владельцем 2026-11-09 командой «установи DSH-профиль»: установка выявила отказ композиции.
- **Approved by:** Disthere (владелец репозитория)
- **Approved at:** 2026-11-09
- **Owner:** Disthere (владелец репозитория)
- **Date:** 2026-11-09
- **Profile:** csharp-api (see `openspec/config.yaml`)
- **Constitution:** [`openspec/constitution.md`](../../../constitution.md) (highest priority — read first)

## Context

Профиль `agentic-openspec` установлен (`~/.dsh/profiles/agentic-openspec`, файлы побайтово совпадают с
репозиторием), но **композиция не собирается**. Фактический отказ CLI:

```text
dsh: [...\.dsh\profiles\agentic-openspec\cordis.patch.yml] patch: entry "preset-analyst" not found
```

Причина установлена по схеме самой установки, а не по догадкам:

1. Патч-слой DSH — массив записей, каждая из которых либо **переопределяет существующий `id`**
   (`- id: <существующий id>` + `config:`/`disabled:`), либо **вставляет новые плагины** отдельным
   списком `- insert:`. Мы объявляли новые id (`preset-analyst` …) записями верхнего уровня — загрузчик
   искал их в уже собранном дереве и падал.
2. Внутренняя форма пресета у нас была верной: `config.id` + `config.plugins` (канон
   `@deepseek-ai/dsh-agent-preset`, подтверждён по README плагина и по слою официального бандла
   `@deepseek-ai/dsh-experimental-agent-team-profile`).
3. Реестр `agent-preset-registry` объявляет бандл `dsh-web-app` (`default: standard`) → в нашем профиле этот
   id **уже существует**, его нужно переопределять, а не вставлять повторно.
4. Базовый дефолт модели в `dsh-base`: `provider: deepseek-official`, `model: deepseek-flash`. Рабочая среда
   владельца использует провайдера **`routerai`** (видно в `desktop`-профиле: `llm-pi-ai` +
   `ROUTERAI_API_KEY`). Значит привязка «провайдер/модель на роль» не может быть выдумана — это решение
   владельца (`OQ-2`).

Дополнительно: `dsh/install.ps1` **не запускается** в Windows PowerShell 5.1 — скрипт содержит кириллицу
без BOM, и парсер ломается на ANSI-декодировании.

Целевой результат: профиль собирается, шесть ролей валидны, установщик запускается, README описывает
реальную проверку. Привязка моделей на роль остаётся за владельцем (`OQ-2`).

Капабилити: новая — `dsh-profile`. Живые спецификации `openspec/specs/` пока пусты.

## Sources

None — изменение обвязки; материалы заказчика не используются.

Источник требований — факты, полученные из установки владельца 2026-11-09:

- отказ CLI при `--dump-config` (текст выше) — `R1`, `R2`;
- канон формата: README плагинов `@deepseek-ai/dsh-agent-preset` и `@deepseek-ai/dsh-persona`,
  `dsh-experimental-agent-team-profile/cordis.patch.yml`, `dsh-web-app/cordis.patch.yml`
  (всё — внутри установленной сборки 0.2.2-rc.1);
- конфигурация провайдера владельца — `~/.dsh/profiles/desktop/cordis.patch.yml` (`llm-pi-ai`, `routerai`);
- незакрытый вопрос [`OQ-2`](../../../../OPEN_QUESTIONS.md) — провайдер и модели на роль.

## Requirements

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

## C# Implementation Plan

None — изменение обвязки DSH (YAML профиля, PowerShell-установщик, документация). C#-кода не добавляет.

- **Layers touched:** none (tooling/harness layer).
- **NuGet packages:** none.
- **Guardrails:** не менять `.cs`/`.csproj`; не задавать провайдера без решения владельца (`OQ-2`);
  не коммитить ключи и `.credentials.yaml`; не трогать профиль `desktop`.

## API / Contract Changes

None — HTTP/gRPC/событийные контракты не затрагиваются. Изменяется «контракт» профиля DSH
(`dsh/profile/cordis.patch.yml`), проверяемый `--dump-config`.

## Test Strategy

- **Unit / Integration (C#):** не применимо — кода нет.
- **Приёмочная проверка (главная):** `dsh --profile agentic-openspec --dump-config` завершается успехом и
  содержит шесть пресетов, один `agent-preset-registry` и персоны.
- **Проверки текста:** синтаксис YAML; отсутствие дублирующихся id; `insert` для новых id; персоны внутри пресетов.
- **Проверка установщика:** запуск `install.ps1` в Windows PowerShell 5.1 без парсерной ошибки.
- **Команды:** зафиксированы в [`acceptance.md`](./acceptance.md).

## Capabilities

### New Capabilities

- `dsh-profile`: корректный профиль DeepSeek Harness — семантика патч-слоя, шесть ролей-пресетов,
  установщик и проверка композиции.

### Modified Capabilities

- Нет.

## Impact

**Изменяется:**

- `dsh/profile/cordis.patch.yml` — переписан под семантику override + `insert`.
- `dsh/install.ps1` — ASCII-безопасный текст и печать реальной команды проверки.
- `dsh/README.md` — путь к CLI, ограничение `desktop`, семантика патча, приёмка.
- `CHANGELOG.md`, `docs/SESSION-START.md`, `OPEN_QUESTIONS.md` (`OQ-2` — данные о провайдере).

**Риски и митигации:** см. [`design.md`](./design.md).

**Rollout:** правка локальная; профиль переустанавливается копированием и проверяется `--dump-config`.

**Rollback:** `git revert`; при необходимости `dsh --from-default-profile <template>` для сброса профиля.

## Open Questions

- [ ] `OQ-2` — какой провайдер и модели закрепить на роли в этом профиле? _recommended default:_
  `routerai` (как в рабочем `desktop`-профиле владельца) c `deepseek/deepseek-v4.1-flash` для быстрых ролей
  и `~deepseek/deepseek-v4-pro-latest` для аналитика и архитектора; до решения пресеты наследуют выбор модели сессии.

## Performance & SLO

None — изменение не влияет на сервисы.

## Contracts

None — контракты черновиков не меняются.

## Acceptance

[`acceptance.md`](./acceptance.md) — матрица `R1`..`R6`; отдельно отмечено, что проверено живьём
(`--dump-config`), а что осталось непроверенным.

## Changelog

Планируемая запись в [`CHANGELOG.md`](../../../../CHANGELOG.md) под `[Unreleased]`:

- `### Исправлено` — профиль DSH: патч-слой переведён на семантику override + `insert`
  (композиция больше не падает на `entry "preset-analyst" not found`); `install.ps1` запускается в
  Windows PowerShell 5.1; `dsh/README.md` описывает реальный CLI и ограничение `desktop`;
- привязка `(003-dsh-profile-patch-fix)`; версия при срезе релиза — **PATCH**.

## Tasks

See [`tasks.md`](./tasks.md). Every task traces back to a requirement (`R1`..`R6`) above.
