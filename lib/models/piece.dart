import 'package:tictactoe_game/models/player.dart';

class Piece {
  final String id;
  final Player owner;
  final int relativeOrder;
  final int row;
  final int col;
  final DateTime placedAt;

  Piece({
    required this.id,
    required this.owner,
    required this.relativeOrder,
    required this.row,
    required this.col,
    required this.placedAt,
  });

  Piece copyWith({
    String? id,
    Player? owner,
    int? relativeOrder,
    int? row,
    int? col,
    DateTime? placedAt,
  }) {
    return Piece(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      relativeOrder: relativeOrder ?? this.relativeOrder,
      row: row ?? this.row,
      col: col ?? this.col,
      placedAt: placedAt ?? this.placedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
