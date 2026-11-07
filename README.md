# moon-trust

A **deterministic trusted-evidence layer** between retrievers and generators: every scan turns an untrusted retrieval feed into a single-line, JSON-serializable report — snapshot of the query and config, evidence re-ranked by retrieval score plus an explainable trust score, and diagnostics — and two runs on identical inputs produce **byte-identical** output.

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
{"query":"hello","config":{},"evidence":[{"id":"t1","text":"first","source":{"uri":"https://example.com/a","title":"Doc A","fetched_at":"2026-11-01T00:00:00Z"},"retrieval_score":0.95,"span":{"start":0,"end":12},"rerank_score":1.7416666666666667,"trust":{"score":0.7916666666666667,"breakdown":{"source_score":0.875,"content_score":0.7083333333333334,"metadata":0.75,"source_type":1,"length":0.125,"template_ratio":0,"language_consistency":1}}},{"id":"a2","text":"second","source":{"uri":"s3://bucket/b","title":"Doc B","fetched_at":"2026-11-02T00:00:00Z","hint":"curated"},"retrieval_score":0.8,"rerank_score":1.6083333333333334,"trust":{"score":0.8083333333333333,"breakdown":{"source_score":0.9,"content_score":0.7166666666666667,"metadata":1,"source_type":0.8,"length":0.15,"template_ratio":0,"language_consistency":1}}},{"id":"b2","text":"third","source":{"uri":"file:///c/d.txt","title":"Doc C","fetched_at":"2026-11-03T00:00:00Z"},"retrieval_score":0.4,"rerank_score":1.0416666666666665,"trust":{"score":0.6416666666666666,"breakdown":{"source_score":0.575,"content_score":0.7083333333333334,"metadata":0.75,"source_type":0.4,"length":0.125,"template_ratio":0,"language_consistency":1}}}],"diagnostics":{"candidate_count":3,"duplicate_id_count":0,"output_count":3,"stages":[{"name":"ingest","count":3},{"name":"dedupe","count":3},{"name":"sort","count":3},{"name":"topk","count":3}]}}
```

Evidence is ordered by `rerank_score = retrieval_score + trust_weight × trust.score` (descending), with ties broken by id ascending. Trust is an explainable heuristic in `[0, 1]`: it blends source signals (metadata completeness, URI scheme) with content signals (length, raw template-marker share, language consistency) and echoes every sub-signal in `trust.breakdown` (`template_ratio` is the raw share — higher is worse; the other sub-signals are quality scores). The two blend weights default to 0.5/0.5 and `trust_weight` defaults to 1.0; library callers can override all three via `ScanConfig`, and non-finite values fall back to those defaults.

Optional `--top-k N` truncates to the N highest-scored items after the rerank sort:

```console
$ _build/native/debug/build/cmd/main/main.exe scan hello tests/fixtures/multi.json --top-k 2
```

Exit codes: `0` success, `1` usage error or malformed candidates file, `2` candidates file cannot be read. Errors and the usage line are printed on stdout; stderr is always empty. The candidates file is JSON encoding of a list of evidence entries (`{id, text, source:{uri, title?, fetched_at, hint?}, retrieval_score, span?}`); each run is filesystem-free — determinism comes from the inputs, never from wall-clock time or randomness.

## Library

The scan core (`src/`) is a pure library usable from any MoonBit CLI or FFI target (native / wasm-gc / js) — only `cmd/main` touches the filesystem. Import as `ShunjunGu/moon-trust`.

## Tests

```console
$ moon test --target all
Total tests: 32, passed: 32, failed: 0.
```

## License

Apache-2.0 (see `moon.mod`).
