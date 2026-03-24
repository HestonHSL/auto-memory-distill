#!/bin/bash
# Auto-Memory-Rules 记忆产物生成器
# 同时生成索引和清单

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_DIR="$SCRIPT_DIR/../memory"
INDEX_FILE="$MEMORY_DIR/index.md"
CHECKLIST_FILE="$MEMORY_DIR/CHECKLIST.md"

echo "� 开始生成记忆系统产物..."
echo ""

# 检查 memory 目录
if [ ! -d "$MEMORY_DIR" ]; then
    echo "⚠️  Memory 目录不存在，创建中..."
    mkdir -p "$MEMORY_DIR"
fi

# 统计记忆数量
memory_count=$(find "$MEMORY_DIR" -name "*.md" -not -name "index.md" -not -name "CHECKLIST.md" | wc -l | tr -d ' ')
echo "✅ 找到 $memory_count 条记忆"

if [ "$memory_count" -eq 0 ]; then
    echo "⚠️  没有记忆文件，跳过生成"
    exit 0
fi

# 定义 category 映射函数
get_category_name() {
    case "$1" in
        api) echo "API 相关" ;;
        types) echo "类型定义" ;;
        component) echo "组件开发" ;;
        hook) echo "Hook 开发" ;;
        state) echo "状态管理" ;;
        testing) echo "测试工程" ;;
        security) echo "安全规范" ;;
        pattern) echo "设计模式" ;;
        convention) echo "编码规范" ;;
        quality) echo "代码质量" ;;
        workflow) echo "工作流程" ;;
        general) echo "通用规则" ;;
        *) echo "$1" ;;
    esac
}

CATEGORIES="api types component hook state testing security pattern convention quality workflow general"

# ============================================
# 第一部分：生成索引 (index.md)
# ============================================

echo ""
echo "📖 [1/2] 生成记忆索引..."

cat > "$INDEX_FILE" << 'EOF'
# 记忆系统索引

> 此文件自动生成，请勿手动编辑
> 运行 `bash scripts/generate-memory-artifacts.sh` 重新生成

EOF

echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$INDEX_FILE"
echo "记忆总数: $memory_count" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"

cat >> "$INDEX_FILE" << 'EOF'
## 使用说明

此索引帮助你快速找到相关记忆：
- 按 category 浏览记忆
- 按 tags 搜索记忆
- 按 priority 筛选记忆

---

EOF

# 按 category 分组生成索引
for category_key in $CATEGORIES; do
    category_name=$(get_category_name "$category_key")
    has_memories=false
    temp_file=$(mktemp)
    
    for memory in "$MEMORY_DIR"/*.md; do
        if [ -f "$memory" ] && [ "$(basename "$memory")" != "index.md" ] && [ "$(basename "$memory")" != "CHECKLIST.md" ]; then
            if grep -q "^category:.*$category_key" "$memory"; then
                has_memories=true
                
                filename=$(basename "$memory")
                title=$(grep "^# " "$memory" | head -1 | sed 's/^# //')
                priority=$(grep "^priority:" "$memory" | sed 's/^priority: *//')
                tags=$(grep "^tags:" "$memory" | sed 's/^tags: *\[//' | sed 's/\]//' | sed 's/, */ | /g')
                description=$(grep "^description:" "$memory" | sed 's/^description: *//')
                
                priority_icon=""
                case $priority in
                    high) priority_icon="🔴" ;;
                    medium) priority_icon="🟡" ;;
                    low) priority_icon="🟢" ;;
                esac
                
                echo "- [$priority_icon $title]($filename)" >> "$temp_file"
                [ -n "$description" ] && echo "  - $description" >> "$temp_file"
                [ -n "$tags" ] && echo "  - 标签: $tags" >> "$temp_file"
                echo "" >> "$temp_file"
            fi
        fi
    done
    
    if [ "$has_memories" = true ]; then
        echo "## $category_name" >> "$INDEX_FILE"
        echo "" >> "$INDEX_FILE"
        cat "$temp_file" >> "$INDEX_FILE"
    fi
    
    rm -f "$temp_file"
done

# 处理未分类的记忆
uncategorized_count=0
temp_file=$(mktemp)

for memory in "$MEMORY_DIR"/*.md; do
    if [ -f "$memory" ] && [ "$(basename "$memory")" != "index.md" ] && [ "$(basename "$memory")" != "CHECKLIST.md" ]; then
        if ! grep -q "^category:" "$memory" || ! grep -E "^category:.*(api|types|component|hook|state|testing|security|pattern|convention|quality|workflow|general)" "$memory"; then
            uncategorized_count=$((uncategorized_count + 1))
            filename=$(basename "$memory")
            title=$(grep "^# " "$memory" | head -1 | sed 's/^# //')
            echo "- [$title]($filename)" >> "$temp_file"
            echo "" >> "$temp_file"
        fi
    fi
done


if [ "$uncategorized_count" -gt 0 ]; then
    echo "## 未分类" >> "$INDEX_FILE"
    echo "" >> "$INDEX_FILE"
    cat "$temp_file" >> "$INDEX_FILE"
fi

rm -f "$temp_file"

# 添加统计信息
echo "---" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
echo "## 统计信息" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"

for category_key in $CATEGORIES; do
    category_name=$(get_category_name "$category_key")
    count=$(grep -l "^category:.*$category_key" "$MEMORY_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" -gt 0 ] && echo "- $category_name: $count 条记忆" >> "$INDEX_FILE"
done

[ "$uncategorized_count" -gt 0 ] && echo "- 未分类: $uncategorized_count 条记忆" >> "$INDEX_FILE"

cat >> "$INDEX_FILE" << 'EOF'

---

## 相关文件

- [CHECKLIST.md](CHECKLIST.md) - 自检清单

EOF

echo "  ✅ 索引已生成: $INDEX_FILE"


# ============================================
# 第二部分：生成清单 (CHECKLIST.md)
# ============================================

echo ""
echo "📋 [2/2] 生成自检清单..."

cat > "$CHECKLIST_FILE" << 'EOF'
# 记忆系统自检清单

> 此文件自动生成，请勿手动编辑
> 运行 `bash scripts/generate-memory-artifacts.sh` 重新生成

EOF

echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$CHECKLIST_FILE"
echo "记忆总数: $memory_count" >> "$CHECKLIST_FILE"
echo "" >> "$CHECKLIST_FILE"

cat >> "$CHECKLIST_FILE" << 'EOF'
## 使用说明

在生成代码前，根据任务类型查看相关类别的检查点，确保不会重复历史错误。

**使用方式**：
- 在对话开始时：AI 会自动加载相关记忆
- 手动检查：根据下方分类查看相关检查点
- 生成代码后：对照 checklist 进行自检

---

EOF

# 按 category 和 priority 生成清单
for category_key in $CATEGORIES; do
    category_name=$(get_category_name "$category_key")
    has_memories=false
    temp_file=$(mktemp)
    
    for priority in "high" "medium" "low"; do
        priority_label=""
        case $priority in
            high) priority_label="🔴 高优先级" ;;
            medium) priority_label="🟡 中优先级" ;;
            low) priority_label="🟢 低优先级" ;;
        esac
        
        has_priority_memories=false
        priority_content=""
        
        for memory in "$MEMORY_DIR"/*.md; do
            if [ -f "$memory" ] && [ "$(basename "$memory")" != "index.md" ] && [ "$(basename "$memory")" != "CHECKLIST.md" ]; then
                if grep -q "^category:.*$category_key" "$memory" && grep -q "^priority:.*$priority" "$memory"; then
                    has_memories=true
                    has_priority_memories=true
                    
                    title=$(grep "^# " "$memory" | head -1 | sed 's/^# //')
                    tags=$(grep "^tags:" "$memory" | sed 's/^tags: *\[//' | sed 's/\]//' | sed 's/, */ | /g')
                    
                    priority_content+="#### $title\n\n"
                    [ -n "$tags" ] && priority_content+="**标签**: $tags\n\n"
                    
                    checkpoints=$(sed -n '/## 检查点/,/^## /p' "$memory" | grep "^- \[ \]")
                    
                    if [ -n "$checkpoints" ]; then
                        priority_content+="**检查点**:\n$checkpoints\n\n"
                    else
                        filename=$(basename "$memory")
                        priority_content+="*无具体检查点，请查看记忆文件: \`$filename\`*\n\n"
                    fi
                fi
            fi
        done
        
        if [ "$has_priority_memories" = true ]; then
            echo -e "### $priority_label\n" >> "$temp_file"
            echo -e "$priority_content" >> "$temp_file"
        fi
    done
    
    if [ "$has_memories" = true ]; then
        echo "## $category_name" >> "$CHECKLIST_FILE"
        echo "" >> "$CHECKLIST_FILE"
        cat "$temp_file" >> "$CHECKLIST_FILE"
    fi
    
    rm -f "$temp_file"
done


# 处理未分类的记忆
echo "## 其他" >> "$CHECKLIST_FILE"
echo "" >> "$CHECKLIST_FILE"

for memory in "$MEMORY_DIR"/*.md; do
    if [ -f "$memory" ] && [ "$(basename "$memory")" != "index.md" ] && [ "$(basename "$memory")" != "CHECKLIST.md" ]; then
        if ! grep -q "^category:" "$memory" || ! grep -E "^category:.*(api|types|component|hook|state|testing|security|pattern|convention|quality|workflow|general)" "$memory"; then
            title=$(grep "^# " "$memory" | head -1 | sed 's/^# //')
            priority=$(grep "^priority:" "$memory" | sed 's/^priority: *//')
            
            echo "### $title" >> "$CHECKLIST_FILE"
            [ -n "$priority" ] && echo "" >> "$CHECKLIST_FILE" && echo "**优先级**: $priority" >> "$CHECKLIST_FILE"
            
            checkpoints=$(sed -n '/## 检查点/,/^## /p' "$memory" | grep "^- \[ \]")
            [ -n "$checkpoints" ] && echo "" >> "$CHECKLIST_FILE" && echo "$checkpoints" >> "$CHECKLIST_FILE"
            echo "" >> "$CHECKLIST_FILE"
        fi
    fi
done

# 添加快速索引
echo "---" >> "$CHECKLIST_FILE"
echo "" >> "$CHECKLIST_FILE"
echo "## 快速索引" >> "$CHECKLIST_FILE"
echo "" >> "$CHECKLIST_FILE"

for category_key in $CATEGORIES; do
    category_name=$(get_category_name "$category_key")
    count=$(grep -l "^category:.*$category_key" "$MEMORY_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" -gt 0 ] && echo "- [$category_name](#${category_name// /-}) ($count 条记忆)" >> "$CHECKLIST_FILE"
done

echo "" >> "$CHECKLIST_FILE"

echo "  ✅ 清单已生成: $CHECKLIST_FILE"

# ============================================
# 输出结算报告
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 所有产物生成成功！"
echo ""
echo "生成的文件："
echo "  - memory/index.md"
echo "  - memory/CHECKLIST.md"
echo ""
echo "📊 统计信息："

for category_key in $CATEGORIES; do
    category_name=$(get_category_name "$category_key")
    count=$(grep -l "^category:.*$category_key" "$MEMORY_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt 0 ]; then
        high=$(grep -l "^priority:.*high" $(grep -l "^category:.*$category_key" "$MEMORY_DIR"/*.md 2>/dev/null) 2>/dev/null | wc -l | tr -d ' ')
        medium=$(grep -l "^priority:.*medium" $(grep -l "^category:.*$category_key" "$MEMORY_DIR"/*.md 2>/dev/null) 2>/dev/null | wc -l | tr -d ' ')
        low=$(grep -l "^priority:.*low" $(grep -l "^category:.*$category_key" "$MEMORY_DIR"/*.md 2>/dev/null) 2>/dev/null | wc -l | tr -d ' ')
        echo "  $category_name: $count 条 (高: $high, 中: $medium, 低: $low)"
    fi
done

[ "$uncategorized_count" -gt 0 ] && echo "  未分类: $uncategorized_count 条记忆"
