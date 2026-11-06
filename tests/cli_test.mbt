// Black-box tests for src/cli through the public resolve() seam. The file
// read is stubbed with plain functions, so — like lib_test — these tests
// never touch the filesystem and run unchanged on native, wasm-gc, and js.

///|
// The usage line, pinned here because tests assert the exact combined
// output "moon-trust: <msg>\n<usage>" for every invalid outcome.
const USE : String = "usage: moon-trust scan <query> <candidates.json> [--top-k N]"

///|
// Successful read: hands back the multi-candidate fixture regardless of path.
fn stub_ok(_ : String) -> Result[String, String] {
  Ok(MULTI)
}

///|
// Failing read: a fixed operational message, like the real main produces.
fn stub_err(_ : String) -> Result[String, String] {
  Err("cannot open 'x': no such file")
}

///|
// "Successful" read of malformed content, to exercise the decoder rejection.
fn stub_bad(_ : String) -> Result[String, String] {
  Ok(MALFORMED)
}

///|
test "no arguments means missing subcommand" {
  let args : Array[String] = []
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(outcome.output, "moon-trust: missing subcommand\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "unknown subcommands are rejected with usage" {
  let args : Array[String] = ["moon-trust", "scanx"]
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(outcome.output, "moon-trust: unknown subcommand: scanx\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "scan requires a query" {
  let args : Array[String] = ["moon-trust", "scan"]
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(outcome.output, "moon-trust: missing query\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "scan requires a candidates file path" {
  let args : Array[String] = ["moon-trust", "scan", "hello"]
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(outcome.output, "moon-trust: missing candidates file path\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "unknown options are rejected" {
  let args : Array[String] = ["moon-trust", "scan", "hello", "c.json", "--json"]
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(outcome.output, "moon-trust: unknown option: --json\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "unexpected non-option arguments are rejected" {
  let args : Array[String] = ["moon-trust", "scan", "hello", "c.json", "extra"]
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(outcome.output, "moon-trust: unexpected argument: extra\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "--top-k without a value is rejected" {
  let args : Array[String] = [
    "moon-trust", "scan", "hello", "c.json", "--top-k",
  ]
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(outcome.output, "moon-trust: missing value for --top-k\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "--top-k with a non-integer value is rejected" {
  let args : Array[String] = [
    "moon-trust", "scan", "hello", "c.json", "--top-k", "abc",
  ]
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(
    outcome.output,
    "moon-trust: --top-k expects an integer, got: abc\n" + USE,
  )
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "--top-k with a negative value is rejected" {
  let args : Array[String] = [
    "moon-trust", "scan", "hello", "c.json", "--top-k", "-1",
  ]
  let outcome = @cli.resolve(args, stub_ok)
  assert_eq(
    outcome.output,
    "moon-trust: --top-k must be a non-negative integer, got: -1\n" + USE,
  )
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "an unreadable file is an operational failure" {
  let args : Array[String] = ["moon-trust", "scan", "hello", "gone.json"]
  let outcome = @cli.resolve(args, stub_err)
  assert_eq(outcome.output, "moon-trust: cannot open 'x': no such file")
  assert_eq(outcome.code.to_int(), 2)
}

///|
test "malformed candidates content is invalid" {
  let args : Array[String] = ["moon-trust", "scan", "hello", "c.json"]
  let outcome = @cli.resolve(args, stub_bad)
  assert_eq(outcome.output, "moon-trust: malformed candidates file\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "a valid run prints exactly the built report" {
  let args : Array[String] = ["moon-trust", "scan", "hello", "c.json"]
  let outcome = @cli.resolve(args, stub_ok)
  let expected = render(
    @src.scan("hello", { top_k: None, }, decode(MULTI).candidates),
  )
  assert_eq(outcome.output, expected)
  assert_eq(outcome.code.to_int(), 0)
}

///|
test "--top-k flows into the report config" {
  let args : Array[String] = [
    "moon-trust", "scan", "hello", "c.json", "--top-k", "2",
  ]
  let outcome = @cli.resolve(args, stub_ok)
  // The success shape itself is asserted elsewhere; here we pin that an
  // accepted --top-k lands in the rendered config as the number 2.
  assert_eq(outcome.output.contains("\"config\":{\"top_k\":2}"), true)
  assert_eq(outcome.code.to_int(), 0)
}

///|
test "identical invocations render byte-identical output" {
  let args : Array[String] = ["moon-trust", "scan", "hello", "c.json"]
  let first = @cli.resolve(args, stub_ok)
  let second = @cli.resolve(args, stub_ok)
  assert_eq(first.output, second.output)
}

///|
test "exit codes map to 0, 1, and 2" {
  assert_eq(@cli.Success.to_int(), 0)
  assert_eq(@cli.Invalid.to_int(), 1)
  assert_eq(@cli.Operational.to_int(), 2)
}
