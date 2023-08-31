import 'package:app_uninstaller/adb/services/adb_service.dart';
import 'package:app_uninstaller/log/cubit/log_messages_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'log/view/log_window.dart';

String BIN = '/home/user/.local/opt/Android/platform-tools/';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => LogMessagesCubit()),
        ],
        child: RepositoryProvider(
          create: (context) => Adb(
            path: BIN,
            logMessagesCubit: context.read<LogMessagesCubit>(),
          ),
          child: const MainPage(),
        ),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .48),
          const Divider(height: 5),
          SizedBox(
            height: MediaQuery.of(context).size.height * .5,
            child: BlocBuilder<LogMessagesCubit, String>(
              builder: (context, state) => LogWindow(log: state),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<Adb>().listPackages(),
        child: const Icon(Icons.restart_alt),
      ),
    );
  }
}
