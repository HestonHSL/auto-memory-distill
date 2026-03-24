#!/bin/bash
# 生成 Frieren memory-integration.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../templates/memory-integration.md"

# 动态检测项目根目录
if echo "$SCRIPT_DIR" | grep -q "/\.frieren/skills/"; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    SKILLS_PATH_FRIEREN=".frieren/skills"
else
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    SKILLS_PATH_FRIEREN=".frieren/skills"
fi

# 显示使用说明
show_usage() {
    cat << EOF
使用方法: $0

说明:
  本脚本仅生成 Frieren 集成规则（输出到 .frieren/rules/memory-integration.md）

EOF
}

detect_frieren() {
    if [ -d "$PROJECT_ROOT/.frieren" ] || [ -d "$PROJECT_ROOT/.frieren/skills" ] || [ -d "$PROJECT_ROOT/.frieren/rules" ]; then
        echo "frieren"
    fi
}

# 检查模板文件
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ 模板文件不存在: $TEMPLATE_FILE"
    exit 1
fi

# 生成 Frieren 版本
generate_frieren() {
    local output_dir="$PROJECT_ROOT/.frieren/rules"
    local output_file="$output_dir/memory-integration.md"
    
    mkdir -p "$output_dir"
    
    # 生成 frontmatter
    cat > "$output_file" << 'EOF'
---
agentRequested: true
description: "核心长期记忆集成规则。捕获纠错和修改要求，积累错误模式，形成自检清单。"
---

EOF
    
    # 添加内容，替换占位符
    sed "s|{SKILLS_PATH}|$SKILLS_PATH_FRIEREN|g" "$TEMPLATE_FILE" >> "$output_file"
    
    echo "✅ Frieren: $output_file"
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

    echo "🎯 目标平台: frieren"
    echo ""
    echo "📝 生成 Frieren 版本..."
    generate_frieren
    
    echo ""
    echo "✨ 生成完成！"
}

# 执行主函数
main "$@"
