import "package:path/path.dart";
import "package:sqflite/sqflite.dart";

class DBMS {
  Database? _db;

  Future<Database> init() async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'wawehead.db'),
      onCreate: (db, version) async {
        // Create the `songs` table
        await db.execute(
          'CREATE TABLE songs(id INTEGER PRIMARY KEY, name TEXT, year INTEGER)',
        );

        // Create the `favourites` table
        await db.execute(
          'CREATE TABLE favourites(song_id INTEGER PRIMARY KEY, is_favorite INTEGER, '
              'FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE)',
        );
      },
      version: 1,
    );
    return _db!;
  }

  // Insert a song into the `songs` table
  Future<void> insertSong(Song song) async {
    final db = await init();
    await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Add a song to `favourites` or update its status
  Future<void> setFavoriteStatus(int songId, bool isFavorite) async {
    final db = await init();
    await db.insert(
      'favourites',
      {'song_id': songId, 'is_favorite': isFavorite ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all favorite songs
  Future<List<Song>> getFavoriteSongs() async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT songs.id, songs.name, songs.year 
      FROM songs
      INNER JOIN favourites ON songs.id = favourites.song_id
      WHERE favourites.is_favorite = 1
    ''');

    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'],
        name: maps[i]['name'],
        year: maps[i]['year'],
      );
    });
  }

  // Get all songs from the `songs` table
  Future<List<Song>> getSongs() async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.query('songs');

    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'],
        name: maps[i]['name'],
        year: maps[i]['year'],
      );
    });
  }

  // Delete a song from the `songs` table
  Future<void> deleteSong(int id) async {
    final db = await init();
    await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update a song in the `songs` table
  Future<void> updateSong(Song song) async {
    final db = await init();
    await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }
}

class Song {
  final int id;
  final String name;
  final int year;

  Song({
    required this.id,
    required this.name,
    required this.year,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'year': year,
    };
  }

  @override
  String toString() {
    return 'Song{id: $id, name: $name, year: $year}';
  }
}
