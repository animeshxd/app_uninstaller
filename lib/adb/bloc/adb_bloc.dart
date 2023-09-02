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
  }

  FutureOr<void> onListPackagesEvent(event, emit) async {
    var result =
        await adb.listPackages(cached: event.cached, search: event.search);

    emit(AdbPackageListResult(result.toSet()));
  }

  FutureOr<void> onUninstallPackagesEvent(event, emit) async {
    for (var element in event.packages) {
      var status1 = await adb.uninstallPackage(element.package);
      var status2 = await adb.uninstallPackage(element.package, user: 0);
      var status3 = await adb.disablePackage(element.package);
      if (status1 || status2 || status3) {
        logger.log("Uninstall Success: ${element.package}");
      } else {
        logger.log("uninstalled failed: ${element.package}");
      }
    }
  }
}
