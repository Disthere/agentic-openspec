# 02. Подходы к написанию кода

## 2.1 Архитектурные принципы

**Clean Architecture + DDD** (внутри каждого сервиса):

```text
┌───────────────────────────────────────────────┐
│ Presentation (Web API, gRPC, Hosted Workers)  │ ← зависит от Application
├───────────────────────────────────────────────┤
│ Application (Use Cases, Handlers, Services)   │ ← зависит от Domain
├───────────────────────────────────────────────┤
│ Domain (Entities, Value Objects, Ports)       │ ← НЕ зависит ни от чего
├───────────────────────────────────────────────┤
│ Infrastructure (EF Core, Broker, Cache, HTTP) │ ← реализует порты Domain
└───────────────────────────────────────────────┘
```

**Правила:**
- Domain не знает о существовании Infrastructure.
- **Dependency Inversion:** порты (интерфейсы) объявлены в Domain, адаптеры — в Infrastructure.
- **Value Objects** вместо примитивной одержимости (деньги, идентификаторы, единицы измерения).

```csharp
// ❌ Плохо: примитивная одержимость
public class Order
{
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "USD";
}

// ✅ Хорошо: Value Objects
public readonly record struct CustomerId(Guid Value);

public readonly record struct Money(decimal Amount, string Currency)
{
    public static Money Of(decimal amount, string currency)
    {
        if (amount < 0) throw new ArgumentOutOfRangeException(nameof(amount));
        return new(amount, currency);
    }
}

public sealed class Order
{
    public required CustomerId CustomerId { get; init; }
    public required Money Total { get; init; }
}
```

## 2.2 SOLID

- **S** — один класс, одна причина изменения. Обработчик не знает о транспорте.
- **O** — расширяем через интерфейсы/стратегии, не правим готовый код.
- **L** — подтипы заменяемы базовыми типами без сюрпризов.
- **I** — много узких интерфейсов лучше одного «божественного».
- **D** — зависим от абстракций, не от реализаций.

## 2.3 SDD-подходы

**Spec-First:**
1. Сначала спецификация (Markdown + Mermaid + контракты).
2. Ревью спецификации как кода.
3. Генерация boilerplate из контрактов (protobuf/OpenAPI → Source Generators, T4, Scriban).
4. Бизнес-логика строго по спецификации.
5. Тесты валидируют соответствие кода спецификации.

**Traceability (трассируемость):**
```csharp
/// <summary>Создаёт платёж и публикует событие PaymentCreated.</summary>
/// <spec-id>PAY-001</spec-id>
/// <spec-ref>openspec/specs/payments/spec.md#create-payment</spec-ref>
public Task<PaymentId> CreateAsync(CreatePayment command, CancellationToken ct) { /* ... */ }
```

**Contract-Driven:**
- Границы между сервисами — это контракты (gRPC `.proto`, OpenAPI, схема сообщения).
- Контракты версионируются (SemVer для API, эволюция protobuf/схем, миграции БД).
- Изменение контракта = изменение спецификации = ревью.

## 2.4 Специфика высоконагруженных микросервисов

- **Отказоустойчивость (Polly):** таймауты, retry с jitter и бюджетом, circuit breaker, bulkhead, fallback.
- **Таймауты и отмена:** каждый внешний вызов с `CancellationToken` и таймаутом; никаких бесконечных ожиданий.
- **Backpressure:** ограничение параллелизма (`Channel<T>`, `SemaphoreSlim`, rate limiting, `System.Threading.RateLimiting`).
- **Наблюдаемость:** OpenTelemetry (traces/metrics/logs), корреляция через `traceparent`, структурные логи
  (`ILogger` + scopes), экспорт в OTLP.
- **Health-checks:** `/health/live`, `/health/ready`, `/health/startup`; зависимости добавлены в readiness.
- **Идемпотентность:** ключи идемпотентности, at-least-once + дедупликация, transactional outbox + inbox.
- **Messaging:** Kafka/RabbitMQ, consumer groups, dead-letter queues, партиционирование для порядка.
- **Сериализация:** gRPC/Protobuf — для внутренних контрактов; JSON (`System.Text.Json` + source generation) — для внешних.
- **Масштабирование:** stateless, горизонтальное; состояние — в Redis/БД; sticky sessions запрещены.
- **Изоляция данных:** database-per-service, никаких общих таблиц между сервисами.
- **Безопасность:** аутентификация/авторизация на границе, секреты — из vault/ключей окружения (не в репозитории).

## 2.5 Прикладные практики ASP.NET Core

- **Валидация:** DataAnnotations + FluentValidation на границе; единый pipeline, кастомные ответы валидации.
- **Обработка ошибок:** глобальный middleware (`IExceptionHandler` / `UseExceptionHandler`), единый формат ошибок —
  `ProblemDetails` (**RFC 9457**); никаких «утечек» stack trace в ответ.
- **API-версионирование:** стратегия версий (URL/header), OpenAPI/Swagger с описанием эндпоинтов, параметров,
  ответов и авторизации (для controller-based и Minimal APIs).
- **Логирование:** структурные логи (`ILogger` + scopes; Serilog — опционально), correlation/`traceparent` в каждом запросе.
- **Кэш:** `IMemoryCache` (локальный), `IDistributedCache`/Redis (распределённый), response caching.
- **Данные:** пагинация/фильтрация/сортировка для больших выборок, компрессия ответов, никакого N+1.
- **Тесты:** покрываем критичные пути; комментарии «Arrange/Act/Assert» не пишем; интеграционные тесты — через
  `WebApplicationFactory<T>`; моки внешних зависимостей.
- **Деплой:** контейнеризация (`dotnet publish -p:PublishProfile=DefaultContainer` или Dockerfile), health-checks /
  readiness-probes, конфигурация по окружениям (`appsettings.{Environment}.json`).
