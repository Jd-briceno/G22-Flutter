import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:melodymuse/pages/final_detail_page.dart';
import 'package:melodymuse/pages/home_screen.dart';
import 'package:melodymuse/pages/complete_profile_page.dart';
import 'package:melodymuse/pages/login-screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Retorna un estado del perfil del usuario
  Future<String> _checkUserState(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      return "noProfile"; // → CompleteProfilePage
    }

    final data = doc.data() ?? {};
    if (!data.containsKey("nickname")) {
      return "incomplete"; // → FinalDetailsPage
    }

    return "complete"; // → HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MelodyMuse',
      theme: ThemeData.dark(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) return LoginPage();

          return FutureBuilder<String>(
            future: _checkUserState(user),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final state = snap.data ?? "noProfile";

              switch (state) {
                case "noProfile":
                  return CompleteProfilePage(user: user);
                case "incomplete":
                  return FinalDetailsPage(user: user);
                case "complete":
                default:
                  return const HomeScreen();
              }
            },
          );
        },
      ),
    );
  }
}
