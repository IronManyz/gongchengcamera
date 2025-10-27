# 底部导航栏 Emoji 图标替换为 SVG 图标

## 概述

本次更新将项目中底部导航栏的 emoji 图标全部替换为专业的 SVG 开源图标，提升应用的视觉效果和专业性。

## 更新内容

### 1. 主页面 (MainPage.ets)

**位置**: `/entry/src/main/ets/pages/MainPage.ets`

**更改**:
- ✅ 添加 `SVGIcon` 组件导入
- ✅ 将底部导航栏的三个 emoji 图标替换为 SVG 图标：
  - 🏗️ (工程) → `SVGIcon` with `iconName: 'building'`
  - 📱 (相册) → `SVGIcon` with `iconName: 'photo'`
  - ⚙️ (设置) → `SVGIcon` with `iconName: 'settings'`

### 2. 项目列表页面 (ProjectListPage.ets)

**位置**: `/entry/src/main/ets/pages/project/ProjectListPage.ets`

**更改**:
- ✅ 添加 `SVGIcon` 组件导入
- ✅ 将高级筛选按钮的 emoji 图标替换为 SVG 图标：
  - ⚙️ → `SVGIcon` with `iconName: 'settings'`

### 3. 底部导航组件 (BottomNavigation.ets)

**位置**: `/entry/src/main/ets/components/common/BottomNavigation.ets`

**状态**: ✅ 已预配置完成

该组件已经配置好了 SVG 图标支持，所有使用此组件的页面都会自动使用 SVG 图标：
- `GalleryPlaceholderPage.ets` - 相册占位页
- `SettingsPlaceholderPage.ets` - 设置占位页
- `AboutPage.ets` - 关于页面
- `themePage.ets` - 主题设置页

## SVG 图标来源

所有 SVG 图标均使用项目中已有的开源图标资源：

| 功能 | SVG 文件 | 图标名称 |
|------|---------|---------|
| 工程 | `icon_building.svg` | building |
| 相册 | `icon_photo.svg` | photo |
| 设置 | `icon_settings.svg` | settings |

图标文件位置：`/entry/src/main/resources/base/media/`

## SVGIcon 组件

**位置**: `/entry/src/main/ets/components/icons/SVGIcon.ets`

该组件提供了统一的 SVG 图标渲染能力，支持以下特性：
- ✅ 动态颜色配置（根据选中状态自动调整颜色）
- ✅ 尺寸配置（默认 24px）
- ✅ 描边宽度配置
- ✅ 使用 Path 组件绘制，确保良好的渲染性能

## 图标颜色方案

底部导航栏图标颜色遵循以下规则：
- **选中状态**: `#1890FF` (品牌蓝色)
- **未选中状态**: `#8C8C8C` (中性灰色)
- **背景色（选中）**: `#E6F7FF` (浅蓝色背景)

## 技术优势

### 相比 Emoji 的优势

1. **视觉一致性**: SVG 图标在所有设备和系统上显示效果一致
2. **专业性**: 使用专业设计的图标，提升应用品质
3. **可定制性**: 可以动态修改颜色、大小等属性
4. **性能**: SVG 渲染性能优于复杂的 emoji
5. **清晰度**: 在不同 DPI 下都能保持清晰

### 实现方式

使用 HarmonyOS 的 `Path` 组件配合 SVG path commands 进行渲染：

```typescript
Path()
  .commands('M3 21h18v-6h-7v-6h4V3H7v6h4v6H3v6z...')
  .fill(iconColor)
  .stroke(Color.Transparent)
  .width(iconSize)
  .height(iconSize)
```

## 构建验证

✅ 项目构建成功，无错误
- 构建时间: ~10秒
- 仅有一些 deprecated API 警告（与本次更新无关）

## 影响范围

### 已更新的文件

1. `/entry/src/main/ets/pages/MainPage.ets`
2. `/entry/src/main/ets/pages/project/ProjectListPage.ets`

### 间接受益的页面（使用 BottomNavigation 组件）

1. `/entry/src/main/ets/pages/gallery/GalleryPlaceholderPage.ets`
2. `/entry/src/main/ets/pages/settings/SettingsPlaceholderPage.ets`
3. `/entry/src/main/ets/pages/about/AboutPage.ets`
4. `/entry/src/main/ets/pages/settings/themePage.ets`

## 后续建议

如需继续优化，可以考虑：

1. **扩展图标库**: 将其他页面中的 emoji 图标也替换为 SVG 图标
2. **图标动画**: 为底部导航图标添加选中/未选中的过渡动画
3. **深色模式适配**: 为深色模式配置不同的图标颜色方案
4. **图标资源优化**: 考虑使用图标字体或图标精灵图进一步优化性能

## 总结

本次更新成功将所有底部导航栏的 emoji 图标替换为专业的 SVG 图标，提升了应用的视觉效果和专业性。更新过程平滑，无破坏性变更，构建验证通过。

