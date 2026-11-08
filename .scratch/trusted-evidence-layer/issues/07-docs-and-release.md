# 07 — 文档与发布

**What to build:** 包具备完整的使用文档、可运行示例与发布产物：读者能按 README 在几分钟内跑通，包可从 mooncakes 安装，CI 矩阵与覆盖率可见。

**Blocked by:** 06 — 验收演示

**Status:** resolved

- [x] README 含定位、安装、最小示例、评分规则、注入检测边界与误报/漏报说明
- [x] 至少两个可运行示例，CI 中执行
- [x] Apache-2.0 LICENSE、CHANGELOG、`.moonignore`
- [x] 包发布到 mooncakes，`moon add` 可用
- [x] CI 矩阵覆盖 native / wasm-gc / js（库）与 native（CLI）
- [x] 覆盖率报告生成，README 给出当前数值
- [x] 包名已对 mooncakes 查重，避开与 `MoonEvidence` 的语义冲突

## Answer

### 文档（README）

- 新增 CI badge、mooncakes 安装方式（`moon add ShunjunGu/moon-trust`）与源码安装方式。
- 新增「最小示例」：`examples/quickstart` 与 `examples/injection-triage` 的完整代码路径、真实命令与逐行输出。
- 新增「评分规则」：检索分归一化、trust 分项公式、risk factor、rerank 公式、默认权重与稳定排序键全部写明。
- 「误报与边界」更名为「误报与漏报边界」，把误报（安全文档被标记、普通祈使句）与漏报（同形字、跨块指令、无标记 base64、中英以外语种）分开说明。
- 新增「Coverage」：库口径 1239/1440（86.0%），含 `cmd/main` 与示例可执行包的全模块口径 1239/1542（80.4%）。
- 新增「版本与发布」：0.1.0、mooncakes 发布状态、查重记录、与 `starlittle/MoonEvidence` 的语义区分。

### 可运行示例

- `examples/quickstart`：三个候选块，展示高检索分但来源单薄的块被 trust 分压后；示例内自断言排名首尾，CI 运行即回归。
- `examples/injection-triage`：一个良性块 + 三个注入块，分别跑 `mark` 与 `drop`，打印逐条规则发现、隔离原因、`blocked=true` 与仅含良性块的上下文；自断言 1 保留 / 3 隔离。
- 两个示例均在 `moon check --target all` 下通过，并在 CI 的 native CLI job（Linux/macOS/Windows）逐台执行。

### 发布产物

- `LICENSE`：Apache-2.0 全文；`moon.mod` 声明 SPDX `Apache-2.0`。
- `CHANGELOG.md`：Keep a Changelog 格式，0.1.0 首次公开发布条目。
- `.moonignore`：排除 `AGENTS.md` / `CONTEXT.md` / `docs/` / `research/` / `.scratch/` / `.omc/` / 赛题整理文档；`moon package --list` 核对发布清单不含开发材料。
- `moon.mod` 升至 `0.1.0`，补 `repository` 与 `keywords`。

### mooncakes 与 `moon add`

- `moon publish` 成功：`ShunjunGu/moon-trust@0.1.0`；评审修正文档后发布 `0.1.1`（纯文档补丁），注册表 `build_status=success`。
- 在仓库外的临时模块中实测 `moon add ShunjunGu/moon-trust@0.1.0` 与 `@0.1.1` → 依赖解析、下载、`moon check --deny-warn`、`moon run app --target native` 全部通过。
- 查重（2026-11-08）：`GET /api/v0/modules/ShunjunGu/moon-trust` 发布前返回 404；`moon-trust` / `trust layer` / `trusted evidence` / `retrieval trust` / `evidence layer` 检索未发现同时覆盖风险扫描、信任评分、冲突检测与引用上下文组装的包。相邻包 `starlittle/MoonEvidence`（证据包校验）与 `cjyhjy/contextguard`（工具输出证据校验）均不实现本层；命名避开 `MoonEvidence` 语义冲突。

### CI 与覆盖率

- `.github/workflows/ci.yml`：
  - `library` job：`wasm` / `wasm-gc` / `js` / `native` 四目标矩阵，分别 `moon check --deny-warn` + `moon test`。
  - `native-cli` job：Linux / macOS / Windows 三 OS，native check/test、构建 CLI、运行两个示例、验证阻断扫描退出码 3、demo 双跑 diff。
  - `coverage` job：`moon coverage analyze` → `moon coverage report -f full_summary` + HTML，上传 `coverage` artifact。
  - `fmt` job 保持不变。
- 覆盖率实测：库 1239/1440（86.0%）；全模块 1239/1542（80.4%）。未覆盖部分为 native-only `cmd/main` shell 与两个示例可执行包，均由 CLI job 以二进制方式执行，而非进程内测试。
- `moon test --target all` 保持 125/125 × 四后端通过。
