import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/constants/app_colors.dart';
import 'package:tictactoe_game/constants/app_sizes.dart';
import 'package:tictactoe_game/constants/game_rules.dart';
import 'package:tictactoe_game/models/board_size.dart';
import 'package:tictactoe_game/models/piece_size.dart';
import 'package:tictactoe_game/providers/game_provider.dart';
import 'package:tictactoe_game/providers/settings_provider.dart';
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
    final settingsAsync = ref.watch(settingsProvider);

    final winningPositions = <(int, int)>{};
    for (final line in winningLines) {
      winningPositions.addAll(line);
    }

    final isWaitingForFreeze = gameState.isWaitingForFreezeTarget();

    return settingsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const Text('加载设置失败'),
      data: (settings) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = _calculateBoardSize(constraints, settings.boardSize.widthRatio);
            final cellSize = AppSizes.getCellSize(boardSize);
            final pieceFontSize = cellSize * settings.pieceSize.cellRatio;
            final orderNumberFontSize = pieceFontSize * 0.25;

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
                  final isFrozen = gameState.isCellFrozen(row, col);
                  final canSelect = isWaitingForFreeze && piece == null;

                  return MouseRegion(
                    onEnter: (_) {
                      if (isWaitingForFreeze) {
                        if (piece == null) {
                          setState(() {
                            _hoveringRow = row;
                            _hoveringCol = col;
                          });
                        }
                      } else if (!gameState.isGameOver && piece == null && !isFrozen) {
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
                    child: GestureDetector(
                      onTap: () => _handleCellTap(row, col, piece, isFrozen, isWaitingForFreeze),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: _getCellColor(isHovering, isFrozen, canSelect),
                          border: Border.all(
                            color: isFrozen
                                ? AppColors.buttonSecondary
                                : (canSelect && isHovering
                                    ? AppColors.buttonSecondary
                                    : AppColors.boardLines),
                            width: isFrozen || (canSelect && isHovering) ? 2.0 : AppSizes.cellBorderWidth,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Stack(
                          children: [
                            PieceWidget(
                              piece: piece,
                              currentPlayer: gameState.currentPlayer,
                              isHovering: isHovering && !isFrozen,
                              isWinning: isWinning,
                              pieceFontSize: pieceFontSize,
                              orderNumberFontSize: orderNumberFontSize,
                              onTap: () {},
                            ),
                            if (isFrozen)
                              const Positioned(
                                top: 4.0,
                                right: 4.0,
                                child: Icon(
                                  Icons.lock,
                                  size: 16.0,
                                  color: AppColors.buttonSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Color _getCellColor(bool isHovering, bool isFrozen, bool canSelect) {
    if (isFrozen) {
      return AppColors.buttonSecondary.withValues(alpha: 0.1);
    }
    if (canSelect && isHovering) {
      return AppColors.buttonSecondary.withValues(alpha: 0.15);
    }
    if (isHovering) {
      return AppColors.buttonPrimary.withValues(alpha: 0.1);
    }
    return Colors.transparent;
  }

  double _calculateBoardSize(BoxConstraints constraints, double widthRatio) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final maxWidth = screenWidth * widthRatio;
    final clampedWidth = maxWidth.clamp(
      AppSizes.boardMinWidth,
      AppSizes.boardMaxWidth,
    );

    final availableHeight = screenHeight -
        AppSizes.titleTopMargin -
        AppSizes.statusBarTopMargin -
        AppSizes.resetButtonBottomMargin -
        kToolbarHeight;

    return clampedWidth.clamp(0, availableHeight);
  }

  void _handleCellTap(int row, int col, Piece? piece, bool isFrozen, bool isWaitingForFreeze) {
    final gameState = ref.read(gameProvider);
    if (gameState.isGameOver) return;

    if (isWaitingForFreeze) {
      if (piece != null) return;
      ref.read(gameProvider.notifier).makeMove(row, col);
      return;
    }

    if (piece != null) return;
    if (isFrozen) return;

    ref.read(gameProvider.notifier).makeMove(row, col);
  }
}
