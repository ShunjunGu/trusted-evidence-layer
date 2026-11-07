# 04 — 多文档冲突检测

**What to build:** 同一 subject 的数值、日期、百分比、单位不一致被报告为显式配对，冲突双方在报告中互相引用，并在信任分与重排中体现惩罚。

**Blocked by:** 02 — 信任评分（来源与内容分项）

**Status:** resolved

- [x] claim 抽取覆盖数值、日期、百分比、单位；subject 来自元数据键或查询锚定词
- [x] 冲突以显式配对出现在报告中，双方互相引用
- [x] 相同取值不报冲突；不同单位不误判为冲突
- [x] 一致性分项接入信任分；冲突惩罚进入重排
- [x] fixture：冲突语料产生预期配对，无冲突语料产生空列表
- [x] 边界：缺失 subject、无法解析的值、中英混排

## Answer

### 管线与契约（`src/conflict.mbt` + `src/lib.mbt`）

- 管线顺序：`dedupe → risk → isolate → conflict → trust → rerank → topk`。冲突只在上一步存活（未隔离）的 evidence 之间检测；被 drop 的块不参与。
- 新增公开类型 `Conflict { id, subject, unit, left, right }` 与 `ConflictSide { evidence_id, value, value_text, span }`。
- `ScanReport` 新增 `conflicts`；`Evidence` 新增 `conflict_ids`（指回参与的冲突 id）与 `conflict_penalty`；`Diagnostics` 新增 `conflict_count`；阶段序列新增 `conflict`。
- 每个冲突是两条不同 evidence 的显式配对；`left`/`right` 各带 evidence_id、可比较的 `value`、原样 `value_text` 与可切片原文的 span。同一 evidence 的内部矛盾不会与自己配对。

### claim 抽取

- **subject 解析顺序**：分隔符前的显式文本键 → `source.title` → 归一化 query。分隔符含 `:` / `：` / `=`、` is/was/are/were/will be`、`为/是/达到/约为/等于`。subject 归一化为 ASCII 小写、折叠空白、剥离前导 `the/a/an`、最长 80 个 UTF-16 码元；无法解析 subject 的值被忽略。
- **值类型**：带符号/千分位/小数的数值；倍数 `thousand/million/billion/trillion`、`千/万/亿`、`k`；百分比 `%` / `percent` / `百分比`；日期 `YYYY-MM-DD`、`YYYY/MM/DD`、`YYYY.MM.DD`、`YYYY年M月D日`、`Month D, YYYY`、`D Month YYYY`。日期归一到 1970-01-01 起的天序号比较。
- **单位词表**：货币 `cny/usd/eur/gbp`、距离 `mm/cm/m/km/mi`、质量 `g/kg/lb`、时间 `ms/s/min/h/day/week/month/year`、数据量 `kb..tb`、温度 `c/f`、面积 `km2/m2`，以及无单位计数 `""`。
- **倍数作为单位的 scale 保留**：`68 million` 的单位是 `million`，`3 trillion` 的单位是 `trillion`，`6800万` 的单位是 `万`；`k` / `千` / `thousand` 统一为 `thousand`。因此不同量级不会互相配对。
- 只有带分隔符的裸数值、或带单位/百分比/日期/倍数的值才成为 claim；`abc123` 这类词内数字被忽略；四位数后紧跟 `-` / `/` / `年` 的非法日期被整体跳过而不是降级成裸数字。
- 短语/数字匹配复用风险扫描的 `fold_text`：隐形字符剥离、空白折叠、全角 ASCII 折叠，span 映射回原文。

### 配对与惩罚

- 按 `(subject, unit)` 分组；不同 evidence、不同取值才配对。相同取值不报；不同单位不互相比较（`10 km` 与 `10 miles`、`68 million` 与 `3 trillion` 均分属不同组）。
- 同一 evidence 对同一 (subject, unit, value) 的重复断言去重；不同取值的内部矛盾保留，但只与其它 evidence 配对。
- `trust.breakdown.consistency = 1 / (1 + conflict_count)` 接入内容分项。
- `conflict_penalty = clamp01(conflict_weight × conflict_count)` 从重排分扣除：`rerank = retrieval + trust_weight × trust − conflict_penalty`。默认 `conflict_weight = 0.5`；非有限值回退 0.5，负值视为 0。
- `ScanConfig` 新增 `conflict_weight`（可选、默认 `{}` 回显），CLI 新增 `--conflict-weight W`（非负有限数，0 允许：关闭额外重排惩罚但保留一致性信号）。
- `top_k` 只截断 `evidence`；`conflicts` 与 evidence 的 `conflict_ids` 作为审计数据保留。

### fixture 与测试

- 新增 `tests/fixtures/conflicts.json`（10 块）：法国人口 68m/67m/68m、税率 20%/21%/20%、中文人口 6800万/6700万、中文税率 20%/21%、日期 2024-03-01/2024-04-01、距离 10 km/10 miles、干净块。嵌入常量 `CONFLICTS` 与文件同形。
- 预期 7 个冲突：人口 2、税率 2、中文人口 1、中文税率 1、日期 1；距离因单位不同为 0；相同取值的 a/c 不配对。
- 覆盖：显式配对与双向引用、同值、不同单位、日期多格式与非法日期、中英混排、title/query 回退、缺失 subject、无法解析值、跨文档限定、top_k 不截断冲突、确定性与 [0,1] 性质。
- README 新增「冲突检测」与「冲突检测边界」；`CONTEXT.md` 新增「一致性」术语。

### 审核修正

- **F1（已修）**：multiplier 原先只折进 value、unit 仍为 `""`，导致同一 subject 下不同量级的属性互相配对（`France: population 68 million, GDP 3 trillion` 与 `population 67 million` 产出 `3 trillion × 67 million` 的假冲突）。现把 multiplier 作为 unit 的 scale 保留，并统一 `k` / `千` / `thousand` 的规范名；新增回归测试 `different magnitudes never pair under one subject`。
- **F2（记录为边界）**：共享一个分隔符的多个属性仍归入同一 subject（`France: population 68 million, GDP 70 million` 同属 `france`）。README 已注明：同子句多属性应各自给键。
- **F3（记录为边界）**：`(subject, unit)` 组内配对为 O(k²)，大候选集会产生大报告；README 已注明保持检索级 top-k。

### 验证

- `moon check --deny-warn --target all` → 0 warning、0 error。
- `moon test --target all` → 86/86 通过（wasm、wasm-gc、js、native）；含非法日期不泄漏月/日 claim、中文/英文体积单位统一、跨量级不配对的回归用例。
- CLI 端到端：`scan france tests/fixtures/conflicts.json` → 10 evidence / 7 conflicts / blocked false；连跑两次 SHA256 均为 `b44d64caabc6aa4fccf0520898c9a89bab49578f4f25d7c2fcc9aa2be816ff9b`。
- 重排惩罚可翻转顺序：在 `trust_weight = 0` 的隔离实验中，无惩罚时按 id 为 `a, b, clean`；`conflict_weight = 1` 时干净块 `clean` 以 0.5 对 −0.5 升至首位。
