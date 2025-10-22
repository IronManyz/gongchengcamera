#!/bin/bash

# EngineeringCamera 生产环境构建脚本
# 用于生成生产环境的发布版本

set -e  # 遇到错误立即退出

# 配置变量
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
OUTPUT_DIR="${BUILD_DIR}/outputs/production"
LOG_FILE="${BUILD_DIR}/build-production.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1" | tee -a "$LOG_FILE"
}

# 检查环境
check_environment() {
    log_step "检查构建环境..."

    # 检查HarmonyOS SDK
    if ! command -v hvigorw &> /dev/null; then
        log_error "hvigorw 命令未找到，请确保已安装HarmonyOS SDK"
        exit 1
    fi

    # 检查签名文件
    if [ ! -f "${PROJECT_ROOT}/signature/release/engineering_camera_release.cer" ]; then
        log_warn "发布签名证书未找到，将使用调试签名"
    fi

    # 检查构建目录
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"

    log_info "环境检查完成"
}

# 清理构建目录
clean_build() {
    log_step "清理构建目录..."

    cd "$PROJECT_ROOT"
    hvigorw clean >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        log_info "构建目录清理完成"
    else
        log_error "构建目录清理失败"
        exit 1
    fi
}

# 构建生产版本
build_production() {
    log_step "构建生产版本..."

    cd "$PROJECT_ROOT"

    # 使用生产环境配置构建
    hvigorw assembleHap \
        -p module=entry@production \
        -p product=production \
        --mode=release \
        >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        log_info "生产版本构建成功"
    else
        log_error "生产版本构建失败"
        log_error "请查看日志文件: $LOG_FILE"
        exit 1
    fi
}

# 验证构建结果
verify_build() {
    log_step "验证构建结果..."

    # 查找生成的HAP文件
    HAP_FILE=$(find "$PROJECT_ROOT" -name "*.hap" -type f | head -1)

    if [ -z "$HAP_FILE" ]; then
        log_error "未找到生成的HAP文件"
        exit 1
    fi

    # 复制到输出目录
    cp "$HAP_FILE" "$OUTPUT_DIR/"

    # 获取文件信息
    FILE_SIZE=$(stat -f%z "$HAP_FILE" 2>/dev/null || stat -c%s "$HAP_FILE" 2>/dev/null)
    FILE_NAME=$(basename "$HAP_FILE")

    log_info "构建验证完成:"
    log_info "  文件名: $FILE_NAME"
    log_info "  文件大小: $(($FILE_SIZE / 1024 / 1024)) MB"
    log_info "  输出目录: $OUTPUT_DIR"
}

# 生成构建报告
generate_report() {
    log_step "生成构建报告..."

    REPORT_FILE="${OUTPUT_DIR}/build-report.txt"

    cat > "$REPORT_FILE" << EOF
EngineeringCamera 生产环境构建报告
=====================================

构建时间: $(date)
构建环境: HarmonyOS NEXT
构建模式: 生产模式 (Release)

构建信息:
- 项目路径: $PROJECT_ROOT
- 输出目录: $OUTPUT_DIR
- 日志文件: $LOG_FILE

构建产物:
$(ls -la "$OUTPUT_DIR/")

构建统计:
- 构建开始时间: $(head -1 "$LOG_FILE")
- 构建完成时间: $(tail -1 "$LOG_FILE")
- 总耗时: TODO (需要解析日志计算)

注意事项:
1. 请在发布前进行充分测试
2. 确认签名证书的有效性
3. 验证应用功能的完整性
4. 检查性能指标是否达标

EOF

    log_info "构建报告已生成: $REPORT_FILE"
}

# 主函数
main() {
    echo "EngineeringCamera 生产环境构建脚本"
    echo "====================================="
    echo ""

    # 记录开��时间
    START_TIME=$(date +%s)

    # 创建日志文件
    echo "构建开始时间: $(date)" > "$LOG_FILE"

    # 执行构建流程
    check_environment
    clean_build
    build_production
    verify_build
    generate_report

    # 计算总耗时
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    log_step "构建完成!"
    log_info "总耗时: ${DURATION} 秒"
    log_info "输出目录: $OUTPUT_DIR"
    log_info "构建日志: $LOG_FILE"

    echo ""
    echo -e "${GREEN}✅ 生产环境构建成功完成!${NC}"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi