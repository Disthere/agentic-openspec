---
description: 'C# conventions for high-load ASP.NET / microservices'
applyTo: '**/*.cs'
---

# C# — краткая выжимка

Полные правила: [`../../openspec/standards/01-code-style.md`](../../openspec/standards/01-code-style.md) и корневой `.editorconfig`.

- C# 12+ (`LangVersion=latest`), `<Nullable>enable</Nullable>`, warnings-as-errors.
- Именование: `PascalCase` — типы/члены; `_camelCase` — приватные поля; `s_` — статические; `I` — интерфейсы; `T` — дженерики; суффикс `Async`.
- Null-проверки: `is null` / `is not null` (не `== null` / `!= null`).
- Allman-скобки, 4 пробела, file-scoped namespace, `System.*`-usings сверху, строка ≤ 120 символов.
- `var` — только когда тип очевиден справа; ключевые слова вместо BCL-типов (`int`, не `Int32`).
- `nameof` вместо строковых литералов; XML-док для публичных API.
- Горячие пути: без LINQ и лишних аллокаций; `Span`/`ArrayPool`/`ValueTask`.
- Никаких `.Result`/`.Wait()`; `async`/`await` на всём пути с `CancellationToken`.
