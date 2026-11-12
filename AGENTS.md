# AGENTS.md

Этот файл — **канон правил** для агентов (стандарт [agents.md](https://agents.md)) и главный источник
истины для **DeepSeek Harness**. [`.clinerules`](./.clinerules) — совместимое зеркало для других
инструментов: при расхождении действует **этот файл**.

> ⏸ **Режим старта:** ничего не делать до явной команды пользователя (ни разведки, ни правок, ни коммитов).
> Порядок развёртывания набора — [`docs/ADOPTION.md`](./docs/ADOPTION.md).
> Состояние конкретной сессии — в `docs/session/` (не коммитится; шаблон — [`docs/SESSION-START-TEMPLATE.md`](./docs/SESSION-START-TEMPLATE.md)).

## Что это за репозиторий

**Агентное рабочее пространство Spec-Driven Development (SDD)** для проекта на **C# / .NET**.
Главная сессия **DeepSeek Harness** выступает Оркестратором и делегирует работу субагентам с
`agentPreset` из [`.agents/`](./.agents) — по фазам жизненного цикла
([`openspec/constitution.md`](./openspec/constitution.md) §7).

## 0. Золотое правило — Spec First

**Никакого продакшн-кода, пока в [`openspec/proposals/`](./openspec/proposals) нет утверждённой
спецификации** (`Status: Approved`, поля `Approved by:` / `Approved at:` заполнены). Нарушение этого
правила — дефект процесса, а не «быстрый путь».

Исключения — только через §5 конституции с записью `D-NNN` в [`DECISIONS.md`](./DECISIONS.md).

> **Граница действия.** Spec First относится к **продукту**: код, контракты, поведение системы.
> Правки **самого набора** (канон, стандарты, схемы, роли, пресет DSH, `tools/`) идут иначе:
> запись `D-NNN` + проверка командой, без фиктивной спецификации. Обоснование —
> [`openspec/constitution.md`](./openspec/constitution.md) §1 п. 7. Требовать полный цикл для правки
> документации значило бы выдумывать требования, что запрещено §1 п. 5.

## 1. Стандарты C# / .NET

- **Платформа:** **.NET 10** (`net10.0`), **C# 14**. Решение [`D-015`](./DECISIONS.md); `.NET 8`/`9` — EOL
  с 2026-11-10. SDK зафиксирован в [`global.json`](./global.json) (`10.0.401`).
- **Настройки проектов:** `<Nullable>enable</Nullable>`, `<ImplicitUsings>enable</ImplicitUsings>`,
  `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, `<LangVersion>latest</LangVersion>`, анализаторы.
- **Стиль:** file-scoped namespaces, primary constructors, `record` для неизменяемых данных, pattern
  matching, `required`/`init`, collection expressions, `var` — только когда тип очевиден.
- **Null:** `ArgumentNullException.ThrowIfNull`, `?.`/`??`/`??=`; проверки — **только** `is null`/`is not null`
  (никогда `== null`). Null-forgiving `!` — только с комментарием-обоснованием.
- **Асинхронность:** `async`/`await` на всём пути, пробрасывай `CancellationToken`; **никогда** `.Result`/`.Wait()`.
- **Именование:** `PascalCase` — типы/члены, `camelCase` — параметры/локальные, `_camelCase` — приватные
  поля, `I` — интерфейсы, `T` — дженерики, суффикс `Async` — асинхронные методы.
- **Модификаторы доступа** — всегда явно; неизменяемые поля — `readonly`.
- **Горячие пути** (обработка запроса, сериализация): без лишних аллокаций и LINQ; `Span`/`ArrayPool`/`ValueTask`.
- **Анализаторы:** NetAnalyzers + SonarAnalyzer.CSharp + Meziantou.Analyzer; максимальная длина строки — 120.
- **Оформление:** Allman, 4 пробела, file-scoped namespace; правила — в [`.editorconfig`](./.editorconfig),
  проверяются `dotnet format`.

### ASP.NET Core (где применимо)

- Новые эндпоинты — **Minimal APIs**; контроллеры оставляй там, где их уже использует конвенция проекта.
- Встроенный **DI** с корректными временами жизни; **паттерн Options** (`IOptions<T>`), не читай
  `IConfiguration` внутри бизнес-логики.
- `TypedResults`/`Results<...>` с правильными кодами состояния; ошибки — через `ProblemDetails`.
- Валидация на границе (FluentValidation или `DataAnnotations`); домен независим от фреймворка.

### Тестирование

- **xUnit v3** + **FluentAssertions** (≤ 7.2.2; 8.x — платный Xceed, запрещён) + **NSubstitute**.
  **Moq не используется** — в CPM его нет.
- Именование: `Method_Scenario_ExpectedResult` или `Should_...`; одно поведение на тест; табличные случаи —
  `[Theory]`/`[InlineData]`; интеграционные — `WebApplicationFactory<T>`.
- Раскладка: `tests/<Project>.UnitTests`, `tests/<Project>.IntegrationTests`.
- **Бутстрап тестового проекта:** `dotnet new install xunit.v3.templates` (однократно), затем
  `dotnet new xunit3`. Шаблон `dotnet new xunit` (v2) под CPM даёт `NU1008`/`NU1010` — не использовать.
- Версии пакетов — **только** в [`Directory.Packages.props`](./Directory.Packages.props); inline `Version=` не писать.

### Инструменты — только dotnet CLI

Никогда `msbuild`, никогда IDE-only шаги:

```powershell
dotnet restore
dotnet build --configuration Release --no-restore
dotnet test  --configuration Release --no-build
dotnet format --verify-no-changes
dotnet new sln / dotnet sln add <proj>
```

Единственный источник команд гейта — [`openspec/config.yaml`](./openspec/config.yaml) → `commands:`.
Другие документы ссылаются туда, а не переписывают команды.

## 2. Процесс SDD

Каждое изменение проходит фазы жизненного цикла. **Единственный источник полной карты фаз**
(артефакт · гейт · владелец) — [`openspec/constitution.md`](./openspec/constitution.md) §7 и
`openspec/config.yaml` → `lifecycle` (10 фаз, включая `archive`).

Короткая карта: **Explore** (прочитай `specs/` и код, правок нет) → **Propose** (`proposals/<NNN-slug>/`:
`proposal.md`, `tasks.md`, при необходимости `design.md` и дельты `specs/`) → **Apply** (только задачи из
`tasks.md`, чекбоксы по ходу) → **Archive** (`proposals/archive/<YYYY-MM-DD>-<NNN>-<slug>/`, дельты влиты
в `specs/`, `Status: Done`).

Ключевые слова (`ADDED`, `Requirement`, `Scenario`, `WHEN`, `THEN`) — **на английском**, их перевод
ломает схему валидации.

**Проверка = команда, а не суждение.** Валидатор предложений:
`tools/validate-proposals.ps1 -Path <предложение>` (или `-All`, `-Archived`, `-CheckLinks`).

### Лёгкий маршрут `lite` (D-020)

Для мелких правок полный цикл избыточен. **`lite` допустим только при всех условиях сразу:**

- изменяется **≤ 2 файлов**;
- изменяется **≤ 50 строк** суммарно;
- **не меняются публичные контракты** (API, схемы событий, форматы хранения, CLI-флаги);
- **не меняется видимое пользователю поведение**.

В `lite` в `proposal.md` достаточно разделов `Context`, `Change`, `Test Strategy`, `Impact`,
`Changelog`; дельты `specs/` и `Requirements` не требуются (в шапке ставится `skip_specs: true`).
Схема — [`openspec/schemas/lite.yaml`](./openspec/schemas/lite.yaml).

**Обязательно даже в `lite`:** запись в `CHANGELOG.md` с привязкой `(<ID>)`, тесты для изменённой
логики, проверка командами. Если хотя бы одно условие нарушено — полный цикл, без обсуждения.

## 3. Делегирование субагентам

Главная сессия DSH — **Оркестратор** (пресет `standard`, нейтральный — решение [`D-018`](./DECISIONS.md)).
Роль доставляется **одним** пресетом **`sdd`** (решение [`D-016`](./DECISIONS.md)): он несёт полную
композицию `preset-standard` (22 плагина) и SDD-персону. Отдельных пресетов на роль нет — роль
указывается **в тексте задачи**.

Для любой нетривиальной задачи:

1. Составь короткий план и определи, какие роли нужны.
2. Делегируй субагенту с `agentPreset=sdd`, явно назвав роль и файл роли:

   | Роль | Файл | Что делает |
   | - | - | - |
   | `analyst` | [`.agents/analyst.md`](./.agents/analyst.md) | `inputs/`, реестр `IN-NNN`, измеримый критерий успеха; Discovery gate |
   | `architect` | [`.agents/architect.md`](./.agents/architect.md) | требования, C4/Mermaid, `openspec/proposals/` |
   | `csharp-dev` | [`.agents/csharp-dev.md`](./.agents/csharp-dev.md) | реализация утверждённой спеки; `dotnet build`/`test` обязательны |
   | `qa-engineer` | [`.agents/qa-engineer.md`](./.agents/qa-engineer.md) | независимые улики в `acceptance.md`/`performance.md`; код не правит |
   | `reviewer` | [`.agents/reviewer.md`](./.agents/reviewer.md) | двухосевой вердикт (`Standards`, `Spec`), находки с ID |
   | `ops-release` | [`.agents/ops-release.md`](./.agents/ops-release.md) | changelog, версия, план отката, SLO/capacity/runbook |

3. Держи основной контекст чистым: проси краткие отчёты, не вставляй целые файлы обратно.
4. Объедини результаты, разреши конфликты, доложи пользователю.

Правила делегирования:

- Ни один субагент не может пропустить гейт спецификации.
- **Ревьюер независим**: никогда тот же агент, что писал код; процедура — двухосевая
  ([`skills/code-review`](./.agents/skills/code-review/SKILL.md)).
- Инженер верификации не подтверждает работу автора кода: улики добывает он, вердикт — Ревьюер.
- При `FAIL` верни нарушения Разработчику, затем повторное ревью, прежде чем сообщать об успехе.
- **Изоляция QA и Ревьюера — дисциплинарная** (в DSH нет read-only permission-preset): оба обязаны
  проверить `git status --porcelain` до и после работы. Не выдавай это за песочницу.

## 4. Структура репозитория

```text
agentic-openspec/
├── AGENTS.md              # канон правил для агентов (DSH читает этот файл)
├── .clinerules            # совместимое зеркало правил для других инструментов
├── CHANGELOG.md           # история изменений (Keep a Changelog + SemVer)
├── OPEN_QUESTIONS.md      # открытые вопросы (OQ-N)
├── DECISIONS.md           # журнал решений (D-NNN)
├── .editorconfig          # стиль C#
├── global.json            # пин SDK
├── Directory.Build.props / Directory.Packages.props
├── .github/               # copilot-instructions, instructions/, workflows/
├── .agents/               # роли и скиллы субагентов
├── dsh/                   # обвязка DeepSeek Harness (бандл пресета sdd + install.ps1)
├── docs/                  # архитектура, эксплуатация, шаблоны, baseline
├── docs/legacy/           # документация проекта до SDD (LEG-NNN); правила — 04-documentation.md §4.10
├── inputs/                # материалы заказчика (ТЗ, концепции, макеты) + INDEX.md
├── openspec/              # артефакты SDD (constitution, standards 01..12, proposals, schemas, specs)
├── src/                   # исходники решений
├── tests/                 # тесты
└── tools/                 # машинные гейты (validate-proposals.ps1)
```

## 5. Ограничения (guardrails)

- **Не коммить секреты**, строки подключения и файлы `.env`. `ROUTERAI_API_KEY` — только из окружения.
- **Не трогай `openspec/proposals/archive/**`**, кроме как для добавления.
- **Не добавляй NuGet-зависимости**, не перечислив их в разделе «C# Implementation Plan» предложения.
- Держи диффы маленькими: одно предложение ≈ одно цельное изменение.
- **Материалы заказчика — только в `inputs/`.** Требования не выдумывай: черпай из `inputs/`
  (и фиксируй в `## Sources`) либо из `OPEN_QUESTIONS.md`/`DECISIONS.md`. Источник требования обязателен.
  **Регистрация материалов — машинная работа, не ручная:** `tools/register-inputs.ps1 -Apply`
  проставляет `IN-NNN`, путь, тип, дату и «что задаёт», убирая плейсхолдер «пока пусто».
  Не проси владельца заполнять таблицу реестра руками — предложи запустить скрипт.
  Проверка автоматическая: `tools/register-inputs.ps1 -Check` (входит в `check-template-clean.ps1`).
- **Не вводи новых ролей, стандартов и профилей** без отдельного предложения SDD.

## 6. Инженерные стандарты (обязательно к прочтению)

Полный свод — [`openspec/standards/`](./openspec/standards). Читай **перед** написанием спецификации или кода:

- [`01-code-style.md`](./openspec/standards/01-code-style.md) — соглашения C#, горячие пути, линтинг.
- [`02-architecture.md`](./openspec/standards/02-architecture.md) — Clean Architecture + DDD, SOLID, high-load.
- [`03-handoffs.md`](./openspec/standards/03-handoffs.md) — handoffs между этапами и сервисами.
- [`04-documentation.md`](./openspec/standards/04-documentation.md) — XML-док, ADR, runbook, changelog, legacy.
- [`05-definition-of-done.md`](./openspec/standards/05-definition-of-done.md) — DoD (Ревьюер использует как чек-лист).
- [`06-api.md`](./openspec/standards/06-api.md) · [`07-persistence.md`](./openspec/standards/07-persistence.md) ·
  [`08-messaging.md`](./openspec/standards/08-messaging.md) · [`09-security.md`](./openspec/standards/09-security.md) ·
  [`10-observability.md`](./openspec/standards/10-observability.md) · [`11-performance.md`](./openspec/standards/11-performance.md) ·
  [`12-desktop.md`](./openspec/standards/12-desktop.md) — десктопный профиль (`csharp-desktop`).

## 7. Рабочий протокол агента

1. **Прочитай канон и конституцию** — этот файл и [`openspec/constitution.md`](./openspec/constitution.md)
   (высший приоритет) — до любых действий.
2. **Осмотрись**: [`STATUS.md`](./STATUS.md), `git status`, `openspec/specs/`, существующий код.
   Правок на этой фазе нет.
3. **Проверь предложение**: есть ли утверждённая спецификация? Нет — вернись к фазе Propose.
4. **Работай по `tasks.md`**, отмечая `- [x]` по ходу; не расширяй объём самовольно.
5. **Проверяй командами** (`config.yaml` → `commands:`), а не рассуждением.
6. **Фиксируй нерешённое** в [`OPEN_QUESTIONS.md`](./OPEN_QUESTIONS.md) как `OQ-N` с рекомендуемым дефолтом.
   **Спрашивай вариантами, а не открытым вопросом** — см. §7.1 ниже.
7. **Обновляй** [`CHANGELOG.md`](./CHANGELOG.md) под `[Unreleased]` с привязкой к ID.
8. **Не коммить без команды владельца.** Правило набора: коммит — только по явному указанию.
9. **Веди [`STATUS.md`](./STATUS.md)** — единственную сводку «где мы сейчас»:
   - при **старте** работы сверь таблицу активных предложений с `openspec/proposals/`;
   - при **смене фазы** предложения — обнови его строку (фаза, счётчики задач, блокер);
   - при **закрытии гейта** — отметь в разделе готовности;
   - при появлении **блокера**, требующего человека, — добавь в «Что ждёт человека».
   Файл коммитится и должен быть верен после каждого гейта. Не превращай его в прозу:
   детали живут в `proposal.md`/`tasks.md`/`acceptance.md`.
10. **Метрики процесса не ведутся руками.** Перед закрытием сессии или батча выполни
    `tools/collect-metrics.ps1 -WithGates -OutFile METRICS.md` — скрипт сам считает требования,
    задачи, заполненность приёмки, вердикты, трассировку и результаты гейтов из артефактов.
    Не проси владельца «записывать метрики»: это машинная работа, а не его.

## 7.1 Уточнения у пользователя — только диалогом с вариантами

**Неизменяемое правило.** Любое уточнение, корректировка или решение, требующее участия человека,
происходит **в режиме диалога с предлагаемыми вариантами ответов**. Открытый вопрос «что делать?»
без вариантов — дефект взаимодействия.

### Как спрашивать

1. **Давай 2–4 конкретных варианта** с короткими названиями.
2. **Первый вариант — рекомендуемый**, с пометкой `(Рекомендую)` и одной фразой почему.
3. **У каждого варианта — следствие**: что произойдёт, если выбрать его. Одна строка, не абзац.
4. **Не смешивай вопросы.** Один вопрос — одно решение. Если их три — три отдельных вопроса.
5. **Не задавай вопрос, если ответ можно узнать из репозитория.** Сначала прочитай файлы
   и `git log`; спрашивай только то, что принадлежит человеку (продукт, приоритеты, право, деньги).

### Что считать «уточнением»

| Требует вариантов | Не требует |
| - | - |
| Выбор из альтернатив (A/B/C) | Факт, который есть в файлах |
| Подтверждение необратимого действия (удалить, переименовать, откатить) | Сообщение о результате проверки |
| Продуктовое или юридическое решение | Техническая деталь с единственным правильным ответом |
| Снятие противоречия в материалах заказчика | Уточнение формулировки, где смысл не меняется |

### Как это связано с `OQ-N`

Вопрос пользователю и запись в [`OPEN_QUESTIONS.md`](./OPEN_QUESTIONS.md) — **не одно и то же**:

- **`OQ-N`** — фиксация нерешённого в артефакте, чтобы оно не потерялось. Запись остаётся, даже когда
  ответ получен (статус меняется на `✅ закрыт (D-NNN)`).
- **Диалог с вариантами** — способ *получить* ответ. Задав вопрос вариантами, зафиксируй результат:
  ответ → запись `D-NNN` в [`DECISIONS.md`](./DECISIONS.md), а `OQ-N` помечается закрытым.

То есть: **сначала спросил вариантами → потом записал.** Не наоборот: не «выношу в OQ и жду»,
оставляя человека разбираться в пустом вопросе.

### Запрещено

- Задавать вопрос без вариантов, когда варианты очевидны.
- Сваливать в один вопрос несколько решений.
- Молча выбирать за человека, если решение принадлежит ему (см. конституцию §1 п. 5).
- Спрашивать о том, что уже зафиксировано в `DECISIONS.md` или `OPEN_QUESTIONS.md`.

## Карта

| Путь | Назначение |
| - | - |
| `AGENTS.md` | **Канон правил** для агентов (DSH читает этот файл) |
| `.clinerules` | Совместимое зеркало правил для других инструментов (DSH его не читает) |
| `dsh/presets-bundle/` | **Единственный источник** пресета `sdd`, персоны и модели (D-016, D-017) |
| `dsh/install.ps1` | Установка профиля в `$DSH_HOME/profiles/agentic-openspec` |
| `dsh/profile/` | Тонкая обёртка профиля (scaffolding, без копий персон) |
| `.agents/*.md` | Шесть ролей жизненного цикла |
| `.agents/skills/` | Переиспользуемые скиллы агентов (`<name>/SKILL.md`) |
| `openspec/constitution.md` | Конституция проекта (высший приоритет) |
| `openspec/config.yaml` | Профиль проекта, активные схемы, `lifecycle`, `commands` (единый источник команд) |
| `openspec/project.md` | Контекст проекта для агентов |
| `openspec/specs/` | Живые спецификации |
| `openspec/proposals/` | Предложения (`<NNN-slug>/`) и `archive/` |
| `openspec/standards/` | Инженерные стандарты 01–12 |
| `openspec/schemas/` | Машиночитаемые схемы валидации |
| `tools/validate-proposals.ps1` | Валидатор предложений (машинный гейт) |
| `tools/collect-metrics.ps1` | Метрики процесса: требования, задачи, приёмка, вердикты, гейты — без ручного учёта |
| `STATUS.md` | **Сводка «где мы сейчас»**: активные предложения, фазы, прогресс, блокеры. Коммитится |
| `CHANGELOG.md` | История изменений (Keep a Changelog + SemVer) |
| `OPEN_QUESTIONS.md` / `DECISIONS.md` | Открытые вопросы (`OQ-N`) и журнал решений (`D-NNN`) |
| `inputs/` | Входные материалы заказчика + реестр `INDEX.md` |
| `docs/` | Архитектура, эксплуатация, шаблоны, `docs/baseline/` |
| `docs/ADOPTION.md` | Инструкция по развёртыванию набора |
| `docs/SET-AUDIT.md` | Протокол сессии аудита самого набора (не продукта) |
| `docs/legacy/` | Реестр `LEG-NNN`, карта соответствий, замороженная история |
| `.github/` | `copilot-instructions.md`, `instructions/`, `workflows/` (CI) |
| `Directory.Build.props` / `Directory.Packages.props` | Общие настройки сборки и централизованные версии |
| `.editorconfig` | Стиль C# — авто-формат и линт |
