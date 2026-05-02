import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/providers/game_provider.dart';

class ResetButton extends ConsumerWidget {
  const ResetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.resetButtonBottomMargin),
      child: ElevatedButton(
        onPressed: () => _handleReset(ref),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppSizes.buttonMinWidth,
            AppSizes.buttonHeight,
          ),
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
          ),
          elevation: 4.0,
        ),
        child: const Text(
          '重新开始',
          style: TextStyle(
            fontSize: AppSizes.buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleReset(WidgetRef ref) {
    ref.read(gameProvider.notifier).resetGame();
  }
}
