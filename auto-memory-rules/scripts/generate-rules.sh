#!/bin/bash
# Auto-Memory-Rules Frieren 多文件规则生成器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/../memory"

# 在 .frieren/skills/auto-memory-rules/scripts 下运行时，项目根目录需回退四级
if echo "$SCRIPT_DIR" | grep -q "/\.frieren/skills/"; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../" && pwd)"
else
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

OUTPUT_DIR="$PROJECT_ROOT/.frieren/rules"
CATEGORIES="api types component hook state testing security pattern convention quality workflow general other"
CLASSIFIED_REGEX="api|types|component|hook|state|testing|security|pattern|convention|quality|workflow|general"

show_usage() {
    cat << EOF
使用方法: $0

说明:
  本脚本仅生成 Frieren 多文件规则（输出到 .frieren/rules/）

示例:
  $0

EOF
}

detect_frieren() {
    if [ -d "$PROJECT_ROOT/.frieren" ] || [ -d "$PROJECT_ROOT/.frieren/skills" ] || [ -d "$PROJECT_ROOT/.frieren/rules" ]; then
        echo "frieren"
    fi
}

# 获取 category 显示名称
get_category_display_name() {
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
        other) echo "其他" ;;
    esac
}

get_frieren_frontmatter() {
    local category_key="$1"
    local scene_desc

    case "$category_key" in
        api) scene_desc="在定义 API 路由、调用接口、编写 API 文档时应用" ;;
        types) scene_desc="在定义 TypeScript 类型、接口、泛型时应用" ;;
        component) scene_desc="在开发 React 组件、设计组件 API 时应用" ;;
        hook) scene_desc="在开发自定义 Hook、封装状态逻辑时应用" ;;
        state) scene_desc="在设计状态管理、处理数据流时应用" ;;
        testing) scene_desc="在编写单元测试、集成测试、端到端测试时应用" ;;
        security) scene_desc="在实现认证鉴权、权限控制、输入校验与安全加固时应用" ;;
        pattern) scene_desc="在进行架构设计、选择设计模式时应用" ;;
        convention) scene_desc="在编写代码、命名变量、组织文件时应用" ;;
        quality) scene_desc="在代码审查、重构优化时应用" ;;
        workflow) scene_desc="在开发流程、调试排查、问题解决时应用" ;;
        *) scene_desc="在相关场景中应用" ;;
    esac

    cat << EOF
---
agentRequested: true
description: "$scene_desc"
---

EOF
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
    local category_display="$1"
    local category_key="$2"
    get_frieren_frontmatter "$category_key"

    cat << EOF
# 记忆系统 - $category_display


> 此文件自动生成，请勿手动编辑
> 运行 \`bash scripts/generate-rules.sh\` 重新生成

---

EOF
}

generate_rules() {
    mkdir -p "$OUTPUT_DIR"

    for category_key in $CATEGORIES; do
        local category_display=$(get_category_display_name "$category_key")
        local output_file="$OUTPUT_DIR/${category_key}-rules.md"
        local temp_file=$(mktemp)
        local has_rules=false

        generate_header "$category_display" "$category_key" > "$temp_file"

        for rule in "$RULES_DIR"/*.md; do
            local basename=$(basename "$rule")
            if [ "$basename" = "index.md" ] || [ "$basename" = "CHECKLIST.md" ]; then
                continue
            fi

            if [ -f "$rule" ]; then
                if [ "$category_key" = "other" ]; then
                    if ! grep -q "^category:" "$rule" || ! grep -E "^category:.*($CLASSIFIED_REGEX)" "$rule"; then
                        has_rules=true
                        extract_rule_essentials "$rule" >> "$temp_file"
                        echo -e "\n---\n" >> "$temp_file"
                    fi
                else
                    if grep -q "^category:.*$category_key" "$rule"; then
                        has_rules=true
                        extract_rule_essentials "$rule" >> "$temp_file"
                        echo -e "\n---\n" >> "$temp_file"
                    fi
                fi
            fi
        done

        if [ "$has_rules" = true ]; then
            mv "$temp_file" "$output_file"
            echo "  ✅ $output_file"
        else
            rm -f "$temp_file"
        fi
    done
}


# 主函数
main() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    if [ -n "$1" ]; then
        echo "❌ 本脚本不接受参数: $1"
        echo ""
        show_usage
        exit 1
    fi

    if [ -z "$(detect_frieren)" ]; then
        echo "⚠️  未探测到平台痕迹（.frieren）"
        echo "请先初始化对应平台目录。"
        echo ""
        show_usage
        exit 1
    fi

    echo "📖 读取规则文件..."

    if [ ! -d "$RULES_DIR" ]; then
        echo "⚠️  Rules 目录不存在: $RULES_DIR"
        exit 1
    fi

    rule_count=$(find "$RULES_DIR" -name "*.md" | wc -l | tr -d ' ')
    echo "✅ 找到 $rule_count 条规则"

    if [ "$rule_count" -eq 0 ]; then
        echo "⚠️  没有规则需要生成"
        exit 0
    fi

    echo "🎯 目标平台: frieren"
    echo ""
    echo "📝 生成 frieren 多文件规则..."
    generate_rules
    echo ""
    echo "✨ [frieren] 规则已生成到: $OUTPUT_DIR"
    echo ""

    echo "📋 统计信息:"
    for category_key in $CATEGORIES; do
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
                    if ! grep -q "^category:" "$rule" || ! grep -E "^category:.*($CLASSIFIED_REGEX)" "$rule"; then
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
