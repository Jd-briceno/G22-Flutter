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
import 'package:melodymuse/database/local_db.dart';
import 'package:melodymuse/services/hive_service.dart';
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
  // Inicializa almacenamiento local (Hive + SQLite)
  await HiveService.init();
  await LocalDB.database;
  print("💾 Hive y SQLite inicializados correctamente.");

  print("🕒 Esperando restauración de sesión de FirebaseAuth...");
  // 👇 Espera a que FirebaseAuth restaure sesión antes de arrancar la app
  await FirebaseAuth.instance.authStateChanges().firstWhere((_) => true);
  print("✅ Sesión restaurada o confirmada.");

  runZonedGuarded(() async {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint("📡 authStateChanges emitió nuevo valor (desde listener global): $user");
    });

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
    print("🔍 Verificando estado del usuario ${user.uid}...");
    final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

    for (int i = 0; i < 5; i++) {
      try {
        final doc = await docRef.get(const GetOptions(source: Source.server));
        if (doc.exists) {
          final data = doc.data() ?? {};
          print("📦 Datos Firestore del usuario: $data");

          final stage = data['profileStage'] ?? 'created';
          final hasNickname =
              data.containsKey("nickname") && (data["nickname"] as String?)?.isNotEmpty == true;
          final hasInterests =
              data.containsKey("interests") && (data["interests"] as List).isNotEmpty;

          if (stage == 'created' || !hasInterests) {
            return "noProfile"; // → CompleteProfilePage
          }
          if (!hasNickname) {
            return "incomplete"; // → FinalDetailsPage
          }
          return "complete"; // → HomeScreen
        } else {
          print("⚠️ Intento ${i + 1}: documento aún no existe en Firestore...");
        }
      } catch (e, st) {
        print("🔥 Error al leer usuario (intento ${i + 1}): $e\n$st");
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    print("⏰ No se encontró documento tras varios intentos → noProfile");
    return "noProfile";
  }



  @override
  Widget build(BuildContext context) {
    print("🧩 Construyendo MyApp...");

    return ChangeNotifierProvider.value(
      value: PlaybackManagerService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MelodyMuse',
        theme: ThemeData.dark(),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: analytics),
        ],
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            debugPrint("📡 [StreamBuilder] snapshot.connectionState = ${snapshot.connectionState}");
            debugPrint("📡 [StreamBuilder] snapshot.hasData = ${snapshot.hasData}");
            debugPrint("📡 [StreamBuilder] snapshot.data = ${snapshot.data}");
            debugPrint("👀 [DEBUG] snapshot.data: ${snapshot.data}");
            if (snapshot.connectionState == ConnectionState.waiting) {
              print("⏳ Esperando conexión de FirebaseAuth...");
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = snapshot.data;

            if (user == null) {
              print("👤 Usuario no autenticado → Mostrando LoginPage");
              return const LoginPage();
            }

            print("✅ Usuario autenticado detectado: ${user.email} (${user.uid})");

            return FutureBuilder<String>(
              future: _checkUserState(user),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  print("⏳ Esperando Firestore para usuario ${user.uid}...");
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snap.hasError) {
                  print("❌ Error en FutureBuilder: ${snap.error}");
                  return const Scaffold(
                    body: Center(child: Text("Error cargando usuario")),
                  );
                }

                print("🧭 Resultado del _checkUserState: ${snap.data}");

                switch (snap.data) {
                  case "noProfile":
                    return CompleteProfilePage(user: user);
                  case "incomplete":
                    return FinalDetailsPage(user: user);
                  case "complete":
                    return const HomeScreen();
                  default:
                    return const Scaffold(
                      body: Center(child: Text("Error: estado desconocido")),
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
