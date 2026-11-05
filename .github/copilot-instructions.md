# Copilot Instructions — agentic-openspec

Короткая точка входа. **Канонические правила — в `.clinerules` и `openspec/standards/`**; этот файл не дублирует их.

## Порядок работы

1. **Spec First** — сначала спецификация в `openspec/proposals/`, затем код.
2. Прочитай конституцию `openspec/constitution.md` и относящиеся к задаче стандарты `openspec/standards/`.
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

- Правила: [`.clinerules`](../.clinerules)
- Конституция: [`openspec/constitution.md`](../openspec/constitution.md)
- Стандарты: [`openspec/standards/`](../openspec/standards/)
- Инструкции по темам: `.github/instructions/*.instructions.md`
