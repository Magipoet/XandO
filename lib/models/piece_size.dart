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
        return 0.2;
      case PieceSize.standard:
        return 1.0 / 3.0;
      case PieceSize.large:
        return 0.5;
    }
  }
}
