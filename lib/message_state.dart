// Sherman Yan

import 'package:flutter_bloc/flutter_bloc.dart';

class MessageState {
  final List<String> history;
  MessageState(this.history);
}

class MessageCubit extends Cubit<MessageState> {
  MessageCubit() : super(MessageState([]));

  void addChat(String line) {
    final h = List<String>.from(state.history)..add(line);
    emit(MessageState(h));
  }
}
