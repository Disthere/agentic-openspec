<!--
  Пометка лицензии и происхождения. Файл ОБЯЗАТЕЛЕН при распространении набора:
  он сохраняется, даже если вы заменяете LICENSE на свою (см. sdd/docs/ADOPTION.md).
-->

# Сторонние материалы и лицензии

Набор `agentic-openspec` распространяется под лицензией, указанной в [`LICENSE`](./LICENSE).
Ниже — материалы третьих лиц, которые использованы внутри набора, с указанием лицензии и роли.

## Компоненты

| Материал | Где в наборе | Лицензия | Что сделано |
| - | - | - | - |
| **OpenSpec** (спецификационный формат: `proposal`/`specs`, `ADDED/MODIFIED Requirements`, `WHEN/THEN`) | структура `sdd/openspec/`, схемы, шаблоны предложений | **MIT** | Идея формата и конвенции ключевых слов; текст лицензии — ниже |
| ~~Wikipedia:Signs of AI writing~~ | — | — | **Удалено** вместе со скиллом `ai-writing-tells` (решение набора, [`DECISIONS-FROZEN.md`](./sdd/docs/legacy/DECISIONS-FROZEN.md)). Обязательств по CC BY-SA больше нет |

> **Важно:** материалы из Wikipedia **удалены из набора** вместе со скиллом `ai-writing-tells`
> (решение набора, [`DECISIONS-FROZEN.md`](./sdd/docs/legacy/DECISIONS-FROZEN.md)). Файлов, к которым
> относилось бы условие «share-alike» CC BY-SA 4.0, в наборе **нет**, поэтому обязательств по
> CC BY-SA у получателя набора не возникает. Если вы вернёте такие материалы — обязательство
> вернётся вместе с ними: указывайте ссылку на страницу и дату снимка в самих файлах.

## Лицензия OpenSpec (MIT)

```text
MIT License

Copyright (c) OpenSpec contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Что делать при развёртывании

1. **`LICENSE`** — замените на лицензию своего проекта.
2. **`THIRD-PARTY.md`** — **сохраните**: обязательство перед OpenSpec (**MIT**) остаётся, пока
   используются конвенции формата (ключевые слова `ADDED`/`REQUIREMENT`/`WHEN`/`THEN`, структура
   `proposal`/`specs`). Обязательств по CC BY-SA набор больше не несёт — материалы Wikipedia удалены.
3. Действий по Wikipedia не требуется: скилл `.agents/skills/ai-writing-tells/` и его материалы
   уже удалены (см. [`sdd/docs/CLEANUP.md`](./sdd/docs/CLEANUP.md)).
