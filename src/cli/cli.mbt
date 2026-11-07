// Pure CLI logic: argument parsing, outcome rendering, and usage text.
// No side effects here — decoding and printing happen in the caller, so the
// whole package compiles unchanged for native, wasm-gc, and js targets.

///|
/// How a run ends: success with a report on stdout, invalid input (exit 1),
/// or an operational failure such as an unreadable file (exit 2).
#derive(Debug, Eq)
pub(all) enum ExitCode {
  Success
  Invalid
  Operational
}

///|
pub extend ExitCode with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ExitCode with Eq::{not_equal, equal}

///|
pub fn ExitCode::to_int(self : ExitCode) -> Int32 {
  match self {
    Success => 0
    Invalid => 1
    Operational => 2
  }
}

///|
/// Everything the executable shell needs: the text to print and the exit
/// status to translate it into.
#derive(Debug)
pub struct CliOutcome {
  output : String
  code : ExitCode
}

///|
pub extend CliOutcome with @moonbitlang/core/debug.Debug::{to_repr}

///|
fn usage() -> String {
  "usage: moon-trust scan <query> <candidates.json> [--top-k N]"
}

///|
fn invalid(msg : String) -> CliOutcome {
  { output: "moon-trust: " + msg + "\n" + usage(), code: Invalid, }
}

///|
fn operational(msg : String) -> CliOutcome {
  { output: "moon-trust: " + msg, code: Operational, }
}

///|
/// Pure command dispatch. `args` is the raw argv (element 0 is the program
/// name and is ignored); `read_file` is the injected read seam so this
/// function stays free of filesystem access.
pub fn resolve(
  args : Array[String],
  read_file : (String) -> Result[String, String],
) -> CliOutcome {
  if args.length() < 2 {
    return invalid("missing subcommand")
  }
  if args[1] != "scan" {
    return invalid("unknown subcommand: " + args[1])
  }
  if args.length() < 3 {
    return invalid("missing query")
  }
  if args.length() < 4 {
    return invalid("missing candidates file path")
  }
  let query = args[2]
  let path = args[3]
  let mut top_k : Int32? = None
  let mut i = 4
  while i < args.length() {
    let token = args[i]
    if is_option(token) {
      if token == "--top-k" {
        if i + 1 >= args.length() {
          return invalid("missing value for --top-k")
        }
        match parse_top_k(args[i + 1]) {
          Some(value) => {
            if value < 0 {
              return invalid(
                "--top-k must be a non-negative integer, got: " + args[i + 1],
              )
            }
            top_k = Some(value)
          }
          None =>
            return invalid("--top-k expects an integer, got: " + args[i + 1])
        }
        i = i + 2
        continue
      }
      return invalid("unknown option: " + token)
    }
    return invalid("unexpected argument: " + token)
  }
  let content = match read_file(path) {
    Ok(text) => text
    Err(msg) => return operational(msg)
  }
  let file = @src.parse_candidates(content) catch {
    _ => return invalid("malformed candidates file")
  }
  let report = @src.scan(
    query,
    { ..@src.ScanConfig::default(), top_k, },
    file.candidates,
  )
  { output: report.to_json().stringify(), code: Success, }
}

///|
fn is_option(token : String) -> Bool {
  token.length() >= 2 &&
  token.get_char(0) == Some('-') &&
  token.get_char(1) == Some('-')
}

///|
fn parse_top_k(text : String) -> Int32? {
  try @string.parse_int(text) |> Some catch {
    _ => None
  }
}
