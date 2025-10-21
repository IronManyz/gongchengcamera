# HarmonyOS ArkTS 语法速查手册

## 目录
- [基础组件结构](#基础组件结构)
- [装饰器详解](#装饰器详解)
- [状态管理](#状态管理)
- [生命周期](#生命周期)
- [布局组件](#布局组件)
- [列表渲染](#列表渲染)
- [事件处理](#事件处理)
- [资源引用](#资源引用)

---

## 基础组件结构

### 最小页面组件

```typescript
@Entry
@Component
struct Index {
  @State message: string = 'Hello World'

  build() {
    Column() {
      Text(this.message)
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
  }
}
```

### 自定义子组件

```typescript
@Component
struct CustomButton {
  @Prop label: string = 'Button'
  @Prop onClick: () => void

  build() {
    Button(this.label)
      .onClick(() => {
        this.onClick?.()
      })
  }
}
```

---

## 装饰器详解

### @Entry - 页面入口

```typescript
@Entry  // 标记为页面入口组件
@Component
struct HomePage {
  build() {
    // ...
  }
}
```

### @Component - 自定义组件

```typescript
@Component
struct MyComponent {
  build() {
    // ...
  }
}
```

### @Preview - 组件预览

```typescript
@Preview  // 可在 DevEco Studio 中预览
@Component
struct PreviewDemo {
  build() {
    Text('Preview Me')
  }
}
```

### @Reusable - 可复用组件

```typescript
@Reusable
@Component
struct ReusableItem {
  @State item: string = ''

  // 组件复用时调用
  aboutToReuse(params: ESObject) {
    this.item = params.item
  }

  build() {
    Text(this.item)
  }
}
```

---

## 状态管理

### @State - 组件内部状态

```typescript
@Component
struct CounterExample {
  @State count: number = 0  // 状态变量

  build() {
    Column() {
      Text(`Count: ${this.count}`)
      Button('Increment')
        .onClick(() => {
          this.count++  // 修改触发 UI 更新
        })
    }
  }
}
```

**支持的类型：**
- 基本类型: `string`, `number`, `boolean`
- 数组: `Array<T>`
- 对象: `Object`（浅观察）
- Date, Map, Set

### @Prop - 单向数据传递

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
  @State parentMsg: string = 'Hello'

  build() {
    Child({ message: this.parentMsg })
  }
}
```

**特点：**
- 单向传递：父 → 子
- 子组件修改不影响父组件

### @Link - 双向数据同步

```typescript
@Component
struct Child {
  @Link count: number  // 双向绑定

  build() {
    Button(`Child: ${this.count}`)
      .onClick(() => {
        this.count++  // 修改会同步到父组件
      })
  }
}

@Entry
@Component
struct Parent {
  @State parentCount: number = 0

  build() {
    Column() {
      Text(`Parent: ${this.parentCount}`)
      Child({ count: $parentCount })  // 使用 $ 传递引用
    }
  }
}
```

### @Observed + @ObjectLink - 嵌套对象观察

```typescript
@Observed
class Person {
  name: string
  age: number

  constructor(name: string, age: number) {
    this.name = name
    this.age = age
  }
}

@Component
struct PersonCard {
  @ObjectLink person: Person  // 观察对象

  build() {
    Column() {
      Text(this.person.name)
      Button('Birthday')
        .onClick(() => {
          this.person.age++  // 触发 UI 更新
        })
    }
  }
}

@Entry
@Component
struct Parent {
  @State person: Person = new Person('Alice', 25)

  build() {
    PersonCard({ person: this.person })
  }
}
```

### @Provide + @Consume - 跨层级数据共享

```typescript
@Entry
@Component
struct GrandParent {
  @Provide('themeColor') color: string = 'red'

  build() {
    Column() {
      Parent()
    }
  }
}

@Component
struct Parent {
  build() {
    Child()  // 中间层不需要传递
  }
}

@Component
struct Child {
  @Consume('themeColor') color: string  // 直接消费

  build() {
    Text('Hello')
      .fontColor(this.color)
  }
}
```

### @Watch - 状态变化监听

```typescript
@Component
struct WatchExample {
  @State @Watch('onCountChange') count: number = 0

  onCountChange() {
    console.log(`Count changed to: ${this.count}`)
  }

  build() {
    Button(`Count: ${this.count}`)
      .onClick(() => {
        this.count++  // 触发 onCountChange
      })
  }
}
```

### @Local - 本地状态 (API 12+)

```typescript
@Component
struct Child {
  @Local message: string = 'Default'  // 不会被父组件覆盖

  build() {
    Text(this.message)
  }
}

@Entry
@Component
struct Parent {
  build() {
    // 即使传递参数，子组件仍使用本地初始值
    Child({ message: 'From Parent' })  // 无效
  }
}
```

### @Track - 精细化属性观察

```typescript
@Observed
class UserInfo {
  @Track name: string  // 只有 name 变化才触发更新
  age: number          // age 变化不触发

  constructor(name: string, age: number) {
    this.name = name
    this.age = age
  }
}

@Component
struct Example {
  @State user: UserInfo = new UserInfo('Alice', 25)

  build() {
    Column() {
      Text(this.user.name)  // 只有 name 变化才重新渲染
        .fontSize(20)
    }
  }
}
```

---

## 生命周期

```typescript
@Component
struct LifecycleExample {
  @State data: string[] = []

  // 1. 组件即将出现
  aboutToAppear() {
    console.log('Component is about to appear')
    // 初始化数据、API 调用
    this.loadData()
  }

  // 2. 组件即将消失
  aboutToDisappear() {
    console.log('Component is about to disappear')
    // 清理资源、取消订阅
  }

  // 3. 组件复用时调用（配合 @Reusable）
  aboutToReuse(params: ESObject) {
    console.log('Component reused')
    this.data = params.data
  }

  // 4. 组件回收时调用
  aboutToRecycle() {
    console.log('Component recycled')
  }

  async loadData() {
    // 模拟 API 调用
    this.data = await fetchData()
  }

  build() {
    // ...
  }
}
```

---

## 布局组件

### Column - 垂直布局

```typescript
Column({ space: 10 }) {  // 子元素间距
  Text('Item 1')
  Text('Item 2')
  Text('Item 3')
}
.width('100%')
.height(200)
.justifyContent(FlexAlign.Center)  // 主轴对齐
.alignItems(HorizontalAlign.Start) // 交叉轴对齐
```

### Row - 水平布局

```typescript
Row({ space: 10 }) {
  Text('Left')
  Text('Center')
  Text('Right')
}
.width('100%')
.justifyContent(FlexAlign.SpaceBetween)
```

### Stack - 层叠布局

```typescript
Stack({ alignContent: Alignment.TopStart }) {
  Image($r('app.media.bg'))
  Text('Overlay')
}
.width(200)
.height(200)
```

### Flex - 弹性布局

```typescript
Flex({
  direction: FlexDirection.Row,
  wrap: FlexWrap.Wrap,
  justifyContent: FlexAlign.SpaceBetween
}) {
  Text('Item 1').flexGrow(1)
  Text('Item 2').flexGrow(2)
}
```

---

## 列表渲染

### ForEach - 循环渲染

```typescript
@Entry
@Component
struct ListExample {
  @State items: Array<{ id: string, name: string }> = [
    { id: '1', name: 'Apple' },
    { id: '2', name: 'Banana' }
  ]

  build() {
    List() {
      ForEach(
        this.items,                     // 数据源
        (item: { id: string, name: string }) => {  // 渲染函数
          ListItem() {
            Text(item.name)
          }
        },
        (item: { id: string, name: string }) => item.id  // 唯一键（必须！）
      )
    }
  }
}
```

### LazyForEach - 懒加载列表

```typescript
class MyDataSource implements IDataSource {
  private list: string[] = []

  totalCount(): number {
    return this.list.length
  }

  getData(index: number): string {
    return this.list[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    // ...
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    // ...
  }
}

@Entry
@Component
struct LazyListExample {
  private data: MyDataSource = new MyDataSource()

  build() {
    List() {
      LazyForEach(
        this.data,
        (item: string) => {
          ListItem() {
            Text(item)
          }
        },
        (item: string) => item
      )
    }
  }
}
```

---

## 事件处理

### 点击事件

```typescript
Button('Click Me')
  .onClick(() => {
    console.log('Button clicked')
  })
```

### 长按事件

```typescript
Text('Long Press')
  .onTouch((event: TouchEvent) => {
    if (event.type === TouchType.Down) {
      console.log('Touch down')
    }
  })
```

### 手势

```typescript
Text('Swipe Me')
  .gesture(
    PanGesture()
      .onActionStart(() => {
        console.log('Pan start')
      })
      .onActionUpdate((event: GestureEvent) => {
        console.log(`offsetX: ${event.offsetX}`)
      })
  )
```

---

## 资源引用

### 字符串资源

```typescript
Text($r('app.string.hello'))
```

### 图片资源

```typescript
Image($r('app.media.icon'))
  .width(100)
  .height(100)
```

### 颜色资源

```typescript
Text('Colored')
  .fontColor($r('app.color.primary'))
```

### Rawfile 资源

```typescript
Image($rawfile('images/logo.png'))
```

---

## 样式扩展

### @Styles - 抽取通用样式

```typescript
@Styles function commonTextStyle() {
  .fontSize(16)
  .fontColor(Color.Black)
  .margin(10)
}

Text('Example')
  .commonTextStyle()
```

### @Extend - 扩展组件

```typescript
@Extend(Text) function fancyText(size: number, color: Color) {
  .fontSize(size)
  .fontColor(color)
  .fontWeight(FontWeight.Bold)
}

Text('Fancy')
  .fancyText(20, Color.Red)
```

### @Builder - 自定义构建函数

```typescript
@Builder function HeaderBuilder(title: string) {
  Row() {
    Text(title)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
  }
  .width('100%')
  .height(60)
  .backgroundColor(Color.Blue)
}

@Entry
@Component
struct Page {
  build() {
    Column() {
      HeaderBuilder('My Page')
      // 页面内容
    }
  }
}
```

---

## 条件渲染

```typescript
@Component
struct ConditionalExample {
  @State showContent: boolean = true

  build() {
    Column() {
      if (this.showContent) {
        Text('Content Visible')
      } else {
        Text('Content Hidden')
      }

      Button('Toggle')
        .onClick(() => {
          this.showContent = !this.showContent
        })
    }
  }
}
```

---

## 路由导航

```typescript
import router from '@ohos.router'

// 跳转到页面
router.pushUrl({
  url: 'pages/Detail',
  params: {
    id: 123,
    name: 'Item'
  }
})

// 接收参数
@Entry
@Component
struct Detail {
  @State id: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    this.id = params.id as number
  }

  build() {
    Column() {
      Text(`ID: ${this.id}`)
      Button('Back')
        .onClick(() => {
          router.back()
        })
    }
  }
}
```

---

## 网络请求

```typescript
import http from '@ohos.net.http'

async function fetchData() {
  let httpRequest = http.createHttp()

  try {
    const response = await httpRequest.request(
      'https://api.example.com/data',
      {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        }
      }
    )
    return JSON.parse(response.result as string)
  } catch (error) {
    console.error('Request failed:', error)
  } finally {
    httpRequest.destroy()
  }
}
```

---

## 本地存储

```typescript
import preferences from '@ohos.data.preferences'

// 保存数据
async function saveData(key: string, value: string) {
  const prefs = await preferences.getPreferences(getContext(), 'myStore')
  await prefs.put(key, value)
  await prefs.flush()
}

// 读取数据
async function getData(key: string): Promise<string> {
  const prefs = await preferences.getPreferences(getContext(), 'myStore')
  return await prefs.get(key, '') as string
}
```
