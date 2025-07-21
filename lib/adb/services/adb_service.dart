import 'dart:async';
import 'dart:convert';
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

  Future<Process> executeRaw(
    List<String> args,
    StreamConsumer<String>? stream,
  ) async {
    final process = await Process.start(p.join(path, 'adb'), args);
    if (stream != null) {
      process.stderr.transform(utf8.decoder).pipe(stream);
      process.stdout.transform(utf8.decoder).pipe(stream);
    }
    return process;
  }

  Future<(ProcessResult result, String logs, int status)> executeWithLog(
    List<String> args,
  ) async {
    final process = await execute(args);
    final status = process.exitCode;
    return (process, '${process.stderr}${process.stdout}', status);
  }

  Future<List<String>> getAttachedDevices() async {
    final (_, stdlog, status) = await executeWithLog(['devices']);
    final devices = RegExp(r"List of devices attached\n([\s\S]*)")
            .firstMatch(stdlog.trim())
            ?.group(1)
            ?.trim()
            .split('\n') ??
        [];

    if (status == 1) return [];
    final Map<String, String> deviceMap = {};
    for (var device in devices) {
      final parts = device.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final deviceId = parts[0];
      final deviceName = parts[1];
      deviceMap[deviceId] = deviceName;
    }
    print(
      "Devices found: ${deviceMap.length}, ${deviceMap.entries.join(', ')}",
    );

    final result = devices.map((e) => e.split(RegExp(r'\s'))[0]).toList();
    return result;
  }

  /// List of discovered mdns services
// adb-R4WOCICYHE5D6T69-MfEQVn	_adb-tls-connect._tcp	192.168.0.226:33883
  Future<Map<String, String>> getMdnsDevices() async {
    final (_, stdlog, status) = await executeWithLog(['mdns', 'services']);
    if (status != 0) {
      return {};
    }
    final devices = stdlog
        .trim()
        .split('\n')
        .skip(1)
        .map((d) => d.split(RegExp(r'\s+')))
        .map((d) => MapEntry(d[0], d[2]));
    return Map.fromEntries(devices);
  }

  Future<bool> _executeWithLogAndKillwithStatus(List<String> args) async {
    final (_, _, status) = await executeWithLog(args);
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
    final args = ["shell", "pm", "uninstall"];
    if (keep) args.add("-k");
    if (user != -1) args.addAll(['--user', user.toString()]);
    args.add(packageName);
    return await _executeWithLogAndKillwithStatus(args);
  }

  Future<bool> disablePackage(
    String packageName, {
    int user = -1,
  }) async {
    final args = ['shell', 'pm', 'disable-user'];
    if (user != -1) args.addAll(['--user', user.toString()]);
    args.add(packageName);
    return await _executeWithLogAndKillwithStatus(args);
  }

  String listPackagedCached = "";
  Future<List<PackageInfo>> listPackages({
    bool cached = false,
    String? search,
  }) async {
    String log = "";
    if (!cached || listPackagedCached.isEmpty) {
      final (_, log, status) =
          await executeWithLog(["shell", "pm", "list", "packages", "-f"]);
      listPackagedCached = log;
      if (status != 0) return [];
    }
    log = listPackagedCached;

    final packages = (search == null)
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
