# @local/dsh-openspec-presets

Бандл-патч, который добавляет в профиль **`desktop`** шесть ролей SDD из
[`agentic-openspec`](..): `analyst`, `architect`, `csharp-dev`, `qa-engineer`,
`reviewer`, `ops-release`.

Зачем бандл, а не правка `cordis.patch.yml`: профиль `desktop` принадлежит
Electron-приложению, приложение перезаписывает свой пользовательский патч при
изменении настроек. Слой бандла применяется раньше пользовательского патча,
поэтому роли не теряются.

## Установка

```
plugin_manager  action=install_bundle  target=C:\Projects\agentic-openspec\dsh\presets-bundle
```

или из CLI (для профиля, не владеемого приложением):

```powershell
& $dsh plugin --profile desktop add "C:\Projects\agentic-openspec\dsh\presets-bundle"
```

## Что нужно, кроме бандла

1. **Открыть в Desktop рабочее пространство с SDD-каркасом** — `C:\Projects\agentic-openspec`
   (там `AGENTS.md`, `.agents/*.md`, `openspec/`). Персоны ролей ссылаются на эти файлы.
2. **Провайдер и модель.** В `desktop` уже настроен `llm-pi-ai` (провайдер `routerai`) и
   `agent-default-model = routerai/deepseek/deepseek-v4.1-flash`, поэтому отдельно ничего
   задавать не нужно. Ключ `ROUTERAI_API_KEY` берётся из хранилища креденшлов.
3. **Выбор роли** — переключатель пресетов в UI (`ui-agent-preset`). Бандл **не** меняет
   роль по умолчанию (`standard`), чтобы не навязывать SDD-персону другим проектам;
   выбранная в UI роль запоминается для новых сессий.

## Проверка

```
plugin_manager  action=list_bundles           # @local/dsh-openspec-presets
plugin_manager  action=list_plugins           # строки preset-analyst … preset-ops-release
```

## Удаление

```
plugin_manager  action=remove_bundle  target=@local/dsh-openspec-presets
```

## Ограничения

- Роли — не песочница: персоны задают контекст, права дают permission presets.
- Ссылки на `openspec/` разрешаются относительно **открытого воркспейса**; в другом воркспейсе
  роли будут ссылаться на несуществующие файлы.
- Бандл не переносит `ui-settings-general.welcomeNoticeVersion` и прочие настройки профиля
  `agentic-openspec` — только роли и дефолт пресета.
