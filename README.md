# PhotoMaster

> 小圈子影像分享 + 端侧画质分析工具。基于 Flutter 一套代码跨 Android / Web，后端用 Supabase。

简体中文 | [English](README.en.md)

[![Stars](https://img.shields.io/github/stars/chuchu08241010-coder/photomaster_software?style=flat-square)](https://github.com/chuchu08241010-coder/photomaster_software/stargazers)
[![Release](https://img.shields.io/github/v/release/chuchu08241010-coder/photomaster_software?style=flat-square)](https://github.com/chuchu08241010-coder/photomaster_software/releases)
[![License](https://img.shields.io/github/license/chuchu08241010-coder/photomaster_software?style=flat-square)](LICENSE)
![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?style=flat-square&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white)

PhotoMaster 是一个面向好友小圈子的摄影分享应用，并内置**完全在本地运行、不上传原图**的画质分析模块（直方图 / 波形 / 清晰度 / 噪声 / 对比度 / 动态范围 / EXIF），以及**竞品 A/B 客观对比**。

## ✨ 功能特性

- **摄影分享**：发图帖（文案 / #标签 / 地址 / 自动 EXIF）→ 朋友圈式时间线 + 个人主页；可编辑、删除、收藏、评论。
- **文字帖**：器材 / 技巧 / 提问 / 后期 / 预设 / 机位 六类，与图片分享隔离。
- **主题投稿活动**：像公众号推送——1:1 海报 + 标题；进入看规则、投稿，作品可点赞、可改删。
- **端侧画质分析**：本地计算亮度/RGB 直方图、亮度波形、清晰度（拉普拉斯方差 + Tenengrad）、噪声（Immerkær 估计）、RMS 对比度、有效动态范围、色温，并综合评分；每项指标带阈值与原理解读；可保存/分享分析图。
- **竞品 A/B 对比**：两张样张逐项客观对比并自动判优。
- **邮箱验证码登录**：身份绑定邮箱，换设备/重装可找回。
- **其他**：漂流瓶每日开场、评论通知、IP 属地、应用内新版本提示、多套配色主题、使用说明。

## 📸 截图

| 时间线 | 画质分析 | 竞品对比 |
|---|---|---|
| ![时间线](docs/screenshots/timeline.jpg) | ![画质分析](docs/screenshots/analysis.jpg) | ![竞品对比](docs/screenshots/compare.jpg) |

## 🧩 技术栈

- **前端**：Flutter / Dart，Riverpod（状态）、go_router（路由）、`image` / `exif`（端侧图像处理）、cached_network_image
- **后端**：Supabase（Auth + PostgreSQL + Storage，行级安全 RLS）
- **部署**：Web → Netlify；Android → 签名 APK

## 🏗️ 架构

```mermaid
flowchart LR
  subgraph Client["Flutter 客户端 · Android / Web"]
    UI["UI：摄影 / 活动 / 分析 / 我的"]
    Lab["端侧画质分析（直方图/波形/清晰度/噪声/对比度/动态范围）"]
    AuthC["邮箱验证码登录"]
  end
  subgraph Backend["Supabase 后端"]
    DB[("PostgreSQL + RLS")]
    Store[("Storage 图片桶")]
    Auth["Auth"]
  end
  UI -->|"发帖/评论/收藏/投稿"| DB
  UI -->|"上传压缩图"| Store
  AuthC --> Auth
  Lab -. "本地计算，不上传原图" .- UI
```

## 🔬 端侧画质分析算法

全部在设备本地完成，不上传图片：

| 指标 | 方法 |
|---|---|
| 清晰度 | 拉普拉斯方差、Tenengrad（Sobel 梯度能量）|
| 噪声 | Immerkær 噪声估计（特定卷积核）|
| 对比度 | RMS 对比度（亮度标准差）|
| 动态范围 | 亮度 0.5%~99.5% 分位跨度换算成档(stops) |
| 曝光 | 高光溢出 / 暗部死黑占比、平均亮度 |
| 色彩 | 灰世界近似色温 |
| 波形/直方图 | Luma + RGB 分布、亮度波形 |

## 🚀 快速开始

### 环境要求
- Flutter 3.44+（Dart 3.12+）
- 一个 Supabase 项目（免费额度即可；后端与凭据配置见下方「配置你自己的 Supabase」）

### 运行
```bash
flutter pub get
flutter run --dart-define-from-file=env/supabase.json
```

### 构建
```bash
# Web（中国网络下加 --no-web-resources-cdn 避免 CanvasKit 从 Google CDN 加载）
flutter build web --release --no-web-resources-cdn --dart-define-from-file=env/supabase.json

# Android APK
flutter build apk --release --dart-define-from-file=env/supabase.json
```

## 🔧 配置你自己的 Supabase（详细步骤）

本项目自带一个 Supabase 项目才能跑起来（免费额度即可）。**每个人用自己的 Supabase，数据互不相通。**

### 1. 新建项目
1. 注册并登录 [supabase.com](https://supabase.com/)，点 **New project**。
2. 填项目名、数据库密码、地区（选离你近的），等待初始化完成。

### 2. 初始化数据库
1. 左侧进入 **SQL Editor** → New query。
2. 打开本仓库的 [`supabase/schema.sql`](supabase/schema.sql)，**全选复制**，粘贴后点 **Run**。
   - 这一步会自动建好所有表、行级安全策略（RLS）、函数、触发器，以及图片存储桶 `post-images`。
   - 脚本可重复运行（都是 `if not exists` / `drop policy if exists`），安全。

### 3. 打开邮箱验证码登录
1. **Authentication → Providers → Email**：开启，并允许新用户注册。
2. **Authentication → Email Templates**：把 **Magic Link** 和 **Confirm signup** 两个模板的正文加入验证码变量 `{{ .Token }}`，例如：
   ```html
   <h2>登录验证码</h2>
   <p style="font-size:28px;font-weight:bold;letter-spacing:4px;">{{ .Token }}</p>
   ```
3.（可选，推荐）**Authentication → SMTP Settings** 配置自定义 SMTP（如 QQ/163/Brevo），否则内置邮件有严格的发送频率限制、且模板可能不可编辑。

### 4. 取得连接凭据
在 **Project Settings → API** 页面复制：
- **Project URL** → 填到 `SUPABASE_URL`
- **anon / publishable key**（`publishable`，**不要用 `service_role`**）→ 填到 `SUPABASE_PUBLISHABLE_KEY`

### 5. 写入本地配置（不会进 git）
```bash
cp env/supabase.json.example env/supabase.json
```
编辑 `env/supabase.json`：
```jsonc
{
  "SUPABASE_URL": "https://<你的项目ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "<你的 publishable key>"
}
```
> 该文件已被 `.gitignore` 忽略——**你的凭据只留在本地，绝不会被提交或开源**。

### 6. 运行
```bash
flutter pub get
flutter run --dart-define-from-file=env/supabase.json
```
首次用邮箱登录：输入邮箱 → 收验证码 → 输码 → 设昵称即可进入。

> ⚠️ **安全提示**：`service_role` 密钥拥有绕过 RLS 的最高权限，**只能用于服务端、切勿写进客户端或提交到仓库**。客户端只用 `publishable/anon` key。

## 📁 目录结构

```
lib/
  app/           # 应用入口、路由、主题
  core/          # Supabase 客户端、通用组件
  features/
    auth/        # 邮箱验证码登录
    photography/ # 摄影帖 / 时间线 / 发帖 / 搜索
    text_post/   # 文字帖
    campaign/    # 主题投稿活动
    lab/         # 端侧画质分析 + 竞品对比
    social/      # 收藏 / 评论 / 操作条（通用）
    profile/     # 个人主页 / 资料
    notifications/ update/ drift_bottle/ ...
supabase/schema.sql   # 数据库结构与 RLS（自行在 Supabase 运行）
```

## 📄 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
