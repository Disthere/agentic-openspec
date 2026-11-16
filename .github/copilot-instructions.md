# Copilot Instructions — agentic-openspec

Короткая точка входа. **Канонические правила — в [`AGENTS.md`](../AGENTS.md) и [`sdd/openspec/`](../sdd/openspec)**;
этот файл их не дублирует.

## Порядок работы

1. **Spec First** — сначала спецификация в `sdd/openspec/proposals/`, затем код.
2. Прочитай конституцию `sdd/openspec/constitution.md` и относящиеся к задаче стандарты `sdd/openspec/standards/`.
3. Не меняй границы сервисов, публичные контракты, версии SDK/зависимостей и схему данных вне утверждённого плана.
4. Неоднозначность — зафиксируй вопрос, не придумывай бизнес-правило.

## Команды проверки

```powershell
dotnet restore
dotnet build --configuration Release --no-restore
dotnet test  --configuration Release --no-build
dotnet format --verify-no-changes
```

## Запреты

- Секреты и PII — не в коде, не в логах.
- Breaking change контрактов — без плана миграции запрещён.
- SLO/«оптимизировано» — без воспроизводимого нагрузочного теста.

## Ссылки

- Правила: [`AGENTS.md`](../AGENTS.md) (канон), [`.clinerules`](../.clinerules) (зеркало)
- Конституция: [`sdd/openspec/constitution.md`](../sdd/openspec/constitution.md)
- Стандарты: [`sdd/openspec/standards/`](../sdd/openspec/standards)
- Инструкции по темам: `.github/instructions/*.instructions.md`
