part of 'adb_bloc.dart';

@immutable
sealed class AdbEvent {}

final class AdbEventPair extends AdbEvent {
  final String ipWithPort;
  final String pin;

  AdbEventPair(this.ipWithPort, this.pin);
}

final class AdbEventConnect extends AdbEvent {
  final String ipWithPort;

  AdbEventConnect(this.ipWithPort);
}

final class AdbEventUninstallPackages extends AdbEvent {
  final Iterable<PackageInfo> packages;

  AdbEventUninstallPackages(this.packages);
}

final class AdbEventListPackages extends AdbEvent {
  final bool cached;
  final String? search;

  AdbEventListPackages(this.cached, this.search);
}

final class AdbEventListDevices extends AdbEvent {}

final class AdbEventExecuteCommand extends AdbEvent {
  final List<String> args;
  AdbEventExecuteCommand(String args) : args = args.split(' ');
}
