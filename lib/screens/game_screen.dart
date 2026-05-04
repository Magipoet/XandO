import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/providers/game_provider.dart';
import 'package:tictactoe_game/widgets/board_widget.dart';
import 'package:tictactoe_game/widgets/help_dialog.dart';
import 'package:tictactoe_game/widgets/reset_button.dart';
import 'package:tictactoe_game/widgets/status_bar.dart';
import 'package:tictactoe_game/widgets/undo_button.dart';
import 'package:tictactoe_game/widgets/win_dialog.dart';
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
        child: Column(
          children: [
            _buildTopBar(),
            const StatusBar(),
            const Spacer(),
            const Center(
              child: BoardWidget(),
            ),
            const Spacer(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.titleTopMargin,
        left: 16.0,
        right: 16.0,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: Center(
              child: Text(
                '动态井字棋',
                style: TextStyle(
                  fontSize: AppSizes.titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  color: AppColors.textPrimary,
                  onPressed: () => _showHelpDialog(),
                  tooltip: '游戏玩法',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  color: AppColors.textPrimary,
                  onPressed: () => _navigateToSettings(),
                  tooltip: '设置',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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

  void _listenForWin(gameState) {
    if (gameState.isGameOver && gameState.winner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WinDialog.show(context, gameState.winner!);
      });
    }
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
