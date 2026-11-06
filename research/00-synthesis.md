# 调研合并结论：12 个候选选题的生态查重与能力边界

- 日期：2026-11-06
- 证据附录：
  - [01-mooncakes-dedup.md](./01-mooncakes-dedup.md) — 赛题 12 候选逐项查重（API 快照：3,571 modules / 31,961 packages / 10.88M 下载）
  - [02-moonbit-capabilities.md](./02-moonbit-capabilities.md) — 语言与工具链能力边界（43 条一手来源引用）
  - [03-remaining-directions-dedup.md](./03-remaining-directions-dedup.md) — 官方清单其余 17 个方向 / 19 个判定单元查重
  - [04-candidate-directions-dedup.md](./04-candidate-directions-dedup.md) — AI 应用 / 数据格式 / 开发者工具三方向的子项查重
- 基线版本：moonc 0.10.19（2026-11-05）；本机 `moon 0.1.20261012`

---

## 一句话结论

**赛题整理文档第六节的 12 个候选，11 个在 mooncakes.io 上已有功能高度重合、且 2026 年仍在更新的包；第 12 个（MQTT 5.0）为部分重叠。按官方"避免与现有生态高度重复"的规则，这份候选清单不能直接作为新项目选题使用。**

文档本身已提示"选题前请务必在 mooncakes.io 查重"——本次调研就是执行这句话，结果是否决了整张表。

---

## 一、12 候选裁决表

| # | 候选 | 裁决 | 占位包（版本 / 最近更新） | 现存功能缺口 |
|---|---|---|---|---|
| 1 | MQTT 5.0 异步客户端 | **部分重叠** | `Strangelight-Merser/moon-mqtt-client` 0.8.1（2026-10-31）；另有 3 个 3.1.1 客户端 | QoS 2、Topic Alias、Subscription Identifiers、Enhanced AUTH、协议一致性认证 |
| 2 | HTTP 反向代理 | **已占位** | `1726914517-spec/moonproxy` 0.2.1（2026-11-03） | HTTP/2、TLS termination（README 明示不在本版本） |
| 3 | Apache Arrow 列式内存库 | **已占位** | `shunge/arrow` 0.2.1（2026-09-30），四后端测试，IPC stream/file | Flight、C Data Interface、完整 Compute 内核 |
| 4 | DataFrame 核心库 | **已占位** | `ihb2032/MoonFrame` 0.8.1（2026-10-30，检索当日仍有提交） | 未发现明确空白 |
| 5 | 向量数据库客户端 | **已占位** | `SundayT1998/milvus-client` 0.1.3；`yuzhiblue/moon-qdrant` 0.5.0（注册表 build_status=failed） | Qdrant 侧可构建性存疑；row-based 写入在 roadmap |
| 6 | WAV / OGG 音频解码 | **已占位（分片）** | `Ridge-Lab/moonwavkit` 0.1.3（WAV）；`LL728/moonvorbis` 0.1.4 + `LL728/moonopus` 0.2.2 | 缺少统一 Audio 接口与跨格式门面（但属集成层，不是空白） |
| 7 | LSP 语言服务器框架 | **已占位** | `mizchi/lsp` 0.1.3（2026-08-15），含 json/jsonrpc/types/server/client/fs 子包 | 高级特性（语义 token、inlay hints、增量同步） |
| 8 | Typst 兼容渲染子集 | **已占位（双份）** | `Lxxbv/moon_typst` 0.2.1（2026-09-27，定位逐字对应）；**`moonbitlang/typst` 0.1.10（官方，2026-11-02）** | 无——官方全量移植已在下游使用 |
| 9 | 确定性分布式仿真框架 | **已占位（弱维护）** | `oyjh0381/moonlab` 0.1.0（2026-08-12，单版本 / 34 下载） | 维护强度低，但功能覆盖几乎完全一致 |
| 10 | OCI 镜像打包工具 | **已占位（弱维护）** | `oyjh0381/moonoci` 0.1.4（2026-08-13，5 版本 / 80 下载） | registry push、签名、zstd 层 |
| 11 | 前端表单校验与状态管理 | **已占位（成熟）** | `2d5rrr333/moonform` 0.9.3（21 个版本 / 195 下载 / 2026-09-29） | 无 |
| 12 | n2 风格增量构建工具 | **已占位（弱维护）** | `Zcxssxx/moon-ninja` 0.3.2（7 版本 / 65 下载） | restat、dyndep、console pool |

**"弱维护"不等于可用**：moonlab / moonoci / moon-ninja 都是单人单版本低下载，理论上不满足"成熟项目"的严格定义；但评审看到的是功能重合，申报时仍要解释差异化，风险不为零。

---

## 二、两份报告的冲突裁决（重要）

能力报告在 D1、D3 中判断"未发现任何 MoonBit MQTT 库""无现成 LSP 框架"——**该结论错误**，因为其检索仅限 GitHub，而 `Strangelight-Merser/moon-mqtt-client`、`mizchi/lsp` 等包的主要存在证据在 mooncakes 注册表（且部分仓库名与 module 名不一致，GitHub 404 不能反证不存在）。

**裁决：以 01 号报告的 mooncakes API 直接证据为准。** 能力报告 D1/D3 的"协议层缺口"段落仍有效，但其"生态空白"判断作废。这也说明：查重必须以 mooncakes 注册表为唯一权威源，GitHub 只能做辅助。

---

## 三、能力边界红旗（影响所有选题）

| 事实 | 后果 |
|---|---|
| `async` 整体实验性，API 明示可能变化，需 `allow-experimental-packages: true`；native 完整、wasm-gc 不支持、JS 无 I/O | 任何网络/并发类选题都锁死 native，且要接受 API 迁移风险 |
| 无稳定 struct 内存布局（FFI 文档原文 "currently unstable"），无 `#[repr(C)]` | 列式/二进制格式类项目只能走 `FixedArray[Byte]` + 手写偏移 |
| 无用户自定义宏；代码生成靠外部工具（moonyacc / moonlex / protoc-gen-mbt） | 解析器类项目可用，但不能做语言内 DSL 宏 |
| `moon.mod.json` 已废弃，新格式为 `moon.mod` | 网上旧教程会直接踩坑；`moon fmt` 负责迁移 |
| 无官方 Marketplace CI Action | 验收要求 CI，需用官方 composite action 或 `hustcer/setup-moonbit` |
| `x/crypto` 无 RSA/ECC 公钥原语 | TLS 走 `async/tls`（native 依赖 OpenSSL/schannel），纯 MoonBit 实现 TLS 不可行 |

---

## 四、查重方法论的系统性局限（写申报书时必须知道）

1. **mooncakes 搜索不是全文索引**：只匹配「包名 + keywords + 自动摘要」。**中文关键词没有被索引**——第二轮实测 20 个中文词（规则引擎、大数据、流处理、查询引擎、消息队列、布局、解释器……）全部返回 0 条，是系统性缺失而非"命中不稳定"。因此查重只能用英文关键词 + 同义词扩展。
2. **`limit=50` 有效，`page`/`offset` 无效**（结果不翻页），无法保证拿到第 50 条之后的命中。
3. **"最近更新"取 mooncakes 最新版本发布时间**，不是 commit 时间；两者可能不一致。
4. **`repository` 字段可能过期**（`shunge/arrow` 搜索记录指向 404，manifest 才是真实仓库）。
5. **只核对了功能声明**，未 clone 跑测试；"覆盖"指 README/API 声称的覆盖。

**结论**：申报书里的查重表述应写成"检索方法与范围 + 已知局限"，而不是空口断言"生态无重复"。

---

## 五、第二轮：官方清单整体占位图

第二轮覆盖 17 个方向、19 个判定单元（「解释器」拆为 Python / Lua / VB）：

| 判定 | 数量 | 方向 |
|---|---|---|
| 已有成熟包 | 12 | QUIC、Kafka、NATS\*、WebHook\*、API 规则校验、自动布局、事件总线\*、Actor\*、K8s 客户端\*、Lua\*、find/ls 等 CLI、HTTP 应用服务器 |
| 部分重叠 | 5 | Spark/Flink 类、分布式 SQL、ReactiveMongo 类驱动、Python 解释器、LaTeX 渲染 |
| 空白 | 2 | **基于 WASM 的 K8s Operator 运行时**、**Visual Basic 解释器** |

\* = 维护强度偏弱（少版本 / 低下载），但功能重合成立。

### 两个真空白

1. **WASM K8s Operator 运行时** — 能力报告 D5 已裁决：无 WASI 标准库、async 的 wasm1 支持绑定 `moonrun` 且不兼容通用 runtime、宿主接口层需自建。空白，但一个月内高风险。
2. **Visual Basic 解释器** — 官方清单点名，且生态里 Python 子集 / Lua / JS / Scheme / Prolog / Wren / Jsonnet / Starlark 都已有实现，唯独 VB 方言空白。风险是 VB 本身庞大，必须裁剪出可辩护的子集。

### 值得注意的三个"缺一层"

- **LaTeX 渲染库**：解析已有 `kokic/katex-parser`（21 版本 / 185 下载），**渲染器缺失**；`moonbitlang/pagelayout` 可作为分页布局后端。缺的是数学排版与输出这一层。
- **ReactiveMongo 类驱动**：只有 `allain/mongodb`（2026-01 停更、`build_status=legacy`），无响应式流 / Observable 模型。
- **Spark/Flink 类与分布式 SQL**：单机能力齐备（`moonlake` 自述 22 条 TPC-H 全过），**分布式层**（调度、shuffle、容错协调）空白。方向明确，但一个月做不出来。

### 结论

**"在官方清单里找空白"的收益已经很低。** 剩下的是两类：极难（分布式运行时、WASM Operator）或极窄（VB 解释器、LaTeX 渲染器）。这直接改变了路线权衡：

- **路线 A（官方清单剩余方向）** 几乎关闭——不是没题，是剩下的题都不符合"一个月可验收"。
- **路线 B（现有包缺口做增量）** 成为主要可行路径，但要正面回答"为什么不直接给现有包提 PR"。
- **路线 C（脱离清单自选）** 需要自证生态位，评审不确定性最高。

---

*本文件只做证据合并，不做选题决定。决定交给 `/grilling`。*
