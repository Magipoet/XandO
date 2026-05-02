import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/providers/game_provider.dart';
import 'package:tictactoe_game/widgets/board_widget.dart';
import 'package:tictactoe_game/widgets/reset_button.dart';
import 'package:tictactoe_game/widgets/status_bar.dart';
import 'package:tictactoe_game/widgets/win_dialog.dart';

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
            const StatusBar(),
            const Spacer(),
            const Center(
              child: BoardWidget(),
            ),
            const Spacer(),
            const ResetButton(),
          ],
        ),
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
}
