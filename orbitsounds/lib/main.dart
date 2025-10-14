import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'firebase_options.dart';

// 🔹 Provider y servicios
import 'package:provider/provider.dart';
import 'package:melodymuse/services/playback_manager_service.dart';
import 'package:melodymuse/services/notification_service.dart';

// 🔹 Páginas
import 'package:melodymuse/pages/final_detail_page.dart';
import 'package:melodymuse/pages/home_screen.dart';
import 'package:melodymuse/pages/complete_profile_page.dart';
import 'package:melodymuse/pages/login-screen.dart';

// 🔹 Instancia global de Analytics
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 Iniciando MelodyMuse main()');

  try {
    await dotenv.load(fileName: ".env");
    print('📄 Variables de entorno cargadas correctamente.');
  } catch (e, st) {
    print('⚠️ Error cargando el archivo .env: $e\n$st');
  }

  _setupGlobalErrorHandlers();
  await _ensureFirebase();

  runZonedGuarded(() async {
    print('🧠 Entrando en runZonedGuarded -> runApp');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notificationService = NotificationService();
      try {
        print('📣 Inicializando NotificationService...');
        await notificationService.init();
        print('🔔 Notificaciones listas tras frame inicial.');
      } catch (e, st) {
        print('❌ Error inicializando NotificationService: $e\n$st');
      }
    });

    runApp(const MyApp());
  }, (error, stack) {
    print('❌ Error global no capturado: $error\n$stack');
  });
}

RawReceivePort? _isolateErrorPort;

void _setupGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    print('🐞 FlutterError capturado: ${details.exception}');
    if (details.stack != null) print(details.stack);
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    print('🚨 platformDispatcher detectó un error: $error\n$stack');
    return true;
  };

  _isolateErrorPort ??= RawReceivePort((dynamic data) {
    if (data is List && data.length == 2) {
      print('🧵 Error en isolate secundario: ${data[0]}');
      print(data[1]);
    } else {
      print('🧵 Error crudo de isolate: $data');
    }
  });

  Isolate.current.addErrorListener(_isolateErrorPort!.sendPort);
}

Future<void> _ensureFirebase() async {
  try {
    print('🔁 Firebase.apps detectadas al entrar: ${Firebase.apps.length}');
    if (Firebase.apps.isNotEmpty) {
      print("🟢 Firebase ya estaba inicializado.");
      return;
    }

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      print('🍎 Inicializando Firebase con configuración nativa.');
      await Firebase.initializeApp();
    } else {
      print('🤖 Inicializando Firebase con DefaultFirebaseOptions.');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    print("✅ Firebase inicializado correctamente.");
  } on FirebaseException catch (e, st) {
    if (e.code == 'duplicate-app') {
      print("ℹ️ Firebase ya estaba configurado nativamente, reutilizando instancia.");
    } else {
      print("🔥 FirebaseException al inicializar: ${e.code} ${e.message}\n$st");
    }
  } catch (e, st) {
    print("🔥 Error inesperado al inicializar Firebase: $e\n$st");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> _checkUserState(User user) async {
    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    if (!doc.exists) return "noProfile";
    final data = doc.data() ?? {};
    if (!data.containsKey("nickname")) return "incomplete";
    return "complete";
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: PlaybackManagerService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MelodyMuse',
        theme: ThemeData.dark(),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics), // 👈 importante para screen_view
        ],
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

                switch (snap.data) {
                  case "noProfile":
                    return CompleteProfilePage(user: user);
                  case "incomplete":
                    return FinalDetailsPage(user: user);
                  default:
                    return const HomeScreen();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
