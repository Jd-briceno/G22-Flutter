import 'dart:io';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 🔹 Inicialización del sistema de notificaciones
  Future<void> init() async {
    final platform = Platform.operatingSystem;
    print('🔧 NotificationService.init() en $platform');

    // Evita que se ejecute si Flutter no está listo
    if (!Platform.isAndroid && !Platform.isIOS) {
      print('ℹ️ Plataforma $platform sin soporte para notificaciones locales, se omite init.');
      return;
    }

    // ⚙️ Configuración Android
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 🍏 Configuración iOS
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // 👈 importante: pedimos manualmente después
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    try {
      await _notificationsPlugin.initialize(initSettings);
      print('✅ FlutterLocalNotificationsPlugin.initialize completado.');
    } catch (e, st) {
      print('❌ Error al inicializar FlutterLocalNotificationsPlugin: $e\n$st');
      rethrow;
    }

    // 🟢 Solicitar permisos después (de forma segura)
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        if (Platform.isAndroid) {
          final status = await Permission.notification.status;
          print('🔔 Estado permiso notificaciones (Android): $status');
          if (status.isDenied) {
            final result = await Permission.notification.request();
            print('🔔 Resultado solicitud permiso notificaciones: $result');
          }
        } else if (Platform.isIOS) {
          final iosPlugin = _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();
          final granted = await iosPlugin?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
              false;
          print('🔔 Permisos de notificaciones solicitados en iOS. concedidos=$granted');
        }
      } catch (e, st) {
        print('❌ Error solicitando permisos de notificaciones: $e\n$st');
      }
    });
  }

  /// 🔸 Notificación genérica (para alertas, recordatorios, etc.)
  Future<void> showNotification({
    required String title,
    required String body,
    String? channelId,
    String? channelName,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId ?? 'general_channel',
      channelName ?? 'General Notifications',
      channelDescription: 'Notificaciones generales de la app 🎵',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: const Color(0xFF00FF99),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID único
      title,
      body,
      details,
    );
  }

  /// 🏆 Notificación específica para logros (Achievements)
  Future<void> showAchievementNotification({
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidDetails =
        const AndroidNotificationDetails(
      'achievements_channel',
      'Achievements',
      channelDescription: 'Notificaciones de logros musicales 🎶',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: Color(0xFF00FF99),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
