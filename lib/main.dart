import 'dart:async';
import 'dart:math';

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

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final routes = <String, Widget Function(BuildContext)>{
    "/": (context) => const MainPage(),
  };

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeData.copyWith(
        progressIndicatorTheme:
            themeData.progressIndicatorTheme.copyWith(year2023: false),
      ),
      home: const NewApp(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NewApp();
  }
}

class NewApp extends StatefulWidget {
  const NewApp({super.key});

  @override
  State<NewApp> createState() => _NewAppState();
}

class _NewAppState extends State<NewApp> {
  bool isEntended = false;
  int selectedIndex = 0;
  List<Widget> screens = [
    const ApplicationListPage(),
    const DevicesPage(),
    const UninstallPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(scrolledUnderElevation: 0, forceMaterialTransparency: true),
      body: Row(
        children: [
          NavigationRail(
            extended: isEntended,
            destinations: [
              // NavigationsRailDestination(
              //   icon: Icon(Icons.add),
              //   label: Text("New Devices"),
              // ),
              const NavigationRailDestination(
                icon: Icon(Icons.android),
                label: Text("Apps"),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.device_hub_sharp),
                label: Text("Devices"),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text("Settings"),
              ),
            ],
            selectedIndex: selectedIndex,
            leading: const SizedBox(
              height: 30,
            ),
            onDestinationSelected: (value) =>
                setState(() => selectedIndex = value),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(30),
              ),
              child: screens[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class Application {
  final String packageName;
  final String packagePath;
  final Color iconColor;

  Application(this.packageName, this.iconColor, this.packagePath);
}

// Helper to generate a deterministic random color by package, so "random" is stable on hot reload
Color packageColor(String package) {
  final random = Random(package.hashCode);
  return Color.fromARGB(
    255,
    1 + random.nextInt(254),
    1 + random.nextInt(100),
    1 + random.nextInt(50),
  );
}

class ApplicationList extends StatelessWidget {
  final List<Application> apps;
  final Set<String> selectedPackageNames;
  final void Function(String packageName, bool selected) onSelect;

  const ApplicationList({
    super.key,
    required this.apps,
    required this.selectedPackageNames,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final app = apps[index];
        final selected = selectedPackageNames.contains(app.packageName);

        return InkWell(
          onTap: () => onSelect(app.packageName, !selected),
          borderRadius: BorderRadius.circular(8),
          hoverColor: colorScheme.surfaceTint.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.secondaryContainer
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? colorScheme.secondary
                    : colorScheme.outlineVariant,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.android, color: app.iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.packageName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        app.packagePath,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: selected,
                  onChanged: (checked) =>
                      onSelect(app.packageName, checked ?? false),
                  visualDensity: VisualDensity.compact,
                  activeColor: colorScheme.primary,
                  checkColor: colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ApplicationListPage extends StatefulWidget {
  const ApplicationListPage({super.key});

  @override
  State<ApplicationListPage> createState() => _ApplicationListPageState();
}

class _ApplicationListPageState extends State<ApplicationListPage> {
  final List<Application> _apps = [
    Application(
      'com.google.android.gm',
      packageColor('com.google.android.gm'),
      '/data/app/com.google.android.gm-1/base.apk',
    ),
    Application(
      'com.facebook.katana',
      packageColor('com.facebook.katana'),
      '/data/app/com.facebook.katana-1/base.apk',
    ),
    Application(
      'com.instagram.android',
      packageColor('com.instagram.android'),
      '/data/app/com.instagram.android-1/base.apk',
    ),
    Application(
      'com.whatsapp',
      packageColor('com.whatsapp'),
      '/data/app/com.whatsapp-1/base.apk',
    ),
    Application(
      'com.whatsapp',
      packageColor('com.whatsapp'),
      '/data/app/com.whatsapp-1/base.apk',
    ),
    Application(
      'com.netflix.mediaclient',
      packageColor('com.netflix.mediaclient'),
      '/data/app/com.netflix.mediaclient-1/base.apk',
    ),
    Application(
      'com.spotify.music',
      packageColor('com.spotify.music'),
      '/data/app/com.spotify.music-1/base.apk',
    ),
    Application(
      'com.google.android.youtube',
      packageColor('com.google.android.youtube'),
      '/data/app/com.google.android.youtube-1/base.apk',
    ),
    Application(
      'us.zoom.videomeetings',
      packageColor('us.zoom.videomeetings'),
      '/data/app/us.zoom.videomeetings-1/base.apk',
    ),
  ];

  final Set<String> _selected = {};

  void _toggleSelected(String package, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(package);
      } else {
        _selected.remove(package);
      }
    });
  }

  List<Application> get _filteredApps {
    final query = _textEditingController.text.toLowerCase();
    if (query.isEmpty) return _apps;
    return _apps.where((app) {
      return app.packageName.toLowerCase().contains(query) ||
          app.packagePath.toLowerCase().contains(query);
    }).toList();
  }

  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        toolbarHeight: 72,
        titleSpacing: 16,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _textEditingController,
            onChanged: (v) => setState(() => {}),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Search packages...',
              prefixIcon: Icon(Icons.search, size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _textEditingController.text = "";
            }),
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                PopupMenuButton<int>(
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 0, child: Text('user 0')),
                    PopupMenuItem(value: 1, child: Text('user 1')),
                    PopupMenuItem(value: 2, child: Text('user 2')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('user 0'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {},
              label: Text('Uninstall (${_selected.length})'),
              icon: const Icon(Icons.delete_forever_rounded),
              backgroundColor: colorScheme.errorContainer,
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: ApplicationList(
              apps: _filteredApps,
              selectedPackageNames: _selected,
              onSelect: _toggleSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class UninstallPage extends StatelessWidget {
  const UninstallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: const BulkUninstallStatusPage(),
    );
  }
}

class BulkUninstallStatusPage extends StatefulWidget {
  const BulkUninstallStatusPage({super.key});

  @override
  State<BulkUninstallStatusPage> createState() =>
      _BulkUninstallStatusPageState();
}

class _BulkUninstallStatusPageState extends State<BulkUninstallStatusPage> {
  final List<_UninstallLogEntry> _logs = [
    _UninstallLogEntry('com.example.browser', true),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.social.chatapp', false),
    _UninstallLogEntry('com.media.videoplayer', true),
    _UninstallLogEntry('com.gaming.arcade', true),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.failed.example', false),
    _UninstallLogEntry('com.mock.app1', true),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
    _UninstallLogEntry('com.mock.app2', false),
  ];

  Stream<_UninstallLogEntry> delayedStream() async* {
    for (var l in _logs) {
      await Future.delayed(const Duration(seconds: 1));
      if (scrollController.positions.isNotEmpty) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
      yield l;
    }
  }

  final scrollController = ScrollController();
  late Stream<_UninstallLogEntry> stream;

  @override
  void initState() {
    super.initState();
    stream = delayedStream().asBroadcastStream();
  }

  int completed = 0; // For mock, assume done
  @override
  Widget build(BuildContext context) {
    final int total = _logs.length;

    String logText = "";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder(
            stream: stream,
            builder: (context, asyncSnapshot) {
              completed += 1;
              return LinearProgressIndicator(value: completed / total);
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: stream,
            builder: (context, asyncSnapshot) {
              return Text(
                'Progress: $completed of $total completed',
                style: Theme.of(context).textTheme.bodyLarge,
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Logs:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: StreamBuilder(
                  stream: stream,
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.hasData) {
                      logText += "${asyncSnapshot.data}\n";
                    }
                    return SelectableText(
                      logText,
                      style: const TextStyle(fontFamily: 'monospace'),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UninstallLogEntry {
  final String packageName;
  final bool success;

  _UninstallLogEntry(this.packageName, this.success);

  @override
  String toString() {
    final status = success ? '[OK]     ' : '[FAILED] ';
    return '$status$packageName';
  }
}

class DevicesPage extends StatelessWidget {
  final List<String> mockDevices = const [
    'Pixel 7 Pro (192.168.1.23)',
    'Galaxy Tab S6 (192.168.1.42)',
    'Linux Workstation (192.168.1.88)',
    'Windows Laptop (192.168.1.91)',
  ];

  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Discover Devices',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: mockDevices.length,
        itemBuilder: (context, index) {
          final device = mockDevices[index];
          return Card(
            elevation: 0.8,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: colorScheme.surface,
            child: ListTile(
              leading: Icon(
                Icons.phonelink,
                color: colorScheme.primary,
              ),
              title: Text(
                device,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Connect'),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // trigger discovery
        },
        label: const Text('Discover Devices'),
        icon: const Icon(Icons.wifi_tethering),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
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
            final dir = await FilePicker.platform
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
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ControlPanelPage(path: dir),
                ),
              );
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
        ),
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
            child: MainControlWindow(),
          ),
          const Divider(thickness: 1, color: Colors.black),
          Expanded(
            child: BlocBuilder<LogMessagesCubit, String>(
              builder: (context, state) => LogWindow(log: state),
            ),
          ),
        ],
      ),
    );
  }
}

class MainControlWindow extends StatelessWidget {
  MainControlWindow({super.key});
  final _textController = TextEditingController(text: "adb devices");
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * .5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .4,
                    child: TextField(
                      autofocus: true,
                      controller: _textController,
                      onSubmitted: (value) =>
                          onExecuteArgsSubmitted(context, value),
                    ),
                  ),
                  IconButton(
                    tooltip: "execute",
                    onPressed: () => onExecuteArgsSubmitted(
                      context,
                      _textController.text.trim(),
                    ),
                    icon: const Icon(Icons.send_time_extension),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * .4,
                child: SingleChildScrollView(
                  child: BlocBuilder<AdbBloc, AdbState>(
                    buildWhen: (previous, current) =>
                        current is AdbExecuteLogResult,
                    builder: (context, state) {
                      if (state is AdbExecuteLogResult) {
                        return SelectableText(
                          state.log,
                          style: state.hasError
                              ? const TextStyle(color: Colors.red)
                              : null,
                        );
                      }
                      return Container();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
                      final packages = state.toList();
                      return Expanded(
                        child: ListView.separated(
                          separatorBuilder: (context, index) => const Divider(),
                          itemCount: packages.length,
                          itemBuilder: (context, index) {
                            final package = packages[index];
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
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void onExecuteArgsSubmitted(BuildContext context, String value) {
    final args = value.trim();
    if (args.isEmpty) return;
    if (args == "shell" || args == "adb shell") {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("adb shell stdin is not supported"),
          ),
        );
        return;
      }
    }
    context.read<AdbBloc>().add(AdbEventExecuteCommand(args));
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
            ),
          ],
        ),
      ],
    );
  }

  void showUninstallDialog(BuildContext context, Set<PackageInfo> state) {
    final adb = context.read<AdbBloc>();
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
          ),
        ],
      ),
    );
  }
}
