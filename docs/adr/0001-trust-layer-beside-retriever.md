# 信任层做在检索器旁边，而不是再做一个检索器

Status: accepted (2026-11-06)

MoonBit 生态里 RAG 主干已被 `MoonRetrieve` 等包覆盖（切分、BM25、向量检索、RRF 融合、上下文组装、评测），而重排、证据信任评分、多文档冲突检测、prompt-injection 检测四项为空白。因此本项目定位为**补位层**：输入任意检索器返回的候选块，输出带信任与风险标注的重排结果与证据上下文；不实现检索能力。

## Considered Options

- **做一站式 RAG 引擎**：与 `MoonRetrieve` 功能高度重合，违反官方"避免与现有生态高度重复"的要求。
- **给 `MoonRetrieve` 提 PR**：信任与安全是正交关注点，应当作用于任何检索器（MoonRetrieve、MoonSearch、vcdb）；绑定单一引擎会降低复用价值，也不构成一个可申报的新项目。

## Consequences

- 必须先定义一个与检索器无关的候选块输入契约，否则"补位"只是口号。
- 验收演示需要至少一个与真实检索器（优先 `MoonRetrieve`）的集成示例，证明契约可用。
