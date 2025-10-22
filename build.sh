#!/bin/bash

# EngineeringCamera 构建脚本
# 用于验证代码编译通过后进行git提交

echo "🚀 开始构建 EngineeringCamera 项目..."

# 清理项目
echo "📹 清理项目..."
hvigorw clean

# 执行构建
echo "🔨 执行构建..."
if hvigorw assembleHap; then
    echo "✅ 构建成功！"
    exit 0
else
    echo "❌ 构建失败！请修复编译错误后再提交。"
    exit 1
fi