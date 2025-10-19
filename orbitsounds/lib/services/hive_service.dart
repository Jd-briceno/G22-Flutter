import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('settings');
  }

  static Box get box => Hive.box('settings');

  static void setRememberMe(bool value) => box.put('rememberMe', value);

  static bool getRememberMe() => box.get('rememberMe', defaultValue: false);

  static void setThemeMode(bool darkMode) => box.put('darkMode', darkMode);

  static bool isDarkMode() => box.get('darkMode', defaultValue: false);
}
