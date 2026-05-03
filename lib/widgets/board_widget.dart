import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/constants/game_rules.dart';
import 'package:tictactoe_game/providers/game_provider.dart';
import 'package:tictactoe_game/widgets/piece_widget.dart';

class BoardWidget extends ConsumerStatefulWidget {
  const BoardWidget({super.key});

  @override
  ConsumerState<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends ConsumerState<BoardWidget> {
  int? _hoveringRow;
  int? _hoveringCol;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final winningLines = ref.watch(gameProvider.notifier).getWinningLines();

    final winningPositions = <(int, int)>{};
    for (final line in winningLines) {
      winningPositions.addAll(line);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = _calculateBoardSize(constraints);
        final cellSize = AppSizes.getCellSize(boardSize);

        return Container(
          width: boardSize,
          height: boardSize,
          padding: const EdgeInsets.all(AppSizes.boardPadding),
          decoration: BoxDecoration(
            color: AppColors.boardBackground,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: GameRules.boardSize,
              mainAxisSpacing: AppSizes.cellSpacing,
              crossAxisSpacing: AppSizes.cellSpacing,
            ),
            itemCount: GameRules.boardSize * GameRules.boardSize,
            itemBuilder: (context, index) {
              final row = index ~/ GameRules.boardSize;
              final col = index % GameRules.boardSize;

              final piece = gameState.board.getPiece(row, col);
              final isWinning = winningPositions.contains((row, col));
              final isHovering = _hoveringRow == row && _hoveringCol == col;

              return MouseRegion(
                onEnter: (_) {
                  if (!gameState.isGameOver && piece == null) {
                    setState(() {
                      _hoveringRow = row;
                      _hoveringCol = col;
                    });
                  }
                },
                onExit: (_) {
                  setState(() {
                    _hoveringRow = null;
                    _hoveringCol = null;
                  });
                },
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.boardLines,
                      width: AppSizes.cellBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: PieceWidget(
                    piece: piece,
                    currentPlayer: gameState.currentPlayer,
                    isHovering: isHovering,
                    isWinning: isWinning,
                    onTap: () => _handleCellTap(row, col),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  double _calculateBoardSize(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final maxWidth = screenWidth * AppSizes.boardMobileWidthRatio;
    final clampedWidth = maxWidth.clamp(
      AppSizes.boardMinWidth,
      AppSizes.boardMaxWidth,
    );

    final availableHeight = screenHeight -
        AppSizes.statusBarTopMargin -
        AppSizes.resetButtonBottomMargin -
        kToolbarHeight;

    return clampedWidth.clamp(0, availableHeight);
  }

  void _handleCellTap(int row, int col) {
    final gameState = ref.read(gameProvider);
    if (gameState.isGameOver) return;
    if (!gameState.board.isEmpty(row, col)) return;

    ref.read(gameProvider.notifier).makeMove(row, col);
  }
}
