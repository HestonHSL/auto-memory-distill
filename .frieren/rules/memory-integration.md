---
agentRequested: true
description: "核心长期记忆集成规则。强制在特定生命周期调用 memory-distill 技能。"
---

# Project Memory Integration

你必须在开发任务的特定时刻严格执行 `memory-distill` 技能所定义的指令：

1. **任务启动 (Pre-task)**：
   - 必须优先检索 `.memory/` 规则并注入上下文。
   - 若目录不存在，必须根据技能规范进行自愈初始化。

2. **任务执行 (Execution)**：
   - **分析完输入/反馈后**：识别到偏好或纠错，应即刻执行同步（Layer 1 Sync）。
   - **生成输出后**：检查输出是否符合已知记忆，必要时微调或追加记录。

3. **结算/话题转移 (Settlement / Topic Shift)**：
   - 必须执行记忆提纯整理（Layer 2 Consolidation），清理原始碎片。

**核心指令**：所有具体的缓存维护、抽象标准与流程细节，必须严格遵循 [SKILL.md](../skills/memory-distill/SKILL.md) 的规定。
