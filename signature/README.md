# 应用签名文件目录

## 目录说明

此目录包含EngineeringCamera应用的签名文件。

### 目录结构

```
signature/
├── README.md                    # 本说明文件
├── release/                     # 发布签名文件
│   ├── engineering_camera_release.cer  # 发布证书文件
│   ├── engineering_camera_release.p12  # 发布密钥库文件
│   └── engineering_camera_release.p7b  # 发布配置文件
└── debug/                       # 调试签名文件（自动生成）
    ├── engineering_camera_debug.cer
    ├── engineering_camera_debug.p12
    └── engineering_camera_debug.p7b
```

## 安全注意事项

1. **不要将签名文件提交到版本控制系统**
2. **妥善保管签名密码**
3. **定期备份签名文件**
4. **限制签名文件的访问权限**

## 签名文件获取

### 调试签名
- 由DevEco Studio自动生成
- 仅用于开发和测试
- 不可以用于发布

### 发布签名
- 需要在华为开发者联盟申请
- 用于应用商店发布
- 需要企业或个人开发者认证

## 详细说明

请参考 `../docs/signing-guide.md` 获取详细的签名配置指南。