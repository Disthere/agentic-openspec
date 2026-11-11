# Changelog — agentic-openspec

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/). Версионирование: [SemVer](https://semver.org/lang/ru/).
Каждая запись привязана к задаче: ID предложения (`openspec/proposals/<NNN-slug>`), `spec-id` (`PAY-001`) или issue (`#123`).

Правила ведения — [`openspec/standards/04-documentation.md` §4.6](openspec/standards/04-documentation.md#46-changelog).
Шаблон записи — [`docs/CHANGELOG-TEMPLATE.md`](docs/CHANGELOG-TEMPLATE.md).

## [Unreleased]

### Добавлено

- **Батч 3 плана: роли в DSH исполняются (G3 — автоматическая часть выполнена).**
  - **`preset-sdd` — 22 плагина** вместо шести пресетов с одной персоной (P0-9, P0-11). Композиция —
    точная копия `preset-standard`, заменена только персона; решение [`D-016`](DECISIONS.md).
  - **`allowedAgentPresets: [sdd]`** в группе `delegation` — делегирование по роли сконфигурировано (P0-10).
  - **Дефолт реестра — `standard`** (нейтральный), решение [`D-018`](DECISIONS.md) закрывает `OQ-13`.
  - **`install.ps1`**: бэкап `.bak-<timestamp>` при отличии файла + предупреждение в выводе (P1-16);
    патч профиля производится из бандла (P1-11, решение [`D-017`](DECISIONS.md)).
  - **`docs/ci/check-dsh-profile.ps1`** обновлён: проверяет `preset-sdd`, дефолт `standard` и отсутствие
    возврата легаси-пресетов ролей.
  - **`argument-hint` удалён** из 3 скиллов и 6 ролей (P2-30).
- **Батч 4 плана: канон, стандарты, противоречия (G4 — выполнен).**
  - **[`AGENTS.md`](AGENTS.md) — настоящий канон (217 строк)**: C#-минимум, тесты, ASP.NET Core,
    guardrails, перечень стандартов 01–12, рабочий протокол из 8 пунктов (P0-2).
  - **[`.clinerules`](.clinerules) — зеркало (46 строк)**: только ссылки и три непреложных правила;
    «Cline выступает Оркестратором» заменено на «главная сессия DSH».
  - **`tools/check-canon-parity.ps1`** — сверка канона и зеркала: 12 якорных пунктов, контроль размеров,
    запрет другого оркестратора и дублирования команд. Включён в CI; доказан негативным тестом.
  - **`THIRD-PARTY.md`** — лицензии сторонних материалов (OpenSpec MIT с текстом; Wikipedia CC BY-SA
    снята вместе со скиллом).
  - **`docs/CLEANUP.md` + `tools/check-template-clean.ps1`** — чек-лист развёртывания за 10 минут и его
    машинная проверка (P0-5, задачи 5.2/5.8).

- **Батч 2 плана: гейты проверяются машиной, цикл замкнут (G2 — выполнен).**
  - **`tools/validate-proposals.ps1`** — валидатор предложений (P0-3): проверки V1–V11 и режимы
    `-Path`, `-All`, `-Archived`, `-CheckLinks`. Доказан негативным тестом: на заведомо битом
    предложении даёт 12 ошибок и `exit 1`. Совместим с Windows PowerShell 5.1 (UTF-8 BOM).
  - **`.github/workflows/scaffold-check.yml`** — CI из 4 джобов (P1-14): валидатор + негативный тест,
    .NET build/test/format/vulnerable, скаффолд (роли/скиллы/стандарты/схемы выводятся из каталогов,
    а не хардкодятся), композиция DSH. Черновик `docs/ci/scaffold-check.yml` удалён.
  - **`docs/ci/check-dsh-profile.ps1`** — регресс-защита P0-9/P0-10: поднимает изолированный `DSH_HOME`,
    требует ≥ 8 плагинов у каждого пресета роли. На текущем профиле корректно показывает провал
    (по 1 плагину) — доказательство, что проверка ловит именно этот дефект.
- **Фаза `Archive` в жизненном цикле (P0-4)** — [`openspec/constitution.md`](openspec/constitution.md) §7
  (10-я фаза, владелец — Оркестратор) и `openspec/config.yaml:lifecycle`. Формат архива сведён к одному
  канону `<YYYY-MM-DD>-<NNN>-<slug>/` ([`.clinerules`](.clinerules), [`openspec/README.md`](openspec/README.md)).
- **Живые спецификации** — дельты `001` и `002` влиты в [`openspec/specs/`](openspec/specs):
  `independent-review`, `delivery-roles`, `product-lifecycle`. Предложения перенесены в
  [`openspec/proposals/archive/`](openspec/proposals/archive) со `Status: Done`. Цикл SDD замкнут (P0-4);
  относительные ссылки в архиве пересчитаны под новую глубину.
- **`Approved by:` / `Approved at:`** в [`000-template.md`](openspec/proposals/000-template.md) и в четырёх
  утверждённых предложениях (P2-33); валидатор это проверяет (V11).
- **`item_pattern` схем** исправлен на `\[[ xX]\]` — раньше схема требовала только незакрытые пункты.
- **`spec-first` убран из `schemas.active`** — схемы с таким именем не существует (задача 5.1).

- **Батч 1 плана: .NET собирается с первого клона (G1 — выполнен).** Решение `src/agentic-openspec.slnx`,
  smoke-приложение [`src/Smoke/`](src/Smoke/Program.cs) (эндпоинт `/health` + `ApiMarker` для
  `WebApplicationFactory`) и тестовый проект [`tests/Smoke.Tests/`](tests/Smoke.Tests/HealthEndpointTests.cs)
  на xUnit v3 + MTP. `dotnet restore`, `build -c Release`, `test`, `format --verify-no-changes` — все
  четыре зелёные из чистого состояния; `dotnet list package --vulnerable` — уязвимых нет. (`PLAN` батч 1)
- **`.gitattributes`** — нормализация переносов строк (`text=auto eol=lf`, CRLF для `*.cmd`/`*.bat`/`*.ps1`,
  бинарные исключения). Устраняет смешанные переносы (P2-18). (`PLAN` задача 1.7)
- **`tests/coverlet.runsettings`** — покрытие через MTP (`Microsoft.Testing.Extensions.CodeCoverage`,
  формат cobertura). Заменяет неработающий при xunit.v3 `coverlet.collector` (P1-6). (`PLAN` задача 1.5)

### Изменено

- **[`AGENTS.md`](AGENTS.md) / [`.clinerules`](.clinerules) / [`01-code-style.md`](openspec/standards/01-code-style.md)** —
  `s_`-префикс статических полей внесён в единственный источник стиля (P2-27); `var` —
  `true:suggestion` (P2-21); **FluentAssertions ≤ 7.2.2, 8.x запрещён**; Moq запрещён (P1-8, P2-10).
- **Анализаторы включены по-настоящему**: `MA0141`, `MA0142`, `S103` = warning;
  `<GenerateDocumentationFile>true</GenerateDocumentationFile>` (CS1591 глушится только в тестах) —
  P2-11, P2-19, P2-20, P2-22.
- **Уязвимости больше не глушатся**: `NU1901..NU1904` перенесены из `NoWarn` в `WarningsAsErrors`;
  `NuGetAudit=true`, уровень `moderate` (P1-7).
- **[`dsh/README.md`](dsh/README.md)** приведён к факту: убраны `v4-pro` (фактически `flash`), исправлен
  список шаблонов профиля (проверено: `web`, `acp`, `headless`, `sdk`, `sdk-minimal`; `tui`/`rescue`
  не существуют), убрано «смена модели = перезапуск» (P1-9, P1-20, P2-31).
- **[`.agents/reviewer.md`](.agents/reviewer.md) / [`.agents/qa-engineer.md`](.agents/qa-engineer.md)** —
  обязательная улика неизменности дерева (`git status --porcelain` до/после) и честная запись, что
  изоляция **дисциплинарная**, а не песочница (P1-10).
- **[`.agents/architect.md`](.agents/architect.md)** — стоп `BLOCKED: Discovery gate not closed` (P1-19);
  `acceptance.md` — только пустая матрица, заполняет QA (P1-18).

### Удалено

- **`.agents/skills/ai-writing-tells/`** — решение `D-06`: не обслуживает ни один гейт набора.
- **`SuppressNETCoreSdkPreviewMessage`** из `Directory.Build.props` — мёртвая настройка (P2-31).
- **Шесть пресетов-ролей** `preset-analyst`…`preset-ops-release` — заменены одним `preset-sdd` (D-016).
- **`dsh/profile/cordis.patch.yml`** — копия персон; единственный источник теперь бандл (D-017).

### Исправлено

- **`tests/Directory.Build.props` терял корневые настройки**: MSBuild берёт ближайший файл и не
  наследует родительский — `build` падал `NETSDK1004`. Добавлен явный `<Import>` родительского файла.

- **Линия .NET выровнена: `net10.0` + C# 14** — решение [`D-015`](DECISIONS.md) по гейту D-01(A) плана.
  Обновлены [`openspec/config.yaml`](openspec/config.yaml) (`stack` + `commands`), обе схемы
  (`csharp-api.yaml`, `csharp-desktop.yaml`), [`12-desktop.md`](openspec/standards/12-desktop.md),
  [`01-code-style.md`](openspec/standards/01-code-style.md) (политика `LangVersion=latest`), `README.md`,
  [`AGENTS.md`](AGENTS.md), [`.clinerules`](.clinerules), [`openspec/project.md`](openspec/project.md).
  «.NET 8+»/«C# 12+» удалены из всех нормативных документов (P0-6, P2-8, P2-9). (`PLAN` задачи 1.3, 1.4)
- **Бутстрап тестов: `dotnet new xunit3` вместо `dotnet new xunit`** — шаблон v2 под CPM даёт
  `NU1008`+`NU1010`. Зафиксировано в [`README.md`](README.md), [`.agents/csharp-dev.md`](.agents/csharp-dev.md),
  [`src/.gitkeep`](src/.gitkeep) (P0-7). (`PLAN` задача 1.2)

### Исправлено

- **`Microsoft.Testing.Extensions.CodeCoverage` зафиксирован на 17.14.2** — версия 18.x требует
  Microsoft.Testing.Platform 2.x и падает `TypeLoadException` с xunit.v3 3.2.2 (MTP 1.x).
- **Конфликт анализаторов MA0004 ↔ xUnit1030** — для `tests/**` в [`.editorconfig`](.editorconfig)
  отключён MA0004: в тестах `ConfigureAwait(false)` запрещён правилом xUnit1030.
- Битая ссылка `./tasks.md` в [`000-template.md`](openspec/proposals/000-template.md) (P2-24).
- Ссылки на `001`/`002` в [`CHANGELOG.md`](CHANGELOG.md) и [`OPEN_QUESTIONS.md`](OPEN_QUESTIONS.md)
  переведены на архивные пути после архивации.

- **`CHANGELOG.md` + [`docs/CHANGELOG-TEMPLATE.md`](docs/CHANGELOG-TEMPLATE.md)** — универсальный шаблон changelog
  (Keep a Changelog + SemVer, обязательная привязка к задачам). Правила ведения — в
  [`openspec/standards/04-documentation.md` §4.6](openspec/standards/04-documentation.md#46-changelog),
  DoD релиза обновлён ([`05-definition-of-done.md`](openspec/standards/05-definition-of-done.md) п. 5.4). (`docs-changelog`)
- **`OPEN_QUESTIONS.md` + `DECISIONS.md`** — открытые пункты (`OQ-N`) и журнал решений (`D-NNN`); шаблоны —
  [`docs/OPEN_QUESTIONS-TEMPLATE.md`](docs/OPEN_QUESTIONS-TEMPLATE.md),
  [`docs/DECISIONS-TEMPLATE.md`](docs/DECISIONS-TEMPLATE.md). Правила —
  [`04-documentation.md` §4.7–4.8](openspec/standards/04-documentation.md#47-open-questions). (`docs-open-questions`)
- **`inputs/` + [`docs/INPUTS-TEMPLATE.md`](docs/INPUTS-TEMPLATE.md)** — каталог входных материалов заказчика
  (`briefs/`, `concepts/`, `graphics/`, `samples/`), `README.md` (правила) и `INDEX.md` (реестр `IN-NNN`).
  Вшит в роли (Архитектор/Разработчик/Ревьюер), раздел `## Sources` предложения, схему и стандарт §4.9. (`docs-inputs`)
- **Handoff наружу:** [`03-handoffs.md` §3.5](openspec/standards/03-handoffs.md) + [`docs/HANDOFF-TEMPLATE.md`](docs/HANDOFF-TEMPLATE.md) —
  состав пакета для внешнего исполнителя, принципы, чек-лист вычистки (что НЕ уходит наружу). (`docs-handoff-external`)
- **`docs/SESSION-START.md`** — хендофф сессии: правило «старт без действий», текущее состояние, открытые
  пункты и меню готовых команд. Вшито в [`.clinerules`](.clinerules) и [`AGENTS.md`](AGENTS.md). (`docs-session-start`)
- **`.agents/skills/code-review/`** — двухосевое независимое ревью: `SKILL.md` (границы, источники стандартов,
  промпты осей, агрегация), `references/smell-baseline.md` (базлайн запахов, always judgement call),
  `references/findings.md` (жизненный цикл находки, диспозиции `fixed`/`rejected`/`deferred`, применимость улик).
  Спецификация — [`openspec/proposals/archive/2026-11-10-001-two-axis-review/`](openspec/proposals/archive/2026-11-10-001-two-axis-review/proposal.md). (`001-two-axis-review`)
- **Три роли полного цикла** — [`.agents/analyst.md`](.agents/analyst.md) (Discovery: `inputs/`, `IN-NNN`,
  измеримый критерий успеха), [`.agents/qa-engineer.md`](.agents/qa-engineer.md) (Verify: `acceptance.md`,
  `performance.md`, воспроизводимые улики), [`.agents/ops-release.md`](.agents/ops-release.md)
  (Release/Operate/Feedback: changelog и версия, откат, SLO/capacity/runbook, обратная связь из поддержки).
  (`002-lifecycle-and-roles`)
- **Фазы жизненного цикла** — [`openspec/constitution.md`](openspec/constitution.md) §7: карта
  «фаза → артефакт → гейт → владелец» и правила фаз (гейт без артефакта не вводится; допуск роли = артефакт + гейт). (`002-lifecycle-and-roles`)
- **DoD дискавери и эксплуатации** — [`05-definition-of-done.md`](openspec/standards/05-definition-of-done.md)
  §5.6 (Discovery) и §5.7 (Operate & Support). (`002-lifecycle-and-roles`)
- **Пять новых передач** — [`03-handoffs.md`](openspec/standards/03-handoffs.md) §3.1: Brief → Spec,
  Build → Verify, Verify → Release, Release → Ops, Ops → Spec. (`002-lifecycle-and-roles`)
- **Пресеты DSH** — [`dsh/profile/cordis.patch.yml`](dsh/profile/cordis.patch.yml): `analyst`, `qa-engineer`,
  `ops-release` добавлены к `architect`, `csharp-dev`, `reviewer` (шесть ролей). (`002-lifecycle-and-roles`)
- **Профиль `csharp-desktop`** — второй профиль проекта рядом с серверным: схема
  [`openspec/schemas/csharp-desktop.yaml`](openspec/schemas/csharp-desktop.yaml) и стандарт
  [`openspec/standards/12-desktop.md`](openspec/standards/12-desktop.md) (Avalonia 11+ и CommunityToolkit.Mvvm,
  LLamaSharp/llama.cpp с GGUF и ONNX Runtime GenAI как альтернатива, STT/TTS/VAD/OCR, SQLite + sqlite-vec +
  SQLCipher, BIP39, IPC без портов, подписанный манифест обновлений как единственная точка выхода в сеть,
  запрет аналитики, бюджеты ресурсов вместо серверных SLO, лицензионный инвентарь, архитектурные тесты
  NetArchTest + Roslyn-анализатор запрета сети), плюс DoD §5.8 для десктоп-релиза. Серверный профиль
  (`csharp-api`) не изменён; схема, стандарты и DoD следуют за `project.profile`. (`004-desktop-profile`)
- **`docs/ADOPTION.md`** — инструкция «как развернуть набор»: два сценария (новый проект; существующий
  проект без SDD), готовые промпты для всего пути, полный список человеческих действий и промпты для
  восстановления контекста, откатов и проверки развёртывания. Ручных шагов два: скопировать одну папку
  набора и скопировать папку материалов в `inputs/`; команд в терминале и ручных правок файлов нет.
  Уточнено после приёмки: папка набора — это корень репозитория `agentic-openspec` целиком (включая
  `src/`, `tests/`, настройки сборки); служебную `.git` набор не переносит — сессия удаляет её на
  шаге инициализации. Адресат промптов закреплён явно: §0 «Кому адресаны промпты» и строка
  «Ты — Оркестратор SDD этого проекта» в начале каждого промпта (смена дефолта пресета —
  кандидат `OQ-13`). Непокрытый случай — чужая структура документации в существующем проекте:
  помечено в §3 и вынесено в `OQ-14`. (`005-adoption-guide`)
- **`docs/legacy/`** — каталог-реестр документации проекта, существовавшей до внедрения SDD:
  [`README.md`](docs/legacy/README.md) (правила ведения, словарь статусов, шаблон строки реестра, шаблон
  документа-указателя, маркер «оставить на месте»), [`INDEX.md`](docs/legacy/INDEX.md) (реестр `LEG-NNN`:
  документ · где живёт · владелец · потребитель · актуальность · наш артефакт · действие · статус),
  [`CHANGELOG-FROZEN.md`](docs/legacy/CHANGELOG-FROZEN.md) (приложение для исторической части чужого
  changelog после разбора). Правило «источник истины один»: перенос оставляет указатель без нормативного
  текста, копии рядом с оригиналом не остаётся; «ничего не удаляется» — оригинал всегда становится
  указателем либо остаётся с маркером `🗄`/`🌐`. (`006-legacy-docs-alignment`)
- **Три готовых промпта для Оркестратора** — [`docs/ADOPTION.md`](docs/ADOPTION.md): **B1a** (инвентаризация
  документации и карта соответствий, только чтение, между B1 и B2) и **B5** (приведение документации
  к нашей структуре по утверждённым построчно строкам реестра, после B4) — §3, **B6** (проверка «новый
  участник находит ответ за один переход»: список вопросов + таблица Pass/Fail с числом переходов) — §7.
  Адресат — главная сессия; терминальных команд для человека нет. (`006-legacy-docs-alignment`)

### Изменено

- **`openspec/standards/04-documentation.md`** — уровень «Changelog» в таблице 4.1 и новый раздел 4.6. (`docs-changelog`)
- **`README.md`, `AGENTS.md`** — CHANGELOG добавлен в карту и дерево. (`docs-changelog`)
- **`05-definition-of-done.md`** — DoD спеки: открытые вопросы вынесены в `OPEN_QUESTIONS.md`; DoD релиза: решения зафиксированы в `DECISIONS.md`. (`docs-open-questions`)
- **`openspec/proposals/000-template.md`, `openspec/project.md`** — ссылки на OPEN_QUESTIONS/DECISIONS. (`docs-open-questions`)
- **`openspec/proposals/000-template.md`** — новый раздел `## Changelog`: Архитектор обязан планировать запись в changelog. (`docs-changelog-process`)
- **`.agents/architect.md`** — план записи в CHANGELOG добавлен в результаты Архитектора и в его DoD. (`docs-changelog-process`)
- **`.agents/reviewer.md`** — в процедуру ревью добавлена проверка записи в CHANGELOG (шаг 9). (`docs-changelog-process`)
- **`docs/DECISIONS-TEMPLATE.md`, `DECISIONS.md`, `standards/04-documentation.md` §4.8** — формат журнала решений приведён к табличному виду (`# | Дата | Решение | Статус | Источник` + разделы «подробности»). (`docs-decisions-format`)
- **`.agents/reviewer.md`** — переписан под двухосевое ревью: две независимые сессии (Standards и Spec),
  режим «только чтение», находки с устойчивыми ID и диспозициями, агрегированный вердикт. Контракт
  `VERDICT: Pass|Fail` и формат `Where/Breaks/Fix` сохранены; проверка записи в CHANGELOG (прежний шаг 9)
  перенесена в ось Standards. (`001-two-axis-review`)
- **`.agents/README.md`, `.agents/skills/README.md`** — таблицы скиллов дополнены `code-review` и
  `ai-writing-tells`; описаны соглашения по содержимому (`references/`, опциональный `agents/`). (`001-two-axis-review`)
- **`openspec/standards/05-definition-of-done.md` §5.5** — Ревьюер выполняет двухосевой проход, Оркестратор агрегирует вердикт; запахи кода не блокируют. (`001-two-axis-review`)
- **`OPEN_QUESTIONS.md`** — добавлен `OQ-7`: обязателен ли двухосевой режим для всех предложений. (`001-two-axis-review`)
- **Среда исполнения — DeepSeek Harness, а не Cline:** [`AGENTS.md`](AGENTS.md) закреплён как **канон правил**
  (DSH читает его), [`.clinerules`](.clinerules) — совместимое зеркало; делегирование — субагенты DSH с
  `agentPreset`; Cline CLI и `spawn_agent` убраны из авторитетных документов
  ([`README.md`](README.md), [`AGENTS.md`](AGENTS.md), [`.clinerules`](.clinerules),
  [`.github/copilot-instructions.md`](.github/copilot-instructions.md),
  [`openspec/`](openspec) — `project.md`, `README.md`, `proposals/README.md`, `standards/README.md`). (`002-lifecycle-and-roles`)
- **`openspec/config.yaml`** — блок `lifecycle` (фазы и гейты), `agents.orchestrator: dsh`, шесть ролей,
  правило допуска роли. (`002-lifecycle-and-roles`)
- **`openspec/standards/05-definition-of-done.md`** §5.2 — улики верификации добывает не автор кода
  (Инженер верификации); §5.5 — применение новых ролей. (`002-lifecycle-and-roles`)
- **`.agents/README.md`** — таблица шести ролей, схема делегирования на субагентах DSH, правило допуска
  (артефакт + гейт). (`002-lifecycle-and-roles`)
- **`dsh/README.md`** — состав профиля (шесть пресетов), цикл по фазам жизненного цикла. (`002-lifecycle-and-roles`)
- **`docs/ADOPTION.md` §3** — оговорка «Пока не покрыто» снята и заменена покрытием: шаги **B1a**
  (инвентаризация и карта, только чтение, до B2) и **B5** (применение по утверждённым строкам, после B4);
  §0 — строки B1a/B5 в таблице адресатов, §5 — человеческое действие «утвердить строки реестра»,
  §7 — промпт **B6** «ответ за один переход», §9 — ссылка на `docs/legacy/`. (`006-legacy-docs-alignment`)
- **`openspec/standards/04-documentation.md` §4.10** — правила для документации, существовавшей до внедрения
  SDD: реестр и карта соответствий, «источник истины один», указатели и маркеры, разбор чужого changelog
  (актуальные записи — в проектный файл, исторические — приложением), внешняя документация только
  указателями и без копирования секретов/PII, расхождения «документ vs код» → `OQ-N`;
  перекрёстные ссылки из §4.1 (уровни документации) и §4.9 (`inputs/`). (`006-legacy-docs-alignment`)
- **Карты репозитория** — [`AGENTS.md`](AGENTS.md) и [`.clinerules`](.clinerules) (синхронно,
  канон — `AGENTS.md`), [`README.md`](README.md) (раздел «Что внутри» и дерево структуры),
  [`openspec/project.md`](openspec/project.md) («Where things live»),
  [`docs/SESSION-START.md`](docs/SESSION-START.md) (команда «приведи документацию к структуре», состояние,
  список открытых пунктов) — указывают на реестр `docs/legacy/`. (`006-legacy-docs-alignment`)
- **`OPEN_QUESTIONS.md`** — `OQ-14` закрыт (`D-008`, утверждено 10.11.2026) и перенесён в «Закрытые»
  без удаления разбора; `OQ-15`…`OQ-20` закрыты ответами владельца 10.11.2026 (каталог `docs/legacy/`,
  только указатели для внешних документов, оригинал всегда остаётся указателем, разбор чужого changelog,
  код — факт, проверка чек-листом и промптом).
  [`DECISIONS.md`](DECISIONS.md) — `D-008`…`D-014` по процедуре приведения документации. (`006-legacy-docs-alignment`)

### Исправлено

- **Профиль DeepSeek Harness (`dsh/`)**: патч-слой переведён на семантику DSH — существующие id
  переопределяются, а новые шесть пресетов объявляются списком `insert`. Композиция больше не падает с
  `patch: entry "preset-analyst" not found`: `--dump-config` собирается (exit 0, шесть ролей в дереве,
  10 строк персон). `install.ps1` переписан ASCII-безопасно и запускается в Windows PowerShell 5.1;
  `dsh/README.md` описывает реальный CLI из приложения, ограничение профиля `desktop` и семантику
  override/insert. Модель закреплена решением владельца: провайдер `routerai` (ключ из `ROUTERAI_API_KEY`),
  все шесть ролей на `deepseek/deepseek-v4.1-flash` (`OQ-2` → `D-007`). (`003-dsh-profile-patch-fix`)

### Не изменилось

- Контракт вердикта `VERDICT: Pass|Fail`, формат находок `Where/Breaks/Fix` и нумерация предложений —
  ранее архивированные предложения и их `acceptance.md` читаются без изменений.
- Нумерация DoD 5.1–5.5 сохранена: новые разделы добавлены как 5.6 и 5.7.
- Скиллы `spec-first`, `implement-feature`, `code-review`, `ai-writing-tells` — без изменений.
- Имя файла `.clinerules` сохранено (совместимость с другими инструментами), изменилось только содержимое.
- Шаги **B1–B4** и сценарий A инструкции развёртывания — без изменений: `006` добавляет шаги B1a, B5 и B6,
  не переписывая существующую последовательность. (`006-legacy-docs-alignment`)
- Конституция, роли и пресеты (`.agents/`, `dsh/profile/`), стандарты кроме `04-documentation.md`,
  `docs/architecture/`, `docs/operations/` — не затронуты. (`006-legacy-docs-alignment`)
- Поведение продукта не меняется: C#-кода предложение не добавляет (`src/`, `tests/`, `*.cs`, `*.csproj`
  без правок). (`006-legacy-docs-alignment`)

### Тесты

- Документарные проверки: обязательные разделы `proposal.md` по схеме [`csharp-api.yaml`](openspec/schemas/csharp-api.yaml),
  ≥1 сценарий с `WHEN`/`THEN` на каждое требование, паритет требований умбрелла-спеки и дельт capability,
  резолвинг относительных ссылок в артефактах предложения, формат `tasks.md`.
- `dotnet build` / `dotnet test` / `dotnet format` не запускались: предложения 001 и 002 не добавляют C#-кода.
- Живой прогон двух осей на реальном диффе **не выполнялся** — предмета ревью не было; условие и план
  проверки зафиксированы в [`openspec/proposals/archive/2026-11-10-001-two-axis-review/acceptance.md`](openspec/proposals/archive/2026-11-10-001-two-axis-review/acceptance.md).
- `npx @deepseek-ai/dsh --profile agentic-openspec --dump-config` **не запускался** — профиль ещё не
  установлен; условие зафиксировано в [`openspec/proposals/archive/2026-11-10-002-lifecycle-and-roles/acceptance.md`](openspec/proposals/archive/2026-11-10-002-lifecycle-and-roles/acceptance.md).
- `006-legacy-docs-alignment`: документарные проверки — ссылки в `docs/legacy/README.md`, `INDEX.md`,
  `CHANGELOG-FROZEN.md` и правленых картах резолвятся (проверено скриптом); `dotnet build` / `dotnet test`
  не применимы (кода нет); применение процедуры на реальном проекте с чужой документацией **не выполнялось**
  — условие и честная отметка непроверенного в
  [`acceptance.md`](openspec/proposals/006-legacy-docs-alignment/acceptance.md).

## [0.2.0] — 2026-11-09 · Обвязка DeepSeek Harness + скилл работы с текстами (dsh-profile, ai-writing-tells)

### Добавлено

- **`dsh/`** — обвязка SDD для **DeepSeek Harness**: `profile/` (Cordis-профиль `agentic-openspec`),
  `install.ps1`, `README.md`. Три роли (agent presets) — `architect`, `csharp-dev`, `reviewer` — каждая
  со своей персоной (`@deepseek-ai/dsh-persona`) и **своей моделью** (`@deepseek-ai/dsh-agent-default-model`);
  реестр `agent-preset-registry` с `default: csharp-dev`.
- **`.agents/skills/ai-writing-tells/`** — скилл аудита и правки «AI-признаков» в текстах (по Wikipedia
  «Signs of AI writing»): `SKILL.md` (+`whenToUse`), `references/signs-of-ai-writing.md`,
  `references/rewriting-playbook.md`, `scripts/ai_tells_check.py`.

### Не изменилось

- Навыки `spec-first` и `implement-feature` и их фронтматтер — без изменений.
- Обвязка Cline/VS Code (`.clinerules`, `AGENTS.md`, `openspec/`) не затронута: DSH читает `.agents/skills`
  и `AGENTS.md` как есть.

### Тесты

- Валидация YAML профиля (`cordis.yml`, `cordis.patch.yml`) и `package.json` — 0 ошибок.
  Порядок интерактивной проверки композиции — в [`dsh/README.md`](dsh/README.md).

## [0.1.0] — 2026-11-05 · Начальный SDD-шаблон

### Добавлено

- **`openspec/`** — конституция, `config.yaml`, схемы валидации, шаблоны предложений
  (`proposal`/`tasks`/`performance`/`acceptance`/`contracts`), стандарты `01`–`11`.
- **`.agents/`** — роли Архитектор / Разработчик / Ревьюер + скиллы `spec-first`, `implement-feature`.
- **Правила агента** — `.clinerules`, `AGENTS.md`, `.github/copilot-instructions.md`, `.github/instructions/`.
- **`docs/`** — границы сервисов, ADR, SLO, capacity, runbooks.
- **Сборка .NET** — `global.json`, `Directory.Build.props`, `Directory.Packages.props`, `.editorconfig`.
