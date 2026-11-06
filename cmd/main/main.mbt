// cmd/main — the thin executable shell for the moon-trust CLI. All argument
// parsing, decoding, and rendering live in src/cli and src; this file owns
// only the two side effects a cmd/main may own: read the file's bytes (@fs)
// and set the process exit status. Usage:
//   moon run cmd/main --target native -- scan <query> <candidates.json> [--top-k N]
// @env.args()[0] is the exe path, so the subcommand is [1].

///|
// C `exit(int)`, the one mechanism the toolchain offers for a chosen
// non-zero exit status; the public abort() always panics with a single
// uncontrolled code. Declared for native/llvm only, like core/argparse does.
#cfg(any(target="native", target="llvm"))
extern "c" fn exit_with(code : Int32) = "exit"

///|
// Non-native fallback: no C exit() is reachable, so degrade to abort (a
// single non-zero panic). The CLI is native-only in practice; this branch
// exists only to keep the package compiling off native, where the
// distinct-code granularity is intentionally lost.
#cfg(not(any(target="native", target="llvm")))
fn exit_with(code : Int32) -> Unit {
  let _ = code
  abort("moon-trust: cannot set a specific exit code on this target")
}

///|
// The read seam handed to the pure CLI logic. @fs.path_exists separates
// "cannot open" from "cannot read" so both map to Operational (exit 2) with distinct
// messages, while malformed content is left for src/cli to reject as
// Invalid (exit 1).
fn read_candidates_file(path : String) -> Result[String, String] {
  if !@fs.path_exists(path) {
    return Err("cannot open '\{path}': no such file")
  }
  try @fs.read_file_to_string(path, encoding="utf8") |> Ok catch {
    _ => Err("cannot read '\{path}'")
  }
}

///|
fn main {
  let outcome = @cli.resolve(@env.args(), read_candidates_file)
  println(outcome.output)
  exit_with(outcome.code.to_int())
}
