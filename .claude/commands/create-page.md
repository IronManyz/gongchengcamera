请使用 HarmonyOS ArkTS 语法创建一个新的页面组件。

## 要求：

1. **组件结构**
   - 使用 `@Entry` 和 `@Component` 装饰器
   - 实现 `build()` 方法
   - 使用声明式 UI

2. **状态管理**
   - 根据需求选择合适的装饰器（@State, @Prop, @Link 等）
   - 参考 `docs/state-management.md` 的最佳实践

3. **生命周期**
   - 在 `aboutToAppear()` 中初始化数据
   - 如有需要，在 `aboutToDisappear()` 中清理资源

4. **命名规范**
   - 组件名使用大驼峰（PascalCase）
   - 文件名使用小驼峰（camelCase）

5. **代码规范**
   - 遵循 `.clinerules` 中的开发规范
   - 避免 `docs/common-pitfalls.md` 中的常见错误
   - ForEach 必须提供唯一键

## 参考文档：
- `.clinerules` - 核心开发规范
- `docs/harmonyos-syntax.md` - 语法参考
- `examples/` - 代码示例
