enum AbilityType {
  undo,
  freeze,
}

extension AbilityTypeExtension on AbilityType {
  String get displayName {
    switch (this) {
      case AbilityType.undo:
        return '撤回';
      case AbilityType.freeze:
        return '固定';
    }
  }

  String get tooltip {
    switch (this) {
      case AbilityType.undo:
        return '撤回自己的上一步';
      case AbilityType.freeze:
        return '指定一个格子，对方下一步无法落子此处';
    }
  }

  String get icon {
    switch (this) {
      case AbilityType.undo:
        return '↩';
      case AbilityType.freeze:
        return '🔒';
    }
  }

  String getDisplayNameWithCount(int count) {
    return '$displayName:$count';
  }
}
