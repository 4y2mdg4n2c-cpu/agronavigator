import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Один общий экземпляр DatabaseHelper для всего приложения.
  static final DatabaseHelper instance = DatabaseHelper._internal();
  // Приватный конструктор. Не даёт создавать DatabaseHelper обычным способом.
  DatabaseHelper._internal();

   // Здесь будет храниться открытая SQLite-база.
  // null означает, что база ещё не была открыта.
  Database? _database;
  Future<Database> get database async { // Возвращает открытую базу данных.
    if (_database != null) { // Если база уже была открыта — просто возвращаем её.
      return _database!;
    }
    _database = await _initDatabase(); // Если базы ещё нет — открываем её и сохраняем в _database.
    return _database!; // Возвращаем открытую базу.
  }
  Future<Database> _initDatabase() async { // Создает или открывает файл базы данных.
    final databasePath = await getDatabasesPath(); // Получаем системную папку, где приложение хранит базы данных.
    final path = join(databasePath, 'agronavigator.db'); // Добавляем к пути имя файла базы данных.
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate, // Вызывается один раз при первом создании базы.
    );
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE fields (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)'
    );
  }
  Future<int> createField(String name) async {
    final db = await database;
    return await db.insert(
      'fields',
      {'name': name}
    );
  }
    Future<List<Map<String, dynamic>>> getFields() async {
      final db = await database; // Получаем открытую базу даных
      return await db.query('fields'); // Возвращаем все записи из таблицы fields
    }
}