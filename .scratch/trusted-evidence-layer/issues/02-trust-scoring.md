# 02 — 信任评分（来源与内容分项）

**What to build:** 每个候选块得到 0..1 的信任分与分项明细；重排同时考虑检索分与信任分，低质量来源即使检索分更高也会被压后。

**Blocked by:** 01 — 走通骨架

**Status:** resolved

- [x] 信任分 = 来源分项 + 内容分项，权重可配置，分项出现在报告中
- [x] 来源分项覆盖元数据完整度与来源类型；内容分项覆盖长度、模板化比例、语言一致性
- [x] 一致性分项在本票保持中性（零惩罚），由 04 接入
- [x] 重排使用检索分 + 信任分；并列时按候选 id 稳定排序
- [x] 性质测试：任意输入下信任分恒在 [0,1]
- [x] fixture：低质量来源即使检索分更高，排名仍低于高质量来源
- [x] 报告中回显本次运行的配置快照

## Answer

### 信任模型（`src/lib.mbt`）

- `trust.score = clamp01(source_weight × source_score + content_weight × content_score)`，两个权重先归一化为和为 1；默认 0.5/0.5，权重和 ≤ 0 时回退 0.5/0.5；非有限值（NaN/±∞）回退默认值。
- `source_score = (metadata + source_type) / 2`：
  - `metadata` = `{uri, title, fetched_at, hint}` 四项中非空/存在的比例（0、0.25、…、1）。
  - `source_type` 按 URI scheme 分档：https 1.0、s3/gs 0.8、http 0.6、file 0.4、其他 scheme 0.3、无 scheme 0.2。
- `content_score = (length + template_cleanliness + consistency) / 3`：
  - `length` = UTF-16 码元数 / 40，夹到 [0,1]。
  - `template_ratio` 报告原始 `{`, `}`, `<`, `>` 占比（越高越差；空文本记为 1.0），内容分项使用 `template_cleanliness = clamp01(1 - 8 × template_ratio)`，占比 ≥ 12.5% 即 0 分。
  - `consistency` 本票恒为 1.0（零惩罚占位），04 替换实现但保持 breakdown 形状。
- 每个子信号独立夹取后再混合，最终再夹一次 → 即使构造负数/零和/非有限权重，信任分仍在 [0,1]。

### 重排与确定性

- `rerank_score = retrieval_score + trust_weight × trust.score`，`trust_weight` 默认 1.0。
- 排序：rerank 降序 → id 升序 → 原始输入顺序；固定字段选择排序，无比较器依赖；`top_k` 在完整排序后截断。
- diagnostics 阶段名不变：ingest → dedupe → sort → topk。

### 契约与序列化

- `Evidence` 新增 `rerank_score` 与 `trust{score, breakdown{source_score, content_score, metadata, source_type, length, template_ratio, consistency}}`。
- `ScanConfig` 新增三个可选权重字段；报告回显输入配置快照，缺省键仍被省略（默认配置序列化为 `{}`）。
- 新增 `ScanConfig::default()`（显式 `extend`），调用方无需逐字段拼写；CLI 使用 `{ ..ScanConfig::default(), top_k }`。
- 新增 `tests/fixtures/quality_gap.json`，与测试内嵌 `QUALITY_GAP` 常量同形。

### 验证

- `moon check --deny-warn --target all` → 0 warning、0 error。
- `moon test --target all` → 32/32 通过（wasm、wasm-gc、js、native）。
- CLI 端到端：`multi.json` 连跑两次 SHA256 均为 `99d3253cecefd03c9b10a3c99761f1f58c3945b2bd76307bb2cbec0e155ceecd`，stderr 为空。
- 质量差距 fixture：`highq`（检索 0.4，trust 1.0，rerank 1.4）排在 `lowq`（检索 0.9，trust 0.2625，rerank 1.1625）之前；lowq 的 `template_ratio = 8/11 ≈ 0.727`，highq 为 0。
- 性质测试覆盖 54 种候选形状（空文本、模板饱和、中文、emoji 代理对、9 种来源形态）× 10 组权重（默认、单边、零和、负权重、不平衡、NaN/∞）。
- README 的冻结示例、重排说明与测试计数已同步更新。

### 审查修正

- `template_ratio` 原先存的是反向清洁度分，名实不符；改为报告原始标记占比，清洁度变换留在内容分项内部，并补充 fixture 断言。
- `order_candidates` 去掉冗余 index 重赋值与二次拷贝，改为对 `entries.copy()` 单次选择排序。
- 权重统一经 `finite_or` 消毒：NaN/±∞ 回退默认值，避免非有限值进入报告或破坏重排全序；性质测试与专门用例覆盖。
