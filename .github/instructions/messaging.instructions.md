---
description: 'Asynchronous messaging conventions'
applyTo: '**/*.cs'
---

# Обмен сообщениями — краткая выжимка

Полные правила: [`../../openspec/standards/08-messaging.md`](../../openspec/standards/08-messaging.md).

- Доставка по умолчанию — at-least-once → обработчик **идемпотентен** (dedup по `MessageId`).
- Публикация событий согласована с записью в БД (**transactional outbox**); на входе — inbox.
- Порядок гарантируется только внутри партиции (partition key = id агрегата).
- Retry с backoff + jitter и лимитом; неисправимые сообщения → **DLQ** (обработка DLQ наблюдаема).
- Частичный отказ недопустим: эффект применяется целиком либо не применяется.
- Схема события — часть контракта; эволюция только обратно совместимая.
