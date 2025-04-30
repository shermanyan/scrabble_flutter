// Sherman Yan

import 'package:flutter_bloc/flutter_bloc.dart';

// Represents the state of the Scrabble game
class ScrabbleState {
  final List<List<String>> board;
  final List<List<bool>> owner;
  final List<String> rack;
  final int bagCount;
  final bool myTurn;
  final int placedCount;
  final int myScore;
  final int theirScore;
  final bool resigned;

  ScrabbleState({
    required this.board,
    required this.owner,
    required this.rack,
    required this.bagCount,
    required this.myTurn,
    this.placedCount = 0,
    this.myScore = 0,
    this.theirScore = 0,
    this.resigned = false,
  });

  // Creates a new state with updated values while keeping others unchanged
  ScrabbleState copyWith({
    List<List<String>>? board,
    List<List<bool>>? owner,
    List<String>? rack,
    int? bagCount,
    bool? myTurn,
    int? placedCount,
    int? myScore,
    int? theirScore,
    bool? resigned,
  }) =>
      ScrabbleState(
        board: board ?? this.board,
        owner: owner ?? this.owner,
        rack: rack ?? this.rack,
        bagCount: bagCount ?? this.bagCount,
        myTurn: myTurn ?? this.myTurn,
        placedCount: placedCount ?? this.placedCount,
        myScore: myScore ?? this.myScore,
        theirScore: theirScore ?? this.theirScore,
        resigned: resigned ?? this.resigned,
      );
}

// Handles the game logic and state management
class ScrabbleCubit extends Cubit<ScrabbleState> {
  static const int BOARD_SIZE = 15; // Standard Scrabble board size

  // The letter bag with shuffled tiles
  static final List<String> _letterBag = ([
    ...List.filled(9, 'A'),
    ...List.filled(2, 'B'),
    ...List.filled(2, 'C'),
    ...List.filled(4, 'D'),
    ...List.filled(12, 'E'),
    ...List.filled(2, 'F'),
    ...List.filled(3, 'G'),
    ...List.filled(2, 'H'),
    ...List.filled(9, 'I'),
    ...List.filled(1, 'J'),
    ...List.filled(1, 'K'),
    ...List.filled(4, 'L'),
    ...List.filled(2, 'M'),
    ...List.filled(6, 'N'),
    ...List.filled(2, ''),
    ...List.filled(8, 'O'),
    ...List.filled(2, 'P'),
    ...List.filled(1, 'Q'),
    ...List.filled(6, 'R'),
    ...List.filled(4, 'S'),
    ...List.filled(6, 'T'),
    ...List.filled(4, 'U'),
    ...List.filled(2, 'V'),
    ...List.filled(2, 'W'),
    ...List.filled(1, 'X'),
    ...List.filled(2, 'Y'),
    ...List.filled(1, 'Z'),
  ]..shuffle());

  // Removes specific letters from the bag
  static void removeFromBag(List<String> letters) {
    for (var l in letters) {
      _letterBag.remove(l);
    }
  }

  // Initializes the game state
  ScrabbleCubit(bool iStart)
      : super(ScrabbleState(
          board: List.generate(BOARD_SIZE, (_) => List.filled(BOARD_SIZE, '')),
          owner:
              List.generate(BOARD_SIZE, (_) => List.filled(BOARD_SIZE, false)),
          rack: [],
          bagCount: _letterBag.length,
          myTurn: iStart,
        )) {
    // Draw initial 7 tiles for the player's rack
    final drawn = _drawLetters(7);
    emit(state.copyWith(rack: drawn, bagCount: _letterBag.length));
  }

  // Draws `n` letters from the bag
  List<String> _drawLetters(int n) {
    final draw = <String>[];
    for (var i = 0; i < n && _letterBag.isNotEmpty; i++) {
      draw.add(_letterBag.removeLast());
    }
    return draw;
  }

  // Places a letter on the board locally
  void placeLocal(int x, int y, String letter) {
    // Ensure it's the player's turn, the spot is empty, and the letter is in the rack
    if (!state.myTurn ||
        state.board[x][y].isNotEmpty ||
        !state.rack.contains(letter)) return;

    // Create deep copies of the board and owner arrays
    final b = state.board.map((r) => List<String>.from(r)).toList();
    final o = state.owner.map((r) => List<bool>.from(r)).toList();

    // Place the letter and mark ownership
    b[x][y] = letter;
    o[x][y] = true;

    // Remove the letter from the rack
    final r = List<String>.from(state.rack)..remove(letter);

    // Update the state
    emit(state.copyWith(
      board: b,
      owner: o,
      rack: r,
      placedCount: state.placedCount + 1,
      myScore: state.myScore + 1, // Increment myScore
    ));
  }

  // Places a letter on the board remotely
  void placeRemote(int x, int y, String letter) {
    // Create deep copies of the board and owner arrays
    final b = state.board.map((r) => List<String>.from(r)).toList();
    final o = state.owner.map((r) => List<bool>.from(r)).toList();

    // Place the letter and mark it as remote
    b[x][y] = letter;
    o[x][y] = false;

    // Update the state
    emit(state.copyWith(
      board: b,
      owner: o,
      theirScore: state.theirScore + 1, // Increment theirScore
    ));
  }

  // Ends the local player's turn and draws new tiles
  List<String> endTurnLocal() {
    // Calculate how many tiles to draw to refill the rack
    final drawCount = 7 - state.rack.length;

    // Draw new tiles and add them to the rack
    final newTiles = _drawLetters(drawCount);
    final r = List<String>.from(state.rack)..addAll(newTiles);

    // Update the state
    emit(state.copyWith(
      rack: r,
      bagCount: _letterBag.length,
      myTurn: false,
      placedCount: 0,
    ));

    return newTiles;
  }

  // Passes the local player's turn
  void passLocal() {
    emit(state.copyWith(myTurn: false, placedCount: 0));
  }

  // Ends the remote player's turn and updates the state
  void endTurnRemote(List<String> drawn) {
    // Remove the drawn tiles from the bag
    removeFromBag(drawn);

    // Update the state
    emit(state.copyWith(
      bagCount: _letterBag.length,
      myTurn: true,
      placedCount: 0,
    ));
  }

  // Passes the remote player's turn
  void passRemote() {
    emit(state.copyWith(myTurn: true, placedCount: 0));
  }

  // Handles local resignation
  void resignLocal() => emit(state.copyWith(resigned: true));

  // Handles remote resignation
  void resignRemote() => emit(state.copyWith(resigned: true));
}
