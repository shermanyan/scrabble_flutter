// Sherman Yan

import 'dart:io';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

class SocketState {
  final Socket? socket;
  final bool listening;
  SocketState(this.socket, this.listening);
}

class SocketCubit extends Cubit<SocketState> {
  bool _disposed = false; 

  SocketCubit.server(ServerSocket ss) : super(SocketState(null, false)) {
    ss.listen((client) {
      if (!_disposed) emit(SocketState(client, false));
    });
  }

  // Constructor for client-side socket handling. Attempts to connect to a server.
  SocketCubit.client(String ip) : super(SocketState(null, false)) {
    _attemptConnect(ip);
  }

  // Attempts to connect to the server at the given IP address.
  Future<void> _attemptConnect(String ip) async {
    if (_disposed) return;
    try {
      final s = await Socket.connect(ip, 9203);
      if (!_disposed) emit(SocketState(s, false));
    } catch (e) {
      if (_disposed) return;
      // Retry connection after a delay if it fails.
      await Future.delayed(Duration(seconds: 2));
      return _attemptConnect(ip);
    }
  }

  // Starts listening for incoming messages on the socket.
  void startListening(void Function(String) onMessage) {
    final sock = state.socket;
    if (sock != null && !state.listening) {
      sock.listen((data) {
        final msg = String.fromCharCodes(data).trim();
        onMessage(msg); // Passes received messages to the provided callback.
      });
      emit(SocketState(sock, true));
    }
  }

  // Sends a message through the socket.
  void send(String msg) {
    state.socket?.writeln(msg);
  }

  // Closes the socket connection and resets the state.
  void closeConnection() {
    state.socket?.destroy();
    emit(SocketState(null, false));
  }

  // Disposes of the Cubit and cleans up resources.
  @override
  Future<void> close() async {
    _disposed = true;
    state.socket?.destroy();
    return super.close();
  }
}
