class AppSizes {
  // 棋盘相关
  static const double boardMinWidth = 240.0;
  static const double boardMaxWidth = 600.0;
  static const double boardMobileWidthRatio = 0.8;
  static const double boardPadding = 8.0;
  static const double cellSpacing = 4.0;
  static const double cellBorderWidth = 1.0;

  // 棋子相关
  static const double pieceFontSize = 48.0;
  static const double orderNumberFontSize = 12.0;

  // 文字相关
  static const double statusBarFontSize = 18.0;
  static const double buttonFontSize = 16.0;
  static const double winDialogTitleFontSize = 24.0;

  // 按钮相关
  static const double buttonMinWidth = 120.0;
  static const double buttonHeight = 48.0;
  static const double buttonBorderRadius = 8.0;

  // 间距相关
  static const double statusBarTopMargin = 24.0;
  static const double resetButtonBottomMargin = 24.0;
  static const double winDialogPadding = 24.0;
  static const double winDialogBorderRadius = 16.0;

  // 动画相关
  static const int piecePlaceAnimationDuration = 200;
  static const int pieceRemoveAnimationDuration = 200;
  static const int orderUpdateAnimationDuration = 150;

  // 获取格子尺寸
  static double getCellSize(double boardSize) {
    final availableSize = boardSize - (boardPadding * 2) - (cellSpacing * 2);
    return availableSize / 3;
  }
}
