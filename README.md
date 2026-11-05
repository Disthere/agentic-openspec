# agentic-openspec

> Шаблон **Spec-Driven Development (SDD)** и мультиагентной разработки для **C# / .NET** —
> высоконагруженные ASP.NET Core-приложения и микросервисы. Заточен под [Cline](https://cline.bot)
> (VS Code, Desktop, CLI) и его субагентов.

[![Use this template](https://img.shields.io/badge/Use%20this-template-2ea44f?logo=github)](#сценарий-a--новое-решение)
![workflow](https://img.shields.io/badge/workflow-Spec--First-blue)
![C#](https://img.shields.io/badge/C%23-12%2B-239120?logo=csharp)
![.NET](https://img.shields.io/badge/.NET-8%2B-512BD4?logo=dotnet)

Готовый «фундамент» проекта: правила для агента, роли субагентов, инженерные стандарты,
конституция, SDD-артефакты и общие настройки сборки .NET. Подходит и для **новых**, и для
**существующих** решений — см. два сценария ниже.

---

## Что внутри

- **Правила агента** — [`.clinerules`](./.clinerules) (Cline), [`AGENTS.md`](./AGENTS.md)
  (кросс-инструментальный стандарт), краткие указатели в [`.github/instructions/`](./.github/instructions).
- **Роли субагентов** — [`.agents/`](./.agents): Архитектор, Разработчик C#, Ревьюер + скиллы.
- **Конституция проекта** — [`openspec/constitution.md`](./openspec/constitution.md) (высший приоритет).
- **Инженерные стандарты 01–11** — [`openspec/standards/`](./openspec/standards): Code Style, Architecture,
  Handoffs, Documentation, DoD, API, Persistence, Messaging, Security, Observability, Performance.
- **SDD-процесс** — [`openspec/`](./openspec): конфиг, схемы валидации, шаблоны предложений.
- **Документация эксплуатации** — [`docs/`](./docs): границы сервисов, ADR, SLO, capacity, runbooks.
- **Настройки сборки .NET** — [`global.json`](./global.json), [`Directory.Build.props`](./Directory.Build.props),
  [`Directory.Packages.props`](./Directory.Packages.props), [`.editorconfig`](./.editorconfig).

## Требования

- **.NET SDK 10** (см. [`global.json`](./global.json)) — либо поправьте версию под свой SDK.
- **Node.js 18+** и npm — для Cline CLI.
- **Cline** — расширение VS Code (базово) или **Cline CLI / Desktop** (нужны для субагентов `spawn_agent`).

## Структура

```text
agentic-openspec/
├── .clinerules                 # правила Cline (C#, SDD, делегирование, протокол агента)
├── AGENTS.md                   # кросс-инструментальное зеркало правил
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
│   └── operations/{slo.md, capacity.md, runbooks/}
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
   - `src/` и `tests/` — удалите заглушки и создайте проекты (`dotnet new`).

3. **Убедитесь, что Cline видит правила**: откройте репозиторий в Cline — в панели Rules должны
   появиться `.clinerules` и `AGENTS.md`.

4. **Первая спецификация (Spec First)** — попросите Оркестратора:

   ```text
   Прочитай openspec/constitution.md и .clinerules. Делегируй роль Архитектора
   (.agents/architect.md) и создай предложение openspec/proposals/001-<slug>/ со всеми
   артефактами (proposal.md, tasks.md, contracts/, performance.md, acceptance.md).
   Код не пиши — верни спецификацию на утверждение.
   ```

5. **Сквозной цикл**: утвердите спецификацию → Разработчик ([`.agents/csharp-dev.md`](./.agents/csharp-dev.md))
   реализует и прогоняет `dotnet build`/`dotnet test` → Ревьюер ([`.agents/reviewer.md`](./.agents/reviewer.md))
   даёт `Pass` или список нарушений.

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

| Роль | Файл | Отвечает за |
| - | - | - |
| Оркестратор | Cline | план, делегирование, сведение результатов |
| Архитектор | [`.agents/architect.md`](./.agents/architect.md) | требования, C4/Mermaid, спецификация |
| Разработчик | [`.agents/csharp-dev.md`](./.agents/csharp-dev.md) | код + `dotnet build`/`dotnet test` |
| Ревьюер | [`.agents/reviewer.md`](./.agents/reviewer.md) | вердикт `Pass` / список нарушений |

Субагенты (`spawn_agent`) работают в **Cline CLI и Desktop**; в VS Code-расширении их нет — там роли
применяются последовательно.

### Гейт проверки

```powershell
dotnet restore
dotnet build --configuration Release --no-restore
dotnet test  --configuration Release --no-build
dotnet format --verify-no-changes
```

### Запуск через Cline CLI

```powershell
npm install -g cline     # установка (даёт команду cline)
cline --version

# одноразовый прогон в plan-режиме (JSON удобен для скриптов/CI)
cline -c . -p --json -t 300 "Прочитай .clinerules и создай предложение 001-<slug> через Архитектора"
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

