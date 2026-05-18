import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/models/ability.dart';
import 'package:tictactoe_game/models/game_mode.dart';
import 'package:tictactoe_game/models/game_state.dart';
import 'package:tictactoe_game/models/player.dart';
import 'package:tictactoe_game/providers/game_provider.dart';

class PlayerAbilityPanel extends ConsumerWidget {
  final Player player;
  final Axis direction;

  const PlayerAbilityPanel({
    super.key,
    required this.player,
    required this.direction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    if (!gameState.isFunMode() || gameState.funModeState == null) {
      return _EmptyAbilityPanel(direction: direction);
    }

    final funState = gameState.funModeState!;
    final abilities = funState.getAbilities(player);
    final isCurrentPlayer = gameState.currentPlayer == player;
    final lastPlayer = gameNotifier.lastPlayer;
    final isLastPlayer = lastPlayer == player;
    final isWaiting = funState.waitingForFreezeTarget;

    final canUndo = isLastPlayer && abilities.canUse(AbilityType.undo) && !isWaiting;
    final canFreeze = isLastPlayer && abilities.canUse(AbilityType.freeze);
    final isFreezeWaiting = isWaiting && gameNotifier.freezeInitiator == player;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.boardBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isCurrentPlayer
              ? (player == Player.x ? AppColors.playerX : AppColors.playerO)
              : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: direction == Axis.horizontal
          ? _buildHorizontalLayout(player, abilities, canUndo, canFreeze, isFreezeWaiting, gameNotifier)
          : _buildVerticalLayout(player, abilities, canUndo, canFreeze, isFreezeWaiting, gameNotifier),
    );
  }

  Widget _buildHorizontalLayout(
    Player player,
    PlayerAbilities abilities,
    bool canUndo,
    bool canFreeze,
    bool isFreezeWaiting,
    GameNotifier gameNotifier,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayerTitle(player: player),
        const SizedBox(height: 12.0),
        _AbilityButton(
          ability: AbilityType.undo,
          count: abilities.getUses(AbilityType.undo),
          enabled: canUndo,
          onPressed: () => gameNotifier.useFunUndo(),
          vertical: true,
        ),
        const SizedBox(height: 12.0),
        _AbilityButton(
          ability: AbilityType.freeze,
          count: abilities.getUses(AbilityType.freeze),
          enabled: canFreeze,
          isActive: isFreezeWaiting,
          onPressed: () {
            if (isFreezeWaiting) {
              gameNotifier.cancelFreezeSelection();
            } else {
              gameNotifier.startFreezeSelection();
            }
          },
          vertical: true,
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(
    Player player,
    PlayerAbilities abilities,
    bool canUndo,
    bool canFreeze,
    bool isFreezeWaiting,
    GameNotifier gameNotifier,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayerTitle(player: player),
        const SizedBox(width: 12.0),
        _AbilityButton(
          ability: AbilityType.undo,
          count: abilities.getUses(AbilityType.undo),
          enabled: canUndo,
          onPressed: () => gameNotifier.useFunUndo(),
          vertical: false,
        ),
        const SizedBox(width: AppSizes.actionButtonSpacing),
        _AbilityButton(
          ability: AbilityType.freeze,
          count: abilities.getUses(AbilityType.freeze),
          enabled: canFreeze,
          isActive: isFreezeWaiting,
          onPressed: () {
            if (isFreezeWaiting) {
              gameNotifier.cancelFreezeSelection();
            } else {
              gameNotifier.startFreezeSelection();
            }
          },
          vertical: false,
        ),
      ],
    );
  }
}

class _PlayerTitle extends StatelessWidget {
  final Player player;

  const _PlayerTitle({required this.player});

  @override
  Widget build(BuildContext context) {
    return Text(
      player.symbol,
      style: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: player == Player.x ? AppColors.playerX : AppColors.playerO,
      ),
    );
  }
}

class _AbilityButton extends StatelessWidget {
  final AbilityType ability;
  final int count;
  final bool enabled;
  final bool isActive;
  final VoidCallback onPressed;
  final bool vertical;

  const _AbilityButton({
    required this.ability,
    required this.count,
    required this.enabled,
    this.isActive = false,
    required this.onPressed,
    required this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = _getButtonColor();

    return Tooltip(
      message: ability.tooltip,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? bgColor.withValues(alpha: 0.7)
              : (enabled ? bgColor : AppColors.textSecondary.withValues(alpha: 0.3)),
          foregroundColor: AppColors.buttonText,
          minimumSize: vertical
              ? const Size(68, 48)
              : const Size(88, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonBorderRadius),
            side: isActive
                ? BorderSide(color: bgColor, width: 2.0)
                : BorderSide.none,
          ),
        ),
        icon: Text(
          ability.icon,
          style: const TextStyle(fontSize: 16.0),
        ),
        label: Text(
          ability.getDisplayNameWithCount(count),
          style: TextStyle(
            fontSize: vertical ? 11.0 : AppSizes.buttonFontSize,
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

class FreezeTargetHint extends ConsumerWidget {
  const FreezeTargetHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    if (!gameState.isFunMode() || !gameState.isWaitingForFreezeTarget()) {
      return const SizedBox.shrink();
    }

    return Container(
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
    );
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

class _EmptyAbilityPanel extends StatelessWidget {
  final Axis direction;

  _EmptyAbilityPanel({required this.direction});

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return const SizedBox(width: 92.0, height: 156.0);
    } else {
      return const SizedBox(height: 72.0);
    }
  }
}
