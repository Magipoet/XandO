import 'package:tictactoe_game/constants/game_rules.dart';
import 'package:tictactoe_game/models/board.dart';
import 'package:tictactoe_game/models/player.dart';

class WinCheckService {
  Player? checkWinner(Board board) {
    for (int row = 0; row < GameRules.boardSize; row++) {
      if (_isLineComplete(board, row, 0, row, 1, row, 2)) {
        return board.cells[row][0]!.owner;
      }
    }

    for (int col = 0; col < GameRules.boardSize; col++) {
      if (_isLineComplete(board, 0, col, 1, col, 2, col)) {
        return board.cells[0][col]!.owner;
      }
    }

    if (_isLineComplete(board, 0, 0, 1, 1, 2, 2)) {
      return board.cells[0][0]!.owner;
    }
    if (_isLineComplete(board, 0, 2, 1, 1, 2, 0)) {
      return board.cells[0][2]!.owner;
    }

    return null;
  }

  bool checkPlayerWin(Board board, Player player) {
    final winner = checkWinner(board);
    return winner == player;
  }

  List<List<(int, int)>> getWinningLines(Board board) {
    final winningLines = <List<(int, int)>>[];

    for (int row = 0; row < GameRules.boardSize; row++) {
      if (_isLineComplete(board, row, 0, row, 1, row, 2)) {
        winningLines.add([(row, 0), (row, 1), (row, 2)]);
      }
    }

    for (int col = 0; col < GameRules.boardSize; col++) {
      if (_isLineComplete(board, 0, col, 1, col, 2, col)) {
        winningLines.add([(0, col), (1, col), (2, col)]);
      }
    }

    if (_isLineComplete(board, 0, 0, 1, 1, 2, 2)) {
      winningLines.add([(0, 0), (1, 1), (2, 2)]);
    }
    if (_isLineComplete(board, 0, 2, 1, 1, 2, 0)) {
      winningLines.add([(0, 2), (1, 1), (2, 0)]);
    }

    return winningLines;
  }

  bool _isLineComplete(
    Board board,
    int r1, int c1,
    int r2, int c2,
    int r3, int c3,
  ) {
    final p1 = board.cells[r1][c1];
    final p2 = board.cells[r2][c2];
    final p3 = board.cells[r3][c3];

    if (p1 == null || p2 == null || p3 == null) return false;
    return p1.owner == p2.owner && p2.owner == p3.owner;
  }
}
