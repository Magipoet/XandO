import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/models/piece.dart';
import 'package:tictactoe_game/models/player.dart';

class PieceWidget extends StatelessWidget {
  final Piece? piece;
  final Player? currentPlayer;
  final bool isHovering;
  final bool isWinning;
  final double pieceFontSize;
  final double orderNumberFontSize;
  final VoidCallback? onTap;

  const PieceWidget({
    super.key,
    this.piece,
    this.currentPlayer,
    this.isHovering = false,
    this.isWinning = false,
    required this.pieceFontSize,
    required this.orderNumberFontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: _getCursor(),
        child: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: _getBorder(),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (piece != null) _buildPieceContent()
              else if (isHovering && currentPlayer != null) _buildHoverPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieceContent() {
    final opacity = _getOpacity();
    final color = _getPieceColor();

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          piece!.owner.symbol,
          style: TextStyle(
            fontSize: pieceFontSize,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: opacity),
          ),
        )
            .animate(
              key: ValueKey(piece!.id),
              onPlay: (controller) => controller.forward(),
            )
            .scale(
              duration: AppSizes.piecePlaceAnimationDuration.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.3, 0.3),
              end: const Offset(1.0, 1.0),
            ),
        Positioned(
          right: 4,
          bottom: 4,
          child: Text(
            piece!.relativeOrder.toString(),
            style: TextStyle(
              fontSize: orderNumberFontSize,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: AppColors.opacityOrderNumber),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoverPreview() {
    return Text(
      currentPlayer!.symbol,
      style: TextStyle(
        fontSize: pieceFontSize,
        fontWeight: FontWeight.bold,
        color: _getPlayerColor(currentPlayer!)
            .withValues(alpha: AppColors.opacityHoverPreview),
      ),
    );
  }

  MouseCursor _getCursor() {
    if (piece != null) {
      return SystemMouseCursors.forbidden;
    }
    return SystemMouseCursors.click;
  }

  Color? _getBackgroundColor() {
    if (isWinning) {
      return AppColors.winHighlight.withValues(alpha: 0.2);
    }
    return null;
  }

  Border? _getBorder() {
    if (isWinning) {
      return Border.all(
        color: AppColors.winHighlight,
        width: 2.0,
      );
    }
    return null;
  }

  double _getOpacity() {
    if (piece == null) return 1.0;
    switch (piece!.relativeOrder) {
      case 1:
        return AppColors.opacityNewest;
      case 2:
        return AppColors.opacityMiddle;
      case 3:
        return AppColors.opacityOldest;
      default:
        return AppColors.opacityNewest;
    }
  }

  Color _getPieceColor() {
    if (piece == null) return AppColors.textPrimary;
    return _getPlayerColor(piece!.owner);
  }

  Color _getPlayerColor(Player player) {
    switch (player) {
      case Player.x:
        return AppColors.playerX;
      case Player.o:
        return AppColors.playerO;
    }
  }
}
