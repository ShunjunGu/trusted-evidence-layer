// Black-box tests for the `demo` subcommand through the pure resolve_demo()
// seam. The corpus read is stubbed, so these tests never touch the
// filesystem; the JSON artifact is returned in the outcome for the executable
// shell to write.

///|
// The pinned human-readable summary for the fixed corpus: the demo
// contract for the application walkthrough.
const DEMO_SUMMARY : String = "moon-trust demo: with vs without the trust layer\nquery: demo\ncorpus: 11 candidates; policy: drop\n\nmetric                      without trust     with trust\nunsafe blocks exposed       5                 0\nconflict pairs found        0                 2\ninjections intercepted      0                 5\n\nranking changes (retrieval order -> rerank order):\n  benign-imperative   9 ->  1  (+8)\n  high-trust         10 ->  2  (+8)\n  benign-doc         11 ->  3  (+8)\n  low-trust           6 ->  4  (+2)\n  fact-a              7 ->  5  (+2)\n  fact-b              8 ->  6  (+2)\n(6 of 6 surviving blocks changed rank)\n\nquarantined (5): inj-override, inj-role, inj-hidden, inj-delimiter, inj-payload\ntrusted run: 6 evidence, blocked=true\ncontext: 6 blocks, 162 tokens / budget 512, truncated=false"

///|
// Successful read of the fixed demo corpus.
fn stub_demo(_ : String) -> Result[String, String] {
  Ok(DEMO)
}

///|
test "demo resolve rejects missing and wrong subcommands" {
  let empty : Array[String] = []
  assert_eq(
    @cli.resolve_demo(empty, stub_demo).output,
    "moon-trust: missing subcommand\n" + USE,
  )
  let wrong : Array[String] = ["moon-trust", "scan"]
  assert_eq(
    @cli.resolve_demo(wrong, stub_demo).output,
    "moon-trust: unknown subcommand: scan\n" + USE,
  )
}

///|
test "demo without a candidates path is invalid" {
  let args : Array[String] = ["moon-trust", "demo"]
  let outcome = @cli.resolve_demo(args, stub_demo)
  assert_eq(outcome.output, "moon-trust: missing candidates file path\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
  assert_eq(outcome.json_path == None, true)
  assert_eq(outcome.json_text == None, true)
}

///|
test "demo rejects unknown options and extra arguments" {
  let unknown : Array[String] = [
    "moon-trust", "demo", "c.json", "--policy", "drop",
  ]
  assert_eq(
    @cli.resolve_demo(unknown, stub_demo).output,
    "moon-trust: unknown option: --policy\n" + USE,
  )
  let extra : Array[String] = ["moon-trust", "demo", "c.json", "extra"]
  assert_eq(
    @cli.resolve_demo(extra, stub_demo).output,
    "moon-trust: unexpected argument: extra\n" + USE,
  )
}

///|
test "demo --json-out without a value is rejected" {
  let args : Array[String] = ["moon-trust", "demo", "c.json", "--json-out"]
  let outcome = @cli.resolve_demo(args, stub_demo)
  assert_eq(outcome.output, "moon-trust: missing value for --json-out\n" + USE)
  assert_eq(outcome.code.to_int(), 1)
}

///|
test "demo maps unreadable and malformed inputs like scan" {
  let unreadable : Array[String] = ["moon-trust", "demo", "gone.json"]
  let missing = @cli.resolve_demo(unreadable, stub_err)
  assert_eq(missing.output, "moon-trust: cannot open 'x': no such file")
  assert_eq(missing.code.to_int(), 2)
  let malformed : Array[String] = ["moon-trust", "demo", "c.json"]
  let bad = @cli.resolve_demo(malformed, stub_bad)
  assert_eq(bad.output, "moon-trust: malformed candidates file\n" + USE)
  assert_eq(bad.code.to_int(), 1)
}

///|
test "demo prints the pinned human-readable comparison and exits 0" {
  let args : Array[String] = ["moon-trust", "demo", "c.json"]
  let outcome = @cli.resolve_demo(args, stub_demo)
  assert_eq(outcome.code.to_int(), 0)
  assert_eq(outcome.output, DEMO_SUMMARY)
  assert_eq(outcome.json_path == None, true)
  assert_eq(outcome.json_text == None, true)
}

///|
test "demo --json-out returns the machine-readable artifact" {
  let args : Array[String] = [
    "moon-trust", "demo", "c.json", "--json-out", "out/demo.json",
  ]
  let outcome = @cli.resolve_demo(args, stub_demo)
  assert_eq(outcome.code.to_int(), 0)
  assert_eq(outcome.json_path == Some("out/demo.json"), true)
  match outcome.json_text {
    Some(text) => {
      assert_true(text.contains("\"comparison\":{"))
      assert_true(text.contains("\"ranking_changes\":["))
      assert_true(
        text.contains(
          "\"unsafe_blocks_exposed\":{\"before\":5,\"after\":0,\"delta\":-5}",
        ),
      )
      assert_true(text.contains("\"quarantined_count\":5"))
      assert_true(text.has_suffix("\n"))
    }
    None => abort("demo --json-out produced no JSON text")
  }
}

///|
test "demo output is byte-identical across repeated invocations" {
  let args : Array[String] = [
    "moon-trust", "demo", "c.json", "--json-out", "out.json",
  ]
  let first = @cli.resolve_demo(args, stub_demo)
  let second = @cli.resolve_demo(args, stub_demo)
  assert_eq(first.output, second.output)
  match (first.json_text, second.json_text) {
    (Some(a), Some(b)) => assert_eq(a, b)
    _ => abort("demo JSON text missing")
  }
}
