import 'package:bloc/bloc.dart';

class LogMessagesCubit extends Cubit<String> {
  LogMessagesCubit() : super('');

  var logs = <String>[];

  void log(String message) {
    logs.add(message.trim());
    emit(logs.join('\n'));
  }

  void clear() => logs.clear();
}
