# GitHub Actions 自动构建 Windows 可执行文件方案

## 文档信息

- **创建日期**：2026-05-03
- **最后更新**：2026-05-03
- **适用项目**：tictactoe_game
- **当前版本**：v1.0.2

---

## 一、方案概述

### 1.1 背景

- **问题**：当前开发环境（Trae IDE）无法直接构建 Windows exe
- **需求**：需要一个可以在 Windows 上双击运行的游戏软件
- **方案**：使用 GitHub Actions 进行云端自动构建

### 1.2 方案优势

| 优势 | 说明 |
|------|------|
| **完全免费** | 公共仓库无限构建分钟数 |
| **无需本地环境** | 不需要 Windows 电脑，不需要安装任何软件 |
| **自动构建** | 推送代码后自动触发构建 |
| **自动发布** | 推送 Tag 后自动创建 GitHub Release |
| **产物可下载** | 构建完成后直接下载 exe 文件 |

### 1.3 工作原理

```
开发者操作                    GitHub Actions                    用户
    │                              │                           │
    │  git push origin master     │                           │
    │ ──────────────────────────> │                           │
    │                              │  1. 检出代码               │
    │                              │  2. 安装 Flutter          │
    │                              │  3. 构建 exe               │
    │                              │  4. 上传 Artifact          │
    │                              │                           │
    │  git push origin v1.0.2     │                           │
    │ ──────────────────────────> │                           │
    │                              │  1. 执行上述构建步骤        │
    │                              │  2. 自动创建 GitHub Release│
    │                              │  3. 自动上传 exe 到 Release│
    │                              │                           │
    │                              │                    下载 exe │
    │                              │ <────────────────────────── │
    │                              │                           │
```

---

## 二、配置文件说明

### 2.1 文件位置

```
.github/workflows/build-windows.yml
```

### 2.2 完整配置

```yaml
name: Build and Release Windows Executable

on:
  push:
    branches: [main, master]
    tags:
      - 'v*'
  pull_request:
    branches: [main, master]
  workflow_dispatch:

jobs:
  build-windows:
    runs-on: windows-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.9'
          channel: 'stable'
          cache: true
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Enable Windows desktop
        run: flutter config --enable-windows-desktop
      
      - name: Generate Windows platform files
        run: flutter create . --platforms windows
      
      - name: Build Windows executable
        run: flutter build windows --release
      
      - name: Create distribution package
        run: |
          $buildDir = "build/windows/x64/runner/Release"
          $distDir = "tictactoe-game-windows"
          
          New-Item -ItemType Directory -Path $distDir -Force
          Copy-Item -Path "$buildDir/*" -Destination $distDir -Recurse
          
          Compress-Archive -Path $distDir -DestinationPath "tictactoe-game-windows.zip"
      
      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: tictactoe-game-windows
          path: tictactoe-game-windows.zip
          retention-days: 30
      
      - name: Create GitHub Release
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v1
        with:
          files: tictactoe-game-windows.zip
          generate_release_notes: true
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 2.3 配置详解

#### 触发条件（on）

| 条件 | 说明 |
|------|------|
| `branches: [main, master]` | 推送到 main 或 master 分支时触发 |
| `tags: ['v*']` | 推送 v 开头的 tag 时触发（如 v1.0.2） |
| `workflow_dispatch` | 允许手动触发构建 |

#### 构建步骤（jobs.build-windows.steps）

| 步骤 | 说明 |
|------|------|
| Checkout code | 从 GitHub 检出代码 |
| Setup Flutter | 安装 Flutter SDK（版本 3.41.9） |
| Install dependencies | 执行 `flutter pub get` |
| Enable Windows desktop | 启用 Windows 桌面支持 |
| Generate Windows platform files | 生成 Windows 平台特定文件 |
| Build Windows executable | 构建 Release 版本 exe |
| Create distribution package | 打包成 zip 文件 |
| Upload build artifact | 上传构建产物（保留 30 天） |
| Create GitHub Release | **仅当推送 tag 时**：自动创建 Release |

#### 关键条件判断

```yaml
if: startsWith(github.ref, 'refs/tags/')
```

- 当推送 `v1.0.2` 等 tag 时，`github.ref` 为 `refs/tags/v1.0.2`
- 此条件为 `true`，执行创建 Release 步骤
- 普通分支推送时，此条件为 `false`，跳过 Release 创建

---

## 三、完整操作流程

### 3.1 首次配置（只需执行一次）

#### 步骤 1：创建 GitHub 仓库

1. 登录 https://github.com
2. 点击 **New repository**
3. 填写：
   - **Repository name**: `tictactoe-game`
   - **Public / Private**: 选择 **Public**（推荐，免费无限构建）
   - **Add a README file**: **不勾选**
4. 点击 **Create repository**

#### 步骤 2：配置 Git 身份

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 配置用户名（使用你的 GitHub 用户名）
git config --global user.name "你的GitHub用户名"

# 配置邮箱（使用 GitHub 注册邮箱）
git config --global user.email "你的GitHub邮箱@example.com"
```

#### 步骤 3：初始化 Git 仓库

```bash
# 检查是否已是 Git 仓库
ls -la .git 2>/dev/null || git init
```

#### 步骤 4：添加远程仓库

```bash
# 使用 HTTPS（需要 Token）
git remote add origin https://github.com/你的用户名/tictactoe-game.git

# 或使用 SSH（需要配置 SSH 密钥）
# git remote add origin git@github.com:你的用户名/tictactoe-game.git

# 验证
git remote -v
```

#### 步骤 5：创建 GitHub Personal Access Token（HTTPS 方式需要）

1. 登录 GitHub → 点击右上角头像 → **Settings**
2. 左侧菜单最下方 → **Developer settings**
3. 点击 **Personal access tokens** → **Tokens (classic)**
4. 点击 **Generate new token** → **Generate new token (classic)**
5. 填写：
   - **Note**: `tictactoe-game-token`
   - **Expiration**: 选择有效期（如 90 天）
   - **Select scopes**: 勾选 **repo**（完整仓库访问权限）
6. 点击 **Generate token**
7. ⚠️ **重要**：立即复制生成的 Token（只显示一次！）

**使用方式**：
- 推送时提示输入密码，粘贴此 Token
- 不是 GitHub 登录密码！

---

### 3.2 日常开发流程

#### 场景 A：普通开发（不创建 Release）

```bash
# 1. 修改代码

# 2. 检查状态
git status

# 3. 添加修改
git add .

# 4. 提交
git commit -m "feat: 添加某某功能"

# 5. 推送到 master
git push origin master
```

**结果**：
- ✅ GitHub Actions 自动构建 exe
- ✅ 上传到 Artifacts（保留 30 天）
- ❌ 不创建 GitHub Release

#### 场景 B：发布新版本（创建 Release）

```bash
# 1. 修改代码

# 2. 检查状态
git status

# 3. 添加修改
git add .

# 4. 提交
git commit -m "fix: 修复某某 Bug"

# 5. 创建 Tag（关键！）
git tag -a v1.0.2 -m "v1.0.2 - Bug 修复版本"

# 6. 推送代码
git push origin master

# 7. 推送 Tag（触发自动 Release！）
git push origin v1.0.2
```

**结果**：
- ✅ GitHub Actions 自动构建 exe
- ✅ 上传到 Artifacts
- ✅ **自动创建 GitHub Release**
- ✅ **自动上传 exe 到 Release Assets**

---

### 3.3 版本号规范

#### 语义化版本控制（SemVer）

```
vMAJOR.MINOR.PATCH
  │       │      │
  │       │      └── PATCH: Bug 修复（如 v1.0.0 → v1.0.1）
  │       │
  │       └── MINOR: 新增功能（向后兼容）（如 v1.0.1 → v1.1.0）
  │
  └── MAJOR: 不兼容的 API 变更（如 v1.1.0 → v2.0.0）
```

#### 版本号递增示例

| 场景 | 版本变更 |
|------|----------|
| Bug 修复（棋子顺序问题） | v1.0.0 → v1.0.1 或 v1.0.2 |
| 新增功能（如音效、AI对手） | v1.0.2 → v1.1.0 |
| 重大重构（不兼容旧版本） | v1.1.0 → v2.0.0 |

#### Tag 命名规范

| Tag 名称 | 说明 |
|----------|------|
| `v1.0.0` | 正式版本 |
| `v1.0.1` | Bug 修复版本 |
| `v1.0.2` | 当前版本 |
| `v1.1.0` | 新增功能版本 |
| `v2.0.0` | 重大变更版本 |

---

### 3.4 完整命令汇总

#### 首次配置（只需一次）

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 配置 Git 身份
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的GitHub邮箱@example.com"

# 初始化 Git（如果还没有）
git init

# 添加远程仓库
git remote add origin https://github.com/你的用户名/tictactoe-game.git

# 验证
git remote -v
```

#### 日常开发（不发布）

```bash
git add .
git commit -m "描述你的修改"
git push origin master
```

#### 发布版本（创建 Release）

```bash
git add .
git commit -m "描述你的修改"
git tag -a v1.0.2 -m "v1.0.2 - 版本说明"
git push origin master
git push origin v1.0.2
```

---

## 四、验证与下载

### 4.1 查看构建状态

1. 打开 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 查看工作流运行状态：
   - 🟡 黄色圆点：正在运行
   - ✅ 绿色对勾：构建成功
   - ❌ 红色叉号：构建失败

### 4.2 查看构建日志

1. 点击具体的工作流运行
2. 点击 **build-windows** 任务
3. 展开各个步骤查看详细日志
4. 如果构建失败，根据错误信息修复

### 4.3 下载构建产物

#### 方式 A：从 Artifacts 下载（任何构建都有）

1. 打开 GitHub Actions → 点击成功的工作流
2. 滚动到页面底部
3. 找到 **Artifacts** 区域
4. 点击 `tictactoe-game-windows` 下载

#### 方式 B：从 Release 下载（仅 Tag 推送有）

1. 打开 GitHub 仓库主页面
2. 点击右侧 **Releases** 区域
3. 点击对应的版本（如 `v1.0.2`）
4. 找到 **Assets** 区域
5. 点击 `tictactoe-game-windows.zip` 下载

### 4.4 在 Windows 上运行

1. 将下载的 zip 文件复制到 Windows 电脑
2. 右键点击 → **解压到当前文件夹**
3. 打开解压后的文件夹 `tictactoe-game-windows`
4. 双击运行 `tictactoe_game.exe`

**⚠️ 重要提示**：
- 不要只复制 exe 文件，需要整个文件夹
- exe 依赖同目录下的 dll 和 data 文件夹

---

## 五、构建产物说明

### 5.1 文件结构

```
tictactoe-game-windows/
├── tictactoe_game.exe          # 主程序（双击运行）
├── flutter_windows.dll         # Flutter 引擎
├── data/
│   ├── app.so                  # 编译后的 Dart 代码
│   └── icudtl.dat              # 国际化数据
├── msvcp140.dll                # Visual C++ 运行时
├── vcruntime140.dll            # Visual C++ 运行时
└── ...（其他依赖文件）
```

### 5.2 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 10 或 Windows 11 |
| 架构 | 64 位（x64） |
| 内存 | 最低 4GB |
| 硬盘 | 约 50MB 可用空间 |

### 5.3 分发方式

| 方式 | 说明 |
|------|------|
| **直接发送** | 将整个文件夹打包成 zip 发送给朋友 |
| **GitHub Release** | 用户从 GitHub 下载最新版本 |
| **安装包** | 可使用 Inno Setup 等工具创建安装程序（可选） |

---

## 六、版本历史

### v1.0.2（当前版本）

- **发布日期**：2026-05-03
- **变更类型**：Bug 修复 + CI/CD 优化
- **主要变更**：
  1. 修复棋子顺序计算逻辑错误
     - 问题：移除旧棋子后，新棋子顺序显示为 1, 2, 4
     - 原因：顺序计算在移除操作之前
     - 修复：调整代码执行顺序，先移除再计算
  2. 配置 GitHub Actions 自动构建
     - 支持 main 和 master 双分支
     - 推送 Tag 自动创建 Release
     - 自动生成 Release 说明

### v1.0.1（未发布）

- 计划中的 Bug 修复版本
- 与 v1.0.2 合并发布

### v1.0.0（初始版本）

- 首次发布
- 包含完整游戏功能
- 存在棋子顺序显示 Bug

---

## 七、故障排查

### 问题 1：推送时认证失败

**现象**：
```
fatal: Authentication failed for 'https://github.com/.../'
```

**原因**：
- 使用了 GitHub 登录密码（现在需要 Personal Access Token）

**解决方案**：
1. 创建 Personal Access Token（参考 3.1 步骤 5）
2. 推送时，密码输入 Token（不是 GitHub 密码）
3. 或者使用 SSH 方式（配置 SSH 密钥）

### 问题 2：构建失败

**现象**：GitHub Actions 显示红色叉号

**排查步骤**：
1. 打开 Actions → 点击失败的工作流
2. 查看哪个步骤失败
3. 展开失败步骤查看详细日志
4. 根据错误信息修复代码

**常见错误**：
| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 依赖安装失败 | 网络问题或版本冲突 | 检查 pubspec.yaml，重试构建 |
| 编译错误 | 代码有语法错误 | 修复代码后重新推送 |
| Windows 构建失败 | 缺少平台文件 | 确保 `flutter create .` 执行成功 |

### 问题 3：Release 没有自动创建

**现象**：推送了 Tag，但没有看到 Release

**可能原因**：
1. Tag 名称不符合 `v*` 格式（如 `1.0.2` 而不是 `v1.0.2`）
2. 构建过程中出错
3. `if` 条件判断问题

**解决方案**：
1. 检查 Tag 名称：必须以 `v` 开头
2. 检查 GitHub Actions 构建是否成功
3. 确认配置文件中的 `if` 条件正确

### 问题 4：exe 无法运行

**现象**：双击 exe 没有反应或报错

**可能原因**：
1. 只复制了 exe 文件，缺少依赖
2. Windows 版本过低
3. 缺少 Visual C++ 运行时

**解决方案**：
1. 确保复制了整个文件夹，不是只复制 exe
2. 确认目标电脑是 Windows 10 或更高版本
3. 尝试安装 Visual C++ Redistributable（通常已包含在打包中）

---

## 八、高级配置（可选）

### 8.1 自定义 Release 标题

修改 `build-windows.yml` 中的 Release 步骤：

```yaml
      - name: Create GitHub Release
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v1
        with:
          name: Release ${{ github.ref_name }}    # 自定义标题
          files: tictactoe-game-windows.zip
          generate_release_notes: true
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 8.2 预发布版本

如果是测试版本，设置 `prerelease: true`：

```yaml
prerelease: true
```

### 8.3 草稿模式

创建草稿 Release，手动确认后发布：

```yaml
draft: true
```

### 8.4 多平台构建

未来可扩展为支持多平台：

```yaml
jobs:
  build-windows:
    runs-on: windows-latest
    # ... Windows 构建步骤
  
  build-web:
    runs-on: ubuntu-latest
    # ... Web 构建步骤
  
  build-android:
    runs-on: ubuntu-latest
    # ... Android 构建步骤
```

需要吗？我可以帮您添加多平台支持。

---

## 九、快速参考

### 9.1 常用命令速查

| 命令 | 说明 |
|------|------|
| `git status` | 查看当前状态 |
| `git add .` | 添加所有修改 |
| `git commit -m "消息"` | 提交代码 |
| `git branch` | 查看分支 |
| `git tag` | 查看所有 tag |
| `git tag -a v1.0.2 -m "说明"` | 创建 annotated tag |
| `git push origin master` | 推送代码到 master |
| `git push origin v1.0.2` | 推送 tag（触发 Release） |
| `git log --oneline -5` | 查看最近 5 条提交 |

### 9.2 链接速查

| 项目 | 链接 |
|------|------|
| GitHub 仓库 | `https://github.com/你的用户名/tictactoe-game` |
| Actions 页面 | `https://github.com/你的用户名/tictactoe-game/actions` |
| Releases 页面 | `https://github.com/你的用户名/tictactoe-game/releases` |
| 创建 Token | `https://github.com/settings/tokens` |
| Flutter 官方文档 | `https://docs.flutter.dev/` |
| GitHub Actions 文档 | `https://docs.github.com/en/actions` |

### 9.3 验证清单

| 验证项 | 操作 | 预期结果 |
|--------|------|----------|
| Git 状态 | `git status` | 显示当前状态 |
| 远程仓库 | `git remote -v` | 显示 origin 地址 |
| Tag 列表 | `git tag` | 显示已创建的 tag |
| Actions 构建 | 打开 Actions 页面 | 构建成功 ✅ |
| Release 创建 | 打开 Releases 页面 | 有对应版本 ✅ |
| 构建产物 | 查看 Assets | 有 zip 文件 ✅ |

---

## 十、附录

### A. 完整操作示例

#### 示例 1：修复 Bug 并发布 v1.0.2

```bash
# 1. 确认当前在项目目录
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 2. 检查状态
git status
# 输出：On branch master, Changes not staged for commit

# 3. 添加修改
git add .

# 4. 提交
git commit -m "fix: 修复棋子顺序计算逻辑

- 问题：移除旧棋子后，新棋子顺序显示为 1, 2, 4
- 原因：顺序计算在移除操作之前执行
- 修复：调整代码执行顺序，先移除再计算"

# 5. 创建 Tag
git tag -a v1.0.2 -m "v1.0.2 - Bug 修复版本

修复内容：
- 棋子顺序显示 Bug：1,2,4 → 1,2,3
- CI/CD 优化：配置自动创建 Release"

# 6. 推送代码
git push origin master

# 7. 推送 Tag（触发自动 Release）
git push origin v1.0.2

# 8. 等待 GitHub Actions 构建（约 5-10 分钟）

# 9. 打开 GitHub Releases 页面下载 exe
```

#### 示例 2：日常开发（不发布）

```bash
# 1. 修改代码

# 2. 提交
git add .
git commit -m "docs: 更新 README"

# 3. 推送（仅构建，不创建 Release）
git push origin master
```

---

## 文档修订历史

| 版本 | 日期 | 修订内容 | 作者 |
|------|------|----------|------|
| 1.0 | 2026-05-03 | 初始版本，完整记录 GitHub Actions 构建方案 | - |

---

**维护者**：开发团队
**最后更新**：2026-05-03
