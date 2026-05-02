import 'package:tictactoe_game/models/game_state.dart';
import 'package:tictactoe_game/models/player.dart';
import 'package:tictactoe_game/services/board_service.dart';
import 'package:tictactoe_game/services/win_check_service.dart';

class GameService {
  final BoardService _boardService = BoardService();
  final WinCheckService _winCheckService = WinCheckService();

  GameState makeMove(GameState currentState, int row, int col) {
    if (currentState.isGameOver) return currentState;
    if (!currentState.board.isEmpty(row, col)) return currentState;

    final newBoard = currentState.board.copy();
    
    _boardService.placePiece(newBoard, currentState.currentPlayer, row, col);

    final winner = _winCheckService.checkWinner(newBoard);
    final isGameOver = winner != null;

    final nextPlayer = isGameOver
        ? currentState.currentPlayer
        : currentState.currentPlayer.next;

    return GameState(
      board: newBoard,
      currentPlayer: nextPlayer,
      winner: winner,
      isGameOver: isGameOver,
      moveCount: currentState.moveCount + 1,
    );
  }

  GameState resetGame() {
    return GameState.initial();
  }

  List<List<(int, int)>> getWinningLines(GameState state) {
    if (!state.isGameOver) return [];
    return _winCheckService.getWinningLines(state.board);
  }
}
