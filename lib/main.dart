// Sherman Yan

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'server_state.dart';
import 'socket_state.dart';
import 'scrabble_player.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Scrabble',
      debugShowCheckedModeBanner: false,
      home: ServerOrClient(),
    ),
  );
}

// Screen to choose between hosting or joining a game
class ServerOrClient extends StatelessWidget {
  const ServerOrClient({super.key});

  @override
  Widget build(BuildContext context) {
    final tec = TextEditingController(text: 'localhost'); // Default server IP
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title of the game
              Text(
                'Scrabble',
                style: TextStyle(
                  shadows: [Shadow(blurRadius: 30, color: Colors.green)],
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Instruction text
              Text(
                'Select your role to start the game:',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 20),
              // Buttons to choose role
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    text: 'Host', // Host button
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => ServerBase()));
                    },
                  ),
                  const SizedBox(width: 20),
                  CustomButton(
                    text: 'Client', // Client button
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ClientBase(tec.text)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Input field for server IP
              SizedBox(
                width: 280,
                child: TextField(
                  controller: tec,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Server IP',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                  textAlign: TextAlign.center,
                  cursorColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom button widget with green border and shadow
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const CustomButton({required this.text, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.green, blurRadius: 6)],
        ),
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}

// Screen for hosting the game
class ServerBase extends StatelessWidget {
  const ServerBase({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServerCubit>(
      create: (_) => ServerCubit(), // Initialize server cubit
      child: BlocBuilder<ServerCubit, ServerState>(
        builder: (context, serverState) {
          if (serverState.server == null) {
            // Show loading screen while server starts
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.green,
              ),
              body: Center(
                child: Text(
                  'Starting server...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              backgroundColor: Colors.black,
            );
          }
          return BlocProvider<SocketCubit>(
            create: (_) => SocketCubit.server(serverState.server!),
            child: BlocBuilder<SocketCubit, SocketState>(
              builder: (context, socketState) {
                if (socketState.socket == null) {
                  // Show waiting screen while waiting for client
                  return Scaffold(
                    appBar: AppBar(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.green,
                    ),
                    body: Center(
                      child: Text(
                        'Waiting for client...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    backgroundColor: Colors.black,
                  );
                }
                // Start the game as the host
                return ScrabbleScreen(isStartingPlayer: true);
              },
            ),
          );
        },
      ),
    );
  }
}

// Screen for joining the game as a client
class ClientBase extends StatelessWidget {
  final String ip; // Server IP to connect to
  const ClientBase(this.ip, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SocketCubit>(
      create: (_) => SocketCubit.client(ip), // Initialize client cubit
      child: BlocBuilder<SocketCubit, SocketState>(
        builder: (context, socketState) {
          if (socketState.socket == null) {
            // Show loading screen while connecting to server
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.green,
              ),
              body: Center(
                child: Text(
                  'Connecting to server...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              backgroundColor: Colors.black,
            );
          }
          // Start the game as the client
          return ScrabbleScreen(isStartingPlayer: false);
        },
      ),
    );
  }
}
