import 'package:tictactoe_game/models/board.dart';
import 'package:tictactoe_game/models/player.dart';

class GameState {
  final Board board;
  final Player currentPlayer;
  final Player? winner;
  final bool isGameOver;
  final int moveCount;

  GameState({
    required this.board,
    required this.currentPlayer,
    this.winner,
    this.isGameOver = false,
    this.moveCount = 0,
  });

  GameState copyWith({
    Board? board,
    Player? currentPlayer,
    Player? winner,
    bool? isGameOver,
    int? moveCount,
  }) {
    return GameState(
      board: board ?? this.board.copy(),
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      isGameOver: isGameOver ?? this.isGameOver,
      moveCount: moveCount ?? this.moveCount,
    );
  }

  static GameState initial() {
    return GameState(
      board: Board(),
      currentPlayer: Player.x,
      winner: null,
      isGameOver: false,
      moveCount: 0,
    );
  }
}
