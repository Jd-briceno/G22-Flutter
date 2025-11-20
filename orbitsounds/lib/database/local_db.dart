import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('melodymuse.db');
    return _db!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print("📀 Creando base de datos local SQLite...");

        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_profile (
            id TEXT PRIMARY KEY,
            fullName TEXT,
            nickname TEXT,
            description TEXT,
            gender TEXT,
            nationality TEXT,
            imagePath TEXT
          )
        ''');
      },
    );
  }

  static Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    final db = await database;
    await db.insert(
      'user_profile',
      {
        'id': userData['id'] ?? '',
        'fullName': userData['fullName'] ?? '',
        'nickname': userData['nickname'] ?? '',
        'description': userData['description'] ?? '',
        'gender': userData['gender'] ?? '',
        'nationality': userData['nationality'] ?? '',
        'imagePath': userData['imagePath'] ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print("💾 Perfil guardado en SQLite correctamente para ${userData['id']}");
  }
}
