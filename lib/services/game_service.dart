import 'package:tictactoe_game/models/ability.dart';
import 'package:tictactoe_game/models/game_mode.dart';
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
    if (currentState.isWaitingForFreezeTarget()) return currentState;
    if (currentState.isCellFrozen(row, col)) return currentState;

    final newBoard = currentState.board.copy();

    _boardService.placePiece(newBoard, currentState.currentPlayer, row, col);

    final winner = _winCheckService.checkWinner(newBoard);
    final isGameOver = winner != null;

    final nextPlayer = isGameOver
        ? currentState.currentPlayer
        : currentState.currentPlayer.next;

    FunModeState? newFunModeState = currentState.funModeState;
    if (currentState.isFunMode() && currentState.funModeState != null) {
      final freezeState = currentState.funModeState!.freezeState;
      if (freezeState.active &&
          freezeState.owner != null &&
          freezeState.owner != currentState.currentPlayer) {
        newFunModeState = currentState.funModeState!.deactivateFreeze();
      }
    }

    return GameState(
      board: newBoard,
      currentPlayer: nextPlayer,
      winner: winner,
      isGameOver: isGameOver,
      moveCount: currentState.moveCount + 1,
      gameMode: currentState.gameMode,
      funModeState: newFunModeState,
    );
  }

  GameState resetGame({GameMode? mode}) {
    return GameState.initial(mode: mode ?? GameMode.normal);
  }

  GameState useFunUndo(GameState currentState, GameState previousState, Player player) {
    if (!currentState.isFunMode()) return currentState;
    if (currentState.isGameOver) return currentState;
    if (!currentState.funModeState!.canUseAbility(player, AbilityType.undo)) {
      return currentState;
    }

    final newFunModeState =
        currentState.funModeState!.useAbility(player, AbilityType.undo);

    return previousState.copyWith(
      funModeState: newFunModeState,
    );
  }

  GameState startFreezeSelection(GameState currentState, Player player) {
    if (!currentState.isFunMode()) return currentState;
    if (currentState.isGameOver) return currentState;
    if (!currentState.funModeState!.canUseAbility(player, AbilityType.freeze)) {
      return currentState;
    }
    if (currentState.isWaitingForFreezeTarget()) return currentState;
    if (currentState.funModeState!.freezeState.active) return currentState;

    return currentState.copyWith(
      funModeState: currentState.funModeState!.startWaitingForFreezeTarget(),
    );
  }

  GameState cancelFreezeSelection(GameState currentState) {
    if (!currentState.isFunMode()) return currentState;
    if (!currentState.isWaitingForFreezeTarget()) return currentState;

    return currentState.copyWith(
      funModeState: currentState.funModeState!.cancelWaitingForFreezeTarget(),
    );
  }

  GameState setFreezeTarget(GameState currentState, int row, int col, Player player) {
    if (!currentState.isFunMode()) return currentState;
    if (currentState.isGameOver) return currentState;
    if (!currentState.isWaitingForFreezeTarget()) return currentState;
    if (!currentState.board.isEmpty(row, col)) return currentState;
    if (!currentState.funModeState!.canUseAbility(player, AbilityType.freeze)) {
      return currentState;
    }
    if (currentState.funModeState!.freezeState.active) {
      return currentState;
    }

    final newFunModeState = currentState.funModeState!
        .useAbility(player, AbilityType.freeze)
        .setFreezeTarget(row, col, player);

    return currentState.copyWith(
      funModeState: newFunModeState,
    );
  }

  List<List<(int, int)>> getWinningLines(GameState state) {
    if (!state.isGameOver) return [];
    return _winCheckService.getWinningLines(state.board);
  }
}
