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
      version: 2,
      onCreate: _onCreate, // Вызывается один раз при первом создании базы.
      onUpgrade: _onUpgrade,
    );
  }
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'CREATE TABLE works ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'field_id INTEGER NOT NULL, '
        'area REAL NOT NULL, '
        'distance REAL NOT NULL, '
        'working_width REAL NOT NULL'
        ')',
      );
    }
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE fields (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)'
    );
    await db.execute(
      'CREATE TABLE works ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'field_id INTEGER NOT NULL, '
      'area REAL NOT NULL, '
      'distance REAL NOT NULL, '
      'working_width REAL NOT NULL'
      ')'
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
    Future<String?> getFieldName(int id) async {
      final db = await database;
      final result = await db.query(
        'fields',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isEmpty) {
        return null;
      }
      return result.first['name'] as String?;
    }
    Future<double> getSavedAreaForField(int fieldId) async {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(area), 0) AS total_area '
        'FROM works WHERE field_id = ?',
        [fieldId],
      );
      return (result.first['total_area'] as num).toDouble();
    }
    Future<int> deleteField(int id) async { // Удаляет поле по id
      final db = await database;
      return await db.delete(
        'fields',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    Future<int> createWork({
      required int fieldId,
      required double area,
      required double distance,
      required double workingWidth,
    }) async {
      final db = await database;
      return await db.insert(
        'works',
        {
          'field_id': fieldId,
          'area': area,
          'distance': distance,
          'working_width': workingWidth
        },
      );
    }

    
}
