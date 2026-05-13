import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/models/ability.dart';
import 'package:tictactoe_game/models/game_mode.dart';
import 'package:tictactoe_game/providers/game_provider.dart';

class FunModeAbilityBar extends ConsumerWidget {
  const FunModeAbilityBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);
    final gameState = ref.read(gameProvider);

    if (!gameState.isFunMode()) {
      return const SizedBox.shrink();
    }

    final canUndo = gameNotifier.canUseAbility(AbilityType.undo);
    final canFreeze = gameNotifier.canUseAbility(AbilityType.freeze);
    final isWaiting = gameNotifier.isWaitingForFreezeTarget;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWaiting) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.buttonSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.buttonSecondary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '请选择要固定的空格子',
                    style: TextStyle(
                      fontSize: AppSizes.buttonFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  TextButton(
                    onPressed: () => gameNotifier.cancelFreezeSelection(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AbilityButton(
                ability: AbilityType.undo,
                enabled: canUndo && !isWaiting,
                onPressed: () => gameNotifier.useFunUndo(),
              ),
              const SizedBox(width: AppSizes.actionButtonSpacing),
              _AbilityButton(
                ability: AbilityType.freeze,
                enabled: canFreeze && !isWaiting,
                onPressed: () => gameNotifier.startFreezeSelection(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbilityButton extends StatelessWidget {
  final AbilityType ability;
  final bool enabled;
  final VoidCallback onPressed;

  const _AbilityButton({
    required this.ability,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _getButtonColor();

    return Tooltip(
      message: ability.tooltip,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? bgColor : AppColors.textSecondary.withValues(alpha: 0.3),
          foregroundColor: AppColors.buttonText,
          minimumSize: const Size(100, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
          ),
        ),
        icon: Text(
          ability.icon,
          style: const TextStyle(fontSize: 18.0),
        ),
        label: Text(
          ability.displayName,
          style: const TextStyle(
            fontSize: AppSizes.buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (ability) {
      case AbilityType.undo:
        return AppColors.buttonPrimary;
      case AbilityType.freeze:
        return AppColors.buttonSecondary;
    }
  }
}

class GameModeSelector extends ConsumerWidget {
  const GameModeSelector({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => const GameModeSelector(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '选择游戏模式',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          _ModeTile(
            mode: GameMode.normal,
            isSelected: gameState.gameMode == GameMode.normal,
            onTap: () {
              ref.read(gameProvider.notifier).switchGameMode(GameMode.normal);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 12.0),
          _ModeTile(
            mode: GameMode.fun,
            isSelected: gameState.gameMode == GameMode.fun,
            onTap: () {
              ref.read(gameProvider.notifier).switchGameMode(GameMode.fun);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final GameMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isSelected
                ? (mode == GameMode.fun ? AppColors.buttonSecondary : AppColors.buttonPrimary)
                    .withValues(alpha: 0.15)
                : AppColors.boardBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? (mode == GameMode.fun ? AppColors.buttonSecondary : AppColors.buttonPrimary)
                  : AppColors.boardLines.withValues(alpha: 0.3),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: mode == GameMode.fun
                      ? AppColors.buttonSecondary.withValues(alpha: 0.2)
                      : AppColors.buttonPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  mode == GameMode.fun ? Icons.sports_esports : Icons.grid_view,
                  color: mode == GameMode.fun
                      ? AppColors.buttonSecondary
                      : AppColors.buttonPrimary,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      mode.description,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: mode == GameMode.fun ? AppColors.buttonSecondary : AppColors.buttonPrimary,
                  size: 24.0,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
