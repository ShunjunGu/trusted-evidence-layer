// Black-box tests for cross-document conflict detection through the public
// scan API. The corpus lives in `CONFLICTS` (fixtures_test.mbt).

///|
// Whether a string array contains `value`.
fn contains_string(values : Array[String], value : String) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

///|
// One candidate with full provenance, an empty title (unless provided), and
// a fixed retrieval score, for claim-extraction probes.
fn conflict_candidate(
  id : String,
  text : String,
  title : String,
) -> @src.Candidate {
  {
    id,
    text,
    source: {
      uri: "https://example.com/" + id,
      title,
      fetched_at: "2026-11-05T00:00:00Z",
      hint: None,
    },
    retrieval_score: 0.5,
    span: None,
  }
}

///|
// The conflicts reported for one (subject, unit) group.
fn conflicts_for(
  report : @src.ScanReport,
  subject : String,
  unit : String,
) -> Array[@src.Conflict] {
  let found : Array[@src.Conflict] = []
  for conflict in report.conflicts {
    if conflict.subject == subject && conflict.unit == unit {
      found.push(conflict)
    }
  }
  found
}

///|
test "conflicting numeric assertions produce explicit cross-document pairs with back-references" {
  let report = @src.scan(
    "france",
    @src.ScanConfig::default(),
    decode(CONFLICTS).candidates,
  )
  assert_eq(report.conflicts.length(), 7)
  for conflict in report.conflicts {
    // Every pair joins two different documents asserting different values.
    assert_true(conflict.left.evidence_id != conflict.right.evidence_id)
    assert_true(!near(conflict.left.value, conflict.right.value))
    // Both sides resolve to included evidence, and that evidence points back.
    let left = evidence_by_id(report, conflict.left.evidence_id)
    let right = evidence_by_id(report, conflict.right.evidence_id)
    assert_true(contains_string(left.conflict_ids, conflict.id))
    assert_true(contains_string(right.conflict_ids, conflict.id))
    // The reported span slices exactly the asserted value in its source.
    assert_eq(
      left.text[conflict.left.span.start:conflict.left.span.end].to_owned(),
      conflict.left.value_text,
    )
    assert_eq(
      right.text[conflict.right.span.start:conflict.right.span.end].to_owned(),
      conflict.right.value_text,
    )
  }

  // Population: a=68m, b=67m, c=68m -> a-b and b-c, never a-c.
  let population = conflicts_for(report, "france population", "million")
  assert_eq(population.length(), 2)
  assert_true(
    (
      population[0].left.value == 68000000.0 &&
      population[0].right.value == 67000000.0
    ) ||
    (
      population[1].left.value == 68000000.0 &&
      population[1].right.value == 67000000.0
    ),
  )
  // Tax rate: 20% vs 21%, grouped by the percent unit.
  let tax = conflicts_for(report, "tax rate", "%")
  assert_eq(tax.length(), 2)
  assert_true(near(tax[0].left.value, 20.0) || near(tax[0].right.value, 21.0))
  // Chinese colon + 万 multiplier + percent.
  assert_eq(conflicts_for(report, "法国人口", "万").length(), 1)
  assert_eq(conflicts_for(report, "税率", "%").length(), 1)
  // Dates are a distinct unit and conflict only on different days.
  let dates = conflicts_for(report, "effective date", "date")
  assert_eq(dates.length(), 1)
  assert_true(!near(dates[0].left.value, dates[0].right.value))
  // Same value (a vs c) and different units (km vs miles) never pair.
  assert_eq(conflicts_for(report, "france distance", "km").length(), 0)
  assert_eq(conflicts_for(report, "france distance", "mi").length(), 0)

  // Back-references are complete and per-evidence counts are exact.
  assert_eq(evidence_by_id(report, "a").conflict_ids.length(), 2)
  assert_eq(evidence_by_id(report, "b").conflict_ids.length(), 4)
  assert_eq(evidence_by_id(report, "c").conflict_ids.length(), 2)
  assert_eq(evidence_by_id(report, "cn-a").conflict_ids.length(), 2)
  assert_eq(evidence_by_id(report, "cn-b").conflict_ids.length(), 2)
  assert_eq(evidence_by_id(report, "date-a").conflict_ids.length(), 1)
  assert_eq(evidence_by_id(report, "date-b").conflict_ids.length(), 1)
  assert_eq(evidence_by_id(report, "distance-km").conflict_ids.length(), 0)
  assert_eq(evidence_by_id(report, "distance-mi").conflict_ids.length(), 0)
  assert_eq(evidence_by_id(report, "clean").conflict_ids.length(), 0)
}

///|
test "same values and different units never conflict" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate("usd-a", "Price is 10 USD.", ""),
    conflict_candidate("usd-b", "Price: 10 USD.", ""),
    conflict_candidate("km", "Distance is 10 km.", ""),
    conflict_candidate("mi", "Distance is 10 miles.", ""),
    conflict_candidate("pct", "Rate is 20%.", ""),
    conflict_candidate("bare", "Rate is 20.", ""),
  ]
  let report = @src.scan("q", @src.ScanConfig::default(), candidates)
  assert_eq(report.conflicts.length(), 0)
  for item in report.evidence {
    assert_eq(item.conflict_ids.length(), 0)
  }
}

///|
test "dates compare by calendar day across formats" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate("iso", "Effective date is 2024-03-01.", ""),
    conflict_candidate("cn", "Effective date：2024年3月1日。", ""),
    conflict_candidate("en", "Effective date: March 1, 2024.", ""),
    conflict_candidate("day-first", "Effective date: 1 March 2024.", ""),
    conflict_candidate("other", "Effective date: 2024-04-01.", ""),
  ]
  let report = @src.scan("q", @src.ScanConfig::default(), candidates)
  // Four documents agree on the same day; the fifth pairs with each of them.
  assert_eq(report.conflicts.length(), 4)
  for conflict in report.conflicts {
    assert_eq(conflict.subject, "effective date")
    assert_eq(conflict.unit, "date")
    assert_true(
      conflict.left.evidence_id == "other" ||
      conflict.right.evidence_id == "other",
    )
  }
}

///|
test "invalid date-like values are skipped instead of compared as bare numbers" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate("bad-a", "Effective date is 2024-13-40.", ""),
    conflict_candidate("bad-b", "Effective date is 2025-13-40.", ""),
  ]
  let report = @src.scan("q", @src.ScanConfig::default(), candidates)
  assert_eq(report.conflicts.length(), 0)
}

///|
test "malformed dates do not leak their month or day as claims" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate("bad-a", "Effective date is 2024-13-40.", ""),
    conflict_candidate("bad-b", "Effective date is 2024-14-40.", ""),
  ]
  let report = @src.scan("q", @src.ScanConfig::default(), candidates)
  assert_eq(report.conflicts.length(), 0)
}

///|
test "Chinese and ASCII volume units canonicalize together" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate("ml-cn", "Volume is 10 毫升", ""),
    conflict_candidate("ml-en", "Volume is 20 ml", ""),
  ]
  let report = @src.scan("q", @src.ScanConfig::default(), candidates)
  assert_eq(conflicts_for(report, "volume", "ml").length(), 1)
}

///|
test "a trailing noun does not change a qualified value" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate("people-a", "Population is 68 million people.", ""),
    conflict_candidate("people-b", "Population is 67 million people.", ""),
  ]
  let report = @src.scan("q", @src.ScanConfig::default(), candidates)
  assert_eq(conflicts_for(report, "population", "million").length(), 1)
}

///|
test "Chinese and mixed-language subjects and units are compared" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate("cn-a", "法国人口：6800万。", ""),
    conflict_candidate("cn-b", "法国人口：6700万。", ""),
    conflict_candidate("mixed-a", "France population 为 68 million.", ""),
    conflict_candidate("mixed-b", "France population：67 million.", ""),
    conflict_candidate("unit-cn", "Distance 为 10 公里", ""),
    conflict_candidate("unit-en", "Distance is 12 km", ""),
  ]
  let report = @src.scan("q", @src.ScanConfig::default(), candidates)
  assert_eq(conflicts_for(report, "法国人口", "万").length(), 1)
  assert_eq(conflicts_for(report, "france population", "million").length(), 1)
  assert_eq(conflicts_for(report, "distance", "km").length(), 1)
}

///|
test "unkeyed qualified values fall back to the title, then the query" {
  let title_a = conflict_candidate("title-a", "68 million", "France population")
  let title_b = conflict_candidate("title-b", "67 million", "France population")
  let by_title = @src.scan("q", @src.ScanConfig::default(), [title_a, title_b])
  assert_eq(by_title.conflicts.length(), 1)
  assert_eq(by_title.conflicts[0].subject, "france population")

  let query_a = conflict_candidate("query-a", "68 million", "")
  let query_b = conflict_candidate("query-b", "67 million", "")
  let by_query = @src.scan("France population", @src.ScanConfig::default(), [
    query_a, query_b,
  ])
  assert_eq(by_query.conflicts.length(), 1)
  assert_eq(by_query.conflicts[0].subject, "france population")
}

///|
test "missing subjects and unparsable values produce no claims" {
  let no_subject_a = conflict_candidate("ns-a", "68 million", "")
  let no_subject_b = conflict_candidate("ns-b", "67 million", "")
  let none = @src.scan("", @src.ScanConfig::default(), [
    no_subject_a, no_subject_b,
  ])
  assert_eq(none.conflicts.length(), 0)
  for item in none.evidence {
    assert_eq(item.conflict_ids.length(), 0)
  }

  let words_a = conflict_candidate("w-a", "France population is many.", "")
  let words_b = conflict_candidate("w-b", "France population is unknown.", "")
  let words = @src.scan("q", @src.ScanConfig::default(), [words_a, words_b])
  assert_eq(words.conflicts.length(), 0)
  for item in words.evidence {
    assert_eq(item.conflict_ids.length(), 0)
  }
}

///|
test "pairs are cross-document; one document's internal contradiction never pairs with itself" {
  let internal = conflict_candidate(
    "internal", "Price: 10 USD. Price: 20 USD.", "",
  )
  let alone = @src.scan("q", @src.ScanConfig::default(), [internal])
  assert_eq(alone.conflicts.length(), 0)
  let other = conflict_candidate("other", "Price: 15 USD.", "")
  let report = @src.scan("q", @src.ScanConfig::default(), [internal, other])
  assert_eq(report.conflicts.length(), 2)
  for conflict in report.conflicts {
    assert_true(conflict.left.evidence_id != conflict.right.evidence_id)
  }
}

///|
test "conflicts lower the consistency signal and subtract a rerank penalty" {
  let report = @src.scan(
    "france",
    @src.ScanConfig::default(),
    decode(CONFLICTS).candidates,
  )
  // b participates in four pairs, a and c in two, each date in one.
  let b = evidence_by_id(report, "b")
  assert_true(near(b.trust.breakdown.consistency, 1.0 / 5.0))
  assert_true(near(b.conflict_penalty, 1.0))
  let a = evidence_by_id(report, "a")
  assert_true(near(a.trust.breakdown.consistency, 1.0 / 3.0))
  assert_true(near(a.conflict_penalty, 1.0))
  let date_a = evidence_by_id(report, "date-a")
  assert_true(near(date_a.trust.breakdown.consistency, 0.5))
  assert_true(near(date_a.conflict_penalty, 0.5))
  let clean = evidence_by_id(report, "clean")
  assert_true(near(clean.trust.breakdown.consistency, 1.0))
  assert_true(near(clean.conflict_penalty, 0.0))
  for item in report.evidence {
    assert_true(
      near(
        item.rerank_score,
        item.retrieval_score + item.trust.score - item.conflict_penalty,
      ),
    )
  }
}

///|
test "conflict penalty can flip the rerank order while trust is held constant" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate("clean", "Status report.", ""),
    conflict_candidate("a", "Price is 10 USD.", ""),
    conflict_candidate("b", "Price is 20 USD.", ""),
  ]
  let no_penalty : @src.ScanConfig = {
    ..@src.ScanConfig::default(),
    trust_weight: Some(0.0),
    conflict_weight: Some(0.0),
  }
  let plain = @src.scan("q", no_penalty, candidates)
  // Trust is removed from rerank, so only the id tie-break orders them.
  assert_eq(plain.evidence[0].id, "a")
  assert_eq(plain.evidence[1].id, "b")
  assert_eq(plain.evidence[2].id, "clean")

  let penalized : @src.ScanConfig = {
    ..@src.ScanConfig::default(),
    trust_weight: Some(0.0),
    conflict_weight: Some(1.0),
  }
  let strict = @src.scan("q", penalized, candidates)
  assert_eq(strict.evidence[0].id, "clean")
  assert_eq(strict.evidence[1].id, "a")
  assert_eq(strict.evidence[2].id, "b")
  assert_true(near(evidence_by_id(strict, "a").conflict_penalty, 1.0))
  assert_true(near(evidence_by_id(strict, "clean").conflict_penalty, 0.0))
}

///|
test "conflict weight is configurable, echoed, and sanitized" {
  let config : @src.ScanConfig = {
    ..@src.ScanConfig::default(),
    conflict_weight: Some(0.25),
  }
  let report = @src.scan("france", config, decode(CONFLICTS).candidates)
  assert_eq(report.config == config, true)
  assert_true(near(evidence_by_id(report, "a").conflict_penalty, 0.5))

  let nan = @src.scan(
    "france",
    { ..@src.ScanConfig::default(), conflict_weight: Some(0.0 / 0.0), },
    decode(CONFLICTS).candidates,
  )
  // Non-finite falls back to the default 0.5; a has two pairs.
  assert_true(near(evidence_by_id(nan, "a").conflict_penalty, 1.0))

  let negative = @src.scan(
    "france",
    { ..@src.ScanConfig::default(), conflict_weight: Some(-1.0), },
    decode(CONFLICTS).candidates,
  )
  assert_true(near(evidence_by_id(negative, "a").conflict_penalty, 0.0))
}

///|
test "conflict penalties and consistency stay within [0, 1] for any weight" {
  let weights : Array[Double] = [0.0, 0.5, 1.0, 2.0, 1.0 / 0.0]
  for weight in weights {
    let config : @src.ScanConfig = {
      ..@src.ScanConfig::default(),
      conflict_weight: Some(weight),
    }
    let report = @src.scan("france", config, decode(CONFLICTS).candidates)
    assert_eq(report.conflicts.length(), 7)
    for item in report.evidence {
      assert_true(
        item.trust.breakdown.consistency >= 0.0 &&
        item.trust.breakdown.consistency <= 1.0,
      )
      assert_true(item.conflict_penalty >= 0.0 && item.conflict_penalty <= 1.0)
      assert_true(item.rerank_score.is_finite())
      for id in item.conflict_ids {
        let mut found = false
        for conflict in report.conflicts {
          if conflict.id == id {
            found = true
          }
        }
        assert_true(found)
      }
    }
  }
}

///|
test "conflict report is byte-identical across repeated runs" {
  let first = render(
    @src.scan(
      "france",
      @src.ScanConfig::default(),
      decode(CONFLICTS).candidates,
    ),
  )
  let second = render(
    @src.scan(
      "france",
      @src.ScanConfig::default(),
      decode(CONFLICTS).candidates,
    ),
  )
  assert_eq(first, second)
  assert_true(first.contains("\"conflicts\":[{\"id\":"))
  assert_true(first.contains("\"subject\":\"france population\""))
  assert_true(first.contains("\"unit\":\"date\""))
  assert_true(first.contains("\"conflict_ids\":[\""))
  assert_true(first.contains("\"conflict_penalty\":"))
}

///|
test "top_k truncates evidence but keeps the conflict audit trail" {
  let report = @src.scan(
    "france",
    { ..@src.ScanConfig::default(), top_k: Some(1), },
    decode(CONFLICTS).candidates,
  )
  assert_eq(report.evidence.length(), 1)
  assert_eq(report.conflicts.length(), 7)
  assert_eq(report.diagnostics.conflict_count, 7)
  assert_eq(stage_count(report, "conflict"), 7)
}

///|
test "different magnitudes never pair under one subject" {
  let candidates : Array[@src.Candidate] = [
    conflict_candidate(
      "mix-a", "France: population 68 million, GDP 3 trillion.", "",
    ),
    conflict_candidate("mix-b", "France: population 67 million.", ""),
  ]
  let report = @src.scan("q", @src.ScanConfig::default(), candidates)
  // Only the two population claims conflict; the GDP claim has a different
  // scale (trillion) and therefore a different unit.
  assert_eq(report.conflicts.length(), 1)
  assert_eq(conflicts_for(report, "france", "million").length(), 1)
  assert_eq(conflicts_for(report, "france", "trillion").length(), 0)
}
