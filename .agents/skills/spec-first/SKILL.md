---
name: spec-first
description: Превращает сырой запрос на фичу в проверяемое предложение OpenSpec в openspec/proposals/. Создаёт proposal.md, tasks.md, при необходимости design.md и дельты спецификаций, не написав ни строки реализационного кода. Применяй до написания любого кода.
argument-hint: запрос на фичу или описание изменения
---

# Скилл: spec-first

Ты выполняешь скилл **spec-first**. Его задача — превратить запрос в спецификацию, а не в код.

## Предусловия

- Существует `openspec/proposals/000-template.md`.
- Ты прочитал `openspec/project.md` и просмотрел `openspec/specs/`.

## Шаги

1. **Explore (разведка)** — прочитай `openspec/specs/` и пути кода, которых касается изменение. Опиши текущее поведение.
2. **Clarify (уточнение)** — вынеси неизвестное в раздел **Open Questions** с рекомендуемым значением по умолчанию.
   Спрашивай пользователя только если блокирующее решение нельзя задать по умолчанию.
3. **Scaffold (скаффолдинг)** — выбери следующий `<NNN>` (с ведущими нулями) и создай `openspec/proposals/<NNN>-<slug>/`.
4. **Write artifacts (артефакты)** на основе `000-template.md`:
   - `proposal.md` — Context, Requirements (с `### Requirement:` + `#### Scenario:` `WHEN`/`THEN`),
     C# Implementation Plan, API/Contract Changes, Test Strategy, Capabilities, Impact, Open Questions.
   - `tasks.md` — пронумерованный чек-лист `- [ ]`.
   - `design.md` — только если дизайн нетривиален (добавь диаграммы C4/sequence в Mermaid).
   - `specs/<capability>/spec.md` — дельты требований ADDED/MODIFIED.
5. **Validate (валидация)** — сверь с `openspec/schemas/csharp-api.yaml` (обязательные разделы на месте,
   у каждого требования ≥ 1 сценарий).
6. **Report (отчёт)** Оркестратору: путь к предложению, список возможностей (capabilities), открытые вопросы,
   «утвердить / нужно уточнение».

## Ограничения

- Никаких правок `.cs`/`.csproj` — если тянет реализовать, напиши вместо этого задачу.
- Помечай шапку предложения `Status: Draft`, пока человек его не утвердит.
