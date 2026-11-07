# moon-trust

A **deterministic trusted-evidence layer** between retrievers and generators: every scan turns an untrusted retrieval feed into a single-line, JSON-serializable report — snapshot of the query and config, risk findings per block, quarantine audit trail, evidence re-ranked by retrieval score plus an explainable trust score, and diagnostics — and two runs on identical inputs produce **byte-identical** output.

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
{"query":"hello","config":{},"evidence":[{"id":"t1","text":"first","source":{"uri":"https://example.com/a","title":"Doc A","fetched_at":"2026-11-01T00:00:00Z"},"retrieval_score":0.95,"span":{"start":0,"end":12},"risk_findings":[],"rerank_score":1.7416666666666667,"trust":{"score":0.7916666666666667,"breakdown":{"source_score":0.875,"content_score":0.7083333333333334,"metadata":0.75,"source_type":1,"length":0.125,"template_ratio":0,"consistency":1,"risk":1}}},{"id":"a2","text":"second","source":{"uri":"s3://bucket/b","title":"Doc B","fetched_at":"2026-11-02T00:00:00Z","hint":"curated"},"retrieval_score":0.8,"risk_findings":[],"rerank_score":1.6083333333333334,"trust":{"score":0.8083333333333333,"breakdown":{"source_score":0.9,"content_score":0.7166666666666667,"metadata":1,"source_type":0.8,"length":0.15,"template_ratio":0,"consistency":1,"risk":1}}},{"id":"b2","text":"third","source":{"uri":"file:///c/d.txt","title":"Doc C","fetched_at":"2026-11-03T00:00:00Z"},"retrieval_score":0.4,"risk_findings":[],"rerank_score":1.0416666666666665,"trust":{"score":0.6416666666666666,"breakdown":{"source_score":0.575,"content_score":0.7083333333333334,"metadata":0.75,"source_type":0.4,"length":0.125,"template_ratio":0,"consistency":1,"risk":1}}}],"quarantined":[],"blocked":false,"diagnostics":{"candidate_count":3,"duplicate_id_count":0,"risk_finding_count":0,"quarantined_count":0,"output_count":3,"stages":[{"name":"ingest","count":3},{"name":"dedupe","count":3},{"name":"risk","count":0},{"name":"isolate","count":3},{"name":"sort","count":3},{"name":"topk","count":3}]}}
```

Evidence is ordered by `rerank_score = retrieval_score + trust_weight × trust.score` (descending), with ties broken by id ascending. Trust is an explainable heuristic in `[0, 1]`: it blends source signals (metadata completeness, URI scheme) with content signals (length, raw template-marker share, evidence consistency), then multiplies by the risk factor reported as `trust.breakdown.risk`. The two provenance/content weights default to 0.5/0.5 and `trust_weight` defaults to 1.0; library callers can override them via `ScanConfig`, and non-finite values fall back to those defaults.

Optional flags:

- `--top-k N` truncates to the N highest-scored evidence items after the rerank sort. `top_k` applies to `evidence` only; the `quarantined` audit trail is never truncated.
- `--policy drop|mark|downrank` selects the isolation policy (default `downrank`).
- `--block-on-high` sets `blocked: true` and makes the CLI exit `3` when any high-severity finding exists — including findings on blocks the drop policy removed.
- `--risk-weight W` scales the risk penalty with a non-negative finite number (default `1.0`).

```console
$ _build/native/debug/build/cmd/main/main.exe scan hello tests/fixtures/injected.json --policy drop --block-on-high
$ echo $?
3
```

Exit codes: `0` success, `1` usage error or malformed candidates file, `2` candidates file cannot be read, `3` blocked scan (report still printed on stdout). Errors and the usage line are printed on stdout; stderr is always empty. The candidates file is JSON encoding of a list of evidence entries (`{id, text, source:{uri, title?, fetched_at, hint?}, retrieval_score, span?}`); each run is filesystem-free — determinism comes from the inputs, never from wall-clock time or randomness.

## 风险扫描与隔离

The scan runs a fixed, deterministic rule set over every kept candidate. Each rule contributes **at most one finding** per block, anchored at its earliest match, and findings are sorted by span start then rule id. A finding carries `rule_id`, `severity` (`low` / `medium` / `high`), a half-open UTF-16 code-unit span (the same measure as `text.length()`), and an explanation that includes the matched phrase.

| rule id | severity | signals |
| --- | --- | --- |
| `instruction.override` | high | "ignore previous instructions", "forget all previous", 忽略之前的指令, 覆盖系统指令 |
| `instruction.redirect` | medium | "ignore the above", "disregard the above", 忽略以上内容 |
| `instruction.imperative` | low | "you must", "you should", "please output", 请输出, 请打印 |
| `role.marker` | high | `<\|system\|>`, `<\|user\|>`, `[INST]`, `<<SYS>>` |
| `role.chat-heading` | medium | `### System`, `Human:`, `Assistant:`, 系统提示词 |
| `hidden.zero-width` | high | U+200B, U+200C, U+200D, U+2060, U+FEFF, U+00AD, U+180E |
| `hidden.bidi-control` | high | U+202A–U+202E, U+2066–U+2069 |
| `payload.encoded` | high | `data:text/html`, `base64,`, HTML-entity / percent-encoded zero-width characters, 解码以下 |
| `payload.code-exec` | medium | `atob(`, `eval(`, `unescape(`, `fromCharCode(` |
| `payload.escape-sequence` | medium | `\xHH` and `\uHHHH` escape sequences |
| `exfiltration.secret` | high | "reveal your system prompt", "output your instructions", 泄露密钥 |
| `exfiltration.send` | medium | "send the following", "upload the following", 发送以下 |
| `delimiter.escape` | high | `</system>`, `<\|endoftext\|>`, `[END OF CONTEXT]`, 以下是新的指令 |

Isolation policies:

- **`downrank` (default)** — keep every block, annotate findings, and multiply trust by `1 − clamp(Σ severity_penalty × risk_weight)`. Severity penalties are high `0.5`, medium `0.25`, low `0.1`, so two high findings already zero the trust score. The applied factor is echoed as `trust.breakdown.risk`.
- **`mark`** — keep every block and annotate findings, but do not penalize scores (`risk` stays `1`).
- **`drop`** — remove blocks with at least one high-severity finding. Removed blocks stay auditable in `quarantined` (id, text, source, findings, reason); kept blocks are annotated without a score penalty. Medium and low findings never remove a block.

Library callers can additionally set `enabled_rules: Some([...])` in `ScanConfig` to restrict scanning to specific rule ids; an absent list enables the whole registry.

### 误报与边界

The rule set is an inspectable heuristic, not a classifier. Known boundaries:

- **Ordinary imperatives stay low severity.** "You should consult a doctor…" and "请输出报表" produce `instruction.imperative` (low) and never trigger the drop policy; under the default `downrank` policy they only lose 10% of trust.
- **Code fences are not delimiter escapes.** The delimiter rule targets explicit context-closing tokens (`</system>`, `[END OF CONTEXT]`, …), not Markdown fences or headings.
- **Zero-width joiners in emoji can false-positive.** U+200D is both a legitimate emoji sequence joiner and a concealment channel; it is reported as high severity. Disable the rule via `enabled_rules` if a corpus is emoji-heavy.
- **Opaque payloads without a marker are missed.** A bare base64 blob with no `base64,`/data-URI prefix (or other encoding marker) is not detected.
- **Documentation about these tokens is flagged.** An article that explains `<|system|>`, `base64,`, or `</system>` matches the same rules as an attack, because the scanner has no way to distinguish mention from use. Use `mark` or a restricted `enabled_rules` list when scanning security documentation.
- **Paraphrases and languages beyond Chinese/English are out of scope.** The scan matches fixed phrases and code units; it does not understand intent.
- **Spans count UTF-16 code units.** They are suitable for slicing the original MoonBit `String`, and for astral characters each code point occupies two units.

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
Total tests: 53, passed: 53, failed: 0.
```

## License

Apache-2.0 (see `moon.mod`).
