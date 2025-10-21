# 鸿蒙开发常见问题和陷阱

## 目录
- [状态管理陷阱](#状态管理陷阱)
- [列表渲染问题](#列表渲染问题)
- [UI 更新不生效](#ui-更新不生效)
- [生命周期误用](#生命周期误用)
- [性能问题](#性能问题)
- [装饰器使用错误](#装饰器使用错误)

---

## 状态管理陷阱

### ❌ 陷阱 1: 修改对象属性不触发 UI 更新

```typescript
@Component
struct BadExample {
  @State user: { name: string, age: number } = { name: 'Alice', age: 25 }

  build() {
    Column() {
      Text(`${this.user.name}, ${this.user.age}`)
      Button('Birthday')
        .onClick(() => {
          this.user.age++  // ❌ 不会触发 UI 更新！
        })
    }
  }
}
```

**原因：** `@State` 只观察对象的引用变化，不观察对象内部属性。

**✅ 解决方案 1：整体替换对象**

```typescript
Button('Birthday')
  .onClick(() => {
    this.user = { ...this.user, age: this.user.age + 1 }  // ✅
  })
```

**✅ 解决方案 2：使用 @Observed + @ObjectLink**

```typescript
@Observed
class User {
  name: string
  age: number

  constructor(name: string, age: number) {
    this.name = name
    this.age = age
  }
}

@Component
struct UserCard {
  @ObjectLink user: User

  build() {
    Button('Birthday')
      .onClick(() => {
        this.user.age++  // ✅ 会触发更新
      })
  }
}
```

---

### ❌ 陷阱 2: 直接修改数组元素不触发更新

```typescript
@Component
struct BadArrayExample {
  @State items: string[] = ['Apple', 'Banana']

  build() {
    Column() {
      ForEach(this.items, (item: string) => {
        Text(item)
      })
      Button('Change First')
        .onClick(() => {
          this.items[0] = 'Orange'  // ❌ 不会触发 UI 更新
        })
    }
  }
}
```

**✅ 解决方案 1：使用数组方法**

```typescript
Button('Change First')
  .onClick(() => {
    this.items.splice(0, 1, 'Orange')  // ✅
  })
```

**✅ 解决方案 2：整体替换数组**

```typescript
Button('Change First')
  .onClick(() => {
    this.items = ['Orange', ...this.items.slice(1)]  // ✅
  })
```

**✅ 解决方案 3：使用 @Track 装饰器**

```typescript
@Observed
class Item {
  @Track value: string

  constructor(value: string) {
    this.value = value
  }
}

@State items: Item[] = [new Item('Apple'), new Item('Banana')]

// 现在可以直接修改
this.items[0].value = 'Orange'  // ✅
```

---

### ❌ 陷阱 3: @State 初始值被父组件覆盖

```typescript
@Component
struct Child {
  @State message: string = 'Default'  // ❌ 会被父组件覆盖

  build() {
    Text(this.message)
  }
}

@Entry
@Component
struct Parent {
  build() {
    Child({ message: 'From Parent' })  // 覆盖了子组件的初始值
  }
}
```

**✅ 解决方案：使用 @Local (API 12+)**

```typescript
@Component
struct Child {
  @Local message: string = 'Default'  // ✅ 不会被覆盖

  build() {
    Text(this.message)  // 始终显示 'Default'
  }
}
```

---

## 列表渲染问题

### ❌ 陷阱 4: ForEach 没有提供唯一键

```typescript
ForEach(
  this.items,
  (item: string, index: number) => {
    ListItem() {
      Text(item)
    }
  }
  // ❌ 缺少第三个参数（键生成函数）
)
```

**问题：** 列表更新时可能出现渲染错误、状态混乱。

**✅ 解决方案：提供唯一键**

```typescript
ForEach(
  this.items,
  (item: Item) => {
    ListItem() {
      Text(item.name)
    }
  },
  (item: Item) => item.id  // ✅ 必须提供唯一键
)
```

---

### ❌ 陷阱 5: 使用 index 作为键值

```typescript
ForEach(
  this.items,
  (item: string, index: number) => {
    ListItem() {
      Text(item)
    }
  },
  (item: string, index: number) => index.toString()  // ❌ 不推荐
)
```

**问题：** 当列表顺序改变时，会导致渲染问题。

**✅ 解决方案：使用数据的唯一标识**

```typescript
ForEach(
  this.items,
  (item: { id: string, name: string }) => {
    ListItem() {
      Text(item.name)
    }
  },
  (item: { id: string, name: string }) => item.id  // ✅ 使用唯一 ID
)
```

---

## UI 更新不生效

### ❌ 陷阱 6: 数组 sort/reverse 不触发更新

```typescript
@State items: string[] = ['C', 'A', 'B']

Button('Sort')
  .onClick(() => {
    this.items.sort()  // ❌ 不会触发 UI 更新
  })
```

**原因：** `sort()` 和 `reverse()` 会修改原数组但不改变数组引用。

**✅ 解决方案：创建新数组**

```typescript
Button('Sort')
  .onClick(() => {
    this.items = [...this.items].sort()  // ✅
  })
```

---

### ❌ 陷阱 7: 修改嵌套数组/对象

```typescript
@State data: { list: string[] } = { list: ['A', 'B'] }

Button('Add')
  .onClick(() => {
    this.data.list.push('C')  // ❌ 不会触发更新
  })
```

**✅ 解决方案 1：整体替换**

```typescript
Button('Add')
  .onClick(() => {
    this.data = {
      ...this.data,
      list: [...this.data.list, 'C']
    }  // ✅
  })
```

**✅ 解决方案 2：使用 @Observed**

```typescript
@Observed
class Data {
  list: string[] = []
}

@State data: Data = new Data()

Button('Add')
  .onClick(() => {
    this.data.list.push('C')  // ✅ 需配合 @ObjectLink
  })
```

---

## 生命周期误用

### ❌ 陷阱 8: 在 build() 中执行副作用

```typescript
build() {
  Column() {
    Text(this.fetchData())  // ❌ 不要在 build 中调用异步方法
  }
}
```

**问题：** `build()` 方法可能会被多次调用，导致重复执行。

**✅ 解决方案：在 aboutToAppear() 中执行**

```typescript
@State data: string = ''

aboutToAppear() {
  this.loadData()  // ✅
}

async loadData() {
  this.data = await fetchData()
}

build() {
  Column() {
    Text(this.data)
  }
}
```

---

### ❌ 陷阱 9: 忘记清理资源

```typescript
@Component
struct TimerExample {
  private timer: number = -1

  aboutToAppear() {
    this.timer = setInterval(() => {
      console.log('Tick')
    }, 1000)
  }

  // ❌ 忘记清理 timer
  build() {
    Text('Timer Running')
  }
}
```

**✅ 解决方案：在 aboutToDisappear() 中清理**

```typescript
aboutToDisappear() {
  if (this.timer !== -1) {
    clearInterval(this.timer)  // ✅
  }
}
```

---

## 性能问题

### ❌ 陷阱 10: 过度使用 @State

```typescript
@Component
struct BadPerformance {
  @State item1: string = ''
  @State item2: string = ''
  // ... 50 个 @State 变量
  @State item50: string = ''

  build() {
    // 任何一个变量变化都会重新渲染整个组件
  }
}
```

**✅ 解决方案：拆分组件**

```typescript
@Component
struct Item {
  @State value: string = ''

  build() {
    Text(this.value)
  }
}

@Component
struct GoodPerformance {
  build() {
    Column() {
      Item()  // 只有该子组件会重新渲染
      Item()
    }
  }
}
```

---

### ❌ 陷阱 11: 大列表使用 ForEach

```typescript
@State bigList: Item[] = Array(1000).fill({})  // 1000 个元素

build() {
  List() {
    ForEach(this.bigList, (item: Item) => {
      ListItem() {
        // ❌ 会一次性渲染所有元素
      }
    })
  }
}
```

**✅ 解决方案：使用 LazyForEach**

```typescript
class MyDataSource implements IDataSource {
  private list: Item[] = Array(1000).fill({})

  totalCount(): number {
    return this.list.length
  }

  getData(index: number): Item {
    return this.list[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {}
  unregisterDataChangeListener(listener: DataChangeListener): void {}
}

@State dataSource: MyDataSource = new MyDataSource()

build() {
  List() {
    LazyForEach(
      this.dataSource,
      (item: Item) => {
        ListItem() {
          // ✅ 按需加载
        }
      },
      (item: Item) => item.id
    )
  }
}
```

---

## 装饰器使用错误

### ❌ 陷阱 12: @Link 传递时忘记使用 $

```typescript
@Component
struct Child {
  @Link count: number

  build() {
    Text(`${this.count}`)
  }
}

@Entry
@Component
struct Parent {
  @State parentCount: number = 0

  build() {
    Child({ count: this.parentCount })  // ❌ 缺少 $
  }
}
```

**✅ 解决方案：使用 $ 传递引用**

```typescript
Child({ count: $parentCount })  // ✅
```

---

### ❌ 陷阱 13: @Observed 忘记装饰类

```typescript
class User {  // ❌ 缺少 @Observed
  name: string
  age: number
}

@Component
struct UserCard {
  @ObjectLink user: User  // 会报错

  build() {
    Text(this.user.name)
  }
}
```

**✅ 解决方案：添加 @Observed**

```typescript
@Observed  // ✅
class User {
  name: string
  age: number
}
```

---

### ❌ 陷阱 14: @Watch 回调中访问旧值

```typescript
@Component
struct WatchExample {
  @State @Watch('onCountChange') count: number = 0

  onCountChange() {
    console.log(`New count: ${this.count}`)
    // ❌ 无法获取旧值
  }
}
```

**✅ 解决方案：手动保存旧值**

```typescript
@State count: number = 0
private oldCount: number = 0

aboutToAppear() {
  this.oldCount = this.count
}

updateCount(newValue: number) {
  const old = this.count
  this.count = newValue
  console.log(`Changed from ${old} to ${newValue}`)
}
```

---

## 路由和导航问题

### ❌ 陷阱 15: 路由参数类型不安全

```typescript
// 页面 A
router.pushUrl({
  url: 'pages/Detail',
  params: { id: 123 }
})

// 页面 B
@Entry
@Component
struct Detail {
  aboutToAppear() {
    const params = router.getParams()
    const id = params.id  // ❌ 类型为 any
  }
}
```

**✅ 解决方案：定义参数接口**

```typescript
interface DetailParams {
  id: number
  name?: string
}

// 页面 B
aboutToAppear() {
  const params = router.getParams() as DetailParams
  const id: number = params.id  // ✅ 类型安全
}
```

---

## 异步操作陷阱

### ❌ 陷阱 16: 异步更新状态不在主线程

```typescript
Button('Load')
  .onClick(async () => {
    const data = await fetchData()
    this.items = data  // ⚠️ 可能不在主线程
  })
```

**✅ 解决方案：确保在主线程更新**

```typescript
Button('Load')
  .onClick(() => {
    fetchData().then((data) => {
      // Promise 的 then 会在主线程执行
      this.items = data  // ✅
    })
  })
```

---

## 资源引用错误

### ❌ 陷阱 17: 资源路径错误

```typescript
Image('app/media/icon.png')  // ❌ 错误的路径格式
```

**✅ 解决方案：使用正确的资源引用**

```typescript
Image($r('app.media.icon'))     // ✅ 推荐
Image($rawfile('images/icon.png'))  // ✅ rawfile 方式
```

---

## 最佳实践总结

### ✅ DO (推荐做法)

1. **状态管理**
   - 使用 `@Observed` + `@ObjectLink` 处理复杂对象
   - 使用 `@Track` 优化性能
   - 保持状态变量简单

2. **列表渲染**
   - 始终提供唯一键
   - 大列表使用 `LazyForEach`
   - 使用数据的 ID 作为 key

3. **生命周期**
   - 在 `aboutToAppear()` 中初始化数据
   - 在 `aboutToDisappear()` 中清理资源
   - 不在 `build()` 中执行副作用

4. **性能优化**
   - 合理拆分组件
   - 使用 `@Reusable` 组件复用
   - 避免过深的组件嵌套

### ❌ DON'T (避免做法)

1. 直接修改对象/数组属性期望触发更新
2. 在 `build()` 方法中执行异步操作
3. 使用 `index` 作为 `ForEach` 的 key
4. 忘记清理定时器、订阅等资源
5. 过度使用 `@State` 导致性能问题
