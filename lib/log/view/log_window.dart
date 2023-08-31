import 'package:flutter/material.dart';

class LogWindow extends StatefulWidget {
  final String log;
  const LogWindow({super.key, required this.log});

  @override
  State<LogWindow> createState() => _LogWindowState();
}

class _LogWindowState extends State<LogWindow> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Text(widget.log));
  }
}
