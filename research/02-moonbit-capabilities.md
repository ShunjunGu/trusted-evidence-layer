# MoonBit 语言与工具链能力边界核查

- 核查日期：2026-11-06
- 版本基线：**moonc v0.10.19**（2026-11-05 发布，官方 release note 明确"对应 moonc 版本：v0.10.19"）
- 运行时库基线：`moonbitlang/async` **0.22.7**；`moonbit-community/rabbita` **0.17.0**
- 取证口径：优先 git 仓库源码 / 官方文档 markdown / 官方发布说明原文。文档路径以 `moonbitlang/moonbit-docs` 仓库为准（发布站 `www.moonbitlang.cn/docs/...` 与之同源）。凡出现 experimental / unstable / alpha 字样，均原样引用。
- 判定用词：**稳定** = 文档未标注实验性且已在标准库/正式发布中；**实验** = 文档或 release note 明示 experimental / unstable / alpha / "API 可能变化"；**缺失** = 在标准库与官方扩展库中均未找到。

---

## 1. 能力速查表

### A. 语言特性

| 能力 | 状态 | 一句话结论 | 来源 |
|---|---|---|---|
| `async` / 协程 | **实验** | 编译器已支持 `async fn` / `async fn main` / `async test`，采用 Kotlin 式协程 + 结构化并发；运行时 API **明确声明不稳定** | [async-experimental.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/async-experimental.md) |
| 真正并发 I/O | **实验（native 最强）** | `moonbitlang/async` 提供事件循环 + http/https、文件、socket、进程；native（Linux/macOS/Windows）完整支持，wasm1 实验性，**wasm-gc 不支持**，JS 仅无 I/O 部分 | [async README](https://github.com/moonbitlang/async) |
| C FFI | **稳定** | `extern "C" fn f(..) -> T = "symbol"`，C stub 走 `native-stub`，头文件 `moonbit.h` 位于 `~/.moon/include` | [ffi.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/ffi.md) |
| JS FFI | **稳定** | `extern "js" fn` 可内联 JS lambda（`#\|(d) => Math.cos(d)`），也可 `"Module" "func"` 导入 | 同上 |
| WASM 导入/导出 | **稳定** | `extern "wasm" fn` 内联 WAT，或 `"module" "name"` 导入；导出用 `#export_name` / `exports` | 同上 |
| 泛型 | **稳定** | 顶层函数与数据类型支持 `[T]` 类型参数 | [fundamentals.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/fundamentals.md) |
| Trait | **稳定（有 object-safety 限制）** | 支持 trait、默认实现、`extend`、trait object（`x as &I`）；object-safe 要求 `Self` 必须是方法第一参数且只出现一次 | [methods.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/methods.md) |
| 模式匹配 | **稳定** | 支持数组、bitstring、区间、Map、Json、or-pattern、guard | [fundamentals.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/fundamentals.md) |
| 错误处理 `raise`/`try` | **稳定** | `raise` 标注、`try/catch/noraise`、`raise?` 错误多态、`Result`、`defer`/`errdefer` | [error-handling.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/error-handling.md) |
| `derive` | **稳定（JSON 参数不稳定）** | 可 derive `Eq/Compare/Debug/Default/Hash/Arbitrary/Shrink/FromJson/ToJson`；JSON 序列化参数原文标注 unstable，且 `repr/case_repr/default/rename_all` 已废弃 | [derive.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/derive.md) |
| 宏 / 用户自定义代码生成 | **缺失** | 文档中无用户宏系统；"macro" 仅指类型别名宏（type macro）。代码生成靠外部工具（moonyacc / moonlex / protoc-gen-mbt） | 文档全文检索；[moonyacc](https://github.com/moonbitlang/moonyacc) |

### B. 标准库与生态

| 能力 | 状态 | 一句话结论 | 来源 |
|---|---|---|---|
| String / 字符 / 字节 | **稳定** | `String`、`StringView`、`Byte`、`Bytes`、`BytesView`、`FixedArray[Byte]` | core 包列表 |
| 集合 HashMap/HashSet | **稳定** | `core/hashmap`、`core/hashset`，另有 `sorted_map`/`sorted_set`/`priority_queue`/`deque`/`queue` | [core](https://github.com/moonbitlang/core) |
| JSON | **稳定** | `core/json`；`Json` 类型与 `ToJson` trait 已迁入该包（v0.10.19 变更） | [v0.10.19](https://www.moonbitlang.cn/updates/2026/11/05/index) |
| 正则 | **稳定（语法受限）** | 语言内建 `re"..."` / `reb"..."` 字面量、`=~`、`lexmatch`、`lexscan`；**不支持 lookahead/lookbehind/反向引用**，不支持 `\d \s \w` | fundamentals.md §Regex |
| 文件 I/O | **稳定** | `moonbitlang/x/fs`，native 走 `fs_native.c`/`file_native.c`，js / wasm / wasm-gc 各有实现 | [x/fs/moon.pkg](https://github.com/moonbitlang/x/blob/main/fs/moon.pkg) |
| 时间 | **稳定** | `moonbitlang/x/time`：Duration、PlainDate/Time、ZonedDateTime、时区（TZif 解析） | [x/time](https://github.com/moonbitlang/x/tree/main/time) |
| 网络 socket | **实验（仅在 async 内）** | `moonbitlang/async/socket` 提供 TCP/UDP/DNS；标准库 `x/sys` 只有 CLI 参数，**无同步 socket API** | async README |
| 加密 / 哈希 | **部分稳定** | `x/crypto`：MD4/MD5/SHA1/SHA2/SHA3(SM3)/RIPEMD160/HMAC/AES/ChaCha；`x/bcrypt`、`x/jwt`。**未发现 RSA/ECC 公钥原语** | [x/crypto](https://github.com/moonbitlang/x/tree/main/crypto) |
| 官方扩展库 `moonbitlang/x` | **实验包集合** | 仓库描述原文："experimental packages for moonbitlang/core"；含 fs/time/crypto/encoding/json5/decimal/num/path/rational/stack/sys/unicode/uuid/codec | [x](https://github.com/moonbitlang/x) |
| Rabbit-TEA（现名 rabbita） | **活跃第三方** | 已更名 `rabbita`，0.17.0，134 star，2026-11-02 仍在提交；Elm/Bonsai 风格，`Val[Html]` + `emit` + command | [rabbita](https://github.com/moonbit-community/rabbita) |
| HTTP 库 | **实验** | `moonbitlang/async/http`：client + server、HTTPS、CONNECT 代理；同时存在于 `core/async/http` | async README |
| 序列化 | **可用但分散** | `core/json` + derive；`protoc-gen-mbt`（Protobuf 生成器）；`x/json5`；社区 `moonpack`（二进制序列化） | 见各处链接 |
| 测试辅助 | **稳定** | `core/test`（快照/`@test.T`）、`core/quickcheck`（property-based）、`moon-cram`（CLI 测试，社区）、`moon testcli`（实验性） | [tests.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/tests.md) |

### C. 工具链

| 能力 | 状态 | 一句话结论 | 来源 |
|---|---|---|---|
| wasm-gc 后端 | **稳定** | 成熟后端，使用宿主 GC；但 **async 不支持 wasm-gc** | ffi.md / async README |
| js 后端 | **稳定（有破坏性变更预告）** | 可输出 CJS/ESM/IIFE；下个版本 `Array` 不再编译成 JS 原生数组 | ffi.md / v0.10.19 |
| native 后端 | **稳定** | C 后端 + 新 native 后端（v0.10.4 起 macOS ARM debug 默认新后端，x86-64 Linux 可用）；`moonbit.h` + `native-stub` 可调 C；**可直接读文件、开 socket（通过 x/fs 与 async）** | ffi.md |
| LLVM 后端 | **实验** | 原文："The backend is experimental and does not support FFIs." | ffi.md |
| 包管理 `moon.mod` | **稳定（已切换格式）** | 新格式 `moon.mod`；**`moon.mod.json` 已不再被普通工具链命令接受**，`moon fmt` 迁移 | [module.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/module.md) |
| 发布 `moon publish` | **稳定** | 先 `moon register`/`moon login`；模块名必须以用户名开头；版本遵循 SemVer；`.moonignore` 控制打包 | [commands.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/commands.md) |
| `moon test` | **稳定** | 默认按 CPU 并行；`--update` 更新快照；`--target all`；`--no-parallelize` 串行 | commands.md / v0.10.19 |
| 快照测试 | **稳定** | `inspect(x, content=...)`、`@json.inspect`、`@test.T::write/writeln`，产物落 `__snapshot__` | tests.md |
| 覆盖率 | **稳定** | `moon test --enable-coverage` + `moon coverage report`（summary/bisect/coveralls/cobertura/html） | [coverage.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/coverage.md) |
| 基准测试 | **稳定** | test block 带 `@bench.T`，`bench()` 自动迭代；`@bench.single_bench` 输出 JSON 统计 | [benchmarks.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/benchmarks.md) |
| `moon check` / `fmt` / `info` | **稳定** | `moon info` 生成 `.mbti` 接口；v0.10.19 起 `moon check` 也会自动生成 `pkg.generated.mbti`（`--no-mbti` 关闭） | commands.md / v0.10.19 |
| CI 模板 | **无官方 marketplace Action** | 官方仓库用仓库内 composite action，安装脚本 `curl -fsSL https://cli.moonbitlang.com/install/unix.sh \| bash`；社区有 `hustcer/setup-moonbit`（18 star，2026-11-02 更新） | [core stable-check.yml](https://github.com/moonbitlang/core/blob/main/.github/workflows/stable-check.yml)、[hustcer/setup-moonbit](https://github.com/hustcer/setup-moonbit) |
| Component Model / WIT | **可用（外部工具链）** | `wit-bindgen moonbit` + `wasm-tools component new`，目标 `--target wasm` | [component-model-tutorial.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/wasm/component-model-tutorial.md) |
| WASI | **未验证 / 仅 legacy 示例** | 文档仓库存在 `legacy/examples/wasi-http`（`moonbit-community/wasi-http`，`preferred_target = "wasm"`），位于 legacy 目录，未验证当前可构建 | [wasi-http](https://github.com/moonbitlang/moonbit-docs/tree/main/legacy/examples/wasi-http) |

---

## 2. 分区详述

## A. 语言特性

### A1. `async` / 协程

**已发布，但整体处于实验状态。**

- 语法形态：`async fn`、`async fn main`、`async test`；调用 async 函数无需 `await`，直接像普通函数调用，调用点即阻塞等待（类似 Kotlin 协程）。原文："Calling `async` function will result in the caller being blocked and waiting for the callee to return, similar to `await` in many other languages."
- 效果系统：async 函数默认隐式 `raise`，需要 `noraise` 显式声明不抛错；默认可取消，`nocancel` 声明不可取消。
- 并发模型：**结构化并发**。只能通过 `@async.with_task_group` 创建 task group，`spawn_bg` 派生任务；`with_task_group` 保证所有子任务终止后才返回，文档称"orphan tasks can never exist"。
- 稳定性标记（原文引用）：
  - 文档文件名即 `async-experimental.md`；
  - "The API of `moonbitlang/async` is not considered stable, and may change in the future."
  - async README："WARNING: this library is current experimental, API is subject to future change."
  - v0.10.19 release note：`moonbitlang/core/async` "仍是实验性的，其 API 仍在不断调整"，使用时必须在 `moon.pkg` 的 `options` 加 `"allow-experimental-packages": true`。
- 迁移状态：`moonbitlang/async` 将被 `moonbitlang/core/async` 取代；两者可同程序混用，`moonbitlang/async@0.22.7+` 兼容。
- 能否做真正的并发 I/O：**能，但分后端**。native（Linux/macOS/Windows，分别 epoll/kqueue/IOCP）完整支持 TCP/UDP、DNS、TLS、HTTP、WebSocket、文件、管道、进程、信号；wasm1 实验性且依赖最新 `moonrun`，不兼容其他 WASM runtime；**wasm-gc 明确未支持**；JS 后端只有与 IO 无关的 API（task group/timeout 等），IO API 不可用。

来源：[async-experimental.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/async-experimental.md)、[async README](https://github.com/moonbitlang/async)、[v0.10.19](https://www.moonbitlang.cn/updates/2026/11/05/index)

### A2. FFI

**三条路径都成熟，且是官方文档的正规能力。**

- **C FFI**
  - 声明：`extern "C" fn put_char(ch : UInt32) -> Unit = "function_name"`。
  - 外部类型：`#external type T` 在 C 后端映射为 `void*`。
  - 链接：`moon.pkg` 里 `options("link": {"native": {"cc-link-flags": "-l<lib>"}})`；C stub 文件用 `options("native-stub": ["x.c"])` 声明。
  - 头文件：`#include "moonbit.h"`，位置 `~/.moon/include`，提供 `moonbit_make_external_object`、`moonbit_incref/decref`、`moonbit_bytes_t` 等。
  - 生命周期：Wasm/C 后端用引用计数；默认 owned 调用约定，可用 `#borrow` / `#owned` 调整（文档警告正在把默认语义从 `#owned` 迁移到 `#borrow`）。
  - 限制：不支持多态外部函数；`struct`/`enum`（带 payload）的布局"currently unstable"。
- **JS FFI**
  - 两种写法：`fn cos(d : Double) -> Double = "Math" "cos"`（映射 `Math.cos`），或 `extern "js" fn cos(d: Double) -> Double = #\|(d) => Math.cos(d)`。
  - 类型映射：`Bool→boolean`、数值→`number`、`String→string`、`FixedArray[Byte]/Bytes→Uint8Array`、`FixedArray[T]→T[]`、`FuncRef[T]→Function`。
  - 注意：`Array[T]` 用作 JS FFI 签名已废弃，改用 `FixedArray[T]`。
- **WASM 导入/导出**
  - 导入：`fn cos(d : Double) -> Double = "math" "cos"`（模块名 + 函数名），或 `extern "wasm" fn ... = #\|(func (param f64) (result f64))`。
  - 导出：`#export_name("add")` 加在 `pub fn` 上，配合 `pkgtype(kind: "foreign_library")`；也可用 `options("link": {"<backend>": {"exports": ["add","fib:test"]}})`。
  - v0.10.19 新增：native 后端可构建**静态链接库**（`.a` / Windows `.lib`），宿主需先调 `moonbit_init()`。
  - 限制原文："The native backend does not currently support exporting a `foreign_library` package as a linkable library artifact, including shared libraries such as a `.dll` or `.so`."（即只支持静态库，不支持动态库）

来源：[ffi.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/ffi.md)、[v0.10.19](https://www.moonbitlang.cn/updates/2026/11/05/index)

### A3. 泛型、trait、模式匹配、错误处理

- **泛型**：顶层函数与数据类型支持类型参数。文档示例覆盖 `List[T]`、`map`、`reduce`。未发现高阶类型/HKT。
- **Trait**：支持 trait 定义、默认方法、`impl`、`extend` 把 trait 方法挂成方法式 API、trait object。**object-safety 约束**：`Self` 必须是方法第一个参数，且方法类型中 `Self` 只能出现一次——这意味着泛型参数里含 `Self` 的方法不能做 trait object。
- **内置 trait**：`Eq`、`Compare : Eq`、`Hash`、`Show`、`Default`。
- **模式匹配**：除常规 struct/enum 外，支持数组模式、bitstring 模式、区间模式、Map 模式、**Json 模式**、or-pattern 默认绑定、guard。匹配是穷尽性检查的。
- **错误处理**：`Error` 为广义错误类型；具体错误类型自动提升；`try { } catch { } noraise { }`；`raise?` 做错误多态（如 `Array::map` 可保留"是否抛错"）；`defer` / `errdefer` 做清理。
- **已知限制（有文档依据的）**：
  - 不能为 type alias 定义新方法或实现 trait（"one cannot define new methods or implement traits for a type alias"）。
  - 自定义构造器（custom constructor）不能用于模式匹配。
  - trait object 的 object-safety 限制（见上）。
  - FFI 不支持多态外部函数。

来源：[fundamentals.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/fundamentals.md)、[methods.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/methods.md)、[error-handling.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/error-handling.md)

### A4. 宏 / 代码生成

**没有用户可写的宏系统。**

- 文档全文检索 "macro" 只有两处：类型别名被描述为 "merely a type macro"；`moon.pkg` 的编译 flag 可 `-D` 定义 C 宏。均非语言级宏。
- 现有的代码生成能力分两类：
  1. **编译器内建 derive**：`#derive(Eq, Compare, Debug, Default, Hash, Arbitrary, Shrink, FromJson, ToJson)`，只能生成固定 trait，不可扩展。
  2. **外部生成器**（先用宿主语言写生成器，再输出 `.mbt`）：
     - `moonyacc`：LR(1) parser generator，仓库含 `lr1/`、`codegen/`、`elab/`，输出 MoonBit 代码；
     - `moonlex`：lexer 生成器（另有 `moonlex-runtime`）；
     - `protoc-gen-mbt`：Protobuf 生成器；
     - `wit-bindgen`：WIT → MoonBit 绑定；
     - `typst.mbt` 的 PLAN 也明确写道 `typst-macros`（`#[elem]`×167、`#[func]`×298）"**codegen** ... so we need a generator"。
- 结论：解析器生成、derive 类需求**可以**通过外部代码生成器实现（已有先例），但**不能**在 MoonBit 语言内写过程宏/属性宏。

来源：文档检索；[moonyacc](https://github.com/moonbitlang/moonyacc)、[moonlex](https://github.com/moonbitlang/moonlex)、[protoc-gen-mbt](https://github.com/moonbitlang/protoc-gen-mbt)、[typst.mbt PLAN.md](https://github.com/moonbitlang/typst.mbt/blob/main/PLAN.md)

---

## B. 标准库与生态基础库

### B5. 标准库覆盖

`moonbitlang/core` 顶层包（仓库目录实测）：
`abort archive argparse array async bench bigint bool buffer builtin byte bytes char cmp compress coverage debug deque diff double encoding env error float hashmap hashset immut int int16 int64 internal json lazy lazy_list lexbuf list math option path prelude priority_queue queue quickcheck random range ref result set sorted_map sorted_set strconv string test tuple uint uint16 uint64 unit v128`

| 需求 | 是否有 | 说明 |
|---|---|---|
| 字符串 | 有 | `core/string`、`StringView`；`core/strconv`、`core/encoding/utf8` |
| 集合 | 有 | `hashmap`、`hashset`、`sorted_map`、`sorted_set`、`priority_queue`、`deque`、`queue`、`list`、`lazy_list` |
| JSON | 有 | `core/json`；`Json` 类型 + `ToJson`；`derive(FromJson/ToJson)`；Json 模式匹配 |
| 正则 | 有（语言级） | `re"..."` / `reb"..."` + `=~` + `lexmatch` + `lexscan`；**无 lookaround/backreference**，不支持 `\d \s \w`，POSIX 字符类仅 ASCII |
| 文件 I/O | 有（x） | `moonbitlang/x/fs`；native/js/wasm/wasm-gc 均有实现 |
| 时间 | 有（x） | `x/time`，含 TZif 时区库；系统时区读取仅 native 与 js |
| 网络 socket | 有（仅 async） | `moonbitlang/async/socket`（TCP/UDP/DNS）；**core 与 x 中没有同步 socket** |
| 加密/哈希 | 部分 | `x/crypto` 有对称加密与哈希；`Hash` trait 只是哈希表用的哈希，不是密码学哈希；未发现 RSA/ECC |
| 压缩/归档 | 有（v0.10.19 新增） | `core/compress`：raw DEFLATE、gzip、zlib；`core/archive/zip`：ZIP/ZIP64 |
| 路径 | 有（v0.10.19 新增） | `core/path`，支持 `/` 运算符拼接 |

来源：[core](https://github.com/moonbitlang/core)、[x](https://github.com/moonbitlang/x)、[v0.10.19](https://www.moonbitlang.cn/updates/2026/11/05/index)、fundamentals.md §Regex

### B6. `moonbitlang/x`

仓库自我描述原文："**experimental packages for moonbitlang/core**"。

实际包目录：`bcrypt`、`codec`（base64）、`crypto`、`decimal`、`encoding`（percent 等）、`fs`、`json5`、`jwt`、`num`、`path`、`rational`、`stack`、`sys`、`time`、`unicode`、`uuid`。

注意事项：
- `x/sys` 的 `get_cli_args()` 已标记 `#deprecated`，官方要求改用 `moonbitlang/core/env` 的 `@env.args()`。
- `x/path` 的能力已被 `core/path` 吸收（v0.10.19 把 path 合入标准库）。
- `x/crypto` 提供的是原语，不含 TLS 协议栈；TLS 在 `async/tls`（native 走 OpenSSL，仓库内有 `openssl.c` 与 Windows 的 `schannel.c`）。

来源：[x](https://github.com/moonbitlang/x)、[x/sys/sys.mbt](https://github.com/moonbitlang/x/blob/main/sys/sys.mbt)

### B7. Rabbit-TEA（rabbita）

- **已改名**：README 原文 "This project was previously named `Rabbit-TEA` and is now renamed to `rabbita`."
- 仓库：`moonbit-community/rabbita`，134 star，Apache-2.0，最后提交 **2026-11-02**，**活跃**。
- 版本：`0.17.0`，已发布到 mooncakes（`mooncakes.io/api/v0/modules/moonbit-community/rabbita` 返回 0.17.0）。
- 目标后端：`preferred_target = "js"`，`supported_targets = "js+native+wasm"`，依赖 `moonbitlang/async@0.22.4`。
- API 形态（README 示例）：
  - `fn counter() -> Val[Html]`，`Val` 是"状态 + 视图"的组合；
  - `@rabbita.create_pure_state(0, update=fn(count, msg) { ... })` 返回 `(count, emit)`；
  - 视图用 `@html` 的 `div/button/h1` 组合，`on_click=emit(Inc)`；
  - 用 `warren` CLI 起项目：`moon install moonbit-community/warren` → `warren new my-project` → `warren dev --browser-entry main`。
- 体积自述：~15 KB min+gzip（含标准库，DCE 由 moonc）。

来源：[rabbita](https://github.com/moonbit-community/rabbita)

### B8. HTTP / 网络 / 序列化 / 测试辅助

- **HTTP**：`moonbitlang/async/http`（及 `moonbitlang/core/async/http`）——client + server、HTTPS、`CONNECT` 代理；`async/websocket` 支持 `wss://`。
- **网络**：`async/socket`（TCP/UDP/DNS）、`async/tls`（OpenSSL；Windows 另有 schannel 实现文件）、`async/pipe`、`async/process`、`async/shell`、`async/signal`。
- **序列化**：
  - JSON：`core/json` + `derive(FromJson/ToJson)`（注意 JSON derive 参数不稳定）；
  - Protobuf：`protoc-gen-mbt`（13 star，2026-10-29 更新）；
  - JSON5：`x/json5`；
  - 二进制：`core/buffer`（含 sleb128/uleb128）、`Bytes`/`FixedArray[Byte]`；社区 `001-Elsa/moonpack`。
- **测试辅助**：`core/test`、`core/quickcheck`（内置 property-based，无需额外依赖）、`moon-cram`（CLI 应用测试，Rust 工具，1 star）、`moon testcli`（v0.10.19 新增，**实验性**，用于替代 cram）。
- **已有第三方参考实现**：`gmlewis/moonbit-jsonrpc2`（JSON-RPC 2.0 抽象，1 star，2026-08-11 最后提交，**低成熟度**）。

来源：[async README](https://github.com/moonbitlang/async)、[protoc-gen-mbt](https://github.com/moonbitlang/protoc-gen-mbt)、[moonbit-jsonrpc2](https://github.com/gmlewis/moonbit-jsonrpc2)、[tests.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/tests.md)

---

## C. 工具链

### C9. 后端目标成熟度与 I/O 能力

| 后端 | 成熟度 | I/O 能力 |
|---|---|---|
| **wasm**（Wasm1） | 稳定 | 自身无 I/O，全靠 host import（`spectest.print_char` 等）。`async` 的 wasm1 支持是**实验性**，需最新 `moonrun`，不兼容其他 WASM runtime；不支持 `@websocket`、`@fs.Watcher`、`@fs.realpath` |
| **wasm-gc** | 稳定 | 宿主 GC；`println` 依赖 host import；**async 明确未支持 wasm-gc** |
| **js** | 稳定 | 可调 Web API / Node API（经 FFI）；`async` 只提供无 I/O 的 API + Promise 互操作（`js_async`） |
| **native** | 稳定 | **能直接读文件、开 socket**：文件走 `x/fs`（C stub），socket/TCP/UDP/TLS/HTTP 走 `async`；也可自由 C FFI |
| **LLVM** | 实验 | 原文："experimental and does not support FFIs" |

native 的两个实现：C 后端（成熟，release 默认）与新 native 后端（v0.10.4 起 macOS Apple Silicon 的 debug 默认；x86-64 Linux 可用；`MOONBIT_NEW_NATIVE=0/1` 切换）。native 目前可产出**静态库** `.a`/`.lib`，但**不能**产出 `.so`/`.dll`。

来源：[ffi.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/ffi.md)、[async README](https://github.com/moonbitlang/async)

### C10. 包管理与发布

**当前格式是 `moon.mod`，不是 `moon.mod.json`。** v0.10.19 原文："配置格式不再接受 JSON 清单"；module.md 原文："`moon.mod.json` is no longer accepted by ordinary toolchain commands. Run `moon fmt` to migrate".

`moon.mod` 关键字段（实测自 `moonbitlang/async/moon.mod` 与 `moonbit-community/rabbita/moon.mod`）：

```
name = "moonbitlang/async"        // 必填；发布到 mooncakes 必须以用户名开头
version = "0.22.7"                // 可选；发布时须符合 SemVer 2.0.0
readme = "README.md"
repository = "https://github.com/moonbitlang/async"
license = "Apache-2.0"            // 须为 SPDX 标识
keywords = [ ]
description = "..."
preferred_target = "native"       // js / wasm / wasm-gc / native / llvm
supported_targets = "js+native+wasm"
source = "src"
import {                          // 依赖声明（旧格式为 deps 字段）
  "moonbitlang/x@0.4.6"
}
```

- 依赖：`moon add moonbitlang/async@0.20.2` 自动写入 `import { ... }`；本地依赖推荐用 `moon.work` 的 `members`；`@version` 在本地覆盖时被忽略。
- 包级配置 `moon.pkg`：
  - `import { "path/to/pkg", "path/to/pkg2" @alias }`；
  - `import { ... } for "test"`（黑盒测试）、`for "wbtest"`（白盒测试）；
  - `pkgtype(kind: "executable" | "foreign_library")`；
  - `options("native-stub": [...], "link": {...}, "allow-experimental-packages": true, targets: {...})`；
  - 条件导入用 `#cfg(target = "native")` 加在 `import` 前（v0.10.19 新增）。
- 发布流程：`moon register`（注册）或 `moon login`（登录）→ `moon publish`。打包内容由 `.moonignore`（gitignore 风格）控制，`_build/` 永远排除；`include`/`exclude` 字段已废弃。
- 主版本路径：v0.10.19 支持 `owner/library/v{n}` 作为新主版本路径；但"语言 1.0 以前暂不支持发布版本 1.0 及以上的包"。

来源：[module.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/module.md)、[package.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/package.md)、[commands.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/commands.md)、[v0.10.19](https://www.moonbitlang.cn/updates/2026/11/05/index)

### C11. 测试

- `moon test`：支持 `-p/--package`、`-f/--file`、`-i/--index`、`-u/--update`、`--target all`、`--enable-coverage`、`--doc`（文档测试）。
- 测试块：`test { ... }`，本质是 `() -> Unit raise Error`；测试名以 `"panic"` 开头表示期望 panic。
- 快照测试三种：
  1. `inspect(x, content=...)`（基于 `Show`）；
  2. `@json.inspect(x, content=...)`（基于 `ToJson`，可格式化）；
  3. `@test.T::write` / `writeln` / `snapshot`（任意输出，落 `__snapshot__/`）。
  全部可用 `moon test --update` 自动写入/更新。
- Property-based：`core/quickcheck`，`check` / `report`，需要 `Arbitrary` + `Shrink` + `Debug`；可设 `count`、`seed`、`max_shrinks`。
- 黑盒/白盒：`_test.mbt` 只可见 public；`_wbtest.mbt` 可见包内全部。
- 覆盖率：**分支覆盖**，`moon coverage report -f summary|bisect|coveralls|cobertura|html`，支持 `--send-to coveralls`；`#coverage.skip` 可跳过函数。
- 基准：`@bench.T::bench`、`@bench.T::keep`（防优化）、`@bench.single_bench`（返回可序列化 `Summary`，稳定性不保证）。
- 并行：v0.10.19 起 `moon test` 默认按 CPU 并行；`--no-parallelize` 串行执行测试程序（不影响包内 `async test` 的并行）。

来源：[tests.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/tests.md)、[coverage.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/coverage.md)、[benchmarks.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/benchmarks.md)、[commands.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/commands.md)

### C12. 工程命令

`moon` 子命令全集（commands.md）：`new`、`build`、`check`、`run`、`test`、`clean`、`fmt`、`doc`、`info`、`bench`、`add`、`remove`、`install`、`tree`、`login`、`register`、`publish`、`package`、`update`、`coverage`、`generate-build-matrix`、`upgrade`、`shell-completion`、`version`。

关键点：
- `moon check`：类型检查；v0.10.19 起成功后自动为本地包生成 `pkg.generated.mbti`，`--no-mbti` 可关闭；`--deny-warn` 把警告当错误。
- `moon fmt`：格式化；`--check` 只检查不改；同时是 `moon.mod.json` → `moon.mod` 的迁移入口。
- `moon info`：为所有包生成 `.mbti` 公共接口文件。
- `moon doc`：生成文档或起本地服务器（`--serve`，默认 `127.0.0.1:3000`）。
- `moon bench`：跑基准。
- `moon run`：可直接跑 `.mbt` 单文件或包；`moonx` 只支持运行 wasm 程序。
- `moon install`：v0.10.19 起**不再**是依赖同步指令；`bin-deps` 已移除。

来源：[commands.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/commands.md)、[v0.10.19](https://www.moonbitlang.cn/updates/2026/11/05/index)

### C13. CI

- **没有官方发布的 GitHub Marketplace Action**。官方仓库（core、moonbit-docs）用的是**仓库内 composite action**：`.github/actions/setup/action.yml`，内容为：
  - *nix：`curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s "<channel>"`，把 `$HOME/.moon/bin` 加入 `GITHUB_PATH`；
  - Windows：`irm https://cli.moonbitlang.com/install/powershell.ps1 | iex`，并装 MSVC（`ilammy/msvc-dev-cmd@v1`）；
  - 最后 `moon update` 更新 registry。
- **社区 Action**：`hustcer/setup-moonbit`（"A Github Action to setup a MoonBit environment for you"，18 star，2026-11-02 更新）；另有 `moonbit-community/setup-moonbit`（2 star，2026-04 后未更新）。
- 官方 CI 矩阵写法可参考 `moonbitlang/core/.github/workflows/stable-check.yml`：`os: [ubuntu-latest, macos-latest, windows-latest]`，步骤为 `moon check --deny-warn --target all`，再 test。
- **存疑**：某社区仓库使用 `uses: moonbitlang/setup-moonbit@v1`，但该仓库在 GitHub API 与 raw 上均返回 404，**未能确认存在**。若照抄会失败，应改用上面的安装脚本或 `hustcer/setup-moonbit`。

来源：[core stable-check.yml](https://github.com/moonbitlang/core/blob/main/.github/workflows/stable-check.yml)、[moonbit-docs .github/actions/setup](https://github.com/moonbitlang/moonbit-docs/blob/main/.github/actions/setup/action.yml)、[hustcer/setup-moonbit](https://github.com/hustcer/setup-moonbit)

---

## D. 五个候选的技术阻塞点

> 以下只列依赖项与该项能力的真实现状，不做主观打分。

### D1. MQTT 5.0 异步客户端（依赖 async + TCP socket + TLS）

1. **async**：已发布但**实验**；`moonbitlang/async` 0.22.7 正在向 `moonbitlang/core/async` 迁移，后者需 `"allow-experimental-packages": true`，且 "API 仍在不断调整"。协议实现若基于旧库，未来需迁移。
2. **TCP socket**：`moonbitlang/async/socket` 有 TCP/UDP/DNS，native 完整、wasm1 实验、**wasm-gc 无**、JS 无 IO。MQTT 只能选 native（或 wasm1 + moonrun）。
3. **TLS**：`async/tls` 在 native 走 **OpenSSL**（仓库内有 `openssl.c`），Windows 另有 `schannel.c`；意味着部署环境需满足 OpenSSL/系统 TLS 依赖；wasm/js 路径不可用。
4. **协议层缺口**：仓库与 GitHub 上**未发现任何 MoonBit MQTT 库**（`gh search repos "mqtt moonbit"` 无结果）；MQTT 5.0 的属性 TLV、QoS2 状态机、会话持久化、主题匹配全部需手写。
5. **可复用的基础设施**：二进制编解码有 `Bytes`/`FixedArray[Byte]`/`core/buffer`（含 uleb128/sleb128）；并发原语有 task group、`with_timeout`、取消、`aqueue`、`semaphore`、`cond_var`，可直接支撑重连/超时/背压。
6. **综合阻塞点**：语言与运行时能力**齐备**，阻塞在于"async API 不稳定 + TLS 依赖宿主 + 无现成 MQTT 协议实现"。

来源：[async README](https://github.com/moonbitlang/async)、[async-experimental.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/async-experimental.md)、[v0.10.19](https://www.moonbitlang.cn/updates/2026/11/05/index)

### D2. Apache Arrow 列式内存库（依赖二进制读写 + 内存布局控制）

1. **二进制读写**：有 `Bytes`/`BytesView`/`FixedArray[Byte]`，C 后端分别映射 `uint8_t*`/`T*`；`core/buffer` 提供 growable buffer 与 sleb128/uleb128。
2. **内存布局控制**：FFI 文档原文 "The layout of `struct`/`enum` with payload is currently unstable"——**没有稳定的结构体内存布局**，也没有 `#[repr(C)]` 一类保证；Arrow 要求的定长布局、8/16/64 字节对齐、validity bitmap 必须全部在字节数组上手工管理，不能靠 struct 直排。
3. **大小端**：core 的 `int64`/`buffer` 中**未发现** `to_be_bytes`/`from_le_bytes` 一类 API（检索结果为空），大小端转换需用位运算手写；这属于"未穷举"而非"确认不存在"。
4. **零拷贝/切片**：`BytesView`、`StringView`、`ArrayView` 存在，可做视图；但 Arrow 的 buffer 复用、对齐分配、引用计数生命周期需自行设计。
5. **SIMD**：core 有 `v128` 包，但未验证其 API 完整度，也未验证能否用于 Arrow 的向量化计算。
6. **综合阻塞点**：**不是"能不能读写字节"的问题，而是"没有稳定内存布局 + 无对齐/端序基础设施"**；可行路径是纯 `FixedArray[Byte]` + 手工偏移，代价是所有 schema/offset/bitmap 逻辑自写。

来源：[ffi.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/ffi.md)、[core](https://github.com/moonbitlang/core)、[fundamentals.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/fundamentals.md)

### D3. LSP 语言服务器框架（依赖 JSON-RPC + stdio/IO + JSON）

1. **JSON**：`core/json` 成熟，`Json` 类型 + `derive(FromJson/ToJson)` 可用；但 JSON derive 的**参数行为原文标注 unstable**，且 enum 序列化需显式选 `style="legacy"|"flat"`——JSON-RPC 的 `id` 可为 number/string/null，`params` 可为 object/array，需手写 `Json` 分支。
2. **JSON-RPC 2.0**：**无官方库**；社区只有 `gmlewis/moonbit-jsonrpc2`（1 star，2026-08-11），成熟度低；GitHub 搜索 "moonbit lsp language server" **无结果**，即无现成 LSP 框架/类型定义。
3. **stdio**：`moonbitlang/async/stdio` 提供标准输入输出通道，native 可用；LSP 的 stdin/stdout 帧解析（`Content-Length` 头）需自写。**wasm-gc 不支持 async**，因此 LSP 只能走 native 或 JS（Node）。
4. **并发/取消**：async 的 task group + 默认取消 + `with_timeout` 可支撑 `$/cancelRequest` 语义；`@fs.Watcher` 可用于 `workspace/didChangeWatchedFiles`，但 **Wasm1 后端不支持 `@fs.Watcher`**。
5. **解析器**：`moonbitlang/parser` 是 MoonBit 官方用 MoonBit 写的 MoonBit 解析器（含 lexer/syntax/untyped_cst/mbti/yacc_parser），可作为"用 MoonBit 写语言前端"的可行性证据；`moonyacc` 可生成 LR(1) 解析器。
6. **综合阻塞点**：底层 IO/JSON/并发**齐备**，缺的是 **LSP 协议层与 JSON-RPC 框架**（需自写），以及 async 的实验性 API 风险。

来源：[async README](https://github.com/moonbitlang/async)、[moonbit-jsonrpc2](https://github.com/gmlewis/moonbit-jsonrpc2)、[moonbitlang/parser](https://github.com/moonbitlang/parser)、[derive.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/language/derive.md)

### D4. Typst 渲染子集（依赖排版/字体/PDF 输出）

1. **关键事实：官方组织下已存在 `moonbitlang/typst.mbt`** —— "A port of the Typst typesetting engine to MoonBit"，仓库创建于 **2026-10-02**，最后提交 2026-11-02，**0 star**，约 31 MB。
2. 其 `PLAN.md` 自述进度：P0 scaffolding、P1 syntax（3792/3792 用例，tree/diagnostics/AST/reparse 全部一致）、P2 eval（3792/3792）、P3 realize + HTML（508/508）、P4 fonts/shaping/layout/export（paged 2299/2299、svg 2299/2299 byte-identical、pdf-semantic 2299/2299、render 2299/2299 exact pixmaps、shape 4598/4598、break 12734/12734）**全部 done**。这些数字是仓库自述，**未独立复现验证**。
3. 支持后端：`native` 与 `wasm`（wasm 版跑在 `moonrun`）；**`wasm-gc` 已不再支持**（README 原文 "wasm-gc is no longer supported"）。CLI 可 `compile` 出 PDF/PNG/SVG/HTML/bundle。
4. 依赖链：字体解析（自写 `otf`，因内置字体是 CFF，MATH/CFF 必须）、整形（自写 rustybuzz 替代）、PDF 写出（基于 `office.mbt` 的 `pdflite`）、UAX#14/#29 表生成、`moonbitlang/regexp`（其 `regex()` 类型）。
5. 已知缺口（PLAN 自述）：PDF 内嵌图像的 DCT/JPX/JBIG2/CCITT 滤镜；`hayagriva`/citationberg（参考文献）deferred；`usvg/resvg` P9。
6. **综合阻塞点**：如果"Typst 渲染子集"指**自己从零写排版**，则字体解析 + 整形 + 断行 + PDF 输出是数月级工作量（上游核心引擎自述约 140k 行 Rust）；如果指**集成/裁剪 typst.mbt**，阻塞点转为该库**尚未发布到 mooncakes、无版本、无第三方验证**，只能以 path 依赖或源码方式引入，且 wasm-gc 不可用。

来源：[typst.mbt](https://github.com/moonbitlang/typst.mbt)、[PLAN.md](https://github.com/moonbitlang/typst.mbt/blob/main/PLAN.md)、[office.mbt](https://github.com/moonbitlang/office.mbt)

### D5. 基于 WASM 的 Kubernetes Operator 运行时（依赖 WASI/宿主接口）

1. **WASM 输出能力**：MoonBit 可编译到 `wasm` 与 `wasm-gc`；组件模型需 `wit-bindgen moonbit`（教程用 0.45.0）+ `wasm-tools component embed/new`，目标命令是 `moon build --target wasm`（**不是 wasm-gc**）。
2. **WASI 现状**：官方文档正文**没有 WASI 章节**；文档仓库只有 `legacy/examples/wasi-http`（模块名 `moonbit-community/wasi-http`，`preferred_target = "wasm"`，用 wit-bindgen 生成），位于 **legacy** 目录，**未验证当前是否可构建**。未发现 WASI preview1/preview2 的标准库封装。
3. **运行时 I/O**：MoonBit 自身在 wasm 里没有 socket/文件能力，全部依赖 host import；`async` 的 wasm1 支持**需要最新 `moonrun` 且不兼容其他 WASM runtime**——这与"跑在 K8s 里的通用 WASM runtime（wasmtime/spin 等）"直接冲突。
4. **K8s API 需求**：watch 长连接、TLS、JSON 反序列化、CRD schema。JSON 有 `core/json`；TLS/HTTP 在 wasm 目标下需由宿主提供（WASI HTTP 或自定义 import），MoonBit 侧只能写业务逻辑。
5. **组件模型可行性**：WIT 路线可生成 import/export 绑定，理论上可把 K8s client 放到宿主、MoonBit 只做 reconcile 逻辑；但需要自建 host ABI，且缺少官方 WASI 库支持。
6. **综合阻塞点**：**语言能产出 wasm/component，但缺少 WASI 标准库与可移植运行时抽象**；"Operator 运行时"的宿主接口层必须自建，MoonBit 只能承担纯逻辑部分。

来源：[component-model-tutorial.md](https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/wasm/component-model-tutorial.md)、[wasi-http example](https://github.com/moonbitlang/moonbit-docs/tree/main/legacy/examples/wasi-http)、[async README](https://github.com/moonbitlang/async)

---

## 3. 查不到 / 存疑清单

以下项**未能以一手来源确认**，不应作为既定事实使用：

1. **`moonbitlang/setup-moonbit@v1` 是否存在**：某社区仓库的 workflow 引用了它，但 GitHub API 与 raw 均 404；官方仓库实际使用仓库内 composite action。**存疑**。
2. **mooncakes.io 关键词搜索能力**：`/api/v0/modules?query=|name=|kw=|search=` 均返回同一份未过滤列表，无法据此枚举"是否存在 MQTT/Arrow/LSP 库"。目前只能以 GitHub 仓库搜索作为替代证据（结果均为"无"），**不等于 mooncakes 上一定没有**。
3. **`typst.mbt` 的真实完成度**：PLAN.md 的 3792/3792、2299/2299 等数字均为仓库自述，**未独立复现**；仓库 0 star、创建仅 1 个月，也无 mooncakes 发布记录（未查得）。
4. **WASI preview1/preview2 的当前支持状态**：只找到 legacy 示例，无正式文档章节，**未验证**。
5. **用户自定义宏**：文档全文未提及，判定为"缺失"；但不能 100% 排除存在未文档化/内部使用的机制（如编译器内建 attribute）。**结论以"文档无、生态用外部生成器"为限**。
6. **大小端转换 API**：`core/int64` 未见 `to_be_bytes` 一类函数，检索为空；未穷举 `core/bytes`、`core/byte` 等包，**标记为未验证**。
7. **RSA/ECC 公钥原语**：`x/crypto` 目录中未见 RSA/ECC/ECDSA/X25519 文件；未检索 mooncakes 全库，**可能存在于第三方包**。
8. **`v128` 包的 API 完整度**：仅确认包存在，未读其接口。
9. **`moonbitlang/core/async` 与 `moonbitlang/async` 的功能差异**：release note 称前者"做了大量改进"且可混用，但未给出逐项 diff；本文所述 async 能力均以 `moonbitlang/async` README/文档为准。
10. **JS 后端 `Array` 布局破坏性变更**：v0.10.19 仅"预告下个版本"，当前版本行为未实测。

---

## 附：本次核查使用的主要一手来源

- MoonBit v0.10.19 发布说明（2026-11-05）：https://www.moonbitlang.cn/updates/2026/11/05/index
- 官方文档仓库（语言/工具链 markdown 源）：https://github.com/moonbitlang/moonbit-docs/tree/main/next
  - async：`next/language/async-experimental.md`
  - FFI：`next/language/ffi.md`
  - derive：`next/language/derive.md`
  - 错误处理：`next/language/error-handling.md`
  - 测试：`next/language/tests.md`
  - 基准：`next/language/benchmarks.md`
  - 基础语法/正则：`next/language/fundamentals.md`
  - trait/方法：`next/language/methods.md`
  - 命令：`next/toolchain/moon/commands.md`
  - 模块：`next/toolchain/moon/module.md`
  - 包：`next/toolchain/moon/package.md`
  - 覆盖率：`next/toolchain/moon/coverage.md`
  - 组件模型：`next/toolchain/wasm/component-model-tutorial.md`
- 标准库：https://github.com/moonbitlang/core
- 扩展库：https://github.com/moonbitlang/x
- 异步运行时：https://github.com/moonbitlang/async
- Rabbita：https://github.com/moonbit-community/rabbita
- Typst 移植：https://github.com/moonbitlang/typst.mbt
- 解析器生成：https://github.com/moonbitlang/moonyacc 、https://github.com/moonbitlang/moonlex 、https://github.com/moonbitlang/protoc-gen-mbt
- 官方 MoonBit 解析器（自举实践）：https://github.com/moonbitlang/parser
- PDF/办公：https://github.com/moonbitlang/office.mbt 、https://github.com/moonbitlang/mbtpdf
- CI 参考：https://github.com/moonbitlang/core/blob/main/.github/workflows/stable-check.yml
