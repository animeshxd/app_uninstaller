import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../adb/bloc/adb_bloc.dart';
import '../../adb/services/adb_service.dart';
import '../cubit/search_cubit.dart';

class PackageSearchDelegate extends SearchDelegate<Set<PackageInfo>> {
  final AdbBloc bloc;
  final SearchCubit searchCubit;
  PackageSearchDelegate(
    this.bloc,
    this.searchCubit,
  );

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
        child: OutlinedButton.icon(
          onPressed: () => bloc.add(AdbEventListPackages(false, null)),
          icon: const Icon(Icons.restart_alt),
          label: const Text("reload packages"),
        ),
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, searchCubit.state);
        searchCubit.notify();
      },
      icon: const Icon(Icons.done),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    var search = query.isNotEmpty ? query : null;

    bloc.add(AdbEventListPackages(false, search));

    return BlocBuilder<AdbBloc, AdbState>(
      bloc: bloc,
      buildWhen: (previous, current) => current is AdbPackageListResult,
      builder: (context, state) {
        state as AdbPackageListResult;
        var packages = state.packages.toList();
        return BlocBuilder<SearchCubit, Set<PackageInfo>>(
          bloc: searchCubit,
          builder: (context, state) {
            return ListView.builder(
              itemCount: packages.length,
              itemBuilder: (context, index) {
                var package = packages[index];

                bool checked = state.contains(package);

                return ListTile(
                  leading: checked
                      ? const Icon(Icons.check_box)
                      : const Icon(Icons.check_box_outline_blank),
                  title: Text(package.package),
                  onTap: () {
                    var func = checked
                        ? searchCubit.removePackage
                        : searchCubit.addPackage;
                    func(package);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    searchCubit.state.isEmpty
        ? bloc.add(AdbEventListPackages(false, null))
        : null;
    return BlocBuilder<AdbBloc, AdbState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          current is AdbPackageListResult || searchCubit.state.isNotEmpty,
      builder: (context, adbState) {
        List<PackageInfo> packages = searchCubit.state.toList();
        if (adbState is AdbPackageListResult && packages.isEmpty) {
          packages = adbState.packages.toList();
        }
        return BlocBuilder<SearchCubit, Set<PackageInfo>>(
          bloc: searchCubit,
          builder: (context, searchstate) {
            return ListView.builder(
              itemCount: packages.length,
              itemBuilder: (context, index) {
                var package = packages[index];

                bool checked = searchstate.contains(packages[index]);

                return ListTile(
                  leading: checked
                      ? const Icon(Icons.check_box)
                      : const Icon(Icons.check_box_outline_blank),
                  title: Text(package.package),
                  onTap: () {
                    var func = checked
                        ? searchCubit.removePackage
                        : searchCubit.addPackage;
                    func(package);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
