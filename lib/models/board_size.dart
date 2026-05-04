enum BoardSize {
  standard,
  large,
}

extension BoardSizeExtension on BoardSize {
  String get label {
    switch (this) {
      case BoardSize.standard:
        return '标准款';
      case BoardSize.large:
        return '大款';
    }
  }

  double get widthRatio {
    switch (this) {
      case BoardSize.standard:
        return 0.8;
      case BoardSize.large:
        return 0.96;
    }
  }
}
