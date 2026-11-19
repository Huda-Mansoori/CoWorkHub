import 'package:flutter/material.dart';

import 'screens/dashboard.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final String? apiBase;

  const MyApp({super.key, this.apiBase});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoWorkHub',
      theme: buildAppTheme(),
      home: Dashboard(apiBase: apiBase),
    );
  }
}
