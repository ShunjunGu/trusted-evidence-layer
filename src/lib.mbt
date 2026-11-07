// 候选块契约 + 确定性扫描：信任评分与信任感知重排。

///|
/// A retrievable text chunk with provenance. All fields are part of the
/// public contract; the report echoes them as-is.
#derive(ToJson, FromJson, Eq)
pub(all) struct Candidate {
  id : String
  text : String
  source : SourceMeta
  retrieval_score : Double
  span : Span?
}

///|
/// Source provenance. `fetched_at` is input data only: it is echoed but
/// never generated, so no wall-clock value ever enters the report. `hint`
/// is an optional trust annotation consumed by trust scoring.
#derive(ToJson, FromJson, Eq)
pub(all) struct SourceMeta {
  uri : String
  title : String
  fetched_at : String
  hint : String?
}

///|
/// Optional half-open character span of the chunk in its document.
#derive(ToJson, FromJson, Eq)
pub(all) struct Span {
  start : Int32
  end : Int32
}

///|
/// Decoded shape of a candidate file: an object `{ "candidates": [ ... ] }`.
#derive(FromJson)
pub(all) struct CandidateFile {
  candidates : Array[Candidate]
}

///|
/// Scan configuration. `top_k` optionally truncates the evidence list; the
/// weights steer the trust blend; the risk knobs select the isolation policy,
/// scale its penalty, gate the blocked flag, and restrict the rule set.
/// Every field is optional: absent keys fall back to deterministic defaults,
/// and every absent key is omitted from the echo so a default config still
/// serializes as `{}`.
#derive(ToJson, Eq)
pub(all) struct ScanConfig {
  top_k : Int32?
  source_weight : Double?
  content_weight : Double?
  trust_weight : Double?
  risk_policy : RiskPolicy?
  risk_weight : Double?
  block_on_high : Bool?
  enabled_rules : Array[String]?
}

///|
/// Trust breakdown: the two weighted components plus every sub-signal
/// behind them. Components blend trust; sub-signals only explain it.
/// `template_ratio` is the raw marker share (higher is worse); the other
/// sub-signals are quality signals in [0, 1] (higher is better). `risk` is
/// the factor actually applied to the blend: 1.0 means no penalty (no
/// findings or a non-penalizing policy), lower values mean risk scoring
/// reduced the score.
#derive(ToJson, Eq)
pub(all) struct TrustBreakdown {
  source_score : Double
  content_score : Double
  metadata : Double
  source_type : Double
  length : Double
  template_ratio : Double
  consistency : Double
  risk : Double
}

///|
/// Per-证据 trust: the score in [0, 1] together with its breakdown. It is
/// an explainable heuristic, never a probability of correctness.
#derive(ToJson, Eq)
pub(all) struct TrustDetail {
  score : Double
  breakdown : TrustBreakdown
}

///|
/// One ordered 候选块 turned into evidence. Mirrors the input candidate and
/// additionally reports the risk findings, the trust info, and the rerank
/// score it was ordered by. Conflict references join here in a later ticket.
#derive(ToJson, Eq)
pub(all) struct Evidence {
  id : String
  text : String
  source : SourceMeta
  retrieval_score : Double
  span : Span?
  risk_findings : Array[RiskFinding]
  rerank_score : Double
  trust : TrustDetail
}

///|
/// One fixed pipeline stage, captured when the scan finishes.
#derive(ToJson, Eq)
pub(all) struct StageRecord {
  name : String
  count : Int32
}

///|
/// Deterministic counters describing a scan run.
#derive(ToJson, Eq)
pub(all) struct Diagnostics {
  candidate_count : Int32
  duplicate_id_count : Int32
  unknown_rule_ids : Array[String]
  risk_finding_count : Int32
  quarantined_count : Int32
  output_count : Int32
  stages : Array[StageRecord]
}

///|
/// The result of a scan. `quarantined` preserves the audit trail of blocks
/// removed by the drop policy; `blocked` is true only when the config asked
/// for blocking and at least one high-severity finding exists (including
/// findings on quarantined blocks). Serialization is byte-identical across
/// repeated runs on identical inputs: fixed field order, no wall-clock or
/// random data.
#derive(ToJson, Eq)
pub(all) struct ScanReport {
  query : String
  config : ScanConfig
  evidence : Array[Evidence]
  quarantined : Array[QuarantinedBlock]
  blocked : Bool
  diagnostics : Diagnostics
}

///|
/// Default config: every knob absent, so the deterministic built-in
/// defaults apply and the echoed snapshot stays `{}`.
pub impl Default for ScanConfig with fn default() {
  {
    top_k: None,
    source_weight: None,
    content_weight: None,
    trust_weight: None,
    risk_policy: None,
    risk_weight: None,
    block_on_high: None,
    enabled_rules: None,
  }
}

///|
pub extend ScanConfig with Default::{default}

// Derived trait implementations are installed as regular methods through
// explicit extends, as the compiler recommends (implicit method promotion
// from derived impls is deprecated).

///|
pub extend Candidate with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend Candidate with @moonbitlang/core/json.FromJson::{from_json}

///|
pub extend Candidate with Eq::{not_equal, equal}

///|
pub extend SourceMeta with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend SourceMeta with @moonbitlang/core/json.FromJson::{from_json}

///|
pub extend SourceMeta with Eq::{not_equal, equal}

///|
pub extend Span with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend Span with @moonbitlang/core/json.FromJson::{from_json}

///|
pub extend Span with Eq::{not_equal, equal}

///|
pub extend CandidateFile with @moonbitlang/core/json.FromJson::{from_json}

///|
pub extend ScanConfig with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend ScanConfig with Eq::{not_equal, equal}

///|
pub extend TrustBreakdown with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend TrustBreakdown with Eq::{not_equal, equal}

///|
pub extend TrustDetail with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend TrustDetail with Eq::{not_equal, equal}

///|
pub extend Evidence with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend Evidence with Eq::{not_equal, equal}

///|
pub extend StageRecord with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend StageRecord with Eq::{not_equal, equal}

///|
pub extend Diagnostics with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend Diagnostics with Eq::{not_equal, equal}

///|
pub extend ScanReport with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend ScanReport with Eq::{not_equal, equal}

///|
/// Decode a candidate file from UTF-8 text.
pub fn parse_candidates(text : String) -> CandidateFile raise {
  let value = @json.parse(text)
  let file : CandidateFile = @json.from_json(value)
  file
}

///|
/// Run the deterministic pipeline: dedupe (first occurrence in input order
/// wins), scan risk rules, isolate per policy, score trust with the applied
/// risk factor, stable selection sort by rerank score (retrieval score +
/// trust) descending / id ascending / original input order, then optional
/// `top_k` truncation.
pub fn scan(
  query : String,
  config : ScanConfig,
  candidates : Array[Candidate],
) -> ScanReport {
  let candidate_count = candidates.length()
  let kept : Array[Candidate] = []
  for candidate in candidates {
    let mut duplicate = false
    for earlier in kept {
      if earlier.id == candidate.id {
        duplicate = true
      }
    }
    if duplicate {
      continue
    }
    kept.push(candidate)
  }
  let duplicate_id_count = candidate_count - kept.length()
  let (source_weight, content_weight) = resolve_weights(config)
  let trust_weight = match config.trust_weight {
    Some(weight) => finite_or(weight, 1.0)
    None => 1.0
  }
  // Downrank is the safe default: findings lower the score unless the caller
  // explicitly asks for annotation-only or removal.
  let policy = match config.risk_policy {
    Some(policy) => policy
    None => RiskPolicy::Downrank
  }
  let drop_policy = match policy {
    RiskPolicy::Drop => true
    _ => false
  }
  let downrank_policy = match policy {
    RiskPolicy::Downrank => true
    _ => false
  }
  let risk_weight = match config.risk_weight {
    Some(weight) => finite_or(weight, 1.0)
    None => 1.0
  }
  let block_on_high = match config.block_on_high {
    Some(flag) => flag
    None => false
  }
  let rules = make_rule_set()
  let scanned : Array[Scanned] = []
  let mut risk_finding_count = 0
  let mut risky_count = 0
  let mut blocked = false
  for index, candidate in kept {
    let findings = scan_risk_text(candidate.text, rules, config.enabled_rules)
    risk_finding_count = risk_finding_count + findings.length()
    if findings.length() > 0 {
      risky_count = risky_count + 1
    }
    let has_high = match highest_severity(findings) {
      Some(RiskSeverity::High) => true
      _ => false
    }
    if block_on_high && has_high {
      blocked = true
    }
    scanned.push({ candidate, index, findings, has_high, })
  }
  let quarantined : Array[QuarantinedBlock] = []
  let survivors : Array[Scanned] = []
  for entry in scanned {
    if drop_policy && entry.has_high {
      quarantined.push(to_quarantined(entry))
    } else {
      survivors.push(entry)
    }
  }
  let scored : Array[Entry] = []
  for entry in survivors {
    let factor = if downrank_policy {
      risk_factor(entry.findings, risk_weight)
    } else {
      1.0
    }
    let trust = score_trust(
      entry.candidate,
      source_weight,
      content_weight,
      factor,
    )
    let rerank = finite_or(entry.candidate.retrieval_score, 0.0) +
      trust_weight * trust.score
    scored.push({
      candidate: entry.candidate,
      index: entry.index,
      trust,
      rerank,
      findings: entry.findings,
    })
  }
  let ordered = order_candidates(scored)
  let all_evidence : Array[Evidence] = []
  for entry in ordered {
    all_evidence.push(to_evidence(entry))
  }
  let sorted_count = all_evidence.length()
  let evidence = match config.top_k {
    Some(top_k) => take_first(all_evidence, top_k)
    None => all_evidence
  }
  {
    query,
    config,
    evidence,
    quarantined,
    blocked,
    diagnostics: {
      candidate_count,
      duplicate_id_count,
      unknown_rule_ids: unknown_rule_ids(config.enabled_rules),
      risk_finding_count,
      quarantined_count: quarantined.length(),
      output_count: evidence.length(),
      stages: [
        { name: "ingest", count: candidate_count, },
        { name: "dedupe", count: kept.length(), },
        { name: "risk", count: risky_count, },
        { name: "isolate", count: survivors.length(), },
        { name: "sort", count: sorted_count, },
        { name: "topk", count: evidence.length(), },
      ],
    },
  }
}

///|
/// A scanned candidate before isolation: its findings and whether any of
/// them is high severity.
priv struct Scanned {
  candidate : Candidate
  index : Int32
  findings : Array[RiskFinding]
  has_high : Bool
}

///|
/// The audit-trail shape of a block removed by the drop policy.
fn to_quarantined(entry : Scanned) -> QuarantinedBlock {
  {
    id: entry.candidate.id,
    text: entry.candidate.text,
    source: entry.candidate.source,
    retrieval_score: finite_or(entry.candidate.retrieval_score, 0.0),
    span: entry.candidate.span,
    risk_findings: entry.findings,
    reason: "dropped by policy: high-severity risk",
  }
}

///|
/// An ordered candidate, its trust info, its rerank score, and its original
/// input position.
priv struct Entry {
  candidate : Candidate
  trust : TrustDetail
  rerank : Double
  index : Int32
  findings : Array[RiskFinding]
}

///|
/// Deterministic ordering. A fixed-field selection sort over a shallow copy,
/// so the caller's array keeps its input order; stable and free of any
/// dependency on input length or environment.
fn order_candidates(entries : Array[Entry]) -> Array[Entry] {
  let working = entries.copy()
  for target in 0..<working.length() {
    let mut best = target
    for probe in (target + 1)..<working.length() {
      if entry_before(working[probe], working[best]) {
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
/// Strict total order: rerank score descending, then id ascending, then
/// original input order. The index tie-break means the comparator never
/// ties for distinct kept candidates.
fn entry_before(first : Entry, second : Entry) -> Bool {
  let first_score = first.rerank
  let second_score = second.rerank
  if first_score > second_score {
    return true
  }
  if first_score < second_score {
    return false
  }
  let first_id = first.candidate.id
  let second_id = second.candidate.id
  if first_id < second_id {
    return true
  }
  if first_id > second_id {
    return false
  }
  first.index < second.index
}

///|
/// A finite weight, or the deterministic fallback. Keeps NaN and infinity
/// out of the score, the report, and the ordering.
fn finite_or(value : Double, fallback : Double) -> Double {
  if value.is_finite() {
    value
  } else {
    fallback
  }
}

///|
/// Resolve the trust blend weights. Absent or non-finite keys default to
/// 0.5/0.5; a non-positive weight sum also falls back to equal weights.
/// Negative weights are allowed — the final clamp keeps the score in range.
fn resolve_weights(config : ScanConfig) -> (Double, Double) {
  let source = match config.source_weight {
    Some(weight) => finite_or(weight, 0.5)
    None => 0.5
  }
  let content = match config.content_weight {
    Some(weight) => finite_or(weight, 0.5)
    None => 0.5
  }
  let total = source + content
  if total > 0.0 {
    (source / total, content / total)
  } else {
    (0.5, 0.5)
  }
}

///|
/// Trust score for one 候选块: trust_score = (来源分项 + 内容分项 weighted
/// blend) × risk factor, normalized to source/content weights summing to 1,
/// clamped to [0, 1]. Every sub-signal is clamped independently, so the
/// score stays in range for any input, including degenerate metadata.
fn score_trust(
  candidate : Candidate,
  source_weight : Double,
  content_weight : Double,
  risk : Double,
) -> TrustDetail {
  let metadata = metadata_completeness(candidate.source)
  let scheme = source_type(candidate.source.uri)
  let source_score = (metadata + scheme) / 2.0
  let length = length_score(candidate.text)
  let template_ratio = template_marker_ratio(candidate.text)
  let template = template_cleanliness(template_ratio)
  let consistency = consistency_score(candidate.text)
  let content_score = (length + template + consistency) / 3.0
  let raw = source_weight * source_score + content_weight * content_score
  let score = clamp_unit(raw * risk)
  {
    score,
    breakdown: {
      source_score,
      content_score,
      metadata,
      source_type: scheme,
      length,
      template_ratio,
      consistency,
      risk,
    },
  }
}

///|
/// 元数据完整度: fraction of { non-empty uri, non-empty title, non-empty
/// fetched_at, hint present }, out of the four provenance fields.
fn metadata_completeness(source : SourceMeta) -> Double {
  let mut present = 0
  if source.uri != "" {
    present = present + 1
  }
  if source.title != "" {
    present = present + 1
  }
  if source.fetched_at != "" {
    present = present + 1
  }
  match source.hint {
    Some(_) => present = present + 1
    None => ()
  }
  present.to_double() / 4.0
}

///|
/// 来源类型 from the uri scheme (deterministic bands): https 1.0, managed
/// store (s3/gs) 0.8, http 0.6, local file 0.4, any other scheme 0.3, no
/// scheme 0.2. Unknown host forms score low rather than high on purpose.
fn source_type(uri : String) -> Double {
  if uri.has_prefix("https://") {
    1.0
  } else if uri.has_prefix("s3://") || uri.has_prefix("gs://") {
    0.8
  } else if uri.has_prefix("http://") {
    0.6
  } else if uri.has_prefix("file://") {
    0.4
  } else if uri.contains("://") {
    0.3
  } else {
    0.2
  }
}

///|
/// Length signal: text length normalized by 40 characters and clipped to
/// [0, 1]. Deterministic per target: string length counts UTF-16 code
/// units, matching the pure-ASCII / BMP-only inputs of 宽度 heuristics.
fn length_score(text : String) -> Double {
  let share = text.length().to_double() / 40.0
  if share < 0.0 {
    0.0
  } else if share > 1.0 {
    1.0
  } else {
    share
  }
}

///|
/// 模板化比例: the raw share of template-ish characters (`{`, `}`, `<`,
/// `>`) in the text, in [0, 1]. Higher means more templated (worse).
/// Empty text carries no content and is treated as fully template-like.
fn template_marker_ratio(text : String) -> Double {
  let characters = text.length()
  if characters == 0 {
    return 1.0
  }
  let mut markers = 0
  for i in 0..<characters {
    let unit = text.code_unit_at(i)
    if unit == 123 || unit == 125 || unit == 60 || unit == 62 {
      markers = markers + 1
    }
  }
  markers.to_double() / characters.to_double()
}

///|
/// Template cleanliness used by the content component: 1 minus eight times
/// the marker ratio, clipped to [0, 1], so a marker share of 12.5% or more
/// scores 0.
fn template_cleanliness(ratio : Double) -> Double {
  let score = 1.0 - ratio * 8.0
  if score < 0.0 {
    0.0
  } else if score > 1.0 {
    1.0
  } else {
    score
  }
}

///|
/// 语言一致性 signal. Zero penalty in this ticket: the constant 1.0 keeps
/// CJK/ASCII scripts neutral. 跨文档一致性 (ticket 04) replaces this
/// placeholder without changing the breakdown shape.
fn consistency_score(_text : String) -> Double {
  1.0
}

///|
/// Project an ordered entry into the public evidence shape.
fn to_evidence(entry : Entry) -> Evidence {
  {
    id: entry.candidate.id,
    text: entry.candidate.text,
    source: entry.candidate.source,
    retrieval_score: finite_or(entry.candidate.retrieval_score, 0.0),
    span: entry.candidate.span,
    risk_findings: entry.findings,
    rerank_score: entry.rerank,
    trust: entry.trust,
  }
}

///|
/// The first `limit` elements, clamped to the array length.
fn[T] take_first(candidates : Array[T], limit : Int32) -> Array[T] {
  let limit = if limit < 0 {
    0
  } else if limit < candidates.length() {
    limit
  } else {
    candidates.length()
  }
  let head : Array[T] = []
  for i in 0..<limit {
    head.push(candidates[i])
  }
  head
}
