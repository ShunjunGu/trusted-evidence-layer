// Deterministic acceptance demo: one fixed corpus measured twice — as a raw
// retrieval feed (no trust layer) and through the full pipeline (risk
// isolation, conflict detection, trust-aware rerank, budgeted context).
//
// The baseline is a counterfactual disclosure, not a second implementation:
// the same rule set inspects the raw feed, so the "unsafe blocks exposed"
// number says what the generator would have received unchecked. Both sides
// are pure functions of the input; the demo adds no clock, randomness, or
// network, so identical candidates always produce identical counts, orders,
// and JSON bytes.

///|
/// One comparison metric: the value before and after the trust layer, plus
/// their difference (`after − before`). `before` is the raw retrieval feed;
/// `after` is the full pipeline.
#derive(ToJson, Eq)
pub(all) struct MetricDelta {
  before : Int32
  after : Int32
  delta : Int32
}

///|
pub extend MetricDelta with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend MetricDelta with Eq::{not_equal, equal}

///|
/// The raw retrieval feed: every candidate in retrieval-score order, with the
/// findings the scanner attributes to it. No dedupe, no isolation, no
/// conflicts, no rerank.
#derive(ToJson, Eq)
pub(all) struct DemoBaseline {
  order : Array[String]
  unsafe_blocks : Int32
  high_severity_findings : Int32
  risk_findings : Int32
}

///|
pub extend DemoBaseline with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend DemoBaseline with Eq::{not_equal, equal}

///|
/// The context accounting carried into the demo summary.
#derive(ToJson, Eq)
pub(all) struct DemoContext {
  budget : Int32
  included_count : Int32
  estimated_tokens : Int32
  truncated : Bool
}

///|
pub extend DemoContext with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend DemoContext with Eq::{not_equal, equal}

///|
/// The full-pipeline side: drop policy, high-severity gate, conflict
/// detection, trust rerank, and the budgeted context.
#derive(ToJson, Eq)
pub(all) struct DemoTrusted {
  order : Array[String]
  unsafe_blocks : Int32
  high_severity_findings : Int32
  risk_findings : Int32
  conflicts : Int32
  quarantined_count : Int32
  quarantined_ids : Array[String]
  blocked : Bool
  context : DemoContext
}

///|
pub extend DemoTrusted with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend DemoTrusted with Eq::{not_equal, equal}

///|
/// One block whose rank differs between the raw feed and the trusted run.
/// `delta = before_rank − after_rank`, so a positive delta means the block
/// moved up.
#derive(ToJson, Eq)
pub(all) struct RankChange {
  id : String
  before_rank : Int32
  after_rank : Int32
  delta : Int32
}

///|
pub extend RankChange with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend RankChange with Eq::{not_equal, equal}

///|
/// The headline comparison. Ranking changes are ordered by `after_rank`
/// ascending (the trusted order); dropped blocks are excluded because the raw
/// feed's rank has no counterpart in the evidence list.
#derive(ToJson, Eq)
pub(all) struct DemoComparison {
  unsafe_blocks_exposed : MetricDelta
  conflict_pairs : MetricDelta
  injections_intercepted : MetricDelta
  ranking_changes : Array[RankChange]
}

///|
pub extend DemoComparison with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend DemoComparison with Eq::{not_equal, equal}

///|
/// The acceptance-demo report: the fixed corpus measured with and without the
/// trust layer, plus the machine-readable comparison a CI job can archive.
/// `policy` is the isolation policy the trusted side actually applied.
#derive(ToJson, Eq)
pub(all) struct DemoReport {
  query : String
  corpus_size : Int32
  policy : RiskPolicy
  baseline : DemoBaseline
  trusted : DemoTrusted
  comparison : DemoComparison
}

///|
pub extend DemoReport with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend DemoReport with Eq::{not_equal, equal}

///|
/// Run the acceptance comparison over one corpus. The trusted side uses the
/// drop policy and turns on the high-severity gate; every other knob keeps its
/// documented default, so the run is reproducible without configuration.
pub fn demo_report(query : String, candidates : Array[Candidate]) -> DemoReport {
  let policy = RiskPolicy::Drop
  let baseline = build_baseline(candidates)
  let report = scan(
    query,
    {
      ..ScanConfig::default(),
      risk_policy: Some(policy),
      block_on_high: Some(true),
    },
    candidates,
  )
  let trusted = trusted_of(report)
  {
    query,
    corpus_size: candidates.length(),
    policy,
    baseline,
    trusted,
    comparison: compare(baseline, trusted),
  }
}

///|
/// A raw-feed entry: the candidate, its original position, its finite
/// retrieval score, and the findings the same rule set reports for it.
priv struct BaselineEntry {
  candidate : Candidate
  index : Int32
  score : Double
  findings : Array[RiskFinding]
}

///|
/// The finding counts shared by both sides of the comparison.
priv struct FindingTally {
  unsafe_blocks : Int32
  high_severity_findings : Int32
  risk_findings : Int32
}

///|
/// Count blocks with at least one high-severity finding, plus all findings and
/// their high-severity subset. One implementation, so the baseline and trusted
/// numbers cannot drift apart.
fn tally_findings(blocks : Array[Array[RiskFinding]]) -> FindingTally {
  let mut unsafe_blocks = 0
  let mut high_severity_findings = 0
  let mut risk_findings = 0
  for findings in blocks {
    if has_high_severity(findings) {
      unsafe_blocks = unsafe_blocks + 1
    }
    for finding in findings {
      risk_findings = risk_findings + 1
      if finding.severity == RiskSeverity::High {
        high_severity_findings = high_severity_findings + 1
      }
    }
  }
  { unsafe_blocks, high_severity_findings, risk_findings, }
}

///|
/// The raw retrieval feed in retrieval-score descending order, ties broken by
/// id then original input position. Every candidate is counted, including
/// duplicate ids: the feed is what the retriever returned.
fn build_baseline(candidates : Array[Candidate]) -> DemoBaseline {
  let rules = make_rule_set()
  let entries : Array[BaselineEntry] = []
  for index, candidate in candidates {
    entries.push({
      candidate,
      index,
      score: finite_or(candidate.retrieval_score, 0.0),
      findings: scan_risk_text(candidate.text, rules, None),
    })
  }
  let ordered = order_baseline(entries)
  let order : Array[String] = []
  let blocks : Array[Array[RiskFinding]] = []
  for entry in ordered {
    order.push(entry.candidate.id)
    blocks.push(entry.findings)
  }
  let tally = tally_findings(blocks)
  {
    order,
    unsafe_blocks: tally.unsafe_blocks,
    high_severity_findings: tally.high_severity_findings,
    risk_findings: tally.risk_findings,
  }
}

///|
/// Deterministic selection sort over a shallow copy, so the caller's array is
/// untouched.
fn order_baseline(entries : Array[BaselineEntry]) -> Array[BaselineEntry] {
  let working = entries.copy()
  for target in 0..<working.length() {
    let mut best = target
    for probe in (target + 1)..<working.length() {
      if baseline_before(working[probe], working[best]) {
        best = probe
      }
    }
    let winner = working[best]
    working[best] = working[target]
    working[target] = winner
  }
  working
}

///|
/// Retrieval score descending, then id ascending, then input order.
fn baseline_before(first : BaselineEntry, second : BaselineEntry) -> Bool {
  if first.score > second.score {
    return true
  }
  if first.score < second.score {
    return false
  }
  if first.candidate.id < second.candidate.id {
    return true
  }
  if first.candidate.id > second.candidate.id {
    return false
  }
  first.index < second.index
}

///|
/// Project the trusted scan into the demo summary.
fn trusted_of(report : ScanReport) -> DemoTrusted {
  let order : Array[String] = []
  let blocks : Array[Array[RiskFinding]] = []
  for evidence in report.evidence {
    order.push(evidence.id)
    blocks.push(evidence.risk_findings)
  }
  let tally = tally_findings(blocks)
  let quarantined_ids : Array[String] = []
  for block in report.quarantined {
    quarantined_ids.push(block.id)
  }
  {
    order,
    unsafe_blocks: tally.unsafe_blocks,
    high_severity_findings: tally.high_severity_findings,
    risk_findings: tally.risk_findings,
    conflicts: report.conflicts.length(),
    quarantined_count: report.quarantined.length(),
    quarantined_ids,
    blocked: report.blocked,
    context: {
      budget: report.context.budget,
      included_count: report.context.included_count,
      estimated_tokens: report.context.estimated_tokens,
      truncated: report.context.truncated,
    },
  }
}

///|
/// Pair the two sides into the headline comparison. Ranking changes are
/// emitted in trusted order, so they are already sorted by `after_rank` and
/// unique per id.
fn compare(baseline : DemoBaseline, trusted : DemoTrusted) -> DemoComparison {
  let changes : Array[RankChange] = []
  for after_index, id in trusted.order {
    match baseline_rank(baseline.order, id) {
      Some(before_rank) => {
        let after_rank = after_index + 1
        if before_rank != after_rank {
          changes.push({
            id,
            before_rank,
            after_rank,
            delta: before_rank - after_rank,
          })
        }
      }
      None => ()
    }
  }
  {
    unsafe_blocks_exposed: metric(baseline.unsafe_blocks, trusted.unsafe_blocks),
    conflict_pairs: metric(0, trusted.conflicts),
    injections_intercepted: metric(0, trusted.quarantined_count),
    ranking_changes: changes,
  }
}

///|
/// The 1-based first position of `id` in the raw feed, or None.
fn baseline_rank(ids : Array[String], id : String) -> Int32? {
  let mut index = 0
  while index < ids.length() {
    if ids[index] == id {
      return Some(index + 1)
    }
    index = index + 1
  }
  None
}

///|
/// One metric pair with its difference.
fn metric(before : Int32, after : Int32) -> MetricDelta {
  { before, after, delta: after - before, }
}

///|
/// Whether any finding in the list is high severity.
fn has_high_severity(findings : Array[RiskFinding]) -> Bool {
  match highest_severity(findings) {
    Some(RiskSeverity::High) => true
    _ => false
  }
}
