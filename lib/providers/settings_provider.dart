import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictactoe_game/models/board_size.dart';
import 'package:tictactoe_game/models/piece_size.dart';

class SettingsState {
  final BoardSize boardSize;
  final PieceSize pieceSize;

  SettingsState({
    required this.boardSize,
    required this.pieceSize,
  });

  SettingsState copyWith({
    BoardSize? boardSize,
    PieceSize? pieceSize,
  }) {
    return SettingsState(
      boardSize: boardSize ?? this.boardSize,
      pieceSize: pieceSize ?? this.pieceSize,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const String _boardSizeKey = 'board_size';
  static const String _pieceSizeKey = 'piece_size';

  @override
  Future<SettingsState> build() async {
    return _loadSettings();
  }

  Future<SettingsState> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final boardSizeIndex = prefs.getInt(_boardSizeKey);
    final pieceSizeIndex = prefs.getInt(_pieceSizeKey);

    return SettingsState(
      boardSize: boardSizeIndex != null && boardSizeIndex < BoardSize.values.length
          ? BoardSize.values[boardSizeIndex]
          : BoardSize.standard,
      pieceSize: pieceSizeIndex != null && pieceSizeIndex < PieceSize.values.length
          ? PieceSize.values[pieceSizeIndex]
          : PieceSize.standard,
    );
  }

  Future<void> setBoardSize(BoardSize size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_boardSizeKey, size.index);
    
    state = AsyncData(state.value!.copyWith(boardSize: size));
  }

  Future<void> setPieceSize(PieceSize size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pieceSizeKey, size.index);
    
    state = AsyncData(state.value!.copyWith(pieceSize: size));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
