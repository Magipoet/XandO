import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tictactoe_game/models/ability.dart';
import 'package:tictactoe_game/models/game_mode.dart';
import 'package:tictactoe_game/models/game_state.dart';
import 'package:tictactoe_game/models/player.dart';
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
  Player? _freezeInitiator;

  GameNotifier(this._gameService) : super(GameState.initial());

  bool get canUndo => _history.isNotEmpty && !state.isGameOver;

  Player? get lastPlayer {
    if (_history.isEmpty) return null;
    return _history.last.currentPlayer;
  }

  bool canUseAbility(AbilityType ability) {
    if (!state.isFunMode()) return false;
    if (state.isGameOver) return false;
    if (_history.isEmpty) return false;
    final lastPlayer = _history.last.currentPlayer;
    return state.funModeState!.canUseAbility(lastPlayer, ability);
  }

  bool get isWaitingForFreezeTarget => state.isWaitingForFreezeTarget();

  GameMode get gameMode => state.gameMode;

  void makeMove(int row, int col) {
    if (state.isGameOver) return;

    if (state.isWaitingForFreezeTarget()) {
      if (!state.board.isEmpty(row, col)) return;
      final initiator = _freezeInitiator;
      if (initiator == null) return;
      state = _gameService.setFreezeTarget(state, row, col, initiator);
      _freezeInitiator = null;
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

    final lastPlayer = _history.last.currentPlayer;
    if (!state.funModeState!.canUseAbility(lastPlayer, AbilityType.undo)) {
      return;
    }

    final previousState = _history.removeLast();
    state = _gameService.useFunUndo(state, previousState, lastPlayer);
  }

  void startFreezeSelection() {
    if (!state.isFunMode()) return;
    if (state.isGameOver) return;
    if (_history.isEmpty) return;

    final lastPlayer = _history.last.currentPlayer;
    if (!state.funModeState!.canUseAbility(lastPlayer, AbilityType.freeze)) {
      return;
    }

    _freezeInitiator = lastPlayer;
    state = _gameService.startFreezeSelection(state, lastPlayer);
  }

  void cancelFreezeSelection() {
    if (!state.isWaitingForFreezeTarget()) return;

    _freezeInitiator = null;
    state = _gameService.cancelFreezeSelection(state);
  }

  void resetGame({GameMode? mode}) {
    _history.clear();
    _freezeInitiator = null;
    state = _gameService.resetGame(mode: mode ?? state.gameMode);
  }

  void switchGameMode(GameMode mode) {
    _history.clear();
    _freezeInitiator = null;
    state = GameState.initial(mode: mode);
  }

  List<List<(int, int)>> getWinningLines() {
    return _gameService.getWinningLines(state);
  }
}
