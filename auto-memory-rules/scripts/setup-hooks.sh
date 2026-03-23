#!/bin/bash
# Auto-Memory-Rules Hook 安装脚本
# 向当前项目的 .claude/settings.json 注入 PostToolUse hook
# 只需运行一次，之后每次向 memory/ 写入文件会自动触发 generate-memory-artifacts.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_HANDLER="$SCRIPT_DIR/../hooks/on-write.sh"

# 探测用户项目根目录（从当前工作目录向上找 git 根）
if command -v git &>/dev/null && git rev-parse --show-toplevel &>/dev/null 2>&1; then
    PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
    PROJECT_ROOT="$(pwd)"
fi

CLAUDE_DIR="$PROJECT_ROOT/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "📦 安装 Auto-Memory-Rules Hook..."
echo "  项目根目录: $PROJECT_ROOT"
echo "  Hook 处理脚本: $HOOK_HANDLER"
echo ""

# 检查 hook 处理脚本是否存在
if [ ! -f "$HOOK_HANDLER" ]; then
    echo "❌ 找不到 hook 处理脚本: $HOOK_HANDLER"
    exit 1
fi

chmod +x "$HOOK_HANDLER"

# 创建 .claude 目录
mkdir -p "$CLAUDE_DIR"

# 使用 Python 安全地创建/合并 settings.json（避免手动拼接 JSON）
python3 - "$SETTINGS_FILE" "$HOOK_HANDLER" << 'PYEOF'
import sys, json, os

settings_file = sys.argv[1]
hook_handler = sys.argv[2]

hook_command = f"bash '{hook_handler}'"

new_hook_entry = {
    "matcher": "Write|Edit|NotebookEdit",
    "hooks": [
        {
            "type": "command",
            "command": hook_command
        }
    ]
}

# 读取现有配置
if os.path.exists(settings_file):
    with open(settings_file, 'r', encoding='utf-8') as f:
        try:
            settings = json.load(f)
        except json.JSONDecodeError:
            print("⚠️  settings.json 格式无效，将重新创建")
            settings = {}
else:
    settings = {}

# 确保 hooks 结构存在
settings.setdefault("hooks", {}).setdefault("PostToolUse", [])

# 检查是否已安装，避免重复
for entry in settings["hooks"]["PostToolUse"]:
    for h in entry.get("hooks", []):
        if hook_handler in h.get("command", ""):
            print("⚠️  Hook 已安装，跳过（避免重复）")
            sys.exit(0)

# 追加 hook
settings["hooks"]["PostToolUse"].append(new_hook_entry)

# 写入
with open(settings_file, 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)

print(f"✅ Hook 已写入: {settings_file}")
PYEOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 安装完成！"
echo ""
echo "效果："
echo "  每次向 memory/ 写入 .md 文件后，Claude Code 会自动"
echo "  触发 generate-memory-artifacts.sh，无需 AI 手动调用"
echo ""
echo "验证方式："
echo "  cat '$SETTINGS_FILE'"
