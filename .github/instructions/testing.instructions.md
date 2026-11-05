---
description: 'Testing conventions for .NET services'
applyTo: '**/tests/**/*.cs'
---

# Тестирование — краткая выжимка

Полные правила: [`../../openspec/standards/05-definition-of-done.md`](../../openspec/standards/05-definition-of-done.md), [`../../openspec/standards/01-code-style.md`](../../openspec/standards/01-code-style.md).

- Фреймворк: **xUnit**; ассерты — **FluentAssertions 7.x** (8.x — платная лицензия).
- Именование: `Method_Scenario_ExpectedResult` или `Should_...`; один сценарий на тест.
- Табличные случаи — `[Theory]`/`[InlineData]`; моки — NSubstitute.
- Интеграционные тесты — `WebApplicationFactory<T>`; инфраструктура — Testcontainers.
- Покрытие: >80% общий, >90% Domain.
- Комментарии «Arrange/Act/Assert» не пишем; тесты проверяют поведение `WHEN`/`THEN`.
- Покрываем граничные случаи и ошибки, а не только happy-path.
