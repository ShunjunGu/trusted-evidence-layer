// Deterministic evidence-context assembly.
//
// The context is the plain-text artifact handed to a generator: ranked
// evidence blocks with stable `[n]` citation markers, one citation record per
// included block, and a closing appendix that lists the risk findings and
// conflict pairs relevant to the included evidence. Assembly is greedy over
// the ranked evidence and is bounded by an approximate token budget; the
// budget is never exceeded, and over-budget evidence is omitted whole rather
// than cut mid-block.

///|
/// One citation: the 1-based `[n]` marker, the evidence id it points at, and
/// that evidence's source metadata. `index` equals the marker number, so the
/// citation table can be indexed directly as `citations[n - 1]`.
#derive(ToJson, Eq)
pub(all) struct Citation {
  index : Int32
  evidence_id : String
  source : SourceMeta
}

///|
pub extend Citation with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend Citation with Eq::{not_equal, equal}

///|
/// The assembled evidence context and its accounting. `text` is the artifact
/// for the generator; `citations` resolves every `[n]` marker in it;
/// `estimated_tokens` is the approximate token count of `text` under the
/// documented estimator (ASCII by word, CJK by character); `truncated` is
/// true when at least one ranked evidence block was omitted for budget, and
/// `omitted_count` records how many.
#derive(ToJson, Eq)
pub(all) struct EvidenceContext {
  budget : Int32
  estimated_tokens : Int32
  truncated : Bool
  included_count : Int32
  omitted_count : Int32
  text : String
  citations : Array[Citation]
}

///|
pub extend EvidenceContext with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend EvidenceContext with Eq::{not_equal, equal}

///|
/// Budget applied when `ScanConfig.context_budget` is absent.
const DEFAULT_CONTEXT_BUDGET : Int32 = 512

///|
/// Resolve the configured budget. Absent means the default; a negative value
/// is clamped to zero, so the context can never be asked for a negative size.
fn resolve_context_budget(config : ScanConfig) -> Int32 {
  match config.context_budget {
    Some(budget) => if budget < 0 { 0 } else { budget }
    None => DEFAULT_CONTEXT_BUDGET
  }
}

///|
/// Assemble the context greedily over the ranked evidence. Each block is
/// considered in order: it is included when its rendered block plus the
/// current appendix (risks and conflicts among included evidence) still fits
/// the remaining budget; otherwise it is omitted and the next block is tried.
/// The rule is deterministic and independent of input length.
fn build_context(
  evidence : Array[Evidence],
  conflicts : Array[Conflict],
  budget : Int32,
) -> EvidenceContext {
  let included : Array[Evidence] = []
  // Citation index (1-based) per included evidence id. Lookups only; the
  // rendered order always comes from the `included` array, so the hash
  // container cannot leak into the output ordering.
  let included_index : @hashmap.HashMap[String, Int32] = @hashmap.HashMap([])
  let mut block_tokens = 0
  let mut risk_line_tokens = 0
  let mut conflict_line_tokens = 0
  let mut omitted = 0
  for item in evidence {
    let index = included.length() + 1
    let block_cost = estimate_tokens(render_block(index, item))
    let mut new_risk_tokens = 0
    for finding in item.risk_findings {
      new_risk_tokens = new_risk_tokens +
        estimate_tokens(render_risk_line(index, finding))
    }
    let risk_header = if risk_line_tokens == 0 && new_risk_tokens > 0 {
      1
    } else {
      0
    }
    let mut new_conflict_tokens = 0
    for conflict in conflicts {
      match trial_conflict_line(conflict, item.id, index, included_index) {
        Some(line) =>
          new_conflict_tokens = new_conflict_tokens + estimate_tokens(line)
        None => ()
      }
    }
    let conflict_header = if conflict_line_tokens == 0 &&
      new_conflict_tokens > 0 {
      1
    } else {
      0
    }
    let total = block_tokens +
      block_cost +
      risk_line_tokens +
      conflict_line_tokens +
      risk_header +
      conflict_header +
      new_risk_tokens +
      new_conflict_tokens
    if total <= budget {
      included.push(item)
      included_index.set(item.id, index)
      block_tokens = block_tokens + block_cost
      risk_line_tokens = risk_line_tokens + new_risk_tokens
      conflict_line_tokens = conflict_line_tokens + new_conflict_tokens
    } else {
      omitted = omitted + 1
    }
  }
  let appendix = render_appendix(included, conflicts)
  let mut text = ""
  for index, item in included {
    if index > 0 {
      text = text + "\n\n"
    }
    text = text + render_block(index + 1, item)
  }
  if appendix != "" {
    if text != "" {
      text = text + "\n\n"
    }
    text = text + appendix
  }
  {
    budget,
    estimated_tokens: estimate_tokens(text),
    truncated: omitted > 0,
    included_count: included.length(),
    omitted_count: omitted,
    text,
    citations: citations_of(included),
  }
}

///|
/// One evidence block: the marker, the untrusted text verbatim, and a source
/// line with the citation metadata. Empty titles render as `(untitled)` so
/// the line stays parseable; the raw title is preserved in the citation.
fn render_block(index : Int32, evidence : Evidence) -> String {
  let title = if evidence.source.title == "" {
    "(untitled)"
  } else {
    evidence.source.title
  }
  "[\{index}] \{evidence.text}\n" +
  "source: \{title} | \{evidence.source.uri} | \{evidence.source.fetched_at}"
}

///|
/// One risk appendix line, anchored at the citation marker of its evidence.
fn render_risk_line(index : Int32, finding : RiskFinding) -> String {
  "- [\{index}] \{finding.rule_id} " +
  "(\{severity_label(finding.severity)}): \{finding.explanation}"
}

///|
/// The appendix line a trial block would add, if `conflict` pairs it with an
/// already-included evidence. Conflicts between two omitted blocks, or with a
/// block included later, yield `None`; the report keeps every pair regardless.
fn trial_conflict_line(
  conflict : Conflict,
  new_id : String,
  new_index : Int32,
  included_index : @hashmap.HashMap[String, Int32],
) -> String? {
  if conflict.left.evidence_id == new_id {
    match included_index.get(conflict.right.evidence_id) {
      Some(right_index) =>
        Some(format_conflict_line(conflict, new_index, right_index))
      None => None
    }
  } else if conflict.right.evidence_id == new_id {
    match included_index.get(conflict.left.evidence_id) {
      Some(left_index) =>
        Some(format_conflict_line(conflict, left_index, new_index))
      None => None
    }
  } else {
    None
  }
}

///|
/// One conflict appendix line with resolved markers. `subject (unit)` groups
/// the pair; the unit is omitted when the claim is unitless.
fn format_conflict_line(
  conflict : Conflict,
  left_index : Int32,
  right_index : Int32,
) -> String {
  let group = if conflict.unit == "" {
    conflict.subject
  } else {
    conflict.subject + " (" + conflict.unit + ")"
  }
  "- [\{left_index}] vs [\{right_index}] \{group}: " +
  "\{conflict.left.value_text} vs \{conflict.right.value_text}"
}

///|
/// Render the closing appendix from the included evidence, or an empty string
/// when there is nothing to disclose. Risks come first, conflicts second.
fn render_appendix(
  included : Array[Evidence],
  conflicts : Array[Conflict],
) -> String {
  let risk_lines : Array[String] = []
  for index, evidence in included {
    for finding in evidence.risk_findings {
      risk_lines.push(render_risk_line(index + 1, finding))
    }
  }
  let included_index : @hashmap.HashMap[String, Int32] = @hashmap.HashMap([])
  for index, evidence in included {
    included_index.set(evidence.id, index + 1)
  }
  let conflict_lines : Array[String] = []
  for conflict in conflicts {
    match
      (
        included_index.get(conflict.left.evidence_id),
        included_index.get(conflict.right.evidence_id),
      ) {
      (Some(left_index), Some(right_index)) =>
        conflict_lines.push(
          format_conflict_line(conflict, left_index, right_index),
        )
      _ => ()
    }
  }
  let mut text = ""
  if risk_lines.length() > 0 {
    text = "Risks:\n" + risk_lines.join("\n")
  }
  if conflict_lines.length() > 0 {
    if text != "" {
      text = text + "\n"
    }
    text = text + "Conflicts:\n" + conflict_lines.join("\n")
  }
  text
}

///|
/// The citation table for the included evidence, in render order.
fn citations_of(included : Array[Evidence]) -> Array[Citation] {
  let citations : Array[Citation] = []
  for index, evidence in included {
    citations.push({
      index: index + 1,
      evidence_id: evidence.id,
      source: evidence.source,
    })
  }
  citations
}

///|
/// Approximate token count: each maximal run of ASCII letters, digits, and
/// `_` counts as one word; every non-ASCII code point (CJK characters and
/// punctuation included) counts as one token; ASCII whitespace and
/// punctuation count as zero. The estimate is deterministic and intentionally
/// cheap — it sizes the context, it is not a tokenizer.
fn estimate_tokens(text : String) -> Int32 {
  let mut tokens = 0
  let mut in_word = false
  for char in text {
    let code = char.to_int()
    if code < 128 {
      if is_ascii_word_code(code) {
        if !in_word {
          tokens = tokens + 1
        }
        in_word = true
      } else {
        in_word = false
      }
    } else {
      tokens = tokens + 1
      in_word = false
    }
  }
  tokens
}

///|
/// ASCII word characters: `0-9`, `A-Z`, `a-z`, `_`.
fn is_ascii_word_code(code : Int32) -> Bool {
  (code >= 48 && code <= 57) ||
  (code >= 65 && code <= 90) ||
  (code >= 97 && code <= 122) ||
  code == 95
}
