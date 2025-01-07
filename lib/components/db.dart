import "package:path/path.dart";
import "package:sqflite/sqflite.dart";

class DBMS {
  static var db;

  Future<void> init() async {
    db = openDatabase(join(await getDatabasesPath(), 'doggie_database.db'),
        onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
      );
    }, version: 1);
  }
}

class Dog {
  final int id;
  final String name;
  final int age;

  const Dog({
    required this.id,
    required this.name,
    required this.age,
  });
}
