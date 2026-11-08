# moon-trust

[![ci](https://github.com/ShunjunGu/trusted-evidence-layer/actions/workflows/ci.yml/badge.svg)](https://github.com/ShunjunGu/trusted-evidence-layer/actions/workflows/ci.yml)

A **deterministic trusted-evidence layer** between retrievers and generators: every scan turns an untrusted retrieval feed into a single-line, JSON-serializable report — snapshot of the query and config, risk findings per block, explicit cross-document conflicts, quarantine audit trail, evidence re-ranked by retrieval score plus an explainable trust score minus conflict penalties, a budgeted generator-ready context with citations, and diagnostics — and two runs on identical inputs produce **byte-identical** output. A one-command [acceptance demo](#验收演示有无信任层对比) runs the same fixed corpus with and without the layer and reports exactly what changed.

## Install

### From mooncakes

[`ShunjunGu/moon-trust`](https://mooncakes.io/docs/ShunjunGu/moon-trust) is
published on mooncakes:

```console
$ moon add ShunjunGu/moon-trust
```

Import the library package as `ShunjunGu/moon-trust/src` (alias `@src`); the
CLI package is `ShunjunGu/moon-trust/cmd/main`.

### From source

Requires the [MoonBit](https://www.moonbitlang.com) toolchain (`moon`):

- *nix: `curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash`
- Windows: `irm https://cli.moonbitlang.com/install/powershell.ps1 | iex`

Then, from the repository root:

```console
$ moon update
$ moon build --target native
```

## 最小示例

Two runnable examples live under `examples/` and are executed in CI.

### 1. Quick start — rerank and cite

`examples/quickstart` builds three candidates, runs the default pipeline, and
prints the rank, trust score, generator-ready context, and citations:

```console
$ moon run examples/quickstart --target native
moon-trust quickstart
query: expense deadline

rank  id             retrieval  trust     rerank
1     curated          0.7000     0.9500    1.6500
2     handbook         0.7000     0.9375    1.6375
3     short-mirror     0.9500     0.5167    1.4667

context: 3 blocks, 53 tokens / budget 512
[1] | Expense reports are due within 30 days of travel.
source: Expenses Policy | s3://knowledge/expenses.md | 2026-11-02T00:00:00Z

[2] | Expense reports are due within 30 days of travel.
source: Travel Handbook | https://intranet.example.com/handbook | 2026-11-01T00:00:00Z

[3] | short
source: (untitled) | file:///tmp/mirror.txt |

citations:
  [1] curated -> s3://knowledge/expenses.md
  [2] handbook -> https://intranet.example.com/handbook
  [3] short-mirror -> file:///tmp/mirror.txt
```

The `short-mirror` block has the highest retrieval score (`0.95`) but a thin
source: no title, no fetch time, a local `file://` URI, and a one-word body. The
trust blend (`0.5167`) drops it below `handbook` (`0.9375`) and `curated`
(`0.9500`), so the generator sees the complete, curated sources first.

### 2. Injection triage — mark vs drop

`examples/injection-triage` scans one benign and three injected chunks under the
`mark` and `drop` policies:

```console
$ moon run examples/injection-triage --target native
moon-trust injection triage

mark policy: 4 evidence kept, 4 findings
  override: instruction.override (high): instruction override: text asks to ignore or replace the caller's instructions (matched: "ignore previous instructions")
  override: exfiltration.secret (high): exfiltration phrase: text asks to reveal or print protected instructions or secrets (matched: "reveal your system prompt")
  hidden: hidden.zero-width (high): hidden character: U+200B zero-width space can conceal text from human review
  role: role.marker (high): role marker: a reserved chat or role delimiter appears in retrieved text (matched: "<|system|>")

drop policy: 1 evidence kept, 3 quarantined, blocked=true
  override: dropped by policy: high-severity risk
    instruction.override (high)
    exfiltration.secret (high)
  hidden: dropped by policy: high-severity risk
    hidden.zero-width (high)
  role: dropped by policy: high-severity risk
    role.marker (high)

context kept under the drop policy:
[1] | Expense reports are due within 30 days.
source: handbook | https://example.com/handbook | 2026-11-08T00:00:00Z
```

`mark` keeps every block and reports the rules that fired. `drop` removes the
three high-severity blocks, lists them in `quarantined`, and sets `blocked=true`
because `block_on_high` is enabled; the context contains only the benign chunk.
Both examples assert their own invariants, so a regression fails the CI run
rather than silently printing different output.

## Scan CLI

The native binary lives under `_build/native/debug/build/cmd/main/main.exe`:

```console
$ _build/native/debug/build/cmd/main/main.exe scan hello tests/fixtures/multi.json
{"query":"hello","config":{},"evidence":[{"id":"t1","text":"first","source":{"uri":"https://example.com/a","title":"Doc A","fetched_at":"2026-11-01T00:00:00Z"},"retrieval_score":0.95,"retrieval_normalized":0.95,"span":{"start":0,"end":12},"risk_findings":[],"conflict_ids":[],"conflict_penalty":0,"rerank_score":1.7416666666666667,"trust":{"score":0.7916666666666667,"breakdown":{"source_score":0.875,"content_score":0.7083333333333334,"metadata":0.75,"source_type":1,"length":0.125,"template_ratio":0,"consistency":1,"risk":1}}},{"id":"a2","text":"second","source":{"uri":"s3://bucket/b","title":"Doc B","fetched_at":"2026-11-02T00:00:00Z","hint":"curated"},"retrieval_score":0.8,"retrieval_normalized":0.8,"risk_findings":[],"conflict_ids":[],"conflict_penalty":0,"rerank_score":1.6083333333333334,"trust":{"score":0.8083333333333333,"breakdown":{"source_score":0.9,"content_score":0.7166666666666667,"metadata":1,"source_type":0.8,"length":0.15,"template_ratio":0,"consistency":1,"risk":1}}},{"id":"b2","text":"third","source":{"uri":"file:///c/d.txt","title":"Doc C","fetched_at":"2026-11-03T00:00:00Z"},"retrieval_score":0.4,"retrieval_normalized":0.4,"risk_findings":[],"conflict_ids":[],"conflict_penalty":0,"rerank_score":1.0416666666666665,"trust":{"score":0.6416666666666666,"breakdown":{"source_score":0.575,"content_score":0.7083333333333334,"metadata":0.75,"source_type":0.4,"length":0.125,"template_ratio":0,"consistency":1,"risk":1}}}],"context":{"budget":512,"estimated_tokens":41,"truncated":false,"included_count":3,"omitted_count":0,"text":"[1] | first\nsource: Doc A | https://example.com/a | 2026-11-01T00:00:00Z\n\n[2] | second\nsource: Doc B | s3://bucket/b | 2026-11-02T00:00:00Z\n\n[3] | third\nsource: Doc C | file:///c/d.txt | 2026-11-03T00:00:00Z","citations":[{"index":1,"evidence_id":"t1","source":{"uri":"https://example.com/a","title":"Doc A","fetched_at":"2026-11-01T00:00:00Z"}},{"index":2,"evidence_id":"a2","source":{"uri":"s3://bucket/b","title":"Doc B","fetched_at":"2026-11-02T00:00:00Z","hint":"curated"}},{"index":3,"evidence_id":"b2","source":{"uri":"file:///c/d.txt","title":"Doc C","fetched_at":"2026-11-03T00:00:00Z"}}]},"conflicts":[],"quarantined":[],"blocked":false,"diagnostics":{"candidate_count":3,"duplicate_id_count":0,"unknown_rule_ids":[],"risk_finding_count":0,"quarantined_count":0,"conflict_count":0,"conflicts_truncated":false,"output_count":3,"stages":[{"name":"ingest","count":3},{"name":"dedupe","count":3},{"name":"risk","count":0},{"name":"isolate","count":3},{"name":"conflict","count":0},{"name":"sort","count":3},{"name":"topk","count":3},{"name":"context","count":3}]}}
```

Evidence is ordered by `rerank_score = retrieval_normalized + trust_weight × trust.score − conflict_penalty` (descending), with ties broken by id ascending. Retrieval scores already inside `[0, 1]` are used as-is; any other batch is min-max normalized to `[0, 1]`, and the value used by rerank is echoed as `retrieval_normalized` alongside the raw `retrieval_score`. Trust is an explainable heuristic in `[0, 1]`: it blends source signals (metadata completeness, URI scheme) with content signals (length, raw template-marker share, cross-document consistency), then multiplies by the risk factor reported as `trust.breakdown.risk`. The two provenance/content weights default to 0.5/0.5, `trust_weight` defaults to 1.0, and `conflict_weight` defaults to 0.5; library callers can override them via `ScanConfig`, and non-finite values fall back to those defaults.

Optional flags:

- `--top-k N` truncates to the N highest-scored evidence items after the rerank sort. `top_k` applies to `evidence` only; the `quarantined` audit trail is never truncated.
- `--policy drop|mark|downrank` selects the isolation policy (default `downrank`).
- `--block-on-high` sets `blocked: true` and makes the CLI exit `3` when any high-severity finding exists — including findings on blocks the drop policy removed.
- `--risk-weight W` scales the risk penalty with a positive finite number (default `1.0`; `0` is rejected).
- `--conflict-weight W` scales the per-conflict rerank penalty with a non-negative finite number (default `0.5`; `0` disables the extra rerank penalty but keeps the consistency signal).
- `--context-budget N` caps the approximate token budget of the assembled evidence context with a non-negative integer (default `512`; `0` produces an empty context while keeping the full report).

```console
$ _build/native/debug/build/cmd/main/main.exe scan hello tests/fixtures/injected.json --policy drop --block-on-high
$ echo $?
3
```

Exit codes: `0` success, `1` usage error or malformed candidates file, `2` candidates file cannot be read, `3` blocked scan (report still printed on stdout). Errors and the usage line are printed on stdout; stderr is always empty. The candidates file is JSON encoding of a list of evidence entries (`{id, text, source:{uri, title?, fetched_at, hint?}, retrieval_score, span?}`); each run is filesystem-free — determinism comes from the inputs, never from wall-clock time or randomness.

The full usage line is:

```text
usage: moon-trust scan <query> <candidates.json> [--top-k N] [--policy drop|mark|downrank] [--block-on-high] [--risk-weight W] [--conflict-weight W] [--context-budget N]
       moon-trust demo <candidates.json> [--json-out PATH]
```

## 评分规则

All scores are deterministic heuristics in `[0, 1]`. They are **not**
probabilities, model confidence, or truth judgments; every sub-signal is
reported so a caller can audit or re-weight the result.

**Retrieval normalization.** If every retrieval score in the batch is already
inside `[0, 1]`, it is used as-is. Otherwise the batch is min-max normalized to
`[0, 1]`. The value used by reranking is echoed as `retrieval_normalized` next
to the raw `retrieval_score`.

**Trust score.**

```text
trust.score = clamp01((source_weight × source_score +
                       content_weight × content_score) × risk_factor)

source_score  = (metadata + source_type) / 2
  metadata    = non-empty {uri, title, fetched_at} plus present hint, / 4
  source_type = https 1.0 | s3/gs 0.8 | http 0.6 | file 0.4 | other :// 0.3 | none 0.2

content_score = (length + template_cleanliness + consistency) / 3
  length              = clamp01(UTF-16 code units / 40)
  template_ratio      = share of { } < > in the raw text
  template_cleanliness= clamp01(1 − 8 × template_ratio)   # 0 at ≥ 12.5%
  consistency         = 1 / (1 + conflict_count)
```

`source_weight` and `content_weight` default to `0.5 / 0.5` and are normalized
to sum to 1; non-finite values fall back to the defaults, and a non-positive sum
also falls back to equal weights. `risk_factor` is `1.0` under `mark` and
`drop`; under `downrank` it is
`1 − clamp01(Σ severity_penalty × risk_weight)` with penalties high `0.5`,
medium `0.25`, low `0.1` (so two high findings already zero the score). The
factor actually applied is echoed as `trust.breakdown.risk`.

**Rerank score.**

```text
rerank_score = retrieval_normalized
             + trust_weight × trust.score
             − conflict_penalty

conflict_penalty = clamp01(conflict_weight × conflict_count)
```

Defaults are `trust_weight = 1.0`, `conflict_weight = 0.5`, and
`risk_weight = 1.0`. Evidence is sorted by `rerank_score` descending, then id
ascending, then original input order; `top_k` truncates after sorting.

## 验收演示：有/无信任层对比

`demo` measures one fixed corpus twice — as the raw retrieval feed (no trust layer) and through the full pipeline — and reports the difference in one command. It needs no network, no keys, and no external service; the same corpus always produces the same summary and the same JSON bytes. This is the demo path for the application walkthrough.

```console
$ moon run cmd/main --target native -- demo tests/fixtures/demo.json --json-out _build/demo.json
moon-trust demo: with vs without the trust layer
query: demo
corpus: 11 candidates; policy: drop

metric                      without trust     with trust
unsafe blocks exposed       5                 0
conflict pairs found        0                 2
injections intercepted      0                 5

ranking changes (retrieval order -> rerank order):
  benign-imperative   9 ->  1  (+8)
  high-trust         10 ->  2  (+8)
  benign-doc         11 ->  3  (+8)
  low-trust           6 ->  4  (+2)
  fact-a              7 ->  5  (+2)
  fact-b              8 ->  6  (+2)
(6 of 6 surviving blocks changed rank)

quarantined (5): inj-override, inj-role, inj-hidden, inj-delimiter, inj-payload
trusted run: 6 evidence, blocked=true
context: 6 blocks, 162 tokens / budget 512, truncated=false
```

**Side definitions.** *Without the trust layer* is the raw retrieval feed: every candidate in retrieval-score order (ties by id, then input order), nothing removed and nothing detected. *With the trust layer* is a normal `scan` with `--policy drop --block-on-high` and default weights, so conflict detection, trust rerank, and context assembly all apply. The baseline's safety numbers are a counterfactual disclosure measured with the same scanner — not a second pipeline.

**Metrics.**

| metric | without | with | meaning |
| --- | --- | --- | --- |
| `unsafe_blocks_exposed` | 5 | 0 | blocks with at least one high-severity finding that would reach the generator |
| `conflict_pairs` | 0 | 2 | explicit cross-document `(subject, unit, value)` disagreements |
| `injections_intercepted` | 0 | 5 | high-severity blocks removed by the drop policy (the quarantine list) |
| `ranking_changes` | — | 6 | surviving blocks whose 1-based rank differs from retrieval order; `delta = before − after`, positive means moved up |

Dropped blocks appear in `quarantined_ids`, not in `ranking_changes`: the raw feed's rank has no counterpart for a block the trusted run removed.

**Machine-readable artifact.** `--json-out PATH` writes the comparison while the human summary still goes to stdout. The JSON is one line with the same numbers plus both full orders:

```json
{
  "query": "demo",
  "corpus_size": 11,
  "policy": "drop",
  "baseline": {"order": ["inj-override", "..."], "unsafe_blocks": 5, "high_severity_findings": 6, "risk_findings": 9},
  "trusted": {"order": ["benign-imperative", "..."], "unsafe_blocks": 0, "high_severity_findings": 0, "risk_findings": 1, "conflicts": 2, "quarantined_count": 5, "quarantined_ids": ["inj-override", "..."], "blocked": true, "context": {"budget": 512, "included_count": 6, "estimated_tokens": 162, "truncated": false}},
  "comparison": {
    "unsafe_blocks_exposed": {"before": 5, "after": 0, "delta": -5},
    "conflict_pairs": {"before": 0, "after": 2, "delta": 2},
    "injections_intercepted": {"before": 0, "after": 5, "delta": 5},
    "ranking_changes": [{"id": "benign-imperative", "before_rank": 9, "after_rank": 1, "delta": 8}, "..."]
  }
}
```

**Reproducibility.** Run the same command twice and compare both streams; they are byte-identical:

```console
$ moon build --target native
$ moon run cmd/main --target native -- demo tests/fixtures/demo.json --json-out _build/a.json > _build/a.txt
$ moon run cmd/main --target native -- demo tests/fixtures/demo.json --json-out _build/b.json > _build/b.txt
$ diff _build/a.txt _build/b.txt && diff _build/a.json _build/b.json
```

CI runs this check on the native target (`.github/workflows/ci.yml`). The corpus is `tests/fixtures/demo.json`; no network, credentials, clock, or randomness participate.

A successful comparison always exits `0`, even when `blocked` is `true`; use `scan --block-on-high` when the exit status itself must gate downstream work. Input errors follow the scan contract: `1` usage error or malformed candidates file, `2` unreadable candidates file or unwritable JSON path.

## 风险扫描与隔离

The scan runs a fixed, deterministic rule set over every kept candidate. Each rule contributes **at most one finding** per block, anchored at its earliest match, and findings are sorted by span start then rule id. A finding carries `rule_id`, `severity` (`low` / `medium` / `high`), a half-open UTF-16 code-unit span (the same measure as `text.length()`), and an explanation (phrase rules name the matched phrase; structural rules name the code point or limit).

Phrase matching runs on a normalized copy: invisible and format characters are stripped, whitespace is collapsed, full-width ASCII is folded to ASCII, and ASCII is lowercased. Every folded position keeps a pointer back to the original UTF-16 code unit, so reported spans always slice the untrusted source exactly.

| rule id | severity | signals |
| --- | --- | --- |
| `instruction.override` | high | "ignore previous instructions", "forget all previous", 忽略之前的指令, 覆盖系统指令 |
| `instruction.redirect` | medium | "ignore the above", "disregard the above", 忽略以上内容 |
| `instruction.imperative` | low | "you must", "you should", "please output", 请输出, 请打印 |
| `role.marker` | high | `<\|system\|>`, `<\|im_start\|>`, `<\|start_header_id\|>`, `<\|eot_id\|>`, `<system>`, `[INST]`, `<<SYS>>` |
| `role.chat-heading` | medium | `### System`, `Human:`, `Assistant:`, `system:`, `developer:`, 系统提示词 |
| `hidden.zero-width` | high | U+200B, U+2060, U+180E |
| `hidden.bidi-control` | high | U+061C, U+202A–U+202E, U+2066–U+2069 |
| `hidden.format` | medium | U+200C, U+200D, U+FEFF, U+00AD, U+034F, U+115F–U+1160, U+17B4–U+17B5, U+180B–U+180F, U+2061–U+2064, U+2800, U+3164, U+FE00–U+FE0F, U+FFF9–U+FFFB |
| `payload.encoded` | high | `data:text/html`, HTML-entity / percent-encoded zero-width characters, 解码以下 |
| `payload.base64` | medium | `base64,` (inline data; common and usually benign) |
| `payload.oversize` | medium | text longer than 100,000 UTF-16 code units; only the prefix was scanned |
| `payload.code-exec` | medium | `atob(`, `eval(`, `unescape(`, `fromCharCode(` |
| `payload.escape-sequence` | medium | `\xHH` and `\uHHHH` escape sequences |
| `exfiltration.secret` | high | "reveal your system prompt", "what is your system prompt", "show me your instructions", "print the conversation history", 泄露密钥 |
| `exfiltration.send` | medium | "send the following", "upload the following", 发送以下 |
| `delimiter.escape` | high | `</system>`, `<\|endoftext\|>`, `[END OF CONTEXT]`, 以下是新的指令 |

Isolation policies:

- **`downrank` (default)** — keep every block, annotate findings, and multiply trust by `1 − clamp(Σ severity_penalty × risk_weight)`. Severity penalties are high `0.5`, medium `0.25`, low `0.1`, so two high findings already zero the trust score. The applied factor is echoed as `trust.breakdown.risk`.
- **`mark`** — keep every block and annotate findings, but do not penalize scores (`risk` stays `1`).
- **`drop`** — remove blocks with at least one high-severity finding. Removed blocks stay auditable in `quarantined` (id, text, source, risk_findings, reason); kept blocks are annotated without a score penalty. Medium and low findings never remove a block.

Library callers can additionally set `enabled_rules: Some([...])` in `ScanConfig` to restrict scanning to specific rule ids; an absent list enables the whole registry and an empty list disables it. Unknown ids are ignored by the scanner but echoed in `diagnostics.unknown_rule_ids`, so a typo cannot silently disable a rule.

`diagnostics` reports `risk_finding_count` (all findings), `quarantined_count`, `conflict_count` (explicit pairs), `conflicts_truncated`, `output_count`, and `unknown_rule_ids`. The stage counters are `ingest` (input candidates), `dedupe` (kept after id dedupe), `risk` (blocks with at least one finding), `isolate` (blocks surviving the policy), `conflict` (reported pairs), `sort` (ranked evidence), `topk` (evidence after truncation), and `context` (evidence included in the assembled context).

### 误报与漏报边界

The rule set is an inspectable heuristic, not a classifier. Known
false-positive and false-negative boundaries:

- **Ordinary imperatives stay low severity.** "You should consult a doctor…" and "请输出报表" produce `instruction.imperative` (low) and never trigger the drop policy; under the default `downrank` policy they only lose 10% of trust.
- **Code fences are not delimiter escapes.** The delimiter rule targets explicit context-closing tokens (`</system>`, `[END OF CONTEXT]`, …), not Markdown fences or headings.
- **Emoji joiners are medium, not high.** U+200D (ZWJ) and U+200C (ZWNJ, used in Persian) are reported as `hidden.format` (medium): they are stripped before phrase matching but never trigger `drop`. Inline `data:image/...;base64,` payloads are likewise `payload.base64` (medium), not `payload.encoded` (high).
- **Normalization folds full-width ASCII and whitespace only.** Other compatibility forms (ligatures, circled letters, Cyrillic/Greek homoglyphs) are not folded; a homoglyph substitution can still evade a phrase rule.
- **Long blocks are capped.** Only the first 100,000 UTF-16 code units are scanned; the remainder is reported as `payload.oversize` (medium) and is not inspected.
- **Cross-block instructions are not detected.** Each block is scanned independently; a phrase split across two adjacent chunks can pass.
- **Overlapping rules accumulate.** One phrase can match several rules (for example `ignore all prior instructions` matches both `instruction.override` and `instruction.redirect`); their penalties add, and two high findings already zero the score.
- **Opaque payloads without a marker are missed.** A bare base64 blob with no `base64,`/data-URI prefix (or other encoding marker) is not detected.
- **Documentation about these tokens is flagged.** An article that explains `<|system|>`, `base64,`, or `</system>` matches the same rules as an attack, because the scanner has no way to distinguish mention from use. Use `mark` or a restricted `enabled_rules` list when scanning security documentation.
- **Paraphrases and languages beyond Chinese/English are out of scope.** The scan matches fixed phrases and code units; it does not understand intent.
- **Spans count UTF-16 code units.** They are suitable for slicing the original MoonBit `String`, and for astral characters each code point occupies two units. Spans are mapped back through normalization, so they always address the original text.

## 冲突检测

Conflict detection runs after isolation and before trust scoring. It extracts explicit `(subject, unit, value)` claims and reports every pair of different documents that assert different values for the same normalized subject and unit.

**Subject resolution** (in order): the text key before a separator (`:`, `：`, `=`, ` is `, ` was `, ` are `, ` were `, ` will be `, `为`, `是`, `达到`, `约为`, `等于`), then the source title, then the normalized query. Subjects are lowercased (ASCII), whitespace-collapsed, stripped of a leading `the` / `a` / `an`, and capped at 80 UTF-16 units. A value with no resolvable subject is ignored.

**Values**: numbers (sign, thousands separators, decimals), multipliers (`thousand` / `million` / `billion` / `trillion`, `千` / `万` / `亿`, `k`; the multiplier is part of the unit, so `68 million` has unit `million` and `3 trillion` has unit `trillion`), percentages (`%`, `percent`, `百分比`), and dates (`YYYY-MM-DD`, `YYYY/MM/DD`, `YYYY.MM.DD`, `YYYY年M月D日`, `Month D, YYYY`, `D Month YYYY`). Units are canonicalized into a small vocabulary: currency (`cny`, `usd`, `eur`, `gbp`), distance (`mm`, `cm`, `m`, `km`, `mi`), mass (`g`, `kg`, `lb`), volume (`ml`, `l`), time (`ms`, `s`, `min`, `h`, `day`, `week`, `month`, `year`), data size (`kb`–`tb`), temperature (`c`, `f`), area (`km2`, `m2`, …), and the unitless count `""`.

**Pairing**: claims are grouped by `(subject, unit)`. Two claims pair when they come from different evidence ids and their values differ. Equal values never conflict; different units are never compared (`10 km` and `10 miles`, and `68 million` and `3 trillion`, are two groups each), and one document's internal contradiction never pairs with itself.

Each `conflicts[]` entry names both sides (`evidence_id`, comparable `value`, original `value_text`, and the span that slices the source). Every evidence entry carries `conflict_ids` pointing back to the pairs it participates in, plus a `conflict_penalty`.

- `trust.breakdown.consistency = 1 / (1 + conflict_count)` feeds the trust content blend.
- `conflict_penalty = clamp01(conflict_weight × conflict_count)` is subtracted from the rerank score. The default weight is `0.5`, so one pair costs `0.5` rank and two or more pairs hit the `1.0` cap.
- `top_k` truncates `evidence` only; `conflicts` and their back-references remain as audit data.

### 冲突检测边界

- **No Chinese numerals.** Only Arabic digits are parsed; `六十八` is not a number.
- **No unit conversion.** `10 km` and `10 miles` are different units and are never compared; `1 m` and `100 cm` likewise.
- **No ranges or approximations.** `10–20` is parsed as two values; `about 10` drops the approximation word.
- **Subject phrasing must match after normalization.** "France population" and "population of France" are different keys; "The tax rate" and "tax rate" are the same after the article is stripped.
- **Fallback subjects can over-group.** An unkeyed, qualified value falls back to the source title, then the query; two unrelated values in same-titled documents can therefore land in one group.
- **Shared separators group attributes.** Values after one separator share its key: `France: population 68 million, GDP 70 million` puts both claims under `france`. Give each attribute its own key (`population: 68 million`, `GDP: 70 million`) when they share a clause.
- **Pairing is capped.** Claims in one `(subject, unit)` group pair pairwise; at most 1,000 conflict pairs are emitted in canonical order. Larger result sets set `diagnostics.conflicts_truncated` and drop the remainder.
- **Ambiguous units are skipped.** `in` (inch) is not recognized because it is usually a preposition; `M` is not a multiplier because it collides with meters. Spell out `million`.
- **Numbers inside words are ignored** (`abc123`), and bare numbers without a key or unit are not claims.
- **Malformed dates are skipped** when a four-digit year is followed by `-`, `/`, or `年`; `2024.13.40` is a known exception because `.` is also a sentence boundary.
- **Chinese copulas are heuristic.** `为` and `是` inside compounds can produce a short or wrong key; prefer explicit colons in Chinese text.
- **Chinese/English only.** Other date formats and languages are out of scope; spans count UTF-16 code units and map back through normalization.

## 证据上下文组装

The last pipeline stage turns the ranked `evidence` into `context`, the plain-text artifact a generator consumes. The context is assembled greedily in rank order under an approximate token budget (`ScanConfig.context_budget`, default `512`); over-budget evidence is omitted whole, never cut mid-block, and `context.truncated` / `context.omitted_count` record the omission. `top_k` runs first, so `omitted_count` counts only budget omissions.

Each included block renders as:

```text
[1] | <untrusted line 1>
| <untrusted line 2>
source: <title or (untitled)> | <uri> | <fetched_at>
```

`context.citations` has one record per marker: `index` (1-based, equal to `n`), `evidence_id`, and the evidence's `source` metadata (`uri`, `title`, `fetched_at`, optional `hint`). Every renderer-generated `[n]` marker resolves to `citations[n - 1]` and to an id present in `evidence`; untrusted brackets are escaped, so a chunk cannot forge one.

When the included evidence carries risk findings or conflict pairs, the context closes with appendices:

```text
Risks:
- [1] instruction.override (high): phrase rule: ...

Conflicts:
- [1] vs [2] france (million): 68 million vs 67 million
```

`Risks:` lists the findings of included evidence, anchored at its marker. `Conflicts:` lists only pairs whose **both** sides are included, so every marker in the appendix resolves too; the report's `conflicts` array still records every pair, including those whose other side was omitted. Sections with no entries are omitted.

**Token estimation** is an intentionally cheap approximation: each maximal run of ASCII letters, digits, and `_` counts as one token; every non-ASCII code point (CJK characters and punctuation included) counts as one token; ASCII whitespace and punctuation count as zero. The applied budget and the estimate after assembly are echoed as `context.budget` and `context.estimated_tokens`; `estimated_tokens` never exceeds `budget`.

### 上下文边界

- **Greedy, not optimal.** A block that does not fit is skipped and later, smaller blocks may still be included. The result is deterministic but not a knapsack optimum.
- **Estimates are not a tokenizer.** ASCII punctuation, repeated spaces, and tokenizer-specific merges are not modeled; leave headroom when the downstream model has a hard limit.
- **Untrusted text is quoted and escaped.** Each line of an evidence block is prefixed with `| `, and `[`, `]`, `|` in untrusted text and metadata are folded to their full-width forms. Only the renderer emits ASCII `[n]` markers and ` | ` separators; a forged `source:` line stays inside a quoted line. The raw text remains in `evidence[]`.
- **Only included evidence is disclosed.** Risks and conflicts involving omitted evidence stay in the report (`evidence`, `conflicts`), not in the context.
- **Duplicate sources are kept distinct.** Two chunks from the same URI each get their own marker and citation; they are never merged.
- **`top_k` precedes the budget.** `evidence` is truncated first; `context.omitted_count` counts budget omissions only, not `top_k` removals.
- **Empty titles render as `(untitled)`.** The citation keeps the raw empty title.

## Library

The scan core (`src/`) is a pure library usable from any MoonBit CLI or FFI target (native / wasm / wasm-gc / js) — only `cmd/main` touches the filesystem. Add it with `moon add ShunjunGu/moon-trust` and import `ShunjunGu/moon-trust/src`.

```moonbit
let report = @src.scan(
  "hello",
  { ..@src.ScanConfig::default(), risk_policy: Some(@src.RiskPolicy::Drop) },
  candidates,
)
// The generator-ready text and its citation table:
let context = report.context
```

`candidates` is `Array[@src.Candidate]`; `report.to_json().stringify()` produces the
same single-line JSON the CLI prints. The complete, compiling version of this
snippet is [`examples/quickstart/main.mbt`](examples/quickstart/main.mbt).

## Coverage

CI runs `moon coverage analyze` and uploads the `full_summary` text and an HTML
report as the `coverage` artifact.

Current line coverage (2026-11-08, instrumented test run):

| scope | covered / total | coverage |
| --- | --- | --- |
| library (`src/` + `src/cli/`) | 1239 / 1440 | **86.0%** |
| whole module (includes `cmd/main` and both example executables) | 1239 / 1542 | 80.4% |

`cmd/main` (34 lines) is the native-only executable shell; CI exercises it
through the binary/CLI integration checks rather than in-process tests. The two
example executables (34 instrumented lines each) are run by the native CLI job
but have no test entry point, so the instrumented library run reports them as
uncovered.

Reproduce locally:

```console
$ moon coverage analyze
$ find _build -name '*.trace.source' -print0 | xargs -0 moon coverage report -f full_summary
```

## Tests

```console
$ moon test --target all
Total tests: 125, passed: 125, failed: 0. [wasm]
Total tests: 125, passed: 125, failed: 0. [wasm-gc]
Total tests: 125, passed: 125, failed: 0. [js]
Total tests: 125, passed: 125, failed: 0. [native]
```

CI runs each target as a separate matrix job (`wasm`, `wasm-gc`, `js`, `native`)
and runs the native CLI, both examples, the blocked-exit check, and the
reproducible demo on Linux, macOS, and Windows.

## 版本与发布

- Current version: `0.1.1` (SemVer); see [CHANGELOG.md](CHANGELOG.md).
- Published on mooncakes as `ShunjunGu/moon-trust` (`moon add ShunjunGu/moon-trust`).
- Name check (before publication on 2026-11-08):
  `GET https://mooncakes.io/api/v0/modules/ShunjunGu/moon-trust` returned `404`
  (unregistered), and registry searches for `moon-trust`,
  `trust layer`, `trusted evidence`, `retrieval trust`, and `evidence layer`
  found no package that combines retrieval-candidate risk scanning, trust
  scoring, cross-document conflict detection, and citation-context assembly.
  Adjacent packages exist but do not implement this layer:
  `starlittle/MoonEvidence` verifies evidence *packs* (manifests, digests,
  Merkle proofs, provenance), and `cjyhjy/contextguard` validates extractive
  evidence in bounded tool-output formats.
- The name deliberately avoids the semantic conflict with
  `starlittle/MoonEvidence`: this package does not verify packed evidence, and
  `MoonEvidence` does not score retrieval candidates, detect cross-document
  conflicts, scan for injected instructions, or assemble a citation context.
- CI matrix: `.github/workflows/ci.yml` covers native / wasm / wasm-gc / js for
  the library, native CLI on Linux/macOS/Windows, and a coverage artifact job.

## License

Apache-2.0. The full text is in [LICENSE](LICENSE) and the SPDX identifier is
declared in `moon.mod`.
