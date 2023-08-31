import 'dart:convert';
import 'dart:io';
import 'package:app_uninstaller/log/cubit/log_messages_cubit.dart';
import 'package:path/path.dart' as p;

class Adb {
  final String path;
  final LogMessagesCubit logMessagesCubit;

  Adb({required this.path, required this.logMessagesCubit});

  Future<Process> execute(List<String> args) async =>
      await Process.start(p.join(path, 'adb'), args);

  Future<(Process, String, int)> _executeWithLog(List<String> args) async {
    var process = await execute(args);
    var status = await process.exitCode;
    Stream<List<int>> stdallout = status == 0 ? process.stdout : process.stderr;
    var log =
        utf8.decode(await stdallout.where((event) => event.isNotEmpty).first);
    logMessagesCubit.log(log);
    return (process, log, status);
  }

  Future<List<String>> getDevices() async {
    var (process, stdlog, status) = await _executeWithLog(['devices']);
    var devices = stdlog.trim().split('\n').sublist(1);
    process.kill();
    if (status == 1) return [];
    return devices.map((e) => e.replaceAll('device', '').trim()).toList();
  }

  Future<bool> _executeWithLogAndKillwithStatus(List<String> args) async {
    var (process, _, status) = await _executeWithLog(args);
    process.kill();
    return status == 0;
  }

  Future<bool> startServer() async {
    return await _executeWithLogAndKillwithStatus(['start-server']);
  }

  Future<bool> killServer() async {
    return await _executeWithLogAndKillwithStatus(['kill-server']);
  }

  Future<bool> pairDevice(String ipwithPort, String pin) async {
    return await _executeWithLogAndKillwithStatus(['pair', ipwithPort, pin]);
  }

  Future<bool> connectDevice(String ipwithPort) async {
    return await _executeWithLogAndKillwithStatus(['connect', ipwithPort]);
  }

  Future<bool> uninstallPackage(
    String packageName, {
    bool keep = false,
    int user = -1,
  }) async {
    var args = ["shell", "pm", "uninstall"];
    if (keep) args.add("-k");
    if (user != -1) args.addAll(['--user', user.toString()]);
    return await _executeWithLogAndKillwithStatus(args);
  }

  Future<bool> disablePackage(
    String packageName, {
    int user = -1,
  }) async {
    var args = ['shell', 'pm', 'disable-user'];
    if (user != -1) args.addAll(['--user', user.toString()]);
    return await _executeWithLogAndKillwithStatus(args);
  }

  Future<void> listPackages() async {
    await _executeWithLogAndKillwithStatus(
      ["shell", "pm", "list", "packages", "-f"],
    );
  }
}

class PackageInfo {
  final String path;
  final String package;

  PackageInfo(this.path, this.package);
}
