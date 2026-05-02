import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/models/player.dart';
import 'package:tictactoe_game/providers/game_provider.dart';

class WinDialog extends ConsumerWidget {
  final Player winner;

  const WinDialog({
    super.key,
    required this.winner,
  });

  static void show(BuildContext context, Player winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WinDialog(winner: winner),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(AppSizes.winDialogPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.winDialogBorderRadius),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${winner.symbol} 方获胜！',
            style: TextStyle(
              fontSize: AppSizes.winDialogTitleFontSize,
              fontWeight: FontWeight.bold,
              color: _getWinnerColor(winner),
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () => _handlePlayAgain(context, ref),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                AppSizes.buttonMinWidth,
                AppSizes.buttonHeight,
              ),
              backgroundColor: _getWinnerColor(winner),
              foregroundColor: AppColors.buttonText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
              ),
            ),
            child: const Text(
              '再来一局',
              style: TextStyle(
                fontSize: AppSizes.buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getWinnerColor(Player player) {
    switch (player) {
      case Player.x:
        return AppColors.playerX;
      case Player.o:
        return AppColors.playerO;
    }
  }

  void _handlePlayAgain(BuildContext context, WidgetRef ref) {
    ref.read(gameProvider.notifier).resetGame();
    Navigator.of(context).pop();
  }
}
