# Tasks — 002-lifecycle-and-roles

> Каждая задача трассируется к требованию (`R1`..`R12`) из [`proposal.md`](./proposal.md).
> Отклонения фиксируются в [`acceptance.md`](./acceptance.md), а не «по факту».

## 1. Каркас фаз и среда

- [x] 1.1 `openspec/constitution.md`: раздел «Фазы жизненного цикла» (фаза → артефакт → гейт → владелец) + DSH в таблице канонических документов. (R1, R2, R11)
- [x] 1.2 `openspec/config.yaml`: блок `lifecycle` (фазы и гейты), `agents.orchestrator: dsh`, состав ролей и способ делегирования. (R1, R10, R11)

## 2. DoD и handoffs

- [x] 2.1 `05-definition-of-done.md`: §5.6 DoD дискавери, §5.7 DoD эксплуатации и поддержки. (R3, R5, R6, R8)
- [x] 2.2 `05-definition-of-done.md`: §5.2 — улики верификации производит не автор кода; §5.5 — применение новых ролей. (R4, R8, R9)
- [x] 2.3 `03-handoffs.md` §3.1: переходы Brief→Spec, Build→Verify, Verify→Release, Release→Ops, Ops→Spec с критериями приёмки. (R7)

## 3. Роли

- [x] 3.1 `.agents/analyst.md` — продуктовый аналитик: `inputs/` + `INDEX.md`, ценность и измеримый критерий успеха, Discovery gate. (R3, R9, R12)
- [x] 3.2 `.agents/qa-engineer.md` — инженер верификации: `acceptance.md`, `performance.md`, воспроизводимые улики, Verification gate. (R4, R9, R12)
- [x] 3.3 `.agents/ops-release.md` — Ops/Release: `docs/operations/*`, релизная часть `CHANGELOG.md`, rollback, Release и Support гейты. (R5, R6, R9, R12)
- [x] 3.4 `.agents/README.md`: таблица ролей (шесть), схема делегирования на субагентах DSH, правило допуска роли (артефакт + гейт). (R9, R11, R12)

## 4. Среда DSH

- [x] 4.1 `dsh/profile/cordis.patch.yml`: пресеты `analyst`, `qa-engineer`, `ops-release` (модель + короткая персона со ссылкой на файл роли). (R10)
- [x] 4.2 `dsh/README.md`: таблица ролей и пресетов (шесть), ожидание `--dump-config`, цикл по фазам жизненного цикла. (R1, R10, R11)

## 5. Гигиена ссылок на среду

- [x] 5.1 `AGENTS.md` и `.clinerules`: канон для DSH — `AGENTS.md`; делегирование — субагенты DSH (`agentPreset`); шесть ролей; `spawn_agent` как инструмент убрать. (R11)
- [x] 5.2 `README.md`, `.github/copilot-instructions.md`, `openspec/{project.md,constitution.md,README.md,proposals/README.md,standards/README.md}`: запуск и авторитет — через DSH, а не Cline CLI. (R11)

## 6. Фиксация

- [x] 6.1 `acceptance.md`: матрица `R1`..`R12`, непроверенные условия отмечены явно. (R1..R12)
- [x] 6.2 `CHANGELOG.md` под `[Unreleased]` + `docs/SESSION-START.md` (среда — DSH, роли, открытый `OQ-8`). (R11, R12)
