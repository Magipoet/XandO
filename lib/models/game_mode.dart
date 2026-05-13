enum GameMode {
  normal,
  fun,
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.normal:
        return '常规模式';
      case GameMode.fun:
        return '趣味模式';
    }
  }

  String get description {
    switch (this) {
      case GameMode.normal:
        return '双方轮流落子，无特殊功能';
      case GameMode.fun:
        return '可使用撤回键和固定键等特殊功能';
    }
  }
}
