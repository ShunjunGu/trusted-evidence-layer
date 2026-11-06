// Fixture candidates as embedded JSON strings (the same shapes as the real
// files under tests/fixtures/). Single-line escaped constants keep the
// package compilable on every target — tests never touch the filesystem so
// they run unchanged for native, wasm-gc, and js.

///|
// Three candidates in non-sorted input order. Expected evidence order:
// t1 (0.95, span 0..12, no hint) > a2 (0.8, hint "curated") > b2 (0.4, no
// hint and no span keys — exercises missing-Option decoding).
const MULTI : String = "{\"candidates\":[{\"id\":\"t1\",\"text\":\"first\",\"source\":{\"uri\":\"https://example.com/a\",\"title\":\"Doc A\",\"fetched_at\":\"2026-11-01T00:00:00Z\"},\"retrieval_score\":0.95,\"span\":{\"start\":0,\"end\":12}},{\"id\":\"a2\",\"text\":\"second\",\"source\":{\"uri\":\"s3://bucket/b\",\"title\":\"Doc B\",\"fetched_at\":\"2026-11-02T00:00:00Z\",\"hint\":\"curated\"},\"retrieval_score\":0.8},{\"id\":\"b2\",\"text\":\"third\",\"source\":{\"uri\":\"file:///c/d.txt\",\"title\":\"Doc C\",\"fetched_at\":\"2026-11-03T00:00:00Z\"},\"retrieval_score\":0.4}]}"

///|
// Two candidates sharing id c1: the first occurrence (0.8) must win and the
// second (0.5) must be dropped with duplicate_id_count = 1.
const DUP : String = "{\"candidates\":[{\"id\":\"c1\",\"text\":\"kept first\",\"source\":{\"uri\":\"u1\",\"title\":\"T\",\"fetched_at\":\"t1\"},\"retrieval_score\":0.8},{\"id\":\"c1\",\"text\":\"dropped second\",\"source\":{\"uri\":\"u2\",\"title\":\"T2\",\"fetched_at\":\"t2\"},\"retrieval_score\":0.5}]}"

///|
// Exactly one candidate.
const SINGLE : String = "{\"candidates\":[{\"id\":\"c1\",\"text\":\"only\",\"source\":{\"uri\":\"u\",\"title\":\"T\",\"fetched_at\":\"t\",\"hint\":\"curated\"},\"retrieval_score\":0.8}]}"

///|
// Empty candidate list.
const EMPTY : String = "{\"candidates\": []}"

///|
// Decode failure: a candidate missing its required `source` metadata.
const MALFORMED : String = "{\"candidates\":[{\"id\":\"c1\",\"text\":\"x\",\"retrieval_score\":0.8}]}"
