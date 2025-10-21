# 工程相机 (Project Camera)

> **版本 Version**: v1.0.0

---

## 简介 — 项目简介 / Project Overview

**中文**

`工程相机` 是一款面向工程施工场景的鸿蒙纯前端拍照管理应用。它以工程与施工地点为单位管理照片，所有数据本地化存储，强调隐私与可审计性。应用提供可定制的水印模板（记录经纬度、海拔、方位角、地理位置、天气、工程信息与自定义备注）、照片涂鸦编辑、分享与一键导航、导出、云盘备份与团队协作等功能。适用于市政、交通、电力、土建、园林、装修等各类工程现场照片归档与质量管理场景。

**English**

`Project Camera` is a HarmonyOS pure-front-end app for construction photography and management. It organizes photos by project and site, stores all data locally to guarantee privacy, and provides configurable watermark templates (coordinates, altitude, azimuth, geo-address, weather, project metadata and custom notes), photo annotation tools, sharing, one-tap navigation & export, cloud backup/sync and team collaboration. Target scenarios include municipal, transportation, power, civil works, landscaping and interior construction.

---

## 功能特性 / Features

- 项目与施工点管理（新建/编辑/删除工程、工点及分组）
- 拍照水印相机：动态水印支持——经纬度、海拔、方位角、地理位置、天气、工程信息、自定义备注、多行业风格模板
- 照片编辑：裁剪、旋转、涂鸦、标注、模糊敏感信息、添加备注
- 分享与导出：通过系统分享、生成报告拼图、PDF/图片导出、一键导航到拍摄点
- 本地数据库管理：查看表结构、备份、导入、清空与数据导出
- 离线优先：所有核心功能可在无网络下正常工作
- 云端备份与多设备同步（可选）——将工程与相片备份到云盘以支持设备间同步
- 团队共享：邀请团队成员、角色与权限管理（拍照/查看/管理）
- 相册与工程备忘录、拼图报表生成
- 权限申请说明：相机、麦克风（视频），定位（经纬度）、文件读写、设备信息读取（用于统计）

---

## 技术栈 / Tech Stack

**强制说明：项目必须使用 ArkTS 开发与 V2 响应式状态管理**

- 开发平台: HarmonyOS NEXT / OpenHarmony
- 开发语言: **ArkTS**（必选）
- UI 框架: **ArkUI**
- 响应式状态管理: **V2 响应式**（@ObservedV2、@Trace、@Local、@Param、@Monitor 等装饰器）
- 本地数据库: 鸿蒙本地关系型数据库或轻量级本地存储（RDB / KV）
- 打包/构建: 鸿蒙编译工具链（按项目规则使用 hvigorw assembleHap 进行构建检查）
- 其他: 系统配置/主题 API（ConfigurationConstant）、存储链接装饰器（@StorageLink）等平台能力

---

## 项目结构 / Project Structure

以下为推荐的鸿蒙纯前端项目目录结构（示例）：

```
project-camera/
├─ src/
│  ├─ main/                # 应用入口（app.json、app.ts）
│  ├─ pages/               # 页面目录（按模块划分）
│  │  ├─ project/          # 工程与施工点管理页面
│  │  ├─ camera/           # 拍照与相机设置页面
│  │  ├─ gallery/          # 本地相册与云端相册页面
│  │  ├─ editor/           # 照片编辑、涂鸦页面
│  │  └─ settings/         # 设置（主题、数据库管理、权限）
│  ├─ components/         # 可复用组件（Watermark、MapPreview、Doodle、SharePanel）
│  ├─ store/               # V2 响应式状态管理（@ObservedV2 模块）
│  ├─ services/            # 本地数据库封装、定位、天气、导出、云盘接口（抽象）
│  ├─ models/              # 数据模型（使用 @ObservedV2 / @Trace 装饰）
│  ├─ assets/              # 图标、模板、样式等
│  └─ utils/               # 工具函数（geo、time、format、permission）
├─ resources/
├─ build/
├─ .ai-rules/
│  ├─ product.md          # 产品愿景（由 steering-architect 生成）
│  ├─ tech.md             # 技术栈说明（由 steering-architect 生成）
│  └─ structure.md        # 项目结构（由 steering-architect 生成）
├─ specs/
│  └─ ...                 # 详细任务/测试规范
├─ docs/
├─ RULES.md               # 鸿蒙语法与团队开发约定
└─ README.md
```

---

## 数据库说明 / Database

### 数据库选型与理由

- **类型**：鸿蒙本地关系型数据库（RDB）或系统提供的轻量级本地数据库能力。
- **选型理由**：
  - 关系型表结构便于进行工程→工点→照片的层级存储与关联查询；
  - 鸿蒙系统数据库能力与系统权限/备份机制兼容，便于实现本地备份与导出；
  - 性能满足离线场景与大量照片元数据索引。

### 推荐数据表设计（示例）

> 注意：下列字段为建议，实际实现时请结合项目需求调整并写入 schema migration 流程。

1. `projects`（工程）
- `project_id` (PK)
- `name`
- `code` (项目编号)
- `client`
- `manager`
- `start_date`, `end_date`
- `metadata` (JSON - 扩展字段，如合同号)
- `created_at`, `updated_at`

2. `sites`（施工地点/工点）
- `site_id` (PK)
- `project_id` (FK -> projects)
- `name`
- `address`
- `latitude`, `longitude`, `altitude`
- `tags` (行业标签)
- `created_at`, `updated_at`

3. `photos`（照片元数据）
- `photo_id` (PK)
- `site_id` (FK -> sites)
- `project_id` (FK -> projects)
- `file_path` (本地存储相对路径)
- `taken_at` (timestamp)
- `latitude`, `longitude`, `altitude`
- `azimuth` (方位角)
- `address` (逆地理位置信息)
- `weather` (简要天气信息)
- `watermark_template_id`
- `notes` (自定义备注)
- `tags`
- `created_at`, `updated_at`

4. `watermark_templates`（水印模板配置）
- `template_id`
- `name`
- `fields` (JSON - 包含经纬度、海拔、天气等哪些项)
- `style` (JSON - 文本样式/位置/透明度)
- `created_by`, `shared`

5. `users` / `team_members`（团队成员与权限）
- `user_id`
- `name`, `email`, `role` (owner/editor/viewer)
- `joined_at`

6. `backups`（本地/云端备份记录）
- `backup_id`, `type` (local/cloud), `path`, `created_at`, `status`

### 数据库初始化流程

1. 启动时检查数据库版本与 schema；
2. 若无数据库或版本不匹配，运行 migration：创建表、索引、默认模板与演示数据；
3. 使用 `@ObservedV2` 数据模型将数据库表映射为响应式对象（见下文实现说明）；
4. 加载必要的缓存/索引以优化照片检索（按 project_id, site_id, date, tag）。

### 数据库管理界面功能说明

- 表查看：列出表与记录数；查看表结构与索引；
- 备份/还原：本地备份导出（文件）、导入还原；可选云端备份/还原；
- 清空表/删除数据：按项目或按日期范围清理历史数据（含导出提醒）；
- 数据导出：CSV/JSON/PACK 格式导出；
- 迁移/版本信息：查看当前 DB 版本，手动触发 migration；
- 日志与审计：记录数据库变更操作（备份、清空、导入、删除）以便溯源。

---

## 主题系统说明 / Theme System

### 白天 / 夜间主题实现方式

- 使用系统提供的配置能力（如 `ConfigurationConstant`）读取系统主题偏好；
- 将主题状态（`light`, `dark`, `system`）存入响应式状态管理（使用 `@ObservedV2` 的 `themeStore`）；
- 主题资源（样式变量、图标变体）统一由主题服务加载并注入到组件树；
- 组件中使用主题变量（例如 `--bg-color`, `--text-color`, `--muted`）进行样式绑定。

### 系统跟随功能说明

- 支持三种模式：`light`, `dark`, `system`（默认）；
- 若为 `system`：应用监听系统主题变更事件并实时更新 `themeStore`；
- 开放 UI 设置页面允许用户手动切换并设置为默认模式。

### 动态监听系统主题变化的机制

- 通过鸿蒙平台能力订阅系统配置变更（示例：监听 `ConfigurationConstant.ACCENT` / `uiMode` 等事件）；
- 系统回调触发时，调用主题服务更新 `@ObservedV2` 中的 `theme` 字段；
- 由于 `theme` 为响应式数据，所有订阅了主题数据的组件会自动重渲染并应用新样式。

### 主题切换的响应式实现

- 在 `store/theme.ts` 中使用 `@ObservedV2` 装饰器声明:
  - `mode: 'light' | 'dark' | 'system'`
  - `variables: Record<string, string>`（实时生成当前主题变量）
- 使用 `@Trace` 对关键主题计算属性（如 `isDark`、`accentColor`）做缓存与跟踪；
- 当 `mode` 变化时，持久化到本地存储（可使用 `@StorageLink`）并通知全局主题服务；
- 组件以 `@Param` 或注入方式获取主题 store，样式绑定直接读取响应式变量。

---

## V2 响应式状态管理说明 / V2 Reactive State

### 为什么使用 V2

- V2 响应式提供更细粒度的深度观察能力，适合复杂嵌套对象（例如项目->工点->照片->水印）并能保证属性级别变更触发 UI 更新。

### 装饰器与使用说明（概念性说明，无代码示例）

- `@ObservedV2`：用于声明持久化、响应式的 Store 或数据模型，使对象及其嵌套属性可被深度观察；
- `@Trace`：用于标注需要被跟踪的计算属性或高频访问的字段以便优化更新策略；
- `@Local`：声明仅在本地存储/缓存使用的字段或临时态数据；
- `@Param`：用于组件间参数注入并保持响应式联动；
- `@Monitor`：用于监控跨模块状态变更的场景（如同步到云备份状态）。

### 与数据库的整合

- 将数据库查询/变更封装为服务（services/dbService）并在返回数据时**同步写入对应的 `@ObservedV2` 数据模型**；
- 数据库的 CRUD 操作应发出明确的事件或直接更新 `@ObservedV2` 对象引用，使 UI 能立即响应；
- 对于批量数据变更（例如导入/清空表），建议通过事务与一次性替换 `ObservedV2` 中的数组引用以减少重复渲染。

### 深度观察能力

- V2 保证嵌套对象的任意属性变更（例如 `site.address.street`）都会触发绑定该值的组件更新；
- 使用 `@Trace` 对计算字段进行缓存，防止高频读取导致的性能问题；

---

## 核心功能模块说明 / Core Modules

> 下列说明为功能使用说明与交互流程（非代码示例）。

### 1. 工程与施工点管理（Project & Site）
- 创建/编辑工程：填写工程基本信息、负责人、起止时间及行业标签；
- 添加工点：在项目下新增工点，填写地址或通过地图拾取经纬度；
- 批量导入/导出项目数据（CSV/JSON）；
- 团队管理：邀请成员加入指定工程并分配角色权限。

### 2. 拍照与水印（Camera & Watermark）
- 打开相机：应用请求相机、定位、文件写入等权限；
- 自动读取定位与方向：拍照时自动采集经纬度、海拔与方位角，并将选中水印模板渲染到照片上；
- 水印模板：支持多行业风格，可选择显示/隐藏任意字段（如天气、项目名、备注）；
- 拍照结果：保存到本地文件并写入 `photos` 表的元数据；同时更新 `@ObservedV2` 的照片列表。

### 3. 照片编辑与导出（Editor & Export）
- 打开编辑器：从相册或拍照结果进入编辑器；
- 编辑工具：涂鸦、文本标注、图形标注、马赛克等；
- 保存/覆盖：保存操作写入本地存储与表的更新时间字段；
- 导出/分享：拼图报告、一键生成 PDF 或图片压缩包，系统分享对接。

### 4. 云盘存储与备份（Cloud Backup & Sync）
- 可选云端备份：用户可手动或定时备份工程数据到云盘；
- 多设备同步：通过云备份记录实现跨设备恢复（注意：核心数据仍以本地为主、云为备份/同步机制）；
- 冲突处理：备份/恢复时提供时间线与冲突合并提示。

### 5. 团队共享与权限管理（Collaboration）
- 邀请流程：项目管理员邀请成员（邮件/链接）；
- 角色体系：Owner / Editor / Viewer；
- 访问控制：基于角色控制拍照、删除、导出、备份等操作。

### 6. 数据库管理界面（DB Admin）
- 可视化查看表结构、执行备份/恢复、按条件清理数据；
- 提供导出/导入工具并记录操作日志；

---

## 权限需求说明 / Permissions

- 相机（CAMERA）：拍摄照片/视频；
- 麦克风（RECORD_AUDIO）：录视频时采集音频；
- 文件读写（READ/WRITE_EXTERNAL_STORAGE 或等效能力）：保存照片与导出文件；
- 定位（ACCESS_FINE_LOCATION）：获取经纬度与海拔用于水印；
- 设备信息（如获取 MAC）：用于匿名统计/设备识别（需征得用户同意与遵守隐私政策）；
- 网络（可选）：云备份/同步功能；

> 强调：应用核心功能应可在离线环境下运行。任何上传到云端的行为都必须获得用户明确授权。

---

## 隐私与安全 / Privacy & Security

- 所有核心数据默认保存在本地数据库，确保数据本地化和可审计；
- 上云/同步为可选功能，上传前须弹出明确授权说明（包含作用、范围、保留期）；
- 对敏感数据（如设备唯一标识）进行脱敏或摘要处理；
- 提供数据导出与彻底删除（wipe）功能，便于合规要求。

---

## 开发与交付流程（Agent 协同工作流）

项目在组织内按以下角色与产物开展：

### 1. 调度与项目指导（steering-architect）
- 产出文件：`.ai-rules/product.md`（产品愿景）、`.ai-rules/tech.md`（技术栈）、`.ai-rules/structure.md`（项目结构）。

### 2. 战略规划（strategic-planner）
- 分阶段产物：
  - Phase 1: `requirements.md`（需求定义）
  - Phase 2: `design.md`（技术设计）
  - Phase 3: `tasks.md`（任务清单与依赖）

### 3. 任务执行（task-executor）
- 执行规范：
  - 每完成一个小节必须进行 Git 提交（commit）；提交前必须使项目通过编译；
  - 使用 `hvigorw assembleHap` 进行编译/校验；
  - 新增文件必须被正确引用并创建测试页面以验证编译通过；
  - 严格遵守 `RULES.md` 中定义的鸿蒙开发规范。

---

## 发布与版本计划 / Release & Versioning

- 本 README 对应 v1.0.0：核心功能与离线化优先实现；
- 建议采用语义化版本控制（SemVer）：MAJOR.MINOR.PATCH；
- 发布流程：每个里程碑合并前通过 CI（包含 `hvigorw assembleHap`）检查并执行自动化测试。

---

## 附录 / Appendix

- 开发注意事项：
  - **必须使用 ArkTS 与 V2 响应式管理**，任何示例或第三方库的引入须保证与 V2 的兼容性；
  - 确保数据库操作与 `@ObservedV2` 对象的同步策略，避免竞态与不一致；
  - 主题切换与样式变量应作为全局服务管理，组件通过响应式注入获得主题变量；
  - 权限申请流程需友好并提供失败降级方案（例如定位失败时允许手动填入坐标）。

- 可扩展点：
  - 增加多种水印模板市场/模板导入导出；
  - 集成企业 SSO 与统一用户管理；
  - 增强的冲突合并策略与多版本历史回滚。

---

## 联系 / Contact

- 作者 / Maintainer: dandan
- 项目类型: 鸿蒙纯前端（ArkTS + ArkUI + V2）

---

（中文与英文文档已合并在本 README 中。若需要单独的英文 README 或导出的 Markdown 文件，请说明。）

