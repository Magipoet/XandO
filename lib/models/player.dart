enum Player {
  x,
  o,
}

extension PlayerExtension on Player {
  String get symbol {
    switch (this) {
      case Player.x:
        return '×';
      case Player.o:
        return '○';
    }
  }

  String get name {
    switch (this) {
      case Player.x:
        return 'X';
      case Player.o:
        return 'O';
    }
  }

  Player get next {
    switch (this) {
      case Player.x:
        return Player.o;
      case Player.o:
        return Player.x;
    }
  }
}
