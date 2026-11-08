// Pure `demo` subcommand: parse arguments, build the acceptance comparison,
// and render the human-readable summary. The machine-readable JSON is
// returned in the outcome; the executable shell owns writing it, keeping
// this package free of side effects.

///|
/// Everything the executable shell needs for a demo run: the summary to print
/// and, when `--json-out` was requested, the JSON artifact to write.
#derive(Debug)
pub struct DemoOutcome {
  output : String
  code : ExitCode
  json_path : String?
  json_text : String?
}

///|
pub extend DemoOutcome with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Fixed query for the demo. The corpus keys every claim explicitly, so the
/// query is only a label; keeping it constant keeps the command short and the
/// output stable.
const DEMO_QUERY : String = "demo"

///|
fn demo_invalid(msg : String) -> DemoOutcome {
  {
    output: "moon-trust: " + msg + "\n" + usage(),
    code: ExitCode::Invalid,
    json_path: None,
    json_text: None,
  }
}

///|
fn demo_operational(msg : String) -> DemoOutcome {
  {
    output: "moon-trust: " + msg,
    code: ExitCode::Operational,
    json_path: None,
    json_text: None,
  }
}

///|
/// Pure demo dispatch. `args` is the raw argv (element 0 is the program name;
/// element 1 is `demo`); `read_file` is the injected read seam. A successful
/// run always exits 0 — use `scan --block-on-high` when the exit status must
/// gate on risk.
pub fn resolve_demo(
  args : Array[String],
  read_file : (String) -> Result[String, String],
) -> DemoOutcome {
  if args.length() < 2 {
    return demo_invalid("missing subcommand")
  }
  if args[1] != "demo" {
    return demo_invalid("unknown subcommand: " + args[1])
  }
  if args.length() < 3 {
    return demo_invalid("missing candidates file path")
  }
  let path = args[2]
  let mut json_out : String? = None
  let mut i = 3
  while i < args.length() {
    let token = args[i]
    if is_option(token) {
      if token == "--json-out" {
        if i + 1 >= args.length() {
          return demo_invalid("missing value for --json-out")
        }
        json_out = Some(args[i + 1])
        i = i + 2
        continue
      }
      return demo_invalid("unknown option: " + token)
    }
    return demo_invalid("unexpected argument: " + token)
  }
  let content = match read_file(path) {
    Ok(text) => text
    Err(msg) => return demo_operational(msg)
  }
  let file = @src.parse_candidates(content) catch {
    _ => return demo_invalid("malformed candidates file")
  }
  let report = @src.demo_report(DEMO_QUERY, file.candidates)
  {
    output: render_demo(report),
    code: ExitCode::Success,
    json_path: json_out,
    json_text: match json_out {
      Some(_) => Some(report.to_json().stringify() + "\n")
      None => None
    },
  }
}

///|
/// The human-readable comparison: a three-row metric table, the blocks whose
/// rank changed (in trusted order), the quarantine list, and the trusted
/// context accounting.
fn render_demo(report : @src.DemoReport) -> String {
  let comparison = report.comparison
  let lines : Array[String] = [
    "moon-trust demo: with vs without the trust layer",
    "query: " + report.query,
    "corpus: \{report.corpus_size} candidates; policy: " +
    @src.policy_label(report.policy),
    "",
    pad_right("metric", 28) + pad_right("without trust", 18) + "with trust",
    pad_right("unsafe blocks exposed", 28) +
    pad_right("\{comparison.unsafe_blocks_exposed.before}", 18) +
    "\{comparison.unsafe_blocks_exposed.after}",
    pad_right("conflict pairs found", 28) +
    pad_right("\{comparison.conflict_pairs.before}", 18) +
    "\{comparison.conflict_pairs.after}",
    pad_right("injections intercepted", 28) +
    pad_right("\{comparison.injections_intercepted.before}", 18) +
    "\{comparison.injections_intercepted.after}",
    "",
    "ranking changes (retrieval order -> rerank order):",
  ]
  let changes = comparison.ranking_changes
  if changes.length() == 0 {
    lines.push("  (none)")
  } else {
    let id_width = max_id_width(changes)
    for change in changes {
      lines.push(
        "  " +
        pad_right(change.id, id_width) +
        "  " +
        pad_left_number(change.before_rank, 2) +
        " -> " +
        pad_left_number(change.after_rank, 2) +
        "  (" +
        signed_delta(change.delta) +
        ")",
      )
    }
    lines.push(
      "(\{changes.length()} of \{report.trusted.order.length()} surviving blocks changed rank)",
    )
  }
  lines.push("")
  if report.trusted.quarantined_count > 0 {
    lines.push(
      "quarantined (\{report.trusted.quarantined_count}): " +
      report.trusted.quarantined_ids.join(", "),
    )
  }
  lines.push(
    "trusted run: \{report.trusted.order.length()} evidence, blocked=" +
    bool_label(report.trusted.blocked),
  )
  lines.push(
    "context: \{report.trusted.context.included_count} blocks, " +
    "\{report.trusted.context.estimated_tokens} tokens / budget " +
    "\{report.trusted.context.budget}, truncated=" +
    bool_label(report.trusted.context.truncated),
  )
  lines.join("\n")
}

///|
/// Pad a string on the right to a fixed display width (the output is ASCII,
/// so UTF-16 length is the display width).
fn pad_right(text : String, width : Int32) -> String {
  let mut out = text
  let mut used = text.length()
  while used < width {
    out = out + " "
    used = used + 1
  }
  out
}

///|
/// Right-align a small non-negative number in a fixed width.
fn pad_left_number(value : Int32, width : Int32) -> String {
  let digits = "\{value}"
  let mut out = ""
  let mut used = digits.length()
  while used < width {
    out = out + " "
    used = used + 1
  }
  out + digits
}

///|
/// Signed delta text: a positive delta is a rank gain.
fn signed_delta(value : Int32) -> String {
  if value > 0 {
    "+" + "\{value}"
  } else {
    "\{value}"
  }
}

///|
fn bool_label(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn max_id_width(changes : Array[@src.RankChange]) -> Int32 {
  let mut width = 0
  for change in changes {
    if change.id.length() > width {
      width = change.id.length()
    }
  }
  width
}
