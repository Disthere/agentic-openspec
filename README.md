# agentic-openspec

> Шаблон **Spec-Driven Development (SDD)** и мультиагентной разработки для **C# / .NET** —
> высоконагруженные ASP.NET Core-приложения и микросервисы. Рабочая среда — **DeepSeek Harness**
> (`dsh`): роли исполняются субагентами с `agentPreset`, шаблон открывается как воркспейс DSH.

[![Use this template](https://img.shields.io/badge/Use%20this-template-2ea44f?logo=github)](#сценарий-a--новое-решение)
![workflow](https://img.shields.io/badge/workflow-Spec--First-blue)
![C#](https://img.shields.io/badge/C%23-14-239120?logo=csharp)
![.NET](https://img.shields.io/badge/.NET-10-512BD4?logo=dotnet)

Готовый «фундамент» проекта: правила для агента, роли субагентов, инженерные стандарты,
конституция, SDD-артефакты и общие настройки сборки .NET. Подходит и для **новых**, и для
**существующих** решений — см. два сценария ниже.

---

## Что внутри

- **Как развернуть в проекте** — [`docs/ADOPTION.md`](./docs/ADOPTION.md): два сценария (новый проект и
  существующий без SDD) готовыми промптами; единственное ручное действие — скопировать одну папку, корень
  набора `agentic-openspec`.
- **Правила агента** — [`AGENTS.md`](./AGENTS.md) (канон для DSH) и [`openspec/`](./openspec);
  [`.clinerules`](./.clinerules) — совместимое зеркало для других инструментов, краткие указатели в
  [`.github/instructions/`](./.github/instructions).
- **Роли субагентов** — [`.agents/`](./.agents): шесть ролей цикла (продуктовый аналитик → архитектор →
  разработчик → инженер верификации → ревьюер → Ops/Release) + скиллы; пресеты среды — в [`dsh/profile/`](./dsh/profile).
- **Конституция проекта** — [`openspec/constitution.md`](./openspec/constitution.md) (высший приоритет).
- **Инженерные стандарты 01–12** — [`openspec/standards/`](./openspec/standards): Code Style, Architecture,
  Handoffs, Documentation, DoD, API, Persistence, Messaging, Security, Observability, Performance,
  Desktop (`12-desktop.md` — профиль `csharp-desktop`).
- **SDD-процесс** — [`openspec/`](./openspec): конфиг, схемы валидации, шаблоны предложений.
- **Документация эксплуатации** — [`docs/`](./docs): границы сервисов, ADR, SLO, capacity, runbooks.
- **Документация до SDD** — `docs/legacy/` (шаблон набора): реестр документов `LEG-NNN`, карта соответствий
  «их документ → наш артефакт», замороженная история изменений; для проектов, у которых документация уже
  есть и устроена иначе. Правила — [`openspec/standards/04-documentation.md` §4.10](./openspec/standards/04-documentation.md),
  промпты — [`docs/ADOPTION.md`](./docs/ADOPTION.md) §3 (B1a, B5) и §7 (B6).
- **История изменений** — [`CHANGELOG.md`](./CHANGELOG.md) (Keep a Changelog + SemVer, привязка к задачам).
- **Открытые вопросы и решения** — [`OPEN_QUESTIONS.md`](./OPEN_QUESTIONS.md) (OQ-N) и [`DECISIONS.md`](./DECISIONS.md) (D-NNN).
- **Входные материалы заказчика** — [`inputs/`](./inputs/README.md): ТЗ, концепции, макеты, образцы данных + реестр [`INDEX.md`](./inputs/INDEX.md).
- **Настройки сборки .NET** — [`global.json`](./global.json), [`Directory.Build.props`](./Directory.Build.props),
  [`Directory.Packages.props`](./Directory.Packages.props), [`.editorconfig`](./.editorconfig).

## Требования

- **.NET SDK 10** (см. [`global.json`](./global.json)) — либо поправьте версию под свой SDK.
- **Node.js 18+** и npm — чтобы запускать DeepSeek Harness командой `npx @deepseek-ai/dsh`.
- **DeepSeek Harness** (`dsh`) — рабочая среда; профиль с ролями и моделями ставится из [`dsh/`](./dsh/README.md).

## Структура

```text
agentic-openspec/
├── .clinerules                 # совместимое зеркало правил (C#, SDD, делегирование)
├── AGENTS.md                   # кросс-инструментальное зеркало правил
├── CHANGELOG.md                # история изменений (Keep a Changelog + SemVer)
├── OPEN_QUESTIONS.md           # открытые пункты (OQ-N) + ответы пользователя
├── DECISIONS.md                # журнал решений (D-NNN)
├── inputs/                     # материалы заказчика: briefs/ concepts/ graphics/ samples/ (+INDEX.md)
├── .editorconfig               # стиль C# (Allman, отступы, именование, анализаторы)
├── global.json                 # фиксация версии .NET SDK
├── Directory.Build.props       # общие настройки сборки всех проектов
├── Directory.Packages.props    # централизованные версии NuGet-пакетов
├── .github/
│   ├── copilot-instructions.md # короткая точка входа для GitHub Copilot
│   ├── instructions/*.md       # тематические указатели (csharp, aspnetcore, ...)
│   └── workflows/              # проверка целостности шаблона
├── .agents/                    # роли и скиллы субагентов
│   ├── architect.md            # Архитектор (спеки, C4/Mermaid, без кода)
│   ├── csharp-dev.md           # Разработчик (реализация + dotnet build/test)
│   ├── reviewer.md             # Ревьюер (вердикт Pass / нарушения)
│   └── skills/<name>/SKILL.md  # переиспользуемые скиллы
├── docs/
│   ├── architecture/{service-boundaries.md, adr/}
│   ├── operations/{slo.md, capacity.md, runbooks/}
│   └── legacy/                 # документация до SDD: реестр LEG-NNN, карта соответствий, замороженный changelog
├── openspec/                   # артефакты SDD
│   ├── constitution.md         # конституция проекта (высший приоритет)
│   ├── config.yaml             # профиль (csharp-api), активные схемы, гейты
│   ├── project.md              # контекст проекта для агентов
│   ├── proposals/              # предложения фич + шаблоны (proposal/tasks/performance/acceptance/contracts)
│   ├── schemas/                # машиночитаемые схемы валидации
│   ├── standards/              # инженерные стандарты 01..11
│   └── specs/                  # живые спецификации (после архивации предложений)
├── src/                        # исходники решений (заглушка — удалите/замените)
└── tests/                      # тесты (заглушка — удалите/замените)
```

---

## Сценарий A — новое решение

1. **Создайте репозиторий из шаблона** — кнопка **Use this template** на GitHub либо через CLI:

   ```powershell
   gh repo create <your-org>/<your-repo> --template Disthere/agentic-openspec --public --clone
   cd <your-repo>
   ```

2. **Адаптируйте шаблон** (пара минут):
   - [`global.json`](./global.json) — версия .NET SDK;
   - [`openspec/project.md`](./openspec/project.md) — стек, конвенции, архитектурная диаграмма;
   - [`README.md`](./README.md) — заголовок и описание вашего проекта;
   - [`Directory.Packages.props`](./Directory.Packages.props) — нужные зависимости (лишнее уберите);
   - `src/` и `tests/` — в шаблоне уже есть рабочая пара `Smoke` / `Smoke.Tests`;
     новые проекты добавляйте через `dotnet new` (см. ниже).

   **Бутстрап проектов (обязательно для тестов):**

   ```powershell
   dotnet new classlib -n <Name> -o src/<Name>
   dotnet new install xunit.v3.templates      # однократно: шаблон xUnit v3
   dotnet new xunit3 -n <Name>.Tests -o tests/<Name>.Tests
   dotnet sln add src/<Name>/<Name>.csproj tests/<Name>.Tests/<Name>.Tests.csproj
   ```

   ⚠️ `dotnet new xunit` (xUnit **v2**) при включённом Central Package Management даёт
   `NU1008` + `NU1010` — используйте `xunit3`. Версии пакетов задаются только в
   [`Directory.Packages.props`](./Directory.Packages.props), inline `Version=` не пишите.

3. **Убедитесь, что DSH видит правила**: откройте корень репозитория как workspace —
   канон для DSH — [`AGENTS.md`](./AGENTS.md) и [`openspec/`](./openspec); скиллы подхватываются из
   [`.agents/skills/`](./.agents/skills) автоматически.

4. **Первая спецификация (Spec First)** — попросите Оркестратора:

   ```text
   Прочитай AGENTS.md, openspec/constitution.md и стандарты. Делегируй субагенту
   пресет architect (.agents/architect.md) и создай предложение openspec/proposals/001-<slug>/
   со всеми артефактами (proposal.md, tasks.md, contracts/, performance.md, acceptance.md).
   Код не пиши — верни спецификацию на утверждение.
   ```

5. **Сквозной цикл**: Discovery (аналитик) → утвердите спецификацию → Build
   ([`.agents/csharp-dev.md`](./.agents/csharp-dev.md), `dotnet build`/`dotnet test`) → Verify
   ([`.agents/qa-engineer.md`](./.agents/qa-engineer.md) — улики в `acceptance.md`) → Review
   ([`.agents/reviewer.md`](./.agents/reviewer.md) — `VERDICT: Pass/Fail`) → Release
   ([`.agents/ops-release.md`](./.agents/ops-release.md) — changelog, откат, runbook).

---

## Сценарий B — существующее решение

Пересоздавать репозиторий не нужно. Скопируйте **только инструментальную часть** в существующий проект
и аккуратно смёржите конфликтующие файлы.

### Что копировать

| Путь | Копировать | Если файл уже есть |
| - | - | - |
| `.agents/` | ✅ обязательно | объедините со своими агентами |
| `openspec/` (без `proposals/archive`) | ✅ обязательно | перенесите; свои спеки положите рядом |
| `.clinerules`, `AGENTS.md` | ✅ обязательно | **влейте** правила, не перезаписывайте целиком |
| `.github/copilot-instructions.md`, `instructions/` | ⚪ по желанию | проверьте, нет ли уже похожих |
| `docs/` | ⚪ по желанию | объедините с вашей документацией |
| `.editorconfig` | ✅ **смёржить** | не перезаписывайте — слейте правила |
| `Directory.Build.props`, `Directory.Packages.props` | ✅ **смёржить** | ваши версии пакетов приоритетнее |
| `global.json` | ⚪ по желанию | подставьте свой SDK |
| `README.md`, `LICENSE`, `src/`, `tests/` | ❌ нет | это часть шаблона, не инструмента |
| `THIRD-PARTY.md` | ✅ если копируете `.agents/skills/` | сохраняет обязательства по MIT/CC BY-SA |

### Команда копирования (PowerShell)

```powershell
$template = "C:\path\to\agentic-openspec"     # локальная копия шаблона
$target   = "C:\path\to\your-existing-repo"   # ваш существующий репозиторий

# Инструментальная часть — копируется целиком
Copy-Item "$template\.agents"  $target -Recurse -Force
Copy-Item "$template\openspec" $target -Recurse -Force
Copy-Item "$template\docs"     $target -Recurse -Force
Copy-Item "$template\.clinerules" $target -Force
Copy-Item "$template\AGENTS.md"   $target -Force
New-Item -ItemType Directory -Force -Path "$target\.github\instructions" | Out-Null
Copy-Item "$template\.github\instructions\*"          "$target\.github\instructions" -Force
Copy-Item "$template\.github\copilot-instructions.md" "$target\.github" -Force

# ВАЖНО: .editorconfig, Directory.Build.props, Directory.Packages.props, global.json —
# смёржите вручную (не перезаписывайте), сохранив свои настройки и версии пакетов.
```

### Что ещё адаптировать под существующий проект

- [`openspec/project.md`](./openspec/project.md) — реальный стек, конвенции и границы сервисов.
- [`docs/architecture/service-boundaries.md`](./docs/architecture/service-boundaries.md) — ваши сервисы.
- [`openspec/standards/07-persistence.md`](./openspec/standards/07-persistence.md) и др. — под ваши БД/брокеры.
- Если в проекте уже есть свой `.clinerules` — **дополните** его ссылкой на `openspec/standards/` и
  `openspec/constitution.md`, а не заменяйте.

---

## Как это работает

### SDD-цикл

```text
Explore → Propose → (человек утверждает) → Apply → Review → Archive
            └── openspec/proposals/<NNN>-<slug>/
```

**Spec First**: код не пишется, пока нет утверждённой спецификации в [`openspec/proposals/`](./openspec/proposals).
Предложения валидируются по [`openspec/schemas/csharp-api.yaml`](./openspec/schemas/csharp-api.yaml).

### Роли (мультиагентность)

| Роль | Файл | Фаза | Отвечает за |
| - | - | - | - |
| Оркестратор | главная сессия DeepSeek Harness | все | план, делегирование субагентам (`agentPreset`), сведение результатов |
| Продуктовый аналитик | [`.agents/analyst.md`](./.agents/analyst.md) | Discovery | входные материалы, `IN-NNN`, измеримый критерий успеха |
| Архитектор | [`.agents/architect.md`](./.agents/architect.md) | Spec, Design | требования, C4/Mermaid, спецификация |
| Разработчик | [`.agents/csharp-dev.md`](./.agents/csharp-dev.md) | Build | код + `dotnet build`/`dotnet test` |
| Инженер верификации | [`.agents/qa-engineer.md`](./.agents/qa-engineer.md) | Verify | `acceptance.md`, `performance.md`, воспроизводимые улики |
| Ревьюер | [`.agents/reviewer.md`](./.agents/reviewer.md) | Review | вердикт `VERDICT: Pass/Fail` по двум осям |
| Ops / Release | [`.agents/ops-release.md`](./.agents/ops-release.md) | Release, Operate | changelog и версия, откат, SLO/capacity/runbook, поддержка |

Роли объявлены пресетами в [`dsh/profile/cordis.patch.yml`](./dsh/profile/cordis.patch.yml): субагент
получает свою композицию и модель. Отдельного агента-оркестратора нет — оркестратор это главная сессия.

### Гейт проверки

```powershell
dotnet restore
dotnet build --configuration Release --no-restore
dotnet test  --configuration Release --no-build
dotnet format --verify-no-changes
```

### Запуск через DeepSeek Harness

```powershell
npx @deepseek-ai/dsh web       # запуск Web UI без глобальной установки
# профиль с ролями и моделями:
powershell -ExecutionPolicy Bypass -File .\dsh\install.ps1
npx @deepseek-ai/dsh --profile agentic-openspec

# headless-прогон (для скриптов/CI)
npx @deepseek-ai/dsh --profile headless "Прочитай AGENTS.md и создай предложение 001-<slug> через пресет architect"
```

---

## CI (опционально)

Готовый workflow проверки целостности шаблона лежит в [`docs/ci/scaffold-check.yml`](./docs/ci/scaffold-check.yml).
Чтобы он запускался, перенесите его в `.github/workflows/`. Для пуша в этот защищённый путь нужен scope `workflow`:

```powershell
gh auth refresh -h github.com -s workflow
```

---

## Лицензия

[MIT](./LICENSE).

## Благодарности

Идеи и структура вдохновлены:
[OpenSpec (Fission-AI)](https://github.com/Fission-AI/OpenSpec) ·
[dotnet/eShop](https://github.com/dotnet/eShop) ·
[dotnet/aspnetcore — Benchmarks](https://github.com/dotnet/aspnetcore/blob/main/docs/Benchmarks.md) ·
[github/awesome-copilot](https://github.com/github/awesome-copilot) ·
[dotnet/runtime — coding style](https://github.com/dotnet/runtime/blob/main/docs/coding-guidelines/coding-style.md) ·
[meysamhadeli/booking-microservices](https://github.com/meysamhadeli/booking-microservices)

