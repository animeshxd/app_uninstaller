import 'package:flutter/material.dart';

class LogWindow extends StatelessWidget {
  final String log;
  const LogWindow({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SelectableText(
        log,
        textAlign: TextAlign.left,
      ),
    );
  }
}
