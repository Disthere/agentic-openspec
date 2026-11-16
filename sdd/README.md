# `sdd/` — весь Spec-Driven Development одной папкой

Эта папка — **всё, что относится к OpenSpec и SDD**. Её можно перенести в проект целиком,
одной операцией.

## Что здесь

| Путь | Что внутри |
| - | - |
| [`openspec/`](./openspec) | конституция, стандарты 01–12, предложения, схемы валидации, живые спецификации |
| [`tools/`](./tools) | машинные гейты: `validate-proposals.ps1`, `check-canon-parity.ps1`, `check-template-clean.ps1`, `check-coverage.ps1`, `register-inputs.ps1`, `collect-metrics.ps1` |
| [`dsh/`](./dsh) | пресет `sdd` для DeepSeek Harness + `install.ps1` |
| [`inputs/`](./inputs) | материалы заказчика (ТЗ, концепции, макеты) + реестр `IN-NNN` |
| [`docs/`](./docs) | инструкция развёртывания, обзор модели, протокол аудита, чек-лист очистки, шаблоны, замороженная история набора |
| [`STATUS.md`](./STATUS.md) | где мы сейчас: активные предложения, фазы, блокеры |
| [`DECISIONS.md`](./DECISIONS.md) | журнал решений (`D-NNN`) |
| [`OPEN_QUESTIONS.md`](./OPEN_QUESTIONS.md) | открытые вопросы (`OQ-N`) |
| [`CHANGELOG.md`](./CHANGELOG.md) | история изменений |
| [`METRICS.md`](./METRICS.md) | метрики процесса (генерируется) |

## Чего здесь НЕТ — и почему

Часть файлов физически не может покинуть корень проекта: их ищут инструменты, и только там.

| Файл / каталог | Кто ищет и где |
| - | - |
| `AGENTS.md` | агентные инструменты читают его как инструкции проекта |
| `.clinerules` | Cline читает только в корне |
| `.agents/skills/` | DSH сканирует `<корень проекта>/.agents/skills` (корень = ближайший предок с `.git`) |
| `global.json`, `Directory.Build.props`, `Directory.Packages.props` | MSBuild поднимается вверх от проекта. **Эти файлы нужны только если ваш продукт на .NET** — в проекте на другом стеке их можно не копировать |
| `.editorconfig`, `.gitattributes` | редакторы и `git` |
| `.github/workflows/` | GitHub Actions |

Полная раскладка с обоснованием — [`AGENTS.md`](../AGENTS.md) §4.

## Как перенести в проект

1. Скопируйте папку `sdd/` в корень проекта.
2. Скопируйте из корня набора то, что требует ваш стек: минимум — `AGENTS.md`, `.clinerules`
   и `.agents/` (иначе агент не получит правила и скиллы). Для .NET-проекта добавьте
   `global.json`, `Directory.Build.props`, `Directory.Packages.props`, `.editorconfig`.
3. Прогоните чек-лист [`docs/CLEANUP.md`](./docs/CLEANUP.md) — он убирает историю набора и
   заменяет реестры шаблонами.
4. Проверьте гейты:

```powershell
.\sdd\tools\validate-proposals.ps1 -All -CheckLinks
.\sdd\tools\check-canon-parity.ps1
.\sdd\tools\check-template-clean.ps1
```

> Если Windows блокирует скрипты (`is not digitally signed`), запускайте через
> `powershell -NoProfile -ExecutionPolicy Bypass -File .\sdd\tools\...` — это ограничение
> машины, а не набора.

Пошагово, с промптами для сессии — [`docs/ADOPTION.md`](./docs/ADOPTION.md).
