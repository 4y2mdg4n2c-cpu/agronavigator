import 'package:agronavigator_app/models/xy_point.dart';
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
      version: 4,
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
    if (oldVersion < 3) {
      await db.execute(
        'CREATE TABLE work_points ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'work_id INTEGER NOT NULL, '
        'segment_index INTEGER NOT NULL, '
        'point_index INTEGER NOT NULL, '
        'x REAL NOT NULL, '
        'y REAL NOT NULL'
        ')',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE fields ADD COLUMN origin_lat REAL;');
      await db.execute('ALTER TABLE fields ADD COLUMN origin_lon REAL;');
    }
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE fields ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name TEXT NOT NULL, '
      'origin_lat REAL, '
      'origin_lon REAL'
      ')'
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
    await db.execute(
      'CREATE TABLE work_points ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'work_id INTEGER NOT NULL, '
      'segment_index INTEGER NOT NULL, '
      'point_index INTEGER NOT NULL, '
      'x REAL NOT NULL, '
      'y REAL NOT NULL'
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
    Future<void> saveFieldOrigin(
      int fieldId,
      double latitude,
      double longitude,
    ) async {
      final db = await database;
      await db.update(
        'fields',
        {
          'origin_lat': latitude,
          'origin_lon': longitude,
        },
        where: 'id = ?',
        whereArgs: [fieldId],
      );
    }
    Future<Map<String, double>?> getFieldOrigin(int fieldId) async {
      final db = await database;
      final result = await db.query(
        'fields',
        columns: ['origin_lat', 'origin_lon'],
        where: 'id = ?',
        whereArgs: [fieldId],
        limit: 1,
      );
      if (result.isEmpty ||
          result.first['origin_lat'] == null ||
          result.first['origin_lon'] == null) {
        return null;
      }
      return {
        'latitude': (result.first['origin_lat'] as num).toDouble(),
        'longitude': (result.first['origin_lon'] as num).toDouble(),
      };
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

    Future<List<int>> getWorkIdsForField(int fieldId) async {
      final db = await database;
      final result = await db.query(
        'works',
        columns: ['id'],
        where: 'field_id = ?',
        whereArgs: [fieldId],
        orderBy: 'id ASC',
      );
      return result.map((row) => row['id'] as int).toList();
    }

    Future<void> saveWorkPoints(
      int workId,
      List<List<XYPoint>> tracks,
    ) async {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete(
          'work_points',
          where: 'work_id = ?',
          whereArgs: [workId],
        );

        final batch = txn.batch();
        for (int segmentIndex = 0;
            segmentIndex < tracks.length;
            segmentIndex++) {
          final segment = tracks[segmentIndex];
          for (int pointIndex = 0;
              pointIndex < segment.length;
              pointIndex++) {
            final point = segment[pointIndex];
            batch.insert(
              'work_points',
              {
                'work_id': workId,
                'segment_index': segmentIndex,
                'point_index': pointIndex,
                'x': point.x,
                'y': point.y,
              },
            );
          }
        }
        await batch.commit(noResult: true);
      });
    }

    Future<List<List<XYPoint>>> getWorkPoints(int workId) async {
      final db = await database;
      final rows = await db.query(
        'work_points',
        where: 'work_id = ?',
        whereArgs: [workId],
        orderBy: 'segment_index ASC, point_index ASC',
      );

      final tracks = <List<XYPoint>>[];
      for (final row in rows) {
        final segmentIndex = row['segment_index'] as int;
        while (tracks.length <= segmentIndex) {
          tracks.add([]);
        }
        tracks[segmentIndex].add(
          XYPoint(
            x: (row['x'] as num).toDouble(),
            y: (row['y'] as num).toDouble(),
          ),
        );
      }
      return tracks;
    }

    
}
