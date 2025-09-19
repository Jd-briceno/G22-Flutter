import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:orbitsounds/pages/home_screen.dart';
import 'package:orbitsounds/pages/testsvgpage.dart';

Future<void> main() async {
  // Load .env before running the app
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MelodyMuse',
      theme: ThemeData.dark(),
      home: const HomeScreen()
    );
  }
}

