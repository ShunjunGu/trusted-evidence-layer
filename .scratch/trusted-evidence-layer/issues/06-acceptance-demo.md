# 06 — 验收演示：有/无信任层对比

**What to build:** 一条可复现命令在固定语料上产出"有/无信任层"对比结果——暴露的不安全块、发现的冲突、拦截的注入、排名变化——并直接作为申报书的演示路径。

**Blocked by:** 05 — 证据上下文组装

**Status:** resolved

- [x] 固定语料 + 一条命令产出有/无信任层对比
- [x] 对比至少覆盖：不安全块数量、冲突对数、拦截注入数、排名变化
- [x] 输出人类可读摘要 + 机器可读 JSON
- [x] 命令在 CI 中可复现：无网络、无密钥
- [x] 结果作为申报书演示路径，README 中有对应章节
- [x] 相同语料重复运行结果一致

## Answer

### 命令与产物

- `moon-trust demo <candidates.json> [--json-out PATH]`；固定语料为 `tests/fixtures/demo.json`（11 块）。
- stdout：人类可读摘要；`--json-out`：单行机器可读 JSON。退出码 `0` 成功（即使 `blocked=true`）、`1` 用法错误或候选文件不合法、`2` 读取失败或 JSON 写入失败。
- 一条命令同时产出两种格式，例如：
  `moon run cmd/main --target native -- demo tests/fixtures/demo.json --json-out _build/demo.json`

### 对比口径（`src/demo.mbt`）

- **无信任层** = 原始检索流：按 `retrieval_score` 降序（并列按 id、再按输入顺序），不去重、不隔离、不检测冲突、不重排。不安全块数用同一规则集做反事实测量，不是第二套实现。
- **有信任层** = 一次普通 `scan`，固定 `risk_policy=drop`、`block_on_high=true`，其余保持默认，因此无需额外配置即可复现。
- 指标：`unsafe_blocks_exposed`（含高严重度发现的块，暴露给生成器的数量）、`conflict_pairs`（显式跨文档冲突对）、`injections_intercepted`（drop 策略隔离的高严重度块数）、`ranking_changes`（存活块在检索序与重排序之间的排名变化，`delta = before − after`，正数表示上移；被丢弃块列入 `quarantined_ids`，不计入排名变化）。
- 固定语料实测：不安全块 5 → 0，冲突对 0 → 2，拦截注入 0 → 5，6/6 存活块排名变化；上下文 6 块 / 162 tokens / budget 512，`blocked=true`。

### 契约与确定性

- 新增公开类型 `DemoReport { query, corpus_size, policy, baseline, trusted, comparison }`、`DemoBaseline`、`DemoTrusted`、`DemoContext`、`DemoComparison`、`MetricDelta`、`RankChange`，全部 `ToJson + Eq`；入口为纯函数 `demo_report(query, candidates)`。
- 基线排序为固定字段选择排序；排名变化按 trusted rank 升序；全流程无时钟、随机源、网络与密钥。
- `src/cli/demo.mbt` 只做参数解析与渲染，把待写 JSON 放回 outcome；`cmd/main` 是唯一执行 `@fs.write_string_to_file` 的地方，写入失败映射为 exit 2。
- 人类摘要与 JSON 均由同一个 `DemoReport` 渲染，重复运行字节一致。

### 测试与 CI

- 新增 `tests/demo_test.mbt`（9 个用例）：基线/trusted 计数与顺序、四项对比指标、排名双向一致性、干净与空语料、JSON 确定性、与 `scan` 报告的一致性。
- 新增 `tests/demo_cli_test.mbt`（8 个用例）：子命令校验、缺参/未知选项/缺值、读取与解码错误映射、固定摘要快照、`--json-out` 产物内容、重复调用一致。
- `moon check --deny-warn --target all` 通过；`moon test --target all` 125/125 × wasm / wasm-gc / js / native 通过。
- CI 新增 demo 复现步骤：同一语料跑两次，分别 diff 人类摘要与 JSON 产物。
- README 新增「验收演示：有/无信任层对比」章节（命令、真实输出、指标定义、JSON 形状、复现命令）；更新 usage 与测试计数。
