# DeepSeek Harness (`dsh`) — обвязка SDD

> Отдельный каталог для работы нашего SDD-набора в **DeepSeek Harness** (`dsh`) — open-source
> agent harness от DeepSeek на архитектуре **«everything is a plugin»** (движок
> [Cordis](https://github.com/cordiverse/cordis)). Дев-превью: **возможны ломающие изменения**.

## Что внутри

| Путь | Назначение |
| - | - |
| [`profile/`](./profile) | Готовый DSH-профиль `agentic-openspec` (bundles + патч с ролями и моделями) |
| [`install.ps1`](./install.ps1) | Копирует профиль в `$DSH_HOME/profiles/agentic-openspec` |
| `README.md` | Эта инструкция |

Правила и артефакты **не дублируются** — DSH использует существующие из корня репозитория:

- правила — [`AGENTS.md`](../AGENTS.md);
- роли — [`.agents/*.md`](../.agents) (их текст вшит в персоны пресетов);
- спецификации и стандарты — [`openspec/`](../openspec);
- скиллы — [`.agents/skills/`](../.agents/skills) — **DSH подхватывает их автоматически**.

## Предпосылки

- **Node.js 18+** — для `npx @deepseek-ai/dsh`.
- **.NET SDK 10** (см. [`global.json`](../global.json)) — для гейта `dotnet build`/`dotnet test`.
- **Ключ DeepSeek API** (platform.deepseek.com) или доступ к вашему OpenAI-совместимому роутеру.

## Быстрый старт

`dsh` — приложение **DeepSeek Harness** (Electron). CLI поставляется вместе с ним и в `PATH` не попадает:

```powershell
# CLI из установленного приложения (в PATH его нет)
$dsh = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\resources\runtime\cli\bin\dsh.cmd'
& $dsh --version      # 0.2.2-rc.1 и выше
```

```powershell
# 1) Установить наш профиль (шесть ролей: аналитик, архитектор, разработчик, QA, ревьюер, Ops/Release)
powershell -ExecutionPolicy Bypass -File .\dsh\install.ps1

# 2) Проверить композицию (обязательный шаг, см. ниже)
& $dsh --profile agentic-openspec --dump-config
```

Дальше — открыть приложение, выбрать рабочее пространство (корень этого репозитория) и работать в
профиле `agentic-openspec`. Провайдер и модели задаются в Web UI (Settings → Models) либо в патче профиля.

> Профиль живёт в `$DSH_HOME/profiles/<name>` (`$DSH_HOME` = `~/.dsh`, если не переопределён),
> а **не** в репозитории. Поэтому `dsh/profile/` — это «исходник» профиля, который `install.ps1`
> разворачивает в домашний каталог DSH.

## Проверка композиции

```powershell
$dsh = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\resources\runtime\cli\bin\dsh.cmd'
& $dsh --profile agentic-openspec --dump-config   # ожидаемый код возврата: 0
```

В собранном дереве должны быть `agent-default-model`, один `agent-preset-registry` и наш пресет роли
**`preset-sdd`** (плюс поставляемые `preset-standard`, `preset-ptc`, `preset-minimal`, `preset-cordis`).
Шесть пресетов-ролей (`preset-analyst` и т.д.) удалены решением `D-016` — не возвращайте их.

Полезно: `--dump-config-schema` (JSON Schema записей и патчей — **тоже требует `--profile`**),
`--dump-default-config` (дерево без пользовательского слоя), `--from-default-profile <template>`
(сбросить профиль из поставляемого шаблона).

**Фактический список шаблонов** (проверено на DSH 0.2.2-rc.1, `--from-default-profile <name> --dump-config`):

| Шаблон | Строк в дереве | Что это |
| - | - | - |
| `web` | ~1244 | веб-приложение (используется профилем `desktop`) |
| `acp` | ~384 | ACP-сервер |
| `headless` | ~392 | headless-режим |
| `sdk` | ~439 | SDK-хост |
| `sdk-minimal` | ~158 | минимальный SDK-хост |

`tui` и `rescue` **не существуют** (CLI отвечает ошибкой) — в прежней версии этого README они были
указаны ошибочно (P1-20 плана).

> Профиль `desktop` принадлежит Electron-приложению: CLI отказывается его дампить
> (`profile "desktop" is managed exclusively by the Electron application`). Это нормально — правьте
> приложение, а не CLI.

## Патч-слой: override или insert

`cordis.patch.yml` — массив записей. Запись верхнего уровня **адресует существующий id** из бандлов:

```yaml
- id: agent-default-model          # id объявлен в dsh-base
  config: { provider: <провайдер>, model: <модель> }

- id: tool-subagent                # выключение плагина
  disabled: true
```

**Новые** плагины добавляются только списком `insert`:

```yaml
- insert:
    - id: preset-analyst           # новый id
      name: '@deepseek-ai/dsh-agent-preset'
      config: { id: analyst, plugins: [ ... ] }
```

Запись верхнего уровня с новым id ломает запуск:

```text
dsh: [...\cordis.patch.yml] patch: entry "preset-analyst" not found
```

Что уже объявлено бандлами (переопределять, но не вставлять повторно):

| id | Кто объявляет | Дефолт |
| - | - | - |
| `agent-default-model` | `dsh-base` | `deepseek-official` / `deepseek-flash` |
| `agent-preset-registry` | `dsh-web-app` | `default: standard` |
| `agent-preset`, `dsh-persona`, `dsh-subagent`, `dsh-skill-filesystem` | `dsh-base` | — |


## Как DSH находит скиллы

Файловый провайдер `dsh-skill-filesystem` сканирует корни в таком порядке приоритета:

| Приоритет | Источник | Путь |
| - | - | - |
| 100 | project-dsh | `<корень проекта>/.dsh/skills` |
| **200** | **project-agents** | **`<корень проекта>/.agents/skills`** ← наши скиллы |
| 300 | custom | `Config.customSkillDirs` |
| 400 | user-dsh | `<dshHome>/skills` |
| 500 | user-agents | `<agentsHome>/skills` |

Корень проекта — **ближайший предок, содержащий `.git`** (в этом репозитории есть). Значит
[`.agents/skills/spec-first`](../.agents/skills/spec-first), [`implement-feature`](../.agents/skills/implement-feature)
и новые скиллы проекта видны агенту сразу.

Формат скилла: каталог `<name>/SKILL.md` или плоский `<name>.md` (глубина — один уровень).
Фронтматтер: обязательны `name` и `description`; опционально `whenToUse`, `metadata`,
`disable-model-invocation`, `user-invocable`.

## Роль и модель (agent preset)

**Один пресет `sdd`** — решение `D-016` (гейт D-02(A) плана). Раньше здесь было шесть пресетов-ролей,
и у каждого в `config.plugins` лежала **ровно одна** персона: агент роли не имел ни `read`, ни `pwsh`,
ни `skill` (дефект P0-9). Теперь роль несёт полную композицию `preset-standard`.

| Пресет `id` | `order` | Модель | Плагинов | Что умеет |
| - | - | - | - | - |
| `sdd` | 10 | `deepseek/deepseek-v4.1-flash` | **22** | все инструменты стандарта + SDD-персона |

Роль **выбирается промптом**, а не отдельным пресетом: персоны `sdd` ссылается на `.agents/<роль>.md`,
`openspec/constitution.md` §7 и `openspec/standards/`, поэтому агент сам берёт нужную роль из задачи.
Роли цикла (аналитик → архитектор → разработчик → QA → ревьюер → Ops/Release), их владельцы и порядок
фаз — [`openspec/constitution.md`](../openspec/constitution.md) §7.

Состав композиции = `preset-standard` один-в-один, изменена только `persona.prefix`. Пресет объявлен
списком `insert` в [`presets-bundle/cordis.patch.yml`](./presets-bundle/cordis.patch.yml) — это
**единственный** источник (решение `D-017`, гейт D-03(A)); `profile/` содержит только scaffolding.

> **Модель** — решение владельца `OQ-2` → `D-007` (2026-11-09): провайдер `routerai`,
> `deepseek/deepseek-v4.1-flash`. Провайдер задаётся переопределением `llm-pi-ai`
> (ключ — из переменной `ROUTERAI_API_KEY`), дефолт модели — переопределением `agent-default-model`.
>
> **Дефолтный пресет сессии — `standard`** (нейтральный), решение `D-018` (гейт D-07(A)):
> Оркестратор не должен получать персону роли. Чтобы работать ролью, выберите `sdd` в UI.
>
> **Разные модели на роли** (если понадобится): в `plugins:` пресета `sdd` добавить
> `@deepseek-ai/dsh-agent-default-model`. Сейчас все роли на одной модели — так и задумано (D-007).

```yaml
- insert:                                   # НОВЫЕ плагины — только через insert
    - id: preset-architect                 # id записи патча (адресует загрузчик)
      name: '@deepseek-ai/dsh-agent-preset'
      config:
        id: architect                      # идентификатор пресета, его сохраняют сессии
        name: Архитектор
        description: Требования, спецификации, без кода
        order: 10                          # порядок в ростере
        plugins:                           # дочерние плагины пресета
          - name: '@deepseek-ai/dsh-persona'
            config: { prefix: "…текст роли со ссылкой на .agents/architect.md…" }
          # модель на роль (необязательно: задана глобально через agent-default-model)
          # - name: '@deepseek-ai/dsh-agent-default-model'
          #   config: { provider: routerai, model: deepseek/deepseek-v4.1-flash }
```

- **Модель на роль** — дочерним плагином `@deepseek-ai/dsh-agent-default-model`. Роли можно развести
  по разным моделям (архитектору — сильнее, ревьюеру — независимую от разработчика).
- **Персона роли** — `@deepseek-ai/dsh-persona` (`prefix`, `suffix`, `complete`, `includeRuntimeContext`).
  Текст персоны короткий и **ссылается на файл роли** — чтобы не дублировать правила.
- **Смена модели**: правите [`presets-bundle/cordis.patch.yml`](./presets-bundle/cordis.patch.yml) и
  перезапускаете; либо удаляете блок `agent-default-model` и задаёте модель в Web UI (Settings → Models).
  Смена модели из UI **не требует перезапуска** приложения, но требует новой сессии.
- **`default: standard`** в `agent-preset-registry` — нейтральный пресет для новых сессий (D-018).
  Пресет `sdd` выбирается в UI, когда нужна роль.

> Если DSH откажется принимать `agent-default-model` внутри `plugins:` — уберите его из пресетов
> (модель возьмётся из Web UI), роли продолжат работать без изменений.

## SDD-цикл в DSH

Тот же процесс, что и в других обвязках, инструментами DSH — по фазам жизненного цикла:

| Фаза | preset | В DSH |
| - | - | - |
| Discovery | `analyst` | разбор `inputs/`, регистрация `IN-NNN`, измеримый критерий успеха, `OQ-N` |
| Explore / Spec | `architect` | читает `openspec/specs/` и код (Plan mode) → `openspec/proposals/<NNN-slug>/` |
| Approve | — | утверждение человеком (`Status: Approved`) |
| Build | `csharp-dev` | код + гейт `dotnet build/test/format` |
| Verify | `qa-engineer` | `acceptance.md`, `performance.md` — воспроизводимые улики |
| Review | `reviewer` | `VERDICT: Pass` / нарушения по двум осям (Standards, Spec) |
| Release | `ops-release` | `CHANGELOG.md`, версия по SemVer, миграции, план отката |
| Operate / Feedback | `ops-release` | SLO, capacity, runbook; инцидент → `OQ-N` или предложение |
| Archive | — | перенос в `proposals/archive/` + вливание дельт в `specs/` |

Карта фаз с артефактами, гейтами и владельцами — [`openspec/constitution.md`](../openspec/constitution.md) §7;
DoD фаз — [`openspec/standards/05-definition-of-done.md`](../openspec/standards/05-definition-of-done.md) §5.6–5.7.

Опоры DSH: **Plan mode** (фаза разведки), **approvals / permission presets** (подтверждение правок
и команд), **subagents** с `agentPreset` (делегирование с собственной композицией и моделью),
**skills** (автоподхват из `.agents/skills`).

## Headless для CI

```powershell
& $dsh --profile headless "Прочитай AGENTS.md и создай предложение 001-<slug> через пресет architect"
```

`headless` — один свежий сеанс, печатает финальный ответ и выходит (удобно для пайплайнов).
Рядом: `--profile acp` (ACP stdio для редакторов-клиентов), `--profile sdk` (JSON-RPC),
`--profile sdk-minimal` (минимальное дерево).

## Ограничения и нюансы

1. **Developer preview** — «THERE WILL BE COMPATIBILITY-BREAKING CHANGES»; прочитайте `SAFETY.md`.
2. **Имя профиля `desktop` зарезервировано** под Electron — CLI им не управляет; поэтому наш профиль
   называется `agentic-openspec`.
3. **Скиллы — один уровень вглубь**: `code-review/references/…` — это ресурсы
   скилла (нормально); вложенные `**/SKILL.md` DSH намеренно не сканирует.
4. **`argument-hint`** (из наших Claude-скиллов) не входит в список полей DSH. Обычно
   игнорируется; если скилл не появился — удалите это поле из фронтматтера.
5. **`.clinerules` DSH не читает** — канон для DSH: `AGENTS.md` + `openspec/`.
6. **Переустановить профиль**: `& $dsh --profile agentic-openspec --from-default-profile web`, затем снова
   `install.ps1`.
7. **Управление плагинами профиля**: `& $dsh plugin --profile agentic-openspec <pnpm args>`.
8. **Профиль `desktop` CLI не обслуживает** — им владеет Electron-приложение; команды CLI и `--dump-config`
   для него отклоняются.

## Файлы

| Файл | Назначение |
| - | - |
| [`presets-bundle/cordis.patch.yml`](./presets-bundle/cordis.patch.yml) | **Единственный источник**: пресет `sdd`, персона, дефолт реестра (D-016, D-017) |
| [`presets-bundle/package.json`](./presets-bundle/package.json) | Манифест бандла (`dsh.bundle.patch`) |
| [`profile/package.json`](./profile/package.json) | Бандлы профиля (`dsh-base`, `dsh-web-app`) |
| [`profile/cordis.yml`](./profile/cordis.yml) | Корень профиля (пустой список) |
| [`install.ps1`](./install.ps1) | Установка профиля в `$DSH_HOME/profiles/agentic-openspec` (с бэкапом `.bak-<timestamp>`) |

> Каталог `profile/` — **тонкая обёртка**: персон и пресета в нём нет. Патч профиля производится из
> бандла при установке (`install.ps1`), поэтому двух расходящихся копий не существует (D-017, P1-11).

Официальная документация: <https://deepseek-harness.github.io/deepseek-harness/>.
Репозиторий: <https://github.com/deepseek-ai/deepseek-harness>.
