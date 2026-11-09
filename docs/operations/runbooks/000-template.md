# Runbook: <имя сервиса>

> Скопируйте в `docs/operations/runbooks/<service>.md`. Один runbook — один сервис.

- **Владелец:** <команда/человек>
- **SLO:** [`../slo.md`](../slo.md)
- **Границы сервиса:** [`../../architecture/service-boundaries.md`](../../architecture/service-boundaries.md)

## Предварительные требования

- .NET SDK (см. `global.json`), Docker, доступ к кластеру k8s, `kubectl`.
- Секреты/строки подключения — из окружения/vault (не из репозитория).

## Деплой

1. Собрать образ: `docker build -t <service>:$(git rev-parse --short HEAD) .`
2. Применить манифесты: `kubectl apply -f deploy/`
3. Проверить rollout: `kubectl rollout status deploy/<service>`

## Диагностика

### Проблема: сервис не становится Ready
**Симптом:** `/health/ready` → 503
**Решение:** проверить зависимости (БД, брокер), логи `kubectl logs deploy/<service>`

### Проблема: рост latency (p99 > SLO)
**Симптом:** алерт по p99 в трейсах OpenTelemetry
**Решение:** проверить пул соединений, медленные запросы (логи EF Core), троттлинг внешних вызовов

### Проблема: растёт DLQ
**Симптом:** метрика DLQ > 0 и растёт
**Решение:** разобрать poison-сообщения, проверить идемпотентность/контракт (см. [`08-messaging.md`](../../../openspec/standards/08-messaging.md))

## Масштабирование

- Горизонтально: `kubectl scale deploy/<service> --replicas=N` (сервис stateless).
- Критерии — в [`../capacity.md`](../capacity.md).

## Откат

- `kubectl rollout undo deploy/<service>`
- Миграции БД — обратимые шаги/feature flags (см. `07-persistence.md`).

## Эскалация

- Контакты дежурного/владельца, ссылки на дашборды и трейсы.
