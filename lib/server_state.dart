// Sherman Yan

import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServerState {
  final ServerSocket? server;
  ServerState(this.server);
}

class ServerCubit extends Cubit<ServerState> {
  ServerCubit() : super(ServerState(null)) {
    _bind();
  }

  Future<void> _bind() async {
    final ss = await ServerSocket.bind(InternetAddress.anyIPv4, 9203);
    emit(ServerState(ss));
  }

  @override
  Future<void> close() async {
    await state.server?.close();
    return super.close();
  }
}