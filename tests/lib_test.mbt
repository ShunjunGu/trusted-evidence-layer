// Black-box tests for the src library through its public API only
// (parse_candidates + scan + the derived ToJson/Eq instances).

///|
// Expands `text` to `CandidateFile raise` with a clear failure message.
fn decode(text : String) -> @src.CandidateFile raise {
  @src.parse_candidates(text)
}

///|
// The report as its JSON bytes — the artifact the CLI prints and the thing
// byte-identity claims are about.
fn render(report : @src.ScanReport) -> String {
  report.to_json().stringify()
}

///|
test "scan output is byte-identical across repeated runs" {
  let first = render(
    @src.scan("hello", { top_k: None, }, decode(MULTI).candidates),
  )
  let second = render(
    @src.scan("hello", { top_k: None, }, decode(MULTI).candidates),
  )
  assert_eq(first, second)
}

///|
test "empty scan output is the frozen skeleton shape" {
  let report = @src.scan("hello", { top_k: None, }, decode(EMPTY).candidates)
  assert_eq(
    render(report),
    "{\"query\":\"hello\",\"config\":{},\"evidence\":[],\"diagnostics\":{\"candidate_count\":0,\"duplicate_id_count\":0,\"output_count\":0,\"stages\":[{\"name\":\"ingest\",\"count\":0},{\"name\":\"dedupe\",\"count\":0},{\"name\":\"sort\",\"count\":0},{\"name\":\"topk\",\"count\":0}]}}",
  )
}

///|
test "single candidate passes through with its metadata intact" {
  let report = @src.scan("hello", { top_k: None, }, decode(SINGLE).candidates)
  assert_eq(report.evidence.length(), 1)
  assert_eq(report.evidence[0].id, "c1")
  assert_eq(report.evidence[0].source.hint == Some("curated"), true)
  assert_eq(report.diagnostics.candidate_count, 1)
  assert_eq(report.diagnostics.output_count, 1)
  assert_eq(report.diagnostics.duplicate_id_count, 0)
}

///|
test "duplicate ids keep the first occurrence and drop the later one" {
  let report = @src.scan("hello", { top_k: None, }, decode(DUP).candidates)
  assert_eq(report.evidence.length(), 1)
  assert_eq(report.evidence[0].text, "kept first")
  assert_eq(report.diagnostics.duplicate_id_count, 1)
  assert_eq(report.diagnostics.output_count, 1)
}

///|
test "candidates are ordered score descending then id ascending" {
  let report = @src.scan("hello", { top_k: None, }, decode(MULTI).candidates)
  assert_eq(report.evidence[0].id, "t1")
  assert_eq(report.evidence[1].id, "a2")
  assert_eq(report.evidence[2].id, "b2")
}

///|
test "equal scores tie-break by id ascending then input order" {
  let meta : @src.SourceMeta = {
    uri: "u",
    title: "T",
    fetched_at: "t",
    hint: None,
  }
  let later : @src.Candidate = {
    id: "c-b",
    text: "later",
    source: meta,
    retrieval_score: 0.5,
    span: None,
  }
  let earlier : @src.Candidate = {
    id: "c-a",
    text: "earlier",
    source: meta,
    retrieval_score: 0.5,
    span: None,
  }
  // Input puts c-b before c-a; the id tie-break must invert them.
  let report = @src.scan("hello", { top_k: None, }, [later, earlier])
  assert_eq(report.evidence[0].id, "c-a")
  assert_eq(report.evidence[1].id, "c-b")
}

///|
test "missing hint and span keys decode to None" {
  let report = @src.scan("hello", { top_k: None, }, decode(MULTI).candidates)
  // b2 omitted both `hint` and `span`.
  assert_eq(report.evidence[2].source.hint == None, true)
  assert_eq(report.evidence[2].span == None, true)
}

///|
test "top-k truncates deterministic order deterministically" {
  let report = @src.scan("hello", { top_k: Some(2), }, decode(MULTI).candidates)
  assert_eq(report.evidence.length(), 2)
  assert_eq(report.evidence[0].id, "t1")
  assert_eq(report.evidence[1].id, "a2")
  assert_eq(report.diagnostics.output_count, 2)
  assert_eq(report.diagnostics.stages[3].name, "topk")
  assert_eq(report.diagnostics.stages[3].count, 2)
}

///|
test "top-k beyond the evidence count is clamped, zero empties" {
  let big = @src.scan("hello", { top_k: Some(999), }, decode(MULTI).candidates)
  assert_eq(big.evidence.length(), 3)
  let zero = @src.scan("hello", { top_k: Some(0), }, decode(MULTI).candidates)
  assert_eq(zero.evidence.length(), 0)
  assert_eq(zero.diagnostics.output_count, 0)
}

///|
test "the report echoes the query and config it was given" {
  let report = @src.scan(
    "你好 world 混排",
    { top_k: Some(2), },
    decode(MULTI).candidates,
  )
  assert_eq(report.query, "你好 world 混排")
  assert_eq(report.config == { top_k: Some(2), }, true)
}

///|
test "malformed candidates text is rejected by the decoder" {
  let rejected = try {
    ignore(decode(MALFORMED))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}
