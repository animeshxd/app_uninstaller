import 'package:app_uninstaller/adb/services/adb_service.dart';
import 'package:app_uninstaller/log/cubit/log_messages_cubit.dart';
import "dart:io";

void main(List<String> args) async {
  final home = Platform.environment["HOME"] ?? "";
  final Adb abd = Adb(
    path: "$home/.local/opt/android/platform-tools",
    logMessagesCubit: LogMessagesCubit(),
  );
  final devices = await abd.getMdnsDevices();
  print(devices);
}
