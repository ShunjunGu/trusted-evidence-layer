// Black-box tests for retrieval-score normalization through the public scan
// API. A batch already inside [0, 1] is used as-is; any other batch is
// min-max normalized per scan.

///|
fn norm_candidate(id : String, score : Double) -> @src.Candidate {
  {
    id,
    text: "a plain paragraph with enough body text to score consistently",
    source: {
      uri: "https://example.com/x",
      title: "T",
      fetched_at: "2026-11-05T00:00:00Z",
      hint: None,
    },
    retrieval_score: score,
    span: None,
  }
}

///|
test "retrieval scores inside [0, 1] are used as-is" {
  let report = @src.scan("q", @src.ScanConfig::default(), [
    norm_candidate("a", 0.4),
    norm_candidate("b", 0.9),
  ])
  assert_true(near(evidence_by_id(report, "a").retrieval_normalized, 0.4))
  assert_true(near(evidence_by_id(report, "b").retrieval_normalized, 0.9))
}

///|
test "BM25-style scores are min-max normalized per batch" {
  let report = @src.scan("q", @src.ScanConfig::default(), [
    norm_candidate("a", 10.0),
    norm_candidate("b", 20.0),
  ])
  assert_true(near(evidence_by_id(report, "a").retrieval_normalized, 0.0))
  assert_true(near(evidence_by_id(report, "b").retrieval_normalized, 1.0))
  // The raw score stays available for audit.
  assert_true(near(evidence_by_id(report, "a").retrieval_score, 10.0))
}

///|
test "equal scores outside [0, 1] normalize to 0.5" {
  let report = @src.scan("q", @src.ScanConfig::default(), [
    norm_candidate("a", 7.0),
    norm_candidate("b", 7.0),
  ])
  assert_true(near(evidence_by_id(report, "a").retrieval_normalized, 0.5))
}

///|
test "negative scores are min-max normalized rather than clamped" {
  let report = @src.scan("q", @src.ScanConfig::default(), [
    norm_candidate("a", -2.0),
    norm_candidate("b", 2.0),
  ])
  assert_true(near(evidence_by_id(report, "a").retrieval_normalized, 0.0))
  assert_true(near(evidence_by_id(report, "b").retrieval_normalized, 1.0))
}
