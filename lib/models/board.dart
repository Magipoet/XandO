import 'package:tictactoe_game/constants/game_rules.dart';
import 'package:tictactoe_game/models/piece.dart';
import 'package:tictactoe_game/models/player.dart';

class Board {
  final List<List<Piece?>> cells;
  final Map<Player, List<Piece>> playerPieces;

  Board()
      : cells = List.generate(
          GameRules.boardSize,
          (_) => List.generate(GameRules.boardSize, (_) => null),
        ),
        playerPieces = {
          Player.x: <Piece>[],
          Player.o: <Piece>[],
        };

  Board._internal({
    required this.cells,
    required this.playerPieces,
  });

  bool isEmpty(int row, int col) {
    _validatePosition(row, col);
    return cells[row][col] == null;
  }

  int getPieceCount(Player player) {
    return playerPieces[player]?.length ?? 0;
  }

  Piece? getPiece(int row, int col) {
    _validatePosition(row, col);
    return cells[row][col];
  }

  List<Piece> getPlayerPieces(Player player) {
    return List.unmodifiable(playerPieces[player] ?? []);
  }

  Board copy() {
    final newCells = List.generate(
      GameRules.boardSize,
      (row) => List.generate(
        GameRules.boardSize,
        (col) {
          final piece = cells[row][col];
          return piece?.copyWith();
        },
      ),
    );

    final newPlayerPieces = <Player, List<Piece>>{};
    for (final player in Player.values) {
      newPlayerPieces[player] = playerPieces[player]!
          .map((piece) => piece.copyWith())
          .toList();
    }

    return Board._internal(
      cells: newCells,
      playerPieces: newPlayerPieces,
    );
  }

  void _validatePosition(int row, int col) {
    if (row < 0 || row >= GameRules.boardSize) {
      throw ArgumentError('Row must be between 0 and ${GameRules.boardSize - 1}');
    }
    if (col < 0 || col >= GameRules.boardSize) {
      throw ArgumentError('Column must be between 0 and ${GameRules.boardSize - 1}');
    }
  }
}
