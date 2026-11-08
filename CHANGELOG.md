# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-11-08

Documentation-only patch for the first public release.

### Fixed

- Link the changelog to the mooncakes package page instead of a GitHub release
  tag that was never created.
- Clarify that consumers import the library package
  `ShunjunGu/moon-trust/src`, not the module name.
- Clarify that the registry `404` check describes the pre-publication state.

## [0.1.0] - 2026-11-08

First public release.

### Added

- Deterministic candidate contract (`Candidate`, `SourceMeta`, `Span`) with JSON
  decoding, independent of any retriever.
- Risk scan over a fixed rule set (instruction overrides, role markers, hidden
  code points, encoded payloads, exfiltration phrases, delimiter escapes), with
  rule id, severity, UTF-16 span, and explanation per finding.
- Isolation policies `downrank` (default), `mark`, and `drop`, plus the
  `block_on_high` report flag and CLI exit code `3`.
- Explainable trust score in `[0, 1]` with a per-signal breakdown (metadata,
  source type, length, template ratio, consistency, applied risk factor).
- Cross-document conflict detection over `(subject, unit, value)` claims,
  covering numbers, multipliers, percentages, and dates; every pair is reported
  with both sides and a back-reference from each evidence entry.
- Trust-aware reranking: batch-normalized retrieval score + weighted trust score
  − conflict penalty, with stable ties by id and input order.
- Budgeted evidence-context assembly with `[n]` citation markers, citation
  table, escaped untrusted text, and risk/conflict appendices.
- Native `scan` CLI and the `demo` subcommand that measures the same fixed
  corpus with and without the trust layer.
- Library API (`ScanConfig`, `scan`, `parse_candidates`) usable on native,
  wasm, wasm-gc, and js targets.
- Two runnable examples: `examples/quickstart` and
  `examples/injection-triage`.
- CI matrix across native, wasm, wasm-gc, and js, plus a native CLI job on
  Linux, macOS, and Windows and a coverage artifact job.
- Apache-2.0 license, `.moonignore` publishing rules, and this changelog.

[0.1.1]: https://mooncakes.io/docs/ShunjunGu/moon-trust
[0.1.0]: https://mooncakes.io/docs/ShunjunGu/moon-trust
