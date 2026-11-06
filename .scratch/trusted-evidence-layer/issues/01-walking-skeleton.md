# 01 — 走通骨架：候选块契约 → 报告 → CLI → CI

**What to build:** 开发者能用一组 fixture 运行 `scan`，得到按检索分数排序的合法 JSON 报告；库在 native / wasm-gc / js 上可检查，CI 跑通 check + test + fmt。

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] 候选块契约可 JSON 序列化：id、文本、来源元数据、检索分数、可选原文区间
- [x] `scan` 读取 fixture、写出报告；报告含 query、配置快照、排序后的证据、诊断信息
- [x] 相同输入两次运行输出字节一致
- [x] 空候选、单候选、重复 id 均有确定行为
- [x] 库在 native / wasm-gc / js 三个目标上通过 `moon check`
- [x] CI 运行 check + test + fmt，全部通过
- [x] README 骨架存在：一句话定位、安装方式、最小示例

## Answer

### 结构分层（供后续 ticket 复用）

- `src/` — 纯库（scan 核心），只依赖 `moonbitlang/core` JSON 编解码，可被任何后端 import（`ShunjunGu/moon-trust`）。
- `src/cli/` — 纯 CLI 逻辑（参数解析、错误文案、退出码映射，输入为字符串列表，不做 IO 库依赖）。
- `cmd/main/` — 薄壳，**native-only**（`#cfg`），全仓库唯一允许 `@fs` 的地方；`src/` 与 `src/cli/` 因此在 wasm-gc / js 上纯净可检查。
- 全部公共结构 `pub(all)` + `#derive(...)`；内部 `priv struct Entry`。

### 报告与确定性

- 报告 = `query + config 快照 + 按排序键升序的 evidence + diagnostics（candidate_count / duplicate_id_count / output_count / stages: ingest→dedupe→sort→topk）`，单一一行 JSON（`report.to_json().stringify()`）。
- 文件系统无关、不用墙钟/随机源，同一输入两次运行输出**字节一致**：

  ```
  _build\native\debug\build\cmd\main\main.exe scan hello tests\fixtures\multi.json  # ×2
  SHA256 = FDF5409E7BC5E9AC62D74DF68EF58C0A590237241F6A797E6A907501632E8EF0（两次完全一致）
  ```

- 空候选 / 单候选 / 重复 id 均确定：重复 id 记入 `duplicate_id_count` 并丢弃后见者；`--top-k 2` 在 canonical 排序后截断（`config:{top_k:2}`，`output_count:2`）。
- 排序/评分语义、冲突与重排 = 后续 ticket，本期只做分数升序的 canonical 序。

### CLI 契约（冻结）

- 用法：`moon-trust scan <query> <candidates.json> [--top-k N]`。
- 退出码：`0` 成功（stdout 打印报告 JSON）；`1` 用法错误**或**候选文件 JSON 结构不合法（如 `scan` 缺 query → `moon-trust: missing query` + usage）；`2` 文件打不开（`moon-trust: cannot open '…': no such file`）。stderr 恒为空，错误一律打在 stdout。

### 目标与测试

- `moon check --deny-warn` ×3 目标全 0；`moon test --target all`（含 wasm1）＝ `Total tests: 26, passed: 26, failed: 0`，wasm / wasm-gc / js / native 四后端一致。
- 测试全部黑盒、无文件系统依赖 → 三后端同一套文件原样跑通；fixture 共 5 个 JSON 在 `tests/fixtures/`。

### CI（`.github/workflows/ci.yml`）

- 矩阵 ubuntu/macos/windows-latest：官方安装脚本无参调用（均为 `latest`），Windows 先 `ilammy/msvc-dev-cmd@v1`（native 链接需要 vcvarsall），并显式 `Add-Content $env:GITHUB_PATH "$env:USERPROFILE\.moon\bin"`（Windows 安装器只写用户级 PATH，不即时生效）→ `moon update` → `moon check --deny-warn --target all` → `moon test --target all`。
- 独立 fmt job（ubuntu）：`moon fmt` + `git diff --exit-code`。

### 风险备忘

- **工具链漂移**：CI 安装 `latest`；`0.1.20261104` 是本地 nightly（CDN 上 `binaries|cores/0.1.20261104/*` 均为 403），无法 pin 到确切本地版本。后续若出现因工具链版本差异导致的编译失败，重新跑本地 `moon update` 对齐后修。
- 派生 `ToJson` 会省略 `None` 字段（未传 `--top-k` 时 `config:{}`）；Option 反解要求键**缺省**（显式 `null` 会失败）。后续若要把 `Option` 字段编出 `null`，需要手写 ToJson。
- `README.md` 已含定位一句话、安装两条、frozen 的 scan 最小示例（含字节一模一样的完整输出）、退出码表与纯库 import 说明。
