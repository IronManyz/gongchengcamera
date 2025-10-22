# EngineeringCamera 应用签名指南

> **版本**: v1.0.0
> **更新日期**: 2025-10-22
> **适用平台**: HarmonyOS NEXT

## 📋 目录

1. [签名概述](#1-签名概述)
2. [签名类型](#2-签名类型)
3. [证书生成](#3-证书生成)
4. [签名配置](#4-签名配置)
5. [签名验证](#5-签名验证)
6. [常见问题](#6-常见问题)

---

## 1. 签名概述

### 1.1 签名的重要性

应用签名是HarmonyOS应用发布的重要安全机制：

- **身份验证**: 验证应用开发者的身份
- **完整性保证**: 确保应用在传输过程中未被篡改
- **系统安全**: 防止恶意应用冒充合法应用
- **版本管理**: 确保应用更新的连续性

### 1.2 签名流程

```
生成密钥库 → 创建签名证书 → 配置签名信息 → 签名应用包 → 验证签名
```

### 1.3 签名文件说明

- **.p12文件**: 包含私钥和证书的密钥库文件
- **.cer文件**: 数字证书文件，包含公钥和身份信息
- **.p7b文件**: 应用配置文件，包含权限和签名配置

---

## 2. 签名类型

### 2.1 调试签名

**用途**:
- 开发和调试阶段使用
- 本地测试和功能验证
- 不可以发布到应用商店

**特点**:
- 使用系统自动生成的证书
- 有效期较短
- 信任度较低

**配置**:
```json5
{
  "name": "default",
  "type": "HarmonyOS",
  "material": {
    "certpath": "调试证书路径",
    "keyAlias": "debugKey",
    "signAlg": "SHA256withECDSA"
  }
}
```

### 2.2 发布签名

**用途**:
- 应用商店发布
- 企业内部分发
- 正式版本部署

**特点**:
- 需要手动生成和管理
- 有效期较长
- 信任度高

**要求**:
- 使用企业或个人开发者证书
- 通过华为开发者联盟认证
- 证书与应用包名绑定

---

## 3. 证书生成

### 3.1 前提条件

1. **注册开发者账号**
   - 访问[华为开发者联盟](https://developer.huawei.com)
   - 完成实名认证
   - 创建应用

2. **安装开发工具**
   - DevEco Studio 5.0+
   - JDK 8+
   - HarmonyOS SDK

### 3.2 生成发布证书

#### 3.2.1 使用DevEco Studio生成

1. **打开签名管理**:
   ```
   Build → Generate Signed Bundle/HarmonyOS App(HAP)
   ```

2. **选择密钥库**:
   - 选择"Create new"
   - 设置密钥库文件路径和密码

3. **填写证书信息**:
   ```
   Alias: releaseKey
   Password: [设置密钥密码]
   Validity: 25年或更长
   Certificate:
     - CN: EngineeringCamera
     - OU: Development Team
     - O: Your Company Name
     - L: Your City
     - ST: Your State
     - C: Your Country Code
   ```

4. **生成证书文件**:
   - 保存.p12密钥库文件
   - 导出.cer证书文件
   - 下载.p7b配置文件

#### 3.2.2 使用命令行生成

```bash
# 生成密钥库
keytool -genkeypair \
  -alias releaseKey \
  -keyalg EC \
  -keysize 256 \
  -validity 9125 \
  -keystore engineering_camera_release.p12 \
  -storetype PKCS12 \
  -storepass [你的密钥库密码] \
  -keypass [你的密钥密码] \
  -dname "CN=EngineeringCamera, OU=Development Team, O=Your Company, L=Your City, ST=Your State, C=CN"

# 导出证书
keytool -exportcert \
  -alias releaseKey \
  -keystore engineering_camera_release.p12 \
  -storepass [你的密钥库密码] \
  -file engineering_camera_release.cer \
  -rfc
```

### 3.3 华为应用市场证书

1. **登录AppGallery Connect**:
   - 访问[AppGallery Connect](https://developer.huawei.com/consumer/cn/appgallery)
   - 选择应用项目

2. **生成签名证书**:
   ```
   我的项目 → 应用 → HAP签名证书 → 添加
   选择: 发布证书
   填写证书信息并生成
   ```

3. **下载证书文件**:
   - 下载.cer证书文件
   - 下载.p7b配置文件
   - 保存密钥库信息

---

## 4. 签名配置

### 4.1 配置文件结构

```
signature/
├── release/
│   ├── engineering_camera_release.cer  # 证书文件
│   ├── engineering_camera_release.p12  # 密钥库文件
│   └── engineering_camera_release.p7b  # 配置文件
└── debug/
    ├── engineering_camera_debug.cer    # 调试证书
    ├── engineering_camera_debug.p12    # 调试密钥库
    └── engineering_camera_debug.p7b    # 调试配置
```

### 4.2 build-profile.json5配置

#### 4.2.1 发布环境配置

```json5
{
  "app": {
    "signingConfigs": [
      {
        "name": "release",
        "type": "HarmonyOS",
        "material": {
          "certpath": "./signature/release/engineering_camera_release.cer",
          "keyAlias": "releaseKey",
          "keyPassword": "${RELEASE_KEY_PASSWORD}",
          "profile": "./signature/release/engineering_camera_release.p7b",
          "signAlg": "SHA256withECDSA",
          "storeFile": "./signature/release/engineering_camera_release.p12",
          "storePassword": "${RELEASE_STORE_PASSWORD}"
        }
      }
    ],
    "products": [
      {
        "name": "production",
        "signingConfig": "release",
        "targetSdkVersion": "5.1.1(19)",
        "compatibleSdkVersion": "5.0.5(17)",
        "runtimeOS": "HarmonyOS"
      }
    ]
  }
}
```

#### 4.2.2 环境变量配置

创建`.env.production`文件：
```env
# 签名配置
RELEASE_KEY_PASSWORD=your_release_key_password_here
RELEASE_STORE_PASSWORD=your_release_store_password_here
SIGN_KEY_ALIAS=releaseKey
```

### 4.3 安全注意事项

#### 4.3.1 密钥安全

- **密码复杂度**: 使用强密码，包含大小写字母、数字和特殊字符
- **密码存储**: 不要在代码中硬编码密码，使用环境变量
- **文件权限**: 设置适当的文件权限，仅允许授权用户访问
- **备份管理**: 定期备份证书文件，但不要与代码一起存储

#### 4.3.2 访问控制

```bash
# 设置文件权限
chmod 600 signature/release/engineering_camera_release.p12
chmod 644 signature/release/engineering_camera_release.cer
chmod 644 signature/release/engineering_camera_release.p7b

# 设置目录权限
chmod 700 signature/release/
```

#### 4.3.3 团队协作

- **密钥管理**: 指定专人管理签名密钥
- **访问记录**: 记录密钥使用情况
- **权限分配**: 根据需要分配签名权限
- **离职处理**: 离职时及时更换密钥

---

## 5. 签名验证

### 5.1 验证签名有效性

#### 5.1.1 使用HAP签名工具

```bash
# 验证HAP包签名
hdc shell hapsigner verify -hapFile engineering-camera.hap

# 获取证书信息
hdc shell hapsigner get-cert-info -hapFile engineering-camera.hap
```

#### 5.1.2 检查签名信息

```typescript
// 签名验证工具
export class SignatureVerifier {
  static async verifySignature(hapPath: string): Promise<SignatureInfo> {
    try {
      // 使用系统API验证签名
      const result = await hapsigner.verify(hapPath)

      return {
        isValid: result.valid,
        signatureAlgorithm: result.algorithm,
        certificateInfo: result.certificate,
        signTime: result.timestamp,
        issuer: result.issuer
      }
    } catch (error) {
      Logger.error('SignatureVerifier', '签名验证失败', error)
      throw new Error('签名验证失败')
    }
  }
}
```

### 5.2 签名问题排查

#### 5.2.1 常见错误

**错误1: 证书过期**
```
错误信息: Certificate has expired
解决方案: 重新生成证书或更新现有证书
```

**错误2: 密钥不匹配**
```
错误信息: Key and certificate do not match
解决方案: 确认使用正确的密钥库和证书
```

**错误3: 签名算法不支持**
```
错误信息: Unsupported signature algorithm
解决方案: 使用SHA256withECDSA算法
```

**错误4: 配置文件不匹配**
```
错误信息: Profile does not match the certificate
解决方案: 使用与证书对应的p7b配置文件
```

#### 5.2.2 问题排查流程

1. **检查证书有效性**
   ```bash
   keytool -list -v -keystore engineering_camera_release.p12
   ```

2. **验证签名配置**
   - 检查build-profile.json5中的签名配置
   - 确认文件路径正确
   - 验证密码设置

3. **重新生成签名**
   ```bash
   # 清理构建
   hvigorw clean

   # 重新签名
   hvigorw assembleHap --release --sign
   ```

---

## 6. 常见问题

### 6.1 证书管理

**Q: 证书丢失了怎么办？**

A:
1. 如果是调试证书，可以重新生成
2. 如果是发布证书，需要：
   - 联系华为开发者联盟重新申���
   - 更新应用配置
   - 重新签名应用

**Q: 证书快过期了怎么办？**

A:
1. 提前1-2个月开始准备证书更新
2. 生成新的证书和密钥库
3. 更新签名配置
4. 测试新证书的有效性

**Q: 可以使用相同的证书发布多个应用吗？**

A:
- 不建议。一个证书应该只对应一个应用
- 不同应用使用不同证书可以提高安全性
- 证书与应用包名绑定

### 6.2 签名流程

**Q: 签名失败怎么办？**

A:
1. 检查证书文件是否存在且有效
2. 验证密码是否正确
3. 确认签名配置文件正确
4. 检查网络连接（如果需要验证证书）

**Q: 发布到应用商店时签名验证失败？**

A:
1. 确认使用发布证书而非调试证书
2. 检查证书是否与应用匹配
3. 验证证书是否在有效期内
4. 确认签名算法符合要求

**Q: 更新应用时需要重新签名吗？**

A:
- 是的，每次发布新版本都需要重新签名
- 使用相同的证书可以保证版本连续性
- 如果更换证书，需要特殊处理

### 6.3 安全相关

**Q: 如何保护签名密钥的安全？**

A:
1. 使用强密码保护密钥库
2. 不要将密码提交到版本控制系统
3. 定期备份密钥文件
4. 限制密钥文件的访问权限
5. 使用安全的存储方式

**Q: 团队开发中如何管理签名？**

A:
1. 指定专人管理发布签名
2. 开发人员使用调试签名
3. 建立签名使用记录
4. 定期轮换密钥
5. 使用CI/CD自动化签名流程

---

## 📞 技术支持

如果在签名过程中遇到问题，可以通过以下方式获取帮助：

- **华为开发者支持**: [developer.huawei.com](https://developer.huawei.com)
- **HarmonyOS文档**: [developer.harmonyos.com](https://developer.harmonyos.com)
- **技术支持邮箱**: dev-support@engineeringcamera.com
- **开发者社区**: [developer.huawei.com](https://developer.huawei.com)

### 相关链接

- [HarmonyOS应用签名指南](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/ohos-signing-apps-0000001233054985)
- [AppGallery Connect](https://developer.huawei.com/consumer/cn/appgallery)
- [密钥工具文档](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)

---

*签名指南最后更新: 2025年10月22日*