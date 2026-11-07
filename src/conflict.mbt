// Deterministic cross-document conflict detection.
//
// Claims are explicit (subject, unit, value) triples extracted from text with
// fixed patterns. Values cover numbers, percentages, dates, and a small
// canonical unit vocabulary. Two documents conflict when they assert
// different values for the same normalized subject and the same unit. The
// detector never reasons about meaning: it groups and compares, nothing more.

///|
/// One side of a reported conflict: which evidence asserted what, the value
/// in comparable form, the asserted text, and the half-open UTF-16 span of
/// that text in the evidence.
#derive(ToJson, Eq)
pub(all) struct ConflictSide {
  evidence_id : String
  value : Double
  value_text : String
  span : Span
}

///|
pub extend ConflictSide with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend ConflictSide with Eq::{not_equal, equal}

///|
/// One explicit pair of incompatible claims about the same subject and unit.
/// `left` and `right` always name different evidence ids.
#derive(ToJson, Eq)
pub(all) struct Conflict {
  id : String
  subject : String
  unit : String
  left : ConflictSide
  right : ConflictSide
}

///|
pub extend Conflict with @moonbitlang/core/json.ToJson::{to_json}

///|
pub extend Conflict with Eq::{not_equal, equal}

///|
/// One extracted claim before pairing.
priv struct Claim {
  subject : String
  unit : String
  value : Double
  value_text : String
  evidence_id : String
  span : Span
}

///|
/// One parsed value: comparable number, end offset in the folded view, the
/// canonical unit, and whether it carries a unit/date/multiplier (a bare
/// number is only a claim when an explicit key precedes it).
priv struct ParsedValue {
  value : Double
  end : Int32
  unit : String
  qualified : Bool
}

///|
priv struct ParsedNumber {
  value : Double
  end : Int32
}

///|
priv struct ParsedDate {
  value : Double
  end : Int32
}

///|
/// Characters trimmed from the ends of a subject key.
const SUBJECT_TRIM : String = " \t\r\n\"'`“”‘’()（）[]【】{}<>#*_,;:.!?，。；：！？、-—–"

///|
/// Extract every claim from `candidates` and pair incompatible assertions.
/// Only cross-evidence pairs are reported, one Conflict per pair.
fn detect_conflicts(
  query : String,
  candidates : Array[Candidate],
) -> Array[Conflict] {
  let query_subject = normalize_key(query)
  let claims : Array[Claim] = []
  for candidate in candidates {
    let found = extract_claims(candidate, query_subject)
    for claim in found {
      claims.push(claim)
    }
  }
  let sorted = sort_claims(claims)
  let deduped = dedup_claims(sorted)
  pair_claims(deduped)
}

///|
/// Extract all claims from one candidate. The subject resolution order is:
/// explicit text key before a separator, then the source title, then the
/// normalized query. A qualified value (unit, percent, date, or multiplier)
/// may stand without an explicit key; a bare number needs one.
fn extract_claims(
  candidate : Candidate,
  query_subject : String,
) -> Array[Claim] {
  let text = candidate.text
  let folded = fold_text(text, MAX_SCAN_UNITS)
  let units = folded.units
  let origin = folded.origin
  let title_subject = normalize_key(candidate.source.title)
  let claims : Array[Claim] = []
  let mut index = 0
  let mut clause_start = 0
  let mut active_separator = -1
  let mut claimed_since_separator = false
  while index < units.length() {
    if is_clause_boundary(units[index]) {
      clause_start = index + 1
      active_separator = -1
      claimed_since_separator = false
      index = index + 1
      continue
    }
    // Do not start inside an ASCII word or number.
    if index > 0 &&
      (is_letter_unit(units[index - 1]) || is_digit_unit(units[index - 1])) {
      index = index + 1
      continue
    }
    let parsed = match parse_date_at(units, index) {
      Some(date) =>
        Some({
          value: date.value,
          end: date.end,
          unit: "date",
          qualified: true,
        })
      None => parse_numeric_value(units, index)
    }
    match parsed {
      None => index = index + 1
      Some(value) => {
        // Reject digits glued to a following word ("12abc"); a space before
        // an unknown word is fine ("68 million people" -> 68 million).
        if value.end < units.length() &&
          is_letter_unit(units[value.end]) &&
          !(value.end > 0 && units[value.end - 1] == 32) {
          index = index + 1
          continue
        }
        // A bare four-digit year followed by a date separator is a malformed
        // date, not a comparable number.
        if !value.qualified && looks_like_date_prefix(units, index, value.end) {
          index = skip_malformed_date(units, index)
          continue
        }
        let separator = find_last_subject_separator(units, clause_start, index)
        let mut used_separator = false
        let subject = match separator {
          Some(separator_start) => {
            used_separator = true
            if separator_start != active_separator {
              active_separator = separator_start
              claimed_since_separator = false
            }
            if claimed_since_separator && !value.qualified {
              index = value.end
              continue
            }
            let explicit = subject_from_units(
              units, clause_start, separator_start,
            )
            if explicit != "" {
              explicit
            } else if title_subject != "" {
              title_subject
            } else {
              query_subject
            }
          }
          None => {
            if !value.qualified {
              index = index + 1
              continue
            }
            if title_subject != "" {
              title_subject
            } else {
              query_subject
            }
          }
        }
        if subject == "" {
          index = value.end
          continue
        }
        let span_start = origin[index]
        let span_end = origin[value.end - 1] + 1
        claims.push({
          subject,
          unit: value.unit,
          value: value.value,
          value_text: text[span_start:span_end].to_owned(),
          evidence_id: candidate.id,
          span: { start: span_start, end: span_end, },
        })
        if used_separator {
          claimed_since_separator = true
        }
        index = value.end
      }
    }
  }
  claims
}

///|
/// Whether a bare four-digit number is followed by a date separator, which
/// means it was meant as a date but failed validation.
fn looks_like_date_prefix(
  units : Array[Int32],
  start : Int32,
  end : Int32,
) -> Bool {
  if end - start != 4 || end >= units.length() {
    return false
  }
  units[end] == 45 || units[end] == 47 || units[end] == 0x5E74
}

///|
/// Skip the whole malformed date-like run (digits, `-`, `/`, 年, 月, 日, 号)
/// so its month and day never leak as separate number claims.
fn skip_malformed_date(units : Array[Int32], start : Int32) -> Int32 {
  let mut index = start
  let mut done = false
  while index < units.length() && !done {
    let unit = units[index]
    if is_digit_unit(unit) ||
      unit == 45 ||
      unit == 47 ||
      unit == 0x5E74 ||
      unit == 0x6708 ||
      unit == 0x65E5 ||
      unit == 0x53F7 {
      index = index + 1
    } else {
      done = true
    }
  }
  index
}

///|
/// Parse a date at `index`, or nothing. Supported forms: YYYY-MM-DD,
/// YYYY/MM/DD, YYYY.MM.DD, YYYY年M月D日, Month D, YYYY, and D Month YYYY.
fn parse_date_at(units : Array[Int32], index : Int32) -> ParsedDate? {
  match parse_month_first_date(units, index) {
    Some(date) => Some(date)
    None =>
      match parse_day_first_date(units, index) {
        Some(date) => Some(date)
        None => parse_numeric_date(units, index)
      }
  }
}

///|
/// "March 1, 2024" or "March 1 2024".
fn parse_month_first_date(units : Array[Int32], index : Int32) -> ParsedDate? {
  match parse_month_name(units, index) {
    Some(pair) => {
      let month = pair.0
      let day_at = skip_spaces(units, pair.1)
      match parse_digits(units, day_at, 1, 2) {
        Some(day_pair) => {
          let comma_at = skip_spaces(units, day_pair.1)
          let year_at = if comma_at < units.length() && units[comma_at] == 44 {
            skip_spaces(units, comma_at + 1)
          } else {
            comma_at
          }
          match parse_digits(units, year_at, 4, 4) {
            Some(year_pair) =>
              make_date(year_pair.0, month, day_pair.0, year_pair.1)
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
/// "1 March 2024".
fn parse_day_first_date(units : Array[Int32], index : Int32) -> ParsedDate? {
  match parse_digits(units, index, 1, 2) {
    Some(day_pair) =>
      if day_pair.1 < units.length() && units[day_pair.1] == 32 {
        let month_at = skip_spaces(units, day_pair.1)
        match parse_month_name(units, month_at) {
          Some(pair) => {
            let year_at = skip_spaces(units, pair.1)
            match parse_digits(units, year_at, 4, 4) {
              Some(year_pair) =>
                make_date(year_pair.0, pair.0, day_pair.0, year_pair.1)
              None => None
            }
          }
          None => None
        }
      } else {
        None
      }
    None => None
  }
}

///|
/// "2024-03-01", "2024/03/01", "2024.03.01", or "2024年3月1日".
fn parse_numeric_date(units : Array[Int32], index : Int32) -> ParsedDate? {
  match parse_digits(units, index, 4, 4) {
    Some(year_pair) =>
      if year_pair.1 < units.length() {
        let separator = units[year_pair.1]
        if separator == 45 || separator == 47 || separator == 46 {
          match parse_digits(units, year_pair.1 + 1, 1, 2) {
            Some(month_pair) =>
              if month_pair.1 < units.length() &&
                units[month_pair.1] == separator {
                match parse_digits(units, month_pair.1 + 1, 1, 2) {
                  Some(day_pair) =>
                    make_date(year_pair.0, month_pair.0, day_pair.0, day_pair.1)
                  None => None
                }
              } else {
                None
              }
            None => None
          }
        } else if separator == 0x5E74 {
          // 年
          match parse_digits(units, year_pair.1 + 1, 1, 2) {
            Some(month_pair) =>
              if month_pair.1 < units.length() && units[month_pair.1] == 0x6708 {
                // 月
                match parse_digits(units, month_pair.1 + 1, 1, 2) {
                  Some(day_pair) => {
                    let mut end = day_pair.1
                    if end < units.length() &&
                      (units[end] == 0x65E5 || units[end] == 0x53F7) {
                      // 日 or 号
                      end = end + 1
                    }
                    make_date(year_pair.0, month_pair.0, day_pair.0, end)
                  }
                  None => None
                }
              } else {
                None
              }
            None => None
          }
        } else {
          None
        }
      } else {
        None
      }
    None => None
  }
}

///|
/// Validate a date and turn it into a day ordinal (days since 1970-01-01).
fn make_date(
  year : Int32,
  month : Int32,
  day : Int32,
  end : Int32,
) -> ParsedDate? {
  if year < 1 ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > days_in_month(year, month) {
    None
  } else {
    Some({ value: days_from_civil(year, month, day).to_double(), end, })
  }
}

///|
fn is_leap_year(year : Int32) -> Bool {
  (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

///|
fn days_in_month(year : Int32, month : Int32) -> Int32 {
  if month == 1 ||
    month == 3 ||
    month == 5 ||
    month == 7 ||
    month == 8 ||
    month == 10 ||
    month == 12 {
    31
  } else if month == 4 || month == 6 || month == 9 || month == 11 {
    30
  } else if month == 2 {
    if is_leap_year(year) {
      29
    } else {
      28
    }
  } else {
    0
  }
}

///|
/// Days since 1970-01-01 for a proleptic Gregorian date (years >= 1).
fn days_from_civil(year : Int32, month : Int32, day : Int32) -> Int32 {
  let adjusted_year = if month <= 2 { year - 1 } else { year }
  let era = adjusted_year / 400
  let year_of_era = adjusted_year - era * 400
  let adjusted_month = if month > 2 { month - 3 } else { month + 9 }
  let day_of_year = (153 * adjusted_month + 2) / 5 + day - 1
  let day_of_era = year_of_era * 365 +
    year_of_era / 4 -
    year_of_era / 100 +
    day_of_year
  era * 146097 + day_of_era - 719468
}

///|
/// Month name or three-letter abbreviation at `index`, as (month, end).
fn parse_month_name(units : Array[Int32], index : Int32) -> (Int32, Int32)? {
  match match_word(units, index, "january") {
    Some(end) => return Some((1, end))
    None => ()
  }
  match match_word(units, index, "february") {
    Some(end) => return Some((2, end))
    None => ()
  }
  match match_word(units, index, "march") {
    Some(end) => return Some((3, end))
    None => ()
  }
  match match_word(units, index, "april") {
    Some(end) => return Some((4, end))
    None => ()
  }
  match match_word(units, index, "may") {
    Some(end) => return Some((5, end))
    None => ()
  }
  match match_word(units, index, "june") {
    Some(end) => return Some((6, end))
    None => ()
  }
  match match_word(units, index, "july") {
    Some(end) => return Some((7, end))
    None => ()
  }
  match match_word(units, index, "august") {
    Some(end) => return Some((8, end))
    None => ()
  }
  match match_word(units, index, "september") {
    Some(end) => return Some((9, end))
    None => ()
  }
  match match_word(units, index, "october") {
    Some(end) => return Some((10, end))
    None => ()
  }
  match match_word(units, index, "november") {
    Some(end) => return Some((11, end))
    None => ()
  }
  match match_word(units, index, "december") {
    Some(end) => return Some((12, end))
    None => ()
  }
  match match_word(units, index, "jan") {
    Some(end) => Some((1, end))
    None =>
      match match_word(units, index, "feb") {
        Some(end) => Some((2, end))
        None =>
          match match_word(units, index, "mar") {
            Some(end) => Some((3, end))
            None =>
              match match_word(units, index, "apr") {
                Some(end) => Some((4, end))
                None =>
                  match match_word(units, index, "jun") {
                    Some(end) => Some((6, end))
                    None =>
                      match match_word(units, index, "jul") {
                        Some(end) => Some((7, end))
                        None =>
                          match match_word(units, index, "aug") {
                            Some(end) => Some((8, end))
                            None =>
                              match match_word(units, index, "sept") {
                                Some(end) => Some((9, end))
                                None =>
                                  match match_word(units, index, "sep") {
                                    Some(end) => Some((9, end))
                                    None =>
                                      match match_word(units, index, "oct") {
                                        Some(end) => Some((10, end))
                                        None =>
                                          match
                                            match_word(units, index, "nov") {
                                            Some(end) => Some((11, end))
                                            None =>
                                              match
                                                match_word(units, index, "dec") {
                                                Some(end) => Some((12, end))
                                                None => None
                                              }
                                          }
                                      }
                                  }
                              }
                          }
                      }
                  }
              }
          }
      }
  }
}

///|
/// Parse a number with optional sign, thousands separators, and decimals.
fn parse_number(units : Array[Int32], index : Int32) -> ParsedNumber? {
  if index >= units.length() {
    return None
  }
  let mut at = index
  let mut sign = 1.0
  if units[at] == 45 {
    sign = -1.0
    at = at + 1
  } else if units[at] == 43 {
    at = at + 1
  }
  let mut value = 0.0
  let mut digits = 0
  let mut seen_dot = false
  let mut scale = 1.0
  let mut done = false
  while at < units.length() && !done {
    match digit_value(units[at]) {
      Some(digit) => {
        digits = digits + 1
        if seen_dot {
          scale = scale * 10.0
          value = value + digit.to_double() / scale
        } else {
          value = value * 10.0 + digit.to_double()
        }
        at = at + 1
      }
      None =>
        if units[at] == 44 &&
          digits > 0 &&
          at + 1 < units.length() &&
          is_digit_unit(units[at + 1]) {
          at = at + 1
        } else if units[at] == 46 && !seen_dot {
          seen_dot = true
          at = at + 1
        } else {
          done = true
        }
    }
  }
  if digits == 0 {
    None
  } else {
    Some({ value: sign * value, end: at, })
  }
}

///|
/// Parse a number, optional multiplier, and optional unit.
fn parse_numeric_value(units : Array[Int32], index : Int32) -> ParsedValue? {
  match parse_number(units, index) {
    None => None
    Some(number) => {
      let multiplier_at = skip_spaces(units, number.end)
      let multiplier = parse_multiplier(units, multiplier_at)
      let mut value_end = if multiplier.0 != 1.0 {
        multiplier.1
      } else {
        number.end
      }
      let unit_at = skip_spaces(units, value_end)
      let unit = parse_unit(units, unit_at)
      if unit.0 != "" {
        value_end = unit.1
      }
      Some({
        value: number.value * multiplier.0,
        end: value_end,
        unit: unit.0,
        qualified: unit.0 != "" || multiplier.0 != 1.0,
      })
    }
  }
}

///|
/// Multiplier word at `index`, as (factor, end); 1.0 when absent.
fn parse_multiplier(units : Array[Int32], index : Int32) -> (Double, Int32) {
  match match_word(units, index, "thousand") {
    Some(end) => return (1000.0, end)
    None => ()
  }
  match match_word(units, index, "million") {
    Some(end) => return (1000000.0, end)
    None => ()
  }
  match match_word(units, index, "billion") {
    Some(end) => return (1000000000.0, end)
    None => ()
  }
  match match_word(units, index, "trillion") {
    Some(end) => return (1000000000000.0, end)
    None => ()
  }
  if index < units.length() {
    let unit = units[index]
    if unit == 0x5343 {
      // 千
      return (1000.0, index + 1)
    }
    if unit == 0x4E07 {
      // 万
      return (10000.0, index + 1)
    }
    if unit == 0x4EBF {
      // 亿
      return (100000000.0, index + 1)
    }
    if unit == 107 {
      // k, only when not glued to another letter
      let end = index + 1
      if end >= units.length() || !is_letter_unit(units[end]) {
        return (1000.0, end)
      }
    }
  }
  (1.0, index)
}

///|
/// Canonical unit name at `index`, as (unit, end); ("", index) when absent.
fn parse_unit(units : Array[Int32], index : Int32) -> (String, Int32) {
  if index >= units.length() {
    return ("", index)
  }
  if units[index] == 37 {
    return ("%", index + 1)
  }
  if units[index] == 0x00B0 && index + 1 < units.length() {
    if units[index + 1] == 99 {
      return ("c", index + 2)
    }
    if units[index + 1] == 102 {
      return ("f", index + 2)
    }
  }
  match match_units(units, index, "公里") {
    true => return with_area_suffix(units, "km", index + 2)
    false => ()
  }
  match match_units(units, index, "千米") {
    true => return with_area_suffix(units, "km", index + 2)
    false => ()
  }
  match match_units(units, index, "英里") {
    true => return with_area_suffix(units, "mi", index + 2)
    false => ()
  }
  match match_units(units, index, "公斤") {
    true => return with_area_suffix(units, "kg", index + 2)
    false => ()
  }
  match match_units(units, index, "千克") {
    true => return with_area_suffix(units, "kg", index + 2)
    false => ()
  }
  match match_units(units, index, "毫升") {
    true => return with_area_suffix(units, "ml", index + 2)
    false => ()
  }
  match match_units(units, index, "毫秒") {
    true => return with_area_suffix(units, "ms", index + 2)
    false => ()
  }
  match match_units(units, index, "分钟") {
    true => return with_area_suffix(units, "min", index + 2)
    false => ()
  }
  match match_units(units, index, "小时") {
    true => return with_area_suffix(units, "h", index + 2)
    false => ()
  }
  match match_units(units, index, "百分比") {
    true => return ("%", index + 3)
    false => ()
  }
  match match_units(units, index, "人民币") {
    true => return with_area_suffix(units, "cny", index + 3)
    false => ()
  }
  match match_units(units, index, "美元") {
    true => return with_area_suffix(units, "usd", index + 2)
    false => ()
  }
  match match_units(units, index, "欧元") {
    true => return with_area_suffix(units, "eur", index + 2)
    false => ()
  }
  match match_units(units, index, "英镑") {
    true => return with_area_suffix(units, "gbp", index + 2)
    false => ()
  }
  match match_units(units, index, "摄氏度") {
    true => return with_area_suffix(units, "c", index + 3)
    false => ()
  }
  match match_units(units, index, "华氏度") {
    true => return with_area_suffix(units, "f", index + 3)
    false => ()
  }
  let single = units[index]
  if single == 0x5143 {
    // 元
    return ("cny", index + 1)
  }
  if single == 0x7C73 {
    // 米
    return with_area_suffix(units, "m", index + 1)
  }
  if single == 0x514B {
    // 克
    return ("g", index + 1)
  }
  if single == 0x78C5 {
    // 磅
    return with_area_suffix(units, "lb", index + 1)
  }
  if single == 0x5347 {
    // 升
    return with_area_suffix(units, "l", index + 1)
  }
  if single == 0x79D2 {
    // 秒
    return ("s", index + 1)
  }
  if single == 0x5929 {
    // 天
    return ("day", index + 1)
  }
  if single == 0x5468 {
    // 周
    return ("week", index + 1)
  }
  if single == 0x6708 {
    // 月
    return ("month", index + 1)
  }
  if single == 0x5E74 {
    // 年
    return ("year", index + 1)
  }
  if is_letter_unit(units[index]) {
    let mut end = index
    while end < units.length() && is_letter_unit(units[end]) {
      end = end + 1
    }
    let token = units_to_string(units, index, end)
    let unit = canonical_unit(token)
    if unit != "" {
      return with_area_suffix(units, unit, end)
    }
  }
  ("", index)
}

///|
/// Append "2" for area units ("km2", "m2", "km²").
fn with_area_suffix(
  units : Array[Int32],
  unit : String,
  end : Int32,
) -> (String, Int32) {
  if end < units.length() {
    if units[end] == 50 {
      return (unit + "2", end + 1)
    }
    if units[end] == 0xB2 {
      return (unit + "2", end + 1)
    }
  }
  (unit, end)
}

///|
/// Canonical ASCII unit name, or "" when unknown.
fn canonical_unit(token : String) -> String {
  if token == "percent" || token == "percentage" || token == "pct" {
    "%"
  } else if token == "cny" || token == "rmb" || token == "yuan" {
    "cny"
  } else if token == "usd" || token == "dollar" || token == "dollars" {
    "usd"
  } else if token == "eur" || token == "euro" || token == "euros" {
    "eur"
  } else if token == "gbp" {
    "gbp"
  } else if token == "km" ||
    token == "kilometer" ||
    token == "kilometers" ||
    token == "kilometre" ||
    token == "kilometres" {
    "km"
  } else if token == "m" ||
    token == "meter" ||
    token == "meters" ||
    token == "metre" ||
    token == "metres" {
    "m"
  } else if token == "cm" || token == "centimeter" || token == "centimeters" {
    "cm"
  } else if token == "mm" || token == "millimeter" || token == "millimeters" {
    "mm"
  } else if token == "ml" ||
    token == "milliliter" ||
    token == "milliliters" ||
    token == "millilitre" ||
    token == "millilitres" {
    "ml"
  } else if token == "l" ||
    token == "liter" ||
    token == "liters" ||
    token == "litre" ||
    token == "litres" {
    "l"
  } else if token == "mi" || token == "mile" || token == "miles" {
    "mi"
  } else if token == "kg" || token == "kilogram" || token == "kilograms" {
    "kg"
  } else if token == "g" || token == "gram" || token == "grams" {
    "g"
  } else if token == "lb" ||
    token == "lbs" ||
    token == "pound" ||
    token == "pounds" {
    "lb"
  } else if token == "ms" || token == "millisecond" || token == "milliseconds" {
    "ms"
  } else if token == "s" ||
    token == "sec" ||
    token == "second" ||
    token == "seconds" {
    "s"
  } else if token == "min" || token == "minute" || token == "minutes" {
    "min"
  } else if token == "h" || token == "hr" || token == "hour" || token == "hours" {
    "h"
  } else if token == "day" || token == "days" {
    "day"
  } else if token == "week" || token == "weeks" {
    "week"
  } else if token == "month" || token == "months" {
    "month"
  } else if token == "year" || token == "years" {
    "year"
  } else if token == "kb" || token == "mb" || token == "gb" || token == "tb" {
    token
  } else if token == "celsius" {
    "c"
  } else if token == "fahrenheit" {
    "f"
  } else {
    ""
  }
}

///|
/// The last subject separator in [from, to), or None. Colon, equals, English
/// copulas, and a small Chinese separator set are recognized.
fn find_last_subject_separator(
  units : Array[Int32],
  from : Int32,
  to : Int32,
) -> Int32? {
  let mut found : Int32? = None
  let mut index = from
  while index < to {
    let unit = units[index]
    if unit == 58 {
      let previous_digit = index > from && is_digit_unit(units[index - 1])
      let next_digit = index + 1 < to && is_digit_unit(units[index + 1])
      let url = index + 2 < to &&
        units[index + 1] == 47 &&
        units[index + 2] == 47
      if !(previous_digit && next_digit) && !url {
        found = Some(index)
      }
    } else if unit == 61 {
      let previous_equal = index > from && units[index - 1] == 61
      let next_equal = index + 1 < to && units[index + 1] == 61
      if !previous_equal && !next_equal {
        found = Some(index)
      }
    } else if match_units(units, index, " is ") ||
      match_units(units, index, " was ") ||
      match_units(units, index, " are ") ||
      match_units(units, index, " were ") ||
      match_units(units, index, " will be ") {
      found = Some(index)
    } else if unit == 0x4E3A || unit == 0x662F {
      // 为 / 是
      found = Some(index)
    } else if match_units(units, index, "达到") ||
      match_units(units, index, "约为") ||
      match_units(units, index, "等于") {
      found = Some(index)
    }
    index = index + 1
  }
  found
}

///|
/// Build and normalize a subject key from folded units.
fn subject_from_units(
  units : Array[Int32],
  start : Int32,
  end : Int32,
) -> String {
  let mut from = start
  let mut to = end
  while from < to && (units[from] == 32 || is_subject_trim_unit(units[from])) {
    from = from + 1
  }
  while to > from &&
        (units[to - 1] == 32 || is_subject_trim_unit(units[to - 1])) {
    to = to - 1
  }
  if to - from < 2 {
    return ""
  }
  normalize_subject_string(units_to_string(units, from, to))
}

///|
/// Normalize a subject key: trim, drop a leading article, cap at 80 units.
fn normalize_subject_string(raw : String) -> String {
  let mut subject = raw.trim(chars=SUBJECT_TRIM).to_owned()
  subject = subject.trim().to_owned()
  subject = match subject.strip_prefix("the ") {
    Some(rest) => rest.to_owned()
    None => subject
  }
  subject = match subject.strip_prefix("a ") {
    Some(rest) => rest.to_owned()
    None => subject
  }
  subject = match subject.strip_prefix("an ") {
    Some(rest) => rest.to_owned()
    None => subject
  }
  subject = subject.trim(chars=SUBJECT_TRIM).to_owned()
  subject = subject.trim().to_owned()
  if subject.length() < 2 {
    return ""
  }
  if subject.length() > 80 {
    subject = subject[subject.length() - 80:].to_owned()
  }
  subject
}

///|
/// Normalize a title or query into a subject key.
fn normalize_key(text : String) -> String {
  let folded = fold_text(text, MAX_SCAN_UNITS)
  normalize_subject_string(
    units_to_string(folded.units, 0, folded.units.length()),
  )
}

///|
/// Build a string from folded units, skipping lone surrogates (subject keys
/// are expected to be BMP text).
fn units_to_string(units : Array[Int32], start : Int32, end : Int32) -> String {
  let chars : Array[Char] = []
  let mut index = start
  while index < end {
    let unit = units[index]
    if unit < 0xD800 || unit > 0xDFFF {
      match unit.to_char() {
        Some(character) => chars.push(character)
        None => ()
      }
    }
    index = index + 1
  }
  String::from_iter(chars.iter())
}

///|
fn is_clause_boundary(unit : Int32) -> Bool {
  unit == 46 || unit == 0x3002 || unit == 59 || unit == 33 || unit == 63
}

///|
fn is_subject_trim_unit(unit : Int32) -> Bool {
  unit == 34 ||
  unit == 39 ||
  unit == 40 ||
  unit == 41 ||
  unit == 44 ||
  unit == 45 ||
  unit == 46 ||
  unit == 47 ||
  unit == 58 ||
  unit == 59 ||
  unit == 60 ||
  unit == 62 ||
  unit == 91 ||
  unit == 93 ||
  unit == 95 ||
  unit == 123 ||
  unit == 125 ||
  unit == 0x2018 ||
  unit == 0x2019 ||
  unit == 0x201C ||
  unit == 0x201D ||
  unit == 0x3001 ||
  unit == 0x3002 ||
  unit == 0x3008 ||
  unit == 0x3009 ||
  unit == 0x3010 ||
  unit == 0x3011 ||
  unit == 0xFF0C ||
  unit == 0xFF1A ||
  unit == 0xFF1B
}

///|
fn is_letter_unit(unit : Int32) -> Bool {
  unit >= 97 && unit <= 122
}

///|
fn is_digit_unit(unit : Int32) -> Bool {
  unit >= 48 && unit <= 57
}

///|
fn digit_value(unit : Int32) -> Int32? {
  if unit >= 48 && unit <= 57 {
    Some(unit - 48)
  } else {
    None
  }
}

///|
fn skip_spaces(units : Array[Int32], index : Int32) -> Int32 {
  let mut at = index
  while at < units.length() && units[at] == 32 {
    at = at + 1
  }
  at
}

///|
/// Parse `min..max` digits at `index`, as (value, end). Rejects a longer run.
fn parse_digits(
  units : Array[Int32],
  index : Int32,
  min : Int32,
  max : Int32,
) -> (Int32, Int32)? {
  let mut at = index
  let mut value = 0
  let mut count = 0
  let mut done = false
  while at < units.length() && count < max && !done {
    match digit_value(units[at]) {
      Some(digit) => {
        value = value * 10 + digit
        count = count + 1
        at = at + 1
      }
      None => done = true
    }
  }
  if count < min {
    None
  } else if at < units.length() && is_digit_unit(units[at]) {
    None
  } else {
    Some((value, at))
  }
}

///|
/// Exact match of a lowercase ASCII word at `index`, with word boundaries.
fn match_word(units : Array[Int32], index : Int32, word : String) -> Int32? {
  if index > 0 && is_letter_unit(units[index - 1]) {
    return None
  }
  if !match_units(units, index, word) {
    return None
  }
  let end = index + word.length()
  if end < units.length() && is_letter_unit(units[end]) {
    None
  } else {
    Some(end)
  }
}

///|
/// Exact match of a folded pattern at `index`.
fn match_units(units : Array[Int32], index : Int32, pattern : String) -> Bool {
  let expected = pattern.code_units()
  if index < 0 || index + expected.length() > units.length() {
    return false
  }
  let mut offset = 0
  while offset < expected.length() {
    if units[index + offset] != fold_unit(expected[offset].to_int()) {
      return false
    }
    offset = offset + 1
  }
  true
}

///|
/// Whether two comparable values are equal within the deterministic epsilon.
fn values_equal(first : Double, second : Double) -> Bool {
  let delta = first - second
  delta < 1.0e-9 && delta > -1.0e-9
}

///|
/// Canonical claim order: subject, unit, evidence id, span start, value.
fn claim_before(first : Claim, second : Claim) -> Bool {
  if first.subject < second.subject {
    true
  } else if first.subject > second.subject {
    false
  } else if first.unit < second.unit {
    true
  } else if first.unit > second.unit {
    false
  } else if first.evidence_id < second.evidence_id {
    true
  } else if first.evidence_id > second.evidence_id {
    false
  } else if first.span.start < second.span.start {
    true
  } else if first.span.start > second.span.start {
    false
  } else {
    first.value < second.value
  }
}

///|
fn sort_claims(claims : Array[Claim]) -> Array[Claim] {
  let working = claims.copy()
  for target in 0..<working.length() {
    let mut best = target
    for probe in (target + 1)..<working.length() {
      if claim_before(working[probe], working[best]) {
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
/// Drop repeated assertions by the same evidence for the same subject, unit,
/// and value. Different values from one evidence are kept.
fn dedup_claims(claims : Array[Claim]) -> Array[Claim] {
  let kept : Array[Claim] = []
  for claim in claims {
    let mut duplicate = false
    for earlier in kept {
      if earlier.subject == claim.subject &&
        earlier.unit == claim.unit &&
        earlier.evidence_id == claim.evidence_id &&
        values_equal(earlier.value, claim.value) {
        duplicate = true
      }
    }
    if !duplicate {
      kept.push(claim)
    }
  }
  kept
}

///|
/// Pair different-evidence claims with different values in the same
/// (subject, unit) group.
fn pair_claims(claims : Array[Claim]) -> Array[Conflict] {
  let conflicts : Array[Conflict] = []
  let mut index = 0
  while index < claims.length() {
    let subject = claims[index].subject
    let unit = claims[index].unit
    let mut group_end = index + 1
    while group_end < claims.length() &&
          claims[group_end].subject == subject &&
          claims[group_end].unit == unit {
      group_end = group_end + 1
    }
    let mut left_index = index
    while left_index < group_end {
      let mut right_index = left_index + 1
      while right_index < group_end {
        let left = claims[left_index]
        let right = claims[right_index]
        if left.evidence_id != right.evidence_id &&
          !values_equal(left.value, right.value) {
          conflicts.push({
            id: conflict_id(left, right),
            subject,
            unit,
            left: {
              evidence_id: left.evidence_id,
              value: left.value,
              value_text: left.value_text,
              span: left.span,
            },
            right: {
              evidence_id: right.evidence_id,
              value: right.value,
              value_text: right.value_text,
              span: right.span,
            },
          })
        }
        right_index = right_index + 1
      }
      left_index = left_index + 1
    }
    index = group_end
  }
  conflicts
}

///|
fn conflict_id(left : Claim, right : Claim) -> String {
  left.subject +
  "|" +
  left.unit +
  "|" +
  left.evidence_id +
  "=" +
  left.value_text +
  "|" +
  right.evidence_id +
  "=" +
  right.value_text
}

///|
/// Conflict ids for one evidence id, in conflict-list order, plus the count.
fn conflict_refs(
  evidence_id : String,
  conflicts : Array[Conflict],
) -> (Array[String], Int32) {
  let ids : Array[String] = []
  let mut count = 0
  for conflict in conflicts {
    if conflict.left.evidence_id == evidence_id ||
      conflict.right.evidence_id == evidence_id {
      ids.push(conflict.id)
      count = count + 1
    }
  }
  (ids, count)
}
