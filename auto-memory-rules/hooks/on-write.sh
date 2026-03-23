#!/bin/bash
# Auto-Memory-Rules Hook Handler
# 由 Claude Code PostToolUse hook 调用
# 检测写入文件是否在 memory/ 目录，是则自动生成记忆产物

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_SCRIPT="$SCRIPT_DIR/../scripts/generate-memory-artifacts.sh"

# 从 stdin 读取工具调用信息（JSON 格式）
TOOL_INFO=$(cat)

# 提取文件路径（Write/Edit 用 file_path，NotebookEdit 用 notebook_path）
FILE_PATH=$(echo "$TOOL_INFO" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    fp = ti.get('file_path', '') or ti.get('notebook_path', '')
    print(fp.replace('\\\\', '/'))
except:
    print('')
" 2>/dev/null || echo "")

# 仅在写入 memory/ 目录时触发
if echo "$FILE_PATH" | grep -q "/memory/"; then
    bash "$ARTIFACT_SCRIPT" 2>&1
fi
