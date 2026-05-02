import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/models/game_state.dart';
import 'package:tictactoe_game/services/game_service.dart';

final gameServiceProvider = Provider<GameService>((ref) {
  return GameService();
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final gameService = ref.watch(gameServiceProvider);
  return GameNotifier(gameService);
});

class GameNotifier extends StateNotifier<GameState> {
  final GameService _gameService;

  GameNotifier(this._gameService) : super(GameState.initial());

  void makeMove(int row, int col) {
    state = _gameService.makeMove(state, row, col);
  }

  void resetGame() {
    state = _gameService.resetGame();
  }

  List<List<(int, int)>> getWinningLines() {
    return _gameService.getWinningLines(state);
  }
}
