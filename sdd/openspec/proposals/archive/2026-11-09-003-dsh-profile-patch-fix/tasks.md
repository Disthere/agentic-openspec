# Tasks — 003-dsh-profile-patch-fix

> Каждая задача трассируется к требованию (`R1`..`R6`) из [`proposal.md`](./proposal.md).

## 1. Профиль

- [x] 1.1 Переписать `dsh/profile/cordis.patch.yml`: существующие id — только override, новые шесть пресетов — через `- insert:`. (R1, R2)
- [x] 1.2 Пресеты: `config.id`, `name`, `description`, `order`, `plugins` с `dsh-persona` (prefix); персона — только внутри пресета. (R3)
- [x] 1.3 Единый блок привязки модели, помеченный как заменяемый; без выдуманного провайдера до решения `OQ-2`. (R4)
- [x] 1.4 Закрепить модель: провайдер `routerai` + `deepseek/deepseek-v4.1-flash` на все шесть ролей (решение владельца, `OQ-2` → `D-007`). (R4)

## 2. Установщик и документация

- [x] 2.1 `dsh/install.ps1`: ASCII-безопасный текст, запуск в Windows PowerShell 5.1, печать реальной команды проверки. (R5)
- [x] 2.2 `dsh/README.md`: путь к CLI внутри установленного приложения, ограничение `desktop` (Electron), семантика override/insert, приёмка `--dump-config`. (R6)

## 3. Проверка и фиксация

- [x] 3.1 Прогон `dsh --profile agentic-openspec --dump-config`: успех, шесть пресетов, один реестр. (R1..R4)
- [x] 3.2 `acceptance.md`: матрица `R1`..`R6`, непроверенное отмечено явно. (R1..R6)
- [x] 3.3 `CHANGELOG.md`, `docs/SESSION-START.md`, `OPEN_QUESTIONS.md` (данные по `OQ-2`). (R6)
- [x] 3.4 Дельта спецификации `specs/dsh-profile/spec.md` с требованиями `R1`..`R6`. (R1..R6)
- [x] 3.5 Закрыть `OQ-2`: запись `D-007` в `DECISIONS.md` и перенос в «Закрытые» в `OPEN_QUESTIONS.md`. (R4)
