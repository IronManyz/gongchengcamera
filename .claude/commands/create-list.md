请创建一个带有列表的 HarmonyOS 页面组件。

## 功能要求：

### 1. 数据结构
定义数据模型，包含：
- `id`: 唯一标识（string）
- 其他业务字段

### 2. 列表实现
```typescript
// 使用 ForEach（数据量 < 100）
ForEach(
  this.dataList,
  (item: DataType) => {
    ListItem() {
      // 列表项内容
    }
  },
  (item: DataType) => item.id  // ⚠️ 必须提供唯一键！
)

// 或使用 LazyForEach（数据量 >= 100）
LazyForEach(
  this.dataSource,
  (item: DataType) => {
    ListItem() {
      // 列表项内容
    }
  },
  (item: DataType) => item.id
)
```

### 3. 列表操作
实现以下功能：
- **添加项目**: 使用 `this.dataList.push(newItem)`
- **删除项目**: 使用 `this.dataList.splice(index, 1)`
- **更新项目**: 参考 `docs/common-pitfalls.md` 的正确做法

### 4. 下拉刷新（可选）
```typescript
Refresh({ refreshing: $$this.isRefreshing }) {
  List() { /* ... */ }
}
.onRefreshing(() => {
  this.loadData()
})
```

### 5. 空状态处理
```typescript
if (this.dataList.length === 0) {
  Column() {
    Image($r('app.media.empty'))
    Text('暂无数据')
  }
} else {
  List() { /* ... */ }
}
```

## 参考示例：
- `examples/list-rendering.ets` - ForEach 和 LazyForEach 完整示例
- `docs/common-pitfalls.md` - 列表更新的常见陷阱
