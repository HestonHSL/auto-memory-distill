#!/bin/bash
# Memory-Distill Checklist 生成器
# 从 memory/rules/ 自动生成代码审查 checklist

# 获取脚本所在目录和项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RULES_DIR="$SCRIPT_DIR/memory/rules"
OUTPUT_FILE="$PROJECT_ROOT/CHECKLIST.md"

echo "# 代码审查 Checklist" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "此 checklist 从 \`memory/rules/\` 自动生成。" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "## 使用方式" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "在对话中请求:" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo '"请用 checklist 审查代码"' >> "$OUTPUT_FILE"
echo '"根据我的偏好规则检查这个文件"' >> "$OUTPUT_FILE"
echo '"用 memory checklist 审查"' >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 遍历所有 rule 文件
for rule in "$RULES_DIR"/*.md; do
    if [ -f "$rule" ]; then
        # 提取标题
        title=$(grep "^# " "$rule" | head -1 | sed 's/^# //')
        
        # 检查是否有检查项部分
        if grep -q "## 检查项" "$rule"; then
            echo "## $title" >> "$OUTPUT_FILE"
            
            # 提取检查项
            sed -n '/## 检查项/,/## /p' "$rule" | grep "^- \[ \]" >> "$OUTPUT_FILE"
            
            # 提取优先级(如果有)
            priority=$(sed -n '/## 优先级/,/^$/p' "$rule" | grep -E "🔴|🟡|🟢" | head -1)
            if [ -n "$priority" ]; then
                echo "" >> "$OUTPUT_FILE"
                echo "$priority" >> "$OUTPUT_FILE"
            fi
            
            echo "" >> "$OUTPUT_FILE"
        fi
    fi
done

echo "✅ Checklist 已生成: $OUTPUT_FILE"
