# 04. Документация артефактов

Документация — часть артефакта, а не отдельная сущность. Код без документации считается незавершённым.

## 4.1 Уровни документации

| Уровень | Что документируем | Формат | Где хранится |
| - | - | - | - |
| **Spec** | Бизнес-правила, архитектура | Markdown, Mermaid | `openspec/` |
| **API** | Публичные интерфейсы, методы | XML Doc Comments | В коде (`///`) |
| **Code** | Сложная логика, решения | Комментарии в коде | В коде (`//`) |
| **Runbook** | Запуск, настройка, диагностика | Markdown | `docs/runbooks/` |
| **ADR** | Архитектурные решения | Markdown (шаблон) | `docs/adr/` |

## 4.2 Шаблон XML Doc Comments

```csharp
/// <summary>
/// Создаёт новый платёж и публикует событие PaymentCreated.
/// </summary>
/// <param name="command">Данные платежа (сумма, валюта, получатель).</param>
/// <param name="ct">Токен отмены.</param>
/// <returns>Идентификатор созданного платежа.</returns>
/// <exception cref="ArgumentNullException">Если <paramref name="command"/> is null.</exception>
/// <exception cref="ArgumentOutOfRangeException">Если сумма ≤ 0.</exception>
/// <spec-id>PAY-001</spec-id>
/// <example>
/// <code>
/// var id = await handler.CreateAsync(new CreatePayment(Money.Of(100m, "USD")), ct);
/// </code>
/// </example>
/// <remarks>
/// Идемпотентно по <c>Idempotency-Key</c>: повторный вызов с тем же ключом возвращает тот же результат.
/// </remarks>
public Task<PaymentId> CreateAsync(CreatePayment command, CancellationToken ct) { /* ... */ }
```

## 4.3 Шаблон ADR (Architecture Decision Record)

```markdown
# ADR-001: gRPC/Protobuf для внутренних контрактов

## Статус
Accepted

## Контекст
Нужно передавать данные между микросервисами с минимальной задержкой и строгой типизацией.

## Решение
Используем gRPC + Protobuf для внутренних контрактов между сервисами.

## Альтернативы
- REST + JSON: проще, но медленнее и менее строгий контракт
- MessagePack: компактнее, но слабее экосистема контрактов
- GraphQL: гибкий, но избыточный для inter-service вызовов

## Последствия
- ✅ Строгая типизация и генерация кода
- ✅ Высокая производительность (HTTP/2, бинарная сериализация)
- ✅ Версионирование через package/эволюцию полей
- ❌ Нужен protoc/`Grpc.Tools`
- ❌ Менее читаемо «в сыром виде»
```

## 4.4 Шаблон Runbook (микросервис)

```markdown
# Runbook: сервис payments-api

## Предварительные требования
- .NET 8 SDK, Docker, доступ к кластеру k8s
- Секреты/строки подключения — из конфигурации окружения (не из репозитория)

## Деплой
1. Собрать образ: `docker build -t payments-api:$(git rev-parse --short HEAD) .`
2. Применить манифесты: `kubectl apply -f deploy/`
3. Проверить rollout: `kubectl rollout status deploy/payments-api`

## Диагностика
### Проблема: сервис не становится Ready
**Симптом:** `/health/ready` возвращает 503
**Решение:** проверить зависимости (БД, брокер), логи `kubectl logs deploy/payments-api`

### Проблема: рост latency запросов
**Симптом:** p99 > SLO в трейсах OpenTelemetry
**Решение:** проверить пул соединений, медленные запросы (EF Core логи), троттлинг внешних вызовов

## Масштабирование и откат
- Горизонтально: `kubectl scale deploy/payments-api --replicas=N` (сервис stateless)
- Откат: `kubectl rollout undo deploy/payments-api`
```

## 4.5 Правила

- Публичные API **обязаны** иметь XML Doc Comments (иначе — warning от анализатора).
- Каждое архитектурное решение — ADR со статусом (`Proposed`/`Accepted`/`Superseded`).
- Каждый сервис — Runbook (деплой, диагностика, откат, масштабирование).
- Документация обновляется в том же PR, что и код.
