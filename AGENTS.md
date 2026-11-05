# AGENTS.md

Этот файл — кросс-инструментальная точка входа (стандарт agents.md). Авторитетные правила для Cline
живут в [`.clinerules`](./.clinerules); держи оба файла синхронизированными.

## Что это за репозиторий

**Агентное рабочее пространство Spec-Driven Development (SDD)** для проекта на **C# / .NET**. Cline
выступает Оркестратором и делегирует работу специализированным субагентам из [`.agents/`](./.agents).

## Непреложные правила

1. **Spec First (сначала спецификация)** — никакого продакшн-кода, пока в [`openspec/proposals/`](./openspec/proposals) нет спецификации.
2. **Только dotnet CLI** — сборка, тесты и форматирование через `dotnet build`, `dotnet test`, `dotnet format`.
3. **C# 12+ / .NET 8+**, nullable включён, warnings as errors, тесты на xUnit.
4. **Делегируй** — направляй работу Архитектора / Разработчика / Ревьюера в `.agents/*.md` через инструмент `spawn_agent`.
5. **Читай конституцию и стандарты** — [`openspec/constitution.md`](./openspec/constitution.md) (высший приоритет) и [`openspec/standards/`](./openspec/standards) обязательны перед написанием кода.

## Карта

| Путь | Назначение |
| - | - |
| `.clinerules` | Правила Cline (стандарты C#, процесс SDD, делегирование) |
| `.agents/architect.md` | Роль Архитектора — требования + дизайн + спецификации |
| `.agents/csharp-dev.md` | Роль Разработчика — реализация на C# |
| `.agents/reviewer.md` | Роль Ревьюера — вердикт о соответствии спецификации |
| `.agents/skills/` | Переиспользуемые скиллы агентов (`<name>/SKILL.md`) |
| `openspec/constitution.md` | Конституция проекта (высший приоритет) |
| `openspec/config.yaml` | Профиль проекта + активные схемы |
| `openspec/project.md` | Контекст проекта для агентов |
| `docs/` | Архитектура (границы, ADR) и эксплуатация (SLO, capacity, runbooks) |
| `Directory.Build.props` / `Directory.Packages.props` | Общие настройки сборки и централизованные версии |
| `.github/copilot-instructions.md` | Короткая точка входа для GitHub Copilot |
| `openspec/proposals/` | Предложения фич (`<NNN-slug>/`) и шаблон |
| `openspec/schemas/` | Машиночитаемые схемы валидации |
| `openspec/standards/` | Инженерные стандарты (Code Style, Architecture, Handoffs, Docs, DoD) |
| `.editorconfig` | Стиль C# (Allman, отступы, именование, анализаторы) — авто-формат и линт |
| `openspec/specs/` | Живые спецификации |

Полный свод правил — в [`.clinerules`](./.clinerules).
