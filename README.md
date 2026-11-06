# moon-trust

A **deterministic trusted-evidence layer** between retrievers and generators: every scan turns an untrusted retrieval feed into a single-line, JSON-serializable report — snapshot of the query and config, the evidence list in canonical (sort-key) order, and diagnostics — and two runs on identical inputs produce **byte-identical** output.

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
{"query":"hello","config":{},"evidence":[{"id":"t1","text":"first","source":{"uri":"https://example.com/a","title":"Doc A","fetched_at":"2026-11-01T00:00:00Z"},"retrieval_score":0.95,"span":{"start":0,"end":12}},{"id":"a2","text":"second","source":{"uri":"s3://bucket/b","title":"Doc B","fetched_at":"2026-11-02T00:00:00Z","hint":"curated"},"retrieval_score":0.8},{"id":"b2","text":"third","source":{"uri":"file:///c/d.txt","title":"Doc C","fetched_at":"2026-11-03T00:00:00Z"},"retrieval_score":0.4}],"diagnostics":{"candidate_count":3,"duplicate_id_count":0,"output_count":3,"stages":[{"name":"ingest","count":3},{"name":"dedupe","count":3},{"name":"sort","count":3},{"name":"topk","count":3}]}}
```

Optional `--top-k N` truncates to the N highest-scored items after the canonical sort:

```console
$ _build/native/debug/build/cmd/main/main.exe scan hello tests/fixtures/multi.json --top-k 2
```

Exit codes: `0` success, `1` usage error or malformed candidates file, `2` candidates file cannot be read. Errors and the usage line are printed on stdout; stderr is always empty. The candidates file is JSON encoding of a list of evidence entries (`{id, text, source:{uri, title?, fetched_at, hint?}, retrieval_score, span?}`); each run is filesystem-free — determinism comes from the inputs, never from wall-clock time or randomness.

## Library

The scan core (`src/`) is a pure library usable from any MoonBit CLI or FFI target (native / wasm-gc / js) — only `cmd/main` touches the filesystem. Import as `ShunjunGu/moon-trust`.

## Tests

```console
$ moon test --target all
Total tests: 26, passed: 26, failed: 0.
```

## License

Apache-2.0 (see `moon.mod`).
