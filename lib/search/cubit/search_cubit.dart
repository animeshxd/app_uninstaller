import 'package:bloc/bloc.dart';

import '../../adb/services/adb_service.dart';

class SearchCubit extends Cubit<Set<PackageInfo>> {
  final _state = <PackageInfo>{};
  SearchCubit() : super({});

  void addPackage(PackageInfo package) {
    _state.add(package);
    emit(Set.from(_state));
  }

  void removePackage(PackageInfo package) {
    _state.remove(package);
    emit(Set.from(_state));
  }

  void clear() {
    _state.clear();
    emit({});
  }

  void notify() {
    emit(_state);
  }
}
