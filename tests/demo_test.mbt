// Black-box tests for the acceptance demo through the public library API:
// the fixed corpus is compared as a raw retrieval feed (no trust layer)
// against the full pipeline (risk isolation, conflicts, trust rerank,
// budgeted context).

///|
// The demo report for one embedded corpus, with a fixed query.
fn demo_of(text : String) -> @src.DemoReport raise {
  @src.demo_report("demo", decode(text).candidates)
}

///|
// The report as its JSON bytes — the machine-readable artifact.
fn demo_json(report : @src.DemoReport) -> String {
  report.to_json().stringify()
}

///|
// A comma-joined id list, so order assertions stay readable.
fn ids(values : Array[String]) -> String {
  values.join(",")
}

///|
test "demo baseline is the raw retrieval feed with unsafe blocks exposed" {
  let report = demo_of(DEMO)
  assert_eq(report.query, "demo")
  assert_eq(report.corpus_size, 11)
  assert_eq(report.policy, @src.RiskPolicy::Drop)
  assert_eq(
    ids(report.baseline.order),
    "inj-override,inj-role,inj-hidden,inj-delimiter,inj-payload,low-trust,fact-a,fact-b,benign-imperative,high-trust,benign-doc",
  )
  assert_eq(report.baseline.unsafe_blocks, 5)
  assert_eq(report.baseline.high_severity_findings, 6)
  assert_eq(report.baseline.risk_findings, 9)
}

///|
test "demo trusted run quarantines every high-risk block" {
  let report = demo_of(DEMO)
  assert_eq(report.trusted.quarantined_count, 5)
  assert_eq(
    ids(report.trusted.quarantined_ids),
    "inj-override,inj-role,inj-hidden,inj-delimiter,inj-payload",
  )
  assert_eq(report.trusted.unsafe_blocks, 0)
  assert_eq(report.trusted.high_severity_findings, 0)
  assert_eq(report.trusted.risk_findings, 1)
  assert_eq(report.trusted.blocked, true)
  assert_eq(
    ids(report.trusted.order),
    "benign-imperative,high-trust,benign-doc,low-trust,fact-a,fact-b",
  )
  assert_eq(report.trusted.context.included_count, 6)
  assert_eq(report.trusted.context.truncated, false)
  assert_true(
    report.trusted.context.estimated_tokens <= report.trusted.context.budget,
  )
}

///|
test "demo comparison covers exposure, conflicts, interception, and ranking" {
  let report = demo_of(DEMO)
  let comparison = report.comparison
  assert_eq(comparison.unsafe_blocks_exposed.before, 5)
  assert_eq(comparison.unsafe_blocks_exposed.after, 0)
  assert_eq(comparison.unsafe_blocks_exposed.delta, -5)
  assert_eq(comparison.conflict_pairs.before, 0)
  assert_eq(comparison.conflict_pairs.after, 2)
  assert_eq(comparison.conflict_pairs.delta, 2)
  assert_eq(comparison.injections_intercepted.before, 0)
  assert_eq(comparison.injections_intercepted.after, 5)
  assert_eq(comparison.injections_intercepted.delta, 5)
  assert_eq(comparison.ranking_changes.length(), 6)
  let first = comparison.ranking_changes[0]
  assert_eq(first.id, "benign-imperative")
  assert_eq(first.before_rank, 9)
  assert_eq(first.after_rank, 1)
  assert_eq(first.delta, 8)
  let last = comparison.ranking_changes[5]
  assert_eq(last.id, "fact-b")
  assert_eq(last.before_rank, 8)
  assert_eq(last.after_rank, 6)
  assert_eq(last.delta, 2)
}

///|
test "demo ranking changes are consistent with both orders" {
  let report = demo_of(DEMO)
  let changes = report.comparison.ranking_changes
  let mut cursor = 0
  for change in changes {
    assert_eq(report.baseline.order[change.before_rank - 1], change.id)
    assert_eq(report.trusted.order[change.after_rank - 1], change.id)
    assert_eq(change.delta, change.before_rank - change.after_rank)
    assert_true(change.delta != 0)
    // Changes are ordered by the trusted rank, ascending.
    if cursor > 0 {
      assert_true(changes[cursor - 1].after_rank < change.after_rank)
    }
    cursor = cursor + 1
  }
}

///|
test "demo on a clean corpus reports no intervention" {
  let report = demo_of(MULTI)
  assert_eq(report.corpus_size, 3)
  assert_eq(report.baseline.unsafe_blocks, 0)
  assert_eq(report.trusted.quarantined_count, 0)
  assert_eq(report.trusted.conflicts, 0)
  assert_eq(report.trusted.blocked, false)
  assert_eq(report.comparison.ranking_changes.length(), 0)
  assert_eq(ids(report.trusted.order), ids(report.baseline.order))
}

///|
test "demo on an empty corpus is a valid zero comparison" {
  let report = demo_of(EMPTY)
  assert_eq(report.corpus_size, 0)
  assert_eq(report.baseline.order.length(), 0)
  assert_eq(report.trusted.order.length(), 0)
  assert_eq(report.comparison.ranking_changes.length(), 0)
  assert_eq(report.comparison.unsafe_blocks_exposed.delta, 0)
  assert_eq(report.comparison.conflict_pairs.delta, 0)
  assert_eq(report.comparison.injections_intercepted.delta, 0)
}

///|
test "demo output is byte-identical across repeated runs" {
  let first = demo_json(demo_of(DEMO))
  let second = demo_json(demo_of(DEMO))
  assert_eq(first, second)
  assert_true(first.contains("\"comparison\":{"))
  assert_true(
    first.contains(
      "\"unsafe_blocks_exposed\":{\"before\":5,\"after\":0,\"delta\":-5}",
    ),
  )
  assert_true(
    first.contains("\"conflict_pairs\":{\"before\":0,\"after\":2,\"delta\":2}"),
  )
  assert_true(
    first.contains(
      "\"injections_intercepted\":{\"before\":0,\"after\":5,\"delta\":5}",
    ),
  )
}

///|
test "demo metrics agree with the underlying scan report" {
  let candidates = decode(DEMO).candidates
  let report = @src.demo_report("demo", candidates)
  let scan = @src.scan(
    "demo",
    {
      ..@src.ScanConfig::default(),
      risk_policy: Some(@src.RiskPolicy::Drop),
      block_on_high: Some(true),
    },
    candidates,
  )
  assert_eq(report.trusted.conflicts, scan.conflicts.length())
  assert_eq(report.trusted.quarantined_count, scan.quarantined.length())
  assert_eq(report.trusted.order.length(), scan.evidence.length())
  assert_eq(
    report.trusted.context.estimated_tokens,
    scan.context.estimated_tokens,
  )
  assert_eq(report.trusted.blocked, scan.blocked)
}
