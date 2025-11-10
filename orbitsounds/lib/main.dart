import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// ViewModels
import 'viewmodels/playback_manager_viewmodel.dart';

// Services
import 'services/local_db_service.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';

// Views
import 'views/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Habilita UI de borde a borde para TODAS las vistas
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 1. Carga de variables de entorno
  await dotenv.load(fileName: ".env");

  // 2. Inicializa Firebase
  await _ensureFirebase();

  // 3. Inicializa servicios locales
  await _warmUpServices();

  // 4. Arranque de la app
  runApp(const MyApp());
}

Future<void> _ensureFirebase() async {
  try {
    debugPrint('🔁 Firebase.apps detectadas: ${Firebase.apps.length}');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase inicializado correctamente');
    } else {
      debugPrint('🟢 Firebase ya estaba inicializado');
    }
  } on FirebaseException catch (e) {
    debugPrint('🔥 FirebaseException: ${e.code} ${e.message}');
  } catch (e) {
    debugPrint('🔥 Error al inicializar Firebase: $e');
  }
}

Future<void> _warmUpServices() async {
  try {
    await HiveService.init();
    debugPrint('📦 HiveService inicializado');
  } catch (e, st) {
    debugPrint('⚠️ HiveService.init() falló: $e\n$st');
  }

  try {
    await LocalDbService.database;
    debugPrint('🗄️ LocalDbService.database inicializado');
  } catch (e, st) {
    debugPrint('⚠️ LocalDbService.database falló: $e\n$st');
  }

  try {
    await NotificationService().init();
    debugPrint('🔔 NotificationService inicializado');
  } catch (e, st) {
    debugPrint('⚠️ NotificationService.init() falló: $e\n$st');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaybackManagerViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OrbitSounds',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'EncodeSans',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
        ),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          // Conserva un pequeño padding superior/inferior (como margen visual)
          return MediaQuery(
            data: mq.copyWith(
              padding: EdgeInsets.only(
                top: mq.padding.top * 0.5,
                bottom: mq.padding.bottom * 0.5,
              ),
            ),
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}