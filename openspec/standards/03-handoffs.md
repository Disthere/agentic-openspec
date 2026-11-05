# 03. Handoffs (передача контекста)

Handoff — формализованная передача контекста между этапами, сервисами или людьми. У каждого handoff есть
**вход**, **выход** и **критерии приёмки**.

## 3.1 Типы handoffs

| Handoff | Откуда | Куда | Артефакт | Критерии приёмки |
| - | - | - | - | - |
| **Spec → Code** | Спецификация | Разработка | Контрактный код (генерация), ручная логика | Компилируется, тесты проходят, есть трассируемость |
| **Code → Test** | Код | Тестирование | Тест-кейсы, BDD-сценарии | Покрытие ≥80% (Domain ≥90%), граничные случаи покрыты |
| **Dev → Dev** | Разработчик | Разработчик | PR (описание + спека + тесты) | CI зелёный, ревью пройдено, документация обновлена |
| **Service → Prod** | Разработка | Прод | Образ контейнера, конфиг, миграции, Helm/k8s-манифесты | Smoke-тесты пройдены, health-checks зелёные, мониторинг настроен, есть rollback |
| **Service → Service** | Сервис A | Сервис B | Контракт (`.proto` / OpenAPI / схема сообщения) | Контракт задокументирован, версионирован, покрыт consumer-driven contract-тестами |

## 3.2 Формат handoff-документа

Для каждого handoff создаётся документ (или секция в PR):

```markdown
# Handoff: Spec → Code (PAY-001)

## Контекст
Реализация создания платежа согласно спеке PAY-001.

## Входные артефакты
- `openspec/specs/payments/spec.md#create-payment`
- `specs/contracts/payments.proto`

## Выходные артефакты
- `src/Payments.Application/CreatePaymentHandler.cs`
- `src/Payments.Api/Endpoints/CreatePaymentEndpoint.cs`
- `tests/Payments.UnitTests/CreatePaymentHandlerTests.cs`

## Критерии приёмки
- [ ] Код компилируется без warnings
- [ ] Все тесты проходят
- [ ] Покрытие >80% (Domain >90%)
- [ ] Трассируемость (spec-id в XML-док)
- [ ] Ревью пройдено

## Известные ограничения
- Не поддерживает частичный возврат (будет в PAY-002)
```

## 3.3 Handoffs в CI/CD

Автоматизируем handoffs через пайплайны:

```yaml
# .github/workflows/spec-to-code.yml
name: Spec to Code Handoff
on:
  push:
    paths:
      - 'specs/contracts/**.proto'

jobs:
  generate:
    steps:
      - name: Generate C# from Protobuf
        run: dotnet tool run protobuf-gen --input specs/contracts --output src/Generated

      - name: Validate generated code
        run: dotnet build src/Generated -c Release

      - name: Run contract tests
        run: dotnet test tests/Contracts.IntegrationTests -c Release

      - name: Create PR with generated code
        run: gh pr create --title "Auto-generated from spec" --body "..."
```

## 3.4 Правила handoff

- Ни один handoff не пропускает **гейт верификации** (`dotnet build` + `dotnet test`).
- Изменение контракта между сервисами — только через **новый handoff Service → Service** с версионированием.
- Каждый handoff линкуется: предложение → спека → код → тесты. Разрыв трассируемости = `Fail` на ревью.
