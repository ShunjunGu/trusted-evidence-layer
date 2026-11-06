# MoonBit 三候选方向 mooncakes.io 查重报告

- 报告日期：2026-11-06
- 检索对象：mooncakes.io 注册表 API v0（一手证据）；GitHub API 仅用于维护强度交叉核对
- 判定口径：
  - **已有成熟包**：功能高度重合，且 2026 年有发布/更新
  - **部分重叠**：有相关包，但覆盖不足或已停更
  - **空白**：未检索到相关包
- 维护强度偏弱的包（单版本 / 低下载 / 长期未更新）在表中以 `⚠` 单独标注
- 表中“最近更新”指**最新版本的发布时间**（注册表 `metadata.created_at`），不是模块首次创建时间；已用版本数与 GitHub 仓库创建时间交叉验证

---

## 1. 汇总表

### 1.1 优先判定：RAG 检索组件与 prompt-injection 护栏

**明确结论（先给判定）：**

1. **RAG 检索组件不是空白，主干已被覆盖。** 文本切分、BM25、向量检索、RRF 混合检索、上下文组装、RAG 评测均有可用的 MoonBit 包；其中 `niuniu513-ask/MoonRetrieve` 是覆盖最完整的一站式实现。
2. **RAG 的细分能力存在三个明确空白：重排（rerank）、证据信任评分（trust score）、多文档冲突检测（conflict detection）。** 未检索到任何专门实现；`MoonRetrieve` 只有 RRF 融合，不是重排模型；`MoonRAGBench` 只提供重排迭代的评测指标，不提供重排器。
3. **Prompt-injection 检测与 LLM 内容护栏是空白；存在相邻的“LLM 动作 / 工具护栏”。** `prompt injection` 的 16 条命中全部是间接提及（Agent 框架、CLI、模板引擎、JSON Schema 校验等），没有一条实现检测或拦截；`jailbreak` 0 命中；`guardrail` 8 条命中均为 A/B 测试护栏或规则引擎，与 LLM 内容护栏无关；`moderation` 8 条命中未发现内容审核实现。相邻实现有 `lqyq666/bodymate` 的 `agent` 子包（把不可信 LLM 提议收敛为 allowlist 命令/查询，丢弃未声明 id、字段和非有限数值）与 `zhangbowen2006/moongate`（MCP 工具双点策略执行）——这是动作/工具策略层，不是 prompt-injection 检测，也不是内容审核。
4. **其他相邻能力存在，但不能替代上述空白：** PII/敏感数据脱敏有 `moon_scrub`、`moonbit-deid`；工具参数校验有 `colmugx/mcp` 的 JSON Schema 校验；执行隔离有 `mizchi/sandbox`。这些都不是 prompt-injection 检测。

| 子项 | 判定 | 最相关包 | 版本 / 最近更新 | 下载 / build | 覆盖说明 |
|---|---|---|---|---|---|
| 文本切分 | 已有成熟包 | niuniu513-ask/MoonRetrieve（Chunker）；weopqrst/agent（RecursiveCharacterTextSplitter） | 0.6.0 / 2026-09-24；0.5.1 / 2026-08-19 | 81 / success；95 / success | 段落切分、块间重叠、超长硬切；LangChain 式递归字符切分 |
| BM25 / 全文检索 | 已有成熟包 | MoonRetrieve；Lucius646/MoonSearch；NaIWaniubi/moonseek；btlqql/moon_findcore | 0.6.0 / 2026-09-24；0.9.0 / 2026-08-24；0.3.0 / 2026-11-04；0.3.0 / 2026-10-18 | 81 / success；49 / success；16 / success；42 / success | BM25（可配 k1/b）、倒排索引、中英文分词、短语/布尔/前缀查询 |
| 向量检索 / ANN | 已有成熟包 | trkbt10/vcdb；yiwnagmolu/moonhnsw；ywz1314/vector；Milvus/Chroma 客户端 | 0.3.2 / 2026-07-20；0.12.4 / 2026-10-30；0.1.3 / 2026-08-16；0.1.3 / 2026-10-31；0.1.1 / 2026-10-31 | 682 / success；38 / success；53 / success；58 / success；48 / success | 多 ANN 算法、HNSW、余弦/内积/L2、外部向量库 REST 客户端；Qdrant 客户端之一 `moon-qdrant` build failed |
| 重排 rerank | **空白** | 无专门包 | — | — | 仅有 RRF 融合（MoonRetrieve）与重排评测（MoonRAGBench），无 cross-encoder / LLM reranker |
| 证据溯源 | 部分重叠 | MoonRetrieve（ContextBuilder）；FidollarinLA/retrace；icyaaaww/moonatlas | 0.6.0 / 2026-09-24；0.2.0 / 2026-09-20；0.1.0 / 2026-10-15 | 81 / success；41 / success；29 / success | 来源编号、去重、引用清单；行级证据与 AI 数值断言复核；多文档来源证据。无 RAG 回答的 claim-level 引用核验器 |
| 信任评分 trust score | **空白** | 无 | — | — | `trust score` 12 条命中均为供应链安全、凭证、交易文档等非 RAG 域 |
| RAG 评测 | 已有成熟包 | q0w1ertyuiop/moonrag-bench；MoonRetrieve 内置评测 | 0.2.1 / 2026-08-24；0.6.0 / 2026-09-24 | 36 / success；81 / success | Recall/Precision/F1/MRR/MAP/nDCG/BPref/ERR/RBP 等；qrels、候选池、负采样、报告导出 |
| 端到端 RAG 管线 | 已有成熟包 | MoonRetrieve；houjie/rag-mbt（build failed） | 0.6.0 / 2026-09-24；0.1.1 / 2026-08-06 | 81 / success；31 / **failed** | 分词→切分→索引→检索→RRF→上下文组装；rag-mbt 注册表构建失败 |
| Prompt-injection 检测 | **空白** | 无 | — | — | 16 条命中均为间接提及；jailbreak 0 命中；无检测/拦截实现 |
| LLM 动作 / 工具护栏 | 部分重叠 | lqyq666/bodymate（agent 子包）；zhangbowen2006/moongate | 0.4.0 / 2026-09-16；0.7.1 / 2026-10-23 | 45 / success；62 / success | bodymate：把不可信 LLM 提议收敛为 allowlist 命令/查询；moongate：MCP 工具双点策略执行与 secret stand-ins；均不检测 prompt injection |
| LLM 内容护栏 / 审核 | **空白** | 无 | — | — | guardrail 命中为 A/B 测试/规则引擎；moderation 命中无内容审核实现 |
| PII 脱敏（相邻） | 已有成熟包 | 123123213weqw/moon_scrub；ljlljl678/moonbit-deid | 0.5.2 / 2026-10-01；0.1.2 / 2026-08-24 | 272 / success；50 / success | 敏感数据检测与脱敏、JSON/流式管线；中英文临床 PHI 检测、替换、审计 |

### 1.2 方向 A：科学 / 二进制数据格式库

| 子方向 | 判定 | 最相关包 | 版本 / 最近更新 | 下载 / build | 链接 |
|---|---|---|---|---|---|
| FITS | 已有成熟包（⚠ 单版本、低下载） | cosettese/moonastrofits | 0.1.0 / 2026-09-30 | 28 / success | [docs](https://mooncakes.io/docs/cosettese/moonastrofits) |
| HDF5 | 已有成熟包（⚠ 两个实现均为单版本） | Zz04321/moon-hdf5；JSJ222/moonh5 | 0.1.0 / 2026-11-04；0.1.0 / 2026-11-01 | 12 / success；18 / success | [moon-hdf5](https://mooncakes.io/docs/Zz04321/moon-hdf5) · [moonh5](https://mooncakes.io/docs/JSJ222/moonh5) |
| NetCDF | 部分重叠 | hrwqe/cf_ocean | 0.1.4 / 2026-08-24 | 53 / success | [docs](https://mooncakes.io/docs/hrwqe/cf_ocean) |
| MAT-file | 已有成熟包 | WeiR-h/moonmatbridge | 0.1.11 / 2026-10-31 | 180 / success | [docs](https://mooncakes.io/docs/WeiR-h/moonmatbridge) |
| Zarr | 已有成熟包 | zlhahaha/zarr | 0.7.0 / 2026-09-30 | 72 / success | [docs](https://mooncakes.io/docs/zlhahaha/zarr) |
| NPY | 已有成熟包 | ShunjunGu/moon-npy；WeiR-h/moonmatbridge | 0.4.0 / 2026-09-29；0.1.11 / 2026-10-31 | 40 / success；180 / success | [moon-npy](https://mooncakes.io/docs/ShunjunGu/moon-npy) · [moonmatbridge](https://mooncakes.io/docs/WeiR-h/moonmatbridge) |
| NPZ（压缩） | 部分重叠 | ShunjunGu/moon-npy（仅未压缩） | 0.4.0 / 2026-09-29 | 40 / success | [docs](https://mooncakes.io/docs/ShunjunGu/moon-npy) |
| Parquet | 已有成熟包 | mizchi/parquet；superbigcup325/colenc | 0.2.2 / 2026-09-24；0.1.3 / 2026-10-26 | 2324 / success；1322 / success | [parquet](https://mooncakes.io/docs/mizchi/parquet) · [colenc](https://mooncakes.io/docs/superbigcup325/colenc) |
| 科学数据通用 | 已有成熟包 | 上述 FITS/HDF5/NetCDF/MAT/Zarr 组合 | — | — | — |
| 二进制格式通用 | 已有成熟包 | moonbitstack/moonfory；prowk/binschema；Yu-zh/data | 0.1.3 / 2026-11-05；0.3.1 / 2026-09-30；0.2.1 / 2026-10-20 | 47 / success；37 / success；140 / success | [moonfory](https://mooncakes.io/docs/moonbitstack/moonfory) · [binschema](https://mooncakes.io/docs/prowk/binschema) · [data](https://mooncakes.io/docs/Yu-zh/data) |
| 相邻：Arrow IPC | 已有成熟包 | shunge/arrow | 0.2.1 / 2026-09-30 | 90 / success | [docs](https://mooncakes.io/docs/shunge/arrow) |
| 相邻：Avro | 已有成熟包 | yugonlian/moon-avro | 0.3.0 / 2026-08-22 | 265 / success | [docs](https://mooncakes.io/docs/yugonlian/moon-avro) |
| 相邻：ORC | 部分重叠（⚠ 单版本、读取向） | oyjh0381/moonorc | 0.1.0 / 2026-11-01 | 18 / success | [docs](https://mooncakes.io/docs/oyjh0381/moonorc) |
| 相邻：NIfTI-1 | 部分重叠（⚠ 单版本） | wangjiale6036-dotcom/moonnifti | 0.2.0 / 2026-09-24 | 48 / success | [docs](https://mooncakes.io/docs/wangjiale6036-dotcom/moonnifti) |

### 1.3 方向 B：AI 应用 / 模型协议客户端

| 子方向 | 判定 | 最相关包 | 版本 / 最近更新 | 下载 / build | 链接 |
|---|---|---|---|---|---|
| MCP SDK（服务端 + 客户端 + 传输） | 已有成熟包 | colmugx/mcp | 0.18.2 / 2026-10-23 | 9890 / success | [docs](https://mooncakes.io/docs/colmugx/mcp) |
| MCP 协议类型 / JSON-RPC 编解码 | 已有成熟包 | marianoguerra/mcp（+ mcp-client / mcp-server / mcp-server-native） | 0.10.1 / 2026-10-19 | 367 / success（client 223、server 203） | [docs](https://mooncakes.io/docs/marianoguerra/mcp) |
| MCP 第二/第三实现 | 已有成熟包 | moonbitstack/moonmcp；shiguri-01/mcp | 0.1.10 / 2026-11-05；0.2.0 / 2026-08-20 | 151 / success；121 / success | [moonmcp](https://mooncakes.io/docs/moonbitstack/moonmcp) · [shiguri](https://mooncakes.io/docs/shiguri-01/mcp) |
| MCP 早期实现 | 部分重叠（⚠ 单版本、已 6 个月未更新） | cogna-dev/mcp-sdk | 0.1.0 / 2026-04-16 | 84 / success | [docs](https://mooncakes.io/docs/cogna-dev/mcp-sdk) |
| JSON-RPC 基础设施 | 已有成熟包 | moonbitstack/moonjrpc | 0.1.3 / 2026-11-05 | 48 / success | [docs](https://mooncakes.io/docs/moonbitstack/moonjrpc) |
| LLM API 客户端（OpenAI 兼容 / 多 provider） | 已有成熟包 | mizchi/llm；gaato/openai；DC-Z-lab/moonllm；marianoguerra/llm | 0.3.2 / 2026-08-15；0.6.0 / 2026-10-19；0.1.0 / 2026-07-07；0.4.2 / 2026-10-19 | 153802 / success；169 / success；504 / success；487 / success | [mizchi/llm](https://mooncakes.io/docs/mizchi/llm) · [openai](https://mooncakes.io/docs/gaato/openai) · [moonllm](https://mooncakes.io/docs/DC-Z-lab/moonllm) · [llm](https://mooncakes.io/docs/marianoguerra/llm) |
| Anthropic Messages 客户端 | 已有成熟包 | gaato/anthropic | 0.12.0 / 2026-10-20 | 114 / success | [docs](https://mooncakes.io/docs/gaato/anthropic) |
| Agent 框架 | 已有成熟包 | colmugx/posoco；moonbitstack/moonkoog；weopqrst/agent | 0.24.1 / 2026-11-05；0.6.1 / 2026-09-22；0.5.1 / 2026-08-19 | 4472 / success；68 / success；95 / success | [posoco](https://mooncakes.io/docs/colmugx/posoco) · [moonkoog](https://mooncakes.io/docs/moonbitstack/moonkoog) · [agent](https://mooncakes.io/docs/weopqrst/agent) |
| Tool calling | 已有成熟包 | mizchi/llm；gaato/openai；moonbitstack/moonmcp | 同上 | 同上 | 同上 |
| Embedding | 部分重叠 | wskwsk68/MoonEmbed；gaato/openai（embeddings API）；majikxu/laya（本地编码器推理） | 0.1.6 / 2026-08-16；0.6.0 / 2026-10-19；0.1.0 / 2026-09-22 | 53 / success；169 / success；26 / success | [MoonEmbed](https://mooncakes.io/docs/wskwsk68/MoonEmbed) · [openai](https://mooncakes.io/docs/gaato/openai) · [laya](https://mooncakes.io/docs/majikxu/laya) |
| RAG 组件（切分/BM25/向量/融合/评测） | 已有成熟包 | niuniu513-ask/MoonRetrieve 等 | 见 1.1 | 见 1.1 | [docs](https://mooncakes.io/docs/niuniu513-ask/MoonRetrieve) |
| RAG 重排 / 信任评分 / 冲突检测 | **空白** | 无 | — | — | — |
| Prompt-injection 检测 | **空白** | 无 | — | — | — |
| LLM 动作 / 工具护栏 | 部分重叠 | lqyq666/bodymate（agent 子包）；zhangbowen2006/moongate | 0.4.0 / 2026-09-16；0.7.1 / 2026-10-23 | 45 / success；62 / success | [bodymate](https://mooncakes.io/docs/lqyq666/bodymate) · [moongate](https://mooncakes.io/docs/zhangbowen2006/moongate) |
| LLM 内容护栏 / 审核 | **空白** | 无 | — | — | — |

### 1.4 方向 C：开发者工具（Markdown / CLI / 配置校验）

| 子方向 | 判定 | 最相关包 | 版本 / 最近更新 | 下载 / build | 链接 |
|---|---|---|---|---|---|
| Markdown 解析 / 渲染 | 已有成熟包 | mizchi/markdown | 0.8.4 / 2026-10-19 | 22093 / success | [docs](https://mooncakes.io/docs/mizchi/markdown) |
| YAML frontmatter | 部分重叠 | moonrockz/mdc；moonrockz/moonbase-mdc；JM-ai-n/moonfolio | 0.1.0 / 2026-10-25；0.0.1 / 2026-10-19；0.1.0 / 2026-08-22 | 83 / success；46 / success；30 / success | [mdc](https://mooncakes.io/docs/moonrockz/mdc) · [moonbase-mdc](https://mooncakes.io/docs/moonrockz/moonbase-mdc) · [moonfolio](https://mooncakes.io/docs/JM-ai-n/moonfolio) |
| YAML | 已有成熟包 | moonbit-community/yaml；moonbitstack/moonyaml | 0.0.8 / 2026-10-18；0.1.4 / 2026-11-03 | 115649 / success；2369 / success | [yaml](https://mooncakes.io/docs/moonbit-community/yaml) · [moonyaml](https://mooncakes.io/docs/moonbitstack/moonyaml) |
| TOML | 已有成熟包 | bobzhang/toml；moonbit-community/toml；moonbitstack/moontoml | 0.4.3 / 2026-08-16；0.5.1 / 2026-11-02；0.1.1 / 2026-11-03 | 129401 / success；48146 / success；792 / success | [toml](https://mooncakes.io/docs/bobzhang/toml) · [community/toml](https://mooncakes.io/docs/moonbit-community/toml) · [moontoml](https://mooncakes.io/docs/moonbitstack/moontoml) |
| CLI 框架 / 参数解析 | 已有成熟包 | moonbitlang/core/argparse（标准库）；mizchi/admiral；hustcer/cmder；Yoorkin/ArgParser | 随 core 0.1.20261105+65efd5b93 / 2026-11-05；0.1.1 / 2026-08-15；0.6.1 / 2026-11-05；0.2.1 / 2026-02-11 ⚠ legacy | 1701（core）/ success；18310 / success；214 / success；107805 / legacy | [argparse](https://github.com/moonbitlang/core/tree/main/argparse) · [admiral](https://mooncakes.io/docs/mizchi/admiral) · [cmder](https://mooncakes.io/docs/hustcer/cmder) · [ArgParser](https://mooncakes.io/docs/Yoorkin/ArgParser) |
| 配置加载 / 分层 / 校验 | 已有成熟包 | moonbitlang/moon_config；moonbitstack/moonconf；MuVirus/moonfig | 0.4.5 / 2026-10-22；0.1.3 / 2026-11-05；0.1.8 / 2026-10-31 | 135172 / success；47 / success；125 / success | [moon_config](https://mooncakes.io/docs/moonbitlang/moon_config) · [moonconf](https://mooncakes.io/docs/moonbitstack/moonconf) · [moonfig](https://mooncakes.io/docs/MuVirus/moonfig) |
| Markdown lint | **空白** | 无 | — | — | — |
| MDX 编译 | **空白** | 无 | — | — | — |
| 独立 frontmatter CLI（mdmeta 类） | **空白** | 无（仅库 mdc） | — | — | — |

### 1.5 真正的空白子项总表

| 方向 | 空白子项 | 证据摘要 |
|---|---|---|
| A 科学 / 二进制格式 | NetCDF-4（HDF5 容器） | 检索到的唯一 NetCDF 包 `cf_ocean` 明确写 "NetCDF-4/HDF5 containers are not implemented"，只支持 Classic CDF-1 / 64-bit Offset CDF-2 |
| A | HDF5 原地修改 / 追加写 | `moonh5` 与 `moon-hdf5` 均只支持新建文件写出；`moon-hdf5` 明确 "In-place editing of an existing file is not supported" |
| A | 压缩 NPZ（zip/deflate） | `moon-npy` 明确只支持未压缩 NPZ，压缩成员直接报 `NpzCompressedMember`；无其他包声称支持压缩 NPZ |
| A | Zarr v3 分片写入 / 云写入 | `zlhahaha/zarr` 的分片只读、HTTP/S3 只读；"sharded writes remain unsupported"、"cloud writes ... outside the supported subset" |
| A | Parquet 嵌套 / 复杂 schema 写入 | `mizchi/parquet` 写出仅支持 flat schema、Int32/Int64/String/Binary、Required/Optional |
| B | RAG 重排（rerank） | `rerank` 3 条、`reranking` 34 条命中均无专门重排器；MoonRetrieve 仅 RRF 融合 |
| B | RAG 证据信任评分 | `trust score` 12 条命中均为供应链/凭证/交易等非 RAG 域 |
| B | 多文档冲突检测 | `conflict detection` 30 条命中为铁路时刻表、CRDT、记录链接等，无 RAG claim 冲突检测 |
| B | Prompt-injection / jailbreak 检测 | `prompt injection` 16 条均为间接提及；`jailbreak` 0 命中 |
| B | LLM 内容护栏 / 内容审核 | `guardrail` 8 条为 A/B 测试或规则引擎；`moderation` 8 条无内容审核实现；`bodymate/agent` 与 `moongate` 是动作/工具策略护栏，不是内容护栏 |
| C | Markdown lint | `lint` 50 条命中含 Modbus、Dockerfile、actionlint、ShellCheck、结构搜索，无 Markdown linter |
| C | MDX 编译 | `mdx` 仅 2 条命中（mizchi/markdown、mizchi/syntree），无 MDX 编译器 |
| C | 独立 frontmatter CLI（mdmeta 类） | `mdmeta` 0 命中；frontmatter 解析仅作为库存在于 `mdc` / `moonbase-mdc` |

---

## 2. 逐条详述（检索词 + 证据）

### 2.1 优先项：RAG 检索组件与安全护栏

#### 2.1.1 检索记录

| 检索词 | 命中数 | 有效相关命中 |
|---|---:|---|
| `bm25` | 6 | MoonRetrieve、MoonSearch、moonseek、moon_findcore（moomem 描述为空，未核实其 BM25 实现） |
| `tf-idf` | 2 | moonnlp（NLP 库，描述提及 TF-IDF） |
| `retrieval` | 50 | MoonRetrieve、MoonEmbed、moonrag-bench、weopqrst/agent |
| `retriever` | 50 | 同上 |
| `chunking` | 14 | MoonRetrieve（Chunker）、weopqrst/agent（RecursiveCharacterTextSplitter）；其余为内容定义分块（备份/去重） |
| `text splitter` | 4 | weopqrst/agent（明确列出 RecursiveCharacterTextSplitter） |
| `rerank` | 3 | 无专门包；仅 promptkit、moonai、moonrag-bench 的描述提及 |
| `reranking` | 34 | 同上，无专门重排器 |
| `vector search` | 36 | vcdb、moonhnsw、vector、Qdrant/Milvus/Chroma 客户端、sqlite-vec |
| `semantic search` | 23 | MoonEmbed、moon_vector、vector |
| `knowledge base` | 10 | MoonAtlas、moonrockz/okf、NoteQL |
| `provenance` | 38 | retrace、moonatlas、medseal、moonflowgraph、bids_metadata_trace |
| `trust score` | 12 | 无 RAG 相关；moon_guard（供应链）、mooncred（凭证）等 |
| `conflict detection` | 30 | 无 RAG 相关；铁路时刻表、CRDT、record linkage |
| `prompt injection` | 16 | 无检测实现；均为 Agent/CLI/模板/校验库的间接提及 |
| `guardrail` | 8 | 无 LLM 护栏；moon-experiment（A/B 测试护栏）、moonup（规则引擎）等 |
| `rag evaluation` | 3 | moonrag-bench、MoonRetrieve、moonkoog |
| `jailbreak` | 0 | — |
| `injection` | 50 | SQL 注入防护（moonorm、sqlguard）、故障注入（moonlab），无 prompt-injection |
| `moderation` | 8 | 无内容审核实现 |
| `prompt safety` | 4 | 无专门包 |
| `llm guard` | 3 | bodymate（LLM 动作 / 工具护栏）；moonspace、npm_typed 为无关匹配 |
| `pii` | 5 | moon_scrub、moonbit-deid（脱敏，非注入防护） |

#### 2.1.2 文本切分

**`niuniu513-ask/MoonRetrieve` 0.6.0**
- 最新版本：2026-09-24；下载 81；build_status `success`；Apache-2.0；9 个版本；依赖 1 个
- 链接：https://mooncakes.io/docs/niuniu513-ask/MoonRetrieve
- README 声称：`Tokenizer`（中/英/日、N-gram、停用词、词干化）、`Chunker`（按段落切分、块间重叠、超长段落硬切）、BM25 倒排索引、短语/布尔/前缀检索、`VectorIndex` 余弦检索、`rrf_fuse` RRF 融合、`ContextBuilder`（来源去重、分块预算、带引用清单的 `ContextReport`）、文档级评测（Precision/Recall/MRR/MAP）、JSONL 导入、`Engine::trace`、highlight、remove/stats、一站式 `Engine`、CLI（index/query/context/evaluate/trace/stats/phrase/boolean/prefix）
- 维护强度：GitHub `niuniu513-ask/MoonRetrieve` 1 star，2026-08-12 创建，2026-09-24 最后 push；9 个版本，更新集中在 2026-08/09

**`weopqrst/agent` 0.5.1**
- 最新版本：2026-08-19；下载 95；build_status `success`；Apache-2.0；8 个版本；依赖 1 个
- 链接：https://mooncakes.io/docs/weopqrst/agent
- README 声称：LangChain 核心抽象移植；RAG 模块包含 `Document`、`MarkdownLoader`、`RecursiveCharacterTextSplitter`、`VectorStore`、`Embedder`、`Retriever`、MMR 多样性检索、`RetrievalTool`
- 维护强度：GitHub `mihujiang/MoonBit` 1 star，2026-07-25 创建，2026-08-24 最后 push

**判定：已有成熟包。** 切分能力至少有两套独立实现，且都集成在可运行的 RAG/Agent 管线中。

#### 2.1.3 BM25 / 全文检索

**`niuniu513-ask/MoonRetrieve` 0.6.0**：BM25 倒排索引，支持增量建索引、Top-K、短语、布尔（AND/OR/-term）、前缀；README 给出 2,000 文档基准与 SciFact 300 题评测（Recall@10 0.7533、MRR@10 0.5847）。

**`Lucius646/MoonSearch` 0.9.0**
- 最新版本：2026-08-24；下载 49；build_status `success`；3 个版本
- 链接：https://mooncakes.io/docs/Lucius646/MoonSearch
- README 声称：Tantivy/Lucene 式倒排索引，schema-aware、可插拔文本分析、可选中文分析、BM25、不可变多 segment 存储、结果高亮、JSONL CLI、WasmGC demo；README 明确 "source metadata is currently at 0.9.0 and is still evolving"，并提示生产使用前阅读 Current limitations

**`NaIWaniubi/moonseek` 0.3.0**
- 最新版本：2026-11-04；下载 16；build_status `success`；3 个版本
- 链接：https://mooncakes.io/docs/NaIWaniubi/moonseek
- README 声称：倒排索引、BM25（可配 k1/b）、中英文分词、短语/AND/OR/NOT/field/prefix、模糊搜索（Levenshtein/Damerau + BK-tree）、did-you-mean、分面过滤、服务端高亮、分段索引 + WAL 崩溃恢复；native/WASM/JS

**`btlqql/moon_findcore` 0.3.0**
- 最新版本：2026-10-18；下载 42；build_status `success`；3 个版本
- 链接：https://mooncakes.io/docs/btlqql/moon_findcore
- 注册表描述：Persistent full-text indexing and ranked search

**判定：已有成熟包。** BM25 内核至少有 4 个独立实现，其中 MoonRetrieve 与 MoonSearch 的 README 给出了架构与评测细节。

#### 2.1.4 向量检索 / ANN

| 包 | 版本 / 更新 | 下载 / build | 注册表描述 / README 摘要 |
|---|---|---|---|
| trkbt10/vcdb | 0.3.2 / 2026-07-20 | 682 / success | High-performance vector database with multiple ANN algorithms；5 个版本 |
| yiwnagmolu/moonhnsw | 0.12.4 / 2026-10-30 | 38 / success | 纯 MoonBit HNSW 图索引，f32 向量，L2/内积/余弦，二进制保存/加载；5 个版本 |
| ywz1314/vector | 0.1.3 / 2026-08-16 | 53 / success | 零依赖向量相似度搜索与索引引擎 |
| lexchb/moon_vector | 0.1.1 / 2026-10-29 | 31 / success | Qdrant REST 客户端 + 内存后端 |
| yuzhiblue/moon-qdrant | 0.5.0 / 2026-10-13 | 95 / **failed** | Qdrant REST API 客户端；⚠ 11 个版本但最新版构建失败 |
| SundayT1998/chroma-client | 0.1.1 / 2026-10-31 | 48 / success | Chroma HTTP 客户端（collections/records/queries/embeddings） |
| SundayT1998/milvus-client | 0.1.3 / 2026-10-31 | 58 / success | Milvus 向量库客户端 |
| colmugx/sqlite-vec | 0.2.4 / 2026-05-19 | 119 / success | SQLite3 + sqlite-vec 扩展绑定 |

**判定：已有成熟包。** 纯 MoonBit ANN 与外部向量库客户端均已存在。

#### 2.1.5 重排（rerank）——空白

- `rerank` 检索仅 3 条命中：`co63oc/moonbit_promptkit`、`QuietlyChan/moonai`、`q0w1ertyuiop/moonrag-bench`。逐条核查 README：
  - `moonbit_promptkit` 0.1.7（81 下载）：README 未出现 rerank 相关实现，仅为 OpenAI 兼容 SDK 的描述性匹配
  - `moonai` 0.1.0（37 下载）：README 未出现 rerank 实现
  - `moonrag-bench` 0.2.1（36 下载）：README 明确其用途是 "evaluating retrieval systems and RAG candidate generation offline"，支持 "reranker iteration" 的评测，但**不提供重排器**
- `MoonRetrieve` 只有 `rrf_fuse`（Reciprocal Rank Fusion），属于多路结果融合，不是 query-document 重排模型，也没有 cross-encoder / LLM reranker。
- 未检索到任何包提供 `rerank(query, documents) -> scored_documents` 形式的 API。

**判定：空白。**

#### 2.1.6 证据溯源——部分重叠

**`niuniu513-ask/MoonRetrieve` 0.6.0**
- `ContextBuilder` 按 token 预算组装上下文，来源去重，输出带引用清单的 `ContextReport`；`Engine::trace` 输出排名、来源、分数、命中/缺失词和原始证据文本。
- 这是“检索结果 -> 提示词”的引用组装，不校验 LLM 回答中的每个 claim 是否被引用支持。

**`FidollarinLA/retrace` 0.2.0**
- 最新版本：2026-09-20；下载 41；build_status `success`；3 个版本；无第三方运行时依赖
- 链接：https://mooncakes.io/docs/FidollarinLA/retrace
- README 声称：CSV + 版本化分析计划生成确定性统计、**记录级证据（record-level evidence）**和可重放报告包；可选的 AI 生成数值断言会在使用前对照一次全新执行进行核验；README 明确 "does not certify data authenticity, causal conclusions or engineering compliance"
- 这是“数值 claim 对可复算数据”的核验，不是文档检索的证据溯源

**`icyaaaww/moonatlas` 0.1.0**
- 最新版本：2026-10-15；下载 29；build_status `success`；1 个版本
- 链接：https://mooncakes.io/docs/icyaaaww/moonatlas
- README 声称：本地多文档知识地图，带 source evidence；纯库、无文件系统/网络 I/O，宿主提供 UTF-8 Markdown/TXT 快照

**其他相关但非 RAG：** `001-Elsa/medseal` 0.6.0（136 下载，逐记录数据转换收据与 provenance）、`AlexenderSokolov/moonflowgraph` 0.3.0（78 下载，agent 工作流 provenance trace）、`cn-cheems/bids_metadata_trace` 0.1.0（BIDS 元数据继承与字段 provenance）。

**判定：部分重叠。** 有引用清单、行级证据、来源证据，但没有面向 RAG 回答的 claim-level 引用核验器。

#### 2.1.7 信任评分——空白

- `trust score` 12 条命中的注册表描述均不属于 RAG 域：`chenzehaoo/moon_guard`（供应链安全、Ed25519 签名）、`moonbitstack/mooncred`（JWT/JWK/X.509 凭证）、`zxwrrg/tradedocs`（贸易单据一致性）、`001-Elsa/medseal`（数据转换收据）等，均不是对检索证据或模型回答的可信度评分。
- `provenance` 命中中的 `starlittle/MoonEvidence` 0.5.1（83 下载）是 "Trusted evidence pack verification library and CLI"，属于证据包验证，不是检索证据可信度评分。
- 未检索到 `trust`、`credibility`、`confidence` 与 RAG/evidence 组合的包。

**判定：空白。**

#### 2.1.8 RAG 评测——已有成熟包

**`q0w1ertyuiop/moonrag-bench` 0.2.1**
- 最新版本：2026-08-24；下载 36；build_status `success`；2 个版本；依赖 1 个
- 链接：https://mooncakes.io/docs/q0w1ertyuiop/moonrag-bench
- README 声称：解析 qrels、retrieval runs、candidate pools（容错 TSV）；校验 ID、相关性、有限分数、重复、query 覆盖；计算 Recall/Precision/F1/R-precision/MRR/MAP/nDCG/BPref/ERR/RBP/fallout/judged coverage/graded-gain；baseline vs candidate 的 per-query wins/losses/ties、delta、overlap、rank movement；数据集画像、负采样；导出 text/Markdown/CSV/JSON/JSONL/HTML/TSV；native CLI；网络无关

**`MoonRetrieve`** 内置文档级检索评测（标注查询集、逐题排名、Precision/Recall/MRR/MAP 汇总），并提供 SciFact 复现说明。

**判定：已有成熟包。**

#### 2.1.9 端到端 RAG 管线

**`niuniu513-ask/MoonRetrieve` 0.6.0**：覆盖文档导入→分词→切分→BM25/向量索引→检索→RRF→ContextBuilder→LLM 提示词，且带 CLI 与评测；是当前最完整的一站式实现。

**`houjie/rag-mbt` 0.1.1**
- 最新版本：2026-08-06；下载 31；build_status **`failed`**；MIT；2 个版本
- 链接：https://mooncakes.io/docs/houjie/rag-mbt
- 注册表描述：MoonBit RAG Library - 2 阶段 6 模块完整封装
- README 资源返回 404；`MoonRetrieve` README 指其 native 侧依赖 Python/bge 嵌入与 FFI
- **注册表 build_status 为 failed，属于不可正常消费状态**

**判定：端到端管线已有成熟包（MoonRetrieve）；rag-mbt 为失败构建，不计入可用供给。**

#### 2.1.10 Prompt-injection 检测 / LLM 护栏——空白

**检索证据：**
- `prompt injection`：16 条命中。逐条核查注册表描述，命中者包括 `Lfan-ke/moonkoog`、`hnlyxiaobing/MBOpenClacky`、`uiwcvb/moonprompt`、`V1GreenSummer/watermark-toolkit`、`bobzhang/openseek`、`moonbitlang/openseek`、`f4ah6o/dsh`、`Betterlol/moon_zod`、`colmugx/posoco`、`mizchi/js_node` 等；没有一条注册表描述声称实现 prompt-injection 检测/拦截。
- `jailbreak`：0 条命中。
- `guardrail`：8 条命中。`pla678889/moon-experiment` 是 A/B 测试分析库的 statistical guardrails；`mw1696803-hub/moonup` 是 Rete 规则引擎的 conflict resolution；其余为无关匹配。
- `moderation`：8 条命中（moonllm、moonkoog、atproto、discord 等），无内容审核/毒性检测实现。
- `prompt safety`：4 条命中（openseek、moonfish、laya、npm_typed），无专门安全库。
- `llm guard`：3 条命中。`lqyq666/bodymate` 的 `agent` 子包是 LLM 动作 / 工具护栏；`thy1016/moonspace` 与 `mizchi/npm_typed` 为无关匹配。
- `injection`：50 条命中，主要是 SQL 注入防护（`Lfan-ke/moonorm`、`Rz-coder8848/moonorm`、`hutingyu-nuist/moonsqlguard`）和故障注入（`oyjh0381/moonlab`），与 prompt injection 无关。
- `adversarial`：4 条，无对抗 prompt 防护。
- `red team`：1 条（bobzhang/games 的无关匹配）。
- `toxicity`：0 条命中。

**相邻但不构成 prompt-injection 防护的能力：**
- `lqyq666/bodymate` 0.4.0（45 下载，success，4 个版本，2026-09-16）：`agent` 子包把不可信 LLM 提议收敛为 `None` / `Command` / `Lookup`，未声明的 id、字段、非有限数值一律丢弃；README 明确这是“LLM 输出的执行护栏”（动作白名单），不检测 prompt injection，也不做内容审核。GitHub `lqyq666/bodymate` 0 stars，2026-09-11 创建，2026-09-18 最后 push。
- `zhangbowen2006/moongate` 0.7.1（62 下载，success，8 个版本，2026-10-23）：MCP 工具的双点策略执行与 secret stand-ins；是工具调用策略层，不检测 prompt injection。
- `tuya-me/aegisrun` 0.9.3（76 下载，build **`failed`**，7 个版本，2026-07-17）：AI Agent Secure Tool Runtime（MoonBit + Wasm）；注册表构建失败，不计入可用供给。
- `123123213weqw/moon_scrub` 0.5.2（272 下载，success，5 个版本，2026-10-01）：离线敏感数据检测、脱敏、JSON/流式管线
- `ljlljl678/moonbit-deid` 0.1.2（50 下载，success，3 个版本，2026-08-24）：中英文临床文本 PHI 检测、替换、审计
- `colmugx/mcp` 0.18.2：工具输入/输出 JSON Schema 校验，在 handler 执行前拒绝非法参数
- `mizchi/sandbox` 0.1.3（53 下载，2026-10-05）：内存沙箱、虚拟文件系统、POSIX 模拟、shell
- 未在本次检索范围内发现专门的 LLM 输出 sanitizer

**判定：**
- **Prompt-injection 检测：空白。** 结论基于 4 组关键词（prompt injection / jailbreak / guardrail / moderation）与注册表 keywords 匹配；不能排除未发布到 mooncakes 的 GitHub 私有项目，但在注册表供给范围内没有可消费的检测包。
- **LLM 内容护栏 / 内容审核：空白。**
- **LLM 动作 / 工具调用护栏：部分重叠。** 有 `bodymate/agent`（动作 allowlist）与 `moongate`（MCP 工具策略执行）两个可用实现；`aegisrun` 构建失败。它们都不覆盖 prompt injection 或内容审核。

### 2.2 方向 A：科学 / 二进制数据格式库

#### A-1 FITS

**检索词**：`fits`（6 条命中）、`scientific data`（14 条）、`binary format`（50 条）

**`cosettese/moonastrofits` 0.1.0**
- 版本 / 最新版本发布：0.1.0 / 2026-09-30
- 下载：28
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 0 个依赖 / 1 个版本
- 链接：https://mooncakes.io/docs/cosettese/moonastrofits
- README 声称的覆盖范围：
  - 严格 80 字节 FITS card 解析；`= ` 值指示符、未定义值、注释、commentary cards；带引号字符串与注释分离；有序/重复 header keyword；`END` 检测与 2880 字节 header padding 校验；结构化错误；支持从字节 0 或指定绝对 offset 解析
  - primary 与 extension HDU 遍历；`SIMPLE`/`XTENSION`、`BITPIX`、`NAXIS`、`NAXISn` 顺序校验；图像几何与 2880 字节 data-unit padding；溢出/截断拒绝
  - 大端 8/16/32/64 位整数图像解码；`BSCALE`/`BZERO`/`BLANK` 物理值语义；IEEE binary32/binary64 解码；NaN/Inf/负零保留
  - 80 字节 card 与 2880 字节 header 编码；`parse → encode → parse` round trip；整数/浮点像素编码
  - primary HDU 组装；IMAGE 与通用 extension HDU 组装
  - `BINTABLE` 固定宽度 schema：`A`/`L`/`X`/`B`/`I`/`J`/`K`/`E`/`D` 列；typed row 解码/编码；三态 logical；MSB-first packed bit array；`P`/`Q` 变长数组 heap 解码/编码；完整 `BINTABLE` extension 构造
  - README 给出 Astropy 15 行参考对比、`fitscheck --compliance`、`fitsverify` 的验证命令
- 维护强度：**单版本**；GitHub `cosettese/MoonAstroFITS` 0 stars，2026-09-14 创建，2026-09-30 最后 push（截至 2026-11-06 已 5 周无更新）
- **判定：已有成熟包（⚠ 单版本、低下载）。** 功能覆盖异常完整（读、校验、写、BINTABLE），但注册表供给只有 1 个版本、28 次下载，维护证据弱。

#### A-2 HDF5

**检索词**：`hdf5`（2 条命中）、`hdf`（2 条）

**`Zz04321/moon-hdf5` 0.1.0**
- 版本 / 最新版本发布：0.1.0 / 2026-11-04
- 下载：12
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 2 个依赖 / 1 个版本
- 链接：https://mooncakes.io/docs/Zz04321/moon-hdf5
- README 声称的覆盖范围：
  - HDF5 1.14.6 common-file profile 的文档化子集；无原生 HDF5 依赖；wasm/native
  - `Hdf5File` 读取现有文件；`Hdf5Writer` 在内存创建完整新文件；`Hdf5Resolver` 跟随外部链接；**不支持原地编辑**
  - Superblock v0–v3、4/8 字节地址、compact/dense groups 与 attributes、hard/soft/external links、所有命名 hard-link 路径
  - Compact/contiguous/chunked datasets；v1 B-tree、single-chunk、implicit、fixed-array、extensible-array、v2 B-tree 索引
  - Deflate、shuffle、Fletcher32、整数 scale-offset、f32/f64 decimal scale-offset，含 per-chunk filter mask
  - 有/无符号 1–8 字节整数（两种字节序）、IEEE float16/32/64、normalized binary floats、字符串、compound、enum、array、time、bitfield、opaque、sequence、reference、complex
  - Hyperslab 与 ordered-point 读取、metadata-only 读取、有界内存 chunk 迭代、object-reference 解析、dataset-region-reference 读取
  - SOHM 读取与可选写入；新文件输出支持 groups/datasets/attributes/links/committed datatypes/filters/fills/references/contiguous external raw-data slots/一个或多个 unlimited 维度
- 维护强度：**单版本**；GitHub `zzSmall6/moon-hdf5` 4 stars，2026-10-19 创建，2026-11-04 最后 push（活跃，但仅有 1 次发布）

**`JSJ222/moonh5` 0.1.0**
- 版本 / 最新版本发布：0.1.0 / 2026-11-01
- 下载：18
- build_status：`success`
- 许可证 / 依赖 / 版本数：MIT / 2 个依赖 / 1 个版本
- 链接：https://mooncakes.io/docs/JSJ222/moonh5
- README 声称的覆盖范围（中文）：
  - 纯 MoonBit HDF5 数组读写，无需 `libhdf5`，支持 native/JS/Wasm/Wasm-GC
  - 明确边界：**不是完整 HDF5 实现**，不自动保证 MATLAB v7.3、NetCDF-4、Keras 等上层格式
  - 文件：superblock 0/1/2/3、标准 user block、2/4/8 字节地址/长度、v2/3 checksum；不支持 SWMR/活动写入、多文件驱动、superblock 扩展
  - 对象与组：v1/v2 object header 与 continuation block、旧符号表、compact links、hard link alias/环、soft link；不支持 dense groups/fractal heaps、external links、shared/committed types
  - 数组：scalar/simple/null/零长度维；contiguous/compact/旧 v1 B-tree chunked/现代未分页 fixed-array chunked；不支持 paged fixed-array、single/implicit/extensible/v2 B-tree 索引、VDS、resize
  - 类型：8/16/32/64 位整数、IEEE32/64、定长 ASCII/UTF-8、大小端；不支持 VLEN/compound/enum/reference/opaque/非标准浮点
  - 属性：内联 v1/v2/v3 定宽数组属性；不支持 dense/shared 属性
  - 过滤器：gzip（zlib 封装 DEFLATE）、shuffle、Fletcher32、per-block filter mask；不支持 LZF/SZIP/插件/scale-offset
  - 写出：新建确定性 superblock2/object-header2、compact groups、连续/紧凑定宽数组、属性、hard/soft links；不支持分块/压缩写出、就地修改、保留未知消息或物理布局
- 维护强度：**单版本**；GitHub `JSJ222/MoonH5` 0 stars，2026-11-01 创建并 push（非常新）

- **判定：已有成熟包（⚠ 两个实现均为单版本）。** HDF5 读能力已相当深入（尤其 `moon-hdf5`），但两者都只支持“新建文件写出”，不支持原地修改；两个实现均为 2026-11 的单版本发布，长期维护证据不足。

#### A-3 NetCDF

**检索词**：`netcdf`（1 条命中）

**`hrwqe/cf_ocean` 0.1.4**
- 版本 / 最新版本发布：0.1.4 / 2026-08-24
- 下载：53
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 0 个依赖 / 5 个版本
- 链接：https://mooncakes.io/docs/hrwqe/cf_ocean
- README 声称的覆盖范围：
  - NetCDF **Classic (CDF-1) 与 64-bit Offset (CDF-2)** 的 header 与 variable payload
  - **明确边界：NetCDF-4/HDF5 containers are not implemented**
  - CF 元数据、维度/属性/单位/standard-name 校验；3D/4D 索引切片、masked arrays、lazy scaling
  - 海洋数据处理：EOS-80/UNESCO 风格与 TEOS-10 近似；QC（missing/range/rate/spike/flatline）；profile screening
  - Zarr：仅 Zarr v2 metadata 与原始 little-endian `f8` chunks，`compressor: null`，不含 zlib/Blosc
  - Parquet：仅“海洋剖面的紧凑 JSON schema 表示”，**不生成完整 Parquet 二进制文件或 Arrow buffers**
  - CSV/JSON/GeoTIFF metadata/lineage 导出
- 维护强度：5 个版本；GitHub `hrwqe/moonbit-cf-ocean` 0 stars，2026-08-13 创建，2026-08-24 最后 push（截至 2026-11-06 已 10 周无更新）
- **判定：部分重叠。** 只覆盖 NetCDF Classic / CDF-2，且包定位是海洋科学工具集，不是通用 NetCDF 库；NetCDF-4 是明确空白。

#### A-4 MAT-file

**检索词**：`matlab`（1 条命中）、`mat file`（0 条命中）、`mat`（50 条命中，含大量数学库噪声）

> 注：`mat file` 作为两词查询返回 0 条，说明搜索 API 对多词短语按包名/关键词/摘要做的是有限匹配；有效检索词是 `matlab` 与 `mat`。

**`WeiR-h/moonmatbridge` 0.1.11**
- 版本 / 最新版本发布：0.1.11 / 2026-10-31
- 下载：180
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 0 个依赖 / 31 个版本
- 链接：https://mooncakes.io/docs/WeiR-h/moonmatbridge
- README 声称的覆盖范围：
  - MAT Level 5 小端/大端读取；标准标签与小数据标签；多变量
  - `miCOMPRESSED` 压缩读取；MoonBit 解码 stored/fixed/dynamic DEFLATE，校验 Adler-32
  - 确定性未压缩/压缩小端写入；不嵌入时间戳
  - 递归混合类型：cell、struct 数组、char、legacy object（类名与字段数据）；多维、空数组、交叉嵌套
  - 字符：六种存储标签；中文、非 BMP；保留编码及原始存储单位；大小端
  - CSC 稀疏：二维 double、logical、complex double；混合文件、容量保留、显式密集转换
  - 数值类型：float32/64；有符号/无符号 int8/16/32/64；logical；复数 float32/64
  - 形状：标量 `[1,1]`、行/列向量、多维、空数组；保持列优先
  - 数据保真：同存储类型往返保留 IEEE 字节、NaN payload、负零、精确 64 位整数
  - JSON 互通、NPY v1.0 导出、NPY 1/2/3 读取（大小端、C/F 顺序、复数交错）
  - 数组处理：切片、按轴取样、拼接、reshape、轴置换；混合文件按名提取变量
  - 无损快照、结构化 diff、按根变量读取、分块读写
  - 核心编译目标：JS、wasm-gc、native；CLI：Windows x64 原生 EXE、可选 Node.js 文件适配器
- 维护强度：31 个版本；GitHub `WeiR-h/moonmatbridge` 0 stars，2026-10-07 创建，2026-11-05 最后 push（高度活跃）
- **判定：已有成熟包。** 覆盖 MAT Level 5 的读写、压缩、混合类型、稀疏、复数、NPY 互通，且版本迭代密集，是 A 方向中维护最强的包之一。

#### A-5 Zarr

**检索词**：`zarr`（2 条命中）

**`zlhahaha/zarr` 0.7.0**
- 版本 / 最新版本发布：0.7.0 / 2026-09-30
- 下载：72
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 4 个依赖 / 7 个版本
- 链接：https://mooncakes.io/docs/zlhahaha/zarr
- README 声称的覆盖范围：
  - Zarr v2 与 v3 分块 N 维数组；独立实现，非官方 Zarr Developers 项目
  - 内存与 native 文件系统；`bool`、有/无符号 8/16/32/64 位整数、float32/float64；元素、矩形切片、缺失 chunk 填充、边缘 chunk
  - raw chunks；gzip/zstd 两种格式；v2 另有 zlib；文档化的 Blosc 子集
  - Groups 与 attributes（v2 `.zgroup`/`.zattrs`，v3 `zarr.json`）
  - v3 sharding 索引 **只读**；**sharded writes 不支持**
  - Native 只读 HTTP 与 S3 适配器，可 hydration 普通 chunk 或 shard 内选定 inner chunk 到临时 `MemoryStore`
  - `RegionTileCursor` 有界 tile 遍历
  - Consolidated metadata 只读
  - 明确不支持：unsupported dtypes/codecs、cloud writes、concurrent-writer snapshots
- 维护强度：7 个版本；GitHub `zlhahaha/zarr` 0 stars，2026-09-23 创建，2026-09-30 最后 push
- **判定：已有成熟包。** v2/v3 主体能力完整，但分片写、云写、并发写快照是明确空白。

#### A-6 NPY / NPZ

**检索词**：`npy`（3 条命中）、`npz`（3 条命中）、`numpy`（7 条命中）

**`ShunjunGu/moon-npy` 0.4.0（已知项）**
- 版本 / 最新版本发布：0.4.0 / 2026-09-29
- 下载：40
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 2 个依赖 / 2 个版本
- 链接：https://mooncakes.io/docs/ShunjunGu/moon-npy
- README 声称的覆盖范围：
  - NPY v1.0 / v2.0 / v3.0 读取与写出
  - primitive numeric dtype：bool / i1–i8 / u1–u8 / f4 / f8；complex c8 / c16（v0.2.0 起）
  - N-D shape（含 0-d scalar、3-D）；C / Fortran order；big-endian / native `=`；空数组
  - 31 个 `.npy` fixture + 3 个 `.npz` Oracle archive 跨语言 round-trip；31/31
  - NPZ **未压缩**读取（v0.3.0）：`decode_npz` → `NpzArchive`，`get(name)`/`names()`；成员名自动剥 `.npy`
  - NPZ **未压缩**写入（v0.4.0）：`encode_npz`，全 ZIP_STORED、自实现 CRC-32、可被 `np.savez` 家族互操作
  - 容器层明确拒绝：压缩成员（`NpzCompressedMember`）、路径穿越、重复成员、zip64、结构损坏/加密
  - 176 个单元测试；CLI `dump [--limit N]` 覆盖 13 个 dtype
- 维护强度：2 个版本；GitHub `ShunjunGu/moon-npy` 0 stars，2026-09-08 创建，2026-09-29 最后 push
- **判定：NPY 已有成熟包；NPZ 部分重叠（仅未压缩）。**

**`WeiR-h/moonmatbridge` 0.1.11**：NPY v1.0 导出、NPY 1/2/3 读取，含大小端、C/F 顺序、复数交错编码；是 MAT↔NPY 的互通层，不是独立 NPY 库。

**`amor2025/moonNum` 0.1.0**
- 最新版本：2026-07-06；下载 74；build_status `success`；1 个版本
- 注册表描述：NumPy 的 Moonbit 移植——多维数组、线性代数、FFT、随机数
- 这是数值计算库，不是 NPY/NPZ 文件格式实现

**`mizchi/numbt` 0.2.4**
- 最新版本：2026-08-15；下载 1645；build_status `success`；4 个版本；依赖 `mizchi/blas` 0.1.3；NumPy-style 数值计算库，BLAS/LAPACK
- README 声称：Vec/Mat zero-copy views、BLAS `cblas_sgemm`、LAPACK SVD、element-wise、softmax/ReLU；依赖 native BLAS/LAPACK
- 不是 NPY 文件格式实现

- **判定（NPY/NPZ 子方向）：已有成熟包（NPY）；部分重叠（NPZ）。** NPZ 压缩成员是明确空白。

#### A-7 Parquet 及列式格式

**检索词**：`parquet`（12 条命中）、`columnar`（14 条）、`arrow`（27 条）、`avro`（5 条）、`orc`（50 条，含大量无关）

**`mizchi/parquet` 0.2.2**
- 版本 / 最新版本发布：0.2.2 / 2026-09-24
- 下载：2324
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 2 个依赖 / 4 个版本
- 链接：https://mooncakes.io/docs/mizchi/parquet
- README 声称的覆盖范围：
  - Reader 通过 vendored `apache-parquet-testing` fixtures：delta_binary_packed、delta_byte_array、delta_encoding_optional_column、delta_encoding_required_column、int32_with_null_pages、fixed_length_byte_array、datapage_v2_empty_datapage.snappy.parquet、int96_from_spark、alltypes_plain、alltypes_dictionary
  - Writer 仅支持 flat schemas：Int32、Int64、String、Binary；Required/Optional repetition
  - DuckDB 双向互操作验证
  - 基准：read delta binary packed、int32 null pages、fixed length byte array、alltypes plain、alltypes dictionary、int96 from spark、empty snappy datapage v2
- 维护强度：4 个版本；GitHub `mizchi/parquet` 6 stars，2026-03-08 创建，2026-09-24 最后 push，2 个 open issues
- **判定：已有成熟包。** 读能力强，写能力仅 flat schema。

**`superbigcup325/colenc` 0.1.3**
- 最新版本：2026-10-26；下载 1322；build_status `success`；4 个版本
- 链接：https://mooncakes.io/docs/superbigcup325/colenc
- 注册表描述：Parquet page-level 编码族，可复用、可验证、可插拔的列式编码内核
- 属于 Parquet 编码层，不是完整文件读写

**`sgy1023-crt/parquet` 0.3.0**
- 最新版本：2026-10-30；下载 16；build_status `success`；1 个版本
- 链接：https://mooncakes.io/docs/sgy1023-crt/parquet
- 注册表描述：基于 `mizchi/parquet` 的 Parquet 读写，增加 row-group statistics 与 selective decoding
- ⚠ 单版本、低下载

**相邻格式：**
- `shunge/arrow` 0.2.1（90 下载，success，3 个版本，2026-09-30）：纯 MoonBit Arrow IPC stream 与 file reader/writer，checked metadata，PyArrow 互操作
- `yugonlian/moon-avro` 0.3.0（265 下载，success，7 个版本，2026-08-22）：Apache Avro schema、datum codec、Object Container File
- `oyjh0381/moonorc` 0.1.0（18 下载，success，1 个版本，2026-11-01）：有界 ORC 列式记录交换与 selective stripe scanning
- `wangjiale6036-dotcom/moonnifti` 0.2.0（48 下载，success，2 个版本，2026-09-24）：NIfTI-1 voxel access 与世界坐标保持变换

- **判定：Parquet 已有成熟包；Arrow/Avro 已有成熟包；ORC 部分重叠（单版本、读取向）。**

#### A-8 通用科学数据 / 二进制格式

- `scientific data` 14 条命中：moonmatbridge、moonastrofits、moon-hdf5、zarr、moonh5、moon-certified、moonecoguard、measure、moonbit-geofield、owl_mbt、moontopolens、moonNum、mathplotlib、pyroduct。真正实现科学数据格式的仍是 FITS/HDF5/MAT/Zarr 四类。
- `binary format` 50 条命中：moonfory（Fory 跨语言二进制格式，0.1.3，47 下载，4 个版本）、binschema（安全组合式二进制协议 codec，0.3.1，37 下载，2 个版本）、Yu-zh/data（serde 形状的序列化框架，0.2.1，140 下载，3 个版本）、bobzhang/unmarshal（OCaml marshalled data，0.3.2，100 下载，10 个版本）等。
- **判定：已有成熟包（通用二进制序列化层）。** 但通用序列化框架不等于具体科学格式实现。

### 2.3 方向 B：AI 应用 / 模型协议客户端

#### B-1 MCP SDK

**检索词**：`mcp`（50 条命中）、`model context protocol`（50 条）

**`colmugx/mcp` 0.18.2**
- 版本 / 最新版本发布：0.18.2 / 2026-10-23
- 下载：9890
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 4 个依赖 / 34 个版本
- 链接：https://mooncakes.io/docs/colmugx/mcp
- README 声称的覆盖范围：
  - MCP **2026-07-28**（stateless per-request metadata + MRTR）
  - 完整 content/tool/resource/prompt wire models；completion、sampling、form/URL elicitation models；trusted request context；cooperative cancellation；cache metadata preservation；registry-aware HTTP header validation
  - 工具输入/输出 JSON Schema 校验：注册时编译 schema，执行前拒绝非法参数；支持 closed objects、数值约束、本地/预加载外部 `$ref`、`$id`/anchors、dynamic references、unevaluated constraints、标准词汇 custom dialects
  - Elicitation 表单在交互前校验；MRTR 响应键/result type/表单约束由服务端独立验证
  - JSON-RPC id 保留超出 Int32/binary64 的整数字面量；字符串 id、大数字 id、重复检查、订阅、取消共享一致路由
  - 高级 API：`MCPServer`、`MCPClient`、`MCPHost`；`connect_stdio` / `connect_http`；`run_stdio` / `run_http`
  - `colmugx/mcp/client/legacy` 兼容 2025-11-25 时代服务端
  - Bearer tokens、server-side auth hooks、protected-resource metadata
  - **明确不含**：OAuth authorization client lifecycle、PKCE、dynamic client registration、token refresh management
  - 一致性：validator 标准套件 1301/1301；可选 format assertions 与通用 ECMA-262 patterns 不在支持范围
- 维护强度：34 个版本；GitHub `colmugx/mcp.mbt` 5 stars，2026-01-21 创建，2026-10-23 最后 push
- **判定：已有成熟包。** 这是当前注册表中版本最多、下载量最高的 MCP SDK，服务端/客户端/Host/双传输齐全。

**`marianoguerra/mcp` 0.10.1 + 子包**
- 版本 / 最新版本发布：0.10.1 / 2026-10-19
- 下载：mcp 367、mcp-client 223、mcp-server 203、mcp-server-native 182、mcp-inspector 198、mcp-inspector-cli 136
- build_status：全部 `success`
- 许可证 / 依赖 / 版本数：MIT / mcp 0 依赖 / 15 个版本
- 链接：https://mooncakes.io/docs/marianoguerra/mcp
- README 声称的覆盖范围：
  - `@jsonrpc`：JSON-RPC 2.0 frames、request-id 生成、modern error codes（-32020 HeaderMismatch、-32021 MissingRequiredClientCapability、-32022 UnsupportedProtocolVersion）
  - `@meta`：每个 modern request 的 `_meta` envelope、resultType 分类（complete / input_required）、保留的 `io.modelcontextprotocol/*` keys
  - `@base64`、`@xmcpheader`（SEP-2243 `x-mcp-header` 扫描、RFC 9110 token 校验、`=?base64?…?=` sentinel、tool-exclusion rule）
  - `@hypermedia` 扩展、`@transport` 的 `Transport`/`ResponseStream` traits
  - `mcp-client`：streamable-HTTP + stdio、MRTR、subscriptions、tasks extension
  - `mcp-server`：side-effect-free routing core、tools/resources/prompts、transport trait
  - `mcp-server-native`：stdio + streamable HTTP with SSE
  - `mcp-inspector` / `mcp-inspector-cli`：session、capability state、mcp.json catalog、one-shot CLI
- 维护强度：15 个版本；GitHub `marianoguerra/mcp-mb` 0 stars，2026-08-06 创建，2026-10-20 最后 push
- **判定：已有成熟包。** 是“协议类型 + 客户端/服务端拆分”的完整套件，偏协议层、无 I/O 的设计便于嵌入。

**`moonbitstack/moonmcp` 0.1.10**
- 版本 / 最新版本发布：0.1.10 / 2026-11-05
- 下载：151
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 10 个依赖 / 10 个版本
- 链接：https://mooncakes.io/docs/moonbitstack/moonmcp
- README 声称的覆盖范围：
  - 同一服务端同时服务两个协议时代：请求携带 `_meta` 协议版本时按 2026-07-28 stateless 处理；`initialize` 握手选择 2025-11-25 至 2024-11-05
  - `#mcp.tool` / `#mcp.resource` / `#mcp.prompt` 注解，参数类型自动生成 input schema；resource URI `{name}` 模板；结果默认 JSON（String 除外）
  - 服务端：tools/resources/resource templates/prompts；Streamable HTTP 与 stdio；progress/subscriptions；向客户端请求输入（MRTR）；completion；authorization（Bearer HMAC / 自定义校验）；logging
  - 客户端：`Client::connect`，支持 Memory / Lines / Http transport；`list_tools`/`list_resources`/`list_prompts`/`call_tool`/`read_resource`/`get_prompt`/`listen`/`request`/`exchange`/`notify`/`close`
  - 官方 MCP conformance suite 在 `src/examples/07-conformance` 的 **所有 server 场景通过**
- 维护强度：10 个版本；GitHub `moonbitstack/moonmcp` 0 stars，2026-10-24 创建，2026-11-05 最后 push（非常活跃）
- **判定：已有成熟包。** 服务端 + 客户端 + 双协议时代 + 官方 conformance 证据齐全。

**`shiguri-01/mcp` 0.2.0**
- 版本 / 最新版本发布：0.2.0 / 2026-08-20
- 下载：121
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 2 个依赖 / 3 个版本
- 链接：https://mooncakes.io/docs/shiguri-01/mcp
- README 声称的覆盖范围：
  - MCP 2026-07-28
  - Server：`ServerBuilder`、typed input via `@schema.JsonSchema` + `@json.FromJson`、tool/resource/prompt、stdio 与 Streamable HTTP
  - Client：`Client`、typed invocation、MRTR resolution
  - Packages：core protocol types、server、client、schema（JSON Schema Draft 2020-12 builder/validator/typed decoder）、stdio、http（SSE progress/subscriptions + OAuth 2.0）、auth（RFC 9728、PKCE S256、token caching）、jsonrpc
- 维护强度：3 个版本；GitHub `shiguri-01/mcp.mbt` 1 star，2026-05-26 创建，2026-08-20 最后 push（截至 2026-11-06 约 11 周无更新）
- **判定：已有成熟包。** 是少数明确覆盖 OAuth 2.0（PKCE S256、token caching）的 MCP 实现。

**`cogna-dev/mcp-sdk` 0.1.0**
- 版本 / 最新版本发布：0.1.0 / 2026-04-16
- 下载：84
- build_status：`success`
- 许可证 / 依赖 / 版本数：MIT / 1 个依赖 / 1 个版本
- 链接：https://mooncakes.io/docs/cogna-dev/mcp-sdk
- README 声称：MCP MoonBit SDK，Server/Tools/Resources/Prompts/Sampling/Elicitation/Content Types、MCP Inspector、Claude Code 集成、Conformance Testing
- 维护强度：⚠ 单版本；GitHub `cogna-dev/mcp-sdk` 0 stars，2026-04-16 发布后无新版本
- **判定：部分重叠（早期实现、单版本、已 6 个月未更新）。**

#### B-2 核实 `moonbitstack/moonjrpc` 的实际覆盖范围

**`moonbitstack/moonjrpc` 0.1.3**
- 版本 / 最新版本发布：0.1.3 / 2026-11-05
- 下载：48
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 1 个依赖（`moonbitlang/async` 0.22.5）/ 3 个版本
- 链接：https://mooncakes.io/docs/moonbitstack/moonjrpc
- 注册表关键词：`json-rpc`、`jrpc`、`jsonrpc`、`rpc`、`json`、`peer`、`bidirectional`、`ndjson`、`stdio`、`content-length`、`lsp`、`mcp`、`acp`
- README 声称的覆盖范围：
  - JSON-RPC 2.0 消息、method table、双向 `Peer` 调用、batch
  - 错误码：-32700 parse error、-32600 invalid request、-32601 method not found、-32602 invalid params、-32603 internal error
  - 传输：`lines`（一行一条消息，MCP/ACP 的 stdio transport）、`content_length`（LSP base protocol）；自定义 `Frames` trait
  - 明确写："The HTTP shape is not here, because each protocol has its own: MCP answers on the POST's SSE stream, ACP on a GET stream, A2A in the POST's body. They build it on `Methods` and `Peer`."
  - 明确写："Telling the other side a call was given up on is left to the protocol: MCP, ACP and LSP each have their own notice for it."
  - 一致性：JSON-RPC 2.0 spec 第 7 节全部示例；与 `vscode-jsonrpc`（content_length）和 `json-rpc-2.0`（lines）互操作
- **核实结论：`moonjrpc` 不是完整 MCP SDK。** 它只提供 JSON-RPC 2.0 消息层、method table、双向 Peer 与 stdio/LSP 帧；不包含 MCP 的 `initialize` 生命周期、capabilities、tools/resources/prompts 类型、`_meta`、SSE 传输、MRTR、OAuth。关键词里的 `mcp` 表示“可用于构建 MCP”，不是“实现了 MCP”。
- 另注：`moonbitstack/moonjsonrpc` 0.1.0（6 下载，2026-11-05，success）与 `moonjrpc` 的描述、关键词、依赖完全相同，但注册表仓库地址不同（`moonbitstack/moonjsonrpc` vs `moonbitstack/moonjrpc`）；疑似同一实现的双发布，未核实源码差异，不影响上述结论。

#### B-3 LLM API 客户端

**检索词**：`openai`（50 条）、`anthropic`（20 条）、`llm`（50 条）、`chat completion`（25 条）、`deepseek`（16 条）、`gemini`（7 条）、`ollama`（2 条）

**`mizchi/llm` 0.3.2**
- 版本 / 最新版本发布：0.3.2 / 2026-08-15
- 下载：153802
- build_status：`success`
- 许可证 / 依赖 / 版本数：MIT / 2 个依赖 / 11 个版本
- 链接：https://mooncakes.io/docs/mizchi/llm
- README 在注册表为空（`readme_content` 长度 1），但源码目录显示覆盖：`chat`、`client`、`config`、`openai/`、`anthropic/`、`claude_code/`、`agent`、`agent_cancellable`、`tool`、`tool_validation`、`tools/`、`skills_loader`、`skill_metadata`、`mock_provider`
- 注册表描述：Pure MoonBit LLM client library
- 维护强度：11 个版本；GitHub `mizchi/llm` 1 star，2026-02-06 创建，2026-08-15 最后 push（截至 2026-11-06 约 12 周无更新）；注册表 `dependents` 为 4，但 153802 次下载是本次检索中 LLM 客户端类最高的一档
- **判定：已有成熟包（⚠ 维护节奏放缓，但生态使用量最高）。**

**`gaato/openai` 0.6.0**
- 最新版本：2026-10-19；下载 169；build_status `success`；Apache-2.0；8 个版本
- 链接：https://mooncakes.io/docs/gaato/openai
- README 声称：Unofficial OpenAI API client；models、embeddings、Responses、Chat Completions（buffered + streaming，含 tool calling）；类型与操作由 vendored OpenAPI spec 生成；可通过 `base_url` 对接 OpenAI 兼容服务；调用方提供 `Transport` 与 `Clock`；重试策略（408/409/429/5xx，两次重试）；`max_body_bytes` 有界读取

**`gaato/anthropic` 0.12.0**
- 最新版本：2026-10-20；下载 114；build_status `success`；Apache-2.0；15 个版本
- 链接：https://mooncakes.io/docs/gaato/anthropic
- README 声称：Anthropic Messages API；buffered/streaming messages、open content blocks、stream events、tool use；`create_message`、`stream_message`、`count_tokens`、`list_models`、`retrieve_model`；thinking + signature；不含 beta APIs、batches、files

**`DC-Z-lab/moonllm` 0.1.0**
- 最新版本：2026-07-07；下载 504；build_status `success`；Apache-2.0；1 个版本；4 个 dependents
- 链接：https://mooncakes.io/docs/DC-Z-lab/moonllm
- 注册表描述：Type-safe, OpenAI-compatible LLM client：chat completions、streaming (SSE)、tool calling、multimodal input
- 维护强度：⚠ 单版本，但 504 下载、4 个依赖者

**`marianoguerra/llm` 0.4.2**
- 最新版本：2026-10-19；下载 487；build_status `success`；Apache-2.0；12 个版本
- 链接：https://mooncakes.io/docs/marianoguerra/llm
- 注册表描述：dialect-agnostic LLM IR、每个 provider 一种 wire mapping、data-driven provider registry、browser 可实现 transport

**`co63oc/moonbit_promptkit` 0.1.7**：2026-08-06，81 下载，success，8 个版本；OpenAI 兼容接口、多平台
**`QuietlyChan/moonai` 0.1.0**：2026-08-16，37 下载，success，1 个版本；provider-neutral AI SDK（受 Vercel AI SDK 7 启发）
**`trkbt10/llm_interop` 0.3.0**：2026-03-22，84 下载，build_status `legacy`，6 个版本；多 provider 统一抽象、streaming、tool calling、protocol translation

- **判定：已有成熟包。** OpenAI/Anthropic 官方风格客户端、统一多 provider 抽象、兼容层均已存在；仅“Ollama 专用客户端”未单独检索到（`ollama` 只命中 mizchi/llm 与 moonkoog 的描述）。

#### B-4 Agent 框架

**检索词**：`agent`（50 条）、`tool calling`（28 条）、`prompt template`（13 条）

**`colmugx/posoco` 0.24.1**
- 最新版本：2026-11-05；下载 4472；build_status `success`；Apache-2.0；71 个版本
- 链接：https://mooncakes.io/docs/colmugx/posoco
- 注册表描述：LLM Agent framework with hexagonal (ports-and-adapters) architecture；定义 extension ports + Agent loop
- 维护强度：71 个版本，高度活跃

**`moonbitstack/moonkoog` 0.6.1**
- 最新版本：2026-09-22；下载 68；build_status `success`；Apache-2.0；5 个版本
- 链接：https://mooncakes.io/docs/moonbitstack/moonkoog
- README 声称：JetBrains Koog 1.1.1 的 MoonBit 移植；prompt/message model、LLM client contract、tool registry（JSON schema descriptor）、`AIAgent` tool-calling loop（Koog `singleRunStrategy`，`maxIterations` 有界）；与 moonapi/mooncat/moonhttp/moonorm 组合

**`weopqrst/agent` 0.5.1**
- 最新版本：2026-08-19；下载 95；build_status `success`；Apache-2.0；8 个版本
- 链接：https://mooncakes.io/docs/weopqrst/agent
- README 声称：LangChain 核心抽象移植；PromptTemplate/ChatPromptTemplate、OutputParser/JsonOutputParser、BufferMemory/BufferWindowMemory/SummaryMemory、Tool trait、LLMChain、ReAct AgentExecutor、RunnableWrapper（pipe/map）、SequentialChain、UsageTracker/CallTrace/TimingTracker、RAG（Document/MarkdownLoader/RecursiveCharacterTextSplitter/VectorStore/Embedder/Retriever/MMR/RetrievalTool）、CLI REPL、`.env`/`config.json`/环境变量、MCPClient/MCPServer 双向桥接 + sse/stdio transport

**`totto2727/agent-sdk` 0.2.1**
- 最新版本：2026-08-23；下载 171；build_status `success`；MIT；3 个版本
- 链接：https://mooncakes.io/docs/totto2727/agent-sdk
- 注册表描述：Provider-neutral MoonBit interfaces for agent CLI SDKs；同作者还有 `agent-core-sdk`、`agent-cli-sdk`、`workgraph-*`

- **判定：已有成熟包。** Agent 框架至少 4 套独立实现，覆盖 LangChain 风格、Koog 移植、六边形架构、CLI SDK 四种路线。

#### B-5 Tool calling / Embedding

**Tool calling：** `mizchi/llm`（tool/tool_validation/tools）、`gaato/openai`（Chat Completions tool calling）、`gaato/anthropic`（tool use）、`moonbitstack/moonmcp`（MCP tools）、`colmugx/mcp`（JSON Schema 校验）均覆盖。
- **判定：已有成熟包。**

**Embedding：**
- `wskwsk68/MoonEmbed` 0.1.6（2026-08-16，53 下载，success，7 个版本）：word2vec text / GloVe text / word2vec binary 加载；cosine exact + bucketed approximate；token/phrase/prefix/threshold/batch/tokenizer-aware 查询；sentence embeddings；metadata-filtered document store；诊断、recall 报告、量化；知识库工作流。**是词向量，不是 Transformer 模型推理。**
- `gaato/openai` 0.6.0：OpenAI embeddings API 客户端。
- `majikxu/laya` 0.1.0（2026-09-22，26 下载，success，1 个版本）：native ModernBERT/mmBERT 编码器推理，BLAS/Metal 后端，Python 运行时零依赖；三种 typed decision（choice/score/noul）；tokenization 与 Hugging Face `tokenizers` 对齐。**是本地编码器推理，但 README 未提供通用 embedding API。**
- **判定：部分重叠。** API embedding 与词向量加载已覆盖；本地 Transformer embedding 模型推理没有专门包（`laya` 是相邻能力，不是通用 embedding 库）。

#### B-6 MCP 之外的模型协议

- `moonbitstack/moonrpc` 0.21.12（1062 下载，success）：gRPC for MoonBit
- `Lfan-ke/moonrpc` 0.10.1（610 下载，success）：gRPC 实现
- `moonbitlang/protobuf` 0.2.0（4474 下载，success）：protobuf runtime；`moonbitlang/protoc-gen-mbt` 0.3.0（67 下载）
- `moonbitstack/moonjsonrpc` 0.1.0 / `moonbitstack/moonjrpc` 0.1.3：JSON-RPC 2.0
- **判定：已有成熟包（协议基础设施）。**

### 2.4 方向 C：开发者工具

#### C-1 Markdown 处理

**检索词**：`markdown`（50 条）、`mdx`（2 条）、`lint`（50 条）

**`mizchi/markdown` 0.8.4**
- 版本 / 最新版本发布：0.8.4 / 2026-10-19
- 下载：22093
- build_status：`success`
- 许可证 / 依赖 / 版本数：MIT / 11 个依赖 / 31 个版本
- 链接：https://mooncakes.io/docs/mizchi/markdown
- README 声称的覆盖范围：
  - CST-based incremental Markdown parser/compiler；JS/WASM/native
  - CommonMark 0.31.2 全部 652 个示例通过
  - 源码导向 CST，保留 node spans；增量解析（编辑位置驱动，最多 42x 加速）
  - GFM：tables、task lists、strikethrough
  - HTML renderer（remark-html 兼容输出）；mdast 兼容 AST；`toMarkdown` 规范化
- 维护强度：31 个版本；GitHub `mizchi/markdown.mbt` **104 stars**，2025-12-18 创建，2026-10-19 最后 push
- **判定：已有成熟包。** 是 C 方向中 GitHub 社区证据最强的包。

**其他 Markdown 包：**
- `shiguri-01/markdown` 0.1.1（2026-06-13，53 下载，success，2 个版本）：event-driven、CommonMark/GFM/HTML/AST
- `oilleelssq-wq/moonmarkdown` 0.2.0（2026-07-21，101 下载）：CommonMark 到 HTML
- `lexchb/moonbit-texteditor` 0.1.0（2026-07-16，34 下载）：Markdown 到 HTML
- `NoahLiu/mdparse` 0.1.0（2026-10-19，82 下载）：从 mizchi/markdown fork，仅保留解析链路
- `moonbit-community/cmark` 被 `mdc` 依赖（0.4.12），是 C 实现移植风格的另一条链路
- **判定：已有成熟包。**

#### C-2 YAML frontmatter

**检索词**：`frontmatter`（28 条）、`front matter`（45 条）、`mdmeta`（0 条）、`metadata`（50 条）

**`moonrockz/mdc` 0.1.0**
- 版本 / 最新版本发布：0.1.0 / 2026-10-25
- 下载：83
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 2 个依赖 / 3 个版本
- 链接：https://mooncakes.io/docs/moonrockz/mdc
- README 声称的覆盖范围：
  - Markdown + 可选 YAML frontmatter；Markdown 使用 `moonbit-community/cmark` 0.4.12，YAML 使用 `moonbit-community/yaml` 0.0.7
  - `Document`：不可变，构造时派生 frontmatter、Markdown tree、source positions；`parse` 为构造器别名
  - `Frontmatter`：不可变；`raw()` 返回原始文本，`value()` 返回 YAML mapping 深拷贝
  - `FrontmatterError`：`InvalidYaml(at~, message~)`、`NotAMapping`、`MultipleDocuments(count~)`
  - `ParseError`：`UnterminatedFrontmatter`、`InvalidFrontmatter`
  - frontmatter 必须首行 `---`，`---` 或 `...` 闭合；支持 trailing spaces/tabs、BOM、LF/CRLF/CR
  - traversal API：`doc.root()`、`Node::children()`、`BlockView`/`InlineView`、`kind()`、`location()`、`doc.source_range(view.location())`
- 维护强度：3 个版本；GitHub `moonrockz/mission-control` 0 stars，2026-10-17 创建，2026-11-01 最后 push
- **判定：部分重叠。** 解析能力完整（frontmatter + Markdown AST + source range），但只有 3 个版本、0.1.0、83 次下载；且是库，不是 CLI。

**`moonrockz/moonbase-mdc` 0.0.1**
- 最新版本：2026-10-19；下载 46；build_status `success`；Apache-2.0；1 个版本
- 链接：https://mooncakes.io/docs/moonrockz/moonbase-mdc
- 注册表描述：Markdown with YAML frontmatter and traversal APIs for Moonbase
- ⚠ 单版本、0.0.1

**`JM-ai-n/moonfolio` 0.1.0**
- 最新版本：2026-08-22；下载 30；build_status `success`；1 个版本
- 链接：https://mooncakes.io/docs/JM-ai-n/moonfolio
- README 声称：Markdown 元数据契约与内容卷宗工具库；不做通用 Markdown 解析、不渲染、不生成站点；专注字段契约、内容画像、registry、diff、编辑修复、稳定 fingerprint、manifest 生成；README 自称 "不是普通 front matter 读取器"
- ⚠ 单版本、低下载

**`moonrockz/telescope` 0.5.1（1751 下载）**、`himeno/mopress` 0.4.0（62 下载）、`hua1104/moonpress` 0.1.0（38 下载）、`mizchi/astra` 0.23.4（900 下载）等静态站点生成器也消费 frontmatter，但不是独立的 frontmatter 解析包。

**`mdmeta` 检索：0 条命中。**
- **判定：部分重叠。** frontmatter 解析已有第三方库（mdc），不是空白；但供给很新、单薄，且没有独立的 frontmatter CLI（mdmeta 类命令行工具为空白）。

#### C-3 YAML

**检索词**：`yaml`（50 条）

**`moonbit-community/yaml` 0.0.8**
- 版本 / 最新版本发布：0.0.8 / 2026-10-18
- 下载：115649
- build_status：`success`
- 许可证 / 依赖 / 版本数：MIT / 0 个依赖 / 8 个版本
- 链接：https://mooncakes.io/docs/moonbit-community/yaml
- README 声称：YAML 解析与 stringify；**简化的 YAML 子集**，可转换为 JSON；移植自 yaml-rust2；示例覆盖 `%YAML 1.2` 指令、嵌套 mapping、sequence、comment
- 维护强度：8 个版本；GitHub `moonbit-community/yaml.mbt` 1 star，2025-08-28 创建，2026-10-18 最后 push，1 个 open issue；12 个 dependents
- **判定：已有成熟包（⚠ 规范覆盖为简化子集，非完整 YAML 1.2）。**

**`moonbitstack/moonyaml` 0.1.4**
- 版本 / 最新版本发布：0.1.4 / 2026-11-03
- 下载：2369
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 0 个依赖 / 5 个版本
- 链接：https://mooncakes.io/docs/moonbitstack/moonyaml
- README 声称：YAML 1.0 / 1.1 / 1.2；两种形状——`Json` value tree，以及保留 comments/anchors/tags/style 的 document tree；`loads`/`dumps`、`parse`/`emit`、`doc.to_json().stringify()`
- 维护强度：5 个版本；GitHub `moonbitstack/moonyaml` 0 stars，2026-09-16 创建，2026-11-04 最后 push；4 个 dependents
- **判定：已有成熟包。**

**`bobzhang/yaml` 0.1.2**：2026-11-03，37 下载，success，3 个版本；YAML 1.2 parser
**`myfreess/yaml` 0.1.0**：2025-08-29，64 下载；旧包
**`tonyfettes/tree_sitter_yaml`**：grammar，不是解析器
- **判定：已有成熟包。**

#### C-4 TOML

**检索词**：`toml`（50 条）

**`bobzhang/toml` 0.4.3**
- 版本 / 最新版本发布：0.4.3 / 2026-08-16
- 下载：129401
- build_status：`success`
- 许可证 / 依赖 / 版本数：Apache-2.0 / 1 个依赖 / 10 个版本
- 链接：https://mooncakes.io/docs/bobzhang/toml
- 注册表描述：MoonBit TOML parser；仓库 `moonbit-community/toml-parser`
- 维护强度：10 个版本；GitHub `moonbit-community/toml-parser` 3 stars，2025-07-16 创建，2026-11-02 最后 push，11 个 open issues；10 个 dependents
- **判定：已有成熟包。**

**`moonbit-community/toml` 0.5.1**
- 最新版本：2026-11-02；下载 48146；build_status `success`；Apache-2.0；3 个版本
- 链接：https://mooncakes.io/docs/moonbit-community/toml
- 注册表描述：A TOML parser implementation in MoonBit
- 与 `bobzhang/toml` 同仓库，疑似同一实现的不同发布名/版本线

**`moonbitstack/moontoml` 0.1.1**
- 最新版本：2026-11-03；下载 792；build_status `success`；Apache-2.0；2 个版本；2 个 dependents
- 链接：https://mooncakes.io/docs/moonbitstack/moontoml
- README 声称：TOML 1.0.0；`loads` 读入 `Json` tree，`dumps` 写回；错误带 line/column

**`sa2360/toml` 0.1.1**：2026-10-04，37 下载，success，2 个版本；注册表描述（自动摘要）声称 TOML v1.0.0 parser + serializer，full toml-test compliance
**`hnlyxiaobing/toml` 0.4.9**：2026-08-27，273 下载，success；fork of bobzhang/toml with array-of-tables fix
**`conglinyizhi/toml` 0.1.0**：2026-08-21，213 下载，success；nightly-compatible
- **判定：已有成熟包。** 至少 5 个可消费的 TOML 实现。

#### C-5 CLI / 参数解析

**检索词**：`cli`（50 条）、`command line`（50 条）、`argument parser`（50 条）、`argparse`（50 条）

**标准库 `moonbitlang/core/argparse`**
- 所属模块：`moonbitlang/core` 0.1.20261105+65efd5b93（2026-11-05，175 个版本，build `success`，Apache-2.0）
- 链接：https://github.com/moonbitlang/core/tree/main/argparse
- 包内文件：`arg_action.mbt`、`arg_group.mbt`、`arg_spec.mbt`、`command.mbt`、`parser.mbt`、`help_render.mbt`、`extends.mbt`、`matches.mbt`、`error.mbt` 等
- README 声称：
  - 受 `clap` 启发的声明式参数解析；`FlagArg` / `OptionArg` / `PositionArg`
  - `long` 默认取参数名；`long=""` 禁用长别名
  - `parse_outcome(cmd, argv=...)` 不读进程状态、不改输入、不打印、不退出、不抛错；返回 `Parsed(matches)` / `Help(text)` / `Version(text)` / `Failed(error)`
  - `parse` 是 CLI 便捷入口：默认读进程参数，help/version 打印并以 0 退出，错误抛异常
  - 环境变量仅来自可选 `env` map，默认空
  - `Command` 支持 subcommand（`command.mbt`）、argument group、help 渲染
- 注意：`/api/v0/modules/core/argparse` 返回 404，因为它不是独立模块，而是 `moonbitlang/core` 模块内的一个 package；上述文件列表与 README 来自 GitHub `moonbitlang/core/argparse` 目录
- **判定：已有成熟包（标准库）。**

**`mizchi/admiral` 0.1.1**
- 最新版本：2026-08-15；下载 18310；build_status `success`；MIT；2 个版本
- 链接：https://mooncakes.io/docs/mizchi/admiral
- README 声称：`moonbitlang/core/argparse` 的薄封装；typed option helpers（string/bool/int/positional）、嵌套 subcommand + run callbacks、面向 AI agent 的 JSON schema 输出、bash/zsh/fish shell completion、自动 `--help`/`--version`
- 维护强度：GitHub `mizchi/admiral` 5 stars，2026-04-06 创建，2026-09-17 最后 push，1 个 open issue
- **判定：已有成熟包。**

**`hustcer/cmder` 0.6.1**
- 最新版本：2026-11-05；下载 214；build_status `success`；MIT；6 个版本
- 链接：https://mooncakes.io/docs/hustcer/cmder
- README 声称：`mizchi/admiral` 的 fork，基于 `moonbitlang/core/argparse`；可执行根命令与嵌套子命令、raising callbacks；string/bool/checked Int32 options + positional；全局选项与局部选项；不可变 command 定义与 parsed invocation；`parse` 返回结构化 outcome、不执行 callback、不做进程 I/O；`source_of` 参数来源；构造时校验；JSON 定义、Bash/Zsh/Fish completion
- 维护强度：GitHub `hustcer/cmder` 0 stars，2026-11-04 创建，2026-11-05 最后 push（非常新）
- **判定：已有成熟包。**

**`Yoorkin/ArgParser` 0.2.1**
- 最新版本：2026-02-11；下载 107805；build_status **`legacy`**；Apache-2.0；14 个版本；4 个 dependents
- 链接：https://mooncakes.io/docs/Yoorkin/ArgParser
- 注册表描述：command line argument parser
- 维护强度：⚠ 最后发布 2026-02-11（9 个月前），build_status 为 legacy
- **判定：部分重叠（高使用量，但已停更且构建体系陈旧）。**

**`TheWaWaR/clap` 0.2.6**
- 最新版本：2025-11-03；下载 6924；build_status **`legacy`**；MIT；8 个版本；12 个 dependents
- 链接：https://mooncakes.io/docs/TheWaWaR/clap
- 注册表描述：Command Line Argument Parser
- 维护强度：⚠ 最后发布 2025-11-03（1 年前），legacy
- **判定：部分重叠（已停更）。**

**`totto2727/admiral` 0.6.5**：2026-08-25，763 下载，success，10 个版本；async-first CLI builder，admiral 的另一条分支
**`Milky2018/options` 0.1.3**：2026-09-07，100 下载，success，4 个版本；README 明确 "for self-use and experimental, not for production"
**`cauchyQ/moonbit-argkit` 0.1.0**：2026-08-03，37 下载；小型零依赖参数解析
**`jqlssg/moondocopt` 0.1.1**：2026-10-26，41 下载；docopt 语义
- **判定（CLI 框架子方向）：已有成熟包。** 标准库 + admiral/cmder 两层生态完整；旧包 ArgParser/clap 仍可消费但已停更。

#### C-6 配置加载 / 分层 / 校验

**检索词**：`config`（50 条）、`dotenv`（11 条）、`json schema`（50 条）

**`moonbitlang/moon_config` 0.4.5**
- 最新版本：2026-10-22；下载 135172；build_status `success`
- 链接：https://mooncakes.io/docs/moonbitlang/moon_config
- 注册表描述：MoonBit package configuration parser
- 说明：用于解析 `moon.mod.json` 等包配置，不是通用应用配置库；135172 次下载是本次检索中配置类包的最高值

**`moonbitstack/moonconf` 0.1.3**
- 最新版本：2026-11-05；下载 47；build_status `success`；Apache-2.0；4 个版本
- 链接：https://mooncakes.io/docs/moonbitstack/moonconf
- README 声称：INI、Java properties、`.env`、HOCON、HCL 读入统一 tree；按程序顺序分层；对 model 校验并绑定 typed values；每个值保留 source + line；不打开文件/不 fetch URL（调用方读入字节）
- 维护强度：GitHub `moonbitstack/moonconf` 0 stars，2026-09-16 创建，2026-11-05 最后 push

**`MuVirus/moonfig` 0.1.8**
- 最新版本：2026-10-31；下载 125；build_status `success`；Apache-2.0；9 个版本
- 链接：https://mooncakes.io/docs/MuVirus/moonfig
- README 声称：JSON、INI、dotenv、YAML、TOML、XML、CBOR 或自建 Value tree 作为来源；Detector 按后缀/内容识别格式；`build_live()` + `Watcher::poll()` 热更新；多层来源（内存默认值、配置文件、环境变量、命令行参数）；按键合并；`MissingKey`/`TypeMismatch`/`ParseError`/`UnknownFormat`；`origin_of`/`origins()`/`snapshot()`

**其他配置包：**
- `Noverberrain/configscope` 0.6.1（107 下载，2026-10-31）：配置契约兼容性检查
- `123123213weqw/moon_configweave` 0.10.0（44 下载，2026-10-18）：分层配置合并、插值、provenance 审计
- `moonbit-community/ini` 0.2.3（79 下载，2026-09-26）：INI parser
- `crh12354/moonconfigkit` 0.1.1（36 下载，2026-08-23）：INI/properties 配置合并、校验、诊断
- `CYang-dep/moonkconfig` 0.3.0（45 下载，2026-10-22）：Kconfig core
- `Ryan-1125/moonlibconfig` 0.2.0（36 下载，2026-10-22）：libconfig 1.8.2 子集
- `ShellWen/dotenv` 0.6.1（105 下载，2025-10-02）、`spectacleCase/dotenv` 0.1.0（94 下载，2026-07-07）、`tonyfettes/dotenv` 0.4.1（55 下载，2025-08-12）
- JSON Schema 校验器：`colmugx/json-schema` 0.1.5（6668 下载）、`mizchi/jsonschema` 0.8.1（5291 下载）、`moonbitstack/moonschema` 0.2.4（1626 下载）、`Betterlol/moon_zod` 0.10.0（226 下载）等
- **判定：已有成熟包。**

#### C-7 Markdown lint / MDX / frontmatter CLI

- **Markdown lint：空白。** `lint` 50 条命中中，`moonbit-community/moongrep`（结构搜索/污点分析）、`668xin/modbus_lint`（Modbus 点表）、`spectacleCase/moonhadolint`（Dockerfile）、`moonbit-community/actionlint`（GitHub Actions）、`moonbit-community/bashcheck`（ShellCheck）、`Mr-Houjie/mbt-typeset`（中文排版校对）均不是 Markdown linter。在 `lint` / `markdown` 的命中范围内未发现 Markdown lint 包。
- **MDX：空白。** `mdx` 仅 2 条命中：`mizchi/markdown`（Markdown parser）与 `mizchi/syntree`（增量语法树/高亮），两者均未声称支持 MDX（JSX-in-Markdown）。
- **独立 frontmatter CLI（mdmeta 类）：空白。** `mdmeta` 0 条命中；`frontmatter` 28 条中，`moonrockz/mdc` 是库，`moonrockz/moonbase-mdc` 是库，`moonrockz/okf` 是 Open Knowledge Format bundle 读写，其余为 SSG/文档工具。未发现专门面向“提取/校验/重写 Markdown frontmatter”的独立命令行工具。

---

## 3. 方法论与局限

### 3.1 检索方法

1. **搜索 API**：`GET https://mooncakes.io/api/v0/search?kw=<keyword>&limit=50`
   - 网络：本机直连超时，全部请求经代理 `http://127.0.0.1:7892`
   - `limit=50` 生效；`page` / `offset` 无效（未使用）
   - 搜索范围：包名 + keywords + 自动摘要/描述，**不是全文索引**
   - 英文关键词有效；按给定配方，中文关键词系统性返回 0 条，本次未使用中文检索
   - 多词查询行为不一致：`mat file` 返回 0；`text splitter` 返回 4；`prompt injection` 返回 16 条（含大量间接匹配）。因此对多词子方向同时使用单词/近义词交叉检索
2. **详情 API**：`GET https://mooncakes.io/api/v0/modules/<owner>/<name>`
   - 提取 `latest_version`、`versions[]`、`build_status`、`metadata.created_at`、`metadata.repository`、`metadata.deps`、`dependents[]`
   - `metadata.created_at` 是**该版本**的发布时间，不是模块首次发布时间；已用多版本包（如 colmugx/mcp 34 个版本、created_at 2026-10-23；GitHub 仓库 2026-01-21 创建）交叉验证
3. **README**：`https://assets.mooncakes.io/assets/<owner>/<name>@<version>/resource.json` 的 `readme_content`
   - 命中率高；`houjie/rag-mbt@0.1.1` 返回 404（该版本无资源或已损坏）
4. **新包扫描**：`GET https://mooncakes.io/api/v0/modules?recent=60&new=60&popular=60`
   - 用于发现未被关键词命中的新包；确认 2026-11-01/04 发布的 HDF5、ORC 等包
5. **GitHub 交叉验证**：`GET https://api.github.com/repos/<owner>/<repo>`（经同一代理）
   - 仅用于维护强度：stars、created_at、pushed_at、archived、open_issues
   - 不代表代码质量或功能完整性

### 3.2 检索词与命中数

**方向 A（11 个主关键词 + 补充）**

| 关键词 | 命中 | 关键词 | 命中 |
|---|---:|---|---:|
| fits | 6 | hdf5 | 2 |
| netcdf | 1 | mat file | 0 |
| matlab | 1 | zarr | 2 |
| npy | 3 | npz | 3 |
| parquet | 12 | scientific data | 14 |
| binary format | 50 | hdf | 2 |
| mat | 50 | numpy | 7 |
| arrow | 27 | avro | 5 |
| orc | 50 | tiff | 7 |
| protobuf | 26 | columnar | 14 |
| scientific | 24 | | |

**方向 B（10 个主关键词 + 补充）**

| 关键词 | 命中 | 关键词 | 命中 |
|---|---:|---|---:|
| mcp | 50 | model context protocol | 50 |
| openai | 50 | anthropic | 20 |
| llm | 50 | chat completion | 25 |
| rag | 16 | agent | 50 |
| tool calling | 28 | embedding | 50 |
| deepseek | 16 | gemini | 7 |
| ollama | 2 | prompt template | 13 |

**方向 C（8 个主关键词 + 补充）**

| 关键词 | 命中 | 关键词 | 命中 |
|---|---:|---|---:|
| markdown | 50 | frontmatter | 28 |
| yaml | 50 | toml | 50 |
| config | 50 | cli | 50 |
| command line | 50 | argument parser | 50 |
| argparse | 50 | mdmeta | 0 |
| front matter | 45 | mdx | 2 |
| lint | 50 | dotenv | 11 |
| json schema | 50 | metadata | 50 |

**补充：RAG / 安全（17 个关键词）**

| 关键词 | 命中 | 关键词 | 命中 |
|---|---:|---|---:|
| bm25 | 6 | tf-idf | 2 |
| retrieval | 50 | retriever | 50 |
| chunking | 14 | text splitter | 4 |
| rerank | 3 | reranking | 34 |
| vector search | 36 | semantic search | 23 |
| knowledge base | 10 | provenance | 38 |
| trust score | 12 | conflict detection | 30 |
| prompt injection | 16 | guardrail | 8 |
| rag evaluation | 3 | jailbreak | 0 |
| injection | 50 | moderation | 8 |
| prompt safety | 4 | pii | 5 |
| adversarial | 4 | red team | 1 |
| content safety | 34 | llm guard | 3 |

**补充：护栏 / lint 交叉验证（6 个关键词）**

| 关键词 | 命中 | 说明 |
|---|---:|---|
| cross encoder | 27 | 无 cross-encoder 重排器；命中为图像/其他域噪声 |
| prompt firewall | 1 | 无关匹配（bobzhang/games） |
| toxicity | 0 | — |
| markdownlint | 6 | 命中为 MoUI Markdown 编辑器、markitdown 等，无 Markdown linter |
| mdlint | 0 | — |
| llm guard | 3 | 1 个动作白名单护栏（bodymate），2 个无关 |

### 3.3 局限

1. **搜索不是全文索引。** 只匹配包名、keywords、自动摘要；README 正文中的能力声明不会被检索到。例如 `moonjrpc` 的 keywords 含 `mcp`，但 README 明确它不是 MCP SDK。本报告对关键包优先核对 README；注册表 README 为空或缺失时（如 `mizchi/llm`、`bobzhang/toml`），使用注册表描述并明确标注。
2. **`limit=50` 截断。** 高频词（`mcp`、`llm`、`markdown`、`cli`、`config` 等）均有 50 条上限，可能存在未展示的相关包。已用 60 条 `recent/new/popular` 新包扫描作为补充，但仍非全量枚举。
3. **多词查询语义不稳定。** `mat file` 0 条、`text splitter` 4 条、`prompt injection` 16 条间接匹配。对多词子方向使用了单词/近义词交叉检索，但仍可能漏检只以短语形式描述的包。
4. **下载量是累计值，不是活跃使用量。** 高下载可能来自 CI、镜像或历史依赖；低下载不代表功能弱（例如单版本新包）。本报告把下载量与版本数、GitHub push 时间并列，避免单一指标误判。
5. **`build_status` 只反映注册表构建结果。** `success` 不等于功能正确或测试充分；`legacy` 表示旧构建体系，不代表不可用，但说明维护停滞。
6. **`metadata.created_at` 是版本发布时间。** 本报告统一标注为“最新版本发布”，不是模块首次发布；对单版本包两者相同。
7. **GitHub 仓库与 mooncakes 包并非一一对应。** 部分包（如 `mizchi/llm`）README 在注册表为空，只能从源码目录推断覆盖范围；部分包仓库无 README 或无 description（`mizchi/llm` 的 GitHub description 为 null）。
8. **“空白”是注册表供给范围内的空白。** 未发布到 mooncakes 的 GitHub 项目、私有项目、以及仅存在于工具链内置的 package（如 `moonbitlang/core/argparse`）不会被 `/api/v0/search` 命中。本报告对标准库包单独用 GitHub 目录与 README 核实。
9. **未做代码级验证。** 本报告只核对注册表元数据与 README 声称的覆盖范围，未克隆仓库、未运行测试、未验证 API 行为；README 的“声称”可能与实现有差距（例如 `houjie/rag-mbt` 声称 6 模块但 build_status 为 failed）。
10. **日期口径。** 所有“最近更新”截至 2026-11-06；GitHub `pushed_at` 与注册表版本发布时间可能相差数日（发布前可能有未发版的 commit）。

### 3.4 复现命令

```bash
# 搜索（经代理）
curl -s -x http://127.0.0.1:7892 \
  --get --data-urlencode "kw=mcp" --data-urlencode "limit=50" \
  "https://mooncakes.io/api/v0/search"

# 详情
curl -s -x http://127.0.0.1:7892 \
  "https://mooncakes.io/api/v0/modules/colmugx/mcp"

# README
curl -s -x http://127.0.0.1:7892 \
  "https://assets.mooncakes.io/assets/colmugx/mcp@0.18.2/resource.json" \
  | jq -r '.readme_content'

# 新包扫描
curl -s -x http://127.0.0.1:7892 \
  "https://mooncakes.io/api/v0/modules?recent=60&new=60&popular=60"

# GitHub 维护强度
curl -s -x http://127.0.0.1:7892 \
  "https://api.github.com/repos/colmugx/mcp.mbt" \
  | jq '{stars:.stargazers_count,created:.created_at,pushed:.pushed_at,archived:.archived}'
```

---

## 附：本报告使用的一手证据文件

原始响应保存在同级目录 `_dedup_raw/`：

- `kw_A__*.json`：方向 A 的 11 个主关键词 + `mat` / `numpy` / `zip` / `scientific` / `columnar` 补充检索
- `kw_B__*.json`：方向 B 的 10 个主关键词
- `kw_C__*.json`：方向 C 的 8 个主关键词 + `argparse` / `core`
- `kw_X__*.json`：相邻格式补充（arrow/avro/orc/tiff/hdf/protobuf 等）
- `kw_Y__*.json`：RAG 组件补充（bm25/tf-idf/retrieval/retriever/chunking/text splitter/rerank/reranking/vector search/semantic search/knowledge base/provenance/trust score/conflict detection/prompt injection/guardrail/rag evaluation）
- `kw_Z__*.json`：安全补充（injection/jailbreak/prompt safety/moderation/content safety/pii/red team/adversarial）
- `kw_W__*.json`：护栏 / lint 交叉验证（cross encoder/llm guard/prompt firewall/content filter/toxicity/markdownlint/mdlint）
- `mod/*.json`：100 个候选包的详情响应
- `readme/*.json`：44 个关键包的 README 资源
- `gh/*.json`：25 个 GitHub 仓库的维护强度数据
- `kw_*.json`：86 个检索响应
- `all_hits.tsv`：全部检索命中去重后的聚合表（1068 行）
