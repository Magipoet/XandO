import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/models/game_mode.dart';
import 'package:tictactoe_game/models/game_state.dart';
import 'package:tictactoe_game/models/player.dart';
import 'package:tictactoe_game/providers/game_provider.dart';
import 'package:tictactoe_game/widgets/board_widget.dart';
import 'package:tictactoe_game/widgets/help_dialog.dart';
import 'package:tictactoe_game/widgets/reset_button.dart';
import 'package:tictactoe_game/widgets/status_bar.dart';
import 'package:tictactoe_game/widgets/undo_button.dart';
import 'package:tictactoe_game/widgets/win_dialog.dart';
import 'package:tictactoe_game/widgets/fun_mode_abilities.dart';
import 'package:tictactoe_game/screens/settings_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    _listenForWin(gameState);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildLayout(gameState),
      ),
    );
  }

  Widget _buildLayout(GameState gameState) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;
    final isDesktop = screenWidth > 800 || isLandscape;

    if (gameState.isFunMode() && isDesktop) {
      return _buildDesktopLayout(gameState);
    } else {
      return _buildMobileLayout(gameState);
    }
  }

  Widget _buildDesktopLayout(GameState gameState) {
    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(gameState),
            const StatusBar(),
            const SizedBox(height: 8.0),
            const Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: PlayerAbilityPanel(
                      player: Player.x,
                      direction: Axis.horizontal,
                    ),
                  ),
                  Center(
                    child: BoardWidget(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: PlayerAbilityPanel(
                      player: Player.o,
                      direction: Axis.horizontal,
                    ),
                  ),
                ],
              ),
            ),
            _buildActionButtons(gameState),
          ],
        ),
        if (gameState.isFunMode())
          Positioned(
            top: AppSizes.titleTopMargin + 64.0 + AppSizes.statusBarTopMargin + 20.0,
            left: 0,
            right: 0,
            child: const Center(
              child: FreezeTargetHint(),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout(GameState gameState) {
    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(gameState),
            const StatusBar(),
            if (gameState.isFunMode()) ...[
              const SizedBox(height: 8.0),
              const PlayerAbilityPanel(
                player: Player.x,
                direction: Axis.vertical,
              ),
            ],
            const Spacer(),
            const Center(
              child: BoardWidget(),
            ),
            const Spacer(),
            if (gameState.isFunMode())
              const PlayerAbilityPanel(
                player: Player.o,
                direction: Axis.vertical,
              ),
            _buildActionButtons(gameState),
          ],
        ),
        if (gameState.isFunMode())
          Positioned(
            top: AppSizes.titleTopMargin + 64.0 + AppSizes.statusBarTopMargin + 20.0,
            left: 0,
            right: 0,
            child: const Center(
              child: FreezeTargetHint(),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.titleTopMargin,
        left: 16.0,
        right: 16.0,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 64.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '动态井字棋',
                  style: TextStyle(
                    fontSize: AppSizes.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  gameState.gameMode.displayName,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: gameState.isFunMode()
                        ? AppColors.buttonSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 8.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.sports_esports),
                    color: gameState.isFunMode()
                        ? AppColors.buttonSecondary
                        : AppColors.textPrimary,
                    onPressed: () => _showModeSelector(),
                    tooltip: '游戏模式',
                    iconSize: 24.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40.0,
                      minHeight: 40.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    color: AppColors.textPrimary,
                    onPressed: () => _showHelpDialog(),
                    tooltip: '游戏玩法',
                    iconSize: 24.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40.0,
                      minHeight: 40.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.textPrimary,
                    onPressed: () => _navigateToSettings(),
                    tooltip: '设置',
                    iconSize: 24.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40.0,
                      minHeight: 40.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(GameState gameState) {
    if (gameState.isFunMode()) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSizes.resetButtonBottomMargin),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ResetButton(),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(bottom: AppSizes.resetButtonBottomMargin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UndoButton(),
          SizedBox(width: AppSizes.actionButtonSpacing),
          ResetButton(),
        ],
      ),
    );
  }

  void _listenForWin(GameState gameState) {
    if (gameState.isGameOver && gameState.winner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WinDialog.show(context, gameState.winner!);
      });
    }
  }

  void _showModeSelector() {
    GameModeSelector.show(context);
  }

  void _showHelpDialog() {
    HelpDialog.show(context);
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
