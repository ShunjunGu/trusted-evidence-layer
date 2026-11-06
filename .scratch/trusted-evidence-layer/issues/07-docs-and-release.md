# 07 — 文档与发布

**What to build:** 包具备完整的使用文档、可运行示例与发布产物：读者能按 README 在几分钟内跑通，包可从 mooncakes 安装，CI 矩阵与覆盖率可见。

**Blocked by:** 06 — 验收演示

**Status:** ready-for-agent

- [ ] README 含定位、安装、最小示例、评分规则、注入检测边界与误报/漏报说明
- [ ] 至少两个可运行示例，CI 中执行
- [ ] Apache-2.0 LICENSE、CHANGELOG、`.moonignore`
- [ ] 包发布到 mooncakes，`moon add` 可用
- [ ] CI 矩阵覆盖 native / wasm-gc / js（库）与 native（CLI）
- [ ] 覆盖率报告生成，README 给出当前数值
- [ ] 包名已对 mooncakes 查重，避开与 `MoonEvidence` 的语义冲突
