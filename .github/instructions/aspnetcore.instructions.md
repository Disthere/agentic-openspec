---
description: 'ASP.NET Core API conventions'
applyTo: '**/*.cs'
---

# ASP.NET Core — краткая выжимка

Полные правила: [`../../openspec/standards/06-api.md`](../../openspec/standards/06-api.md), [`../../openspec/standards/02-architecture.md`](../../openspec/standards/02-architecture.md).

- Minimal APIs для новых эндпоинтов; корректные коды состояния и `TypedResults`.
- Ошибки — единый `ProblemDetails` (**RFC 9457**); без «утечек» stack trace.
- Валидация на границе (DataAnnotations + FluentValidation).
- Partition по версиям: `Asp.Versioning`; OpenAPI генерируется автоматически.
- Идемпотентность изменяющих операций (`Idempotency-Key`).
- Внешние вызовы — таймауты, retry/jitter, circuit breaker (`Microsoft.Extensions.Http.Resilience`).
- Наблюдаемость — OpenTelemetry; health-checks `/health/live`, `/health/ready`.
- Никакого sync-over-async и блокировок в обработчиках запроса.
