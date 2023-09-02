import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adb/bloc/adb_bloc.dart';
import 'adb/services/adb_service.dart';
import 'log/cubit/log_messages_cubit.dart';
import 'log/view/log_window.dart';
import 'search/cubit/search_cubit.dart';
import 'search/view/search_delegate.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SelectPlatformTools(),
    );
  }
}

class SelectPlatformTools extends StatefulWidget {
  const SelectPlatformTools({super.key});

  @override
  State<SelectPlatformTools> createState() => SelectPlatformToolsState();
}

class SelectPlatformToolsState extends State<SelectPlatformTools> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String?> get platformToolsDir async =>
      (await _prefs).getString("platform-tools");
  void setPlatformToolsDir(String path) async =>
      (await _prefs).setString('platform-tools', path);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: platformToolsDir,
      builder: (context, snapshot) => Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.description),
          style: OutlinedButton.styleFrom(
            shape: const LinearBorder(
              start: LinearBorderEdge(),
              end: LinearBorderEdge(),
              top: LinearBorderEdge(),
              bottom: LinearBorderEdge(),
            ),
          ),
          onPressed: () async {
            if (!context.mounted) return;
            var dir = await FilePicker.platform
                .getDirectoryPath(initialDirectory: snapshot.data);
            if (dir == null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please select the directory of adb executable file',
                  ),
                ),
              );
              return;
            }
            if (dir == null) return;

            setPlatformToolsDir(dir);

            if (dir.isEmpty) return;
            if (context.mounted) {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ControlPanelPage(path: dir),
              ));
            }
          },
          label: const Text("select adb executable"),
        ),
      ),
    );
  }
}

class ControlPanelPage extends StatelessWidget {
  final String path;
  const ControlPanelPage({
    super.key,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LogMessagesCubit()),
        BlocProvider(
          create: (context) => SearchCubit(),
        )
      ],
      child: RepositoryProvider(
        create: (context) => Adb(
          path: path,
          logMessagesCubit: context.read<LogMessagesCubit>(),
        ),
        child: BlocProvider<AdbBloc>(
          create: (context) => AdbBloc(
            context.read<Adb>(),
            context.read<LogMessagesCubit>(),
          ),
          child: const ControlPanel(),
        ),
      ),
    );
  }
}

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * .6,
            child: const AdbForm(),
          ),
          const Divider(thickness: 1, color: Colors.black),
          Expanded(
            child: BlocBuilder<LogMessagesCubit, String>(
              builder: (context, state) => LogWindow(log: state),
            ),
          )
        ],
      ),
      floatingActionButton: BlocBuilder<SearchCubit, Set<PackageInfo>>(
        builder: (context, state) {
          return FloatingActionButton(
            onPressed: () => context.read<AdbBloc>().add(AdbEventListDevices()),
            child: const Icon(Icons.phone_android),
          );
        },
      ),
    );
  }
}

class AdbForm extends StatelessWidget {
  const AdbForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: MediaQuery.of(context).size.width * .5),
        const VerticalDivider(thickness: 1),
        SizedBox(
          width: MediaQuery.of(context).size.width * .47,
          child: BlocBuilder<AdbBloc, AdbState>(
            builder: (context, state) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
                    child: ControlActions(),
                  ),
                  const SizedBox(height: 10),
                  BlocBuilder<SearchCubit, Set<PackageInfo>>(
                    builder: (context, state) {
                      var packages = state.toList();
                      return Expanded(
                        child: ListView.separated(
                          separatorBuilder: (context, index) => const Divider(),
                          itemCount: packages.length,
                          itemBuilder: (context, index) {
                            var package = packages[index];
                            return ListTile(
                              title: Text(package.package),
                              subtitle: Text(package.path),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => context
                                    .read<SearchCubit>()
                                    .removePackage(package),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class ControlActions extends StatelessWidget {
  const ControlActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.search),
          style: OutlinedButton.styleFrom(
            shape: const LinearBorder(
              start: LinearBorderEdge(),
              end: LinearBorderEdge(),
              top: LinearBorderEdge(),
              bottom: LinearBorderEdge(),
            ),
          ),
          onPressed: () async {
            await showSearch<Set<PackageInfo>>(
              context: context,
              delegate: PackageSearchDelegate(
                context.read<AdbBloc>(),
                context.read<SearchCubit>(),
              ),
            );
          },
          label: const Text("search packages"),
        ),
        Row(
          children: [
            BlocBuilder<SearchCubit, Set<PackageInfo>>(
              builder: (context, state) {
                return OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  style: OutlinedButton.styleFrom(
                    shape: const LinearBorder(
                      start: LinearBorderEdge(),
                      end: LinearBorderEdge(),
                      top: LinearBorderEdge(),
                      bottom: LinearBorderEdge(),
                    ),
                  ),
                  onPressed: () => showUninstallDialog(context, state),
                  label: const Text("uninstall packages"),
                );
              },
            ),
            IconButton(
              onPressed: () => context.read<SearchCubit>().clear(),
              icon: const Icon(Icons.clear_all),
              tooltip: "Clear Selected",
            )
          ],
        ),
      ],
    );
  }

  void showUninstallDialog(BuildContext context, Set<PackageInfo> state) {
    var adb = context.read<AdbBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Text(state.map((e) => e.package).join('\n')),
        ),
        title: const Text("Confirm Uninstall Action"),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.delete),
            onPressed: () {
              adb.add(AdbEventUninstallPackages(state));
              Navigator.of(context).pop();
            },
            label: const Text("uninstall"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("don't uninstall"),
          )
        ],
      ),
    );
  }
}
