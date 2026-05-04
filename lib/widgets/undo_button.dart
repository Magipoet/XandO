import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/providers/game_provider.dart';

class UndoButton extends ConsumerWidget {
  const UndoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameNotifier = ref.watch(gameProvider.notifier);
    final canUndo = gameNotifier.canUndo;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.resetButtonBottomMargin),
      child: ElevatedButton(
        onPressed: canUndo ? () => _handleUndo(ref) : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppSizes.buttonMinWidth,
            AppSizes.buttonHeight,
          ),
          backgroundColor: canUndo ? AppColors.buttonSecondary : Colors.grey,
          foregroundColor: AppColors.buttonText,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
          ),
          elevation: 4.0,
        ),
        child: const Text(
          '撤销',
          style: TextStyle(
            fontSize: AppSizes.buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleUndo(WidgetRef ref) {
    ref.read(gameProvider.notifier).undo();
  }
}
