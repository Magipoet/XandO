import 'package:tictactoe_game/constants/game_rules.dart';
import 'package:tictactoe_game/models/board.dart';
import 'package:tictactoe_game/models/piece.dart';
import 'package:tictactoe_game/models/player.dart';

class BoardService {
  Piece? placePiece(Board board, Player player, int row, int col) {
    if (!board.isEmpty(row, col)) return null;

    if (board.getPieceCount(player) >= GameRules.maxPiecesPerPlayer) {
      final oldestPiece = board.playerPieces[player]!.first;
      _removePiece(board, oldestPiece);
      _updateRelativeOrders(board, player);
    }

    final pieceId = '${player.name}_${DateTime.now().millisecondsSinceEpoch}';
    final relativeOrder = board.getPieceCount(player) + 1;

    final newPiece = Piece(
      id: pieceId,
      owner: player,
      relativeOrder: relativeOrder,
      row: row,
      col: col,
      placedAt: DateTime.now(),
    );

    _addPiece(board, newPiece);

    return newPiece;
  }

  void _addPiece(Board board, Piece piece) {
    board.cells[piece.row][piece.col] = piece;
    board.playerPieces[piece.owner]!.add(piece);
  }

  void _removePiece(Board board, Piece piece) {
    board.cells[piece.row][piece.col] = null;
    board.playerPieces[piece.owner]!.removeWhere((p) => p.id == piece.id);
  }

  void _updateRelativeOrders(Board board, Player player) {
    final pieces = board.playerPieces[player]!;
    for (int i = 0; i < pieces.length; i++) {
      pieces[i] = pieces[i].copyWith(relativeOrder: i + 1);
      
      final cellPiece = board.cells[pieces[i].row][pieces[i].col];
      if (cellPiece != null && cellPiece.id == pieces[i].id) {
        board.cells[pieces[i].row][pieces[i].col] = pieces[i];
      }
    }
  }

  void resetBoard(Board board) {
    for (int row = 0; row < GameRules.boardSize; row++) {
      for (int col = 0; col < GameRules.boardSize; col++) {
        board.cells[row][col] = null;
      }
    }
    board.playerPieces[Player.x]!.clear();
    board.playerPieces[Player.o]!.clear();
  }
}
