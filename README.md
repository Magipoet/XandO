# 2X&O - 动态井字棋

一款具有创新机制的井字棋游戏，每方最多同时存在 3 个棋子，超过后会自动移除最早放置的棋子。

## 游戏特色

| 特性 | 说明 |
|------|------|
| 🎮 创新玩法 | 动态棋子移除机制，传统井字棋的升级版 |
| 🎨 简洁界面 | 现代化 Material Design 3 风格 |
| ⚡ 流畅动画 | 棋子落子、获胜都有精美动画效果 |
| 🔄 无限对战 | 不会出现平局，游戏可以一直进行下去 |
| 📱 多平台 | 支持 Windows、Android、iOS、Web、Linux、macOS |

## 游戏规则

### 基础规则

1. **两名玩家**：X（×）先手，O（○）后手，轮流下棋
2. **3×3 棋盘**：经典井字棋棋盘布局
3. **获胜条件**：先将 3 个自己的棋子连成一线者获胜（横、竖、斜均可）

### 创新机制：动态棋子移除

这是本游戏与传统井字棋最大的区别：

| 阶段 | 规则 |
|------|------|
| **前 3 步** | 正常落子，棋盘上最多同时存在 6 个棋子（每方 3 个） |
| **第 4 步及以后** | 当玩家已有 3 个棋子时，再放新棋子会**自动移除该玩家最早放置的那个棋子** |

### 规则示例

假设玩家 X 的落子顺序：

```
第 1 步：X 放在 (0,0)  → 棋盘：[X, _, _]
                                 [_, _, _]
                                 [_, _, _]

第 2 步：X 放在 (0,1)  → 棋盘：[X, X, _]
                                 [_, _, _]
                                 [_, _, _]

第 3 步：X 放在 (0,2)  → 棋盘：[X, X, X]  ← 3 个 X 连成一线！
                                 [_, _, _]     如果此时还没赢，继续...
                                 [_, _, _]

第 4 步：X 放在 (1,0)  → 棋盘：[_, X, X]  ← 最早的 X (0,0) 被移除！
                                 [X, _, _]     新的 X 放在 (1,0)
                                 [_, _, _]
```

### 策略要点

1. **记不住顺序？没关系**：棋盘会自动管理棋子的生命周期
2. **防守的重要性**：因为棋子会被移除，防守往往比进攻更重要
3. **时机把握**：在合适的时机让自己的关键棋子连成一线
4. **心理战术**：利用"旧棋子会被移除"的规则进行布局

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.41.9+ | 跨平台 UI 框架 |
| Dart | 3.11.5+ | 编程语言 |
| Flutter Riverpod | 2.6.1+ | 状态管理 |
| Flutter Animate | 4.2.0+ | 动画效果 |

## 项目结构

```
tictactoe_game/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── models/                      # 数据模型
│   │   ├── board.dart               # 棋盘模型
│   │   ├── game_state.dart          # 游戏状态
│   │   ├── piece.dart               # 棋子模型
│   │   └── player.dart              # 玩家枚举
│   ├── providers/                   # 状态管理
│   │   └── game_provider.dart       # 游戏状态管理
│   ├── screens/                     # 页面
│   │   └── game_screen.dart         # 游戏主页面
│   ├── services/                    # 业务逻辑
│   │   ├── board_service.dart       # 棋盘服务
│   │   ├── game_service.dart        # 游戏服务
│   │   └── win_check_service.dart   # 获胜检测服务
│   ├── widgets/                     # UI 组件
│   │   ├── board_widget.dart        # 棋盘组件
│   │   ├── piece_widget.dart        # 棋子组件
│   │   ├── reset_button.dart        # 重置按钮
│   │   ├── status_bar.dart          # 状态栏
│   │   └── win_dialog.dart          # 获胜对话框
│   └── constants/                   # 常量
│       ├── app_colors.dart          # 颜色常量
│       ├── app_sizes.dart           # 尺寸常量
│       └── game_rules.dart          # 游戏规则常量
├── config/
│   └── android/
│       └── app-build.gradle.template # Android 签名配置模板
├── pubspec.yaml                     # 依赖配置
└── .github/workflows/
    └── build-all.yml                # GitHub Actions 自动构建
```

## 快速开始

### 环境要求

- Flutter SDK 3.41.9+
- Dart 3.11.5+
- 支持的平台：Windows 10+, Android 5.0+, iOS 12.0+, Web

### 运行游戏

```bash
# 克隆项目
git clone <repository-url>
cd tictactoe_game

# 安装依赖
flutter pub get

# 运行（选择你的设备）
flutter run
```

### 构建发布版本

#### Windows

```bash
flutter build windows --release
```

输出位置：`build/windows/x64/runner/Release/`

#### Android

```bash
flutter build apk --release
```

输出位置：`build/app/outputs/flutter-apk/app-release.apk`

### GitHub Actions 自动构建

项目已配置 GitHub Actions，推送 tag 即可自动构建双平台版本：

```bash
# 创建并推送 tag
git tag -a v1.0.0 -m "v1.0.0 发布"
git push origin v1.0.0
```

构建完成后，Release 页面会自动生成：
- Windows 可执行文件（ZIP）
- Android APK

## 游戏截图

```
┌─────────────────────────────────────────┐
│              轮到：×                     │
├─────────────────────────────────────────┤
│                                         │
│      ┌─────┬─────┬─────┐               │
│      │  ×  │  ○  │  ×  │               │
│      ├─────┼─────┼─────┤               │
│      │  ○  │  ×  │  ○  │               │
│      ├─────┼─────┼─────┤               │
│      │  ×  │     │     │               │
│      └─────┴─────┴─────┘               │
│                                         │
├─────────────────────────────────────────┤
│              [ 重新开始 ]                │
└─────────────────────────────────────────┘
```

## 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.0.0 | 2026-05-03 | 初始版本发布 |

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**享受游戏！** 🎮
