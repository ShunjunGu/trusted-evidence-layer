# MoonBit 2026-11 黑客松候选选题 · mooncakes.io 生态查重

- 检索日期：2026-11-06
- 主数据源：`https://mooncakes.io/api/v0/*`（站点为 Rabbita SPA，但提供 JSON API，且 `/docs/<owner>/<name>` 页面内嵌 `__rabbita_transcript` 初始响应，可直接取到包元数据与 README 正文）
- 注册表规模（检索时 API 快照）：3,571 个 module / 31,961 个 package / 57,973,055 行 / 10,879,433 次下载
- 辅助源：GitHub（`gh` CLI + 代理 `http://127.0.0.1:7892`）、各包 manifest 中的 `repository` 字段
- 判定口径：按任务给定定义——`已有成熟包` = 功能高度重合且 2026 年有发布/更新；`部分重叠` = 有相关包但功能覆盖不足或已停更；`空白` = 未检索到相关包。维护强度另附版本数、下载量、`build_status` 与 GitHub 最后 push 时间，供主线程自行加权。

## 1. 汇总表

| # | 候选 | 判定 | 最相关包 | 最近更新 | 链接 |
|---|---|---|---|---|---|
| 1 | MQTT 5.0 异步客户端 | **部分重叠** | Strangelight-Merser/moon-mqtt-client 0.8.1（另有 Duckweed/moon-mqtt、youyong5/moonmqtt、ChaonanShen/moonbit-mqtt-broker） | 2026-10-31 | https://mooncakes.io/docs/Strangelight-Merser/moon-mqtt-client |
| 2 | HTTP 反向代理 | **已有成熟包** | 1726914517-spec/moonproxy 0.2.1 | 2026-11-03 | https://mooncakes.io/docs/1726914517-spec/moonproxy |
| 3 | Apache Arrow 列式内存基础库 | **已有成熟包** | shunge/arrow 0.2.1 | 2026-09-30 | https://mooncakes.io/docs/shunge/arrow |
| 4 | DataFrame 核心库 | **已有成熟包** | ihb2032/MoonFrame 0.8.1 | 2026-10-30 | https://mooncakes.io/docs/ihb2032/MoonFrame |
| 5 | 向量数据库客户端（Qdrant/Milvus） | **已有成熟包** | SundayT1998/milvus-client 0.1.3；yuzhiblue/moon-qdrant 0.5.0 | 2026-10-31 / 2026-10-13 | https://mooncakes.io/docs/SundayT1998/milvus-client |
| 6 | WAV / OGG 音频解码库 | **已有成熟包** | Ridge-Lab/moonwavkit 0.1.3（WAV）+ LL728/moonvorbis 0.1.4（OGG/Vorbis） | 2026-08-20 / 2026-10-17 | https://mooncakes.io/docs/LL728/moonvorbis |
| 7 | LSP 语言服务器框架 | **已有成熟包** | mizchi/lsp 0.1.3（含 server / client framework 子包） | 2026-08-15 | https://mooncakes.io/docs/mizchi/lsp |
| 8 | Typst 兼容渲染子集 | **已有成熟包** | Lxxbv/moon_typst 0.2.1；moonbitlang/typst 0.1.10 | 2026-09-27 / 2026-11-02 | https://mooncakes.io/docs/Lxxbv/moon_typst |
| 9 | 确定性分布式系统仿真框架 | **已有成熟包** | oyjh0381/moonlab 0.1.0 | 2026-08-12 | https://mooncakes.io/docs/oyjh0381/moonlab |
| 10 | OCI 镜像打包工具 | **已有成熟包** | oyjh0381/moonoci 0.1.4 | 2026-08-13 | https://mooncakes.io/docs/oyjh0381/moonoci |
| 11 | 前端表单校验与状态管理库 | **已有成熟包** | 2d5rrr333/moonform 0.9.3 | 2026-09-29 | https://mooncakes.io/docs/2d5rrr333/moonform |
| 12 | n2 风格增量构建工具 | **已有成熟包** | Zcxssxx/moon-ninja 0.3.2 | 2026-08-16 | https://mooncakes.io/docs/Zcxssxx/moon-ninja |

## 2. 逐条详述

### 1. MoonBit MQTT 5.0 异步客户端 —— 部分重叠

**最相关包**：`Strangelight-Merser/moon-mqtt-client` v0.8.1，最新版本发布 2026-10-31，下载 113，`build_status=success`，GitHub 最后 push 2026-10-31，共 7 个版本（0.1.0 → 0.8.1）。

- 链接：https://mooncakes.io/docs/Strangelight-Merser/moon-mqtt-client
- 源码：https://github.com/Strangelight-Merser/moon-mqtt-client

**功能覆盖（README 明示）**：

- 基于 `moonbitlang/async` 的原生异步客户端；TCP/TLS/WS/WSS；QoS 0/1；保留消息、Last Will、用户名/密码认证；进程作用域内恢复未确认的 QoS 1 发布，native beta 可选 SQLite durable outbox。
- **协议版本**：默认 MQTT 3.1.1，"可显式选择 MQTT 5 应用子集"（`protocol=@mqtt.Mqtt5`）。

**明确的能力缺口（同 README「支持范围」）**：

- 不支持 QoS 2、Topic Alias、Subscription Identifiers、Enhanced AUTH、通用离线接收队列、加密私钥等。
- README 自述："目前属于早期实现，尚未通过 MQTT 协议一致性认证。"

**同域其他包**：

| 包 | 版本 / 更新 | 覆盖 |
|---|---|---|
| Duckweed/moon-mqtt | 0.3.3 / 2026-10-26 | MQTT 3.1.1 客户端，QoS 0/1/2、持久会话、浏览器 WebSocket；README 写"5.0 为后续路线" |
| youyong5/moonmqtt | 0.1.1 / 2026-10-27 | MQTT 3.1.1 客户端，TCP + TLS |
| ChaonanShen/moonbit-mqtt-broker | 0.4.0 / 2026-09-27 | Broker，MQTT 3.1.1 + opt-in MQTT 5 |
| zbhzs1/moonbit-mqtt | 0.1.0 / 2026-07-11 | 仅 3.1.1 报文编解码，无传输/客户端运行时；下载 730 |
| Wchwch777/Scantling（仅 GitHub） | push 2026-11-05 | 异步 MQTT 3.1.1 TCP 客户端运行时，基于 zbhzs1/moonbit-mqtt |

**判定说明**：若按"能用的异步 MQTT 客户端"口径，重合度高；但候选明确写的是 **MQTT 5.0**，现有最强包只实现 MQTT 5 应用子集（缺 QoS 2、Topic Alias、Subscription Identifiers、Enhanced AUTH），其余客户端均为 3.1.1。故判 `部分重叠`，而非 `已有成熟包`。

**检索词**：`mqtt`、`mqtt5`、`mqtt client`、`pubsub`、`broker`；GitHub `gh search repos --language=MoonBit "mqtt"`。

**判定依据 URL**：
- https://mooncakes.io/docs/Strangelight-Merser/moon-mqtt-client
- https://mooncakes.io/docs/Duckweed/moon-mqtt
- https://github.com/Wchwch777/Scantling

---

### 2. MoonBit HTTP 反向代理 —— 已有成熟包

**最相关包**：`1726914517-spec/moonproxy` v0.2.1，发布 2026-11-03，下载 49，`build_status=success`，GitHub 最后 push 2026-11-03。

- 链接：https://mooncakes.io/docs/1726914517-spec/moonproxy
- 源码：https://github.com/1726914517-spec/moonproxy

**功能覆盖（README 明示）**：

- 定位即 "A native L7 reverse proxy / load balancer runtime"，对标 nginx / HAProxy / Traefik。
- Host / path 路由（精确优先、长前缀优先）；5 种负载均衡策略（轮询、平滑加权轮询、最少连接、随机、client-IP hash / FNV-1a）。
- 逐跳头清理 + `X-Forwarded-For` / `X-Forwarded-Proto` / `X-Forwarded-Host` / `X-Real-IP`，Host 重写。
- 主动 + 被动健康检查；每后端指标；连接失败与幂等方法 5xx 的 failover/retry；请求/响应体流式转发。
- 核心转发决策逻辑可编译到 wasm / wasm-gc / js / native，socket 运行时仅 native。

**边界**：README 明示 "The edge speaks HTTP/1.1; HTTP/2 and TLS termination are not in this release."

**同域其他包**：`zkc-long/faultcanvas` 0.1.0（2026-09-24）是可编程 HTTP 故障代理/服务虚拟化网关，不是生产反向代理；`LuoYunxin1/moonnginx` 0.2.0（2026-09-30）只解析 nginx.conf；`moonbitstack/mooncat`、`bobzhang/crescent` 等是应用服务器，只处理 `proxy-headers`，不转发到上游。moonproxy README 亦自述 "There is no running reverse proxy on mooncakes today"（作者自述，检索结果与其一致）。

**检索词**：`proxy`、`reverse proxy`、`http server`、`http`、`load balancer`、`反向代理`（该中文词返回 0 条，属中文检索漏检，见方法论）。

**判定依据 URL**：
- https://mooncakes.io/docs/1726914517-spec/moonproxy
- https://mooncakes.io/docs/zkc-long/faultcanvas

---

### 3. MoonBit Apache Arrow 列式内存基础库 —— 已有成熟包

**最相关包**：`shunge/arrow` v0.2.1，发布 2026-09-30，下载 90，`build_status=success`，3 个版本（0.1.0 / 0.2.0 / 0.2.1）。manifest 中的真实仓库为 `https://github.com/buildliming/MoonArrow`（push 2026-09-30）。

- 链接：https://mooncakes.io/docs/shunge/arrow
- 源码：https://github.com/buildliming/MoonArrow

**功能覆盖（README 明示）**：

- 纯 MoonBit、只依赖标准库；PyArrow 仅用于开发期互操作测试，无 Arrow C++ / FFI 依赖。
- 列类型：Null、Boolean、各宽度有/无符号整数、Float32/64、Date32/64、Timestamp、Duration、Utf8/Binary、LargeUtf8/LargeBinary、FixedSizeBinary。
- 复合类型：List、LargeList、FixedSizeList、Struct、Map、顶层 Int32 索引的 Utf8/Binary Dictionary。
- 有效位图、null count、非空字段检查。
- IPC stream：V5 写入、V4/V5 读取、legacy 前缀兼容；IPC file：ARROW1 文件、footer 索引、多批次与随机批次读取。
- 元数据：schema/field 的 UTF-8 key/value，保留顺序、重复键与缺省值。
- 读取方式：整体读入、在已有 Bytes 上逐批解码、增量推入 stream 字节块。
- 数据处理：`BatchBuilder`、`RecordBatch`/`Table` 的投影、筛选、拼接、重分块、摘要。
- Native / JS / Wasm / Wasm-GC 四后端均有测试。

**边界**：未检索到 Arrow Flight、Arrow C Data Interface、完整 Arrow Compute 内核集（README 未声称覆盖这些）。

**同域其他包**：`superbigcup325/colenc` 0.1.3（2026-10-26）是 Parquet page 级编码内核；`superbigcup325/moonlake` 0.6.4（2026-10-31）是 CSV/Parquet 上的 SQL 查询引擎；均不提供 Arrow 内存格式。

**检索词**：`arrow`、`columnar`、`parquet`、`record batch`、`列式内存`（该中文词返回 0 条）。

**判定依据 URL**：
- https://mooncakes.io/docs/shunge/arrow
- https://github.com/buildliming/MoonArrow

---

### 4. MoonBit DataFrame 核心库 —— 已有成熟包

**最相关包**：`ihb2032/MoonFrame` v0.8.1，发布 2026-10-30，下载 161，`build_status=success`，GitHub 最后 push 2026-11-06（检索当天仍有提交），2 stars。

- 链接：https://mooncakes.io/docs/ihb2032/MoonFrame
- 源码：https://github.com/ihb2032/MoonFrame

**功能覆盖（README 明示）**：

- CSV / JSON / NDJSON I/O；过滤、排序、空值处理、group-by、join、汇总统计。
- 可组合表达式引擎；lazy query layer。
- 导出 Markdown、HTML、JSON、NDJSON、Vega-Lite 图表。
- API 形态对标 pandas/polars，README 明确 "not a full pandas clone"。

**同域其他包**：`smallbearrr/pandas` 0.7.1（2025-04-02，已一年多未更新，判为停更）；`superbigcup325/moonlake` 0.6.4（2026-10-31，嵌入式 OLAP SQL 引擎，非 DataFrame API）；`hustcer/tabular`（2026-09-26，终端表格美化，不是 DataFrame）。

**检索词**：`dataframe`、`tabular`、`pandas`、`csv`。

**判定依据 URL**：
- https://mooncakes.io/docs/ihb2032/MoonFrame
- https://mooncakes.io/docs/smallbearrr/pandas

---

### 5. MoonBit 向量数据库客户端（Qdrant/Milvus） —— 已有成熟包

**最相关包（Milvus 侧）**：`SundayT1998/milvus-client` v0.1.3，发布 2026-10-31，下载 58，`build_status=success`，GitHub 最后 push 2026-10-31。

- 链接：https://mooncakes.io/docs/SundayT1998/milvus-client
- 源码：https://github.com/SundayT1998/moonbit-language-milvus-client
- 覆盖：集合生命周期、insert/upsert/delete、search/query、索引与分区 CRUD、load/release/flush 及可轮询任务、`QueryIterator` / `SearchIterator` 大结果集翻页、四个 target 可编译（socket 部分需 native）。边界：只做 column-based 写入，row-based 在 roadmap；README 明确不是 Milvus 官方 SDK。

**最相关包（Qdrant 侧）**：`yuzhiblue/moon-qdrant` v0.5.0，发布 2026-10-13，下载 95，共 11 个版本（0.1.0 → 0.5.0），GitHub 最后 push 2026-10-13。**注意：mooncakes API 的 `build_status` 为 `failed`（0.5.0）**；README 中的 GitHub CI / Integration badge 表明仓库侧有 CI 与集成测试，但注册表构建未通过。

- 链接：https://mooncakes.io/docs/yuzhiblue/moon-qdrant
- 覆盖：collection 创建/列举/检查、upsert points、get point、search（含 payload filter）、delete points；Int64/u64 point id 完整往返；基于 `oboard/mio` 的 HTTP 传输。

**同域其他包**：`SundayT1998/chroma-client` 0.1.1（2026-10-31，`build_status=success`）覆盖 Chroma；`trkbt10/vcdb` 0.3.2（2026-07-20，下载 682）是进程内 ANN 向量库而非客户端；`lexchb/moon_vector` 0.1.1（2026-10-29）是 Qdrant REST + 内存后端。

**检索词**：`vector database`、`qdrant`、`milvus`、`向量数据库`（中文词可用）、`similarity search`。

**判定依据 URL**：
- https://mooncakes.io/docs/SundayT1998/milvus-client
- https://mooncakes.io/docs/yuzhiblue/moon-qdrant
- https://mooncakes.io/docs/SundayT1998/chroma-client

---

### 6. MoonBit WAV / OGG 音频解码库 —— 已有成熟包

候选的两半分别已有维护中的实现，但没有单一包同时覆盖 WAV + OGG。

**WAV 侧**：`Ridge-Lab/moonwavkit` v0.1.3，发布 2026-08-20，下载 171，`build_status=success`，共 4 个版本，GitHub push 2026-08-20，已有 3 个下游包（`Ridge-Lab/moonstretch`、`zhangbowen2006/boxrir`、`lin2077-zeming/moonecho`）。

- 链接：https://mooncakes.io/docs/Ridge-Lab/moonwavkit
- 覆盖：RIFF/WAVE header 与 chunk 遍历、PCM 8-bit unsigned / 16/24/32-bit signed、IEEE Float 32-bit 解码、音频统计、PCM 工具（增益/归一化/裁剪/重采样/混音/拼接）、波形摘要、区段分析、质量检查；自述约 4260 行核心代码、72 个测试。
- 边界（README 明示）：**不支持 MP3、AAC、FLAC、OGG 等压缩格式解码**。

**另一 WAV 实现**：`bw448/moon-wav` v0.3.0，发布 2026-08-24，下载 35，`build_status=success`，覆盖 PCM/Float 解码与编码。

**OGG 侧**：`LL728/moonvorbis` v0.1.4，发布 2026-10-17，下载 168，`build_status=success`，GitHub push 2026-10-17。

- 链接：https://mooncakes.io/docs/LL728/moonvorbis
- 覆盖：OGG 容器（page 解析、segment table、CRC-32、packet 组装）、Vorbis 三个包头、Codebook（Huffman、VQ lookup type 1/2）、Floor 0/1、Residue type 0/1/2、立体声耦合、IMDCT 与长短块切换、comment 元数据、输出多声道 16-bit PCM WAV；纯 MoonBit、零 C 依赖、可编译到 WebAssembly。

**Ogg Opus 侧**：`LL728/moonopus` v0.2.2，发布 2026-10-16，下载 158，`build_status=success`，覆盖 Ogg Opus 容器与 CELT 解码。

**编码侧（非解码）**：`mizchi/audio` 0.1.1（2026-04-25，下载 3017）是 wav/ogg 编码器，不覆盖解码。

**检索词**：`wav`、`ogg`、`audio`、`opus`、`vorbis`、`音频解码`（中文词可用）。

**判定依据 URL**：
- https://mooncakes.io/docs/Ridge-Lab/moonwavkit
- https://mooncakes.io/docs/LL728/moonvorbis
- https://mooncakes.io/docs/LL728/moonopus

---

### 7. MoonBit LSP 语言服务器框架 —— 已有成熟包

**最相关包**：`mizchi/lsp` v0.1.3，发布 2026-08-15，下载 71，`build_status=success`，GitHub `mizchi/lsp.mbt` 最后 push 2026-08-15，1 star。

- 链接：https://mooncakes.io/docs/mizchi/lsp
- 源码：https://github.com/mizchi/lsp.mbt

**功能覆盖（README 明示的子包清单）**：

- `mizchi/lsp/json`：JSON parser/serializer
- `mizchi/lsp/jsonrpc`：JSON-RPC 2.0 codec
- `mizchi/lsp/types`：LSP 类型定义（自动生成）
- `mizchi/lsp/server`：**LSP server framework**
- `mizchi/lsp/client`：LSP client framework
- `mizchi/lsp/fs`：文件系统抽象（real / in-memory）
- README 给出 server / client 两侧的完整用法（Transport trait、initialize、publishDiagnostics、openDocument、shutdown 等）。

**同域其他包**：`moonbitstack/moonjrpc` 0.1.3（2026-11-05，JSON-RPC 2.0 + LSP/MCP/ACP framing）是更底层的传输件；`bzy-debug/text_document` 0.1.0（2025-08-27）是 LSP 文本编辑原语，已停更；`yinlaomo112/moon-lsp-compiletest` 0.1.0（2026-08-23）是 moon-lsp 的诊断回归测试器，不是框架。

**检索词**：`lsp`、`language server`、`jsonrpc`。

**判定依据 URL**：
- https://mooncakes.io/docs/mizchi/lsp
- https://mooncakes.io/docs/moonbitstack/moonjrpc

---

### 8. MoonBit Typst 兼容渲染子集 —— 已有成熟包

**最相关包（同题）**：`Lxxbv/moon_typst` v0.2.1，发布 2026-09-27，下载 34，`build_status=success`，GitHub 最后 push 2026-09-27。

- 链接：https://mooncakes.io/docs/Lxxbv/moon_typst
- 源码：https://github.com/Lxxbv/moon-typst
- 定位与候选几乎逐字对应：**"A Pure MoonBit Parser, Layout Engine, and SVG/PDF/HTML Renderer for a Typst-Style Markup Subset"**。
- 覆盖：Span 源码位置、词法分析、递归下降解析、文档 AST、脚本求值与级联样式、流式盒模型排版、SVG 1.1 / PDF 1.4 / HTML5 三后端；支持 `pt/mm/cm/in/em/fr/%` 长度、颜色、Rect/Circle/Line、Grid、Footnote、Figure；wasm-gc / js / native 三目标。
- 边界（README 明示）：实现的是"README 所列的 Typst 风格语法子集，并非完整 Typst 编译器"。

**更强对照（官方全量移植）**：`moonbitlang/typst` v0.1.10，发布 2026-11-02，下载 228，`build_status=success`，GitHub `moonbitlang/typst.mbt` push 2026-11-02，已有下游 `cli/typst`（2026-11-05）。

- 链接：https://mooncakes.io/docs/moonbitlang/typst
- 覆盖：`typst-syntax` 移植（lexer/parser/syntax nodes/spans）、typed AST、Unicode 属性表、PNG/JPEG/GIF/WebP codecs、`typst-svg`、`typst-kit`、`typst-cli` 移植；CLI 支持 `compile` 到 PDF/SVG/HTML、`eval`、`fonts`、`watch`；native + wasm。
- 该包发布在 `moonbitlang` 官方组织下，最新版本 2026-11-02，并已有下游 `cli/typst`。

**相邻包**：`moonbitlang/pagelayout` 0.8.1（2026-10-22，3 个下游包）提供分页文档布局 IR + SVG/PDF 后端，属于同层排版能力。

**检索词**：`typst`、`typesetting`、`markup`、`排版`；GitHub `gh search repos --language=MoonBit "typst"`。

**判定依据 URL**：
- https://mooncakes.io/docs/Lxxbv/moon_typst
- https://mooncakes.io/docs/moonbitlang/typst
- https://mooncakes.io/docs/moonbitlang/pagelayout

---

### 9. MoonBit 确定性分布式系统仿真框架 —— 已有成熟包

**最相关包**：`oyjh0381/moonlab` v0.1.0，发布 2026-08-12，下载 34，`build_status=success`，GitHub 最后 push 2026-08-12。功能与候选几乎完全一致。

- 链接：https://mooncakes.io/docs/oyjh0381/moonlab
- 源码：https://github.com/oyjh0381/MoonLab

**功能覆盖（README 明示）**：

- "Deterministic distributed-system simulation and fault injection for MoonBit."
- 模型以 typed pure transitions 表达 Node；引擎控制调度、Virtual Time、Messages、Timers、Stable Storage、有限 Choice Points、crash/restart、Network Partitions。
- 同一 Scenario + 同一 engine identity + 同一 Decision Stream 产生相同动作序列。
- 失败运行可固化为 Replay JSON / Trace JSONL / Report JSON，可精确重放并在保留 Failure Signature 的前提下局部 shrink。
- 子包：`sim` / `explore` / `artifact` / `runner`；Native CLI `cmd/moonlab`；示例含 Raft-style election、replicated register、two-phase commit、故意故障的 election 模型。

**同域其他包**：

| 包 | 版本 / 更新 | 覆盖 |
|---|---|---|
| wcx789ll/moonsim | 0.1.2 / 2026-08-15 | 确定性离散事件 + 多 agent 系统仿真框架 |
| walkzzz/moondes | 0.5.0 / 2026-08-16 | 通用离散事件仿真引擎 |
| zlhahaha/moonsim | 0.3.1 / 2026-07-12 | 确定性仿真 + 模型测试/回放 |
| Ljh684/moonnet-lab | 0.1.0 / 2026-09-30 | 包级网络仿真 + TCP 拥塞控制实验 |
| moonbitstack/moonraft | 0.7.5 / 2026-11-05 | Raft 共识实现（不是仿真框架） |

**判定说明**：功能重合度最高，但 moonlab 仅 v0.1.0 单版本、下载 34，维护强度偏弱；按任务给定"2026 年有更新"口径仍归入 `已有成熟包`。

**检索词**：`simulation`、`distributed`、`distributed simulation`、`consensus`、`raft`、`fault injection`、`deterministic`、`discrete event`。

**判定依据 URL**：
- https://mooncakes.io/docs/oyjh0381/moonlab
- https://mooncakes.io/docs/wcx789ll/moonsim

---

### 10. MoonBit OCI 镜像打包工具 —— 已有成熟包

**最相关包**：`oyjh0381/moonoci` v0.1.4，发布 2026-08-13，下载 80，`build_status=success`，共 5 个版本，GitHub 最后 push 2026-08-13。

- 链接：https://mooncakes.io/docs/oyjh0381/moonoci
- 源码：https://github.com/oyjh0381/MoonBit

**功能覆盖（README 明示）**：

- "building, inspecting, and validating deterministic OCI Image Layout directories without a container daemon or registry."
- 确定性 USTAR/PAX writer 与安全导向的 USTAR/PAX/GNU reader。
- SHA-256 Digest、content-addressed in-memory OCI Image Layout。
- 未压缩与确定性 gzip Layer，正确处理 compressed Layer Digest 与 uncompressed DiffID。
- 有序多层构建，支持 Whiteout 与 Opaque Directory 语义。
- 严格、带版本号的 JSON Build Specification。
- descriptor-graph / size / digest / tar / gzip / DiffID 校验；Root Filesystem 重建。
- Native CLI：`build`、`inspect`、`list`、`verify`、`archive`、`version`。
- 可移植 core 支持 Wasm / Wasm-GC / JS / Native。
- 边界（README 明示）：不解析 Dockerfile、不运行容器、不联系 registry、不签名镜像、不编码 zstd Layer；v0.1 Native Layer Source 拒绝宿主机符号链接。

**同域其他包**：

| 包 | 版本 / 更新 | 覆盖 |
|---|---|---|
| PaiGack/dive | 0.2.1 / 2026-10-31 | OCI 镜像分析：层叠加、whiteout diff、体积效率报告（只读） |
| Hhsqoo/artifactdock | 0.2.3 / 2026-09-28 | 轻量 OCI Distribution registry server |
| mizchi/wacon | 0.1.1 / 2026-04-25 | 面向 WASM module 的最小 OCI 容器运行时 |
| mizchi/oci_wasm | 0.5.1 / 2026-10-05 | WebAssembly package registry 客户端 |
| spectacleCase/moonhadolint | 0.1.3 / 2026-10-29 | Dockerfile parser + hadolint 风格 linter（不打包） |

**检索词**：`oci`、`container image`、`docker`、`tar`。

**判定依据 URL**：
- https://mooncakes.io/docs/oyjh0381/moonoci
- https://mooncakes.io/docs/PaiGack/dive

---

### 11. MoonBit 前端表单校验与状态管理库 —— 已有成熟包

**最相关包**：`2d5rrr333/moonform` v0.9.3，发布 2026-09-29，下载 195，`build_status=success`，共 21 个版本（0.1.0 → 0.9.3），GitHub 最后 push 2026-09-29。

- 链接：https://mooncakes.io/docs/2d5rrr333/moonform
- 源码：https://github.com/2d5rrr333/moonform

**功能覆盖（README 明示）**：

- Headless 表单状态机：字段值、dirty/touched、错误派生、按需订阅、提交编排；语义对标 `@tanstack/form-core@1.33.5`，并称以上游测试集做行为等价翻译（`upstream/PARITY.md`）。
- 结构化字段访问器（lens）：`(key, get, set)` 组合子，替代 dot-path 字符串；数组字段 push/insert/remove/swap/move/replace + meta 迁移。
- FormGroup：组级校验器、组错误分发到子字段、组内提交不影响表单提交态。
- Resolver 协议：内置 required/min/max/pattern/闭包规则；`moonschema`（zod-style JSON Schema）适配，可作字段或组校验器。
- 校验时序：同步/异步校验、`on_change_async_debounce_ms` 防抖、竞态中止、虚拟 `Clock` 实现确定性测试。
- 跨目标：core/rules 零第三方依赖，js / wasm / native 三目标可编译，同一校验定义前后端复用。
- 可选包：`/schema`、`/react`、`/lens-gen`。

**状态管理侧对照**：`mizchi/signals` 0.6.6（2026-10-05，`build_status=success`，3 个下游）提供细粒度响应式 signals；`mizchi/luna` 0.25.2（2026-10-18）是响应式 UI 库；`tiye/respo` 0.3.4（2026-05-17）是 virtual DOM。moonform 自身即覆盖"表单状态 + 校验"这一组合层。

**检索词**：`form`、`validation`、`state management`、`reactive`、`store`、`form state`、`form validation`、`表单校验`（中文词可用）。

**判定依据 URL**：
- https://mooncakes.io/docs/2d5rrr333/moonform
- https://mooncakes.io/docs/mizchi/signals

---

### 12. MoonBit n2 风格增量构建工具 —— 已有成熟包

**最相关包**：`Zcxssxx/moon-ninja` v0.3.2，发布 2026-08-16，下载 65，`build_status=success`，共 7 个版本，GitHub 最后 push 2026-08-16。

- 链接：https://mooncakes.io/docs/Zcxssxx/moon-ninja
- 源码：https://github.com/Zcxssxx/Zcxproject11

**功能覆盖（README 明示）**：

- 真实 `build.ninja` 风格文本解析：`rule` 块、`build outputs: rule inputs`、单边多输出、`|` 隐式依赖与 `||` order-only 依赖、注释。
- 依赖图构建 + Tarjan SCC 诊断 + 环检测。
- 增量重建决策：native MTime + 内容哈希快照；`incremental.mbt` / `build_state.mbt` 持久化状态 sidecar。
- Make 风格 depfile 解析并合并到产生边（`parse_depfile`、`dependency_diff.mbt`）。
- `$in` / `$out` 展开、命名变量展开、response file 物化。
- 确定性无锁依赖波次 + 有界 worker 池并行执行；WASM-GC/JS host 执行 ABI。
- 可检视 build plan、路径安全、命令校验；CI 与自检脚本。
- 边界：README 明示是"a well-documented subset of Ninja"；所列范围未提及 `restat`、`dyndep`、console pool。

**同域其他包**：

| 包 | 版本 / 更新 | 覆盖 |
|---|---|---|
| Lyhdsba/moonforge | 0.1.3 / 2026-08-11 | MoonBit 原生增量任务运行器（小型构建、codegen、本地 CI） |
| 123123213weqw/moon_taskforge | 0.10.0 / 2026-10-18 | 本地增量 DAG 任务执行，带缓存与恢复 |
| mizchi/pkf | 0.16.0 / 2026-08-30 | Pkl-native 任务运行器 |

**检索词**：`ninja`、`incremental build`、`build system`、`增量构建`（中文词可用）。

**判定依据 URL**：
- https://mooncakes.io/docs/Zcxssxx/moon-ninja
- https://mooncakes.io/docs/Lyhdsba/moonforge

---

## 3. 方法论与局限

### 3.1 实际使用的检索路径

1. **首页/文档页是 SPA，但数据在服务端可拿**：`https://mooncakes.io/` 与 `https://mooncakes.io/docs/<owner>/<name>` 均返回 HTML，内含 `<script id="__rabbita_transcript" type="application/json">`，保存了首屏所有 API 响应。
2. **搜索 API**：`GET https://mooncakes.io/api/v0/search?kw=<关键词>&limit=50`。返回字段：`name`、`version`、`yanked`、`license`、`repository`、`keywords`、`description`、`created_at`、`downloads`、`matched_package_count`、`matched_packages[].summary`。
3. **包详情 API**：`GET https://mooncakes.io/api/v0/modules/<owner>/<name>`。返回 `latest_version`、`versions[]`、`dependents[]`、`build_status`、`metadata.created_at`（当前最新版本的发布时间）、`metadata.repository`。
4. **README 正文**：详情 API 的 `metadata.readme_content` 为空；改从文档页 transcript 中的 `https://assets.mooncakes.io/assets/<module>@<version>/resource.json` 取 `readme_content`，成功取到全部重点包的完整 README。
5. **GitHub 交叉验证**：`gh api repos/<owner>/<repo>` 取 `pushed_at`、stars；`gh api repos/<owner>/<repo>/readme` 取 README。`gh` 已登录，经 `HTTPS_PROXY=http://127.0.0.1:7892` 访问。
6. **新包扫描**：`GET /api/v0/modules?recent=60&new=60&popular=60`，扫描最近/最新/最热各 60 条，确认没有漏掉 2026-10/11 新发布的同域包。

### 3.2 检索词清单（中英双跑）

| 候选 | 实际检索词 |
|---|---|
| 1 MQTT | mqtt / mqtt5 / mqtt client / pubsub / broker；GitHub `mqtt` |
| 2 反向代理 | proxy / reverse proxy / http server / http / load balancer / 反向代理（0 hit） |
| 3 Arrow | arrow / columnar / parquet / record batch / 列式内存（0 hit） |
| 4 DataFrame | dataframe / tabular / pandas / csv |
| 5 向量库客户端 | vector database / qdrant / milvus / similarity search / 向量数据库 |
| 6 音频解码 | wav / ogg / audio / opus / vorbis / 音频解码 |
| 7 LSP | lsp / language server / jsonrpc；GitHub `language server protocol` |
| 8 Typst | typst / typesetting / markup / 排版；GitHub `typst` |
| 9 分布式仿真 | simulation / distributed / distributed simulation / consensus / raft / fault injection / deterministic / discrete event |
| 10 OCI | oci / container image / docker / tar |
| 11 表单 | form / validation / state management / reactive / store / form state / form validation / 表单校验 |
| 12 增量构建 | ninja / incremental build / build system / 增量构建 |

### 3.3 关键局限（必须与结论一起读）

1. **搜索索引不是全文索引**。`matched_packages[].summary` 与 `summary_fragments` 表明，检索匹配的是「包名 + keywords + 平台自动生成的包摘要」，不是 README 全文。因此：
   - 中文关键词覆盖不稳定：`反向代理`、`列式内存` 都返回 0 条，但英文 `reverse proxy` / `arrow` 能命中；`向量数据库`、`音频解码`、`表单校验`、`增量构建` 则可用。本次对每个候选都做了中英双跑，仍不能排除"摘要未写到某能力点"导致的漏检。
   - 单次搜索默认只返回 20 条；本次统一加 `&limit=50`。`limit` 参数有效（实测 `form` 返回 50 条），但 `page` / `offset` 参数无效（结果不翻页），因此无法保证拿到第 50 条之后的命中。
2. **"最近更新"取的是 mooncakes 最新版本发布时间**（详情 API `metadata.created_at`），不是仓库 commit 时间。表中的 GitHub `pushed_at` 仅作辅助。两者可能不一致，例如 MoonFrame 的 mooncakes 最新版本是 2026-10-30，但 GitHub 在 2026-11-06 仍有提交。
3. **`repository` 字段可能过期/错误**。`shunge/arrow` 的搜索记录写 `github.com/shunge/arrow`（404），manifest 中才是真实仓库 `github.com/buildliming/MoonArrow`；`LL728/moonopus` 的仓库指向 `Xcsa-ee/moonopus`。因此 GitHub 404 不能反证包不存在，本报告一律以 manifest 的 `repository` 为准，并在 404 时改用 mooncakes 的 `resource.json` README。
4. **部分仓库不可读**：`SundayT1998/milvus-client`、`moonbitlang/typst`、`oyjh0381/moonoci`、`Zcxssxx/moon-ninja` 的 `repos/<owner>/<name>` 调用返回 404（仓库名与 module 名不同，或仓库私有/迁移）。这些包的 README 已从 mooncakes `resource.json` 取得，功能判断不受影响；但 stars、issue 活跃度无法核实。
5. **"维护良好"没有量化阈值**。黑客松规则只给了"近期仍在维护（2026 年有更新）"。本报告据此判定，并额外列出：版本数、下载量、`build_status`、GitHub `pushed_at`。需要特别注意的两处：
   - `yuzhiblue/moon-qdrant` 0.5.0 的 `build_status` 为 **failed**（共 11 个版本，GitHub 侧有 CI badge），Qdrant 这一半的"可构建性"存疑；Milvus 侧的 `SundayT1998/milvus-client` 为 success。
   - `oyjh0381/moonlab`（v0.1.0，单版本，34 下载）、`oyjh0381/moonoci`（v0.1.4，5 个版本，80 下载）、`Zcxssxx/moon-ninja`（v0.3.2，7 个版本，65 下载）均为单人低下载量包，功能重合但生态验证程度有限；对照组 `2d5rrr333/moonform` 有 21 个版本、195 下载。
6. **只核对了功能声明，未做代码级验证**。判定依据是 README、公开 API 索引（`module_index.json` / `package_data.json`）与 `build_status`；未逐一 clone 运行测试，因此"覆盖"指 README/API 声称的覆盖，不代表质量与边界完全可靠。
7. **快照时点**：以上数据为 2026-11-06 当日 API 快照；首页 `new` 列表中已有 2026-11-06 当天发布的包，说明注册表仍在持续新增，结论可能随新包出现而变化。所有引用包在检索时 `yanked=false`。
