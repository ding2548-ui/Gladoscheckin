import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const GladosApp());
}

class GladosApp extends StatelessWidget {
  const GladosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GLaDOS 签到',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6D00),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6D00),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
