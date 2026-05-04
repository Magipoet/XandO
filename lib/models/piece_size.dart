enum PieceSize {
  small,
  standard,
  large,
}

extension PieceSizeExtension on PieceSize {
  String get label {
    switch (this) {
      case PieceSize.small:
        return '小款';
      case PieceSize.standard:
        return '标准款';
      case PieceSize.large:
        return '大款';
    }
  }

  double get cellRatio {
    switch (this) {
      case PieceSize.small:
        return 1.0 / 3.0;
      case PieceSize.standard:
        return 0.5;
      case PieceSize.large:
        return 2.0 / 3.0;
    }
  }
}
