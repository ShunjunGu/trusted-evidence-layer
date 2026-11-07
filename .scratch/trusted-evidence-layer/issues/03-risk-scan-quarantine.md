# 03 — 风险扫描与隔离策略

**What to build:** 注入 fixture 中的候选块被逐条规则标注（规则 id、严重度、文本区间、解释），并按配置被丢弃、标记或降权；配置为阻断且存在高严重度风险时 CLI 返回非零退出码。

**Blocked by:** 02 — 信任评分（来源与内容分项）

**Status:** resolved

- [x] 规则集覆盖：祈使式指令、角色/标记 token、隐藏或零宽字符、编码载荷、外泄短语、分隔符逃逸
- [x] 每条发现含规则 id、严重度、文本区间、解释
- [x] 隔离策略可配置：drop / mark / downrank
- [x] 风险惩罚进入信任分与重排
- [x] CLI 在"阻断 + 高严重度"时返回非零退出码，否则返回 0
- [x] 误报语料：合法文档中的普通祈使句不应被高严重度标注，边界写入文档
- [x] fixture：注入块被标注并按策略处理，报告可复现

## Answer

### 规则引擎（`src/risk.mbt`）

- 13 条固定规则覆盖 6 类信号：`instruction.override` / `instruction.redirect` / `instruction.imperative`（祈使式指令）、`role.marker` / `role.chat-heading`（角色标记）、`hidden.zero-width` / `hidden.bidi-control`（隐藏字符）、`payload.encoded` / `payload.code-exec` / `payload.escape-sequence`（编码载荷）、`exfiltration.secret` / `exfiltration.send`（外泄短语）、`delimiter.escape`（分隔符逃逸）。
- 每个候选块每条规则最多贡献一条 finding，锚定最早命中；短语匹配为 ASCII 大小写不敏感，CJK 按原样匹配。
- finding = `rule_id` + `severity`（JSON 小写 `low`/`medium`/`high`）+ 半开 UTF-16 code-unit 区间 + 含命中短语的解释。区间与 `text.length()` 同一度量，可直接切片原文。
- findings 按 `(span.start, rule_id)` 升序稳定排序；零宽/双向控制字符按码位逐一定名（如 `U+200B zero-width space`）。
- `enabled_rules: Some([...])` 可限制启用的规则集；缺省 = 全量。

### 隔离策略与风险惩罚

- `downrank`（默认）：保留全部块，`trust.score = clamp01(blend × risk)`，其中 `risk = 1 − clamp01(Σ severity_penalty × risk_weight)`；penalty = high 0.5 / medium 0.25 / low 0.1。两条 high 即把信任分压到 0。`risk` 写入 `trust.breakdown.risk`，重排公式 `retrieval + trust_weight × trust.score` 因此自动含风险惩罚。
- `mark`：保留全部块并标注，不惩罚（`risk = 1`）。
- `drop`：仅移除含 high finding 的块；被移除块保留在 `quarantined`（id、text、source、findings、reason），中/低严重度块只标注不惩罚。
- `risk_weight` 非有限值回退 1.0；负值经 clamp 视为 0 惩罚。
- `block_on_high: true` 时，任一 high finding（含已隔离块）令报告 `blocked = true`。

### 报告与 CLI 契约

- `Evidence` 新增 `risk_findings`；`TrustBreakdown` 新增 `risk`；`Diagnostics` 新增 `risk_finding_count` / `quarantined_count`；阶段序列变为 `ingest → dedupe → risk → isolate → sort → topk`。
- `ScanReport` 新增 `quarantined`（审计轨迹）与 `blocked`；默认配置仍序列化为 `{}`。
- CLI 新增 `--policy drop|mark|downrank`、`--block-on-high`、`--risk-weight W`；非法/缺失值走既有 usage 错误（exit 1）。
- 退出码：`0` 成功、`1` 用法/JSON 错误、`2` 文件不可读、`3` 阻断（报告仍打印到 stdout）。
- 新增 `tests/fixtures/injected.json`（10 个块：5 个 high 注入、1 个 medium 外泄、1 个 low 普通祈使、3 个干净文本），嵌入常量 `INJECTED` 与其同形。

### 误报与边界

- 普通祈使句（“You should consult a doctor…”、“请输出报表”）只触发 `instruction.imperative`（low），不会触发 drop；默认 downrank 下仅扣 10% 信任分。
- Markdown 代码围栏不算分隔符逃逸；`delimiter.escape` 只匹配显式上下文闭合 token。
- U+200D 既是 emoji ZWJ 连接符也是隐藏通道，按 high 上报；emoji 密集型语料可用 `enabled_rules` 关闭该规则。
- 无任何编码标记的裸 base64 长串不检测；规则是短语/码位启发式，不做语义理解。
- 边界已写入 README「风险扫描与隔离 / 误报与边界」。

### 验证

- `moon check --deny-warn --target all` → 0 warning、0 error。
- `moon test --target all` → 53/53 通过（wasm、wasm-gc、js、native）；含风险性质测试（3 种策略 × 5 组权重，信任分与各分项恒在 [0,1]）与 `top_k` 不截断隔离审计的用例。
- CLI 端到端：`injected.json` 默认 downrank → 10 evidence / 0 quarantined / blocked false；`--policy drop` → 5 evidence + 5 quarantined（override, hidden, role, payload, delimiter）；`--policy drop --block-on-high` → exit 3 且报告可审计。
- 同命令连跑两次 SHA256 均为 `84507d9262cf2d07f530346be6cf7d88fcaed2aab26882772c6dc27555b4d399`。
- downrank 使注入块整体落到干净块之后（override 从 mark 下 rerank 1.8375 降至 0.9，clean 1.55 居首）。
