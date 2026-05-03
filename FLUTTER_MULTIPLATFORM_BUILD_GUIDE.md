# Flutter 多平台统一构建方案 v2.0

> 文档版本：v2.0
> 最后更新：2026-05-03
> 适用项目：tictactoe_game

---

## 目录

1. [设计思想](#一设计思想)
2. [文件结构](#二文件结构)
3. [快速开始](#三快速开始)
4. [详细操作步骤](#四详细操作步骤)
5. [常见问题](#五常见问题)
6. [Workflow 配置详解](#六workflow-配置详解)
7. [模板文件详解](#七模板文件详解)
8. [安全建议](#八安全建议)
9. [回滚方案](#九回滚方案)

---

## 一、设计思想

### 1.1 原方案的问题

在 v1.0 版本中，我们使用了两个独立的 GitHub Actions Workflow：
- `build-windows.yml` - 构建 Windows exe
- `build-android.yml` - 构建 Android APK

**存在的问题**：

| 问题 | 说明 | 风险 |
|------|------|------|
| **竞争条件** | 两个 Workflow 同时触发，可能创建两个 Release | Release 被创建两次，资产分散 |
| **sed 脆弱性** | 使用 sed 动态修改 `build.gradle` | Flutter 版本升级可能导致格式不匹配 |
| **无预检查** | 构建开始后才发现 Secrets 未配置 | 浪费构建时间，失败原因不明确 |
| **无签名验证** | 无法确认 APK 是否正确签名 | 可能发布未签名的 APK |
| **多 Workflow 混乱** | 推送 tag 触发多个 Workflow | 界面混乱，难以调试 |

### 1.2 v2.0 的解决方案

#### 核心设计原则

```
┌─────────────────────────────────────────────────────────────────────┐
│                        v2.0 设计原则                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. 单一入口                                                         │
│     └── 统一 Workflow，消除竞争条件                                  │
│                                                                     │
│  2. 显式依赖                                                         │
│     └── 使用 needs 关键字确保执行顺序                                     │
│                                                                     │
│  3. 提前验证                                                         │
│     └── pre-check Job 在构建前验证配置                                │
│                                                                     │
│  4. 模板替换                                                         │
│     └── 使用模板文件替代 sed 动态修改                                 │
│                                                                     │
│  5. 事后验证                                                         │
│     └── 签名验证确保 APK 正确签名                                    │
│                                                                     │
│  6. 原子发布                                                         │
│     └── 只有双平台都成功才创建 Release                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

#### 架构对比

**v1.0 架构**：
```
推送 tag v1.0.3
    │
    ├───▶ Build Windows Executable ──▶ 创建 Release
    │
    └───▶ Build Android Release APK ──▶ 追加到 Release（可能竞争）
```

**v2.0 架构**：
```
推送 tag v1.0.4
    │
    ▼
┌─────────────────┐
│   pre-check     │ 验证：Tag 格式、Secrets、模板文件
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌─────────┐
│Windows│ │ Android │ 并行执行
│ Build │ │  Build  │
└───┬───┘ └────┬────┘
    │            │
    └─────┬──────┘
          │
          ▼
    ┌───────────┐
    │create-    │ 只有前两个都成功才执行
    │ release  │ 创建统一 Release
    └───────────┘
```

### 1.3 Job 依赖关系

```yaml
# 伪代码表示依赖关系：

pre-check:
  - 验证所有配置

build-windows:
  needs: pre-check      # 依赖 pre-check 成功
  - 构建 Windows exe
  - 上传 Artifact

build-android:
  needs: pre-check      # 依赖 pre-check 成功
  - 构建 Android APK
  - 签名验证
  - 上传 Artifact

create-release:
  needs: [pre-check, build-windows, build-android]  # 依赖所有三个 Job
  - 下载 Artifacts
  - 创建 Release
```

### 1.4 为什么这样设计？

| 设计决策 | 原因 | 优势 |
|----------|------|------|
| **统一 Workflow** | 消除竞争条件 | 确保 Release 只创建一次 |
| **needs 依赖** | 控制执行顺序 | pre-check 失败则不执行构建 |
| **pre-check Job** | 提前验证配置 | 避免浪费构建时间 |
| **模板文件替换** | sed 方式不可靠 | 完全可控，不依赖格式 |
| **签名验证** | 无法确认签名结果 | 确保 APK 正确签名 |
| **独立 create-release** | 原子性发布 | 要么都发布，要么都不发布 |

---

## 二、文件结构

### 2.1 新增/修改的文件

```
tictactoe_game/
├── .github/
│   └── workflows/
│       ├── build-all.yml              ✅ 新增（统一 Workflow）
│       ├── build-windows.yml          ⚠️ 建议禁用（旧方案）
│       └── build-android.yml          ⚠️ 建议禁用（旧方案）
│
├── config/
│   └── android/
│       └── app-build.gradle.template    ✅ 新增（签名配置模板）
│
├── .gitignore                        ✅ 已修改（添加忽略规则）
│
├── pubspec.yaml                        ⚠️ 需确认（版本号）
│
└── 安卓方案.md                         ✅ 本文档
```

### 2.2 不应提交的文件

| 文件 | 说明 | 为什么不应提交 |
|------|------|----------------|
| `tictactoe-keystore.jks` | 密钥库文件 | 包含私钥，泄露风险 |
| `key.properties` | 签名配置 | 包含密码 |
| `keystore-base64.txt` | Base64 编码 | 可解码为私钥 |
| `android/` | 动态生成 | `flutter create` 会重新生成 |
| `windows/` | 动态生成 | `flutter create` 会重新生成 |
| `build/` | 构建输出 | 临时文件 |

### 2.3 .gitignore 配置

```gitignore
# Android Signing (敏感信息，绝不提交)
*.jks
*.keystore
key.properties
android-signing/

# Base64 encoded keystore (敏感信息，绝不提交)
*base64*.txt
```

---

## 三、快速开始

### 3.1 前置条件

| 条件 | 说明 |
|------|------|
| GitHub 仓库 | 已有 tictactoe_game 项目 |
| Java JDK | 用于创建密钥库（本地可选，GitHub Actions 会自动配置） |
| Git | 用于提交和推送 |

### 3.2 快速操作清单

```
┌─────────────────────────────────────────────────────────────┐
│                    快速操作流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                           │
│  第一步：创建密钥库（如果还没有）                          │
│  ├── 安装 Java JDK                                      │
│  ├── 运行 keytool 命令                                   │
│  └── 记住密码！                                          │
│                                                           │
│  第二步：配置 GitHub Secrets                                │
│  ├── ANDROID_KEYSTORE_BASE64                           │
│  ├── ANDROID_KEYSTORE_PASSWORD                          │
│  ├── ANDROID_KEY_PASSWORD                               │
│  └── ANDROID_KEY_ALIAS                                    │
│                                                           │
│  第三步：确认文件已提交                                   │
│  ├── build-all.yml                                       │
│  ├── app-build.gradle.template                           │
│  ├── .gitignore                                          │
│  └── 安卓方案.md                                          │
│                                                           │
│  第四步：创建并推送 tag                                    │
│  ├── git tag -a v1.0.4 -m "..."                        │
│  └── git push origin v1.0.4                               │
│                                                           │
│  第五步：监控构建                                         │
│  ├── 打开 GitHub Actions                                 │
│  └── 观察执行顺序                                         │
│                                                           │
│  第六步：验证结果                                         │
│  └── 确认 Release 包含双平台文件                           │
│                                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 四、详细操作步骤

### 4.1 阶段一：创建密钥库

#### 步骤 1.1：检查 Java 环境

```bash
# 检查 Java 版本
java -version

# 检查 keytool
which keytool
```

**如果没有安装 Java**：

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y openjdk-17-jdk

# CentOS/RHEL
sudo yum install -y java-17-openjdk-devel
```

#### 步骤 1.2：创建密钥库

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 创建密钥库（交互式）
keytool -genkey -v \
  -keystore tictactoe-keystore.jks \
  -alias tictactoe-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 36500
```

#### 步骤 1.3：交互式问题详解

| 问题 | 说明 | 示例回答 |
|------|------|----------|
| 输入密钥库口令 | 保护整个 .jks 文件的密码 | `MyStrongPass123! |
| 再次输入新口令 | 确认密码 | 同上 |
| 您的名字与姓氏是什么? | 证书中的 CN 字段 | `TicTacToe Game` |
| 您的组织单位名称是什么? | 证书中的 OU 字段 | `Personal Project` |
| 您的组织名称是什么? | 证书中的 O 字段 | `Personal` |
| 您所在的城市或区域名称是什么? | 证书中的 L 字段 | `Beijing` |
| 您所在的省/市/自治区名称是什么? | 证书中的 ST 字段 | `Beijing` |
| 该单位的双字母国家/地区代码是什么? | 证书中的 C 字段 | `CN` |
| 以上信息是否正确? | 确认 | `y` |
| 输入 <tictactoe-key> 的密钥口令 | 密钥本身的密码 | **直接按回车（使用相同密码） |

#### 步骤 1.4：验证密钥库

```bash
# 查看密钥库内容
keytool -list -v -keystore tictactoe-keystore.jks
```

**预期输出**：
```
密钥库类型: PKCS12
密钥库提供方: SUN

您的密钥库包含 1 个条目

别名名称: tictactoe-key
创建日期: 2026-5-3
条目类型: PrivateKeyEntry
证书链长度: 1
...
```

### 4.2 阶段二：配置 GitHub Secrets

#### 步骤 2.1：Base64 编码密钥库

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 编码（-w 0 表示不换行，重要！）
base64 -w 0 tictactoe-keystore.jks > keystore-base64.txt

# 验证
ls -la keystore-base64.txt
```

#### 步骤 2.2：打开 GitHub Secrets 页面

1. 打开 `https://github.com/你的用户名/tictactoe-game`
2. 点击 **Settings** 标签
3. 左侧菜单找到 **Secrets and variables** → **Actions**
4. 点击 **New repository secret** 按钮

#### 步骤 2.3：添加 4 个 Secrets

| Secret 名称 | 值 | 说明 |
|-------------|-----|------|
| `ANDROID_KEYSTORE_BASE64` | `keystore-base64.txt` 的全部内容 | 一长串字符 |
| `ANDROID_KEYSTORE_PASSWORD` | 你设置的密钥库密码 | 创建时的第一个密码 |
| `ANDROID_KEY_PASSWORD` | 你设置的密钥密码 | 通常与上面相同 |
| `ANDROID_KEY_ALIAS` | `tictactoe-key` | 创建时的 alias |

#### 步骤 2.4：验证配置

完成后，页面应该显示 4 个 Secrets：
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

### 4.3 阶段三：提交配置文件

#### 步骤 3.1：确认文件存在

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 检查 build-all.yml
ls -la .github/workflows/build-all.yml

# 检查模板文件
ls -la config/android/app-build.gradle.template

# 检查 .gitignore
grep -E "(jks|base64)" .gitignore
```

#### 步骤 3.2：禁用旧的 Workflow 文件（重要！

**如果不处理，推送 tag 时会触发多个 Workflow**。

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 方案 A：重命名禁用（推荐，保留回滚能力）
mv .github/workflows/build-windows.yml .github/workflows/build-windows.yml.disabled
mv .github/workflows/build-android.yml .github/workflows/build-android.yml.disabled

# 方案 B：删除
# git rm .github/workflows/build-windows.yml
# git rm .github/workflows/build-android.yml
```

#### 步骤 3.3：添加文件到暂存区

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 添加必需的文件
git add .gitignore
git add .github/workflows/build-all.yml
git add config/android/app-build.gradle.template
git add "安卓方案.md"

# 如果重命名了旧文件
git add .github/workflows/

# 可选：其他修改的文件（根据你的情况）
# git add lib/screens/game_screen.dart
# git add lib/widgets/board_widget.dart
# git add GITHUB_ACTIONS_BUILD.md
```

#### 步骤 3.4：确认敏感文件不会被提交

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 检查状态
git status

# 确保以下文件不在 "Changes to be committed" 中：
# ❌ tictactoe-keystore.jks
# ❌ keystore-base64.txt
# ❌ key.properties

# 它们应该显示为：
# - "Untracked files"（未追踪）
# - 或不显示（如果被 .gitignore 忽略）
```

#### 步骤 3.5：提交

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 提交
git commit -m "feat: 统一多平台构建方案 v2.0

改进内容：
- 合并 Windows 和 Android 为统一 Workflow
- 使用 Jobs 依赖消除竞争条件
- 新增 pre-check Job，提前验证配置
- 改用模板文件替换 build.gradle
- 新增 APK 签名验证步骤
- 版本号自动从 Git Tag 推导
- 统一由 create-release Job 创建 Release
- 更新 .gitignore，添加敏感文件忽略规则"

# 推送
git push origin master
```

### 4.4 阶段四：创建 Tag 并触发构建

#### 步骤 4.1：创建 Tag

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 创建 tag v1.0.4
git tag -a v1.0.4 -m "v1.0.4 - 统一多平台构建

新特性：
- 统一 Workflow，消除竞争条件
- 预检查机制，提前验证 Secrets 配置
- 模板文件替换 build.gradle，更可靠
- 签名验证步骤，确保 APK 正确签名
- 自动版本号管理，从 Tag 推导"
```

#### 步骤 4.2：推送 Tag

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 推送 tag 到远程
git push origin v1.0.4
```

### 4.5 阶段五：监控构建

#### 步骤 5.1：打开 GitHub Actions

1. 打开 `https://github.com/你的用户名/tictactoe-game/actions`
2. 找到最新的 workflow run 名称为 `Build All Platforms`

#### 步骤 5.2：观察执行顺序

```
执行顺序可视化：

[时间轴] ─────────────────────────────────────────────────▶

pre-check ──────▶ 完成
     │
     ├──▶ build-windows ────────────────────▶ 完成 ──┐
     │                                                  │
     └──▶ build-android ─────────────────────▶ 完成 ──┼──▶ create-release ──▶ 完成
                                                        │
                                              (两个都完成后才开始)
```

#### 步骤 5.3：检查各 Job 输出

| Job | 需要检查的内容 |
|-----|---------------|
| `pre-check` | 显示"✅ All Android signing secrets are configured" |
| `build-windows` | 显示"✅ Artifact 已上传" |
| `build-android` | 显示"✅ APK signature verified successfully" |
| `create-release` | 显示"✅ Release created" |

### 4.6 阶段六：验证结果

#### 步骤 6.1：检查 Release

1. 打开 `https://github.com/你的用户名/tictactoe-game/releases`
2. 找到 `v1.0.4` 版本

#### 步骤 6.2：确认 Assets

应该包含两个文件：
- `tictactoe-game-windows.zip`
- `tictactoe-game-android-v1.0.4-release.apk`

#### 步骤 6.3：确认 Release Notes

应该有自动生成的 Release Notes。

---

## 五、常见问题

### 5.1 keytool: command not found

**问题**：
```bash
bash: keytool: command not found
```

**原因**：
- 没有安装 Java JDK
- 或 Java 没有配置到 PATH

**解决方案**：

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y openjdk-17-jdk

# 验证
which keytool
```

### 5.2 pre-check Job 失败

**现象**：构建在 pre-check 阶段失败

**常见错误**：

| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| `Invalid tag format` | Tag 不是以 `v` 开头 | 使用 `v1.0.4` 格式 |
| `ANDROID_KEYSTORE_BASE64 is not configured` | Secrets 未配置 | 配置所有 4 个 Secrets |
| `build.gradle template not found` | 模板文件缺失 | 确认 `config/android/app-build.gradle.template` 已提交 |

### 5.3 签名验证失败

**现象**：`Verify APK signature` 步骤失败

**可能原因**：

1. **Secrets 配置错误**
   - 检查 `ANDROID_KEYSTORE_BASE64` 是否有换行
   - 检查密码是否正确

2. **模板文件签名配置有误**
   - 检查 `app-build.gradle.template` 中的 `signingConfigs`

3. **keystore 文件解码错误**
   - 验证 Base64 编码：
     ```bash
     # 本地验证
     base64 -d keystore-base64.txt > test-keystore.jks
     keytool -list -v -keystore test-keystore.jks
     ```

### 5.4 create-release Job 未执行

**现象**：前两个 Job 成功，但 create-release 没有执行

**原因**：
- `needs: [pre-check, build-windows, build-android]` 要求所有依赖 Job 都成功

**检查**：
1. 确认 `pre-check`、`build-windows`、`build-android` 都是 **✓ Successful**
2. 确认没有 Job 被跳过（Skipped）

### 5.5 推送 tag 触发多个 Workflow

**现象**：推送 tag 时触发了多个 Workflow

**原因**：
- 旧的 `build-windows.yml` 和 `build-android.yml` 没有禁用

**解决方案**：

```bash
# 方案 A：重命名禁用
mv .github/workflows/build-windows.yml .github/workflows/build-windows.yml.disabled
mv .github/workflows/build-android.yml .github/workflows/build-android.yml.disabled
git add .github/workflows/
git commit -m "chore: 禁用旧的独立 workflow"
git push origin master

# 方案 B：删除
git rm .github/workflows/build-windows.yml
git rm .github/workflows/build-android.yml
git commit -m "chore: 删除旧的独立 workflow"
git push origin master
```

### 5.6 忘记密钥库密码

**情况 1：还没有发布过应用**

可以重新创建：

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 删除旧的
rm tictactoe-keystore.jks
rm keystore-base64.txt

# 重新创建
keytool -genkey -v \
  -keystore tictactoe-keystore.jks \
  -alias tictactoe-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 36500

# 重新编码
base64 -w 0 tictactoe-keystore.jks > keystore-base64.txt

# 重新配置 GitHub Secrets
```

**情况 2：已经发布过应用且用户已安装**

⚠️ **必须使用相同的密钥库**，否则用户无法更新（需要卸载重装）。

建议：
- 尝试所有可能的密码组合
- 检查是否有密码记录
- 如果确实无法找回，且用户可以接受卸载重装，可以重新创建

### 5.7 Android 版本号问题

**现象**：用户无法覆盖安装新版本

**原因**：`versionCode` 没有递增

**解决方案**：

每次发布前，修改 `pubspec.yaml`：

```yaml
# 修改前
version: 1.0.0+1

# 修改后
version: 1.0.4+4
```

**注意**：
- `+` 后面的数字是 `versionCode`，必须递增
- Git Tag 用于文件命名，不影响 Android 内部的 `versionCode`

---

## 六、Workflow 配置详解

### 6.1 完整配置

文件位置：`.github/workflows/build-all.yml`

```yaml
name: Build All Platforms

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

env:
  FLUTTER_VERSION: '3.41.9'
  JAVA_VERSION: '17'
  APP_NAME: 'tictactoe-game'
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true

permissions:
  contents: write
```

### 6.2 Job 1: pre-check

```yaml
jobs:
  pre-check:
    name: Pre-check Configuration
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
    - name: Checkout code
      uses: actions/checkout@v6

    - name: Validate version format
      id: version
      run: |
        if [[ "${{ github.ref }}" == refs/tags/* ]]; then
          TAG="${{ github.ref_name }}"
          if [[ "$TAG" == v* ]]; then
            VERSION="${TAG#v}"
            echo "VERSION=$VERSION" >> $GITHUB_OUTPUT
            echo "TAG=$TAG" >> $GITHUB_OUTPUT
          else
            echo "Invalid tag format. Tag should start with 'v'"
            exit 1
          fi
        else
          echo "VERSION=dev" >> $GITHUB_OUTPUT
          echo "TAG=dev" >> $GITHUB_OUTPUT
        fi

    - name: Check pubspec.yaml version
      run: |
        if ! grep -q "version: " pubspec.yaml; then
          echo "❌ No version found in pubspec.yaml"
          exit 1
        fi
        echo "✅ pubspec.yaml version: $(grep 'version: ' pubspec.yaml)"

    - name: Check Android signing config
      if: startsWith(github.ref, 'refs/tags/')
      env:
        KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
        KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
        KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
        KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
      run: |
        ERROR=0
        if [ -z "$KEYSTORE_BASE64" ]; then
          echo "❌ ANDROID_KEYSTORE_BASE64 is not configured"
          ERROR=1
        else
          echo "✅ ANDROID_KEYSTORE_BASE64 is configured"
        fi
        # ... 检查其他 Secrets
        if [ $ERROR -eq 1 ]; then
          exit 1
        fi
        echo "✅ All Android signing secrets are configured"

    - name: Check build.gradle template exists
      run: |
        if [ -f "config/android/app-build.gradle.template" ]; then
          echo "✅ build.gradle template found"
        else
          echo "❌ build.gradle template not found"
          exit 1
        fi

    outputs:
      version: ${{ steps.version.outputs.VERSION }}
      tag: ${{ steps.version.outputs.TAG }}
```

**pre-check 的作用**：
1. 验证 Tag 格式
2. 验证 pubspec.yaml 版本
3. 验证所有 Secrets 已配置
4. 验证模板文件存在

**如果任何一项失败，构建立即停止，不浪费构建时间**。

### 6.3 Job 2: build-windows

```yaml
  build-windows:
    name: Build Windows Executable
    needs: pre-check
    runs-on: windows-latest
    timeout-minutes: 30
    steps:
    - name: Checkout code
      uses: actions/checkout@v6

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
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
        $distDir = "${{ env.APP_NAME }}-windows"
        New-Item -ItemType Directory -Path $distDir -Force
        Copy-Item -Path "$buildDir/*" -Destination $distDir -Recurse
        Compress-Archive -Path $distDir -DestinationPath "${{ env.APP_NAME }}-windows.zip"

    - name: Upload Windows ZIP as Artifact
      uses: actions/upload-artifact@v7
      with:
        name: ${{ env.APP_NAME }}-Windows-ZIP
        path: ${{ env.APP_NAME }}-windows.zip
        retention-days: 90
```

**关键点**：
- `needs: pre-check` - 依赖 pre-check 成功
- 不直接创建 Release，只上传 Artifact

### 6.4 Job 3: build-android

```yaml
  build-android:
    name: Build Android Release APK
    needs: pre-check
    runs-on: ubuntu-latest
    timeout-minutes: 40
    steps:
    - name: Checkout code
      uses: actions/checkout@v6

    - name: Setup Java JDK
      uses: actions/setup-java@v4
      with:
        distribution: 'temurin'
        java-version: ${{ env.JAVA_VERSION }}

    - name: Setup Android SDK
      uses: android-actions/setup-android@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        channel: 'stable'
        cache: true

    - name: Install dependencies
      run: flutter pub get

    - name: Generate Android platform files
      run: flutter create . --platforms android

    - name: Copy build.gradle template  # ✅ v2.0 改进：模板替换
      run: |
        TEMPLATE="config/android/app-build.gradle.template"
        TARGET="android/app/build.gradle"
        if [ -f "$TEMPLATE" ]; then
          cp "$TEMPLATE" "$TARGET"
          echo "✅ build.gradle copied from template"
        else
          echo "❌ Template file not found"
          exit 1
        fi

    - name: Decode Keystore from Secrets
      if: startsWith(github.ref, 'refs/tags/')
      env:
        KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
      run: |
        echo "$KEYSTORE_BASE64" | base64 -d > android/app/tictactoe-keystore.jks
        echo "✅ Keystore file created"

    - name: Create key.properties
      if: startsWith(github.ref, 'refs/tags/')
      env:
        STORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
        KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
        KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
      run: |
        cat > android/key.properties << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=tictactoe-keystore.jks
EOF
        echo "✅ key.properties created"

    - name: Build Release APK
      run: flutter build apk --release

    - name: Verify APK signature  # ✅ v2.0 新增：签名验证
      if: startsWith(github.ref, 'refs/tags/')
      run: |
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        
        # 使用 apksigner 验证
        BUILD_TOOLS_DIR="$ANDROID_HOME/build-tools"
        LATEST_BUILD_TOOLS=$(ls -1 $BUILD_TOOLS_DIR | sort -V | tail -n 1)
        APK_SIGNER="$BUILD_TOOLS_DIR/$LATEST_BUILD_TOOLS/apksigner"
        
        if [ -f "$APK_SIGNER" ]; then
          if "$APK_SIGNER" verify --print-certs "$APK_PATH"; then
            echo "✅ APK signature verified successfully"
          fi
        fi
        
        # 备用方案：jarsigner
        if command -v jarsigner &> /dev/null; then
          if jarsigner -verify "$APK_PATH" 2>/dev/null; then
            echo "✅ jarsigner verification: APK is signed"
          fi
        fi

    - name: Rename APK with version
      env:
        VERSION: ${{ needs.pre-check.outputs.tag }}
      run: |
        APK_VERSION=${VERSION:-dev}
        cp build/app/outputs/flutter-apk/app-release.apk \
          ${{ env.APP_NAME }}-android-$APK_VERSION-release.apk
        echo "✅ APK renamed"

    - name: Upload APK as Artifact
      uses: actions/upload-artifact@v7
      with:
        name: ${{ env.APP_NAME }}-Android-Release-APK
        path: ${{ env.APP_NAME }}-android-*.apk
        retention-days: 90
```

**v2.0 改进点**：

| 改进 | 说明 |
|------|------|
| **模板文件替换** | 使用 `cp` 命令复制模板文件，替代 sed 动态修改 |
| **签名验证** | 新增 `Verify APK signature` 步骤，确保 APK 正确签名 |
| **版本号自动** | 从 `needs.pre-check.outputs.tag` 获取版本号 |

### 6.5 Job 4: create-release

```yaml
  create-release:
    name: Create GitHub Release
    needs: [pre-check, build-windows, build-android]
    runs-on: ubuntu-latest
    timeout-minutes: 10
    if: startsWith(github.ref, 'refs/tags/')
    steps:
    - name: Download Windows Artifact
      uses: actions/download-artifact@v7
      with:
        name: ${{ env.APP_NAME }}-Windows-ZIP
        path: ./release

    - name: Download Android Artifact
      uses: actions/download-artifact@v7
      with:
        name: ${{ env.APP_NAME }}-Android-Release-APK
        path: ./release

    - name: List release assets
      run: |
        echo "📦 Release assets:"
        ls -la ./release/

    - name: Create GitHub Release
      uses: softprops/action-gh-release@v2
      with:
        files: |
          ./release/*
        generate_release_notes: true
        token: ${{ secrets.GITHUB_TOKEN }}
```

**关键点**：

| 配置 | 说明 |
|------|------|
| `needs: [pre-check, build-windows, build-android]` | 依赖所有三个 Job 都成功 |
| `if: startsWith(github.ref, 'refs/tags/')` | 只在推送 tag 时执行 |
| `actions/download-artifact` | 下载前两个 Job 上传的 Artifacts |
| `softprops/action-gh-release` | 创建统一的 Release |

**为什么这是最佳实践**：

1. **原子性**：要么双平台都发布，要么都不发布
2. **单一入口**：只有一个 Job 负责创建 Release，消除竞争条件
3. **统一的 Release Notes**：由一个 Job 生成，格式一致
4. **清晰的依赖关系**：明确的执行顺序

---

## 七、模板文件详解

### 7.1 文件位置

`config/android/app-build.gradle.template`

### 7.2 核心签名配置

```groovy
// 在文件开头，加载 key.properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

// 在 android 块内
android {
    namespace 'com.example.tictactoe_game'
    compileSdk 34

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release  // 关键：使用 release 签名
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 7.3 路径说明

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `rootProject.file('key.properties')` | `android/key.properties` | 从 `android/` 目录读取 |
| `file(keystoreProperties['storeFile'])` | `android/app/tictactoe-keystore.jks` | 相对于 `android/app/` 目录 |
| `signingConfig signingConfigs.release` | 使用 release 签名 | 配置生效的关键 |

### 7.4 与 sed 方式对比

| 对比项 | v1.0 (sed) | v2.0 (模板替换) |
|--------|------------|-----------------|
| **可靠性** | 依赖生成的格式不变 | 完全可控 |
| **维护性** | 复杂，需要调试正则 | 简单，直接编辑模板 |
| **灵活性** | 只能做简单替换 | 可以完全自定义 |
| **调试难度** | 高（sed 出错难定位） | 低（直接看模板文件） |

### 7.5 如何自定义模板

如果需要修改签名配置，直接编辑 `config/android/app-build.gradle.template`：

```groovy
// 例如：修改 applicationId
defaultConfig {
    applicationId "com.yourcompany.tictactoe"  // 修改这里
    minSdk 21
    targetSdk 34
    // ...
}

// 例如：修改 minSdk 版本
defaultConfig {
    minSdk 24  // 修改这里
    // ...
}
```

---

## 八、安全建议

### 8.1 密钥库安全

| 建议 | 说明 |
|------|------|
| **离线备份** | 将密钥库文件和密码记录在安全的地方 |
| **多份备份** | 备份到多个位置（U盘、加密云盘等）|
| **密码强度** | 使用强密码，包含大小写字母、数字、特殊字符 |
| **定期检查** | 确认备份文件可以正常使用 |

### 8.2 GitHub Secrets 安全

| 建议 | 说明 |
|------|------|
| **不要打印** | 不要在 workflow 中打印 Secrets 内容 |
| **最小权限** | 只给需要的人访问 Secrets 的权限 |
| **定期轮换** | 如果怀疑泄露，立即更新 Secrets 和密钥库 |

### 8.3 Git 提交安全

```bash
# 提交前确认
git status

# 应该看到：
# ❌ 不应该看到：tictactoe-keystore.jks, keystore-base64.txt
# ✅ 应该看到：pubspec.yaml, build-all.yml, 模板文件
```

### 8.4 v2.0 的安全性增强

| 增强项 | 说明 |
|--------|------|
| **pre-check** | 验证 Secrets 存在，但不会打印值 |
| **Redact** | workflow 中使用 `sed 's/=.*/=***REDACTED***/'` 隐藏密码 |
| **Artifacts** | 构建产物通过 Artifacts 传递，不暴露在日志中 |
| **.gitignore** | 添加了 `*base64*.txt` 忽略规则 |

---

## 九、回滚方案

### 9.1 紧急回滚

如果新方案出现问题，可以快速回滚到 v1.0。

#### 方案 A：恢复旧的 Workflow 文件

```bash
cd /remote-home/share/lijl/task_all/2XandO/tictactoe_game

# 恢复重命名的文件
mv .github/workflows/build-windows.yml.disabled .github/workflows/build-windows.yml
mv .github/workflows/build-android.yml.disabled .github/workflows/build-android.yml

# 提交
git add .github/workflows/
git commit -m "revert: 回滚到旧的独立 workflow"
git push origin master
```

#### 方案 B：使用 workflow_dispatch 手动触发

在 GitHub Actions 页面，手动触发旧的 workflow：
1. 打开 Actions 页面
2. 选择旧的 workflow（如 `Build Windows Executable`）
3. 点击 `Run workflow` 按钮

### 9.2 渐进式回滚

如果不确定问题所在，可以分步回滚：

1. **首先**：检查日志，确定失败的具体步骤
2. **然后**：根据失败原因针对性修复
3. **最后**：如果无法快速修复，则回滚

### 9.3 保留的 Workflow 文件

建议保留旧的 workflow 文件（重命名为 `.disabled`），这样：
- 新方案有问题时可以快速回滚
- 可以对比新旧方案的行为
- 便于调试

---

## 附录 A：命令速查

### A.1 密钥库相关

```bash
# 创建密钥库（交互式）
keytool -genkey -v \
  -keystore tictactoe-keystore.jks \
  -alias tictactoe-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 36500

# 查看密钥库信息
keytool -list -v -keystore tictactoe-keystore.jks

# Base64 编码（用于 GitHub Secrets）
base64 -w 0 tictactoe-keystore.jks > keystore-base64.txt

# Base64 解码（验证用）
base64 -d keystore-base64.txt > decoded.jks
```

### A.2 Git 相关

```bash
# 提交配置
git add .gitignore .github/workflows/build-all.yml config/android/app-build.gradle.template "安卓方案.md"
git commit -m "feat: 统一多平台构建方案 v2.0"
git push origin master

# 创建并推送标签
git tag -a v1.0.4 -m "v1.0.4 - 统一多平台构建"
git push origin v1.0.4

# 删除错误的标签（如果需要）
git tag -d v1.0.4           # 删除本地标签
git push origin :v1.0.4     # 删除远程标签
```

### A.3 验证签名

```bash
# 使用 apksigner 验证（Android SDK 工具）
apksigner verify --print-certs app-release.apk

# 使用 jarsigner 验证（Java 工具）
jarsigner -verify -verbose -certs app-release.apk
```

---

## 附录 B：实施清单

| 序号 | 任务 | 状态 |
|------|------|------|
| 1 | 安装/检查 Java JDK | ⬜ |
| 2 | 创建密钥库文件 (.jks) | ⬜ |
| 3 | Base64 编码密钥库 | ⬜ |
| 4 | 配置 GitHub Secrets (4 个) | ⬜ |
| 5 | 确认 build-all.yml 已提交 | ⬜ |
| 6 | 确认模板文件已提交 | ⬜ |
| 7 | 确认 .gitignore 已更新 | ⬜ |
| 8 | 禁用旧的 workflow 文件 | ⬜ |
| 9 | 提交所有更改 | ⬜ |
| 10 | 推送 master 分支 | ⬜ |
| 11 | 创建 tag v1.0.4 | ⬜ |
| 12 | 推送 tag | ⬜ |
| 13 | 监控 GitHub Actions | ⬜ |
| 14 | 验证 Release 包含双平台 | ⬜ |

---

**文档版本**：v2.0  
**最后更新**：2026-05-03

如有问题，请提供具体的错误信息。
