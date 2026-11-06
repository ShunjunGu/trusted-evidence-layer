# 01 — 走通骨架：候选块契约 → 报告 → CLI → CI

**What to build:** 开发者能用一组 fixture 运行 `scan`，得到按检索分数排序的合法 JSON 报告；库在 native / wasm-gc / js 上可检查，CI 跑通 check + test + fmt。

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] 候选块契约可 JSON 序列化：id、文本、来源元数据、检索分数、可选原文区间
- [ ] `scan` 读取 fixture、写出报告；报告含 query、配置快照、排序后的证据、诊断信息
- [ ] 相同输入两次运行输出字节一致
- [ ] 空候选、单候选、重复 id 均有确定行为
- [ ] 库在 native / wasm-gc / js 三个目标上通过 `moon check`
- [ ] CI 运行 check + test + fmt，全部通过
- [ ] README 骨架存在：一句话定位、安装方式、最小示例
