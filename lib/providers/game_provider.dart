import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/models/ability.dart';
import 'package:tictactoe_game/models/game_mode.dart';
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

  bool canUseAbility(AbilityType ability) {
    return state.canUseAbility(ability);
  }

  bool get isWaitingForFreezeTarget => state.isWaitingForFreezeTarget();

  GameMode get gameMode => state.gameMode;

  void makeMove(int row, int col) {
    if (state.isGameOver) return;

    if (state.isWaitingForFreezeTarget()) {
      if (!state.board.isEmpty(row, col)) return;
      _history.add(state.copyWith());
      state = _gameService.setFreezeTarget(state, row, col);
      return;
    }

    _history.add(state.copyWith());
    state = _gameService.makeMove(state, row, col);
  }

  void undo() {
    if (_history.isEmpty) return;
    if (state.isGameOver) return;

    state = _history.removeLast();
  }

  void useFunUndo() {
    if (!state.isFunMode()) return;
    if (_history.isEmpty) return;
    if (state.isGameOver) return;
    if (!state.canUseAbility(AbilityType.undo)) return;

    _history.removeLast();
    state = _gameService.useFunUndo(state, _history);
  }

  void startFreezeSelection() {
    if (!state.isFunMode()) return;
    if (state.isGameOver) return;
    if (!state.canUseAbility(AbilityType.freeze)) return;

    state = _gameService.startFreezeSelection(state);
  }

  void cancelFreezeSelection() {
    if (!state.isWaitingForFreezeTarget()) return;

    state = _gameService.cancelFreezeSelection(state);
  }

  void resetGame({GameMode? mode}) {
    _history.clear();
    state = _gameService.resetGame(mode: mode ?? state.gameMode);
  }

  void switchGameMode(GameMode mode) {
    _history.clear();
    state = GameState.initial(mode: mode);
  }

  List<List<(int, int)>> getWinningLines() {
    return _gameService.getWinningLines(state);
  }
}
