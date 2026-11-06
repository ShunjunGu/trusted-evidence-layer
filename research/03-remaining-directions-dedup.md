# MoonBit 黑客松官方推荐清单剩余方向 · mooncakes.io 查重

- 检索日期：2026-11-06
- 主数据源：`https://mooncakes.io/api/v0/*`（搜索 / 模块详情 / 最近新增扫描）与 registry 托管 README（`https://assets.mooncakes.io/assets/<owner>/<name>@<version>/resource.json` 的 `readme_content`）
- 辅助源：GitHub（`gh api`，经代理 `http://127.0.0.1:7892`），仅用于核对仓库活跃度与仓库名，不作为包存在性的反证
- 查重范围：官方推荐清单中未被前一轮 12 个候选覆盖的 17 个方向。其中「解释器 / 运行时」按要求拆为 Python、Lua、Visual Basic 三项，共 19 个判定单元
- 判定口径（与前一轮一致）：
  - `已有成熟包`：功能高度重合，且 2026 年有发布 / 更新
  - `部分重叠`：有相关包，但覆盖不足或已停更
  - `空白`：未检索到相关包
- 维护强度另附：版本数、注册表 `downloads`、`build_status`、`dependents`、GitHub `pushed_at`。判定后带 `*` 表示维护强度偏弱（版本少或下载量低），详见逐条

## 1. 汇总表

| # | 方向 | 判定 | 最相关包 | 版本 / 更新 | 链接 |
|---|---|---|---|---|---|
| 1 | QUIC 协议库 | **已有成熟包** | moonbitstack/moonquic | 0.3.11 / 2026-11-04 | https://mooncakes.io/docs/moonbitstack/moonquic |
| 2 | Kafka 异步客户端 | **已有成熟包** | daqing/moonkafka | 0.3.4 / 2026-09-29 | https://mooncakes.io/docs/daqing/moonkafka |
| 3 | NATS 异步客户端 | **已有成熟包**\* | sa2360/moonnats；bzhangui/moonjet | 0.1.2 / 2026-10-30；0.2.1 / 2026-10-27 | https://mooncakes.io/docs/sa2360/moonnats |
| 4 | 轻量 WebHook 处理框架 | **已有成熟包**\* | bzhangui/hooklab；lin2077-zeming/MoonHook | 0.3.0-rc.5 / 2026-09-28；0.4.0 / 2026-09-12 | https://mooncakes.io/docs/bzhangui/hooklab |
| 5 | API 动态规则校验引擎 | **已有成熟包** | YeeHh2004/moonrule；mw1696803-hub/moonup | 0.4.1 / 2026-08-11；0.1.1 / 2026-10-22 | https://mooncakes.io/docs/YeeHh2004/moonrule |
| 6 | 自动布局引擎（OGDF / d3-force 类） | **已有成熟包** | moonbit-community/elk；gaato/force | 0.4.1 / 2026-11-03；0.1.0 / 2026-10-20 | https://mooncakes.io/docs/moonbit-community/elk |
| 7 | 事件总线 / 消息抽象层 | **已有成熟包**\* | violetcb/eventrail；shaoaiwan/moonevent | 0.3.2 / 2026-08-17；0.2.0 / 2026-08-23 | https://mooncakes.io/docs/violetcb/eventrail |
| 8 | Actor 模型并发框架 | **已有成熟包**\* | didiLjf/moonorbit | 0.2.1 / 2026-08-16 | https://mooncakes.io/docs/didiLjf/moonorbit |
| 9 | Spark / Flink 类大数据处理引擎 | **部分重叠** | LMK-ai-nb/tideweave；bobzhang/differential | 0.2.5 / 2026-10-29；0.1.0 / 2026-10-16 | https://mooncakes.io/docs/LMK-ai-nb/tideweave |
| 10 | 分布式 SQL 查询引擎 | **部分重叠** | superbigcup325/moonlake | 0.6.4 / 2026-10-31 | https://mooncakes.io/docs/superbigcup325/moonlake |
| 11 | ReactiveMongo 类响应式 MongoDB 驱动 | **部分重叠** | allain/mongodb | 0.1.1 / 2026-01-29（build_status=legacy） | https://mooncakes.io/docs/allain/mongodb |
| 12 | Kubernetes API 客户端 / Controller 框架 | **已有成熟包**\* | cxh04/kubemoon | 0.1.1 / 2026-09-30 | https://mooncakes.io/docs/cxh04/kubemoon |
| 13 | 基于 WASM 的 Kubernetes Operator 运行时 | **空白** | 未检索到 | — | — |
| 14a | Python 解释器 / 运行时 | **部分重叠** | marianoguerra/pure-py | 0.12.0 / 2026-10-27 | https://mooncakes.io/docs/marianoguerra/pure-py |
| 14b | Lua 解释器 / 运行时 | **已有成熟包**\* | hongweifei/lua | 0.1.0 / 2026-09-29 | https://mooncakes.io/docs/hongweifei/lua |
| 14c | Visual Basic 解释器 / 运行时 | **空白** | 未检索到 | — | — |
| 15 | LaTeX 渲染库 | **部分重叠** | kokic/katex-parser | 0.6.0 / 2026-10-02 | https://mooncakes.io/docs/kokic/katex-parser |
| 16 | find / cat / ls 等经典 CLI 的现代替代 | **已有成熟包** | cli/find；cli/ls | 0.2.5 / 2026-11-01；0.2.4 / 2026-10-27 | https://mooncakes.io/docs/cli/find |
| 17 | HTTP Web 服务器（应用服务器 / 框架） | **已有成熟包** | moonbitlang/moonback；moonbitstack/mooncat | 0.8.10 / 2026-10-30；0.19.5 / 2026-11-05 | https://mooncakes.io/docs/moonbitlang/moonback |

> `*` = 维护强度偏弱。判定仍按「功能重合 + 2026 年有更新」给出，弱维护只作为附注，不等同于「不重合」。

## 2. 逐条详述

### 1. QUIC 协议库 —— 已有成熟包

**最相关包**：`moonbitstack/moonquic` v0.3.11，最新版本发布 2026-11-04，注册表 `downloads=1152`，`build_status=success`，15 个版本，1 个依赖方。GitHub `moonbitstack/moonquic` 最后 push 2026-11-05。

- 链接：https://mooncakes.io/docs/moonbitstack/moonquic
- 源码：https://github.com/moonbitstack/moonquic

**README 声称的覆盖范围**：

- 定位为「The QUIC transport for MoonBit (RFC 9000, RFC 9001, RFC 9002) — bytes in, events out」。
- 分包覆盖：`frame`（RFC 9000 §19 全部帧类型、ACK range 编码）、`packet`（长 / 短头、Retry、Version Negotiation、包号、三个包号空间）、`crypto`（RFC 9001 §5 包保护、头保护、Retry tag、§6 密钥更新）、`recovery`（RFC 9002 RTT、两档丢包阈值、PTO、NewReno / CUBIC / BBR、持久拥塞）、`stream`（流 ID 与重组、双向状态机、流控与配额、轮转调度）、`conn`（传输参数、CRYPTO 流、客户端 / 服务端握手、连接表与事件循环、放大限制、连接迁移与路径验证、无状态重置、RFC 9221 datagram、0-RTT）。
- `Endpoint::server` 在 moontls 的 QUIC 模式下运行 TLS 1.3 握手；socket 由调用方提供，核心为 sans-IO。
- 8 个可运行示例（frames / params / crypto / ack / flow / recovery / streams / sender）。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| moonbitstack/moonnet | 0.1.10 / 2026-11-05 | 1901 | TCP / TLS / QUIC 的 connection、listener、dialer |
| moonbitstack/moonhttp | 0.15.8 / 2026-11-05 | 2857 | 无 I/O 的 HTTP/1–HTTP/3、WebSocket、SSE、multipart |
| ZSeanYves/MoonbitHTTP | 0.7.0 / 2026-10-07 | 140 | HTTP/1.1、HTTP/2、HTTP/3、QUIC、TLS 的流式协议套件，仅 2 个版本 |
| OJII3/moq-mbt | 0.4.2 / 2026-11-05 | 95 | Media over QUIC（MoQ）传输 |

**检索词**：`quic`、`http3`、`http/3`（QUIC 为英文缩写，无独立中文词）。

**判定说明**：QUIC 传输层 + HTTP/3 映射 + 网络 dialer 三层都已存在，且 moonquic 为 15 版本、跨 2026-11 仍在发布的项目。判 `已有成熟包`。

**依据 URL**：
- https://mooncakes.io/docs/moonbitstack/moonquic
- https://mooncakes.io/docs/moonbitstack/moonnet

---

### 2. Kafka 异步客户端 —— 已有成熟包

**最相关包**：`daqing/moonkafka` v0.3.4，发布 2026-09-29，`downloads=87`，`build_status=success`，7 个版本，0 个依赖方。GitHub `daqing/moonkafka` 最后 push 2026-10-29。

- 链接：https://mooncakes.io/docs/daqing/moonkafka
- 源码：https://github.com/daqing/moonkafka

**README 声称的覆盖范围**：

- 明确「Target: Apache Kafka 4.x only」，只支持 KRaft 集群，不兼容 ZooKeeper 时代。
- 线协议编解码：compact types、zig-zag varint、tagged fields；按 broker 通告范围做逐请求 API 版本协商。
- RecordBatch v2（CRC32C 校验）、record headers、控制 / 事务标志、`read_committed` 过滤、增量 batch builder、gzip / snappy / lz4 / zstd 整批解压。
- 数据面：Produce v12/v13、Fetch v12–v16（增量 fetch session，KIP-227）、Metadata v12/v13、DescribeTopicPartitions v0、ListOffsets v10/v11、FindCoordinator v4。
- 集群层：按 node id 共享连接池、metadata 缓存与过期 / 错误刷新、topic-id 映射、coordinator 查找。
- Producer：按 leader 连接、murmur2 key 分区、sticky / round-robin、batch linger / batch-size / buffer-memory、后台 sender、acks 0/1/-1、退避重试、leadership 变更刷新、REBOOTSTRAP_REQUIRED 恢复、幂等 producer（InitProducerId、序列号、epoch bump）、事务（begin / commit / abort、AddPartitionsToTxn、TxnOffsetCommit、fencing）。
- Consumer：并发 per-leader fetch、增量 session 与驱逐恢复、按 sentinel / 时间戳解析 offset、seek 族、同步 / 异步 commit 与 autocommit、pause / resume、auto-offset-reset、leader-epoch 截断检测、read_committed。
- 消费组：KIP-848（默认路径，服务端分配、静态成员、regex 订阅）与 classic（JoinGroup / SyncGroup / Heartbeat，range / round-robin / sticky / cooperative-sticky）。
- Admin：topic、config、ACL、quota、SCRAM、log dirs、leader、reassignment、cluster / controller 内省、transaction、group。
- Share groups（KIP-932）：`ShareConsumer` + ShareGroupHeartbeat v1。
- README 自述测试规模「200+ test suite（unit、mock-broker、golden fixtures）+ 可选真实集群集成 harness」。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| daqing/moonkafka-demo | 0.3.0 / 2026-09-30 | 28 | producer / consumer 示例 |
| zbhzs1/moonasyncapi | 0.2.0 / 2026-09-19 | 37 | AsyncAPI 3.0 → MoonBit 类型 / 消息接口生成器，不是客户端 |

**检索词**：`kafka`（仅 3 条结果）、`kafka client`；中文「卡夫卡」返回 0 条。

**判定说明**：注册表中唯一的 Kafka 客户端，功能面覆盖到事务、KIP-848、Admin、Share Groups，属「实现完整但下载量低」的单点项目。判 `已有成熟包`，维护强度注记为下载量偏低（87）。

**依据 URL**：
- https://mooncakes.io/docs/daqing/moonkafka

---

### 3. NATS 异步客户端 —— 已有成熟包（弱维护）

**最相关包（核心 NATS）**：`sa2360/moonnats` v0.1.2，发布 2026-10-30，`downloads=52`，`build_status=success`，3 个版本，0 个依赖方。GitHub `sa2360/moonnats` 最后 push 2026-10-29。

- 链接：https://mooncakes.io/docs/sa2360/moonnats
- 源码：https://github.com/sa2360/moonnats

**README 声称的覆盖范围**：

- 零 I/O 的协议编解码层（可跑 wasm）+ 基于 `moonbitlang/async` 的 native 异步客户端。
- 主题校验与 `*` / `>` 通配符匹配；PUB / SUB / UNSUB / PING / CONNECT 编码；服务端帧流式解析（TCP 粘包 / 半包、二进制 payload）；INFO 握手；HMSG 头块；INBOX 生成。
- `ReconnectingClient` 已知节点轮换与订阅恢复；TLS（系统根证书 / 自定义 PEM，TLS-first）；`connect_urls` 集群节点发现；CLI `moonnats_cli pub / sub`。
- README 自述 CI 用真实 nats-server 覆盖 TLS、集群拓扑、收发与关闭；Windows 不跑完整 native async 客户端测试。

**同域其他包（JetStream）**：`bzhangui/moonjet` v0.2.1，发布 2026-10-27，`downloads=59`，`build_status=success`，4 个版本。

- 链接：https://mooncakes.io/docs/bzhangui/moonjet
- README 声称：NATS JetStream 持久消息 SDK，有界二进制协议、持久发布、消息 ID 去重、ACK、重投、回放、背压、断线恢复、durable pull。
- README 同时声明：核心协议与 JetStream 请求 / ACK / PubAck 由 MoonBit 实现，但**联网为 Node/JS 参考适配**，「不冒称 Native/Wasm 已联网」，且「不是完整官方客户端」。

**检索词**：`nats`（2 条）、`nats jetstream`、`jetstream`；中文「消息队列」返回 0 条。

**判定说明**：核心 NATS 协议 + 异步客户端 + 重连 / TLS / 集群发现已有完整实现；JetStream 侧有独立包但联网适配仅 Node/JS。两者均为 3–4 版本、50 余下载。判 `已有成熟包*`。

**依据 URL**：
- https://mooncakes.io/docs/sa2360/moonnats
- https://mooncakes.io/docs/bzhangui/moonjet

---

### 4. MQTT 之外的轻量 WebHook 处理框架 —— 已有成熟包（弱维护）

**最相关包（入站平台）**：`bzhangui/hooklab` v0.3.0-rc.5，发布 2026-09-28，`downloads=88`，`build_status=success`，3 个版本，0 个依赖方。GitHub `bzhangui/hooklab` 最后 push 2026-11-03。

- 链接：https://mooncakes.io/docs/bzhangui/hooklab
- 源码：https://github.com/bzhangui/hooklab

**README 声称的覆盖范围**：

- 自托管 Webhook 安全与事件交付平台：原始负载验签、时间窗校验、防重放、事务持久化、路由、受限转换、应用事件发布、出站签名、Worker 租约、可靠重试、死信与回放。
- 两种模式：`serve-config`（SQLite 单机、静态受信任配置）与 `serve-platform`（PostgreSQL 多租户、CloudEvents、SLO 与告警、消费者门户）。
- MoonBit 领域内核可编译到 JS / Wasm / Wasm-GC / Native；服务器适配器运行在 Node.js。
- README 明确「可安装的 MoonBit 核心库，不代表完整平台已公开托管或达到生产就绪」。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| lin2077-zeming/MoonHook | 0.4.0 / 2026-09-12 | 57 | **出站**投递框架：事件建模、Hook 注册、HMAC-SHA256 签名与验签、时间戳防重放、重试、Outbox、死信、幂等、审计日志；`transport_http` 基于 `moonbitlang/async` 真实 POST。README 自述「专注投递侧，入站只提供最小验签处理器」 |
| zzy12346/moonhook | 0.2.0 / 2026-08-28 | 34 | 描述为「A lightweight MoonBit WebHook processing framework」，但 README 正文只有标题 `# zzy12346/moonhook`（21 字符），无任何能力说明；仓库名为 `zzy12346/12312` |
| mxz1234/moon_webhook_guard | 0.2.0 / 2026-08-21 | 32 | Webhook 签名验证、重放保护、幂等、事件路由工具包；1 个版本 |
| chensuiyi/notify | 0.6.0 / 2026-10-06 | 49 | 多平台通知（飞书 / 钉钉 / 企业微信 / Slack / Discord / 通用 Webhook / SMTP），含去重、限流、重试；偏向发送端 |

**检索词**：`webhook`（17 条）、`hook`、`web hook`；中文「回调」返回 0 条。

**判定说明**：入站（hooklab）、出站（MoonHook）、验签（moon_webhook_guard）、通知（notify）四个切面都已有包，但均为单人 0.x、32–88 下载；其中一个包的 README 为空壳。功能重合成立，成熟度不足。判 `已有成熟包*`。

**依据 URL**：
- https://mooncakes.io/docs/bzhangui/hooklab
- https://mooncakes.io/docs/lin2077-zeming/MoonHook
- https://mooncakes.io/docs/zzy12346/moonhook

---

### 5. API 动态规则校验引擎（runtime rule validation） —— 已有成熟包

**最相关包（表达式规则）**：`YeeHh2004/moonrule` v0.4.1，发布 2026-08-11，`downloads=57`，`build_status=success`，5 个版本，0 个依赖方。GitHub `YeeHh2004/moonrule` 最后 push 2026-08-11。

- 链接：https://mooncakes.io/docs/YeeHh2004/moonrule
- 源码：https://github.com/YeeHh2004/moonrule

**README 声称的覆盖范围**：

- 「轻量、可解释动态规则引擎」，把规则表达式编译为可复用程序，在 JSON 数据上执行；明确面向「API 准入、表单校验、配置检查和 CI 质量门禁」。
- 词法 / 优先级解析 / 不可变 AST；JSON 字段、数组索引、嵌套路径、`?.` / `?[...]` 可选访问；算术、比较、布尔短路、集合成员；字符串 / 数组 / 对象 / 正则内置函数；一次编译多次执行；多规则批量校验。
- 稳定诊断码、源码范围、修复提示；确定性逐步执行轨迹；对不可信规则文本做长度 / AST 节点数 / 嵌套深度限制；运行期最大执行步数限制。
- 静态分析（依赖路径、函数调用、复杂度、不可达分支）、严重级别策略、快速失败、多数据批量校验；25 个内置函数；JSON 报告与 CI 退出码。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| mw1696803-hub/moonup | 0.1.1 / 2026-10-22 | 32 | 产生式规则引擎（Rete 网络）：多事实工作内存、跨事实 join、增量传播、冲突消解、match-select-act。README 明确写「与 moonrule 互补：moonrule 判断输入合不合法，MoonUp 判断事实流变化时该做什么」 |
| 123123213weqw/moon_policyforge | 0.10.0 / 2026-10-18 | 45 | 可解释规则决策：37 个操作、优先级、first/all/unique 决策、冲突标记、条件轨迹、规则集 diff、JSON Schema 2020-12 导出、100k fact 规模校验、206 个白盒测试 |
| z2823253773-p/moonrules | 0.2.0 / 2026-07-29 | 39 | 可解释、带预算限制的 JSON 业务规则 |
| kaigeliang/jsonlogic | 0.2.1 / 2026-10-09 | 43 | JSONLogic 求值、作用域分析、批量执行、QueryX 集成 |
| moonbitstack/moonschema | 0.2.4 / 2026-11-03 | 1626 | JSON Schema draft-04 到 v1 校验，四种输出格式、十九个 format 名 |
| colmugx/json-schema | 0.1.5 / 2026-10-23 | 6660 | compile-once JSON Schema 2020-12 校验器，精确十进制、pattern 语义 |
| mizchi/jsonschema | 0.8.1 / 2026-08-15 | 5291 | JSON Schema 校验器 + 代码生成，19 个版本 |
| Betterlol/moon_zod | 0.10.0 / 2026-11-02 | 223 | Zod / Pydantic 风格的运行时 JSON Schema 校验，16 个版本 |

**检索词**：`rule`、`rule engine`、`validation`、`validator`、`json schema`、`jsonlogic`、`policy`、`rules`；中文「规则引擎」返回 0 条。

**判定说明**：表达式校验（moonrule）、产生式规则（moonup）、决策表（policyforge）、JSON Schema（moonschema / json-schema / jsonschema）四个层次都存在，且 JSON Schema 侧已有数千下载的成熟包。判 `已有成熟包`。

**依据 URL**：
- https://mooncakes.io/docs/YeeHh2004/moonrule
- https://mooncakes.io/docs/mw1696803-hub/moonup
- https://mooncakes.io/docs/123123213weqw/moon_policyforge

---

### 6. 自动布局引擎（OGDF / d3-force 类） —— 已有成熟包

**最相关包（ELK / OGDF 类分层布局）**：`moonbit-community/elk` v0.4.1，发布 2026-11-03，`downloads=7281`，`build_status=success`，2 个版本（社区命名空间下），1 个依赖方。GitHub `moonbit-community/moon_elk` 最后 push 2026-11-03，4 stars。

- 链接：https://mooncakes.io/docs/moonbit-community/elk
- 源码：https://github.com/moonbit-community/moon_elk

**README 声称的覆盖范围**：

- Eclipse Layout Kernel（ELK）的 MoonBit 端口；社区维护版，承接 `Milky2018/moon_elk` 与 `bobzhang/elk`，旧包已弃用。
- 兼容基线为 elkjs 0.9.3（ELK 0.9.1）；坐标可能与早期 elkjs 0.8.2 版本不同。
- 提供 `layout_json`：JSON 图输入 → ELK 引擎布局 → JSON 输出；`engine/all` 为聚合入口。
- README 未逐项列出算法族，只声明「ELK port」与兼容基线。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| Milky2018/moon_elk | 0.3.2 / 2026-10-13 | 46349 | 同项目的前身，22 个版本，已被 registry 标记 `yanked=true` |
| moonbit-community/moon_dagre | 0.3.1 / 2026-07-16 | 51147 | dagre 端口，支持 directed / multigraph / compound graph 的有向图分层布局，4 个版本，2 个依赖方 |
| gaato/force | 0.1.0 / 2026-10-20 | 28 | **d3-force 端口**：`link`、`many_body`（Barnes–Hut）、`center`、`collide`、`x`、`y`；JS / native / wasm-gc 同 seed 同坐标；单版本 |
| moonbit-community/diago | 0.4.1 / 2026-11-03 | 6788 | 图表工具包，聚合 Dagre、ELK、Railway 三种布局引擎，输出 SVG / ASCII / Unicode |
| moonbit-community/graphviz | 0.1.10 / 2026-09-17 | 45655 | Graphviz 重写（DOT 解析 + 布局 + SVG），11 个版本，3 个依赖方 |
| dowdiness/graphviz | 0.1.0 / 2026-04-21 | 27834 | DOT 解析、布局引擎、SVG 渲染 |

**检索词**：`layout`、`graph layout`、`force-directed`、`dagre`、`elk`、`ogdf`、`d3`、`graphviz`、`diagram`；中文「布局」「力导向」各返回 0 条。

**判定说明**：OGDF 同类（ELK 分层布局）与 d3-force 同类（gaato/force）都已有直接对应包，dagre / graphviz / diago 进一步覆盖有向图与 DOT。d3-force 侧仅有 1 个版本、28 下载，属弱维护；ELK 侧有 22 版本历史与数千下载。判 `已有成熟包`。

**依据 URL**：
- https://mooncakes.io/docs/moonbit-community/elk
- https://mooncakes.io/docs/gaato/force
- https://mooncakes.io/docs/moonbit-community/moon_dagre

---

### 7. 事件总线 / 消息抽象层 —— 已有成熟包（弱维护）

**最相关包**：`violetcb/eventrail` v0.3.2，发布 2026-08-17，`downloads=49`，`build_status=success`，5 个版本，0 个依赖方。GitHub `violetcb/eventrail` 最后 push 2026-08-17。

- 链接：https://mooncakes.io/docs/violetcb/eventrail
- 源码：https://github.com/violetcb/eventrail

**README 声称的覆盖范围**：

- 「MoonBit 原生的确定性事件总线与消息轨迹库」。
- 订阅注册、按主题路由、批量校验与发布、投递结果记录、重试与死信、事件流查询、读模型投影、快照与诊断报告、事件保留策略、事件回放。
- 适用场景写明：进程内事件通知、插件消息分发、Wasm 示例、API 规则验证、任务编排、单元测试重放、CI 事件流审计。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| shaoaiwan/moonevent | 0.2.0 / 2026-08-23 | 32 | 定位逐字对应「event bus and message abstraction layer」：Event / Subscription / HandlerReport / DispatchReport 模型、真实 `EventBus.publish`、中间件管道（可改写或中止）、topic 精确 / `*` / `#` 匹配、handler 优先级、pause / resume / unsubscribe |
| xvyve123/moonflow | 0.1.0 / 2026-08-23 | 29 | 描述为「A lightweight event bus and message abstraction layer」，但 README 正文只有 `# username/moonflow`（占位），仓库名为 `xvyve123/2131`；单版本 |

**检索词**：`event bus`（33 条）、`eventbus`、`bus`、`message`、`pubsub`；中文「事件总线」返回 0 条。

**判定说明**：两个包的定位与官方方向几乎逐字重合，eventrail 的功能面（重试、死信、投影、回放、保留策略）超过「抽象层」的最低要求。但三者均为 1–5 版本、29–49 下载，且 moonflow 的 README 为占位。判 `已有成熟包*`。

**依据 URL**：
- https://mooncakes.io/docs/violetcb/eventrail
- https://mooncakes.io/docs/shaoaiwan/moonevent

---

### 8. Actor 模型并发框架 —— 已有成熟包（弱维护）

**最相关包**：`didiLjf/moonorbit` v0.2.1，发布 2026-08-16，`downloads=61`，`build_status=success`，3 个版本，0 个依赖方。GitHub `didiLjf/moonorbit` 最后 push 2026-08-16。

- 链接：https://mooncakes.io/docs/didiLjf/moonorbit
- 源码：https://github.com/didiLjf/moonorbit

**README 声称的覆盖范围**：

- 基于 `moonbitlang/async` 的异步 Actor 框架，README 自述「生产级」「已按 OSC 2026 要求完成预验收自查」。
- 强类型 Actor + 独立异步信箱（`@aqueue.Blocking` / Unbounded / DiscardOldest / DiscardLatest）。
- 层级监督树：父 Actor 作为监督者，支持 `OneForOne` / `OneForAll` / `RestForOne`，带最大重试次数，失败后后台重建运行 Task 且信箱不丢失。
- 生命周期钩子：`pre_start`、`post_stop`、`pre_restart`、`post_restart`。
- 背压与限流；路由与负载均衡（RoundRobin / Broadcast / Random）；定时器（`send_after` / `send_repeatedly` + `TimerSubscription`）；`stash` / `unstash_all`。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| moonrockz/moon-lander-actors | 0.11.0 / 2026-10-31 | 47 | Moon-Lander 框架内的「local typed actors with bounded mailboxes」，不是通用 Actor 框架 |
| Zcxssxx/moon-actor | 0.1.0 / 2026-07-06 | 35 | 仅 1 个版本、无 README 描述，仓库名为 `Zcxssxx/Zcxproject22` |
| colmugx/fuwaroid | 0.4.0 / 2026-11-03 | 4800 | 「lightweight single-writer concurrency」，是并发原语而非 Actor 模型（无 mailbox / supervision） |

**检索词**：`actor`（50 条）、`actor model`、`mailbox`、`supervision`；中文查询不适用（`Actor` 为英文术语）。

**判定说明**：moonorbit 的监督树、信箱、背压、路由、定时器、stash 覆盖了 Actor 框架的核心语义；但仅 3 个版本、61 下载、0 依赖。判 `已有成熟包*`。

**依据 URL**：
- https://mooncakes.io/docs/didiLjf/moonorbit

---

### 9. Spark / Flink 类大数据处理引擎 —— 部分重叠

**最相关包（Flink 类事件时间窗口）**：`LMK-ai-nb/tideweave` v0.2.5，发布 2026-10-29，`downloads=71`，`build_status=success`，7 个版本，0 个依赖方。GitHub `LMK-ai-nb/TideWeave`。

- 链接：https://mooncakes.io/docs/LMK-ai-nb/tideweave
- 源码：https://github.com/LMK-ai-nb/TideWeave

**README 声称的覆盖范围**：

- README 首句：「通用、可嵌入的事件时间窗口处理库：窗口、水位线、UDAF、触发与状态清理，**对标 Flink 能力**」。
- 滚动 / 带相位偏移的滑动 / 会话窗口；半开区间；负窗口起点的 floor 对齐。
- 按事件 ID 插入 / 替换 / 撤回，跨 key 移动与多项原子事务；会话迟到合并、撤回拆分；count / Int64 sum / min / max 与成员来源。
- 显式水位线推进与 allowed-lateness；`WatermarkTracker` 有界乱序水位；`within_lateness` 探针。
- 可插拔 UDAF（`Measure` + `measure_window`），内置 count / sum / min / max / avg。
- 可配置触发（`Watermark` 或 `Count(n)`）；before / after changelog；显式状态清理 `Forget`；checkpoint 精确回放；下游 `View` 原子校验版本连续性。
- README 明确区分：「Flink 是分布式集群运行时……TideWeave 解决的是另一个问题：已经发生的事实被更正时，如何给出可核对、可回放、可被下游验证的修正」。
- 提供 `docs/FLINK_MAPPING.md` 逐条对照 Flink 能力。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| bobzhang/differential | 0.1.0 / 2026-10-16 | 28 | Differential Dataflow 的 MoonBit 端口；README 首段明确「work in progress」「not a completed port or a production release」。已实现 timestamp lattice、antichain、progress、join / reduce / distinct、arrangement、capture / replay、增量 BFS / 最短路等基础算子；`COMPATIBILITY.md` 跟踪剩余工作 |
| Oyc996/moonwatermarkkit | 0.2.0 / 2026-07-18 | 30 | 事件时间 watermark、lateness、窗口分配原语；单版本 |
| Ag108/MoonEventTime | 0.1.0 / 2026-11-05 | 0（新包） | 键控事件时间滚动窗口、watermark、迟到侧输出；`build_status=failed`，无 repository 字段 |
| zmjknn/moon-stream-quality | 0.2.2 / 2026-08-18 | 40 | 日志 / 传感器 / 事件流的流式数据质量规则引擎，不是通用流处理运行时 |

**检索词**：`spark`、`flink`、`stream processing`、`dataflow`、`big data`、`mapreduce`、`etl`、`pipeline`、`batch processing`；中文「大数据」「流处理」各返回 0 条。

**判定说明**：存在 Flink 语义级的事件时间窗口组件（TideWeave，7 版本、71 下载）和一个明确未完成的 Differential Dataflow 端口（单版本、28 下载），但**没有分布式执行运行时**（无调度器、shuffle / exchange、容错 checkpoint 协调、集群部署）。覆盖的是「单机事件时间窗口 + 增量数据流算子」，不是「Spark / Flink 类大数据处理引擎」。判 `部分重叠`。

**依据 URL**：
- https://mooncakes.io/docs/LMK-ai-nb/tideweave
- https://mooncakes.io/docs/bobzhang/differential

---

### 10. 分布式 SQL 查询引擎 —— 部分重叠

**最相关包（单机列式 SQL 引擎）**：`superbigcup325/moonlake` v0.6.4，发布 2026-10-31，`downloads=160`，`build_status=success`，11 个版本，0 个依赖方。GitHub `superbigcup325/moonlake`。

- 链接：https://mooncakes.io/docs/superbigcup325/moonlake
- 源码：https://github.com/superbigcup325/moonlake

**README 声称的覆盖范围**：

- 「An embeddable, columnar SQL engine for analytics」：对 CSV / Parquet 文件执行 SQL，native 与 wasm-gc 同一套代码。
- 自研 parser、binder、planner、向量化算子、hash join、聚合、窗口、spill store；无存储引擎、无 server、无 FFI。
- CSV 类型推断；Parquet 子集读写；`--memory` 下 ORDER BY spill 到有序 run、大 join / GROUP BY 分区处理，放不下时明确拒绝而不是 OOM。
- README 自述「All 22 TPC-H queries pass on their official texts within a 1e-9 relative tolerance」，另有 property tests、pushdown fuzzer、Parquet testing corpus。
- README 明确「A query engine over files, not a database」。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| uiwcvb/moonsql | 0.1.0 / 2026-08-13 | 37 | 纯 MoonBit、零 FFI 的嵌入式关系型 SQL 引擎：parser、类型检查、全语句执行、逻辑 B+Tree、4096B 页式单文件持久化、REPL；README 明确「当前没有 WAL / 事务」；单版本 |
| moonbit-community/sqlparser | 0.5.2 / 2026-10-30 | 329 | 可扩展 SQL lexer / parser |
| bobzhang/sqlglot | 0.1.0 / 2026-10-01 | 95 | SQL parser / transpiler / optimizer 的 sqlglot 端口 |
| JQ-ai-nb/relcore | 0.2.6 / 2026-10-25 | 54 | 关系执行核：typed plans、per-node cardinality、可验证契约 |
| codeworm96/magpiedb | 0.2.0 / 2026-04-20 | 57 | 轻量 OLAP 数据库（README 自述 vibe coded），2 个版本 |

**检索词**：`sql`（50 条）、`query engine`、`distributed sql`、`database engine`、`olap`、`distributed`；中文「分布式SQL」「查询引擎」各返回 0 条。

**判定说明**：单机 SQL 引擎（moonlake 覆盖 TPC-H 22 条、moonsql 覆盖 B+Tree 持久化）与 SQL 前端（sqlparser / sqlglot / relcore）都已存在，但**没有分布式层**：无 coordinator / worker、无分片 / 复制、无跨节点 shuffle / exchange、无分布式事务或全局调度。判 `部分重叠`。

**依据 URL**：
- https://mooncakes.io/docs/superbigcup325/moonlake
- https://mooncakes.io/docs/uiwcvb/moonsql

---

### 11. ReactiveMongo 类响应式数据库驱动（MongoDB driver） —— 部分重叠

**最相关包**：`allain/mongodb` v0.1.1，发布 2026-01-29，`downloads=39`，`build_status=legacy`，2 个版本，0 个依赖方。GitHub `allain/moonbit-mongodb` 最后 push 2026-01-29。

- 链接：https://mooncakes.io/docs/allain/mongodb
- 源码：https://github.com/allain/moonbit-mongodb

**README 声称的覆盖范围**：

- 「An async MongoDB driver for MoonBit with a simple JSON-based API」，基于 `moonbitlang/async`。
- 原生 OP_MSG 二进制线协议（MongoDB 3.6+）；JSON 优先的文档 API。
- Full CRUD；聚合管道（pipeline stage helper）；游标与批量迭代；索引管理；批量写；**Change Streams**（collection / database 级）；find-and-modify 原子操作；Extended JSON（ObjectId / DateTime / Int64）。
- 需要 native target（async TCP）。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| oboard/morm | 0.5.0 / 2026-09-24 | 857 | 轻量 ORM，带 typed queries、代码生成、多数据库引擎；检索结果与 README 均未声明 MongoDB 支持，不能作为 Mongo 驱动替代 |

**检索词**：`mongo`（50 条，绝大多数为 `mongo` 子串噪声）、`mongodb`（仅 2 条）、`bson`、`reactive`（26 条，均为 UI / signal / Rx 类）、`change stream`；中文「响应式」返回 0 条，「数据库驱动」返回 0 条。

**判定说明**：存在一个功能面较完整的**异步** MongoDB 驱动（CRUD、聚合、游标、索引、批量、Change Streams），但它（a）不是 ReactiveMongo 式的响应式流 / Observable 模型，（b）最后发布 2026-01-29，`build_status=legacy`，仅 2 个版本、39 下载。按「ReactiveMongo 类响应式驱动」口径，覆盖不足且已停更。判 `部分重叠`。

**依据 URL**：
- https://mooncakes.io/docs/allain/mongodb

---

### 12. Kubernetes API 客户端 / Controller 框架 —— 已有成熟包（弱维护）

**最相关包**：`cxh04/kubemoon` v0.1.1，发布 2026-09-30，`downloads=43`，`build_status=success`，2 个版本，0 个依赖方。GitHub `cxh04/KubeMoon` 最后 push 2026-09-30。

- 链接：https://mooncakes.io/docs/cxh04/kubemoon
- 源码：https://github.com/cxh04/KubeMoon

**README 声称的覆盖范围**：

- 「Kubernetes 动态客户端与 Controller Runtime」，自述补齐 Operator 依赖的链路：资源发现、动态对象、LIST / WATCH、缓存、去重队列、失败恢复、调谐。
- Discovery：解码 `/api` core 版本目录、`/apis` named group 目录、`APIResourceList`；保留服务端 group / version 顺序；解析 namespace scope、verbs、singularName、shortNames、categories、子资源。
- `httptransport` 基于 `moonbitlang/async/http`：五种请求方法、认证头、JSON body、连接复用、URL 限定在指定 API Server；HTTPS 默认系统信任根，`ClientConfig.ca_file` 支持 ServiceAccount CA；WATCH 独立连接逐块读取，跨 chunk 的 UTF-8 与半条 JSON 安全。
- `reflector` 用 resourceVersion 更新 `store`；BOOKMARK 只推进进度；`queue` 合并重复 key、处理期间再变化只补一次调谐；失败指数退避；`Expired/410` 自动重新 LIST；分页 LIST 收齐前不替换缓存。
- 在 kind 中验收 `cmd/configmirror`：CRD + Controller / RBAC + finalizer + 双目标同步 + Controller 重启 + 目标删除自愈，GitHub Actions kind 作业已验证。
- README 明确的质量边界：「v0.1 不承诺 kubeconfig exec / OIDC、云厂商认证、OpenAPI 强类型生成、leader election、Admission Webhook 或 **Wasm Operator Host**」；「当前实现只针对单实例 Controller」。

**同域其他包**：检索 `kubernetes`（3 条）、`k8s`（2 条）、`controller`、`crd`、`kube` 未发现第二个 K8s 客户端或 Controller 框架；`moonbitstack/moonctl` 是 MoonBit 服务代码生成器，不是 K8s 客户端；`moonbitstack/moonp8s` 是 Prometheus 指标库。

**检索词**：`kubernetes`、`k8s`、`kube`、`controller`、`crd`、`operator`；中文「容器编排」「控制器」各返回 0 条。

**判定说明**：K8s 动态客户端 + controller runtime 的核心链路已实现并做过 kind 端到端验收，但仅 2 个版本、43 下载、单实例、缺 leader election / Admission Webhook。判 `已有成熟包*`。

**依据 URL**：
- https://mooncakes.io/docs/cxh04/kubemoon

---

### 13. 基于 WASM 的 Kubernetes Operator 运行时 —— 空白

**检索结果**：未检索到任何相关包。

**检索词与结果**：

| 检索词 | 结果数 | 相关内容 |
|---|---|---|
| `operator` | 50 | 绝大多数是数学 / 张量算子；唯一 K8s 相关为 `cxh04/kubemoon`（Controller Runtime，不是 WASM Operator Host） |
| `wasm operator` | 12 | 全部为 JSON Schema、Web 绑定、Typst、张量算子等噪声，无 K8s 相关 |
| `wasm k8s` | 0 | — |
| `kubernetes` / `k8s` | 3 / 2 | 仅 `cxh04/kubemoon` 与 OpenTelemetry、moonctl |
| `crd` | 10 | 全部为 CRDT（字符子串命中），无 Kubernetes CRD |
| `controller` | 50 | 仅 `cxh04/kubemoon` 与游戏 / 物理 / UI 噪声 |

**旁证**：`cxh04/kubemoon` 的 README 在「声明质量边界」中明确把「Wasm Operator Host」列为 v0.1 **不承诺**的能力，说明该方向在 registry 中没有可复用的实现。

**判定说明**：`wasmoon`（Milky2018/wasmoon，WebAssembly runtime with JIT / interpreter / WASI / Component Model）是通用 WASM 运行时，不与 Kubernetes Operator 生命周期、CRD watch、调谐循环集成；不构成该方向的覆盖。判 `空白`。

**依据 URL**：
- https://mooncakes.io/docs/cxh04/kubemoon（README 明确排除 Wasm Operator Host）
- https://mooncakes.io/docs/Milky2018/wasmoon（通用 WASM 运行时，非 Operator Host）

---

### 14a. Python 解释器 / 运行时 —— 部分重叠

**最相关包**：`marianoguerra/pure-py` v0.12.0，发布 2026-10-27，`downloads=254`，`build_status=success`，15 个版本，1 个依赖方。GitHub `marianoguerra/pure-py-mb` 最后 push 2026-10-27。

- 链接：https://mooncakes.io/docs/marianoguerra/pure-py
- 源码：https://github.com/marianoguerra/pure-py-mb

**README 声称的覆盖范围**：

- Python 3.12 的 tokenizer 与 parser，产出 CPython 形状的 AST；一个筛除 PurePy 排除项的 sieve；well-formedness checker；解释器；把 AST 打回 Python 源码的 printer；CLI。
- **定位是「a pure functional subset of Python」**，有独立规范 `pure-py/pure-py-spec` 与小步操作语义；不是完整 CPython。
- 一致性：规范 v0.23.0 的 2378 条断言全过，四个 oracle；另有两个 oracle 直接对比 CPython 的 token 流与 parse tree，第三个做 printer round-trip。
- 提供浏览器 Playground 与 29 个示例；支持宿主通过 `host` 模块注入外部能力。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| Kaida-Amethyst/python | 0.1.7 / 2025-11-13 | 5106 | 「Manipulate Python code in Moonbit」，是 Python 代码操作 / 元编程，不是解释器；已超一年未更新 |
| moonbit-community/moonpython | 0.1.0 / 2026-10-29 | 17 | 无描述、无 README 内容，单版本，无法确认能力 |
| CAIMEOX/qc_pyext | 0.1.1 / 2026-01-26 | 1377 | QuickCheck / reference testing 的 Python 扩展，不是解释器 |

**检索词**：`python`（50 条）、`interpreter`、`runtime`、`vm`、`cpython`；中文「解释器」返回 0 条。

**判定说明**：存在一个经过规范一致性验证的 Python 3.12 **纯函数子集**解释器，但完整 Python 语法 / 对象模型 / 标准库 / C 扩展 / 生成器等均不在覆盖内；`moonpython` 无内容。判 `部分重叠`。

**依据 URL**：
- https://mooncakes.io/docs/marianoguerra/pure-py

---

### 14b. Lua 解释器 / 运行时 —— 已有成熟包（弱维护）

**最相关包**：`hongweifei/lua` v0.1.0，发布 2026-09-29，`downloads=29`，`build_status=success`，1 个版本，0 个依赖方。GitHub `hongweifei/lua.mbt` 最后 push 2026-10-14。

- 链接：https://mooncakes.io/docs/hongweifei/lua
- 源码：https://github.com/hongweifei/lua.mbt

**README 声称的覆盖范围**：

- 「用 MoonBit 实现的 Lua 5.4 解释器」：词法分析、语法分析、单遍代码生成、**寄存器式虚拟机**、全部标准库都在仓库内实现。
- 宿主边界为 `stub.c`：流、文件、时钟、环境变量、进程控制、与 `printf` 兼容的数字格式化、随机数发生器。
- 构建产物同时是 `lua` CLI：可跑脚本、`-e` 执行、交互式 REPL；支持 UTF-8 标识符（含中文变量名）。
- README 长 29,768 字符，含完整构建 / 测试 / 语言覆盖说明。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| tonyfettes/lua | 0.1.3 / 2025-12-11 | 1296 | Lua 语言 **bindings**（绑定官方 C 实现），`build_status=legacy`，4 个版本 |
| tonyfettes/mua | 0.1.1 / 2025-12-11 | 50 | 基于 tonyfettes/lua 的高层 Lua 绑定 |
| tonyfettes/tree_sitter_lua | 0.1.26 / 2026-03-26 | 63 | tree-sitter Lua 语法 |
| moonbit-community/tree-sitter-lua | 0.5.0 / 2026-10-25 | 20 | tree-sitter Lua 语法（新端口） |

**检索词**：`lua`（8 条）、`lua 5.4`、`interpreter`；中文「解释器」返回 0 条（见 14a 同项）。

**判定说明**：Lua 5.4 的完整解释器（含字节码 VM 与标准库）已有纯 MoonBit 实现，功能重合度高；但仅 1 个版本、29 下载、0 依赖。判 `已有成熟包*`。

**依据 URL**：
- https://mooncakes.io/docs/hongweifei/lua
- https://mooncakes.io/docs/tonyfettes/lua

---

### 14c. Visual Basic 解释器 / 运行时 —— 空白

**检索结果**：未检索到任何相关包。

**检索词与结果**：

| 检索词 | 结果数 | 相关内容 |
|---|---|---|
| `visual basic` | 5 | 全部无关（games、crater-browser、npm_typed、image、moon_rapier） |
| `basic` | 50 | 全部为子串噪声（moonapi、any-collection、AMQP、LLVM、logging 等），无 BASIC 语言实现 |
| `vb` | 9 | 全部无关（partsieve、moonplant、libyue、circuit-solver、SSE、wax 等） |
| `vba` | 1 | `zlhahaha/partsieve`（OOXML 审计），无关 |

**同域参考（非 BASIC）**：

| 包 | 版本 / 更新 | 覆盖 |
|---|---|---|
| marianoguerra/pure-py | 0.12.0 / 2026-10-27 | Python 3.12 纯函数子集 |
| hongweifei/lua | 0.1.0 / 2026-09-29 | Lua 5.4 完整解释器 |
| dowdiness/js_engine | 0.9.0 / 2026-09-11 | 纯 MoonBit 跨目标嵌入式 JavaScript 引擎 |
| FlyCloudC/scheme | 0.7.0 / 2026-08-05 | Scheme 教学解释器 |
| bobzhang/prolog | 0.1.6 / 2026-11-03 | Prolog 解释器（SLD resolution） |
| wdgodghl/moonwren | 0.9.4 / 2026-10-31 | Wren 兼容脚本语言实现 |
| pangbit/moonjsonnet | 0.2.3 / 2026-10-31 | Jsonnet 解释器 |
| connect0459/starlark | 0.5.4 / 2026-10-23 | Starlark 配置语言实现 |

**判定说明**：解释器生态覆盖了 Python 子集、Lua、JS、Scheme、Prolog、Wren、Jsonnet、Starlark，但没有任何 Visual Basic / VBA / BASIC 方言实现。判 `空白`。

**依据 URL**：
- 无（未检索到相关包）

---

### 15. LaTeX 渲染库 —— 部分重叠

**最相关包**：`kokic/katex-parser` v0.6.0，发布 2026-10-02，`downloads=185`，`build_status=success`，21 个版本，0 个依赖方。GitHub `kokic/katex-parser` 最后 push 2026-11-04。

- 链接：https://mooncakes.io/docs/kokic/katex-parser
- 源码：https://github.com/kokic/katex-parser

**README 声称的覆盖范围**：

- 「A port of the KaTeX parser」：把 LaTeX 数学表达式词法分析、语法分析为 typed AST，支持宏展开。
- `builtin_commands()` / `builtin_commands_json()`：导出内置命令目录（public symbols、functions、builtin macros、implicit commands、supported starred forms），供编辑器 / 构建流程读取。
- **README 未声称任何排版、布局、SVG / PDF / MathML 渲染能力**；它是 parser，不是 renderer。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| Lampese/biblatex | 0.1.0 / 2025-07-20 | 52 | BibTeX / BibLaTeX 解析与写出；已停更 |
| edragain2nd/biblatex | 0.1.1 / 2025-08-15 | 44 | 同上（另一个实现） |
| moonbitlang/typst | 0.1.10 / 2026-11-02 | 228 | Typst 排版引擎的 MoonBit 端口（官方），不是 LaTeX 兼容层 |
| moonbitlang/pagelayout | 0.8.1 / 2026-10-22 | 15480 | 分页文档布局引擎，format-neutral page-model IR + SVG / PDF 后端；可作为排版后端，但不解析 LaTeX |
| marianoguerra/html | 0.1.1 / 2026-10-19 | 118 | HTML / SVG / MathML 语义树与容错 parser，不含 LaTeX 数学布局 |
| CAIMEOX/Motiva | 0.3.0 / 2026-07-21 | 55 | Manim 风格动画引擎，非 LaTeX 渲染 |

**检索词**：`latex`（50 条）、`tex`、`katex`（3 条）、`mathml`（6 条）、`typesetting`（9 条）、`formula`（35 条）；中文「排版」「数学公式」各返回 0 条。

**判定说明**：LaTeX 数学表达式的**解析**已有成熟实现（21 个版本、185 下载），BibTeX 元数据解析也有两个包；但把 LaTeX 排版为 SVG / PDF / PNG 的**渲染器**未检索到。Typst 是另一门排版语言，不能直接渲染 LaTeX 源码。判 `部分重叠`。

**依据 URL**：
- https://mooncakes.io/docs/kokic/katex-parser
- https://mooncakes.io/docs/moonbitlang/typst

---

### 16. find / cat / ls 等经典 CLI 的现代替代 —— 已有成熟包

**最相关包（find）**：`cli/find` v0.2.5，发布 2026-11-01，`downloads=121`，`build_status=success`，8 个版本，0 个依赖方。仓库 `moonbit-community/cmd`，GitHub 最后 push 2026-11-05，1 star。

- 链接：https://mooncakes.io/docs/cli/find
- 源码：https://github.com/moonbit-community/cmd

**README 声称的覆盖范围**：

- 通过 `moonx cli/find@0.2.5 [PATH...] [EXPRESSION]` 运行；遍历目录树、不跟随符号链接。
- 谓词可用 `!`、AND、OR 组合；支持打印、`-exec`、`-delete`。
- 选项：`-name` / `-path`、`-type` / `-xtype` / `-empty` / `-size`、`-amin` / `-atime` / `-cmin` / `-ctime` / `-mmin` / `-mtime`、`-newer` / `-anewer` / `-cnewer` / `-newerXY` / `-used`、`-readable` / `-writable` / `-executable`、`-mindepth` / `-maxdepth` / `-depth` / `-prune`、`-print` / `-print0`。
- `-exec ... +` 在遍历中批量执行，UTF-8 参数字节与重复占位符计入 64 KiB payload 预算。

**最相关包（ls）**：`cli/ls` v0.2.4，发布 2026-10-27，`downloads=107`，`build_status=success`，7 个版本。

- 链接：https://mooncakes.io/docs/cli/ls
- README 覆盖：隐藏项选择、递归、排序、引用 / 转义、列布局、颜色；`-a` / `-A` / `-d` / `-R` / `-F` / `-1` / `-C` / `-x` / `-m` / `-r` / `-t` / `-S` / `-u` / `-c` / `--time` / `-H` / `-L` / `-P` / `-w` / `-T` / `-b` / `-N` / `-Q` / `--quoting-style`。

**同域其他包（coreutils 单命令集）**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| bobzhang/cat | 0.1.2 / 2026-09-28 | 60 | 字节透明的 cat，可经 moonx 运行 |
| bobzhang/head | 0.1.3 / 2026-09-28 | 65 | head |
| bobzhang/tail | 0.1.3 / 2026-09-28 | 77 | tail |
| bobzhang/sort | 0.1.2 / 2026-09-28 | 69 | sort |
| bobzhang/wc | 0.1.3 / 2026-09-28 | 68 | wc |
| bobzhang/nl / uniq / cut / tr / join / comm / paste / base64 / xxd / printf / sleep / true / false | 0.1.x / 2026-08-25–09-28 | 39–69 | 其余经典文本 / 文件命令，共约 19 个 |
| five-nuts/coreutils | 0.1.3 / 2024-11-16 | 44 | 名为 coreutils，但无 README、无描述、`build_status` 为空，3 个版本，已近两年未更新 |
| cli/core | 0.9.1 / 2026-11-01 | 895 | MoonX 命令模块的共享 runtime core |

**检索词**：`coreutils`（20 条）、`cli`（50 条）、`find`（50 条）、`ls`（50 条）、`cat`、`shell`；中文「命令行」返回 0 条。

**判定说明**：`find` / `ls` 已有近 GNU 选项覆盖的实现，`cat` / `head` / `tail` / `sort` / `wc` 等 19 个命令各有独立包，且 `moonbit-community/cmd` 在 2026-11-05 仍在提交。功能重合成立。需要区分的是：现有实现是**逐选项对齐 GNU 行为的移植**，不是 `fd` / `bat` / `eza` 那种以现代 UX（彩色、git 集成、交互式 TUI、智能默认值）为核心的重写；「现代替代」的 UX 层未被单独覆盖。判 `已有成熟包`。

**依据 URL**：
- https://mooncakes.io/docs/cli/find
- https://mooncakes.io/docs/cli/ls
- https://mooncakes.io/docs/bobzhang/cat

---

### 17. HTTP Web 服务器（应用服务器 / 框架） —— 已有成熟包

**最相关包（应用框架）**：`moonbitlang/moonback` v0.8.10，发布 2026-10-30，`downloads=60393`，`build_status=success`，9 个版本，2 个依赖方。GitHub `moonbitlang/moonback` 最后 push 2026-11-04，7 stars。

- 链接：https://mooncakes.io/docs/moonbitlang/moonback
- 源码：https://github.com/moonbitlang/moonback

**README 声称的覆盖范围**：

- 基于 `moonbitlang/async` 的异步 Web 后端框架；路由层、可组合 `Module`、中间件、typed request / response helper、优雅关闭、module 级依赖注入。
- `GET` / `POST` / 任意方法注册；typed query / cookie；text / type-safe HTML / JSON / empty / WebSocket upgrade 响应；`ctx.on_close` 生命周期清理；app mount；typed config。
- 目标平台 native。

**最相关包（ASGI 服务器）**：`moonbitstack/mooncat` v0.19.5，发布 2026-11-05，`downloads=958`，`build_status=success`，30 个版本，1 个依赖方。GitHub `moonbitstack/mooncat` 最后 push 2026-11-05。

- 链接：https://mooncakes.io/docs/moonbitstack/mooncat
- README 覆盖：ASGI 3.0 服务器；单个端口上同时支持 HTTP/1.1、HTTP/2、HTTP/3、WebSocket、TLS；应用是 `(scope, receive, send)` 函数；与 `moonasgi` 接口配套。

**同域其他包**：

| 包 | 版本 / 更新 | downloads | 覆盖 |
|---|---|---|---|
| bobzhang/crescent | 0.11.2 / 2026-10-30 | 670 | Crescent Web 框架，25 个版本 |
| oboard/mocket | 0.10.2 / 2026-10-16 | 3239 | MoonBit Web 框架，67 个版本 |
| moonbitstack/moonapi | 0.17.9 / 2026-11-05 | 610 | typed Web 框架，22 个版本 |
| moonbitstack/moonasgi | 0.10.6 / 2026-11-04 | 1837 | ASGI 3.0 接口层，服务器 ↔ 框架的 SEAM |
| jaredzhou/pony | 0.5.0 / 2026-10-02 | 136 | Chi 风格轻量 HTTP 框架 + router |
| kupas/express | 0.4.0 / 2026-10-28 | 59 | Express 兼容框架，uWebSockets 绑定 |
| wflixu/Halo | 0.6.0 / 2026-05-01 | 55 | Koa 风格洋葱模型中间件框架 |
| daqing/moonway | 0.11.9 / 2026-10-22 | 92 | 全栈 Web 框架 |
| RabitLogic/mbit | 0.3.0 / 2026-08-01 | 71 | Gin 风格框架 |
| Lfan-ke/moonzero | 0.7.3 / 2026-09-13 | 108 | go-zero 风格服务框架（yanked） |

**检索词**：`http server`（50 条）、`web server`（50 条）、`http`、`server`、`framework`、`web`；中文「Web服务器」「应用服务器」各返回 0 条。

**判定说明**：应用框架（moonback / crescent / mocket / moonapi / pony / express / Halo / moonway / mbit）与服务器（mooncat，HTTP/1.1 + HTTP/2 + HTTP/3 + WebSocket + TLS）都已存在，moonback 下载 60,393、mooncat 30 个版本且当天仍在发布。反向代理由前一轮的 `moonproxy` 单独占位，本项只查应用服务器 / 框架，结论同样是已有成熟包。判 `已有成熟包`。

**依据 URL**：
- https://mooncakes.io/docs/moonbitlang/moonback
- https://mooncakes.io/docs/moonbitstack/mooncat

## 3. 方法论与局限

### 3.1 检索方法

1. **搜索 API**：`GET https://mooncakes.io/api/v0/search?kw=<关键词>&limit=50`。每个方向至少 2 个英文关键词；可中文化的关键词（反向代理、事件总线、规则引擎、大数据、流处理、命令行、Web 服务器等）中英双跑。
2. **模块详情**：`GET https://mooncakes.io/api/v0/modules/<owner>/<name>`，取 `latest_version`、`build_status`、`metadata.created_at`（最新版本发布时间）、`metadata.repository`、`versions` 数量、`dependents` 数量。
3. **README 正文**：搜索与详情 API 的 `metadata.readme_content` 为空；从 `https://mooncakes.io/docs/<owner>/<name>` 页面内嵌的 `__rabbita_transcript` 找到 `https://assets.mooncakes.io/assets/<module>@<version>/resource.json`，取 `readme_content`。本次实际直接按 `<owner>/<name>@<version>` 构造该 URL，命中率 100%。
4. **新包扫描**：`GET https://mooncakes.io/api/v0/modules?recent=60&new=60&popular=60`，用于捕捉搜索关键词漏掉的新包（据此发现 `Ag108/MoonEventTime`、`moonbitstack/moonp8s` 等）。
5. **GitHub 交叉验证**：`gh api repos/<owner>/<repo>`（经代理），只用于核对 `pushed_at`、stars、archived 状态。共核对 20 个仓库。
6. **导航式补查**：对每个方向补充同义词与上下位词（如 layout → dagre / elk / graphviz / diagram；interpreter → vm / runtime / scheme / prolog / starlark；k8s → crd / controller / kube）。

### 3.2 判定口径的具体应用

- `已有成熟包`：README 明示的能力与方向描述高度重合，且 `metadata.created_at` 落在 2026 年。**不要求** stars / 下载量达到某个阈值；低下载、少版本以 `*` 标注。
- `部分重叠`：功能方向一致但覆盖明显不足（如只有 parser 没有 renderer、只有单机没有分布式、只有 async 没有 reactive），或最后发布已明显停更（`allain/mongodb` 停在 2026-01-29 且 `build_status=legacy`）。
- `空白`：所有检索词组合均未返回相关包，且有旁证（如 `kubemoon` README 明确把 Wasm Operator Host 列为未实现）。
- 「维护强度偏弱」的标注不等于「不可用」：`moonquic`（15 版本 / 1152 下载）与 `hongweifei/lua`（1 版本 / 29 下载）都判 `已有成熟包`，但后者带 `*`。

### 3.3 局限

1. **搜索不是全文索引**：只匹配包名、`keywords`、自动摘要。README 正文中的能力词不参与匹配。一个包即使实现了某方向，只要名称 / 关键词不含该词，就可能漏检。缓解手段是同义词扩展 + 新包扫描，但不能保证零漏检。
2. **`limit=50` 有效，`page` / `offset` 无效**：单关键词最多返回 50 条且不能翻页。对 `sql`、`layout`、`operator`、`controller`、`pipeline` 这类高频词，第 50 条之后的命中不可见。本次对每个方向使用了多个更窄的关键词来降低影响。
3. **中文关键词系统性返回 0 条**：本轮实际跑了 20 个中文关键词——`规则引擎`、`大数据`、`流处理`、`查询引擎`、`消息队列`、`回调`、`布局`、`力导向`、`容器编排`、`控制器`、`命令行`、`Web服务器`、`排版`、`数学公式`、`解释器`、`数据库驱动`、`响应式`、`卡夫卡`、`分布式SQL`、`应用服务器`——**全部返回 `[]`（0 条）**。前一轮的 `反向代理`、`列式内存` 同样为 0。这说明搜索 API 未对中文 token 建立索引，而不是「命中不稳定」。因此所有结论只依据英文关键词；各条目中的「中文『X』返回 0 条」是实测结果，不是推测。
4. **`downloads` 是注册表聚合值**：不等于独立用户数，也不按版本拆分；新包的下载量天然偏低。跨包比较只能作量级参考。
5. **`created_at` 是最新版本发布时间**，不是 commit 时间；GitHub `pushed_at` 可能更晚（如 `hooklab` 注册表 2026-09-28，GitHub push 2026-11-03）。
6. **`build_status` 的 `legacy`** 表示该包未用当前工具链构建 / 未通过当前 CI，不等于源码不可用；`five-nuts/coreutils` 的 `build_status` 为空，表示没有构建记录。
7. **README 是自我声明**：本报告只核对「README / API 声称的覆盖范围」，未 clone 仓库、未运行测试、未做协议一致性验证。声称与实现可能不一致。
8. **GitHub 404 不能反证包不存在**：module 名与仓库名可能不同（如 `shunge/arrow` → `buildliming/MoonArrow`）；部分包的 `repository` 字段是占位名（`zzy12346/12312`、`xvyve123/2131`、`shaoaiwan/1234`、`Zcxssxx/Zcxproject22`），这类字段只能说明作者未维护规范仓库，不能说明代码不存在。
9. **注册表每日变化**：本报告是 2026-11-06 的快照。`new` / `recent` 列表中 2026-11-05 仍有新包发布，结论有时效性。
10. **未做「包与包之间」的依赖闭包分析**：一个方向可能由多个包组合覆盖（如 QUIC = moonquic + moonnet + moonhttp），本报告按「单包功能 + 同域包集合」判断，未验证组合后的端到端可用性。

### 3.4 数据快照摘要（本报告引用到的量级）

| 指标 | 值 |
|---|---|
| 判定单元 | 19（17 个方向，其中「解释器 / 运行时」拆 3 项） |
| `已有成熟包` | 12 |
| `部分重叠` | 5 |
| `空白` | 2 |
| 引用到的 registry 包（去重） | 60+ |
| 核对过的 GitHub 仓库 | 20 |
| 带 `*`（弱维护）的判定 | 6 |

> 计数口径：`已有成熟包` 含带 `*` 的 6 项（3、4、7、8、12、14b）；`部分重叠` 为 9、10、11、14a、15 共 5 项；`空白` 为 13、14c 共 2 项。
