// Quick start: run the trust layer over three candidates and print the
// reranked evidence plus the generator-ready context. The example is
// self-checking: a high-retrieval but thin source must not outrank complete,
// curated sources.

///|
/// Build a candidate with complete provenance; `hint` is an optional trust
/// annotation.
fn candidate(
  id : String,
  text : String,
  uri : String,
  title : String,
  fetched_at : String,
  hint : String?,
  score : Double,
) -> @src.Candidate {
  {
    id,
    text,
    source: { uri, title, fetched_at, hint, },
    retrieval_score: score,
    span: None,
  }
}

///|
/// Pad `text` with spaces on the right to `width`.
fn pad_right(text : String, width : Int32) -> String {
  let mut out = text
  while out.length() < width {
    out = out + " "
  }
  out
}

///|
/// Round a score in [0, 1] to four decimal places for the summary table.
fn fixed4(value : Double) -> String {
  let scaled = (value * 10000.0 + 0.5).to_int()
  let whole = scaled / 10000
  let mut fraction = "\{scaled % 10000}"
  while fraction.length() < 4 {
    fraction = "0" + fraction
  }
  "\{whole}." + fraction
}

///|
fn main raise {
  let candidates : Array[@src.Candidate] = [
    candidate(
      "handbook",
      "Expense reports are due within 30 days of travel.",
      "https://intranet.example.com/handbook",
      "Travel Handbook",
      "2026-11-01T00:00:00Z",
      None,
      0.7,
    ),
    candidate(
      "curated",
      "Expense reports are due within 30 days of travel.",
      "s3://knowledge/expenses.md",
      "Expenses Policy",
      "2026-11-02T00:00:00Z",
      Some("curated"),
      0.7,
    ),
    candidate(
      "short-mirror",
      "short",
      "file:///tmp/mirror.txt",
      "",
      "",
      None,
      0.95,
    ),
  ]
  let report = @src.scan(
    "expense deadline",
    @src.ScanConfig::default(),
    candidates,
  )
  println("moon-trust quickstart")
  println("query: \{report.query}")
  println("")
  println("rank  id             retrieval  trust     rerank")
  for index, evidence in report.evidence {
    println(
      "\{index + 1}     " +
      pad_right(evidence.id, 15) +
      "  " +
      pad_right(fixed4(evidence.retrieval_score), 9) +
      "  " +
      pad_right(fixed4(evidence.trust.score), 8) +
      "  " +
      fixed4(evidence.rerank_score),
    )
  }
  println("")
  println(
    "context: \{report.context.included_count} blocks, " +
    "\{report.context.estimated_tokens} tokens / budget " +
    "\{report.context.budget}",
  )
  println(report.context.text)
  println("")
  println("citations:")
  for citation in report.context.citations {
    println(
      "  [\{citation.index}] \{citation.evidence_id} -> " + citation.source.uri,
    )
  }
  // The curated, complete source wins; the thin, high-retrieval mirror loses.
  assert_eq(report.evidence[0].id, "curated")
  assert_eq(report.evidence[report.evidence.length() - 1].id, "short-mirror")
}
