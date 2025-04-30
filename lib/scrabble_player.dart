// Sherman Yan

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'socket_state.dart';
import 'scrabble_game_state.dart';
import 'message_state.dart';

class ScrabbleScreen extends StatelessWidget {
  final bool isStartingPlayer;
  const ScrabbleScreen({required this.isStartingPlayer, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide ScrabbleCubit and MessageCubit to manage game and chat states
        BlocProvider(create: (_) => ScrabbleCubit(isStartingPlayer)),
        BlocProvider(create: (_) => MessageCubit()),
      ],
      child: BlocBuilder<ScrabbleCubit, ScrabbleState>(
        builder: (context, gameState) => PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            final cubit = context.read<ScrabbleCubit>();
            if (!cubit.state.resigned) {
              // Resign if the player hasn't resigned yet
              cubit.resignLocal();
              context.read<SocketCubit>().send('resign');
            }
            // Close socket connection when navigating back
            context.read<SocketCubit>().closeConnection();
          },
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.green,
              ),
            ),
            backgroundColor: Colors.black,
            body: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Resign button logic
                            TextButton(
                              onPressed: () {
                                context.read<ScrabbleCubit>().resignLocal();
                                context.read<SocketCubit>().send('resign');
                                context
                                    .read<MessageCubit>()
                                    .addChat('You resigned');
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: Text('Resign'),
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${gameState.theirScore} - ${gameState.myScore}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Scrabble board
                        SizedBox(
                          width: 380,
                          height: 380,
                          child: _BoardGrid(),
                        ),

                        const SizedBox(height: 12),
                        // Rack panel for player's tiles
                        _RackPanel(),
                        const SizedBox(height: 12),
                        // End turn and pass buttons
                        _EndTurnButton(),
                      ],
                    ),
                  ),
                ),
                // Chat panel for communication
                Expanded(flex: 1, child: _ChatPanel()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScrabbleCubit>();
    final sc = context.read<SocketCubit>();
    final state = cubit.state;

    // Start listening to socket messages if not already listening
    if (sc.state.socket != null && !sc.state.listening) {
      sc.startListening((msg) {
        // Handle different types of messages from the opponent
        if (msg.startsWith('pl ')) {
          final p = msg.split(' ');
          cubit.placeRemote(int.parse(p[1]), int.parse(p[2]), p[3]);
        } else if (msg.startsWith('end ')) {
          final drawn = msg.substring(4).split(',');
          cubit.endTurnRemote(drawn);
        } else if (msg == 'pass') {
          cubit.passRemote();
          context.read<MessageCubit>().addChat('Opponent passed');
        } else if (msg.startsWith('chat ')) {
          context.read<MessageCubit>().addChat('Them: ${msg.substring(5)}');
        } else if (msg == 'resign') {
          cubit.resignRemote();
          context.read<MessageCubit>().addChat('Opponent resigned — you win!');
        }
      });
    }

    final size = ScrabbleCubit.BOARD_SIZE;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: size * size,
      itemBuilder: (_, i) {
        final x = i ~/ size, y = i % size;
        return DragTarget<String>(
          // Allow dropping tiles only if it's the player's turn and the cell is empty
          onWillAcceptWithDetails: (tile) =>
              state.myTurn && state.board[x][y].isEmpty && !state.resigned,
          onAccept: (tile) {
            cubit.placeLocal(x, y, tile);
            sc.send('pl $x $y $tile');
          },
          builder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: state.board[x][y].isEmpty
                    ? Colors.green
                    : (state.owner[x][y] ? Colors.brown : Colors.blue),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                state.board[x][y],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RackPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rack = context.watch<ScrabbleCubit>().state.rack;
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: rack.map((tile) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Draggable<String>(
                  // Allow dragging tiles from the rack
                  data: tile,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _TileWidget(letter: tile, size: 30),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _TileWidget(letter: tile, size: 20),
                  ),
                  child: _TileWidget(letter: tile, size: 20),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}

class _TileWidget extends StatelessWidget {
  final String letter;
  final double size;
  const _TileWidget({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.brown, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EndTurnButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScrabbleCubit>();
    final state = cubit.state;
    final sc = context.read<SocketCubit>();

    final canPass = state.myTurn;
    final canEnd = state.myTurn && state.placedCount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // PASS button logic
        ElevatedButton(
          onPressed: canPass
              ? () {
                  cubit.passLocal();
                  sc.send('pass');
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: canPass ? Colors.red : Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Pass',
              style: TextStyle(color: canPass ? Colors.red : Colors.grey)),
        ),

        const SizedBox(width: 12),

        // END TURN button logic
        ElevatedButton(
          onPressed: canEnd
              ? () {
                  final newTiles = cubit.endTurnLocal();
                  sc.send('end ${newTiles.join(',')}');
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: canEnd ? Colors.green : Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('End Turn',
              style: TextStyle(color: canEnd ? Colors.green : Colors.grey)),
        ),
      ],
    );
  }
}

class _ChatPanel extends StatefulWidget {
  @override
  _ChatPanelState createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _chatTec = TextEditingController();
  final _scrollCtl = ScrollController();

  @override
  void dispose() {
    _chatTec.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _chatTec.text.trim();
    if (text.isEmpty) return;
    final sc = context.read<SocketCubit>();
    final mc = context.read<MessageCubit>();
    // Send chat message to opponent and update local chat history
    sc.send('chat $text');
    mc.addChat('You: $text');
    _chatTec.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtl.hasClients) {
        _scrollCtl.jumpTo(_scrollCtl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<MessageCubit>().state.history;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            'Chat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ListView.builder(
                controller: _scrollCtl,
                padding: const EdgeInsets.all(8),
                itemCount: history.length,
                itemBuilder: (_, i) {
                  final msg = history[i];
                  final isStatus =
                      !(msg.startsWith('You:') || msg.startsWith('Them:'));
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Text(
                      msg,
                      style: TextStyle(
                        color: isStatus ? Colors.green : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatTec,
                  cursorColor: Colors.green,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type…',
                    hintStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.green),
                onPressed: _send,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
