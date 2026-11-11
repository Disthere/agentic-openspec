# CLEANUP — что срезать при развёртывании набора

**Назначение:** чек-лист для проекта, который берёт `agentic-openspec` как шаблон. Прохождение —
**не более 10 минут**. После него в репозитории не остаётся истории набора, чужих примеров и
«активной» документации, которая к вашему продукту не относится.

> Правило: **ничего не удаляйте из `openspec/proposals/archive/`**, если хотите сохранить примеры
> реальных спецификаций. Перенос в архив — безопаснее удаления.

## 1. Лицензия и сторонние материалы (2 мин)

- [ ] [`LICENSE`](./LICENSE) — заменить на лицензию **своего** проекта.
- [ ] [`THIRD-PARTY.md`](./THIRD-PARTY.md) — **сохранить**. Обязательства по MIT (OpenSpec) остаются,
      пока конвенции формата используются.
- [ ] Если материалы Wikipedia не нужны — они уже удалены вместе со скиллом `ai-writing-tells` (D-06).

## 2. Реестры и журналы (2 мин)

- [ ] [`CHANGELOG.md`](./CHANGELOG.md) — заменить на [`docs/CHANGELOG-TEMPLATE.md`](./docs/CHANGELOG-TEMPLATE.md).
- [ ] [`OPEN_QUESTIONS.md`](./OPEN_QUESTIONS.md) — заменить на [`docs/OPEN_QUESTIONS-TEMPLATE.md`](./docs/OPEN_QUESTIONS-TEMPLATE.md).
- [ ] [`DECISIONS.md`](./DECISIONS.md) — заменить на [`docs/DECISIONS-TEMPLATE.md`](./docs/DECISIONS-TEMPLATE.md).
- [ ] [`docs/SESSION-START.md`](./docs/SESSION-START.md) — заменить на [`docs/SESSION-START-TEMPLATE.md`](./docs/SESSION-START-TEMPLATE.md)
      (или удалить `docs/session/`).

## 3. Предложения и спецификации (2 мин)

- [ ] Активные предложения `openspec/proposals/00[1-6]-*` — **уже перенесены** в `archive/` (батч 2)
      либо перенесите сами.
- [ ] Если примеры не нужны — удалить `openspec/proposals/archive/2026-11-*`.
- [ ] `openspec/specs/` — удалить `independent-review/`, `delivery-roles/`, `product-lifecycle/`
      (это спецификации **набора**, а не вашего продукта), оставив `README.md`.
- [ ] Освободить номер: первое предложение — **первый свободный** номер, не обязательно `001`
      (см. [`docs/ADOPTION.md`](./ADOPTION.md) §5).

## 4. Код (1 мин)

- [ ] `src/Smoke/` и `tests/Smoke.Tests/` — **оставить**: это доказательство, что шаблон собирается.
      Переименуйте под свой домен, когда появится первый настоящий сервис.
- [ ] `agentic-openspec.slnx` — переименовать под имя решения.

## 5. Документация набора (2 мин)

- [x] `docs/baseline/` — **уже перенесена** в `docs/legacy/set-history/baseline/`.
- [ ] `docs/legacy/` — оставить шаблоны, убрать примеры документов другого проекта.
- [ ] `README.md`, `AGENTS.md`, `.clinerules` — заменить название проекта и описание.
- [x] `PLAN.md`, `ASSESSMENT.md` — **уже перенесены** в `docs/legacy/set-history/`.

## 6. DSH-профиль (1 мин)

- [ ] `dsh/presets-bundle/cordis.patch.yml` — пресет `sdd` уже нейтрален по роли; поменяйте только
      модель и `description`, если нужно.
- [ ] Установить профиль: `powershell -ExecutionPolicy Bypass -File .\dsh\install.ps1`.
- [ ] Дефолтный пресет — `standard` (D-018); роль выбирается пресетом `sdd` в UI.

## 7. Проверка «шаблон чист»

После прохождения чек-листа выполните:

```powershell
# 1. Сборка и тесты
dotnet restore
dotnet build --configuration Release --no-restore
& .\artifacts\bin\Smoke.Tests\release\Smoke.Tests.exe

# 2. Совместимость машинных гейтов
.\tools\validate-proposals.ps1 -All -CheckLinks
.\tools\check-canon-parity.ps1

# 3. В шаблоне не осталось истории набора
.\tools\check-template-clean.ps1
```

Все четыре команды должны завершиться с кодом **0**.

## Что НЕ удалять никогда

| Путь | Почему |
| - | - |
| `AGENTS.md` | Канон правил — DSH читает его |
| `openspec/constitution.md` | Высший приоритет; гейты и фазы |
| `openspec/standards/` | Инженерные стандарты 01–12 |
| `.agents/*.md` | Шесть ролей цикла |
| `openspec/config.yaml` | Единственный источник команд гейта |
| `tools/validate-proposals.ps1` | Машинный гейт предложений |
| `Directory.Build.props` / `Directory.Packages.props` | Сборка и CPM |
| `global.json` | Пин SDK |
| `THIRD-PARTY.md` | Лицензионные обязательства |
