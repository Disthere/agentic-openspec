#!/usr/bin/env python3
"""Heuristic scanner for AI-writing tells (stdlib only).

Based on Wikipedia:Signs of AI writing (snapshot 09.11.2026).
This is NOT a detector: it flags suspicious patterns for human review.

Usage:
    python ai_tells_check.py FILE [--lang auto|en|ru] [--json] [--min-weight S|M|W]
    cat text.txt | python ai_tells_check.py - --lang ru

Exit codes: 0 = no strong artifacts, 1 = strong artifacts found (convenient for CI).
"""
from __future__ import annotations

import argparse
import bisect
import json
import re
import sys
from dataclasses import dataclass, field

S, M, W = "S", "M", "W"
WEIGHT_SCORE = {S: 5, M: 2, W: 1}
WEIGHT_CAP = {S: 2, M: 3, W: 2}

EN_AI_VOCAB = [
    "delve", "delving", "pivotal", "tapestry", "testament", "underscore", "underscores",
    "underscoring", "showcase", "showcases", "showcasing", "foster", "fostered", "fostering",
    "enhance", "enhanced", "enhancing", "robust", "landscape", "intricate", "intricacies",
    "meticulous", "meticulously", "bolster", "bolstered", "garner", "garnered", "interplay",
    "vibrant", "crucial", "align with", "boasts", "deep dive", "additionally", "multifaceted",
    "leverage", "prioritize", "showcases",
]
RU_AI_VOCAB = [
    "играет важную роль", "играет ключевую роль", "является свидетельством",
    "оставляет неизгладимый след", "символ эпохи", "в современном мире", "не только",
    "подчёркивает", "ключевой", "динамично развивающийся", "многообразие", "важно отметить",
    "стоит отметить", "в заключение", "представляет собой", "в совокупности",
    "на сегодняшний день", "вызовы и перспективы", "несмотря на вызовы", "более широкий контекст",
]

CHECKS: list[dict] = [
    # ---------------- STRONG artifacts ----------------
    dict(id="insert_url", cat="placeholders", w=S, langs="any",
         pat=r"INSERT_[A-Z0-9_]{2,}", desc="Плейсхолдер INSERT_... (URL/источник)"),
    dict(id="bracket_placeholder", cat="placeholders", w=S, langs="any",
         pat=r"\[(?:Your|Insert|Enter|Add|Fill|Describe|List|Your Name|Paste|Enter|Укажите|Вставьте|Ваш|Ваше|Введите|Опишите)[^\]]{0,70}\]",
         desc="Плейсхолдер в квадратных скобках"),
    dict(id="date_placeholder", cat="placeholders", w=S, langs="any",
         pat=r"\b20\d{2}-(?:XX|xx)-(?:XX|xx)\b", desc="Дата-плейсхолдер 20XX-XX-XX"),
    dict(id="utm_marker", cat="citations", w=S, langs="any",
         pat=r"(?:utm_source=(?:openai|chatgpt|copilot)|referrer=grok\.com)",
         desc="UTM/referrer маркер чат-бота в ссылке"),
    dict(id="oaicite", cat="markup", w=S, langs="any",
         pat=r"(?:contentReference\[oaicite:\d+\]|oaicite)", desc="Внутренний артефакт цитирования LLM"),
    dict(id="footnote_arrow", cat="citations", w=S, langs="any",
         pat=r"↩", desc="Символ возврата сноски (↩), типичный для чат-ботов"),
    dict(id="code_fence", cat="markup", w=S, langs="any",
         pat=r"```", desc="Markdown-код-блок (```)"),
    dict(id="md_heading", cat="markup", w=S, langs="any",
         pat=r"(?m)^#{1,6}\s+\S", desc="Markdown-заголовок (#)"),
    dict(id="md_bold", cat="markup", w=S, langs="any",
         pat=r"\*\*[^*\n]{1,80}\*\*", desc="Markdown-жирный (**...**)"),
    dict(id="md_hr", cat="markup", w=S, langs="any",
         pat=r"(?m)^-{3,}\s*$", desc="Markdown-разделитель (---)"),
    dict(id="md_link", cat="markup", w=S, langs="any",
         pat=r"\[[^\]]{1,80}\]\(https?://[^)\s]+\)", desc="Markdown-ссылка [текст](url)"),
    dict(id="ai_refusal", cat="communication", w=S, langs="any",
         pat=r"\b(?:as an AI language model|as a large language model|как языковая модель|как ИИ-модель)\b",
         desc="Отказ/самоописание модели"),
    dict(id="knowledge_cutoff", cat="historical", w=S, langs="any",
         pat=r"(?:as of my last (?:knowledge )?(?:update|training)|up to my last training update|на момент последнего обновления знаний|по состоянию на момент обучения)",
         desc="Заявление о knowledge cutoff"),

    # ---------------- MEDIUM patterns ----------------
    dict(id="ai_vocab_en", cat="language", w=M, langs="en",
         pat=r"\b(?:" + "|".join(re.escape(v) for v in EN_AI_VOCAB) + r")\b",
         desc="AI-лексика (EN), кластер слов"),
    dict(id="ai_vocab_ru", cat="language", w=M, langs="ru",
         pat=r"(?:" + "|".join(re.escape(v) for v in RU_AI_VOCAB) + r")",
         desc="AI-лексика/штампы (RU)"),
    dict(id="significance_en", cat="content", w=M, langs="en",
         pat=r"\b(?:stands? as a|serves? as a|is a testament|are a testament|pivotal (?:role|moment)|underscor(?:es|ing)|highlights? (?:the|its)|reflects? (?:a )?broader|indelible mark|key turning point|evolving landscape|deeply rooted|setting the stage for|marks? a shift)\b",
         desc="Раздувание значимости/наследия (EN)"),
    dict(id="significance_ru", cat="content", w=M, langs="ru",
         pat=r"(?:играет (?:важную|ключевую|значимую) роль|является свидетельством|оставляет неизгладимый след|символ эпохи|поворотный момент|ключевой момент|более широкий контекст|в современном мире)",
         desc="Раздувание значимости (RU)"),
    dict(id="vague_attr_en", cat="content", w=M, langs="en",
         pat=r"\b(?:industry reports?|observers? have|experts? (?:argue|say|believe|note)|critics? (?:argue|say)|several (?:sources|publications)|some critics)\b",
         desc="Размытые атрибуции (EN)"),
    dict(id="vague_attr_ru", cat="content", w=M, langs="ru",
         pat=r"(?:эксперты (?:отмечают|считают|говорят)|наблюдатели отмечают|аналитики отмечают|ряд источников|некоторые критики|по мнению экспертов)",
         desc="Размытые атрибуции (RU)"),
    dict(id="hedging_en", cat="communication", w=M, langs="en",
         pat=r"(?:it is important to note|it'?s worth noting|important to note|not widely (?:documented|available)|limited (?:public )?information|based on available information|in the provided sources|does not (?:by itself )?establish|should not be confused with|should be treated as|crucial to note)",
         desc="Хеджи и оговорки о доступности источников (EN)"),
    dict(id="hedging_ru", cat="communication", w=M, langs="ru",
         pat=r"(?:важно отметить|стоит отметить|необходимо подчеркнуть|следует отметить|не широко (?:задокументировано|освещено)|по имеющимся данным|на основе доступной информации|не является доказательством|не следует путать)",
         desc="Хеджи и оговорки (RU)"),
    dict(id="collab_en", cat="communication", w=M, langs="en",
         pat=r"\b(?:i hope this helps|of course!|certainly!|you'?re absolutely right|would you like|let me know|is there anything else|here'?s a|feel free to|happy to help|i apologize)\b",
         desc="Коммуникация с пользователем, оставшаяся в тексте (EN)"),
    dict(id="collab_ru", cat="communication", w=M, langs="ru",
         pat=r"(?:надеюсь, это поможет|конечно!|безусловно!|вы абсолютно правы|хотите, чтобы я|дайте знать|обращайтесь|буду рад помочь|приношу извинения)",
         desc="Коммуникация с пользователем (RU)"),
    dict(id="meta_en", cat="communication", w=M, langs="en",
         pat=r"\b(?:in this (?:article|guide|section)|this (?:article|guide) will|we will (?:discuss|explore|look)|below is a|the purpose is to provide|before (?:publishing|submission))\b",
         desc="Метакомментарии и инструкции в тексте (EN)"),
    dict(id="meta_ru", cat="communication", w=M, langs="ru",
         pat=r"(?:в этой статье|в данном разделе|мы рассмотрим|ниже приведён|перед публикацией|в этом разделе мы)",
         desc="Метакомментарии (RU)"),
    dict(id="conclusion_en", cat="historical", w=M, langs="en",
         pat=r"(?im)^\s*(?:in (?:summary|conclusion)|overall,|to sum up)\b",
         desc="Шаблонные финалы In summary/In conclusion (EN)"),
    dict(id="conclusion_ru", cat="historical", w=M, langs="ru",
         pat=r"(?im)^\s*(?:в (?:заключение|итоге|сумме)|подводя итог|таким образом)\b",
         desc="Шаблонные финалы (RU)"),
    dict(id="neg_parallel_en", cat="language", w=M, langs="en",
         pat=r"(?:not only\b[^.\n]{0,120}\bbut also|isn'?t just\b[^.\n]{0,80}\bit'?s|is not just\b[^.\n]{0,80}\bit is|is not\b[^.\n]{0,40},?\s*but\b)",
         desc="Негативные параллелизмы (EN)"),
    dict(id="neg_parallel_ru", cat="language", w=M, langs="ru",
         pat=r"(?:не только[^.\n]{0,90}но и|это не просто[^.\n]{0,90}это|не\s+\w+[^.\n]{0,40},\s*а\s+\w+)",
         desc="Негативные параллелизмы (RU)"),
    dict(id="copula_en", cat="language", w=M, langs="en",
         pat=r"\b(?:serves? as|stands? as|marks? (?:a|the|an)|functions? as|operates? as|represents? a)\b",
         desc="Избегание простых is/are (EN)"),
    dict(id="copula_ru", cat="language", w=M, langs="ru",
         pat=r"(?:представляет собой|выступает в качестве)", desc="Избегание простых конструкций (RU)"),
    dict(id="awards_header", cat="content", w=M, langs="any",
         pat=r"(?im)^[ \t]*(?:#{1,6}[ \t]*)?(?:awards? and recognition|awards? & recognition|награды и признание)[ \t]*$",
         desc="Раздел «Награды и признание»"),
    dict(id="challenges_header", cat="content", w=M, langs="any",
         pat=r"(?im)^[ \t]*(?:#{1,6}[ \t]*)?(?:challenges? and (?:future|legacy)|future outlook|вызовы и перспективы|проблемы и перспективы)[ \t]*$",
         desc="Шаблонный раздел «вызовы и перспективы»"),

    # ---------------- WEAK patterns ----------------
    dict(id="title_case_heading", cat="style", w=W, langs="any",
         pat=r"(?m)^(?:#{1,6}\s*)?([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,6})\s*$",
         desc="Заголовок в Title Case"),
    dict(id="emoji", cat="style", w=W, langs="any",
         pat=r"[\U0001F300-\U0001FAFF\u2600-\u27BF]", desc="Эмодзи в тексте"),
    dict(id="curly_quotes", cat="style", w=W, langs="en",
         pat=r"[“”‘’]", desc="Кривые кавычки/апострофы (EN)"),
    dict(id="transition_start", cat="style", w=W, langs="en",
         pat=r"(?m)^\s*(?:Additionally|Moreover|Furthermore|Consequently|Notably|Importantly|In addition),",
         desc="Transition-слова в начале предложения"),
    dict(id="rule_of_three_en", cat="language", w=W, langs="en",
         pat=r"\b\w+,\s+\w+,\s+and\s+\w+\b", desc="Правило трёх (EN)"),
    dict(id="rule_of_three_ru", cat="language", w=W, langs="ru",
         pat=r"\b\w+,\s+(?!но\b|а\b)\w+\s+и\s+\w+\b", desc="Правило трёх (RU)"),
    dict(id="inline_header_list", cat="style", w=W, langs="any",
         pat=r"(?m)^\s*[-*]\s+\*\*[^*\n]{1,60}\*\*\s*[:—-]", desc="Список с inline-заголовками"),
    dict(id="stiff_synonyms", cat="syntax_human", w=W, langs="en",
         pat=r"\b(?:utiliz(?:e|ed|ing)|authored|relocated|attempted|passed away)\b",
         desc="Книжные синонимы вместо простых слов (скорее человеческое/перенос)"),
]

EM_DASH_RE = re.compile(r"\s—\s")
HUMAN_SIMPLE_RE = re.compile(r"\b(?:there is|there are|it is|it has|they are|is|are)\b", re.I)
HUMAN_CONTRACTION_RE = re.compile(r"\b(?:don't|doesn't|isn't|it's|I'm|we're|can't|won't)\b")


@dataclass
class Finding:
    check_id: str
    category: str
    weight: str
    description: str
    count: int
    points: int
    examples: list[dict] = field(default_factory=list)


def detect_lang(text: str) -> str:
    cyr = len(re.findall(r"[А-Яа-яЁё]", text))
    lat = len(re.findall(r"[A-Za-z]", text))
    if cyr == 0 and lat == 0:
        return "en"
    return "ru" if cyr >= lat * 0.3 else "en"


class Matcher:
    def __init__(self, text: str):
        self.text = text
        self.line_starts = [0] + [m.end() for m in re.finditer(r"\n", text)]

    def line_of(self, pos: int) -> int:
        return bisect.bisect_right(self.line_starts, pos)

    def line_text(self, pos: int) -> str:
        line_no = self.line_of(pos)
        start = self.line_starts[line_no - 1]
        end = self.text.find("\n", start)
        if end == -1:
            end = len(self.text)
        return self.text[start:end].strip()

    def snippet(self, pos: int, matched: str = "") -> str:
        """A bounded window around the match, with ellipses; falls back to the match."""
        line = self.line_text(pos)
        if not line:
            return matched.strip()[:160]
        if len(line) <= 180:
            return line
        start = self.line_starts[self.line_of(pos) - 1]
        col = max(0, pos - start)
        a = max(0, col - 60)
        b = min(len(line), a + 160)
        prefix = "…" if a > 0 else ""
        suffix = "…" if b < len(line) else ""
        return (prefix + line[a:b].strip() + suffix)[:200]


def scan(text: str, lang: str) -> dict:
    m = Matcher(text)
    findings: list[Finding] = []
    for chk in CHECKS:
        if chk["langs"] not in ("any", lang):
            continue
        if chk["cat"] == "syntax_human":
            continue  # human-leaning, counted separately
        try:
            rx = re.compile(chk["pat"])
        except re.error as exc:  # pragma: no cover
            print(f"WARN: bad regex {chk['id']}: {exc}", file=sys.stderr)
            continue
        matches = list(rx.finditer(text))
        if not matches:
            continue
        examples = []
        seen = set()
        for mm in matches[:8]:
            line = m.snippet(mm.start(), mm.group(0))
            key = (m.line_of(mm.start()), line[:80])
            if key in seen:
                continue
            seen.add(key)
            examples.append({"line": m.line_of(mm.start()), "text": line[:180]})
        points = WEIGHT_SCORE[chk["w"]] * min(len(matches), WEIGHT_CAP[chk["w"]])
        findings.append(Finding(chk["id"], chk["cat"], chk["w"], chk["desc"],
                                len(matches), points, examples))

    # extra signal: em dash density (EN only)
    if lang == "en":
        dashes = len(EM_DASH_RE.findall(text))
        per_1k = dashes / max(len(text) / 1000.0, 0.001)
        if dashes >= 4 and per_1k >= 3.0:
            pts = 2 if per_1k < 6 else 4
            findings.append(Finding("em_dash_density", "style", M,
                                    "Плотность длинных тире с пробелами (EN)",
                                    dashes, pts, [{"line": 0, "text": f"≈{per_1k:.1f} на 1000 символов"}]))
    # AI vocab density bonus
    vocab = [f for f in findings if f.check_id in ("ai_vocab_en", "ai_vocab_ru")]
    if vocab and vocab[0].count >= 6:
        bonus = 4 if vocab[0].count < 10 else 8
        findings.append(Finding("ai_vocab_density", "language", M,
                                "Высокая плотность AI-лексики", vocab[0].count, bonus, []))

    score = sum(f.points for f in findings)
    strong = [f for f in findings if f.weight == S]
    categories: dict[str, int] = {}
    for f in findings:
        categories[f.category] = categories.get(f.category, 0) + f.points

    if strong:
        verdict = "AI-артефакты: вероятно (требует проверки фактов)"
    elif score >= 30:
        verdict = "AI-вероятно (кластер средних признаков)"
    elif score >= 15:
        verdict = "Смешанно: есть подозрительные признаки"
    elif score >= 6:
        verdict = "Слабые признаки: контекст решает"
    else:
        verdict = "Неубедительно: признаков мало"

    human_notes = []
    contractions = len(HUMAN_CONTRACTION_RE.findall(text))
    simple_copulas = len(re.findall(r"\b(?:there is|there are|it is|it has|they are)\b", text, re.I))
    stiff_hits = len(re.findall(r"\b(?:utiliz(?:e|ed|ing)|authored|relocated|attempted|passed away)\b",
                                text, re.I))
    if contractions >= 2:
        human_notes.append(f"Разговорные сокращения: {contractions} (скорее человеческое)")
    if simple_copulas >= 3:
        human_notes.append(f"Простые конструкции is/has: {simple_copulas} (скорее человеческое)")
    if stiff_hits >= 2:
        human_notes.append(f"Книжные синонимы: {stiff_hits} (человеческая привычка/перевод)")
    if contractions == 0 and simple_copulas < 3:
        human_notes.append("Нет простых разговорных маркеров — не признак, но учитывай жанр")
    human_notes.append("Проверь дату: текст до 30.11.2022 не может быть AI-сгенерированным")

    findings.sort(key=lambda f: (-WEIGHT_SCORE[f.weight], -f.points, f.check_id))
    return {
        "language": lang,
        "score": score,
        "verdict": verdict,
        "strong_count": len(strong),
        "categories": dict(sorted(categories.items(), key=lambda kv: -kv[1])),
        "findings": [
            {
                "id": f.check_id, "category": f.category, "weight": f.weight,
                "description": f.description, "count": f.count, "points": f.points,
                "examples": f.examples,
            }
            for f in findings
        ],
        "human_notes": human_notes,
        "caveat": "Эвристика, не доказательство. Оценивай кластеры, жанр, автора и контекст.",
    }


def print_report(res: dict, source: str, show_examples: int = 3) -> None:
    print(f"=== AI-writing tells scan: {source} ===")
    print(f"Язык: {res['language']} | Score: {res['score']} | Вердикт: {res['verdict']}")
    print()
    if res["categories"]:
        print("Баллы по категориям:")
        for cat, pts in res["categories"].items():
            print(f"  - {cat:12s} {pts}")
        print()
    print(f"Найдено сигналов: {len(res['findings'])} (сильных: {res['strong_count']})")
    for f in res["findings"]:
        print(f"\n[{f['weight']}] {f['description']} — {f['count']}× (+{f['points']})")
        for ex in f["examples"][:show_examples]:
            line = f"стр. {ex['line']}: " if ex["line"] else ""
            print(f"    {line}{ex['text']}")
    print("\nЗаметки:")
    for n in res["human_notes"]:
        print(f"  - {n}")
    print(f"\n[!] {res['caveat']}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Heuristic AI-writing tells scanner")
    ap.add_argument("path", help="file path or '-' for stdin")
    ap.add_argument("--lang", choices=["auto", "en", "ru"], default="auto")
    ap.add_argument("--json", action="store_true", help="JSON output")
    ap.add_argument("--min-weight", choices=["S", "M", "W"], default="W",
                    help="show only findings at/above this weight")
    args = ap.parse_args()

    if args.path == "-":
        text = sys.stdin.read()
        source = "<stdin>"
    else:
        with open(args.path, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        source = args.path

    lang = detect_lang(text) if args.lang == "auto" else args.lang
    res = scan(text, lang)
    order = {"W": 0, "M": 1, "S": 2}
    res["findings"] = [f for f in res["findings"] if order[f["weight"]] >= order[args.min_weight]]

    if args.json:
        print(json.dumps({"source": source, **res}, ensure_ascii=False, indent=2))
    else:
        print_report(res, source)
    return 1 if res["strong_count"] else 0


if __name__ == "__main__":
    sys.exit(main())
