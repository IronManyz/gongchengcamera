请修复代码中 UI 不更新的问题。

## 常见原因和解决方案：

### 1. 对象属性修改不触发更新

**❌ 错误：**
```typescript
@State user: { name: string } = { name: 'Alice' }
this.user.name = 'Bob'  // 不会触发 UI 更新
```

**✅ 解决方案 1：整体替换**
```typescript
this.user = { ...this.user, name: 'Bob' }
```

**✅ 解决方案 2：使用 @Observed**
```typescript
@Observed
class User {
  name: string
}
@State user: User = new User()
this.user.name = 'Bob'  // 配合 @ObjectLink 使用
```

---

### 2. 数组元素修改不触发更新

**❌ 错误：**
```typescript
@State items: string[] = ['A', 'B']
this.items[0] = 'X'  // 不会触发更新
```

**✅ 解决方案 1：使用 splice**
```typescript
this.items.splice(0, 1, 'X')
```

**✅ 解决方案 2：整体替换**
```typescript
this.items = ['X', ...this.items.slice(1)]
```

---

### 3. 数组 sort/reverse 不触发更新

**❌ 错误：**
```typescript
this.items.sort()  // 修改了原数组但不触发更新
```

**✅ 解决方案：**
```typescript
this.items = [...this.items].sort()
```

---

### 4. 嵌套对象/数组修改

**❌ 错误：**
```typescript
@State data: { list: string[] } = { list: [] }
this.data.list.push('new')  // 不会触发更新
```

**✅ 解决方案：**
```typescript
this.data = {
  ...this.data,
  list: [...this.data.list, 'new']
}
```

---

### 5. ForEach 列表不更新

**检查项：**
- [ ] 是否提供了唯一键（第三个参数）
- [ ] 键值是否使用 ID 而非 index
- [ ] 数据修改方式是否正确

---

## 完整参考：
详见 `docs/common-pitfalls.md` 的 "UI 更新不生效" 章节
