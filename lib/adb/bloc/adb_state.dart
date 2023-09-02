part of 'adb_bloc.dart';

@immutable
sealed class AdbState {}

final class AdbInitial extends AdbState {}

final class ADbConnectSuccess extends AdbSuccess {}

final class ADbConnectFailed extends AdbFailed {}

final class AdbPairSuccess extends AdbSuccess {}

final class AdbPairFailed extends AdbFailed {}

final class AdbSuccess extends AdbState {}

final class AdbFailed extends AdbState {}

final class AdbPackageListResult extends AdbSuccess {
  final Set<PackageInfo> packages;

  AdbPackageListResult(this.packages);
}

final class AdbExecuteLogResult extends AdbSuccess {
  final String log;
  final bool hasError;

  AdbExecuteLogResult(this.log, this.hasError);
}
