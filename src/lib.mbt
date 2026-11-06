// Walking skeleton: candidate contract + deterministic scan.

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
/// is an optional trust annotation, unused by the skeleton scan.
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
/// Scan configuration: optional truncation to the first `top_k` results.
#derive(ToJson, Eq)
pub(all) struct ScanConfig {
  top_k : Int32?
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
  output_count : Int32
  stages : Array[StageRecord]
}

///|
/// The result of a scan. Serialization is byte-identical across repeated
/// runs on identical inputs: fixed field order, no wall-clock or random data.
#derive(ToJson, Eq)
pub(all) struct ScanReport {
  query : String
  config : ScanConfig
  evidence : Array[Candidate]
  diagnostics : Diagnostics
}

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
/// Run the deterministic scan: dedupe (first occurrence in input order
/// wins), stable selection sort by retrieval score descending / id
/// ascending / original input order, then optional `top_k` truncation.
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
  let ordered = order_candidates(kept)
  let evidence = match config.top_k {
    Some(top_k) => take_first(ordered, top_k)
    None => ordered
  }
  {
    query,
    config,
    evidence,
    diagnostics: {
      candidate_count,
      duplicate_id_count,
      output_count: evidence.length(),
      stages: [
        { name: "ingest", count: candidate_count, },
        { name: "dedupe", count: kept.length(), },
        { name: "sort", count: ordered.length(), },
        { name: "topk", count: evidence.length(), },
      ],
    },
  }
}

///|
/// An ordered candidate together with its original input position.
priv struct Entry {
  candidate : Candidate
  index : Int32
}

///|
/// Deterministic ordering. A fixed-field selection sort; stable and free
/// of any dependency on input length or environment.
fn order_candidates(candidates : Array[Candidate]) -> Array[Candidate] {
  let working : Array[Entry] = []
  for index, candidate in candidates {
    working.push({ candidate, index, })
  }
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
  let ordered : Array[Candidate] = []
  for entry in working {
    ordered.push(entry.candidate)
  }
  ordered
}

///|
/// Strict total order: score descending, then id ascending, then original
/// input order. The index tie-break means the comparator never ties.
fn entry_before(first : Entry, second : Entry) -> Bool {
  let first_score = first.candidate.retrieval_score
  let second_score = second.candidate.retrieval_score
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
