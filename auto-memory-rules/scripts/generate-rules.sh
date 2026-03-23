#!/bin/bash
# Auto-Memory-Rules 统一规则生成器
# 根据编辑器类型生成对应格式的规则文件

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RULES_DIR="$SCRIPT_DIR/../memory"

# 动态检测项目根目录
# 如果在 .kiro/skills/ 或 .frieren/skills/ 下，往上3层
# 否则往上2层
if echo "$SCRIPT_DIR" | grep -q "/\.kiro/skills/\|/\.frieren/skills/"; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
else
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

RULES_DIR="$SCRIPT_DIR/../memory"

# 加载编辑器配置
source "$SCRIPT_DIR/editor-config.sh"

# 显示使用说明
show_usage() {
    cat << EOF
使用方法: $0 <editor>

支持的编辑器:
  kiro      - Kiro AI 编程助手
  frieren   - Frieren AI 编程助手
  cursor    - Cursor 编辑器
  windsurf  - Windsurf (Codeium)

示例:
  $0 kiro
  $0 cursor

EOF
}

# 获取 category 显示名称
get_category_display_name() {
    case "$1" in
        api) echo "API 相关" ;;
        types) echo "类型定义" ;;
        component) echo "组件开发" ;;
        hook) echo "Hook 开发" ;;
        state) echo "状态管理" ;;
        pattern) echo "设计模式" ;;
        convention) echo "编码规范" ;;
        quality) echo "代码质量" ;;
        workflow) echo "工作流程" ;;
        general) echo "通用规则" ;;
        other) echo "其他" ;;
    esac
}

# 提取规则的核心要素（去掉示例和冗余说明）
extract_rule_essentials() {
    local rule_file="$1"
    local in_frontmatter=false
    local in_checklist=false
    local skip_section=false
    
    while IFS= read -r line; do
        # 处理 frontmatter
        if [ "$line" = "---" ]; then
            if [ "$in_frontmatter" = false ]; then
                in_frontmatter=true
                echo "$line"
            else
                in_frontmatter=false
                echo "$line"
            fi
            continue
        fi
        
        # frontmatter 内容保留
        if [ "$in_frontmatter" = true ]; then
            echo "$line"
            continue
        fi
        
        # 跳过的章节
        if echo "$line" | grep -qE "^## (示例|相关规则|反思记录|规则来源|触发场景|优先级说明)"; then
            skip_section=true
            continue
        fi
        
        # 遇到新章节，重置跳过标记
        if echo "$line" | grep -qE "^## "; then
            skip_section=false
        fi
        
        # 如果在跳过的章节中，继续跳过
        if [ "$skip_section" = true ]; then
            continue
        fi
        
        # 保留标题、核心原则、具体要求、检查点
        if echo "$line" | grep -qE "^#|^## (核心原则|具体要求|检查点)"; then
            echo "$line"
            continue
        fi
        
        # 检查点部分
        if echo "$line" | grep -qE "^- \[ \]"; then
            echo "$line"
            continue
        fi
        
        # 保留列表项（具体要求）
        if echo "$line" | grep -qE "^- "; then
            echo "$line"
            continue
        fi
        
        # 保留普通段落（但跳过空行过多的情况）
        if [ -n "$line" ]; then
            echo "$line"
        fi
    done < "$rule_file"
}

# 生成文件头部
generate_header() {
    local editor="$1"
    local category_display="$2"
    local use_frontmatter="$3"
    local frontmatter_type="$4"
    local category_key="$5"
    
    if [ "$use_frontmatter" = "true" ]; then
        case "$frontmatter_type" in
            "kiro")
                get_kiro_frontmatter "$category_key" "$category_display"
                ;;
            "frieren")
                get_frieren_frontmatter "$category_key" "$category_display"
                ;;
        esac
    fi
    
    cat << EOF
# 记忆系统 - $category_display


> 此文件自动生成，请勿手动编辑
> 运行 \`bash scripts/generate-rules.sh $editor\` 重新生成

---

EOF
}

# 生成多文件规则
generate_multi_file_rules() {
    local editor="$1"
    local output_dir="$2"
    local file_prefix="$3"
    local file_suffix="$4"
    local use_frontmatter="$5"
    local frontmatter_type="$6"
    
    local categories="api types component hook state pattern convention quality workflow general other"
    
    for category_key in $categories; do
        local category_display=$(get_category_display_name "$category_key")
        local output_file="$output_dir/${file_prefix}${category_key}${file_suffix}"
        local temp_file=$(mktemp)
        local has_rules=false
        
        # 生成文件头部
        generate_header "$editor" "$category_display" "$use_frontmatter" "$frontmatter_type" "$category_key" > "$temp_file"
        
        # 查找该 category 的规则
        for rule in "$RULES_DIR"/*.md; do
            # 跳过自动生成的文件
            local basename=$(basename "$rule")
            if [ "$basename" = "index.md" ] || [ "$basename" = "CHECKLIST.md" ]; then
                continue
            fi
            
            if [ -f "$rule" ]; then
                if [ "$category_key" = "other" ]; then
                    # 未分类或不在标准列表中
                    if ! grep -q "^category:" "$rule" || ! grep -E "^category:.*(api|types|component|hook|state|pattern|convention|quality|workflow)" "$rule"; then
                        has_rules=true
                        extract_rule_essentials "$rule" >> "$temp_file"
                        echo -e "\n---\n" >> "$temp_file"
                    fi
                else
                    # 标准 category
                    if grep -q "^category:.*$category_key" "$rule"; then
                        has_rules=true
                        extract_rule_essentials "$rule" >> "$temp_file"
                        echo -e "\n---\n" >> "$temp_file"
                    fi
                fi
            fi
        done
        
        # 如果该 category 有规则，写入输出文件
        if [ "$has_rules" = true ]; then
            mv "$temp_file" "$output_file"
            echo "  ✅ $output_file"
        else
            rm -f "$temp_file"
        fi
    done
}


# 生成单文件规则
generate_single_file_rules() {
    local editor="$1"
    local output_file="$2"
    local use_frontmatter="$3"
    local frontmatter_type="$4"
    
    # 生成文件头部
    cat > "$output_file" << EOF
# Auto-Memory-Rules

> 此文件自动生成，请勿手动编辑
> 运行 \`bash scripts/generate-rules.sh $editor\` 重新生成

---

EOF
    
    local categories="api types component hook state pattern convention quality workflow general other"
    
    for category_key in $categories; do
        local category_display=$(get_category_display_name "$category_key")
        local has_rules=false
        
        # 查找该 category 的规则
        for rule in "$RULES_DIR"/*.md; do
            # 跳过自动生成的文件
            local basename=$(basename "$rule")
            if [ "$basename" = "index.md" ] || [ "$basename" = "CHECKLIST.md" ]; then
                continue
            fi
            
            if [ -f "$rule" ]; then
                local match=false
                
                if [ "$category_key" = "other" ]; then
                    if ! grep -q "^category:" "$rule" || ! grep -E "^category:.*(api|types|component|hook|state|pattern|convention|quality|workflow)" "$rule"; then
                        match=true
                    fi
                else
                    if grep -q "^category:.*$category_key" "$rule"; then
                        match=true
                    fi
                fi
                
                if [ "$match" = true ]; then
                    if [ "$has_rules" = false ]; then
                        echo "## $category_display" >> "$output_file"
                        echo "" >> "$output_file"
                        has_rules=true
                    fi
                    
                    extract_rule_essentials "$rule" >> "$output_file"
                    echo -e "\n---\n" >> "$output_file"
                fi
            fi
        done
    done
    
    echo "  ✅ $output_file"
}


# 主函数
main() {
    # 检查参数
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    local editor="$1"
    
    # 验证编辑器
    if ! list_supported_editors | grep -q "^$editor$"; then
        echo "❌ 不支持的编辑器: $editor"
        echo ""
        show_usage
        exit 1
    fi
    
    echo "📖 读取规则文件..."
    
    # 检查 rules 目录是否存在
    if [ ! -d "$RULES_DIR" ]; then
        echo "⚠️  Rules 目录不存在: $RULES_DIR"
        exit 1
    fi
    
    # 统计规则数量
    rule_count=$(find "$RULES_DIR" -name "*.md" | wc -l | tr -d ' ')
    echo "✅ 找到 $rule_count 条规则"
    
    if [ "$rule_count" -eq 0 ]; then
        echo "⚠️  没有规则需要生成"
        exit 0
    fi
    
    # 获取编辑器配置
    local config=$(get_editor_config "$editor")
    if echo "$config" | grep -q "^error:"; then
        echo "❌ $(echo "$config" | cut -d: -f2-)"
        exit 1
    fi
    
    local output_dir=$(parse_config "$config" "output_dir")
    local file_prefix=$(parse_config "$config" "file_prefix")
    local file_suffix=$(parse_config "$config" "file_suffix")
    local use_frontmatter=$(parse_config "$config" "use_frontmatter")
    local frontmatter_type=$(parse_config "$config" "frontmatter_type")
    local multi_file=$(parse_config "$config" "multi_file")
    
    # 创建输出目录
    local full_output_dir="$PROJECT_ROOT/$output_dir"
    mkdir -p "$full_output_dir"
    
    echo "📝 生成 $editor 规则文件..."
    
    if [ "$multi_file" = "true" ]; then
        # 多文件模式
        generate_multi_file_rules "$editor" "$full_output_dir" "$file_prefix" "$file_suffix" "$use_frontmatter" "$frontmatter_type"
    else
        # 单文件模式
        local output_file="$full_output_dir/$file_suffix"
        generate_single_file_rules "$editor" "$output_file" "$use_frontmatter" "$frontmatter_type"
    fi
    
    echo ""
    echo "✨ 规则已生成到: $full_output_dir"
    echo ""
    echo "📋 统计信息:"
    
    # 统计各 category 的规则数量
    local categories="api types component hook state pattern convention quality workflow general other"
    for category_key in $categories; do
        local category_display=$(get_category_display_name "$category_key")
        local count
        
        if [ "$category_key" = "other" ]; then
            count=0
            for rule in "$RULES_DIR"/*.md; do
                local basename=$(basename "$rule")
                if [ "$basename" = "index.md" ] || [ "$basename" = "CHECKLIST.md" ]; then
                    continue
                fi
                if [ -f "$rule" ]; then
                    if ! grep -q "^category:" "$rule" || ! grep -E "^category:.*(api|types|component|hook|state|pattern|convention|quality|workflow)" "$rule"; then
                        count=$((count + 1))
                    fi
                fi
            done
        else
            count=0
            for rule in "$RULES_DIR"/*.md; do
                local basename=$(basename "$rule")
                if [ "$basename" = "index.md" ] || [ "$basename" = "CHECKLIST.md" ]; then
                    continue
                fi
                if [ -f "$rule" ] && grep -q "^category:.*$category_key" "$rule"; then
                    count=$((count + 1))
                fi
            done
        fi
        
        if [ "$count" -gt 0 ]; then
            echo "  $category_display: $count 条规则"
        fi
    done
}

# 执行主函数
main "$@"
