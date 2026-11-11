# @local/dsh-openspec-presets

Бандл-патч, который добавляет в профиль **`desktop`** пресет роли SDD из
[`agentic-openspec`](../..): **`sdd`** («SDD-роль»).

> **Один пресет, а не шесть.** Решение [`D-016`](../../DECISIONS.md) (гейт D-02(A)):
> шесть пресетов-ролей (`analyst`, `architect`, …) удалены. У каждого из них в
> `config.plugins` была **ровно одна** персона — агент роли не имел ни `read`, ни
> `pwsh`, ни `skill` (дефект P0-9). Пресет `sdd` несёт полную композицию
> `preset-standard` (22 плагина), а роль указывается **в тексте задачи**.

Зачем бандл, а не правка `cordis.patch.yml`: профиль `desktop` принадлежит
Electron-приложению, приложение перезаписывает свой пользовательский патч при
изменении настроек. Слой бандла применяется раньше пользовательского патча,
поэтому пресет не теряется.

## Установка

Профиль `desktop` уже подключён к этому бандлу через junction:

```text
~/.dsh/profiles/desktop/node_modules/@local/dsh-openspec-presets
  → (junction) → C:\Projects\agentic-openspec\dsh\presets-bundle
```

Если связь потеряна:

```
plugin_manager  action=install_bundle  target=C:\Projects\agentic-openspec\dsh\presets-bundle
```

## Как выбрать роль

**Настройки → «Управление агентом по умолчанию»** → в списке пресетов выбрать
**«SDD-роль (agentic-openspec)»** (внутренний `id` — `sdd`) → сохранить → начать новую сессию.

Бандл **не** меняет роль по умолчанию (`standard`, решение [`D-018`](../../DECISIONS.md)),
чтобы не навязывать SDD-персону другим проектам. Выбранный в UI пресет запоминается
для новых сессий.

## Что нужно, кроме бандла

1. **Открыть в Desktop рабочее пространство с SDD-каркасом** — `C:\Projects\agentic-openspec`
   (там `AGENTS.md`, `.agents/*.md`, `openspec/`). Персона `sdd` ссылается на эти файлы;
   их отсутствие = агент не знает правил.
2. **Провайдер и модель.** В `desktop` уже настроен `llm-pi-ai` (провайдер `routerai`) и
   `agent-default-model`, поэтому отдельно ничего задавать не нужно. Ключ `ROUTERAI_API_KEY`
   берётся из хранилища креденшлов.

## Проверка

```
plugin_manager  action=list_bundles     # @local/dsh-openspec-presets
plugin_manager  action=list_plugins     # строка preset-sdd
```

Машинная проверка композиции (≥ 8 плагинов, дефолт `standard`, `allowedAgentPresets`):

```powershell
./docs/ci/check-dsh-profile.ps1
```

## Удаление

```
plugin_manager  action=remove_bundle  target=@local/dsh-openspec-presets
```

## Ограничения

- **Роль — не песочница.** Персона задаёт контекст; права дают permission presets,
  а их для роли сейчас нет. Изоляция QA и Ревьюера — дисциплинарная плюс обязательная
  проверка `git status --porcelain` (см. [`.agents/reviewer.md`](../../.agents/reviewer.md)).
- **Ссылки на `openspec/` разрешаются относительно открытого воркспейса.** В другом
  воркспейсе роль будет ссылаться на несуществующие файлы.
- **Роль передаётся промптом**: пресет один, поэтому «роль по имени пресета» не работает.
  Это цена отказа от шести копий композиции (D-016).
