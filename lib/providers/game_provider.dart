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
  final List<GameState> _history = [];

  GameNotifier(this._gameService) : super(GameState.initial());

  bool get canUndo => _history.isNotEmpty && !state.isGameOver;

  void makeMove(int row, int col) {
    if (state.isGameOver) return;
    
    _history.add(state.copyWith());
    state = _gameService.makeMove(state, row, col);
  }

  void undo() {
    if (_history.isEmpty) return;
    if (state.isGameOver) return;
    
    state = _history.removeLast();
  }

  void resetGame() {
    _history.clear();
    state = _gameService.resetGame();
  }

  List<List<(int, int)>> getWinningLines() {
    return _gameService.getWinningLines(state);
  }
}
