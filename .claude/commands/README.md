# 自定义 Slash Commands 使用指南

这个目录包含鸿蒙开发专用的自定义命令，让 Claude Code 更高效地帮助你开发。

## 📖 可用命令

### 1. `/create-page` - 创建新页面

快速创建符合规范的 HarmonyOS 页面组件。

**使用方法：**
```
/create-page 创建一个用户列表页面，包含搜索功能
```

**Claude 会帮你：**
- ✅ 使用正确的装饰器
- ✅ 遵循命名规范
- ✅ 实现生命周期管理
- ✅ 避免常见陷阱

---

### 2. `/review` - 代码审查

全面审查 HarmonyOS 代码，检查潜在问题。

**使用方法：**
```
/review 审查以下代码

[粘贴你的代码]
```

**检查内容：**
- 状态管理是否正确
- 列表渲染是否有问题
- 生命周期使用是否恰当
- 性能优化建议
- 常见陷阱检测

---

### 3. `/create-list` - 创建列表页面

创建带有列表功能的页面组件。

**使用方法：**
```
/create-list 创建一个商品列表页面，支持下拉刷新
```

**功能包括：**
- ForEach/LazyForEach 选择建议
- 列表增删改操作
- 空状态处理
- 下拉刷新（可选）

---

### 4. `/fix-update` - 修复 UI 不更新

诊断和修复 UI 不更新的问题。

**使用方法：**
```
/fix-update 我的数组修改了但 UI 没有更新

[粘贴问题代码]
```

**解决的问题：**
- 对象属性修改不生效
- 数组元素修改不生效
- sort/reverse 不触发更新
- 嵌套数据修改问题

---

## 🎯 工作原理

当你使用 `/create-page` 时：

1. Claude Code 读取 `.claude/commands/create-page.md` 文件
2. 将文件内容作为系统提示词
3. 结合你的具体需求生成代码
4. 自动遵循 `.clinerules` 和参考文档

## 💡 创建自定义命令

你可以添加自己的命令！只需在此目录创建 `.md` 文件：

```markdown
<!-- .claude/commands/my-command.md -->

请实现XXX功能。

## 要求：
1. ...
2. ...

## 参考：
- 文档路径
- 示例代码
```

然后使用：
```
/my-command 具体需求描述
```

## 📚 命令设计最佳实践

### 1. 明确的指令
```markdown
✅ 请使用 HarmonyOS ArkTS 语法创建...
❌ 帮我做一个...
```

### 2. 包含检查清单
```markdown
## 检查项：
- [ ] 是否使用正确的装饰器
- [ ] 是否提供唯一键
```

### 3. 引用知识库文档
```markdown
## 参考：
- `.clinerules`
- `docs/state-management.md`
- `examples/list-rendering.ets`
```

### 4. 提供示例代码
```markdown
## 正确示例：
\`\`\`typescript
@State items: Item[] = []
this.items.push(newItem)  // ✅
\`\`\`
```

## 🔧 推荐工作流

### 场景 1：创建新页面
```bash
1. /create-page 创建待办事项列表页
2. [Claude 生成代码]
3. /review 审查生成的代码
4. [根据建议调整]
```

### 场景 2：解决问题
```bash
1. /fix-update 我的列表不更新
2. [Claude 分析并提供解决方案]
3. 应用修复
```

### 场景 3：快速开发
```bash
1. /create-list 创建商品列表
2. [Claude 生成基础代码]
3. 根据业务需求调整
4. /review 最终审查
```

## 🌟 命令组合使用

复杂任务可以组合命令：

**示例：创建完整的 CRUD 页面**
```
1. /create-list 创建用户列表页面
2. /create-page 创建用户详情页面
3. /create-page 创建用户编辑页面
4. /review 审查以上三个页面的代码
```

## ⚙️ 配置建议

在项目 `.claude/` 目录下可以添加：

```
.claude/
├── commands/          # 自定义命令
│   ├── create-page.md
│   ├── review.md
│   ├── create-list.md
│   └── fix-update.md
├── prompts/           # 可选：提示词模板
└── snippets/          # 可选：代码片段
```

## 📝 更新命令

修改已有命令：

1. 编辑对应的 `.md` 文件
2. 保存
3. 下次使用时自动生效（无需重启）

---

## 🆘 常见问题

**Q: 命令不生效？**
A: 确保文件在 `.claude/commands/` 目录，且文件名与命令名一致。

**Q: 可以嵌套调用命令吗？**
A: 不可以，但可以在命令中引用其他命令的逻辑。

**Q: 命令会覆盖 .clinerules 吗？**
A: 不会，命令是补充，.clinerules 始终生效。

---

**提示：** 善用这些命令可以大幅提升开发效率！🚀
