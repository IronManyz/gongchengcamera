请实现 HarmonyOS 表单验证功能。

## 要求：

1. **状态管理**
   - 使用 `@State` 存储表单字段
   - 使用 `@State` 存储错误信息

2. **验证规则**
   ```typescript
   // 必填验证
   if (this.username.trim() === '') {
     this.usernameError = '用户名不能为空'
   }

   // 格式验证（邮箱）
   const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
   if (!emailRegex.test(this.email)) {
     this.emailError = '邮箱格式不正确'
   }
   ```

3. **实时验证**
   - 使用 `@Watch` 监听字段变化
   - 或在 TextInput 的 `onChange` 中验证

4. **提交验证**
   ```typescript
   handleSubmit() {
     if (this.validateAll()) {
       // 提交表单
     }
   }
   ```

## 示例结构：
```typescript
@Component
struct FormExample {
  @State username: string = ''
  @State usernameError: string = ''

  @State email: string = ''
  @State emailError: string = ''

  validateUsername(): boolean { /* ... */ }
  validateEmail(): boolean { /* ... */ }
  validateAll(): boolean { /* ... */ }

  build() { /* ... */ }
}
```
