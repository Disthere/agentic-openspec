# 01. Code Style (C#)

## 1.1 Базовые соглашения

Основа — [Microsoft C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
и [dotnet/runtime coding-style](https://github.com/dotnet/runtime/blob/main/docs/coding-guidelines/coding-style.md).

**Именование:**
- `PascalCase` — публичные члены, типы, методы, свойства.
- `camelCase` — параметры и локальные переменные.
- `_camelCase` — приватные и внутренние поля (с подчёркиванием).
- `s_camelCase` — **статические** приватные поля (префикс `s_`). Это единственное место, где
  стандарт требует такой префикс; `.editorconfig` даёт его как `suggestion`, чтобы не ломать сборку.
- Префикс `I` — интерфейсы (`IOrderService`, `IPaymentGateway`).
- Префикс `T` — дженерик-параметры (`TResult`, `TRequest`).
- Суффикс `Async` — все асинхронные методы (`GetOrderAsync`).

**`var`:** используем, когда тип очевиден из правой части (`var orders = new List<Order>()`).
Если тип не очевиден — пишем его явно. Правило `.editorconfig`:
`csharp_style_var_when_type_is_apparent = true:suggestion` (не ошибка сборки).

**Платформа и версия языка:** линия проекта — **.NET 10** (`net10.0`), **C# 14** (решение
[`D-015`](../../DECISIONS.md), гейт D-01(A) плана). В `Directory.Build.props` держим
`<LangVersion>latest</LangVersion>` — осознанно: на SDK `10.0.401` это и есть C# 14, а пин
конкретного номера позволил бы коду молча отстать от заявленной версии. `.NET 8`/`9` — **EOL
с 2026-11-10**, новые проекты на них не создаются. SDK фиксируется `global.json`.

**Модификаторы доступа:** указываем всегда явно, никогда не полагаемся на default.

**Readonly:** поля, не изменяющиеся после конструктора, — `readonly` (или `static readonly`).

**Null-safety:** `<Nullable>enable</Nullable>` во всех проектах. `null` без явной причины запрещён.
Используем `required`, `init`, `record`, `ArgumentNullException.ThrowIfNull`.

**DI:** зависимость от абстракций, внедрение через конструктор, корректные времена жизни.

**Тестовые библиотеки (правило, а не пожелание):** ассерты — **FluentAssertions ≤ 7.2.2**; версия 8.x
**запрещена** — она под платной лицензией Xceed. Альтернатива с совместимым API — `AwesomeAssertions`.
Моки — **NSubstitute**; `Moq` не используется (его нет в `Directory.Packages.props`).
Версия `FluentAssertions` проверяется при ревью и регрессом в CI: `dotnet list package` не должен
показывать ≥ 8.0.0 (P1-8 плана).

**Async:** пробрасываем `CancellationToken`; `ValueTask` — для горячих путей, где результат часто
готов синхронно (кэш, буферизованный ответ).

## 1.2 Специфика высоконагруженных ASP.NET / микросервисов

**Аллокации в горячем пути** (обработка запроса, десериализация, построение ответа):
```csharp
// ❌ Плохо: аллокация на каждый запрос
public async Task<IActionResult> GetAsync(string id)
{
    var items = new List<Item>();   // аллокация на каждый вызов
    // ...
}

// ✅ Хорошо: пул буферов вместо новых массивов
byte[] buffer = ArrayPool<byte>.Shared.Rent(4096);
try { /* ... */ }
finally { ArrayPool<byte>.Shared.Return(buffer); }
```

- Горячий путь: `Span<T>`/`Memory<T>`, `stackalloc` (малые буферы), `ArrayPool<T>`, `System.IO.Pipelines`,
  `RecyclableMemoryStream`, `ValueTask`.
- Избегаем боксинга, лишних строковых конкатенаций, LINQ и `foreach` по интерфейсам там, где можно по `Span`.
- Парсинг — на `Span`: `Utf8JsonReader`, `int.TryParse(ReadOnlySpan<char>)`.
- **LINQ запрещён в горячих путях** (обработка запроса, сериализация). Допустим в холодных (фон, отчёты).

**Структуры vs классы:**
- `readonly record struct` — маленькие частые значения (ID, `Money`, лёгкие DTO горячего пути).
- `record` — конфигурация, DTO, сообщения, контракты.
- `class` — сервисы, репозитории, обработчики (ссылочная семантика, DI).

**Исключения:**
- В горячем пути исключений нет — используем `Result<T>` / паттерн `Try*`.
- Исключения только для действительно исключительных ситуаций (сбой внешнего сервиса, невалидный контракт).
- Не управляем потоком через `throw`: в .NET исключения дороги.

**I/O и данные:**
- Всё асинхронно; sync-over-async (`.Result`, `.Wait()`, `.GetAwaiter().GetResult()`) запрещён.
- EF Core: `AsNoTracking()` для чтения, проекции (`Select`), никакого N+1, батчинг, `AsSplitQuery` где нужно.
- Dapper — сырые горячие запросы; пул соединений, таймауты, `CancellationToken`.

**Состояние и кэш:**
- `IMemoryCache` — локальный, `IDistributedCache` (Redis) — распределённый.
- Идемпотентность записи (ключи идемпотентности), transactional outbox для надёжной доставки сообщений.

## 1.3 Форматирование и линтинг

- `.editorconfig` в корне репозитория (строгие правила); `dotnet format` в CI (`--verify-no-changes`).
- Анализаторы: `Microsoft.CodeAnalysis.NetAnalyzers` (все правила → warning), `SonarAnalyzer.CSharp`,
  `Meziantou.Analyzer`.
- `TreatWarningsAsErrors` в CI.
- Максимальная длина строки — **120** символов.
- Format on Save включён в IDE.

Требуемые пакеты (пример):
```xml
<PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="*" PrivateAssets="all" />
<PackageReference Include="SonarAnalyzer.CSharp" Version="*" PrivateAssets="all" />
<PackageReference Include="Meziantou.Analyzer" Version="*" PrivateAssets="all" />
```

## 1.4 Стиль оформления (Allman, отступы, using, var, комментарии)

Эти правила закреплены в корневом [`.editorconfig`](../../.editorconfig) (основа — `.editorconfig` из dotnet/runtime)
и автоматически проверяются `dotnet format`.

- **Скобки (Allman):** открывающая `{` — на новой строке (`if/for/while/foreach/using/try`, методы, типы).
- **Отступы:** 4 пробела, без табов. XML/JSON/YAML/проектные файлы — 2 пробела.
- **Строки:** перевод строки в конце файла; без хвостовых пробелов; не более одной пустой строки подряд; без «случайных» пробелов.
- **Модификаторы доступа:** указываем всегда явно; видимость — первым модификатором (`public abstract`, не `abstract public`).
- **`this.`** — не используем, кроме случаев крайней необходимости.
- **`using`-директивы:** вне `namespace`, отсортированы по алфавиту, `System.*` — сверху; namespace — file-scoped.
- **`var`** — только когда тип явно назван справа (`new`, cast): `var s = new FileStream(...)`, но не `var s = OpenStream()`.
  Target-typed `new()` — только когда тип назван слева.
- **Ключевые слова вместо BCL-типов:** `int`, `string`, `float` (и `int.Parse`, не `Int32.Parse`).
- **Константы и локальные функции** — `PascalCase`.
- **`nameof(...)`** вместо строковых литералов с именами членов.
- **Поля** — в начале объявления типа; `static readonly` (не `readonly static`).
- **Primary constructor:** параметры — `camelCase` без `_`; если тип крупный, присваиваем их `_`-полям.
- **Метки (`goto`)** — с отступом на один меньше текущего.
- **Не-ASCII** в исходниках — через `\uXXXX`, а не литералом.
- **XML-документация** обязательна для публичных API (с `<example>`/`<code>` где уместно) — см. [`04-documentation.md`](./04-documentation.md).

## 1.5 Nullable и современный C#

- Включаем `<Nullable>enable</Nullable>`; объявляем переменные non-nullable; проверяем `null` на границах (входные параметры API, внешние данные).
- Проверки на null — только `is null` / `is not null`, **никогда** `== null` / `!= null`.
- Доверяем аннотациям: не добавляем проверки там, где тип гарантированно не-null.
- Pattern matching и `switch`-выражения предпочтительнее ручных проверок и приведений типов.
- `record`/`record struct` — для неизменяемых данных; `readonly struct` — для горячих значений.
- `nameof` и `throw`-выражения вместо ручных проверок и строковых констант.
