import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../log/cubit/log_messages_cubit.dart';
import '../services/adb_service.dart';

part 'adb_event.dart';
part 'adb_state.dart';

class AdbBloc extends Bloc<AdbEvent, AdbState> {
  Adb adb;
  LogMessagesCubit logger;
  AdbBloc(
    this.adb,
    this.logger,
  ) : super(AdbInitial()) {
    on<AdbEventConnect>((event, emit) async {
      var status = await adb.connectDevice(event.ipWithPort);
      if (status) {
        emit(ADbConnectSuccess());
      } else {
        emit(ADbConnectFailed());
      }
    });

    on<AdbEventPair>((event, emit) async {
      var status = await adb.pairDevice(event.ipWithPort, event.pin);
      if (status) {
        emit(AdbPairSuccess());
      } else {
        emit(AdbPairFailed());
      }
    });

    on<AdbEventUninstallPackages>(onUninstallPackagesEvent);
    on<AdbEventListPackages>(onListPackagesEvent);
    on<AdbEventListDevices>((event, emit) async {
      var result = await adb.getDevices();
      logger.log("Devices: ");
      result.forEach(logger.log);
    });

    on<AdbEventExecuteCommand>((event, emit) async {
      if (event.args.first == 'adb') event.args.removeAt(0);
      var (_, log, status) = await adb.executeWithLog(event.args);
      emit(AdbExecuteLogResult(log, status != 0));
    });
  }

  FutureOr<void> onListPackagesEvent(event, emit) async {
    var result =
        await adb.listPackages(cached: event.cached, search: event.search);

    emit(AdbPackageListResult(result.toSet()));
  }

  FutureOr<void> onUninstallPackagesEvent(event, emit) async {
    var packages = event.packages.map((e) => e.package);
    logger.log('uninstalling ${packages.join(',')}');
    for (var package in packages) {
      var status1 = await adb.uninstallPackage(package);
      var status2 = await adb.uninstallPackage(package, user: 0);
      var status3 = await adb.disablePackage(package);
      if (status1 || status2 || status3) {
        logger.log("Uninstall Success: $package");
      } else {
        logger.log("uninstalled failed: $package");
      }
    }
    logger.log('Transaction completed');
  }
}
