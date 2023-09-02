import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

import '../../log/cubit/log_messages_cubit.dart';

class Adb {
  final String path;
  final LogMessagesCubit logMessagesCubit;

  Adb({required this.path, required this.logMessagesCubit});

  Future<ProcessResult> execute(List<String> args) async =>
      await Process.run(p.join(path, 'adb'), args);

  Future<(ProcessResult, String, int)> executeWithLog(
      List<String> args) async {
    var process = await execute(args);
    var status = process.exitCode;
    return (process, '${process.stderr}${process.stdout}', status);
  }

  Future<List<String>> getDevices() async {
    var (_, stdlog, status) = await executeWithLog(['devices']);
    var devices = RegExp(r"List of devices attached\n([\s\S]*)")
            .firstMatch(stdlog.trim())
            ?.group(1)
            ?.trim()
            .split('\n') ??
        [];

    if (status == 1) return [];

    var result = devices.map((e) => e.split(RegExp(r'\s'))[0]).toList();
    return result;
  }

  Future<bool> _executeWithLogAndKillwithStatus(List<String> args) async {
    var (_, _, status) = await executeWithLog(args);
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
    args.add(packageName);
    return await _executeWithLogAndKillwithStatus(args);
  }

  Future<bool> disablePackage(
    String packageName, {
    int user = -1,
  }) async {
    var args = ['shell', 'pm', 'disable-user'];
    if (user != -1) args.addAll(['--user', user.toString()]);
    args.add(packageName);
    return await _executeWithLogAndKillwithStatus(args);
  }

  String listPackagedCached = "";
  Future<List<PackageInfo>> listPackages(
      {bool cached = false, String? search}) async {
    String log = "";
    if (!cached || listPackagedCached.isEmpty) {
      var (_, log, status) =
          await executeWithLog(["shell", "pm", "list", "packages", "-f"]);
      listPackagedCached = log;
      if (status != 0) return [];
    }
    log = listPackagedCached;

    var packages = (search == null)
        ? log.trim().split('\n')
        : RegExp(
            'package:.*$search(\$|.*)\n',
            caseSensitive: false,
            multiLine: true,
          ).allMatches(log).map((e) => e.group(0) ?? '');
    return packages
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .map((e) => e.split('.apk='))
        .map((e) => PackageInfo('${e[0]}.apk', e[1]))
        .toList();
  }
}

class PackageInfo extends Equatable {
  final String path;
  final String package;

  const PackageInfo(this.path, this.package);

  @override
  List<Object> get props => [path, package];
}
