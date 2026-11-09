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
с файлом `SKILL.md`, который начинается с YAML-фронтматтера (`name`, `description`, `argument-hint`).

- [`skills/spec-first/SKILL.md`](./skills/spec-first/SKILL.md) — превратить запрос в черновик спецификации.
- [`skills/implement-feature/SKILL.md`](./skills/implement-feature/SKILL.md) — реализовать утверждённую спецификацию.
- [`skills/code-review/SKILL.md`](./skills/code-review/SKILL.md) — двухосевое независимое ревью (Standards / Spec);
  каталоги — в `skills/code-review/references/`.
- [`skills/ai-writing-tells/SKILL.md`](./skills/ai-writing-tells/SKILL.md) — аудит текстов на «AI-признаки».

## Протокол делегирования

Главная сессия **DeepSeek Harness** (Оркестратор) запускает по одному субагенту на сфокусированную цель
через `agentPreset` из профиля [`dsh/profile/cordis.patch.yml`](../dsh/profile/cordis.patch.yml), затем
объединяет полученные отчёты. Отдельного агента-оркестратора не существует: оркестратор — это сама
главная сессия.

```text
Запрос пользователя
   │
   ▼
Главная сессия DSH (Оркестратор)
   ├─ subagent agentPreset=analyst      → inputs/, INDEX.md (IN-NNN), критерий успеха ─┐ Discovery gate
   ├─ subagent agentPreset=architect    → openspec/proposals/<NNN-slug>/ ────────────┤ (человек утверждает)
   ├─ subagent agentPreset=csharp-dev   → src/ + tests/ (dotnet build/test) ─────────┤ Build + Test gate
   ├─ subagent agentPreset=qa-engineer  → acceptance.md, performance.md ─────────────┤ Verification gate
   ├─ subagent agentPreset=reviewer     → VERDICT: Pass | Fail (две оси) ────────────┤ Review gate
   ├─ subagent agentPreset=ops-release  → CHANGELOG, rollback, runbook ──────────────┤ Release + Support гейты
   └─ отчёт пользователю
```

Правила:

- Промпт субагента = **файл роли + конкретная задача + путь к спецификации**. Персоны пресетов перечисляют
  файлы правил явно, поэтому правила доходят до субагента независимо от того, читается ли `AGENTS.md`
  как инструкции воркспейса (см. `OQ-1`).
- Правила живут в `.agents/*` и `openspec/`; персоны пресетов их **не дублируют**.
- Проси у каждого субагента **краткий отчёт** (затронутые пути, ключевые решения, статус), чтобы основной
  контекст оставался чистым.
- Ревьюер независим от Разработчика и Инженера верификации; процедура двухосевая (Standards / Spec) по
  скиллу [`skills/code-review`](./skills/code-review/SKILL.md): один вердикт и два раздельных отчёта.
- Роль, которой нет в профиле DSH, не делегируется: сначала пресет, потом задача.
