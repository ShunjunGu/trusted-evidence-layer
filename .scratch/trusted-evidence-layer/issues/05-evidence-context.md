# 05 — 证据上下文组装

**What to build:** `evaluate` 在令牌预算内输出带 `[n]` 引用与风险/冲突附录的证据上下文；每条引用可解析到已包含证据；预算永不被突破。

**Blocked by:** 03 — 风险扫描与隔离策略；04 — 多文档冲突检测

**Status:** resolved

- [x] 上下文在预算内贪心组装，令牌估算近似（ASCII 按词、CJK 按字）
- [x] 每条 `[n]` 引用可解析到报告中的已包含证据，并附来源元数据
- [x] 风险与冲突以附录形式出现在上下文末尾
- [x] 预算不可突破；超预算时按确定性规则截断
- [x] 边界：空候选、单候选、重复来源、中英混排
- [x] 性质测试：引用总能解析；预算永不突破

## Answer

### 契约（`src/context.mbt` + `src/lib.mbt`）

- 新增公开类型 `EvidenceContext { budget, estimated_tokens, truncated, included_count, omitted_count, text, citations }` 与 `Citation { index, evidence_id, source }`。
- `ScanReport` 新增 `context`（位于 `evidence` 之后）；`ScanConfig` 新增可选 `context_budget`（默认 512，库内把负数钳到 0，CLI 拒绝负数）；`Diagnostics.stages` 新增 `context`。
- 上下文只从 `evidence`（已应用 `top_k`）组装；被 `top_k` 截掉的候选不进入 `omitted_count`，该计数只统计预算淘汰。

### 组装与估算

- 顺序：按重排后的 evidence 顺序贪心；当前块成本 + 当前附录成本仍不超预算时纳入，否则整块跳过并继续尝试后续更小块。块永不截断。
- 令牌估算：ASCII `[A-Za-z0-9_]` 连续串按 1 词；每个非 ASCII 码点（含 CJK 字符与标点）按 1 token；ASCII 空白与标点不计。`estimated_tokens` 由最终文本重新估算，恒 ≤ `budget`。
- 渲染：`[n] | <未信任文本>`，每行加 `| ` 引用前缀；`[`、`]`、`|` 在不可信文本与元数据中转为全角，只有渲染器能产出 ASCII `[n]` 与 ` | `；`source:` 行由渲染器生成。块间空行。

### 引用与附录

- `citations[n - 1].index == n`，`evidence_id` 必在报告 `evidence` 中，`source` 为原样来源元数据。
- 附录位于文本末尾：`Risks:` 按 evidence 顺序列出已包含证据的 findings（`[n] rule_id (severity): explanation`）；`Conflicts:` 仅列出双方都已包含的配对（`[n] vs [m] subject (unit): left vs right`）。报告 `conflicts` 仍保留全部配对，包括另一端未进入上下文的。
- 无任何风险/冲突时省略对应小节；未被包含的证据不占用附录。

### 边界与测试

- 新增 `tests/context_test.mbt`（15 个用例）：空候选、单候选、重复来源、空标题、中英混排；tight budget 确定性；greedy 跳过超大高排名块；budget 0；单块超预算整块丢弃；风险附录位置与逐条 marker；风险/冲突附录顺序；冲突附录行与双向引用；单端未包含的冲突不进入附录；ASCII 词/CJK 字增量各精确为 10；多预算性质（预算不破、引用可解析、计数守恒）。
- CLI 新增 `--context-budget N`，覆盖 0、缺失值、负数、非整数。
- 冻结空报告快照更新（新增 `context` 与 `context` stage）。
- `moon check --deny-warn --target all` 通过；`moon test --target all` 109/109 × wasm / wasm-gc / js / native 通过。
- README 新增「证据上下文组装」「上下文边界」；`CONTEXT.md` 新增「引用」术语。

### 审核修正

- **F1（已修）**：`Citation` 原先把 `SourceMeta` 的四个字段平铺复制（Data Clumps，字段演进会漂移）；改为嵌入 `source: SourceMeta`。
- **F2（已修）**：严重度→字符串映射在 JSON 序列化与附录各一份（Repeated Switches）；提取 `risk.mbt` 包内 `severity_label` 单一实现。
- **F3（已修）**：冲突行渲染原先用 `unwrap_or(0)` 兜底，理论上可写出无法解析的 `[0]`；改为 `trial_conflict_line -> String?`，不满足双端包含时返回 `None`，未解析 marker 不可达。
- **F4（已修，安全问题）**：上下文原先原样拼入不可信文本，chunk 内的 `[99]` 或伪造的 `source:` 行可冒充引用/来源。现改为逐行 `| ` 引用前缀，并把不可信文本与元数据中的 `[`、`]`、`|` 折叠为全角 `［］｜`；只有渲染器能产出 ASCII `[n]` 与 ` | `。新增注入回归测试，断言 `[99]` 被转义、伪造 source 行保持引用状态、所有 marker 可解析。
