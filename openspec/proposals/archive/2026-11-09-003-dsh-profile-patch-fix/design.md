# Design — 003-dsh-profile-patch-fix

Разбор отказа композиции профиля и обоснование правки. Все выводы получены из установленной сборки
DeepSeek Harness **0.2.2-rc.1** на машине владельца, а не из предположений.

## 1. Что произошло

Профиль скопирован в `~/.dsh/profiles/agentic-openspec` (SHA256 трёх файлов совпадают с репозиторием),
CLI найден (`%LOCALAPPDATA%\Programs\DeepSeek Harness\resources\runtime\cli\bin\dsh.cmd`) и запущен:

```text
dsh: [...\profiles\agentic-openspec\cordis.patch.yml] patch: entry "preset-analyst" not found
```

## 2. Причина: семантика патч-слоя

Патч-слой — массив записей; запись верхнего уровня **адресует существующий id** в уже собранном дереве
(override конфига / `disabled`), а новые плагины добавляются отдельным списком `insert`. Подтверждение —
официальный слой бандла ролей:

```yaml
- id: tool-subagent
  disabled: true

- insert:
    - id: agent-team
      name: '@deepseek-ai/dsh-experimental-agent-team'
      config: { maxMembers: 8, ... }
```

Мы же писали `- id: preset-analyst` / `- id: preset-architect` … как обычные записи → загрузчик искал эти id
в дереве и падал на первом же.

## 3. Что в профиле уже существует (нельзя вставлять повторно)

| id | Кто объявляет | Дефолт |
| - | - | - |
| `agent-default-model` | `dsh-base` | `provider: deepseek-official`, `model: deepseek-flash` |
| `agent-preset-registry` | `dsh-web-app` | `default: standard` |
| `agent-preset`, `dsh-persona`, `dsh-subagent`, `dsh-skill-filesystem` | `dsh-base` | — |

Следствие: реестр переопределяется (`- id: agent-preset-registry` + `config.default`), а шесть наших
пресетов — это новые id, значит только `insert`.

## 4. Канонический формат пресета (подтверждён двумя источниками)

README `@deepseek-ai/dsh-agent-preset`:

```yaml
- id: agent-preset-registry
  name: '@deepseek-ai/dsh-agent-preset-registry'
  config: { default: standard }
- id: preset-standard
  name: '@deepseek-ai/dsh-agent-preset'
  config:
    id: standard
    plugins: []
```

| Поле | Обязательность | Смысл |
| - | - | - |
| `id` | требуется | стабильный идентификатор пресета (внешняя запись патча адресует загрузчик) |
| `plugins` | требуется | список дочерних плагинов пресета |
| `name`, `description` | опционально | отображение в ростере |
| `order` | опционально | порядок в ростере |

README `@deepseek-ai/dsh-persona`: `prefix` (требуется), `suffix`, `complete`, `includeRuntimeContext`;
**строка персоны монтируется внутри композиции пресета** — глобальный монтаж конфликтует с регистрацией
персоны развёртывания и падает. В нашей прежней записи персона была внутри `config.plugins` — единственная
часть, которую не пришлось менять.

## 5. Решение: что меняется

1. Оставить в патче **один override реестра** (`default: csharp-dev`) — id существует в `dsh-web-app`.
2. Шесть пресетов перенести в **`- insert:`**, у каждого — `config.id`, `name`, `description`, `order` и
   `plugins` с `dsh-persona.prefix`.
3. **Модель на роль не задавать.** База рассчитывает на `deepseek-official`, владелец работает через
   `routerai` (`llm-pi-ai`, `ROUTERAI_API_KEY`); выдумывать провайдера в профиль нельзя — это решение
   владельца (`OQ-2`). До решения пресеты наследуют выбор модели сессии, а в патче остаётся помеченный
   блок-инструкция, как закрепить модель на роль одной строкой.
4. `install.ps1` переписать **ASCII-безопасно**: Windows PowerShell 5.1 читает `.ps1` как ANSI, если нет
   BOM, и кириллица в `throw` ломает разбор. Текст сообщений — английский; сам файл чистый ASCII.
5. `dsh/README.md` дополнить фактами установки: путь к CLI, ограничение `desktop` (Electron), семантика
   патча, приёмочная команда.

## 6. Альтернативы и почему отклонены

| Вариант | Почему нет |
| - | - |
| Добавить BOM в `.ps1` вместо ASCII | BOM решает PS 5.1, но файл остаётся хрупким к любому инструменту, срезающему BOM; ASCII-текст не имеет этой зависимости вовсе |
| Оставить шесть пресетов в отдельных `presets/*.yml` (как делает `dsh-web-app`) | требует своего `package.json` `dsh.bundle.patch`; для одного профиля это лишняя механика — патч-слой справляется |
| Сразу закрепить `routerai` в пресетах | выдуманный провайдер: ключ `ROUTERAI_API_KEY` и каталог моделей живут в окружении владельца, а не в шаблоне |
| Не трогать `install.ps1`, устанавливать копированием | установщик остаётся «на бумаге рабочим», а это уже привело к ложному состоянию в `SESSION-START.md` |

## 7. Трассируемость на стандарты

| Элемент | Норма |
| - | - |
| Факт отказа зафиксирован, не «на глаз» | [`constitution.md`](../../../constitution.md) §1 п. 4 «Измеряй, не заявляй» |
| Решение о провайдере — за владельцем | [`OPEN_QUESTIONS.md`](../../../../OPEN_QUESTIONS.md) (`OQ-2`), §1 п. 5 «Никаких молчаливых решений» |
| Приёмочная проверка `--dump-config` | [`05-definition-of-done.md`](../../../standards/05-definition-of-done.md) §5.3 (DoD скаффолда: собирается и запускается) |
| Запись в changelog с `(<ID>)` | [`04-documentation.md`](../../../standards/04-documentation.md) §4.6 |
| Правка не расширяет объём 002 | [`design.md`](../../archive/2026-11-10-002-lifecycle-and-roles/design.md) §6 (границы предложения) |
