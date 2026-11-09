# Каталог признаков AI-текста

Источник: [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing),
снимок 09.11.2026 (raw-wikitext, полный список разделов).
Страница — **описательная**: это наблюдения, а не правила и не доказательство. Многие признаки
встречаются у людей; сила — в **кластерах** и в **сильных артефактах**, а не в отдельных словах.

> Веса ниже: **S** = сильный признак (почти не встречается случайно), **M** = средний
> (подозрительно в кластере), **W** = слабый (только вместе с другими).
> «Words» — маркеры, которые страница перечисляет как характерные.

---

## 0. Оговорки самой страницы (не пропускать)

- AI-детекторы (GPTZero, Pangram и др.) ошибаются; высокий процент детектора — не основание
  для удаления/обвинения.
- Люди плохо различают AI и человека: исследования 2025 г. дают результат на уровне случайного
  угадывания у неопытных, ~57/64% у людей в одном исследовании и ~90% у подмножества экспертов
  (при 3,3% ложных срабатываний).
- Человеческая речь и письмо сами дрейфуют под влиянием LLM; вывод «это AI» по стилю — вероятностный.
- Признаки меняются со временем: у GPT-4, GPT-4o, GPT-5, GPT-6 разные словари и манера.

---

## 1. Content — содержание

### 1.1 Undue emphasis on significance, legacy, and broader trends — **S/M**
Раздувание значимости: произвольные детали объявляются «поворотным моментом», «частью более
широкого движения», «символом эпохи». Для тривиальных тем (этимология, население) — тоже.
**Words:** `stands/serves as`, `is a testament/reminder`, `a crucial/pivotal/vital/significant/key
role/moment`, `underscores/highlights its importance/significance`, `reflects broader`,
`symbolizing its ongoing/enduring/lasting`, `contributing to the`, `setting the stage for`,
`marking/shaping the`, `represents/marks a shift`, `key turning point`, `evolving landscape`,
`focal point`, `indelible mark`, `deeply rooted`, `distinction matters because...`
- Проявления: «помещается в широкие дебаты», «участвует в публичных обсуждениях»,
  «поднимает философские вопросы»; биология — натянутые связи с «экосистемой» и «сохранением вида».

### 1.2 Canned emphasis on notability, attribution, and media coverage — **S/M**
Доказывание значимости через перечисление типов источников, а не через факты.
**Words:** `independent coverage`, `local/regional/national/[country] media outlets`,
`music/business/tech outlets`, `trade publications`, `cited/featured/profiled in`,
`written by a leading expert`, `active social media presence`.
- «поддерживает активное присутствие в соцсетях», «освещалось в X, Y и других крупных СМИ»;
  собственные поверхностные выводы приписываются источнику.

### 1.3 Undue emphasis on identification by primary or tertiary sources — **M** (с 2026)
Переизбыток формул «источник идентифицирует субъекта как…».
**Words:** `Databases/records/listings/filings/materials identify/list/describe [subject] as...`,
`was identified by [source] as [fact]...`, `is listed in`, `his/her professional profile lists`.

### 1.4 Superficial analyses — **S/M**
Навешивание «-ing»-анализов в конце предложений: «подчёркивая важность…», «отражая…»,
«способствуя…», часто с размытой атрибуцией.
**Words:** `highlighting/underscoring/emphasizing ...`, `ensuring ...`, `reflecting/symbolizing ...`,
`contributing to ...`, `cultivating/fostering ...`, `encompassing ...`, `enhancing ...`,
`valuable insights`, `align/resonate with`.

### 1.5 Vague expression of connection or association — **M**
Вместо прямого факта — размытая связь.
**Words:** `in connection with/to ...`, `connected with/to`, `in association with ...`, `associated with`.
- «источники идентифицировали X как связанного с руководством Y» вместо «X был CEO Y».

### 1.6 Vague attributions and overgeneralization of opinions — **M**
**Words:** `Industry reports`, `Observers have cited`, `Experts argue`, `Some critics argue`,
`several sources/publications` (когда источников мало), `such as` перед исчерпывающими списками.

### 1.7 Outline-like conclusions about challenges and future prospects — **M**
Шаблонные финалы «вызовы и перспективы».
**Words:** `Despite its... faces several challenges...`, `Despite these challenges`,
`Challenges and Legacy`, `Future Outlook`.

### 1.8 «Awards and recognition» section — **M**
Отдельный раздел «Награды и признание» (или просто «Recognition»), заголовки «X and Y» —
следствие культа значимости и размытых «признаний».

---

## 2. Language and grammar — язык и грамматика

### 2.1 High density of «AI vocabulary» words — **S (в кластере)**
Одно-два слова — совпадение; много и часто — один из сильнейших признаков (после 2022).
**Words (базовый список):** `Additionally` (в начале предложения), `align with`, `boasts`
(в значении «has»), `bolstered`, `crucial`, `deep dive`, `delve`, `emphasizing`, `enduring`,
`enhance`, `fostering`, `garner`, `highlight` (глагол), `interplay`, `intricate/intricacies`,
`landscape` (абстрактно), `meticulous/meticulously`, `pivotal`, `robust`, `showcase`,
`tapestry` (абстрактно), `testament`, `underscore` (глагол), `valuable`, `vibrant`.
- **Эпохи (примерно):**
  - 2023–сер. 2024 (GPT-4): Additionally, boasts, bolstered, crucial, delve, emphasizing, enduring,
    garner, intricate, interplay, key, landscape, meticulously, pivotal, underscore, tapestry,
    testament, valuable, vibrant.
  - сер. 2024–сер. 2025 (GPT-4o): align with, bolstered, crucial, emphasizing, enhance, enduring,
    fostering, highlighting, pivotal, showcasing, underscore, vibrant.
  - сер. 2025–сер. 2026 (GPT-5): emphasizing, enhance, highlighting, showcasing + лексика
    «notability/attribution/media coverage».
  - сер. 2026+ (GPT-6): challenge, clearer, dependable, echoed, foster, leverage, matters,
    multifaceted, practical, prioritize, quietly, steady, universally; короткие предложения 8–20 слов,
    много точек и запятых.
- Grok отдельно: causal, empirical, correlate, underscore.
- Важно: переизбыток **конкретных** слов, а не их синонимов; учитывать контекст (underscore как
  подчёркивание/музыка).

### 2.2 Avoidance of basic copulatives («is»/«are») — **M**
Замена простого «is/are» на «serves as», «stands as», «marks», «functions as», «operates as»,
«represents a»; «has» → «boasts/features/maintains/offers».
**Words:** `serves as/stands as/marks/functions as/operates as/represents [a]`,
`boasts/features/maintains/offers [a]`, `refers to`.
- Иногда сложнее: «ventured into politics as a candidate» вместо «was a candidate».

### 2.3 Negative parallelisms — **M**
1) **Not just X, but also Y** — `Not only ... but ...`, `It is not just ..., it's ...`;
2) **Not X, but Y** — `It's not ..., it's ...`, `no ..., no ..., just ...`;
3) **Y rather than X** — особенно часто в свежем выводе (2026).

### 2.4 Leads treating lists/broad titles as proper nouns — **M**
«Catchment area (health) refers to…», «The “List of songs about Mexico” is a curated compilation…»
— заголовок подаётся как сущность.

### 2.5 Rule of three — **M/W**
«adjective, adjective, adjective», «short phrase, short phrase, and short phrase» — ради видимости
полноты.

---

## 3. Style — стиль (сводка страницы)

- **Title Case** в заголовках вместо sentence case.
- **Overuse of boldface** в прозе; попытки жирного через `*asterisks*` (не срабатывают).
- **Inline-header vertical lists**: списки, где каждый пункт — «**Термин**: объяснение».
- **Неправильные уровни заголовков**: H1 с названием статьи, несколько H1.
- **Эмодзи** в начале заголовков/пунктов списка.
- **Кривые кавычки и апострофы** (“ ” ’) вместо прямых (для EN; в RU «ёлочки» — норма).

---

## 4. Communication intended for the user — коммуникация с пользователем

### 4.1 Collaborative communication — **S (если осталось в тексте)**
Ответы, адресованные пользователю, попали в контент.
**Words:** `a Wikipedia-style article`, `I hope this helps`, `Of course!`, `Certainly!`,
`You're absolutely right!`, `Would you like...`, `is there anything else`, `let me know`,
`more detailed breakdown`, `here is a ...`, `[check/verify/confirm]... before [publishing]`.
- Метакомментарии в тексте, инструкции «удалите этот раздел перед отправкой», «в этом разделе
  мы обсудим…», «цель — дать полное понимание…».

### 4.2 Hedging disclaimers about source availability and recommended usage — **M/S**
- 2023–24 (дидактические): «важно отметить», «следует помнить», «критически важно различать».
- 2024–25 (RAG): «не широко задокументировано», «информации мало в доступных источниках»,
  «на основе доступной информации», «поддерживает низкий профиль / не раскрывает детали».
- Сер. 2026+: «следует рассматривать как X, а не Y» (negative parallelism), «не устанавливает,
  что…», «не путать с…» (менее надёжно).
**Words:** `While specific details are limited/scarce...`, `not widely available/documented/disclosed`,
`...in the provided/available sources / search results...`, `[claim] should be [treated/presented] as...
rather than...`, `based on available information`, `...does not by itself establish...`.

### 4.3 Phrasal templates and placeholder text — **S**
- Мад-либы: `[Describe the specific section...]`, `[Your Name]`, `[link to the revised article]`,
  `[fun fact related to...]`, `[Entertainer's Name]`, `(Add your channel URL here)`.
- **Даты-плейсхолдеры:** `2025-XX-XX`, `20XX`; `access-date=2025-XX-XX`.
- **URL-плейсхолдеры:** `INSERT_SOURCE_URL_30`, `INSERT_WEBSITE_URL_HERE`, `SOURCE_PUBLISHER`.
- Комментарии в инфобоксах «Add if available with citation», «Add spouse if reliably sourced»
  (проверять, не шаблон ли это).
- Незаполненные блоки «Evidence to be supplied: [Diffs...]».

---

## 5. Markup irregularities — разметка (сильный, почти однозначный)

- **Markdown** в тексте: `**bold**`, `#` для заголовков, `---`/`----` разделители,
  ссылки `[url](text)`, код-блоки ``` ``` ``` (часто с «wikitext»).
- **Внутренние структуры цитат**: `contentReference[oaicite:1]`, аналогичные артефакты чат-ботов.
- **Несуществующие категории/шаблоны**, битые трансклюзии.

---

## 6. Citations — ссылки и цитаты

- **Битые внешние ссылки** пачкой (и нет архивных копий) — сильный признак.
- **Невалидные DOI/ISBN** (проверка контрольной суммы) — вероятная галлюцинация.
- **DOI ведут не к тем статьям** (ссылка валидна, статья не та / авторы не те).
- **Книги без страниц/URL** или страницы не подтверждают текст.
- **Некорректное переиспользование ссылок**, символ `↩` вокруг сносок, «сноски» в стиле чата.
- **UTM-маркеры**: `utm_source=openai`, `utm_source=chatgpt.com`, `utm_source=copilot.com`,
  `referrer=grok.com`.
- **Named refs объявлены, но не использованы** (и наоборот).
- **Ссылки на поиск** (`links to searches`) в тексте.

---

## 7. Comment-specific indicators — комментарии/обсуждения

- Неверные цитаты правил, выдуманные сокращения (`WP:XYZ`), ссылки на «политику» без страницы.
- Длинные комментарии, разбитые на разделы с заголовками (Markdown/plain/H2–H3).
- Трансклюзия служебных шаблонов/баннеров при упоминании.
- Преуменьшение использования LLM: «я вложил человеческий труд», «это мои мысли».
- Просьбы к критикам указать, «что именно улучшить», «давайте сосредоточимся на содержании».
- Отрицание критики как «недоказанных спекуляций» вместо конкретики.
- Тон клерка/клиентского сервиса: «I understand your concerns», «I hope this message finds you
  well», «Dear Wikipedia Editorial Team», извинения «за возможные неудобства», обещания «исправить».

---

## 8. Edit summaries — описания правок (для вики/PR)

- **Канцелярские заверения о соответствии**: `ensured that... adheres to`, `refined`, `enhanced`,
  `streamlined`, `in compliance/complies with`, `Wikipedia guidelines/style/standards`, `revised`,
  `verifiability`, `neutrality`, `neutral tone`, `encyclopedic tone`, `clarity`, `flow`.
- **«Сохранено/не тронуто/избежал»**: `preserved/preserving`, `retained/retaining`,
  `avoided/avoiding`, `ensured/ensuring`, `aimed/aiming to` — упоминание того, что не менялось.
- **Акцент на наличии источников**: `added sourced [content]`, `added verified [content]`,
  `added coverage/citations/references`, `improved attribution`,
  `with independent/secondary/third-party/peer-reviewed sources`.
- **Перечисление имён параметров/шаблонов** с разметкой (`infobox parameters (image_size)`).
- **«Учёл замечания ревьюера»** (`Addressing reviewer feedback`) — очевидное, чего человек не пишет.
- **Преамбула чат-бота** в описании (`ChatGPT responded:`, `Claude responded:`).
- Старые: first-person + AI-лексика + эмодзи + попытки markdown.

---

## 9. Miscellaneous — прочее

- **Резкая смена стиля** у автора (внезапно идеальная грамматика/иной регистр); при этом стиль
  может меняться синхронно с эпохами LLM (2023 → 2025 → 2026).
- **«Submission statements»** в черновиках: обращение к ревьюеру с объяснением значимости.
- **Предустановленные maintenance-шаблоны**: черновик уже помечен «declined» без причины.
- **Канцелярские user pages**: «Welcome To My User Page!», «About Me», «My Interests»,
  «Let's Connect!», эмодзи, markdown-жирный.
- **Permissions gaming**: масса безобидных AI-правок ради прав; признак работает только в одну
  сторону — сам по себе быстрый набор текста не доказывает gaming.
- **Различия LLM**: у каждого чат-бота свой идиолект (GPT-5 ≠ GPT-4 ≠ Gemini/Claude;
  ChatGPT/Grok любят «широкий контекст», Gemini/Claude лаконичнее).
- **Смещения**: прозападный уклон, проавторитарный уклон (2026), галлюцинации на редких языках.

---

## 10. Historical indicators — исторические (для старых текстов)

1. **Промо-язык 2023–2025** — **M (истор.)**: `boasts a`, `vibrant`, `rich`, `profound`,
   `enhancing`, `showcasing`, `exemplifies`, `commitment to`, `natural beauty`, `nestled`,
   `in the heart of`, `groundbreaking`, `renowned`, `featuring`, `diverse array`.
2. **Заявления о knowledge cutoff (2022–23)** — `Up to my last training update`,
   `as of my last knowledge update...`.
3. **Section summaries** — `In summary`, `In conclusion`, `Overall` в конце разделов/абзацев.
4. **Prompt refusal** — `as an AI language model`, `as a large language model`,
   `I cannot offer medical advice, but I can...`, `I'm sorry`.
5. **Overuse of em dashes (2022–09.2026)** — длинное тире с пробелами, формульно, вместо запятых/
   скобок. В 2025–26 модели стали подавлять — и появился обратный признак: слишком мало пунктуации,
   короткие предложения. **Для русского это не признак** (длинное тире — норма).
6. **Abrupt cut offs** — текст обрывается на полуслове (лимит токенов, «continue generating»).
7. **Устаревшие access-date** — дата доступа заметно старше даты правки.
8. **Lexical diversity / elegant variation** — навязчивая замена повторов синонимами
   (repetition penalty).

---

## 11. Signs of human writing — обратные признаки

- **Текст старше 30.11.2022** — AI исключён (для соответствующего фрагмента).
- **Автор может объяснить свои правки** и ошибки, показать источник/пассаж.
- **Синтаксис**: простые `is/has` («there is a», «it has a»), простые слова (`wrote`, `moved`,
  `used`, `tried`, `died` вместо `authored`, `relocated`, `utilized`, `attempted`, `passed away`),
  суперлативы/определённость, квалификаторы (`very`, `perhaps`, `tends to`), «водянистые»
  конструкции (`as a result of`, `in order to`, `all of the`, `a part of`, `the fact that`).

---

## 12. Ineffective indicators — НЕ использовать как доказательство

- Идеальная грамматика.
- Смешение регистров / «клинично и эмоционально» одновременно.
- «Роботизированная»/«скучная» проза.
- «Fancy»/академический стиль.
- Переходные слова по отдельности (Additionally, Consequently, Notably).
- Отсутствие источников.
- Странная разметка (случайные `<span>` — чаще баг редактора/расширения).
- Корректная разметка (человек мог пользоваться визуальным редактором/превью).

---

## 13. Русская адаптация

- **Не признаки**: длинное тире, «ёлочки», «является», «осуществляет», «в рамках», «в условиях»,
  канцелярит как таковой.
- **Русские AI-маркеры (плотность + кластер):** «играет важную роль», «является свидетельством»,
  «в современном мире», «не только… но и», «подчёркивает», «ключевой», «динамично развивающийся»,
  «многообразие», «важно отметить», «стоит отметить», «в заключение», «данный», «позволяет»,
  «обеспечивает», «способствует», «формирует», «представляет собой», «в совокупности»,
  «на сегодняшний день», «вызовы и перспективы», «несмотря на вызовы», «более широкий контекст»,
  «символ эпохи», «оставляет неизгладимый след».
- **Структурные**: CPU-списки с «**Термин**: …», шаблонные финалы, лид-определение, «В этой статье
  мы рассмотрим», метакомментарии, плейсхолдеры.
- **Английские маркеры в русском тексте** (если перевод): кальки `delving`, `tapestry` → «гобелен»,
  «углубиться», «многообразие».

---

## 14. Шпаргалка по весам

| Уровень | Примеры | Как трактовать |
|---|---|---|
| **S** | Markdown-артефакты, плейсхолдеры (`INSERT_`, `[Your Name]`, `2025-XX-XX`), `utm_source=chatgpt.com`, `contentReference[oaicite:…]`, «as an AI language model», пачка битых/выдуманных ссылок, `↩` | почти однозначно AI-артефакт → проверять факты |
| **M** | AI-лексика в кластере, significance-фразы, «serves as», negative parallelism, hedging disclaimers, collaborative-фразы, edit-summary-формулы | подозрительно в кластере; нужен контекст |
| **W** | «Additionally» в начале, правило трёх, Transition-слова, кривые кавычки (EN), 1–2 AI-слова | только вместе с другими |
| **Обратные** | простые «is/has», разговорные слова, суперлативы, объяснимые ошибки, текст до 30.11.2022 | снижают вероятность AI |

**Практическое правило:** S — достаточно для вывода «AI-артефакт»; M — нужно ≥4–5 из разных
категорий в одном фрагменте; W — игнорировать поодиночке.

---

## 15. Источник и версия

- Страница: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing
- Снимок: 09.11.2026 (полный список — 77 секций, использованы разделы 1–72).
- Дополнительные подстраницы (для углубления): `/Style`, `/Markup`, `/Examples/...`,
  «Signs of AI use in comments».
- Статус: страница — «WikiProject advice», не правило; список **дескриптивный**.
