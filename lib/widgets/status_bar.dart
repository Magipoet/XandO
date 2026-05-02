import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/models/player.dart';
import 'package:tictactoe_game/providers/game_provider.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.statusBarTopMargin),
      child: Text(
        '轮到 ${gameState.currentPlayer.symbol} 方',
        style: TextStyle(
          fontSize: AppSizes.statusBarFontSize,
          fontWeight: FontWeight.bold,
          color: _getPlayerColor(gameState.currentPlayer),
        ),
      ),
    );
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
