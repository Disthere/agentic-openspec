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

```powershell
# 1) Запустить DSH и открыть Web UI (http://127.0.0.1:3080)
npx @deepseek-ai/dsh web

# 2) В Web UI: Settings -> Models -> введите DeepSeek API key и сохраните
#    (маршрут модели становится доступен сразу, без перезапуска)

# 3) Choose workspace -> выберите КОРЕНЬ этого репозитория

# 4) Установить наш профиль (роли: Архитектор / Разработчик / Ревьюер)
powershell -ExecutionPolicy Bypass -File .\dsh\install.ps1
```

Запуск с нашим профилем:

```powershell
npx @deepseek-ai/dsh --profile agentic-openspec
```

> Профиль живёт в `$DSH_HOME/profiles/<name>` (`$DSH_HOME` = `~/.dsh`, если не переопределён),
> а **не** в репозитории. Поэтому `dsh/profile/` — это «исходник» профиля, который `install.ps1`
> разворачивает в домашний каталог DSH.

## Проверка композиции

```powershell
npx @deepseek-ai/dsh --profile agentic-openspec --dump-config
```

В собранном дереве должны быть `agent-default-model`, `agent-preset-registry` и три пресета:
`architect`, `csharp-dev`, `reviewer`.

Полезно: `--dump-config-schema` (JSON Schema вместо значений), `--dump-default-config` (чистый
шаблон без ваших слоёв).

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
и ваш новый [`ai-writing-tells`](../.agents/skills/ai-writing-tells) видны агенту сразу.

Формат скилла: каталог `<name>/SKILL.md` или плоский `<name>.md` (глубина — один уровень).
Фронтматтер: обязательны `name` и `description`; опционально `whenToUse`, `metadata`,
`disable-model-invocation`, `user-invocable`.

## Роли и модели (agent presets)

| Роль | preset `id` | Модель (по умолчанию в патче) | Задача |
| - | - | - | - |
| Архитектор | `architect` | `deepseek/deepseek-v4-pro` | спецификация, C4/Mermaid, без кода |
| Разработчик | `csharp-dev` *(default)* | `deepseek/deepseek-v4.1-flash` | код + `dotnet build/test` |
| Ревьюер | `reviewer` | `deepseek/deepseek-v4.1-flash` | вердикт `VERDICT: Pass/Fail` |

Роли объявлены тремя записями `@deepseek-ai/dsh-agent-preset` в
[`profile/cordis.patch.yml`](./profile/cordis.patch.yml):

```yaml
- id: preset-architect
  name: '@deepseek-ai/dsh-agent-preset'
  config:
    id: architect
    name: Архитектор
    order: 10
    plugins:
      - name: '@deepseek-ai/dsh-agent-default-model'
        config: { provider: deepseek, model: deepseek/deepseek-v4-pro }
      - name: '@deepseek-ai/dsh-persona'
        config: { prefix: "…текст роли со ссылкой на .agents/architect.md…" }
```

- **Модель на роль** — дочерним плагином `@deepseek-ai/dsh-agent-default-model`. Роли можно развести
  по разным моделям (архитектору — сильнее, ревьюеру — независимую от разработчика).
- **Персона роли** — `@deepseek-ai/dsh-persona` (`prefix`, `suffix`, `complete`, `includeRuntimeContext`).
  Текст персоны короткий и **ссылается на файл роли** — чтобы не дублировать правила.
- **Смена модели**: правите `cordis.patch.yml` и перезапускаете; либо удаляете блок
  `agent-default-model` и задаёте модель в Web UI (Settings → Models).
- **`default: csharp-dev`** в `agent-preset-registry` — роль по умолчанию для новых сессий.

> Если DSH откажется принимать `agent-default-model` внутри `plugins:` — уберите его из пресетов
> (модель возьмётся из Web UI), роли продолжат работать без изменений.

## SDD-цикл в DSH

Тот же процесс, что и в других обвязках, инструментами DSH:

| Этап | В DSH |
| - | - |
| Explore | агент читает `openspec/specs/` и код (Plan mode) |
| Propose | сессия пресета **Архитектор** → `openspec/proposals/<NNN-slug>/` |
| Approve | утверждение человеком (`Status: Approved`) |
| Apply | сессия пресета **Разработчик** → код + гейт `dotnet build/test` |
| Review | сессия пресета **Ревьюер** → `VERDICT: Pass` или нарушения |
| Archive | перенос в `proposals/archive/` + вливание дельт в `specs/` |

Опоры DSH: **Plan mode** (фаза разведки), **approvals / permission presets** (подтверждение правок
и команд), **subagents** с `agentPreset` (делегирование с собственной композицией и моделью),
**skills** (автоподхват из `.agents/skills`).

## Headless для CI

```powershell
npx @deepseek-ai/dsh --profile headless "Прочитай .clinerules и создай предложение 001-<slug> через Архитектора"
```

`headless` — один свежий сеанс, печатает финальный ответ и выходит (удобно для пайплайнов).
Рядом: `--profile acp` (ACP stdio для редакторов-клиентов), `--profile sdk` (JSON-RPC),
`--profile sdk-minimal` (минимальное дерево).

## Ограничения и нюансы

1. **Developer preview** — «THERE WILL BE COMPATIBILITY-BREAKING CHANGES»; прочитайте `SAFETY.md`.
2. **Имя профиля `desktop` зарезервировано** под Electron — CLI им не управляет; поэтому наш профиль
   называется `agentic-openspec`.
3. **Скиллы — один уровень вглубь**: `ai-writing-tells/references/…` и `scripts/` — это ресурсы
   скилла (нормально); вложенные `**/SKILL.md` DSH намеренно не сканирует.
4. **`argument-hint`** (из наших Cline/Claude-скиллов) не входит в список полей DSH. Обычно
   игнорируется; если скилл не появился — удалите это поле из фронтматтера.
5. **`.clinerules` DSH не читает** — канон для DSH: `AGENTS.md` + `openspec/`.
6. **Переустановить профиль**: `npx @deepseek-ai/dsh --profile agentic-openspec --from-default-profile web`,
   затем снова `install.ps1`.
7. **Управление плагинами профиля**: `npx @deepseek-ai/dsh plugin --profile agentic-openspec <pnpm args>`.

## Файлы

| Файл | Назначение |
| - | - |
| [`profile/package.json`](./profile/package.json) | Бандлы профиля (`dsh-base`, `dsh-web-app`) |
| [`profile/cordis.yml`](./profile/cordis.yml) | Корень профиля (пустой список) |
| [`profile/cordis.patch.yml`](./profile/cordis.patch.yml) | **Роли, персоны, модели** — правьте здесь |
| [`install.ps1`](./install.ps1) | Установка профиля в `$DSH_HOME/profiles/agentic-openspec` |

Официальная документация: <https://deepseek-harness.github.io/deepseek-harness/>.
Репозиторий: <https://github.com/deepseek-ai/deepseek-harness>.
