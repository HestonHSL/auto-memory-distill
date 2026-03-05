---
name: memory-distill
description: 长期记忆管理核心技能。涵盖碎片捕获、规则提纯与质量门控。
---

# Memory-Distill 核心执行准则

> 本文件是记忆管理的“唯一真理来源”。

## 1. 触发时机与导航

- **实时同步**：[`/auto-memory-sync`](./workflows/auto-memory-sync.md)
  - _触发_：分析完用户输入/反馈或完成关键输出后。
- **结算整理**：[`/memory-consolidation`](./workflows/memory-consolidation.md)
  - _触发_：任务结束或话题转移。

## 2. 详细执行规范

### 2.1 任务启动与自愈

- 优先尝试 `list_dir .memory`。
- 若不存在，自动创建目录及 `index.md`。
- 检索优先级：关键词匹配 (`grep`) > 目录扫描。

### 2.2 对话内缓存

维护以下状态以减少 IO：

- `last_keywords` / `last_topic_fingerprint` / `last_loaded_memory_files`

### 2.3 提纯质量门控 (Layer 2 标准)

- **抽象化**：去除路径、行号、变量名，转换为指令式语言。
- **降噪**：过滤偶发性尝试，仅保留具有模式特征的规则。
- **冲突处理**：新旧规则矛盾时，优先保留最新反馈。

## 3. 参考文档

- [意图识别与记录规范](./references/intent-recognition.md)
- [提纯整理标准](./references/distillation-standards.md)
