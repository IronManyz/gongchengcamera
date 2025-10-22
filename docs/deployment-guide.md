# EngineeringCamera 部署指南

> **版本**: v1.0.0
> **更新日期**: 2025-10-22
> **适用平台**: HarmonyOS NEXT

## 📋 目录

1. [部署概述](#1-部署概述)
2. [环境要求](#2-环境要求)
3. [构建配置](#3-构建配置)
4. [本地部署](#4-本地部署)
5. [生产部署](#5-生产部署)
6. [应用商店发布](#6-应用商店发布)
7. [版本管理](#7-版本管理)
8. [故障排除](#8-故障排除)

---

## 1. 部署概述

### 1.1 部署架构

EngineeringCamera 采用标准的HarmonyOS应用部署架构：

```
开发环境 → 构建环境 → 测试环境 → 生产环境
    ↓           ↓           ↓           ↓
源代码管理 → 自动构建 → 质量检测 → 应用发布
```

### 1.2 部署方式

- **本地部署**: 开发者本地直接安装调试
- **测试部署**: 内部测试版本分发
- **生产部署**: 应用商店正式发布
- **企业部署**: 企业内部分发部署

### 1.3 部署流程

1. **环境准备**: 配置开发环境和工具链
2. **代码构建**: 执行编译和打包流程
3. **质量检测**: 运行测试和代码检查
4. **签名打包**: 生成发布版本安装包
5. **部署发布**: 分发到目标渠道

---

## 2. 环境要求

### 2.1 开发环境要求

#### 2.1.1 硬件要求

| 组件 | 最低配置 | 推荐配置 |
|------|----------|----------|
| CPU | Intel i5 / Apple M1 | Intel i7 / Apple M2 |
| 内存 | 8GB | 16GB |
| 存储 | 20GB可用空间 | 50GB可用空间 |
| 网络 | 稳定网络连接 | 高速网络连接 |

#### 2.1.2 软件要求

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| HarmonyOS SDK | API 12+ | HarmonyOS NEXT开发套件 |
| DevEco Studio | 5.0+ | 官方IDE |
| Node.js | 16.x+ | 构建工具依赖 |
| Git | 2.30+ | 版本控制 |
| HVigor | 4.x+ | 构建工具 |

#### 2.1.3 系统要求

- **Windows**: Windows 10/11 (64位)
- **macOS**: macOS 12.0+
- **Linux**: Ubuntu 20.04+ (推荐)

### 2.2 运行环境要求

#### 2.2.1 设备要求

- **系统版本**: HarmonyOS NEXT 5.0+
- **RAM**: 最低4GB，推荐8GB+
- **存储空间**: 至少500MB可用空间
- **摄像头**: 支持自动对焦的后置摄像头
- **传感器**: GPS、陀螺仪、加速计

#### 2.2.2 权限要求

- **相机权限**: 拍摄照片和视频
- **位置权限**: 获取GPS位置信息
- **存储权限**: 保存照片和数据文件
- **麦克风权限**: 视频录制音频（可选）

---

## 3. 构建配置

### 3.1 项目结构

```
EngineeringCamera/
├── entry/                     # 应用主模块
│   ├── src/main/ets/         # ArkTS源代码
│   ├── src/main/resources/   # 资源文件
│   ├── build-profile.json5   # 构建配置
│   └── module.json5          # 模块配置
├── AppScope/                  # 应用级配置
├── oh-package.json5          # 依赖配置
├── hvigorfile.ts             # 构建脚本
└── hvigorw                   # 构建工具
```

### 3.2 构建配置文件

#### 3.2.1 build-profile.json5

```json5
{
  "apiType": "stageMode",
  "buildMode": "debug",
  "targets": [
    {
      "name": "default"
    }
  ],
  "products": [
    {
      "name": "entry",
      "signConfig": "default",
      "compatibleSdkVersion": "5.0.0(12)",
      "runtimeOS": "HarmonyOS"
    }
  ]
}
```

#### 3.2.2 module.json5

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "srcEntry": "./ets/Application.ets",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:icon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:camera_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.APPROXIMATELY_LOCATION",
        "reason": "$string:location_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 3.3 构建命令

#### 3.3.1 基础构建命令

```bash
# 清理构建缓存
hvigorw clean

# 编译构建
hvigorw assembleHap

# 调试构建
hvigorw assembleHap --mode module -p module=entry@default

# 发布构建
hvigorw assembleHap --mode module -p module=entry@default --release
```

#### 3.3.2 高级构建选项

```bash
# 指定构建目标
hvigorw assembleHap -p module=entry@default

# 并行构建
hvigorw assembleHap --parallel

# 详细日志
hvigorw assembleHap --verbose

# 跳过测试
hvigorw assembleHap -x test
```

---

## 4. 本地部署

### 4.1 设备连接

#### 4.1.1 USB连接

1. **启用开发者模式**:
   - 设置 → 关于手机 → 连续点击版本号7次
   - 返回设置 → 开发者选项 → 开启开发者选项

2. **开启USB调试**:
   - 开发者选项 → USB调试 → 开启
   - 连接设备时选择"传输文件"模式

3. **验证连接**:
   ```bash
   hdc list targets
   ```

#### 4.1.2 网络连接

1. **启用网络调试**:
   - 开发者选项 → 网络ADB调试 → 开启
   - 记录设备的IP地址

2. **连接设备**:
   ```bash
   hdc tconn [设备IP]:5555
   ```

### 4.2 本地安装

#### 4.2.1 调试版本安装

```bash
# 构建调试版本
hvigorw assembleHap --mode module -p module=entry@default

# 安装到设备
hdc install entry/build/default/outputs/default/entry-default-unsigned.hap
```

#### 4.2.2 签名版本安装

```bash
# 构建签名版本
hvigorw assembleHap --release

# 安装到设备
hdc install entry/build/default/outputs/default/entry-default-unsigned.hap
```

### 4.3 调试部署

#### 4.3.1 实时调试

1. **启动调试**:
   ```bash
   hdc hilog
   ```

2. **查看日志**:
   ```bash
   hdc hilog | grep EngineeringCamera
   ```

3. **性能监控**:
   ```bash
   hdc shell hilog -D
   ```

#### 4.3.2 热重载部署

```bash
# 启动监视模式
hvigorw --mode module -p module=entry@default --watch

# 自动重载应用
# DevEco Studio会自动处理应用重载
```

---

## 5. 生产部署

### 5.1 发布版本构建

#### 5.1.1 生产环境配置

```json5
// build-profile.json5 - 生产配置
{
  "apiType": "stageMode",
  "buildMode": "release",
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS"
    }
  ],
  "products": [
    {
      "name": "entry",
      "signConfig": "release",
      "compatibleSdkVersion": "5.0.0(12)",
      "runtimeOS": "HarmonyOS",
      "output": {
        "artifactName": "engineering-camera"
      }
    }
  ]
}
```

#### 5.1.2 代码混淆

```typescript
// 在build-profile.json5中启用混淆
{
  "obfuscation": {
    "enable": true,
    "files": ["**/*.ets"],
    "optimize": true,
    "removeLogs": true
  }
}
```

### 5.2 应用签名

#### 5.2.1 生成签名证书

```bash
# 生成调试证书
keytool -genkeypair -alias engineering_camera_debug -keyalg EC -validity 365 -keystore engineering_camera_debug.jks

# 生成发布证书
keytool -genkeypair -alias engineering_camera_release -keyalg EC -validity 3650 -keystore engineering_camera_release.jks
```

#### 5.2.2 签名配置

```json5
// 在signingConfigs中配置签名
{
  "signingConfigs": [
    {
      "name": "default",
      "type": "HarmonyOS",
      "material": {
        "certpath": "./signature/engineering_camera_debug.cer",
        "storePassword": "your_password",
        "keyAlias": "engineering_camera_debug",
        "keyPassword": "your_password",
        "profile": "./signature/engineering_camera_debug.p7b",
        "signAlg": "SHA256withECDSA"
      }
    }
  ]
}
```

### 5.3 版本打包

#### 5.3.1 构建发布包

```bash
# 清理环境
hvigorw clean

# 构建发布版本
hvigorw assembleHap --release

# 生成签名包
hvigorw assembleHap --release --sign
```

#### 5.3.2 包验证

```bash
# 验证包完整性
hdc shell hapsigner verify -hapFile engineering-camera.hap

# 检查包信息
hdc shell hapsigner get-cert-info -hapFile engineering-camera.hap
```

---

## 6. 应用商店发布

### 6.1 华为应用市场发布

#### 6.1.1 准备发布材料

1. **应用包**: 签名后的HAP文件
2. **应用图标**: 512x512 PNG格式
3. **应用截图**: 至少3张，最多10张
4. **应用介绍**: 详细的功能说明
5. **隐私政策**: 用户隐私保护说明
6. **版本说明**: 更新内容说明

#### 6.1.2 发布流程

1. **注册开发者账号**:
   - 访问华为开发者联盟
   - 注册企业或个人开发者账号
   - 完成实名认证

2. **创建应用**:
   - 登录AppGallery Connect
   - 创建新应用
   - 填写应用基本信息

3. **上传应用包**:
   - 上传签名后的HAP文件
   - 系统自动进行安全检测
   - 等待检测结果

4. **完善应用信息**:
   - 上传应用图标和截图
   - 填写应用描述和关键词
   - 设置应用分类和标签

5. **提交审核**:
   - 检查所有信息完整性
   - 提交审核
   - 等待审核结果

### 6.2 其他应用商店

#### 6.2.1 支持的应用商店

- **华为应用市场**: 主要发布渠道
- **小米应用商店**: 可选发布渠道
- **OPPO应用商店**: 可选发布渠道
- **vivo应用商店**: 可选发布渠道
- **荣耀应用市场**: 可选发布渠道

#### 6.2.2 多渠道适配

```typescript
// 渠道标识配置
export const CHANNEL_CONFIG = {
  HUAWEI: 'huawei',
  XIAOMI: 'xiaomi',
  OPPO: 'oppo',
  VIVO: 'vivo',
  HONOR: 'honor'
}

// 获取当前渠道
export function getCurrentChannel(): string {
  return CHANNEL_CONFIG.HUAWEI // 默认华为渠道
}
```

---

## 7. 版本管理

### 7.1 版本号规范

#### 7.1.1 版本号格式

```
主版本号.次版本号.修订号 (构建号)
例如: 1.0.0 (100)
```

- **主版本号**: 重大功能更新或架构变更
- **次版本号**: 新功能添加或重要改进
- **修订号**: Bug修复或小功能改进
- **构建号**: 构建次数，递增

#### 7.1.2 版本更新策略

| 版本类型 | 更新频率 | 更新内容 | 用户操作 |
|----------|----------|----------|----------|
| 主要版本 | 3-6个月 | 重大功能更新 | 主动更新 |
| 次要版本 | 1-2个月 | 新功能添加 | 推荐更新 |
| 修订版本 | 1-4周 | Bug修复 | 自动更新 |
| 紧急修复 | 随时 | 严重Bug修复 | 强制更新 |

### 7.2 版本发布流程

#### 7.2.1 开发阶段

```bash
# 创建功能分支
git checkout -b feature/new-feature

# 开发完成后合并到开发分支
git checkout develop
git merge feature/new-feature

# 提交测试
git checkout -b release/v1.0.0
```

#### 7.2.2 测试阶段

```bash
# 构建测试版本
hvigorw assembleHap --mode debug

# 分发给测试人员
hdc install engineering-camera-test.hap

# 收集反馈并修复
```

#### 7.2.3 发布阶段

```bash
# 合并到主分支
git checkout main
git merge release/v1.0.0

# 创建发布标签
git tag -a v1.0.0 -m "Release version 1.0.0"

# 构建发布版本
hvigorw assembleHap --release

# 推送到远程仓库
git push origin main --tags
```

### 7.3 版本回滚

#### 7.3.1 紧急回滚

```bash
# 回滚到上一个稳定版本
git checkout v1.0.1

# 重新构建
hvigorw assembleHap --release

# 发布紧急修复版本
```

#### 7.3.2 数据兼容性

```typescript
// 数据库版本管理
export const DATABASE_VERSIONS = {
  V1_0_0: 1,
  V1_0_1: 2,
  V1_1_0: 3,
  V1_2_0: 4
}

// 版本兼容性检查
export function checkDataCompatibility(currentVersion: number, targetVersion: boolean): boolean {
  return targetVersion >= currentVersion
}
```

---

## 8. 故障排除

### 8.1 常见构建问题

#### 8.1.1 编译错误

**问题**: 编译时出现类型错误
```
解决方法:
1. 检查ArkTS语法是否符合规范
2. 更新HarmonyOS SDK到最新版本
3. 清理构建缓存: hvigorw clean
4. 检查依赖项版本兼容性
```

**问题**: 资源文件找不到
```
解决方法:
1. 检查resources目录结构
2. 确认资源文件命名规范
3. 验证$resource引用路径
4. 重新同步项目
```

#### 8.1.2 签名问题

**问题**: 应用签名失败
```
解决方法:
1. 检查证书文件是否有效
2. 验证签名配置参数
3. 确认密钥库密码正确
4. 重新生成签名证书
```

**问题**: 安装时签名验证失败
```
解决方法:
1. 确认使用正确的签名证书
2. 检查证书有效期
3. 验证签名算法配置
4. 重新签名应用包
```

### 8.2 运行时问题

#### 8.2.1 权限问题

**问题**: 应用启动时权限被拒绝
```
解决方法:
1. 检查module.json5中的权限声明
2. 确认权限使用场景说明
3. 验证权限申请逻辑
4. 添加权限申请引导
```

**问题**: 定位权限获取失败
```
解决方法:
1. 检查设备GPS是否开启
2. 确认应用有位置权限
3. 验证位置服务配置
4. 添加权限检查逻辑
```

#### 8.2.2 性能问题

**问题**: 应用启动缓慢
```
解决方法:
1. 优化应用初始化逻辑
2. 减少启动时的资源加载
3. 使用懒加载策略
4. 优化数据库查询
```

**问题**: 内存占用过高
```
解决方法:
1. 检查内存泄漏问题
2. 优化图片缓存策略
3. 及时释放不需要的资源
4. 使用性能分析工具
```

### 8.3 部署问题

#### 8.3.1 设备连接问题

**问题**: hdc无法连接设备
```
解决方法:
1. 检查USB连接和数据线
2. 确认设备开启了USB调试
3. 重启hdc服务: hdc kill-server
4. 检查设备驱动程序
```

**问题**: 应用安装失败
```
解决方法:
1. 检查设备存储空间
2. 确认应用签名有效
3. 卸载旧版本应用
4. 检查系统版本兼容性
```

#### 8.3.2 应用商店审核问题

**问题**: 应用审核被拒
```
解决方法:
1. 仔细阅读审核反馈意见
2. 修改不符合规范的内容
3. 重新测试所有功能
4. 提交申诉或重新申请
```

**问题**: 应用安全检测失败
```
解决方法:
1. 移除不安全的权限申请
2. 修复安全漏洞
3. 更新依赖库版本
4. 重新进行安全检测
```

---

## 📞 技术支持

### 部署相关支持

如果在部署过程中遇到问题，可以通过以下方式获取帮助：

- **技术文档**: [docs.engineeringcamera.com](https://docs.engineeringcamera.com)
- **开发者社区**: [dev.engineeringcamera.com](https://dev.engineeringcamera.com)
- **技术支持邮箱**: dev-support@engineeringcamera.com
- **问题反馈**: [github.com/engineeringcamera/issues](https://github.com/engineeringcamera/issues)

### 常用链接

- **HarmonyOS开发者官网**: [developer.harmonyos.com](https://developer.harmonyos.com)
- **DevEco Studio下载**: [developer.harmonyos.com/cn/develop/deveco-studio](https://developer.harmonyos.com/cn/develop/deveco-studio)
- **华为应用市场**: [appgallery.huawei.com](https://appgallery.huawei.com)
- **应用分发平台**: [developer.huawei.com](https://developer.huawei.com)

---

*部署指南最后更新: 2025年10月22日*