# 鸿蒙 Spec-Driven 开发指南

使用三个 AI Agent 实现严格的规格驱动开发流程，类似于 AWS Kiro 的开发模式。

---

## 🎯 Spec-Driven 开发流程

```
需求分析 → 技术设计 → 任务拆解 → 代码实现
    ↓          ↓          ↓          ↓
  .ai-rules/  design.md  tasks.md   代码+编译验证
```

---

## 🤖 三个 Agent 的职责

### 1. **steering-architect** (项目分析师)
- **作用**: 分析现有代码库，创建项目指导文件
- **输出**: `.ai-rules/product.md`, `.ai-rules/tech.md`, `.ai-rules/structure.md`
- **何时使用**: 项目初始化、架构分析、创建项目规范

### 2. **strategic-planner** (项目规划师)
- **作用**: 功能需求分析、技术设计、任务拆解
- **输出**: `specs/<feature>/requirements.md`, `design.md`, `tasks.md`
- **何时使用**: 制定新功能规划、需求分析、技术设计

### 3. **task-executor** (任务执行器)
- **作用**: 执行 tasks.md 中的任务，生成代码
- **输出**: 代码实现 + Git 提交
- **何时使用**: 执行具体编码任务、实现特定功能

---

## 📋 完整开发流程示例

### Step 1: 初始化项目规范

```
@steering-architect 分析现有代码库并创建项目指导文件
```

**Agent 会做什么：**
1. 扫描项目目录结构（entry/src/main/ets/）
2. 分析 oh-package.json5, module.json5
3. 识别 ArkTS 语法和装饰器使用
4. 生成三个文件：
   - `.ai-rules/product.md` - 项目愿景和目标
   - `.ai-rules/tech.md` - HarmonyOS 技术栈
   - `.ai-rules/structure.md` - 目录结构和命名规范

**示例输出 `.ai-rules/tech.md`:**
```markdown
---
title: Technology Stack
description: "HarmonyOS technology stack and development tools"
inclusion: always
---

# Technology Stack

## Platform
- **HarmonyOS NEXT**
- **API Version**: 12
- **Target Devices**: Phone, Tablet

## Language & Framework
- **ArkTS** (TypeScript superset)
- **ArkUI** (Declarative UI framework)

## State Management
- Local State: @State, @Prop, @Link
- Complex Objects: @Observed + @ObjectLink
- Global State: AppStorage

## Core APIs
- HTTP: @ohos.net.http
- Storage: Preferences
- Navigation: @ohos.router
```

---

### Step 2: 规划功能需求

```
@strategic-planner

我想开发一个待办事项应用，需要包含：
- 任务列表页面（首页）
- 添加任务功能
- 编辑/删除任务
- 标记任务完成
- 任务持久化存储
```

**Agent 会引导你完成三个阶段：**

#### Phase 1: 需求定义
Agent 会询问：
- "功能名称（kebab-case）？" → 你输入: `todo-app`
- "用户能否编辑任务标题？"
- "需要任务优先级吗？"
- "需要截止日期吗？"

生成 `specs/todo-app/requirements.md`:
```markdown
# Requirements: Todo App

## User Stories

### US-1: View Task List
**As a** user
**I want to** view all my tasks
**So that** I can see what needs to be done

**Acceptance Criteria:**
- When the app starts, then all tasks are displayed in a list
- When there are no tasks, then an empty state is shown

### US-2: Add New Task
**As a** user
**I want to** add a new task
**So that** I can track new to-dos

**Acceptance Criteria:**
- When I tap the add button, then a form appears
- When I enter a title and submit, then the task is added to the list
- When title is empty, then an error message is shown
```

#### Phase 2: 技术设计
Agent 会生成 `specs/todo-app/design.md`:
```typescript
# Technical Design: Todo App

## Data Models

@Observed
class TodoItem {
  @Track id: string
  @Track title: string
  @Track isCompleted: boolean
  createdAt: Date

  constructor(title: string) {
    this.id = Date.now().toString()
    this.title = title
    this.isCompleted = false
    this.createdAt = new Date()
  }
}

## Component Structure

### TodoListPage (pages/todoList.ets)
- @Entry @Component
- @State items: TodoItem[]
- @State isLoading: boolean
- Methods: loadTodos(), addTodo(), toggleTodo(), deleteTodo()

### TodoItem Component (components/todoItem.ets)
- @Component
- @ObjectLink item: TodoItem
- Methods: handleToggle(), handleDelete()

## State Management
- Use @State for items array in TodoListPage
- Use @Observed + @ObjectLink for individual TodoItem
- Use @Track on id, title, isCompleted for performance

## Data Persistence
- Use Preferences API for lightweight storage
- Key: "todo_items"
- Format: JSON.stringify(items)
```

#### Phase 3: 任务拆解
Agent 会生成 `specs/todo-app/tasks.md`:
```markdown
# Plan: todo-app

## Tasks
- [ ] 1. Create data models
  - [ ] 1.1 Define TodoItem class in models/todoItem.ets
  - [ ] 1.2 Add @Observed decorator
  - [ ] 1.3 Add @Track to id, title, isCompleted
  - Test: Run `hvigorw assembleHap` - models compile successfully

- [ ] 2. Create todo list page
  - [ ] 2.1 Run command: `/create-page TodoList with list of todos`
  - [ ] 2.2 Implement @State items array
  - [ ] 2.3 Add aboutToAppear() to load saved todos
  - Test: Manual - page displays empty state

- [ ] 3. Implement list rendering
  - [ ] 3.1 Run command: `/create-list with TodoItem data model`
  - [ ] 3.2 Ensure ForEach has unique key (item.id)
  - [ ] 3.3 Display item title and completion status
  - Test: Manual - list displays hardcoded items

- [ ] 4. Implement add todo功能
  - [ ] 4.1 Add TextInput for new todo title
  - [ ] 4.2 Add Button to submit
  - [ ] 4.3 Implement addTodo() method with validation
  - [ ] 4.4 Use this.items.push(newItem) to add
  - Test: Manual - can add new todos, list updates

- [ ] 5. Implement toggle completion
  - [ ] 5.1 Add Checkbox to each list item
  - [ ] 5.2 Implement toggleTodo() method
  - [ ] 5.3 Update item.isCompleted
  - Test: Manual - can toggle completion, UI updates

- [ ] 6. Code review
  - [ ] 6.1 Run command: `/review` on all files
  - [ ] 6.2 Fix issues (check ForEach keys, state management)
  - Test: All review issues resolved

- [ ] 7. Build verification
  - [ ] 7.1 Run: `hvigorw assembleHap`
  - [ ] 7.2 Fix any compilation errors
  - Test: Build succeeds without warnings

- [ ] 8. Version control
  - [ ] 8.1 Git add all modified files
  - [ ] 8.2 Git commit -m "feat: implement todo app core features"
  - Test: Changes committed successfully

## Rules & Tips
- Reference `.clinerules` for all development standards
- Check `docs/common-pitfalls.md` for array update patterns
- Use `examples/list-rendering.ets` for ForEach reference
- Run `hvigorw assembleHap` after each major change
- ForEach MUST have unique keys - use item.id
- Use @Observed + @ObjectLink for TodoItem
- Avoid this.items[index] = newValue, use splice instead
```

---

### Step 3: 执行任务

```
@task-executor 执行 specs/todo-app/tasks.md 中的任务

执行要求：
1. 版本控制
   - 每完成一个小节后必须进行 Git 提交
   - 提交前必须确保代码编译通过
   - 提交信息应清晰描述完成的内容

2. 编译验证
   - 使用bash执行命令 `hvigorw assembleHap` 进行编译检查
   - 确认无编译错误后方可提交代码
   - 编译失败时需修复所有错误后再提交

3. 新增文件处理
   - 新增的文件必须被正确引用
   - 对于新增文件，需创建测试页面并导入该文件以验证编译
   - 确保所有新增代码都能被编译器检测到

4. 开发规范
   - 严格遵守 `.clinerules` 中定义的鸿蒙开发规范
   - 代码风格、命名规则、架构设计均需符合规范要求
```

**Agent 会做什么：**

#### 执行任务 1.1: 定义 TodoItem 类
1. 读取 tasks.md，找到第一个未完成任务
2. 创建 `models/todoItem.ets`
3. 定义 TodoItem 类并添加 @Observed
4. 运行 `hvigorw assembleHap` 验证编译
5. 如果成功，标记任务为完成 `[x]`
6. 输出: "任务 1.1 完成，创建了 models/todoItem.ets"

#### 执行任务 2.1: 创建页面
1. 识别命令: `/create-page TodoList`
2. 读取 `.claude/commands/create-page.md` 获取模板
3. 生成 `pages/todoList.ets`，包含：
   - @Entry @Component decorators
   - @State items: TodoItem[] = []
   - aboutToAppear() 方法
   - build() 方法with Column布局
4. 确保遵循 `.clinerules` 命名规范
5. 运行 `hvigorw assembleHap`
6. 标记任务完成

#### 执行任务 3.1: 实现列表渲染
1. 识别命令: `/create-list with TodoItem`
2. 读取命令模板
3. 在 build() 中添加 ForEach：
```typescript
List() {
  ForEach(
    this.items,
    (item: TodoItem) => {
      ListItem() {
        Text(item.title)
      }
    },
    (item: TodoItem) => item.id  // ✅ 唯一键
  )
}
```
4. 运行编译验证
5. 标记完成

#### 执行任务 8.1-8.2: 版本控制
1. 执行: `git add pages/todoList.ets models/todoItem.ets`
2. 执行: `git commit -m "feat: implement todo app core features"`
3. 确认提交成功
4. 标记任务完成

---

## 🔄 迭代开发流程

### 添加新功能

**场景**: 添加任务优先级功能

```
@strategic-planner

这是对现有功能的扩展，feature name: todo-app

我想添加任务优先级功能：
- 每个任务可以设置优先级（高、中、低）
- 列表按优先级排序
- 优先级用颜色标识
```

Agent 会：
1. 加载现有的 `specs/todo-app/requirements.md`, `design.md`, `tasks.md`
2. 询问你要修改哪个阶段（Requirements/Design/Tasks）
3. 更新相应文档
4. 生成增量任务到 tasks.md

---

## 💡 最佳实践

### 1. 项目初始化（只需一次）

```
@steering-architect 分析现有代码库并创建项目指导文件
```

这会创建 `.ai-rules/` 目录，之后所有 Agent 都会引用这些规范。

### 2. 每个新功能都走完整流程

```
功能A:
@steering-architect (如果是新项目)
@strategic-planner (规划)
@task-executor (执行)

功能B:
@strategic-planner (规划)
@task-executor (执行)
...
```

### 3. 利用 Commands 加速开发

在 tasks.md 中使用:
- `/create-page` - 自动生成符合规范的页面
- `/create-list` - 自动处理列表渲染陷阱
- `/review` - 自动检查常见问题
- `/fix-update` - 快速修复 UI 不更新问题

### 4. 编译验证至关重要

每个任务完成后必须运行:
```bash
hvigorw assembleHap
```

确保：
- 新文件被正确引用
- 没有语法错误
- 装饰器使用正确

### 5. 小步提交

不要等整个功能完成才提交，每个小节（Section）完成后提交：
```bash
git add <files>
git commit -m "feat: implement task list display"
```

---

## 🛠️ 故障排查

### Q: strategic-planner 生成的 tasks 太粗糙？

**A**: 在Phase 3询问时，明确要求：
```
请生成更细粒度的任务，每个任务只做一件事，
并在每个任务后添加 build 验证步骤
```

### Q: task-executor 跳过了编译验证？

**A**: 在 tasks.md 中明确写入:
```markdown
- [ ] 1.1 创建 TodoItem 类
  - Test: Run `hvigorw assembleHap` and ensure build succeeds
```

### Q: 生成的代码不符合 .clinerules？

**A**: 运行:
```
@task-executor 执行下一个任务，严格遵守 .clinerules 和 docs/common-pitfalls.md
```

### Q: UI 不更新怎么办？

**A**: 使用 command:
```
/fix-update 我修改了数组但 UI 没有更新
```

Agent 会诊断并提供解决方案（使用 splice, 整体替换等）

---

## 📚 相关文档

- **`.clinerules`** - 鸿蒙核心开发规范
- **`docs/harmonyos-syntax.md`** - ArkTS 语法速查
- **`docs/common-pitfalls.md`** - 常见陷阱和解决方案
- **`docs/state-management.md`** - 状态管理完整指南
- **`.claude/commands/README.md`** - 命令使用说明
- **`.claude/agents/`** - Agent 详细说明

---

## 🎓 学习路径

### 新手
1. 用 `@steering-architect` 分析一个示例项目
2. 查看生成的 `.ai-rules/` 文件，理解项目结构
3. 用 `@strategic-planner` 规划一个简单功能（如计数器）
4. 用 `@task-executor` 执行任务，观察生成的代码

### 进阶
1. 尝试规划复杂功能（如待办事项应用）
2. 在 tasks.md 中集成多个 `/commands`
3. 使用自治模式让 executor 自动执行所有任务
4. 优化 tasks.md 的颗粒度

### 专家
1. 自定义 `.claude/commands/` 创建项目特定命令
2. 扩展 `.ai-rules/` 添加项目特定规范
3. 为团队创建标准化的 Agent 工作流
4. 贡献常见模式到知识库

---

## 🚀 快速开始

**5 分钟创建一个鸿蒙待办应用：**

```
1. @steering-architect 分析项目

2. @strategic-planner 开发待办应用，包含列表、添加、删除功能

3. @task-executor 执行 specs/todo-app/tasks.md 自治模式

4. 等待 Agent 完成所有任务 ✅
```

就这么简单！🎉
