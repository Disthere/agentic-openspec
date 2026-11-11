<!--
  Пометка лицензии и происхождения. Файл ОБЯЗАТЕЛЕН при распространении набора:
  он сохраняется, даже если вы заменяете LICENSE на свою (см. docs/ADOPTION.md).
-->

# Сторонние материалы и лицензии

Набор `agentic-openspec` распространяется под лицензией, указанной в [`LICENSE`](./LICENSE).
Ниже — материалы третьих лиц, которые использованы внутри набора, с указанием лицензии и роли.

## Компоненты

| Материал | Где в наборе | Лицензия | Что сделано |
| - | - | - | - |
| **OpenSpec** (спецификационный формат: `proposal`/`specs`, `ADDED/MODIFIED Requirements`, `WHEN/THEN`) | структура `openspec/`, схемы, шаблоны предложений | **MIT** | Идея формата и конвенции ключевых слов; текст лицензии — ниже |
| ~~Wikipedia:Signs of AI writing~~ | — | — | **Удалено** вместе со скиллом `ai-writing-tells` (D-06). Обязательств по CC BY-SA больше нет |

> **Важно:** материалы из Wikipedia — производная работа под **CC BY-SA 4.0**. Если вы распространяете
> набор, условие «share-alike» относится к этим файлам. Источник и авторы указаны в самих файлах
> (ссылка на страницу и дата снимка). Удаление этих файлов снимает обязательство по CC BY-SA.

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
2. **`THIRD-PARTY.md`** — **сохраните**: обязательства перед OpenSpec (MIT) и Wikipedia (CC BY-SA)
   остаются, пока материалы остаются в наборе.
3. Если материалы Wikipedia вам не нужны — удалите `.agents/skills/ai-writing-tells/` целиком и
   строку про Wikipedia из этого файла (см. [`docs/CLEANUP.md`](./docs/CLEANUP.md)).
