import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../Models/word.dart';

class DatabaseHelper {
  static final _databaseName = "yugtalk.db";
  static final _databaseVersion = 1;

  static final table = 'word';

  static final columnId = 'wordID';
  static final columnName = 'wordName';
  static final columnDesc = 'wordDesc';
  static final columnImage = 'wordImage';
  static final columnAudio = 'wordAudio';
  static final columnVideo = 'wordVideo';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper sad = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    // if _database is null we instantiate it
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    String path = join(await getDatabasesPath(), _databaseName);
    try {
      _database = await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
      print('Database created successfully');
    } catch (e) {
      print('Error creating database: $e');
      // Handle error here
    }
    return _database!;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('DROP TABLE IF EXISTS $table');

    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnName TEXT NOT NULL,
            $columnDesc TEXT NOT NULL,
            $columnImage BLOB NOT NULL,
            $columnAudio TEXT NOT NULL,
            $columnVideo TEXT NOT NULL
          )
          ''');
  }

  Future<void> insertWords(List<Word> words) async {
    final db = await database;

    // Insert each word into the database
    for (final word in words) {
      await db.insert(
        'word',
        word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Word>> getAllWords() async {
    Database db = await sad.database;
    List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return Word(
        wordID: maps[i][columnId],
        wordName: maps[i][columnName],
        wordDesc: maps[i][columnDesc],
        wordImage: maps[i][columnImage],
        wordAudio: maps[i][columnAudio],
        wordVideo: maps[i][columnVideo],
      );
    });
  }

  Future<int> deleteWord(int id) async {
    Database db = await sad.database;
    return await db.delete(
      table,
      where: "$columnId = ?",
      whereArgs: [id],
    );
  }

  Future close() async {
    Database db = await sad.database;
    db.close();
  }

    /*Future<void> getDummyData() async {
      List<Word> dummyWords = [
        Word(
          wordID: "12",
          wordName: 'Dummy Word 1',
          wordDesc: 'This is a dummy word 1',
          wordImage: '',
          wordAudio: 'dummy_audio_1.mp3',
          wordVideo: 'dummy_video_1.mp4',
        ),
        Word(
          wordID: "11",
          wordName: 'Dummy Word 2',
          wordDesc: 'This is a dummy word 2',
          wordImage: '',
          wordAudio: 'dummy_audio_2.mp3',
          wordVideo: 'dummy_video_2.mp4',
        ),
        // Add more dummy words if needed
      ];

      await insertWords(dummyWords); // Insert the dummy words into the database
    }*/

}