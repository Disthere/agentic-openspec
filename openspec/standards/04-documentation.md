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
| **Changelog** | Что изменилось между релизами | Markdown (Keep a Changelog) | `CHANGELOG.md` (корень) |

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

## 4.6 Changelog

Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/), версионирование — [SemVer](https://semver.org/lang/ru/).
Файл — `CHANGELOG.md` в корне проекта. Готовый к копированию шаблон — [`docs/CHANGELOG-TEMPLATE.md`](../../docs/CHANGELOG-TEMPLATE.md).

**Правила:**

- Заголовок записи — `## [X.Y.Z] — YYYY-MM-DD · <суть в одну строку> (<ID>)`, где `(<ID>)` — **привязка к задаче**:
  ID предложения (`openspec/proposals/<NNN-slug>`), `spec-id` (`PAY-001`) или issue (`#123`). Без привязки запись не принимается.
- Версия по SemVer: **MAJOR** — ломающее изменение, **MINOR** — новая функциональность, **PATCH** — исправление.
- Незавершённое накапливается в `## [Unreleased]` и при релизе переносится в `## [X.Y.Z] — YYYY-MM-DD`.
- Секции (пишутся только непустые). Стандартные: `Добавлено`, `Изменено`, `Исправлено`, `Удалено`, `Устарело`, `Безопасность`.
  Наши дополнения: `Не изменилось` (явно: дефолтное поведение прежнее), `Производительность` (замер baseline→candidate),
  `Миграция` (для ломающих изменений), `Тесты` (число тестов и предупреждений сборки).
- Каждый пункт отвечает на три вопроса: **что** (тип/метод/ключ конфига), **где** (файл/слой), **эффект** (зачем / как меняется поведение).
- Изменения дефолтов конфигурации указываются явно; для ломающих изменений обязательна секция `Миграция`.
- Changelog пишется в том же PR, что и изменение, и входит в DoD релиза
  ([`05-definition-of-done.md`](./05-definition-of-done.md), п. 5.4).
