# moon-trust

A **deterministic trusted-evidence layer** between retrievers and generators: every scan turns an untrusted retrieval feed into a single-line, JSON-serializable report — snapshot of the query and config, risk findings per block, explicit cross-document conflicts, quarantine audit trail, evidence re-ranked by retrieval score plus an explainable trust score minus conflict penalties, and diagnostics — and two runs on identical inputs produce **byte-identical** output.

## Install

Requires the [MoonBit](https://www.moonbitlang.com) toolchain (`moon`):

- *nix: `curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash`
- Windows: `irm https://cli.moonbitlang.com/install/powershell.ps1 | iex`

Then, from the repository root:

```console
$ moon update
$ moon build --target native
```

## Scan CLI

The native binary lives under `_build/native/debug/build/cmd/main/main.exe`:

```console
$ _build/native/debug/build/cmd/main/main.exe scan hello tests/fixtures/multi.json
{"query":"hello","config":{},"evidence":[{"id":"t1","text":"first","source":{"uri":"https://example.com/a","title":"Doc A","fetched_at":"2026-11-01T00:00:00Z"},"retrieval_score":0.95,"span":{"start":0,"end":12},"risk_findings":[],"conflict_ids":[],"conflict_penalty":0,"rerank_score":1.7416666666666667,"trust":{"score":0.7916666666666667,"breakdown":{"source_score":0.875,"content_score":0.7083333333333334,"metadata":0.75,"source_type":1,"length":0.125,"template_ratio":0,"consistency":1,"risk":1}}},{"id":"a2","text":"second","source":{"uri":"s3://bucket/b","title":"Doc B","fetched_at":"2026-11-02T00:00:00Z","hint":"curated"},"retrieval_score":0.8,"risk_findings":[],"conflict_ids":[],"conflict_penalty":0,"rerank_score":1.6083333333333334,"trust":{"score":0.8083333333333333,"breakdown":{"source_score":0.9,"content_score":0.7166666666666667,"metadata":1,"source_type":0.8,"length":0.15,"template_ratio":0,"consistency":1,"risk":1}}},{"id":"b2","text":"third","source":{"uri":"file:///c/d.txt","title":"Doc C","fetched_at":"2026-11-03T00:00:00Z"},"retrieval_score":0.4,"risk_findings":[],"conflict_ids":[],"conflict_penalty":0,"rerank_score":1.0416666666666665,"trust":{"score":0.6416666666666666,"breakdown":{"source_score":0.575,"content_score":0.7083333333333334,"metadata":0.75,"source_type":0.4,"length":0.125,"template_ratio":0,"consistency":1,"risk":1}}}],"conflicts":[],"quarantined":[],"blocked":false,"diagnostics":{"candidate_count":3,"duplicate_id_count":0,"unknown_rule_ids":[],"risk_finding_count":0,"quarantined_count":0,"conflict_count":0,"output_count":3,"stages":[{"name":"ingest","count":3},{"name":"dedupe","count":3},{"name":"risk","count":0},{"name":"isolate","count":3},{"name":"conflict","count":0},{"name":"sort","count":3},{"name":"topk","count":3}]}}
```

Evidence is ordered by `rerank_score = retrieval_score + trust_weight × trust.score − conflict_penalty` (descending), with ties broken by id ascending. Trust is an explainable heuristic in `[0, 1]`: it blends source signals (metadata completeness, URI scheme) with content signals (length, raw template-marker share, cross-document consistency), then multiplies by the risk factor reported as `trust.breakdown.risk`. The two provenance/content weights default to 0.5/0.5, `trust_weight` defaults to 1.0, and `conflict_weight` defaults to 0.5; library callers can override them via `ScanConfig`, and non-finite values fall back to those defaults.

Optional flags:

- `--top-k N` truncates to the N highest-scored evidence items after the rerank sort. `top_k` applies to `evidence` only; the `quarantined` audit trail is never truncated.
- `--policy drop|mark|downrank` selects the isolation policy (default `downrank`).
- `--block-on-high` sets `blocked: true` and makes the CLI exit `3` when any high-severity finding exists — including findings on blocks the drop policy removed.
- `--risk-weight W` scales the risk penalty with a positive finite number (default `1.0`; `0` is rejected).
- `--conflict-weight W` scales the per-conflict rerank penalty with a non-negative finite number (default `0.5`; `0` disables the extra rerank penalty but keeps the consistency signal).

```console
$ _build/native/debug/build/cmd/main/main.exe scan hello tests/fixtures/injected.json --policy drop --block-on-high
$ echo $?
3
```

Exit codes: `0` success, `1` usage error or malformed candidates file, `2` candidates file cannot be read, `3` blocked scan (report still printed on stdout). Errors and the usage line are printed on stdout; stderr is always empty. The candidates file is JSON encoding of a list of evidence entries (`{id, text, source:{uri, title?, fetched_at, hint?}, retrieval_score, span?}`); each run is filesystem-free — determinism comes from the inputs, never from wall-clock time or randomness.

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

`diagnostics` reports `risk_finding_count` (all findings), `quarantined_count`, `conflict_count` (explicit pairs), `output_count`, and `unknown_rule_ids`. The stage counters are `ingest` (input candidates), `dedupe` (kept after id dedupe), `risk` (blocks with at least one finding), `isolate` (blocks surviving the policy), `conflict` (reported pairs), `sort` (ranked evidence), and `topk` (evidence after truncation).

### 误报与边界

The rule set is an inspectable heuristic, not a classifier. Known boundaries:

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
- **Pairing is quadratic.** Claims in one `(subject, unit)` group pair pairwise; a large candidate set with many distinct values produces O(n²) conflict entries. Keep candidate sets to retrieval-sized top-k.
- **Ambiguous units are skipped.** `in` (inch) is not recognized because it is usually a preposition; `M` is not a multiplier because it collides with meters. Spell out `million`.
- **Numbers inside words are ignored** (`abc123`), and bare numbers without a key or unit are not claims.
- **Malformed dates are skipped** when a four-digit year is followed by `-`, `/`, or `年`; `2024.13.40` is a known exception because `.` is also a sentence boundary.
- **Chinese copulas are heuristic.** `为` and `是` inside compounds can produce a short or wrong key; prefer explicit colons in Chinese text.
- **Chinese/English only.** Other date formats and languages are out of scope; spans count UTF-16 code units and map back through normalization.

## Library

The scan core (`src/`) is a pure library usable from any MoonBit CLI or FFI target (native / wasm-gc / js) — only `cmd/main` touches the filesystem. Import as `ShunjunGu/moon-trust`.

```moonbit
let report = @src.scan(
  "hello",
  { ..@src.ScanConfig::default(), risk_policy: Some(@src.RiskPolicy::Drop) },
  candidates,
)
```

## Tests

```console
$ moon test --target all
Total tests: 85, passed: 85, failed: 0.
```

## License

Apache-2.0 (see `moon.mod`).
