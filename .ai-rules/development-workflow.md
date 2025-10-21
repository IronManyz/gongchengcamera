---
title: Development Workflow
description: "EngineeringCamera项目开发流程：Git工作流、代码审查、测试策略、发布流程和团队协作规范"
inclusion: always
---

# 工程相机 (Engineering Camera) 开发流程

## 概述

本文档定义了EngineeringCamera项目的完整开发流程，包括Git工作流、代码规范、测试策略、发布流程等。所有开发人员必须遵循此流程确保项目质量和开发效率。

**核心原则：质量优先、自动化优先、文档优先、协作优先**

## 1. 开发环境配置

### 1.1 必需工具

```bash
# 1. DevEco Studio 4.0+
# 下载地址：https://developer.harmonyos.com/cn/develop/deveco-studio

# 2. HarmonyOS SDK API 11+
# 在DevEco Studio中通过SDK Manager安装

# 3. Node.js (用于构建工具)
# 版本要求：16.x 或更高版本

# 4. Git (版本控制)
# 版本要求：2.30 或更高版本
```

### 1.2 项目初始化

```bash
# 克隆项目
git clone https://github.com/your-org/EngineeringCamera.git
cd EngineeringCamera

# 安装依赖
ohpm install

# 打开项目
# 使用DevEco Studio打开项目目录

# 首次构建
./hvigorw assembleHap --mode module -p module=entry@default
```

### 1.3 开发配置

```typescript
// local.properties (本地配置，不提交到Git)
sdk.dir=/path/to/ohos-sdk
hvigor.dir=/path/to/hvigor
sign.alias=your-signing-alias
sign.password=your-signing-password

// 环境变量配置
export HOS_SDK_HOME=/path/to/ohos-sdk
export HVIGOR_WRAPPER_HOME=/path/to/hvigor
```

## 2. Git工作流程

### 2.1 分支策略

```
main (主分支)
├── release/v1.0.0 (发布分支)
├── develop (开发分支)
│   ├── feature/photo-watermark (功能分支)
│   ├── feature/project-management (功能分支)
│   └── feature/camera-capture (功能分支)
└── hotfix/critical-bug-fix (热修复分支)
```

**分支说明**：
- **main**: 主分支，只包含稳定版本，每个提交都是可发布的版本
- **develop**: 开发分支，集成所有功能开发
- **feature/xxx**: 功能分支，从develop分支切出，完成后合并回develop
- **release/xxx**: 发布分支，从develop分支切出，用于发布前的最终准备
- **hotfix/xxx**: 热修复分支，从main分支切出，修复后合���回main和develop

### 2.2 提交规范

#### 提交消息格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型 (type)**：
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

**范围 (scope)**：
- `camera`: 相机相关
- `photo`: 照片管理
- `project`: 项目管理
- `ui`: 界面组件
- `database`: 数据库相关
- `service`: 服务层
- `build`: 构建相关

**示例**：
```bash
# 新功能提交
git commit -m "feat(camera): add watermark template support

- Add standard watermark templates
- Support custom watermark configuration
- Implement watermark preview functionality

Closes #123"

# 修复提交
git commit -m "fix(photo): resolve photo loading crash on low memory

- Add memory check before loading large images
- Implement image compression for memory optimization
- Add error handling for out-of-memory scenarios

Fixes #145"

# 性能优化
git commit -m "perf(gallery): optimize photo grid rendering performance

- Use LazyForEach for virtualized scrolling
- Implement image caching strategy
- Reduce component re-render count"
```

### 2.3 分支操作流程

#### 创建功能分支
```bash
# 切换到develop分支并更新
git checkout develop
git pull origin develop

# 创建功能分支
git checkout -b feature/photo-watermark

# 开始开发...
```

#### 提交代码
```bash
# 添加修改
git add .

# 提交（遵循提交规范）
git commit -m "feat(watermark): implement watermark rendering engine"

# 推送到远程分支
git push origin feature/photo-watermark
```

#### 创建Pull Request
```markdown
## 功能描述
实现相机拍照时的水印渲染引擎，支持多种模板和自定义配置。

## 变更内容
- 新增WatermarkService类
- 实现WatermarkCanvas组件
- 添加水印模板管理
- 支持GPS、天气、时间等信息水印

## 测试说明
- [x] 单元测试通过
- [x] UI测试通过
- [x] 手动测试通过
- [x] 性能测试通过

## 截图/演示
[在此添加功能截图或演示视频]

## 相关Issue
Closes #123
```

#### 合并代码
```bash
# 代码审查通过后，合并到develop
git checkout develop
git pull origin develop
git merge feature/photo-watermark
git push origin develop

# 删除功能分支
git branch -d feature/photo-watermark
git push origin --delete feature/photo-watermark
```

## 3. 代码审查流程

### 3.1 审查清单

#### 功能性审查
- [ ] 功能实现符合需求文档
- [ ] 边界情况处理正确
- [ ] 错误处理机制完善
- [ ] 性能满足要求
- [ ] 安全性考虑充分

#### 代码质量审查
- [ ] 遵循ArkTS编码规范
- [ ] 使用V2响应式状态管理
- [ ] 代码结构清晰，可读性好
- [ ] 无明显代码重复
- [ ] 注释完整且准确

#### 测试审查
- [ ] 单元测试覆盖率 > 80%
- [ ] 集成测试通过
- [ ] UI测试通过
- [ ] 性能测试通过
- [ ] 测试用例设计合理

#### 构建审查
- [ ] 项目编译通过
- [ ] 无警告信息
- [ ] 资源文件引用正确
- [ ] 权限声明完整
- [ ] 配置文件正确

### 3.2 审查工具配置

#### ESLint配置 (code-linter.json5)
```json
{
  "files": ["**/*.ets"],
  "ignore": [
    "**/build/**/*",
    "**/oh_modules/**/*"
  ],
  "ruleSet": [
    "plugin:@typescript-eslint/recommended",
    "plugin:@security/recommended"
  ],
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@security/no-unsafe-eval": "error",
    "@security/no-unsafe-func": "error"
  }
}
```

#### Git Hooks
```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running pre-commit checks..."

# 1. 代码格式检查
npm run lint

# 2. 类型检查
npm run type-check

# 3. 单元测试
npm run test:unit

# 4. 构建检查
./hvigorw assembleHap --mode module -p module=entry@default

echo "Pre-commit checks passed!"
```

## 4. 测试策略

### 4.1 测试金字塔

```
    /\
   /  \     E2E Tests (端到端测试)
  /____\    - 少量、关键路径测试
 /      \
/________\ Integration Tests (集成测试)
           - 中等数量、服务间交互测试
/__________\
/____________\ Unit Tests (单元测试)
              - 大量、函数级测试
```

### 4.2 单元测试

#### 测试规范
```typescript
// entry/src/test/PhotoService.test.ets
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { PhotoService } from '../services/business/PhotoService'
import { PhotoModel } from '../models/PhotoModel'

describe('PhotoService', () => {
  let photoService: PhotoService

  beforeAll(async () => {
    // 测试环境初始化
    photoService = PhotoService.getInstance()
    await photoService.initializeTestDatabase()
  })

  afterAll(async () => {
    // 清理测试环境
    await photoService.cleanupTestDatabase()
  })

  beforeEach(async () => {
    // 每个测试前的准备
    await photoService.clearTestData()
  })

  describe('createPhoto', () => {
    it('should create photo with valid data', async () => {
      // Arrange
      const photoData = {
        filePath: '/test/photo.jpg',
        projectId: 'project123',
        siteId: 'site456'
      }

      // Act
      const photo = await photoService.createPhoto(photoData)

      // Assert
      expect(photo.id).not.toBe('')
      expect(photo.filePath).toBe(photoData.filePath)
      expect(photo.projectId).toBe(photoData.projectId)
      expect(photo.createdAt).toBeGreaterThan(0)
    })

    it('should throw error for invalid file path', async () => {
      // Arrange
      const invalidData = {
        filePath: '',  // 无效路径
        projectId: 'project123'
      }

      // Act & Assert
      await expect(photoService.createPhoto(invalidData))
        .rejects.toThrow('Invalid file path')
    })

    it('should handle concurrent photo creation', async () => {
      // 测试并发场景
      const promises = Array.from({ length: 10 }, (_, i) =>
        photoService.createPhoto({
          filePath: `/test/photo${i}.jpg`,
          projectId: 'project123'
        })
      )

      const photos = await Promise.all(promises)
      expect(photos).toHaveLength(10)
      expect(new Set(photos.map(p => p.id)).size).toBe(10)  // ID唯一
    })
  })

  describe('getPhotosByProject', () => {
    it('should return photos for specific project', async () => {
      // 准备测试数据
      await photoService.createPhoto({ filePath: '/test/1.jpg', projectId: 'project1' })
      await photoService.createPhoto({ filePath: '/test/2.jpg', projectId: 'project1' })
      await photoService.createPhoto({ filePath: '/test/3.jpg', projectId: 'project2' })

      // 查询project1的照片
      const photos = await photoService.getPhotosByProject('project1')

      expect(photos).toHaveLength(2)
      expect(photos.every(p => p.projectId === 'project1')).toBe(true)
    })

    it('should return empty array for non-existent project', async () => {
      const photos = await photoService.getPhotosByProject('non-existent')
      expect(photos).toHaveLength(0)
    })
  })
})
```

#### 测试工具配置
```typescript
// entry/src/test/test-config.ets
export class TestConfig {
  static readonly TEST_DB_NAME = 'test_engineering_camera.db'
  static readonly TEST_FILES_DIR = '/data/test/files'

  static async setupTestEnvironment() {
    // 创建测试目录
    await fs.mkdir(TestConfig.TEST_FILES_DIR, true)

    // 初始化测试数据库
    await DatabaseService.initialize(TestConfig.TEST_DB_NAME)
  }

  static async cleanupTestEnvironment() {
    // 清理测试数据
    await fs.rmdir(TestConfig.TEST_FILES_DIR, true)
    await DatabaseService.close()
  }
}
```

### 4.3 集成测试

```typescript
// entry/src/test/integration/CameraIntegration.test.ets
describe('Camera Integration Tests', () => {
  let cameraService: CameraService
  let photoService: PhotoService

  beforeAll(async () => {
    cameraService = CameraService.getInstance()
    photoService = PhotoService.getInstance()
  })

  it('should capture and save photo with metadata', async () => {
    // 模拟拍照流程
    const photoPath = await cameraService.capturePhoto()

    // 获取位置信息
    const location = await LocationService.getCurrentLocation()

    // 获取天气信息
    const weather = await WeatherService.getCurrentWeather(location)

    // 保存照片记录
    const photo = await photoService.createPhoto({
      filePath: photoPath,
      latitude: location.latitude,
      longitude: location.longitude,
      weather: weather.description,
      // ... 其他元数据
    })

    // 验证照片记录
    expect(photo).toBeDefined()
    expect(photo.filePath).toBe(photoPath)
    expect(photo.latitude).toBe(location.latitude)
    expect(photo.weather).toBe(weather.description)
  })
})
```

### 4.4 UI测试

```typescript
// entry/src/ohosTest/ets/test/GalleryTest.ets
import { Driver, By, Component } from '@ohos.UiTest'

describe('Gallery UI Tests', () => {
  let driver: Driver

  beforeAll(async () => {
    driver = Driver.create()
    await driver.delayMs(2000)  // 等待应用启动
  })

  it('should display photo gallery', async () => {
    // 导航到相册页面
    const galleryButton = await driver.findComponent(By.key('gallery_button'))
    await galleryButton.click()
    await driver.delayMs(1000)

    // 验证照片列表显示
    const photoList = await driver.findComponent(By.key('photo_list'))
    expect(photoList).toBeDefined()

    // 验证照片项存在
    const photoItems = await driver.findComponents(By.key('photo_item'))
    expect(photoItems.length).toBeGreaterThan(0)
  })

  it('should handle photo selection', async () => {
    const photoItems = await driver.findComponents(By.key('photo_item'))
    const firstPhoto = photoItems[0]

    // 点击照片
    await firstPhoto.click()
    await driver.delayMs(1000)

    // 验证进入详情页
    const photoDetail = await driver.findComponent(By.key('photo_detail'))
    expect(photoDetail).toBeDefined()
  })
})
```

### 4.5 性能测试

```typescript
// entry/src/test/performance/PhotoLoadingTest.ets
describe('Photo Loading Performance', () => {
  it('should load 100 photos within 5 seconds', async () => {
    const startTime = Date.now()

    // 创建100张测试照片
    const photos = Array.from({ length: 100 }, (_, i) =>
      PhotoService.createPhoto({
        filePath: `/test/photo${i}.jpg`,
        projectId: 'perf_test'
      })
    )

    await Promise.all(photos)

    const endTime = Date.now()
    const duration = endTime - startTime

    expect(duration).toBeLessThan(5000)  // 5秒内完成
  })

  it('should maintain 60fps when scrolling photo list', async () => {
    // 测试滚动性能
    const startTime = Date.now()

    // 模拟滚动操作
    await GalleryPage.scrollToBottom()

    const endTime = Date.now()
    const fps = 1000 / ((endTime - startTime) / 10)  // 假设滚动10屏

    expect(fps).toBeGreaterThan(55)  // 保持55fps以上
  })
})
```

## 5. 构建和部署

### 5.1 构建配置

#### Hvigor构建脚本
```typescript
// hvigor/hvigor-config.json5
{
  "modelVersion": "5.1.1",
  "dependencies": {
    "@ohos/hvigor-ohos-plugin": "4.0.5"
  },
  "execution": {
    "parallel": true,
    "daemon": true
  }
}
```

#### 构建命令
```bash
# 开发构建
./hvigorw assembleHap --mode module -p module=entry@default

# 发布构建
./hvigorw assembleHap --mode module -p module=entry@release --release

# 清理构建缓存
./hvigorw clean

# 依赖检查
./hvigorw dependencies

# 代码检查
./hvigorw lint
```

### 5.2 签名配置

```typescript
// build-profile.json5
{
  "app": {
    "signingConfigs": [
      {
        "name": "debug",
        "type": "HarmonyOS",
        "material": {
          "keyAlias": "debug",
          "storePassword": "debug123456",
          "keyPassword": "debug123456",
          "signAlg": "SHA256withECDSA"
        }
      },
      {
        "name": "release",
        "type": "HarmonyOS",
        "material": {
          "keyAlias": "release",
          "storePassword": "release123456",
          "keyPassword": "release123456",
          "signAlg": "SHA256withECDSA"
        }
      }
    ],
    "products": [
      {
        "name": "default",
        "signingConfig": "debug"
      }
    ]
  }
}
```

### 5.3 CI/CD配置

#### GitHub Actions配置
```yaml
# .github/workflows/build.yml
name: Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Setup HarmonyOS SDK
      run: |
        # 下载和配置HarmonyOS SDK

    - name: Install dependencies
      run: ohpm install

    - name: Run lint
      run: npm run lint

    - name: Run tests
      run: npm run test:unit

    - name: Build debug
      run: ./hvigorw assembleHap --mode module -p module=entry@default

  release:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - uses: actions/checkout@v3

    - name: Build release
      run: ./hvigorw assembleHap --mode module -p module=entry@release --release

    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: engineering-camera-hap
        path: entry/build/default/outputs/default/*.hap
```

## 6. 发布流程

### 6.1 版本管理

#### 语义化版本控制
```
MAJOR.MINOR.PATCH

MAJOR: 不兼容的API变更
MINOR: 向后兼容的功能新增
PATCH: 向后兼容的问题修正
```

#### 版本号示例
- `1.0.0` - 首个正式版本
- `1.1.0` - 新增团队协作功能
- `1.1.1` - 修复照片上传bug
- `2.0.0` - 重构数据存储架构

### 6.2 发布检查清单

#### 代码质量检查
- [ ] 所有单元测试通过
- [ ] 集成测试通过
- [ ] UI测试通过
- [ ] 代码审查完成
- [ ] 性能测试通过
- [ ] 安全扫描通过

#### 功能完整性检查
- [ ] 所有需求功能实现
- [ ] 用户文档更新
- [ ] API文档更新
- [ ] 变更日志更新
- [ ] 版本号更新

#### 构建和签名检查
- [ ] Release构建成功
- [ ] 签名文件正确
- [ ] 包大小检查通过
- [ ] 权限声明正确
- [ ] 兼容性测试通过

### 6.3 发布步骤

```bash
# 1. 创建发布分支
git checkout -b release/v1.1.0 develop

# 2. 更新版本号
# 编辑 AppScope/app.json5
"versionCode": 1000100,
"versionName": "1.1.0"

# 3. 更新变更日志
# 编辑 CHANGELOG.md

# 4. 提交版本更新
git commit -m "chore(release): prepare for v1.1.0"

# 5. 构建发布版本
./hvigorw assembleHap --mode module -p module=entry@release --release

# 6. 创建发布标签
git tag -a v1.1.0 -m "Release version 1.1.0"

# 7. 推送到远程
git push origin release/v1.1.0
git push origin v1.1.0

# 8. 合并到主分支
git checkout main
git merge release/v1.1.0
git push origin main

# 9. 合并回开发分支
git checkout develop
git merge release/v1.1.0
git push origin develop

# 10. 删除发布分支
git branch -d release/v1.1.0
git push origin --delete release/v1.1.0
```

### 6.4 热修复流程

```bash
# 1. 从主分支创建热修复分支
git checkout main
git pull origin main
git checkout -b hotfix/critical-memory-leak

# 2. 修复问题
# ... 修复代码 ...

# 3. 测试验证
npm run test:unit
./hvigorw assembleHap --mode module -p module=entry@release --release

# 4. 提交修复
git commit -m "fix(memory): resolve critical memory leak in photo loading"

# 5. 创建修复版本
git tag -a v1.1.1 -m "Hotfix version 1.1.1"

# 6. 推送到远程
git push origin hotfix/critical-memory-leak
git push origin v1.1.1

# 7. 合并到主分支
git checkout main
git merge hotfix/critical-memory-leak
git push origin main

# 8. 合并到开发分支
git checkout develop
git merge hotfix/critical-memory-leak
git push origin develop

# 9. 删除热修复分支
git branch -d hotfix/critical-memory-leak
git push origin --delete hotfix/critical-memory-leak
```

## 7. 团队协作规范

### 7.1 角色职责

#### 产品负责人 (Product Owner)
- 定义产品需求和优先级
- 编写和维护用户故事
- 验收完成的功能
- 管理产品backlog

#### 技术负责人 (Tech Lead)
- 制定技术方案和架构决策
- 代码审查和技术指导
- 技术风险评估和解决
- 团队技术培训

#### 开发工程师 (Developer)
- 实现功能需求
- 编写单元测试
- 参与代码审查
- 修复bug

#### 测试工程师 (QA Engineer)
- 制定测试计划
- 执行测试用例
- 编写自动化测试
- 质量保证

### 7.2 沟通规范

#### 日常沟通
- **即时沟通**: 使用企业微信/钉钉进行日常沟通
- **技术讨论**: 在GitHub Issues中进行技术讨论
- **文档协作**: 使用GitHub Wiki进行文档协作
- **会议记录**: 使用共享文档记录会议内容

#### 会议规范
- **每日站会**: 15分钟，同步进度和问题
- **需求评审**: 产品负责人讲解需求，团队评估
- **技术评审**: 技术方案讨论和决策
- **回顾会议**: 总结迭代成果和改进点

### 7.3 文档管理

#### 文档类型
```
├── docs/
│   ├── requirements/          # 需求文档
│   │   ├── user-stories.md
│   │   └── acceptance-criteria.md
│   ├── design/               # 设计文档
│   │   ├── architecture.md
│   │   ├── api-design.md
│   │   └── ui-design.md
│   ├── development/          # 开发文档
│   │   ├── setup-guide.md
│   │   ├── coding-standards.md
│   │   └── testing-guide.md
│   └── deployment/           # 部署文档
│       ├── build-process.md
│       └── release-process.md
```

#### 文档更新规范
- 每个功能模块必须有对应的文档
- 代码变更时同步更新文档
- 重要决策需要记录在架构文档中
- 定期审查和更新过时文档

## 8. 质量保证

### 8.1 代码质量指标

#### 代码覆盖率
```typescript
// package.json
{
  "scripts": {
    "test:coverage": "hvigor test --coverage",
    "test:coverage:check": "hvigor test --coverage --coverageReporters=text-summary",
    "test:coverage:report": "hvigor test --coverage --coverageReporters=html"
  }
}

// 覆盖率要求
{
  "statements": 80,    // 语句覆盖率 > 80%
  "branches": 75,      // 分支覆盖率 > 75%
  "functions": 85,     // 函数覆盖率 > 85%
  "lines": 80         // 行覆盖率 > 80%
}
```

#### 性能指标
- 应用启动时间 < 3秒
- 拍照响应时间 < 1秒
- 照片加载时间 < 2秒
- 内存使用 < 500MB
- 电池消耗优化

#### 安全指标
- 无高危安全漏洞
- 敏感数据加密存储
- 权限最小化原则
- 代码静态分析通过

### 8.2 持续改进

#### 度量指标
```typescript
// 开发效率指标
{
  "commit_frequency": "每日提交次数",
  "pr_review_time": "PR审查平均时间",
  "build_time": "构建时间",
  "test_coverage": "测试覆盖率",
  "bug_density": "bug密度(每千行代码)",
  "code_churn": "代码变更率"
}

// 质量指标
{
  "crash_rate": "应用崩溃率",
  "anr_rate": "应用无响应率",
  "user_satisfaction": "用户满意度",
  "feature_adoption": "功能采用率",
  "performance_score": "性能评分"
}
```

#### 改进措施
- 定期代码质量回顾
- 技术债务管理
- 团队技能培训
- 工具链优化
- 流程持续改进

---

**注意**: 本开发流程是项目开发的强制性规范，所有团队成员必须严格遵守。任何流程修改都需要经过团队讨论并更新此文档。