# HarmonyOS 响应式状态管理指南

## 目录
- [状态管理概述](#状态管理概述)
- [装饰器选择指南](#装饰器选择指南)
- [组件内状态 (@State)](#组件内状态-state)
- [父子组件通信](#父子组件通信)
- [复杂对象管理](#复杂对象管理)
- [跨层级数据共享](#跨层级数据共享)
- [状态监听](#状态监听)
- [高级技巧](#高级技巧)
- [实战案例](#实战案例)

---

## 状态管理概述

HarmonyOS 使用声明式 UI 框架 ArkUI,状态管理是驱动 UI 更新的核心机制。

### 核心概念

```
数据变化 → 状态更新 → UI 自动重新渲染
```

### 响应式更新原理

```typescript
@State count: number = 0

// 修改状态
this.count++  // → 触发 build() 重新执行 → UI 更新
```

---

## 装饰器选择指南

### 快速决策树

```
需要存储数据？
  ├─ 是 → 组件内部使用？
  │       ├─ 是 → 使用 @State
  │       └─ 否 → 父子组件传递？
  │               ├─ 单向传递 → 使用 @Prop
  │               └─ 双向同步 → 使用 @Link
  ├─ 复杂对象/嵌套数据？
  │       └─ 使用 @Observed + @ObjectLink
  └─ 跨多层组件共享？
          └─ 使用 @Provide + @Consume
```

### 装饰器对比表

| 装饰器 | 用途 | 数据流向 | 支持类型 | 性能 |
|--------|------|----------|----------|------|
| @State | 组件内部状态 | 单向 | 所有类型 | 中等 |
| @Prop | 父传子（单向） | 父→子 | 所有类型 | 高 |
| @Link | 父子双向同步 | 双向 | 所有类型 | 中等 |
| @Provide/@Consume | 跨层级共享 | 双向 | 所有类型 | 中等 |
| @Observed/@ObjectLink | 嵌套对象观察 | 双向 | 类实例 | 低 |
| @Watch | 状态监听 | - | 配合其他 | 低 |
| @Local | 本地状态(API 12+) | 单向 | 所有类型 | 高 |
| @Track | 精细化观察 | - | 类属性 | 高 |

---

## 组件内状态 (@State)

### 基本用法

```typescript
@Component
struct Counter {
  @State count: number = 0  // 可观察的状态

  build() {
    Column() {
      Text(`Count: ${this.count}`)
      Button('Add')
        .onClick(() => {
          this.count++  // 修改触发 UI 更新
        })
    }
  }
}
```

### 支持的数据类型

#### 1. 基本类型

```typescript
@State name: string = 'Alice'
@State age: number = 25
@State isActive: boolean = true
```

#### 2. 数组

```typescript
@State items: string[] = ['A', 'B', 'C']

// ✅ 触发更新的操作
this.items.push('D')
this.items.pop()
this.items.splice(0, 1)
this.items = [...this.items, 'E']

// ❌ 不触发更新
this.items[0] = 'X'  // 直接索引赋值
this.items.sort()     // 不改变引用的方法
```

#### 3. 对象（浅观察）

```typescript
@State user: { name: string, age: number } = { name: 'Bob', age: 30 }

// ✅ 触发更新
this.user = { name: 'Alice', age: 25 }

// ❌ 不触发更新
this.user.name = 'Alice'
this.user.age = 25
```

#### 4. Date

```typescript
@State currentDate: Date = new Date()

// ✅ 触发更新
this.currentDate = new Date()

// ❌ 不触发更新
this.currentDate.setHours(10)
```

### 多状态管理

```typescript
@Component
struct UserProfile {
  @State name: string = ''
  @State age: number = 0
  @State email: string = ''
  @State isLoading: boolean = false

  aboutToAppear() {
    this.loadUserData()
  }

  async loadUserData() {
    this.isLoading = true
    try {
      const data = await fetchUser()
      this.name = data.name
      this.age = data.age
      this.email = data.email
    } finally {
      this.isLoading = false
    }
  }

  build() {
    if (this.isLoading) {
      LoadingProgress()
    } else {
      Column() {
        Text(this.name)
        Text(`${this.age}`)
        Text(this.email)
      }
    }
  }
}
```

---

## 父子组件通信

### @Prop - 单向传递（父→子）

```typescript
@Component
struct Child {
  @Prop message: string  // 从父组件接收

  build() {
    Text(this.message)
  }
}

@Entry
@Component
struct Parent {
  @State parentMessage: string = 'Hello from Parent'

  build() {
    Column() {
      Text(this.parentMessage)
      Child({ message: this.parentMessage })

      Button('Change in Parent')
        .onClick(() => {
          this.parentMessage = 'Updated'  // 子组件会自动更新
        })
    }
  }
}
```

**特点：**
- 父组件修改 → 子组件自动更新
- 子组件修改 → 不影响父组件
- 适合：配置、属性传递

### @Link - 双向同步

```typescript
@Component
struct Counter {
  @Link count: number  // 双向绑定

  build() {
    Row() {
      Button('-')
        .onClick(() => {
          this.count--  // 修改会同步到父组件
        })
      Text(`${this.count}`)
      Button('+')
        .onClick(() => {
          this.count++
        })
    }
  }
}

@Entry
@Component
struct Parent {
  @State totalCount: number = 0

  build() {
    Column() {
      Text(`Total: ${this.totalCount}`)
      Counter({ count: $totalCount })  // 使用 $ 传递引用
      Counter({ count: $totalCount })
      // 两个 Counter 会同步更新
    }
  }
}
```

**特点：**
- 双向同步：父 ↔ 子
- 必须使用 `$` 传递
- 适合：表单、计数器等需要双向绑定的场景

### 何时使用 @Prop vs @Link

```typescript
// ✅ 使用 @Prop：只读属性
@Component
struct UserCard {
  @Prop username: string
  @Prop avatarUrl: string

  build() {
    Row() {
      Image(this.avatarUrl)
      Text(this.username)
    }
  }
}

// ✅ 使用 @Link：需要修改
@Component
struct SettingSwitch {
  @Link isEnabled: boolean

  build() {
    Toggle({ isOn: this.isEnabled })
      .onChange((value: boolean) => {
        this.isEnabled = value  // 同步到父组件
      })
  }
}
```

---

## 复杂对象管理

### @Observed + @ObjectLink

用于观察嵌套对象的属性变化。

```typescript
@Observed
class Task {
  name: string
  isFinished: boolean

  constructor(name: string, isFinished: boolean = false) {
    this.name = name
    this.isFinished = isFinished
  }
}

@Component
struct TaskItem {
  @ObjectLink task: Task  // 观察对象

  build() {
    Row() {
      Text(this.task.name)
        .decoration({
          type: this.task.isFinished ? TextDecorationType.LineThrough : TextDecorationType.None
        })
      Checkbox({ select: this.task.isFinished })
        .onChange((value: boolean) => {
          this.task.isFinished = value  // ✅ 触发 UI 更新
        })
    }
  }
}

@Entry
@Component
struct TodoList {
  @State tasks: Task[] = [
    new Task('Learn ArkTS'),
    new Task('Build App')
  ]

  build() {
    List() {
      ForEach(
        this.tasks,
        (task: Task) => {
          ListItem() {
            TaskItem({ task: task })
          }
        },
        (task: Task) => task.name
      )
    }
  }
}
```

### @Track - 精细化属性观察

只观察被 `@Track` 装饰的属性，优化性能。

```typescript
@Observed
class UserInfo {
  @Track name: string        // 只有 name 变化才触发更新
  age: number                // age 变化不触发
  @Track avatar: string      // avatar 变化触发更新

  constructor(name: string, age: number, avatar: string) {
    this.name = name
    this.age = age
    this.avatar = avatar
  }
}

@Component
struct UserProfile {
  @State user: UserInfo = new UserInfo('Alice', 25, 'avatar.png')

  build() {
    Column() {
      Image(this.user.avatar)  // avatar 变化会更新
      Text(this.user.name)     // name 变化会更新
      // age 变化不会触发此组件重新渲染
    }
  }
}
```

**使用场景：**
- 类有很多属性，但只关心部分
- 优化渲染性能
- 减少不必要的 UI 更新

---

## 跨层级数据共享

### @Provide + @Consume

不需要逐层传递，跨组件直接共享数据。

```typescript
@Entry
@Component
struct AppRoot {
  @Provide('themeColor') color: string = '#007DFF'
  @Provide('fontSize') fontSize: number = 16

  build() {
    Column() {
      PageHeader()  // 可以消费 themeColor
      PageContent() // 可以消费 themeColor 和 fontSize
    }
  }
}

@Component
struct PageHeader {
  @Consume('themeColor') color: string

  build() {
    Row() {
      Text('Header')
        .fontColor(this.color)  // 使用祖先组件的数据
    }
  }
}

@Component
struct PageContent {
  @Consume('themeColor') color: string
  @Consume('fontSize') fontSize: number

  build() {
    Column() {
      Text('Content')
        .fontColor(this.color)
        .fontSize(this.fontSize)
      Button('Change Theme')
        .onClick(() => {
          this.color = '#FF0000'  // 修改会同步到所有消费者
        })
    }
  }
}
```

**特点：**
- 双向同步
- 跨越中间层级
- 使用字符串 key 匹配
- 适合：主题、语言、用户信息等全局状态

---

## 状态监听

### @Watch - 状态变化回调

```typescript
@Component
struct SearchBar {
  @State @Watch('onQueryChange') query: string = ''
  @State searchResults: string[] = []

  onQueryChange() {
    console.log(`Query changed to: ${this.query}`)
    this.performSearch()
  }

  async performSearch() {
    if (this.query.length > 0) {
      this.searchResults = await search(this.query)
    } else {
      this.searchResults = []
    }
  }

  build() {
    Column() {
      TextInput({ placeholder: 'Search...', text: this.query })
        .onChange((value: string) => {
          this.query = value  // 触发 onQueryChange
        })

      List() {
        ForEach(this.searchResults, (item: string) => {
          ListItem() {
            Text(item)
          }
        })
      }
    }
  }
}
```

### 监听多个状态

```typescript
@Component
struct Form {
  @State @Watch('validate') username: string = ''
  @State @Watch('validate') password: string = ''
  @State isValid: boolean = false

  validate() {
    this.isValid = this.username.length > 0 && this.password.length > 6
  }

  build() {
    Column() {
      TextInput({ placeholder: 'Username', text: this.username })
        .onChange((value: string) => {
          this.username = value
        })
      TextInput({ placeholder: 'Password', text: this.password })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.password = value
        })
      Button('Submit')
        .enabled(this.isValid)
    }
  }
}
```

---

## 高级技巧

### 1. 状态提升（State Lifting）

当多个子组件需要共享状态时，将状态提升到共同的父组件。

```typescript
@Entry
@Component
struct Parent {
  @State sharedData: string = 'Shared'

  build() {
    Column() {
      ChildA({ data: $sharedData })
      ChildB({ data: $sharedData })
      // 两个子组件共享同一状态
    }
  }
}

@Component
struct ChildA {
  @Link data: string

  build() {
    Text(this.data)
  }
}

@Component
struct ChildB {
  @Link data: string

  build() {
    TextInput({ text: this.data })
      .onChange((value: string) => {
        this.data = value  // 同步到 ChildA
      })
  }
}
```

### 2. 计算属性模式

```typescript
@Component
struct ShoppingCart {
  @State items: Array<{ price: number, quantity: number }> = []

  // 计算总价
  get totalPrice(): number {
    return this.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  }

  build() {
    Column() {
      ForEach(this.items, (item) => {
        Text(`${item.quantity} x $${item.price}`)
      })
      Text(`Total: $${this.totalPrice}`)
    }
  }
}
```

### 3. 状态组合

将相关状态组合成对象，减少状态变量数量。

```typescript
// ❌ 不推荐：状态分散
@State firstName: string = ''
@State lastName: string = ''
@State age: number = 0
@State email: string = ''

// ✅ 推荐：状态组合
@Observed
class UserForm {
  firstName: string = ''
  lastName: string = ''
  age: number = 0
  email: string = ''
}

@State form: UserForm = new UserForm()
```

---

## 实战案例

### 案例1: 待办事项列表

```typescript
@Observed
class TodoItem {
  id: string
  @Track text: string
  @Track isCompleted: boolean

  constructor(text: string) {
    this.id = Date.now().toString()
    this.text = text
    this.isCompleted = false
  }
}

@Component
struct TodoItemView {
  @ObjectLink item: TodoItem

  build() {
    Row() {
      Checkbox({ select: this.item.isCompleted })
        .onChange((value: boolean) => {
          this.item.isCompleted = value
        })
      Text(this.item.text)
        .decoration({
          type: this.item.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None
        })
    }
  }
}

@Entry
@Component
struct TodoApp {
  @State todos: TodoItem[] = []
  @State newTodoText: string = ''

  build() {
    Column() {
      Row() {
        TextInput({ placeholder: 'New todo...', text: this.newTodoText })
          .onChange((value: string) => {
            this.newTodoText = value
          })
        Button('Add')
          .onClick(() => {
            if (this.newTodoText.trim()) {
              this.todos.push(new TodoItem(this.newTodoText))
              this.newTodoText = ''
            }
          })
      }

      List() {
        ForEach(
          this.todos,
          (todo: TodoItem) => {
            ListItem() {
              TodoItemView({ item: todo })
            }
          },
          (todo: TodoItem) => todo.id
        )
      }
    }
  }
}
```

### 案例2: 多步骤表单

```typescript
@Observed
class FormData {
  step1: { name: string, email: string } = { name: '', email: '' }
  step2: { address: string, phone: string } = { address: '', phone: '' }
}

@Component
struct Step1 {
  @ObjectLink formData: FormData

  build() {
    Column() {
      TextInput({ placeholder: 'Name', text: this.formData.step1.name })
        .onChange((value: string) => {
          this.formData.step1.name = value
        })
      TextInput({ placeholder: 'Email', text: this.formData.step1.email })
        .onChange((value: string) => {
          this.formData.step1.email = value
        })
    }
  }
}

@Component
struct Step2 {
  @ObjectLink formData: FormData

  build() {
    Column() {
      TextInput({ placeholder: 'Address', text: this.formData.step2.address })
        .onChange((value: string) => {
          this.formData.step2.address = value
        })
      TextInput({ placeholder: 'Phone', text: this.formData.step2.phone })
        .onChange((value: string) => {
          this.formData.step2.phone = value
        })
    }
  }
}

@Entry
@Component
struct MultiStepForm {
  @State currentStep: number = 1
  @State formData: FormData = new FormData()

  build() {
    Column() {
      if (this.currentStep === 1) {
        Step1({ formData: this.formData })
      } else {
        Step2({ formData: this.formData })
      }

      Row() {
        if (this.currentStep > 1) {
          Button('Previous')
            .onClick(() => {
              this.currentStep--
            })
        }
        if (this.currentStep < 2) {
          Button('Next')
            .onClick(() => {
              this.currentStep++
            })
        } else {
          Button('Submit')
            .onClick(() => {
              console.log('Form data:', JSON.stringify(this.formData))
            })
        }
      }
    }
  }
}
```

---

## 性能优化建议

1. **使用 @Track 精细化观察**
   - 大对象只标记需要观察的属性

2. **避免过度使用 @State**
   - 拆分组件，减少单组件状态数量

3. **使用 @Local 避免覆盖**
   - API 12+ 中使用 @Local 保护组件内部状态

4. **合理使用 @Provide/@Consume**
   - 只用于真正需要跨层级共享的数据

5. **状态设计原则**
   - 单一职责：每个状态变量只负责一件事
   - 最小化：只存储必要的状态
   - 扁平化：避免过深的嵌套结构
