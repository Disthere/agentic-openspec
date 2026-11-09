# AGENTS.md

Этот файл — точка входа для агентов (стандарт agents.md) и **канон правил для DeepSeek Harness**.
[`.clinerules`](./.clinerules) — совместимое зеркало для других инструментов; держи оба файла
синхронизированными, но при расхождении канон — этот файл.

> ⏸ **Режим старта:** ничего не делать до явной команды пользователя (ни разведки, ни правок, ни коммитов).
> Состояние и список готовых команд — [`docs/SESSION-START.md`](./docs/SESSION-START.md).

## Что это за репозиторий

**Агентное рабочее пространство Spec-Driven Development (SDD)** для проекта на **C# / .NET**. Главная
сессия **DeepSeek Harness** выступает Оркестратором и делегирует работу субагентам с `agentPreset` из
[`.agents/`](./.agents) — по фазам жизненного цикла
([`openspec/constitution.md`](./openspec/constitution.md) §7).

## Непреложные правила

1. **Spec First (сначала спецификация)** — никакого продакшн-кода, пока в [`openspec/proposals/`](./openspec/proposals) нет спецификации.
2. **Только dotnet CLI** — сборка, тесты и форматирование через `dotnet build`, `dotnet test`, `dotnet format`.
3. **C# 12+ / .NET 8+**, nullable включён, warnings as errors, тесты на xUnit.
4. **Делегируй** — направляй работу шести ролей (аналитик → архитектор → разработчик → инженер верификации →
   ревьюер → Ops/Release) в `.agents/*.md` субагентам DSH; пресеты — [`dsh/profile/cordis.patch.yml`](./dsh/profile/cordis.patch.yml).
   Отдельного агента-оркестратора нет: оркестратор — главная сессия DSH.
5. **Читай конституцию и стандарты** — [`openspec/constitution.md`](./openspec/constitution.md) (высший приоритет) и [`openspec/standards/`](./openspec/standards) обязательны перед написанием кода.

## Карта

| Путь | Назначение |
| - | - |
| `AGENTS.md` | **Канон правил** для агентов (DSH читает этот файл): стандарты C#, процесс SDD, делегирование |
| `.clinerules` | Совместимое зеркало правил для других инструментов (DSH его не читает) |
| `dsh/profile/cordis.patch.yml` | Пресеты ролей DeepSeek Harness (модель + персона) |
| `.agents/analyst.md` | Роль продуктового аналитика — вход, `IN-NNN`, критерий успеха |
| `.agents/architect.md` | Роль Архитектора — требования + дизайн + спецификации |
| `.agents/csharp-dev.md` | Роль Разработчика — реализация на C# |
| `.agents/qa-engineer.md` | Роль инженера верификации — улики, `acceptance.md` |
| `.agents/reviewer.md` | Роль Ревьюера — двухосевой вердикт |
| `.agents/ops-release.md` | Роль Ops / Release — релиз, эксплуатация, поддержка |
| `.agents/skills/` | Переиспользуемые скиллы агентов (`<name>/SKILL.md`) |
| `openspec/constitution.md` | Конституция проекта (высший приоритет) |
| `openspec/config.yaml` | Профиль проекта + активные схемы |
| `openspec/project.md` | Контекст проекта для агентов |
| `CHANGELOG.md` | История изменений (Keep a Changelog + SemVer, привязка к задачам) |
| `OPEN_QUESTIONS.md` / `DECISIONS.md` | Открытые вопросы (`OQ-N`) и журнал решений (`D-NNN`) |
| `inputs/` | Входные материалы заказчика (ТЗ, концепции, макеты) + реестр `INDEX.md` |
| `docs/` | Архитектура (границы, ADR) и эксплуатация (SLO, capacity, runbooks) |
| `Directory.Build.props` / `Directory.Packages.props` | Общие настройки сборки и централизованные версии |
| `.github/copilot-instructions.md` | Короткая точка входа для GitHub Copilot |
| `openspec/proposals/` | Предложения фич (`<NNN-slug>/`) и шаблон |
| `openspec/schemas/` | Машиночитаемые схемы валидации |
| `openspec/standards/` | Инженерные стандарты (Code Style, Architecture, Handoffs, Docs, DoD) |
| `.editorconfig` | Стиль C# (Allman, отступы, именование, анализаторы) — авто-формат и линт |
| `openspec/specs/` | Живые спецификации |

Полный свод правил — в этом файле (канон для DSH); детализация — в [`openspec/`](./openspec).
[`.clinerules`](./.clinerules) — совместимое зеркало для других инструментов.
