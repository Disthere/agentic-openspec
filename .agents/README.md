# `.agents/` — роли и скиллы субагентов

Здесь хранятся **роли** и **скиллы**, которые главная сессия DeepSeek Harness использует в режиме
Оркестратора. Роль — это не просто описание: она владеет **артефактом** и закрывает **гейт**; роль без
артефакта и гейта не добавляется (правило допуска — [`openspec/constitution.md`](../openspec/constitution.md) §7).

## Роли

| Файл | Роль | Фаза | Отвечает за | Никогда не делает |
| - | - | - | - | - |
| [`analyst.md`](./analyst.md) | Продуктовый аналитик | Discovery | `inputs/` и реестр `IN-NNN`, ценность и измеримый критерий успеха, `OQ-N` | Не пишет спецификаций и кода; не выдумывает требования |
| [`architect.md`](./architect.md) | Архитектор | Spec, Design | Требования, диаграммы C4/Mermaid, `openspec/proposals/*` | Не пишет реализационный код |
| [`csharp-dev.md`](./csharp-dev.md) | Разработчик C# | Build | Реализацию по `tasks.md` + `dotnet build`/`dotnet test` | Не меняет спецификацию в одностороннем порядке |
| [`qa-engineer.md`](./qa-engineer.md) | Инженер верификации | Verify | `acceptance.md`, `performance.md`, воспроизводимые улики | Не правит код, который проверяет; не подтверждает непроверенное |
| [`reviewer.md`](./reviewer.md) | Ревьюер | Review | Двухосевой вердикт (Standards / Spec), находки с ID и диспозициями | Не правит код, который проверяет |
| [`ops-release.md`](./ops-release.md) | Ops / Release | Release, Operate, Feedback | Changelog и версия, миграции и откат, SLO/capacity/runbook, обратная связь из поддержки | Не выпускает релиз без плана отката и записи в changelog |

## Скиллы

Переиспользуемые параметризованные возможности лежат в [`skills/`](./skills). Каждый скилл — это папка
с файлом `SKILL.md`, который начинается с YAML-фронтматтера (`name`, `description`).
Поле `argument-hint` **не используется**: DSH его не читает (P2-30 плана), поэтому оно удалено из всех
скиллов и ролей. Не возвращайте его — это вводит в заблуждение.

- [`skills/spec-first/SKILL.md`](./skills/spec-first/SKILL.md) — превратить запрос в черновик спецификации.
- [`skills/implement-feature/SKILL.md`](./skills/implement-feature/SKILL.md) — реализовать утверждённую спецификацию.
- [`skills/code-review/SKILL.md`](./skills/code-review/SKILL.md) — двухосевое независимое ревью (Standards / Spec);
  каталоги — в `skills/code-review/references/`.

> `ai-writing-tells` из набора **удалён** (решение D-06): он не обслуживает ни один гейт набора.
> Если он нужен — это глобальный бандл скиллов DSH, а не часть шаблона.

## Протокол делегирования

Главная сессия **DeepSeek Harness** (Оркестратор) запускает по одному субагенту на сфокусированную цель
через `agentPreset` из профиля [`dsh/profile/cordis.patch.yml`](../dsh/profile/cordis.patch.yml), затем
объединяет полученные отчёты. Отдельного агента-оркестратора не существует: оркестратор — это сама
главная сессия.

```text
Запрос пользователя
   │
   ▼
Главная сессия DSH (Оркестратор, пресет `standard` — нейтральный, D-018)
   ├─ subagent agentPreset=sdd + «ты аналитик»      → inputs/, INDEX.md (IN-NNN) ─────┐ Discovery gate
   ├─ subagent agentPreset=sdd + «ты архитектор»    → openspec/proposals/<NNN-slug>/ ─┤ (человек утверждает)
   ├─ subagent agentPreset=sdd + «ты разработчик»   → src/ + tests/ (dotnet) ─────────┤ Build + Test gate
   ├─ subagent agentPreset=sdd + «ты QA»            → acceptance.md ────────────────┤ Verification gate
   ├─ subagent agentPreset=sdd + «ты ревьюер»       → VERDICT: Pass / Fail ─────────┤ Review gate
   ├─ subagent agentPreset=sdd + «ты ops-release»   → CHANGELOG, rollback, runbook ──┤ Release + Support гейты
   └─ отчёт пользователю
```

**Фактический механизм (решение D-016, гейт D-02(A) плана).** Роль доставляется **одним** пресетом
`sdd` — он несёт полную композицию `preset-standard` (22 плагина) и SDD-персону. Шести отдельных
пресетов-ролей больше нет: у каждого в `config.plugins` была ровно одна персона, и агент роли
не имел ни `read`, ни `pwsh`, ни `skill` — это был дефект P0-9.

Делегирование настраивается в `presets-bundle/cordis.patch.yml`:

```yaml
- id: tool-subagent-control
  config:
    allowedAgentPresets: [sdd]    # ровно один адресуемый пресет роли
```

Правила:

- Промпт субагента = **`agentPreset=sdd` + имя роли + файл роли + конкретная задача + путь к спецификации**.
  Роль уточняется промптом; персона `sdd` перечисляет `.agents/<роль>.md`, `AGENTS.md`,
  `openspec/constitution.md` §7 и `openspec/standards/`, поэтому правила доходят до субагента.
- Правила живут в `.agents/*` и `openspec/`; персона пресета их **не дублирует**.
- Проси у каждого субагента **краткий отчёт** (затронутые пути, ключевые решения, статус), чтобы основной
  контекст оставался чистым.
- Ревьюер независим от Разработчика и Инженера верификации; процедура двухосевая (Standards / Spec) по
  скиллу [`skills/code-review`](./skills/code-review/SKILL.md): один вердикт и два раздельных отчёта.
  Отдельного `read-only` permission-preset в DSH пока нет — изоляция дисциплинарная плюс обязательная
  проверка `git status --porcelain` (см. `.agents/reviewer.md`).
- Передавай роль **явно** в тексте задачи. Пресет `sdd` один, поэтому «роль по имени пресета» больше
  не работает — это цена отказа от шести копий композиции (D-016).
