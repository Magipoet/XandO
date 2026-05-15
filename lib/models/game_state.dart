import 'package:tictactoe_game/models/ability.dart';
import 'package:tictactoe_game/models/board.dart';
import 'package:tictactoe_game/models/game_mode.dart';
import 'package:tictactoe_game/models/player.dart';

class PlayerAbilities {
  final Map<AbilityType, int> usesRemaining;

  PlayerAbilities({Map<AbilityType, int>? usesRemaining})
      : usesRemaining = usesRemaining ?? {};

  int getUses(AbilityType ability) {
    return usesRemaining[ability] ?? 0;
  }

  bool canUse(AbilityType ability) {
    return getUses(ability) > 0;
  }

  PlayerAbilities useAbility(AbilityType ability) {
    final newUses = Map<AbilityType, int>.from(usesRemaining);
    if (newUses.containsKey(ability) && newUses[ability]! > 0) {
      newUses[ability] = newUses[ability]! - 1;
    }
    return PlayerAbilities(usesRemaining: newUses);
  }

  PlayerAbilities copyWith({
    Map<AbilityType, int>? usesRemaining,
  }) {
    return PlayerAbilities(
      usesRemaining: usesRemaining ?? Map.from(this.usesRemaining),
    );
  }
}

class FreezeState {
  final int? row;
  final int? col;
  final Player? owner;
  final bool active;

  FreezeState({
    this.row,
    this.col,
    this.owner,
    this.active = false,
  });

  bool isCellFrozen(int cellRow, int cellCol) {
    if (!active) return false;
    return row == cellRow && col == cellCol;
  }

  FreezeState copyWith({
    int? row,
    int? col,
    Player? owner,
    bool? active,
  }) {
    return FreezeState(
      row: row ?? this.row,
      col: col ?? this.col,
      owner: owner ?? this.owner,
      active: active ?? this.active,
    );
  }

  FreezeState deactivate() {
    return FreezeState(active: false);
  }
}

class FunModeState {
  final Map<Player, PlayerAbilities> playerAbilities;
  final FreezeState freezeState;
  final bool waitingForFreezeTarget;

  FunModeState({
    Map<Player, PlayerAbilities>? playerAbilities,
    FreezeState? freezeState,
    this.waitingForFreezeTarget = false,
  })  : playerAbilities = playerAbilities ??
            {
              Player.x: PlayerAbilities(usesRemaining: {
                AbilityType.undo: 1,
                AbilityType.freeze: 1,
              }),
              Player.o: PlayerAbilities(usesRemaining: {
                AbilityType.undo: 1,
                AbilityType.freeze: 1,
              }),
            },
        freezeState = freezeState ?? FreezeState();

  PlayerAbilities getAbilities(Player player) {
    return playerAbilities[player] ?? PlayerAbilities();
  }

  bool canUseAbility(Player player, AbilityType ability) {
    return getAbilities(player).canUse(ability);
  }

  FunModeState useAbility(Player player, AbilityType ability) {
    final newAbilities = Map<Player, PlayerAbilities>.from(playerAbilities);
    newAbilities[player] = newAbilities[player]!.useAbility(ability);
    return FunModeState(
      playerAbilities: newAbilities,
      freezeState: freezeState,
      waitingForFreezeTarget: waitingForFreezeTarget,
    );
  }

  FunModeState setFreezeTarget(int row, int col, Player owner) {
    return FunModeState(
      playerAbilities: playerAbilities,
      freezeState: FreezeState(
        row: row,
        col: col,
        owner: owner,
        active: true,
      ),
      waitingForFreezeTarget: false,
    );
  }

  FunModeState startWaitingForFreezeTarget() {
    return FunModeState(
      playerAbilities: playerAbilities,
      freezeState: freezeState,
      waitingForFreezeTarget: true,
    );
  }

  FunModeState cancelWaitingForFreezeTarget() {
    return FunModeState(
      playerAbilities: playerAbilities,
      freezeState: freezeState,
      waitingForFreezeTarget: false,
    );
  }

  FunModeState deactivateFreeze() {
    return FunModeState(
      playerAbilities: playerAbilities,
      freezeState: freezeState.deactivate(),
      waitingForFreezeTarget: waitingForFreezeTarget,
    );
  }

  FunModeState copyWith({
    Map<Player, PlayerAbilities>? playerAbilities,
    FreezeState? freezeState,
    bool? waitingForFreezeTarget,
  }) {
    return FunModeState(
      playerAbilities: playerAbilities ?? Map.from(this.playerAbilities),
      freezeState: freezeState ?? this.freezeState,
      waitingForFreezeTarget: waitingForFreezeTarget ?? this.waitingForFreezeTarget,
    );
  }
}

class GameState {
  final Board board;
  final Player currentPlayer;
  final Player? winner;
  final bool isGameOver;
  final int moveCount;
  final GameMode gameMode;
  final FunModeState? funModeState;

  GameState({
    required this.board,
    required this.currentPlayer,
    this.winner,
    this.isGameOver = false,
    this.moveCount = 0,
    this.gameMode = GameMode.normal,
    this.funModeState,
  });

  GameState copyWith({
    Board? board,
    Player? currentPlayer,
    Player? winner,
    bool? isGameOver,
    int? moveCount,
    GameMode? gameMode,
    FunModeState? funModeState,
  }) {
    return GameState(
      board: board ?? this.board.copy(),
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      isGameOver: isGameOver ?? this.isGameOver,
      moveCount: moveCount ?? this.moveCount,
      gameMode: gameMode ?? this.gameMode,
      funModeState: funModeState ?? this.funModeState,
    );
  }

  static GameState initial({GameMode mode = GameMode.normal}) {
    return GameState(
      board: Board(),
      currentPlayer: Player.x,
      winner: null,
      isGameOver: false,
      moveCount: 0,
      gameMode: mode,
      funModeState: mode == GameMode.fun ? FunModeState() : null,
    );
  }

  bool isFunMode() {
    return gameMode == GameMode.fun;
  }

  bool canUseAbility(AbilityType ability) {
    if (!isFunMode()) return false;
    if (funModeState == null) return false;
    if (isGameOver) return false;
    return funModeState!.canUseAbility(currentPlayer, ability);
  }

  bool isWaitingForFreezeTarget() {
    if (!isFunMode()) return false;
    if (funModeState == null) return false;
    return funModeState!.waitingForFreezeTarget;
  }

  bool isCellFrozen(int row, int col) {
    if (!isFunMode()) return false;
    if (funModeState == null) return false;
    return funModeState!.freezeState.isCellFrozen(row, col);
  }

  Player? getFrozenCellOwner(int row, int col) {
    if (!isFunMode()) return null;
    if (funModeState == null) return null;
    if (!funModeState!.freezeState.isCellFrozen(row, col)) return null;
    return funModeState!.freezeState.owner;
  }
}
