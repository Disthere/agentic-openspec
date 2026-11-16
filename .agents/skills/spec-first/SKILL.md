---
name: spec-first
description: Превращает сырой запрос на фичу в проверяемое предложение OpenSpec в sdd/openspec/proposals/. Создаёт proposal.md, tasks.md, при необходимости design.md и дельты спецификаций, не написав ни строки реализационного кода. Применяй до написания любого кода.
---

# Скилл: spec-first

Ты выполняешь скилл **spec-first**. Его задача — превратить запрос в спецификацию, а не в код.

## Предусловия

- Существует `sdd/openspec/proposals/000-template.md`.
- Ты прочитал `sdd/openspec/project.md` и просмотрел `sdd/openspec/specs/`.

## Шаги

1. **Explore (разведка)** — прочитай `sdd/openspec/specs/` и пути кода, которых касается изменение. Опиши текущее поведение.
2. **Clarify (уточнение)** — вынеси неизвестное в раздел **Open Questions** с рекомендуемым значением по умолчанию.
   Спрашивай пользователя только если блокирующее решение нельзя задать по умолчанию.
3. **Scaffold (скаффолдинг)** — выбери следующий `<NNN>` (с ведущими нулями) и создай `sdd/openspec/proposals/<NNN>-<slug>/`.
4. **Write artifacts (артефакты)** на основе `000-template.md`:
   - `proposal.md` — Context, Requirements (с `### Requirement:` + `#### Scenario:` `WHEN`/`THEN`),
     C# Implementation Plan, API/Contract Changes, Test Strategy, Capabilities, Impact, Changelog.
     (`Changelog` обязателен: валидатор `V1` требует его как раздел — без него предложение
     не проходит гейт. `Open Questions` — по необходимости, гейт его не требует.)
   - `tasks.md` — пронумерованный чек-лист `- [ ]`.
   - `design.md` — только если дизайн нетривиален (добавь диаграммы C4/sequence в Mermaid).
   - `specs/<capability>/spec.md` — дельты требований ADDED/MODIFIED.
5. **Validate (валидация)** — сверь со схемой **активного профиля**: `sdd/openspec/config.yaml` →
   `project.profile` (значение `csharp-api` или `csharp-desktop`) → `sdd/openspec/schemas/<profile>.yaml`.
   Не подставляй `csharp-api` жёстко: у десктопного профиля свой набор стандартов (P1-17).
   Обязательные разделы на месте, у каждого требования ≥ 1 сценарий. Машинная проверка —
   `sdd/tools/validate-proposals.ps1 -Path <предложение>` (не «на глаз»).
6. **Report (отчёт)** Оркестратору: путь к предложению, список возможностей (capabilities), открытые вопросы,
   «утвердить / нужно уточнение».

## Ограничения

- Никаких правок `.cs`/`.csproj` — если тянет реализовать, напиши вместо этого задачу.
- Помечай шапку предложения `Status: Draft`, пока человек его не утвердит.
