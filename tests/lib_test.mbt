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
// The count recorded for one named pipeline stage.
fn stage_count(report : @src.ScanReport, name : String) -> Int32 {
  for stage in report.diagnostics.stages {
    if stage.name == name {
      return stage.count
    }
  }
  abort("missing stage: " + name)
}

///|
test "scan output is byte-identical across repeated runs" {
  let first = render(
    @src.scan(
      "hello",
      { ..@src.ScanConfig::default(), top_k: None, },
      decode(MULTI).candidates,
    ),
  )
  let second = render(
    @src.scan(
      "hello",
      { ..@src.ScanConfig::default(), top_k: None, },
      decode(MULTI).candidates,
    ),
  )
  assert_eq(first, second)
}

///|
test "empty scan output is the frozen skeleton shape" {
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: None, },
    decode(EMPTY).candidates,
  )
  assert_eq(
    render(report),
    "{\"query\":\"hello\",\"config\":{},\"evidence\":[],\"context\":{\"budget\":512,\"estimated_tokens\":0,\"truncated\":false,\"included_count\":0,\"omitted_count\":0,\"text\":\"\",\"citations\":[]},\"conflicts\":[],\"quarantined\":[],\"blocked\":false,\"diagnostics\":{\"candidate_count\":0,\"duplicate_id_count\":0,\"unknown_rule_ids\":[],\"risk_finding_count\":0,\"quarantined_count\":0,\"conflict_count\":0,\"conflicts_truncated\":false,\"output_count\":0,\"stages\":[{\"name\":\"ingest\",\"count\":0},{\"name\":\"dedupe\",\"count\":0},{\"name\":\"risk\",\"count\":0},{\"name\":\"isolate\",\"count\":0},{\"name\":\"conflict\",\"count\":0},{\"name\":\"sort\",\"count\":0},{\"name\":\"topk\",\"count\":0},{\"name\":\"context\",\"count\":0}]}}",
  )
}

///|
test "single candidate passes through with its metadata intact" {
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: None, },
    decode(SINGLE).candidates,
  )
  assert_eq(report.evidence.length(), 1)
  assert_eq(report.evidence[0].id, "c1")
  assert_eq(report.evidence[0].source.hint == Some("curated"), true)
  assert_eq(report.diagnostics.candidate_count, 1)
  assert_eq(report.diagnostics.output_count, 1)
  assert_eq(report.diagnostics.duplicate_id_count, 0)
}

///|
test "duplicate ids keep the first occurrence and drop the later one" {
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: None, },
    decode(DUP).candidates,
  )
  assert_eq(report.evidence.length(), 1)
  assert_eq(report.evidence[0].text, "kept first")
  assert_eq(report.diagnostics.duplicate_id_count, 1)
  assert_eq(report.diagnostics.output_count, 1)
}

///|
test "candidates are ordered score descending then id ascending" {
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: None, },
    decode(MULTI).candidates,
  )
  assert_eq(report.evidence[0].id, "t1")
  assert_eq(report.evidence[1].id, "a2")
  assert_eq(report.evidence[2].id, "b2")
}

///|
test "equal rerank scores tie-break by id ascending then input order" {
  let meta : @src.SourceMeta = {
    uri: "u",
    title: "T",
    fetched_at: "t",
    hint: None,
  }
  let later : @src.Candidate = {
    id: "c-b",
    text: "bravo",
    source: meta,
    retrieval_score: 0.5,
    span: None,
  }
  let earlier : @src.Candidate = {
    id: "c-a",
    text: "alpha",
    source: meta,
    retrieval_score: 0.5,
    span: None,
  }
  // Equal-length texts keep length, template, and language signals equal,
  // so the trust scores — and therefore the rerank scores — truly tie.
  // Input puts c-b before c-a; the id tie-break must invert them.
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: None, },
    [later, earlier],
  )
  assert_eq(report.evidence[0].rerank_score, report.evidence[1].rerank_score)
  assert_eq(report.evidence[0].id, "c-a")
  assert_eq(report.evidence[1].id, "c-b")
}

///|
test "missing hint and span keys decode to None" {
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: None, },
    decode(MULTI).candidates,
  )
  // b2 omitted both `hint` and `span`.
  assert_eq(report.evidence[2].source.hint == None, true)
  assert_eq(report.evidence[2].span == None, true)
}

///|
test "top-k truncates deterministic order deterministically" {
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: Some(2), },
    decode(MULTI).candidates,
  )
  assert_eq(report.evidence.length(), 2)
  assert_eq(report.evidence[0].id, "t1")
  assert_eq(report.evidence[1].id, "a2")
  assert_eq(report.diagnostics.output_count, 2)
  assert_eq(stage_count(report, "topk"), 2)
}

///|
test "top-k beyond the evidence count is clamped, zero empties" {
  let big = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: Some(999), },
    decode(MULTI).candidates,
  )
  assert_eq(big.evidence.length(), 3)
  let zero = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: Some(0), },
    decode(MULTI).candidates,
  )
  assert_eq(zero.evidence.length(), 0)
  assert_eq(zero.diagnostics.output_count, 0)
}

///|
test "the report echoes the query and config it was given" {
  let report = @src.scan(
    "你好 world 混排",
    { ..@src.ScanConfig::default(), top_k: Some(2), },
    decode(MULTI).candidates,
  )
  assert_eq(report.query, "你好 world 混排")
  assert_eq(
    report.config == { ..@src.ScanConfig::default(), top_k: Some(2), },
    true,
  )
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

///|
// Tolerance for derived Double values checked against worked examples.
fn near(actual : Double, expected : Double) -> Bool {
  let delta = actual - expected
  delta < 1.0e-9 && delta > -1.0e-9
}

///|
test "trust breakdown carries every sub-signal from a worked example" {
  let source : @src.SourceMeta = {
    uri: "https://example.com/x",
    title: "T",
    fetched_at: "2026-11-01T00:00:00Z",
    hint: None,
  }
  let candidate : @src.Candidate = {
    id: "c1",
    text: "abcd",
    source,
    retrieval_score: 0.5,
    span: None,
  }
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: None, },
    [candidate],
  )
  let trust = report.evidence[0].trust
  let breakdown = trust.breakdown
  // Provenance: metadata 3/4 (no hint) and https 1.0 -> source 0.875.
  assert_true(near(breakdown.metadata, 0.75))
  assert_true(near(breakdown.source_type, 1.0))
  assert_true(near(breakdown.source_score, 0.875))
  // Content: length 4/40, no template markers, neutral consistency -> 0.7.
  assert_true(near(breakdown.length, 0.1))
  // Raw marker share, not the inverted cleanliness score.
  assert_true(near(breakdown.template_ratio, 0.0))
  assert_true(near(breakdown.consistency, 1.0))
  assert_true(near(breakdown.content_score, 0.7))
  // Equal default source/content weights -> (0.875 + 0.7) / 2.
  assert_true(near(trust.score, 0.7875))
  // The breakdown is part of the serialized report, not just the struct.
  let json = render(report)
  assert_true(json.contains("\"trust\":{"))
  assert_true(json.contains("\"breakdown\":{"))
}

///|
test "trust score and sub-signals stay within [0, 1] for any candidate shape" {
  let metas : Array[@src.SourceMeta] = [
    { uri: "", title: "", fetched_at: "", hint: None, },
    {
      uri: "https://example.com/a",
      title: "T",
      fetched_at: "2026-11-01T00:00:00Z",
      hint: Some("curated"),
    },
    { uri: "http://example.com/a", title: "", fetched_at: "t", hint: None, },
    { uri: "s3://bucket/key", title: "T", fetched_at: "", hint: Some("h"), },
    { uri: "gs://bucket/key", title: "", fetched_at: "", hint: Some("h"), },
    { uri: "file:///tmp/a.txt", title: "T", fetched_at: "t", hint: None, },
    {
      uri: "ftp://example.com/a",
      title: "T",
      fetched_at: "t",
      hint: Some("h"),
    },
    { uri: "weird://host/a", title: "T", fetched_at: "t", hint: None, },
    { uri: "no-scheme", title: "T", fetched_at: "t", hint: Some("h"), },
  ]
  let texts : Array[String] = [
    "", "<{a}{b}{c}>", "plain text", "你好，世界。这是一段中文内容。",
    "😀 emoji text with surrogate pairs 😀😀", "A curated paragraph with plenty of plain body text verified by the editors.",
  ]
  let candidates : Array[@src.Candidate] = []
  for i, meta in metas {
    for j, text in texts {
      candidates.push({
        id: "c\{i}-\{j}",
        text,
        source: meta,
        retrieval_score: i.to_double() / 3.0,
        span: None,
      })
    }
  }
  // Degenerate weight combinations must not break the invariant either:
  // equal, one-sided, zero-sum, negative, and imbalanced pairs.
  let configs : Array[@src.ScanConfig] = [
    { ..@src.ScanConfig::default(), top_k: None, },
    {
      ..@src.ScanConfig::default(),
      source_weight: Some(1.0),
      content_weight: Some(0.0),
    },
    {
      ..@src.ScanConfig::default(),
      source_weight: Some(0.0),
      content_weight: Some(1.0),
    },
    {
      ..@src.ScanConfig::default(),
      source_weight: Some(0.0),
      content_weight: Some(0.0),
    },
    {
      ..@src.ScanConfig::default(),
      source_weight: Some(-2.0),
      content_weight: Some(1.0),
    },
    {
      ..@src.ScanConfig::default(),
      source_weight: Some(2.0),
      content_weight: Some(-1.0),
    },
    {
      ..@src.ScanConfig::default(),
      source_weight: Some(3.0),
      content_weight: Some(1.0),
    },
    // NaN and infinity must degrade to the deterministic defaults.
    { ..@src.ScanConfig::default(), source_weight: Some(0.0 / 0.0), },
    {
      ..@src.ScanConfig::default(),
      source_weight: Some(1.0 / 0.0),
      content_weight: Some(0.0 / 0.0),
    },
    { ..@src.ScanConfig::default(), trust_weight: Some(1.0 / 0.0), },
  ]
  for config in configs {
    let report = @src.scan("property", config, candidates)
    assert_eq(report.evidence.length(), candidates.length())
    for item in report.evidence {
      let score = item.trust.score
      assert_true(score >= 0.0 && score <= 1.0)
      let breakdown = item.trust.breakdown
      assert_true(breakdown.metadata >= 0.0 && breakdown.metadata <= 1.0)
      assert_true(breakdown.source_type >= 0.0 && breakdown.source_type <= 1.0)
      assert_true(
        breakdown.source_score >= 0.0 && breakdown.source_score <= 1.0,
      )
      assert_true(breakdown.length >= 0.0 && breakdown.length <= 1.0)
      assert_true(
        breakdown.template_ratio >= 0.0 && breakdown.template_ratio <= 1.0,
      )
      assert_true(breakdown.consistency >= 0.0 && breakdown.consistency <= 1.0)
      assert_true(
        breakdown.content_score >= 0.0 && breakdown.content_score <= 1.0,
      )
    }
  }
}

///|
test "a low-quality source ranks below a high-quality one despite a higher retrieval score" {
  let report = @src.scan(
    "hello",
    { ..@src.ScanConfig::default(), top_k: None, },
    decode(QUALITY_GAP).candidates,
  )
  assert_eq(report.evidence.length(), 2)
  assert_eq(report.evidence[0].id, "highq")
  assert_eq(report.evidence[1].id, "lowq")
  // The inversion is real: the winner has the lower retrieval score.
  assert_true(
    report.evidence[0].retrieval_score < report.evidence[1].retrieval_score,
  )
  // lowq's 11 code units carry 8 template markers; highq carries none.
  assert_true(near(report.evidence[0].trust.breakdown.template_ratio, 0.0))
  assert_true(
    near(report.evidence[1].trust.breakdown.template_ratio, 8.0 / 11.0),
  )
}

///|
test "weights are configurable and echoed in the report snapshot" {
  let source : @src.SourceMeta = {
    uri: "https://example.com/x",
    title: "T",
    fetched_at: "2026-11-01T00:00:00Z",
    hint: Some("curated"),
  }
  let good : @src.Candidate = {
    id: "good",
    text: "A curated paragraph with plenty of plain body text verified by the editors.",
    source,
    retrieval_score: 0.5,
    span: None,
  }
  let bad : @src.Candidate = {
    id: "bad",
    text: "<{a}{b}>",
    source,
    retrieval_score: 0.5,
    span: None,
  }
  let candidates = [good, bad]
  let source_only : @src.ScanConfig = {
    ..@src.ScanConfig::default(),
    source_weight: Some(1.0),
    content_weight: Some(0.0),
  }
  let content_only : @src.ScanConfig = {
    ..@src.ScanConfig::default(),
    source_weight: Some(0.0),
    content_weight: Some(1.0),
  }
  let by_source = @src.scan("q", source_only, candidates)
  // Identical provenance under source-only weights: a true rerank tie,
  // decided by id ascending.
  assert_true(near(by_source.evidence[0].trust.score, 1.0))
  assert_true(near(by_source.evidence[1].trust.score, 1.0))
  assert_eq(
    by_source.evidence[0].rerank_score,
    by_source.evidence[1].rerank_score,
  )
  assert_eq(by_source.evidence[0].id, "bad")
  assert_eq(by_source.evidence[1].id, "good")
  let by_content = @src.scan("q", content_only, candidates)
  assert_true(near(by_content.evidence[0].trust.score, 1.0))
  assert_true(near(by_content.evidence[1].trust.score, 0.4))
  assert_eq(by_content.evidence[0].id, "good")
  assert_eq(by_content.evidence[1].id, "bad")
  // The report echoes the exact config snapshot used for the run.
  assert_eq(by_content.config == content_only, true)
}

///|
test "non-finite weights fall back to deterministic defaults" {
  let source : @src.SourceMeta = {
    uri: "https://example.com/x",
    title: "T",
    fetched_at: "2026-11-01T00:00:00Z",
    hint: None,
  }
  let candidate : @src.Candidate = {
    id: "c1",
    text: "abcd",
    source,
    retrieval_score: 0.5,
    span: None,
  }
  let by_nan = @src.scan(
    "q",
    { ..@src.ScanConfig::default(), source_weight: Some(0.0 / 0.0), },
    [candidate],
  )
  // Same numbers as the default-weight worked example.
  assert_true(near(by_nan.evidence[0].trust.score, 0.7875))
  assert_true(near(by_nan.evidence[0].rerank_score, 1.2875))
  let by_inf = @src.scan(
    "q",
    { ..@src.ScanConfig::default(), trust_weight: Some(1.0 / 0.0), },
    [candidate],
  )
  assert_true(near(by_inf.evidence[0].rerank_score, 1.2875))
}

///|
test "unrelated evidence has neutral consistency" {
  let source : @src.SourceMeta = {
    uri: "https://example.com/x",
    title: "T",
    fetched_at: "t",
    hint: None,
  }
  let ascii : @src.Candidate = {
    id: "ascii",
    text: "abcd",
    source,
    retrieval_score: 0.5,
    span: None,
  }
  let cjk : @src.Candidate = {
    id: "cjk",
    text: "你好世界",
    source,
    retrieval_score: 0.5,
    span: None,
  }
  let report = @src.scan("q", { ..@src.ScanConfig::default(), top_k: None, }, [
    ascii, cjk,
  ])
  // Same UTF-16 length and no template markers: only the consistency signal
  // could separate the two, and it must stay neutral (1.0, no penalty).
  assert_true(near(report.evidence[0].trust.breakdown.consistency, 1.0))
  assert_true(near(report.evidence[1].trust.breakdown.consistency, 1.0))
  assert_eq(report.evidence[0].trust.score, report.evidence[1].trust.score)
}
