/**
 * 状态管理示例
 * 展示 @State, @Prop, @Link, @Observed, @ObjectLink 的用法
 */

// ========== @State 基本用法 ==========
@Component
struct StateExample {
  @State counter: number = 0

  build() {
    Column() {
      Text(`Counter: ${this.counter}`)
      Button('Increment')
        .onClick(() => {
          this.counter++
        })
    }
  }
}

// ========== @Prop 单向传递 ==========
@Component
struct ChildWithProp {
  @Prop message: string

  build() {
    Text(this.message)
      .fontSize(20)
  }
}

// ========== @Link 双向绑定 ==========
@Component
struct ChildWithLink {
  @Link count: number

  build() {
    Row() {
      Button('-')
        .onClick(() => {
          this.count--
        })
      Text(`${this.count}`)
        .margin({ left: 10, right: 10 })
      Button('+')
        .onClick(() => {
          this.count++
        })
    }
  }
}

// ========== @Observed + @ObjectLink 嵌套对象 ==========
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
    Column() {
      Text(`Name: ${this.user.name}`)
      Text(`Age: ${this.user.age}`)
      Button('Birthday')
        .onClick(() => {
          this.user.age++  // 触发 UI 更新
        })
    }
    .padding(10)
    .border({ width: 1, color: Color.Gray })
  }
}

// ========== 完整示例 ==========
@Entry
@Component
struct StateManagementExample {
  @State parentCount: number = 0
  @State user: User = new User('Alice', 25)

  build() {
    Scroll() {
      Column({ space: 20 }) {
        // @State 示例
        Text('@State Example')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        StateExample()

        Divider()

        // @Prop 示例
        Text('@Prop Example')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        ChildWithProp({ message: 'Hello from Parent' })

        Divider()

        // @Link 示例
        Text('@Link Example')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text(`Parent Count: ${this.parentCount}`)
        ChildWithLink({ count: $parentCount })

        Divider()

        // @ObjectLink 示例
        Text('@ObjectLink Example')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        UserCard({ user: this.user })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
  }
}
