# Auto-Memory-Rules

让 AI 记住你的每一次纠错与偏好，并自动增强自身的输出规则。

Auto-Memory-Rules 是一套面向 AI Native 开发的长期记忆管理系统。它通过自我反思机制，将你在开发过程中对 AI 的纠错、偏好和规范要求转化为可持久执行的项目规则。

## 解决的痛点

- **遗忘曲线**：AI 在长对话或跨任务中极易忘记用户之前的纠错和偏好
- **维护成本**：手动整理项目规范（如 `.cursorrules`）繁琐且难以随开发实时同步
- **重复纠错**：同样的错误需要反复提醒，浪费时间和精力
- **配置断层**：不同成员或不同环境下，AI 对特定项目的认知无法自动保持一致

## 核心理念：自我反思 + 主动学习

系统通过三层反思机制，将用户的反馈转化为可执行的规则：

### 1. 表层反思：用户说了什么？
直接理解用户的字面要求

### 2. 深层反思：为什么用户会这么说？
- 我的回答哪里不够好？
- 我遗漏了什么重要信息？
- 我的方案有什么不合理的地方？

### 3. 原则提取：这背后的通用原则是什么？
- 是代码质量问题？（quality）
- 是用户偏好？（convention）
- 是最佳实践？（pattern）
- 是否可以泛化到类似场景？

## 工作流程

### 对话开始
1. 编辑器自动加载生成的规则文件（如 `api-rules.md`、`hook-rules.md`）
2. 形成"避坑清单"，主动规避已知错误

### 对话执行
1. **持续监听**用户的纠错、偏好和规范要求
2. **自我反思**：理解用户要求的深层原因
3. **提取原则**：识别可复用的通用规则
4. **创建记忆**：直接记录到 `memory/` 目录

### 对话结束
1. 统计本次记录的记忆数量
2. 自动生成索引和自检清单（已安装 hook 则自动触发）
3. 更新编辑器规则（可选）

## 项目亮点

- **零干预进化**：无需用户手动维护，AI 在对话中自动捕获反馈并生成规则
- **自我反思机制**：AI 不只记录"做什么"，更理解"为什么"，形成深层认知
- **Hook 自动触发**：通过 Claude Code PostToolUse hook，每次写入记忆文件自动更新索引和清单
- **冲突智能处理**：规则演进则覆盖，场景分支则合并，两种冲突情形均有对应策略
- **多格式输出**：支持生成 Kiro Steering、Frieren Rules、Cursor/Windsurf 单文件等多种格式
- **自动增强**：通过生成脚本将记忆转化为编辑器规则，直接增强 AI 能力

## 目录结构

```text
<your-project>/
├── .{editor}/                           # 编辑器配置目录（kiro/frieren/etc）
│   ├── steering/ 或 rules/              # 规则目录
│   │   ├── memory-integration.md        # 核心集成规则（脚本生成）
│   │   └── {category}-rules.md          # 按分类生成的规则（脚本生成）
│   └── skills/
│       └── auto-memory-rules/           # 技能包核心
│           ├── SKILL.md                 # 核心逻辑与规则模板
│           ├── hooks/
│           │   └── on-write.sh          # Hook 处理脚本（监听 memory/ 写入）
│           ├── scripts/
│           │   ├── setup-hooks.sh                 # 注册 Claude Code hook（一次性）
│           │   ├── generate-memory-artifacts.sh   # 生成索引和清单
│           │   ├── generate-integration-rules.sh  # 生成集成规则
│           │   ├── generate-rules.sh              # 生成分类规则
│           │   └── editor-config.sh               # 编辑器配置
│           ├── templates/
│           │   └── memory-integration.md          # 集成规则模板
│           └── memory/                  # 记忆存储库
│               ├── YYYY-MM-DD-{category}-{brief}.md  # AI 创建的记忆
│               ├── index.md             # 自动生成的索引
│               └── CHECKLIST.md         # 自动生成的清单
```


## 规则分类与命名

系统采用标准化的分类体系，确保规则的可检索性：

### 规则分类 (Category)
- `api` - API 相关
- `types` - 类型定义
- `component` - 组件开发
- `hook` - Hook 开发
- `state` - 状态管理
- `pattern` - 设计模式
- `convention` - 编码规范
- `quality` - 代码质量
- `workflow` - 工作流程
- `general` - 跨领域通用规则（不适合以上分类时使用）

### 优先级标记
- 🔴 `high` - 高优先级（严重影响代码质量或功能）
- 🟡 `medium` - 中优先级（影响代码可维护性）
- 🟢 `low` - 低优先级（优化建议）

### 规则文件结构
每个规则文件包含 frontmatter 元数据：
```yaml
---
category: hook
priority: high
tags: [react, hooks, state]
description: Hook 不应暴露内部 setter
---
```

## 如何使用

### 安装

根据你使用的 AI 编程助手，将 `auto-memory-rules/` 放到对应的 skills 目录：

```bash
# 拷贝技能包到编辑器 skills 目录
# Kiro: .kiro/skills/
# Frieren: .frieren/skills/
# 其他: 项目根目录或自定义位置
cp -r auto-memory-rules <your-project>/.{editor}/skills/

# 生成集成规则（必须）
bash <your-project>/.{editor}/skills/auto-memory-rules/scripts/generate-integration-rules.sh {editor}

# 注册 Claude Code hook（推荐，自动触发索引更新）
bash <your-project>/.{editor}/skills/auto-memory-rules/scripts/setup-hooks.sh
```

### 使用

AI 助手会自动识别并应用规则。在对话中：
- AI 会自动监听你的纠错、偏好和规范要求
- 进行自我反思，理解你的真实意图
- 将有价值的反馈转化为记忆文件
- 在后续任务中自动应用这些规则

### 生成规则文件

```bash
# 生成索引和清单（已安装 hook 则自动触发，无需手动执行）
bash scripts/generate-memory-artifacts.sh

# 生成编辑器规则（可选，更新编辑器规则时运行）
bash scripts/generate-rules.sh {editor}

# 支持的编辑器: kiro, frieren, cursor, windsurf
```

### 查看生成的文件

- `memory/index.md` - 按分类浏览所有记忆（自动生成）
- `memory/CHECKLIST.md` - 代码审查自检清单（自动生成）
- `.kiro/steering/{category}-rules.md` - Kiro 自动加载的分类规则（可选生成）
- `.frieren/rules/{category}-rules.md` - Frieren 格式的分类规则文档（可选生成）

## 触发信号

AI 会在以下情况下自动记录规则：

### 立即记录（高优先级）
- ❗ **明确纠错**："不对"、"错了"、"应该是..."
- ❗ **要求修改**："改成..."、"换成..."、"不要..."
- ❗ **指出遗漏**："还要..."、"别忘了..."、"漏了..."

### 反思后记录（中优先级）
- ⚠️ **偏好表达**："我更喜欢..."、"最好..."、"建议..."
- ⚠️ **全局规范**："统一..."、"所有..."、"都要..."、"一律..."
- ⚠️ **方法指导**："用...命令"、"去...查询"
- ⚠️ **交互优化**：对回答方式、展示格式、沟通风格的调整

### 不记录
- ✗ 一次性特殊处理（"临时..."、"这里特殊..."）
- ✗ 项目特定的业务逻辑
- ✗ 纯概念解释（没有可复用的规则）

## 未来升级：语义化搜索 (QMD)

当你的规则库增长到一定规模时，可以考虑引入 QMD 以获得更精准的语义检索能力：

- [QMD 技术指南](./qmd-guide.md)
- [QMD 语义化检索升级待办](./todo-qmd-integration.md)

---

> 由自我反思机制驱动的 AI 学习系统
