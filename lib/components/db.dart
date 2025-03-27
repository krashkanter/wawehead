import "package:path/path.dart";
import "package:sqflite/sqflite.dart";
import "package:wawehead/components/metadata.dart";

class DBMS {
  Database? _db;

  Future<Database> init() async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'wawehead.db'),
      onCreate: (db, version) async {
        // Create Artists table
        await db.execute('''
          CREATE TABLE artists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            image_path TEXT
          )
        ''');

        // Create Albums table
        await db.execute('''
          CREATE TABLE albums(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist_id INTEGER,
            year INTEGER,
            cover_art_path TEXT,
            FOREIGN KEY (artist_id) REFERENCES artists(id)
          )
        ''');

        // Create songs table with expanded fields
        await db.execute('''
          CREATE TABLE songs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist_id INTEGER,
            album_id INTEGER,
            duration INTEGER NOT NULL, 
            path TEXT NOT NULL,
            size INTEGER,
            date_added INTEGER,
            play_count INTEGER DEFAULT 0,
            FOREIGN KEY (artist_id) REFERENCES artists(id),
            FOREIGN KEY (album_id) REFERENCES albums(id)
          )
        ''');

        // Create favourites table
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id INTEGER NOT NULL,
            date_added INTEGER NOT NULL,
            FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
          )
        ''');

        // Create playlists table
        await db.execute('''
          CREATE TABLE playlists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            date_created INTEGER,
            date_modified INTEGER,
            cover_image TEXT
          )
        ''');

        // Create playlist_songs table
        await db.execute('''
          CREATE TABLE playlist_songs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_id INTEGER NOT NULL,
            song_id INTEGER NOT NULL,
            position INTEGER NOT NULL,
            date_added INTEGER,
            FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
            FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
          )
        ''');

        // Create recently_played table
        await db.execute('''
          CREATE TABLE recently_played(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
          )
        ''');

        // Create settings table
        await db.execute('''
          CREATE TABLE settings(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            theme TEXT DEFAULT 'light',
            equalizer_settings TEXT,
            crossfade_duration INTEGER DEFAULT 0,
            gapless_playback INTEGER DEFAULT 0,
            last_played_song_id INTEGER,
            last_position INTEGER,
            FOREIGN KEY (last_played_song_id) REFERENCES songs(id)
          )
        ''');
      },
      version: 1,
    );
    return _db!;
  }

  // SONG OPERATIONS
  Future<int> insertSong(Song song) async {
    final db = await init();
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Song>> getSongs() async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.query('songs');
    return List.generate(maps.length, (i) => Song.fromMap(maps[i]));
  }

  Future<Song?> getSong(int id) async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Song.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateSong(Song song) async {
    final db = await init();
    await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  Future<void> deleteSong(int id) async {
    final db = await init();
    await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // FAVORITES OPERATIONS
  Future<void> addToFavorites(int songId) async {
    final db = await init();
    await db.insert(
      'favorites',
      {
        'song_id': songId,
        'date_added': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFromFavorites(int songId) async {
    final db = await init();
    await db.delete(
      'favorites',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
  }

  Future<bool> isFavorite(int songId) async {
    final db = await init();
    final result = await db.query(
      'favorites',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    return result.isNotEmpty;
  }

  Future<List<Song>> getFavoriteSongs() async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN favorites f ON s.id = f.song_id
      ORDER BY f.date_added DESC
    ''');

    return List.generate(maps.length, (i) => Song.fromMap(maps[i]));
  }

  // ARTIST OPERATIONS
  Future<int> insertArtist(Artist artist) async {
    final db = await init();
    return await db.insert(
      'artists',
      artist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Artist>> getArtists() async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.query('artists');
    return List.generate(maps.length, (i) => Artist.fromMap(maps[i]));
  }

  // ALBUM OPERATIONS
  Future<int> insertAlbum(Album album) async {
    final db = await init();
    return await db.insert(
      'albums',
      album.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Album>> getAlbums() async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.query('albums');
    return List.generate(maps.length, (i) => Album.fromMap(maps[i]));
  }

  // PLAYLIST OPERATIONS
  Future<int> createPlaylist(Playlist playlist) async {
    final db = await init();
    return await db.insert('playlists', playlist.toMap());
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final db = await init();

    // Get the highest position in the playlist
    final result = await db.query(
      'playlist_songs',
      columns: ['MAX(position) as max_pos'],
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );

    final int position = (result.first['max_pos'] as int?) ?? 0;

    await db.insert(
      'playlist_songs',
      {
        'playlist_id': playlistId,
        'song_id': songId,
        'position': position + 1,
        'date_added': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Update playlist's modified date
    await db.update(
      'playlists',
      {'date_modified': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<List<Playlist>> getPlaylists() async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.query('playlists');
    return List.generate(maps.length, (i) => Playlist.fromMap(maps[i]));
  }

  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.position
    ''', [playlistId]);

    return List.generate(maps.length, (i) => Song.fromMap(maps[i]));
  }

  // RECENTLY PLAYED OPERATIONS
  Future<void> addToRecentlyPlayed(int songId) async {
    final db = await init();
    await db.insert(
      'recently_played',
      {
        'song_id': songId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Keep only the most recent 50 songs
    await db.execute('''
      DELETE FROM recently_played 
      WHERE id NOT IN (
        SELECT id FROM recently_played 
        ORDER BY timestamp DESC 
        LIMIT 50
      )
    ''');

    incrementPlayCount(songId);
  }

  Future<List<Map<String, Object?>>> executeQueries(String sql) async {
    final db = await init();
    return await db.rawQuery(sql);
  }

  Future<List<Song>> getRecentlyPlayed() async {
    final db = await init();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT s.*, rp.timestamp FROM songs s
    INNER JOIN recently_played rp ON s.id = rp.song_id
    ORDER BY rp.timestamp DESC
  ''');
    return List.generate(maps.length, (i) => Song.fromMap(maps[i]));
  }

  Future<void> incrementPlayCount(int songId) async {
    final db = await init();
    await db.execute('''
      UPDATE songs SET play_count = play_count + 1 WHERE id = '${songId}';
    ''');
  }
}

// MODEL CLASSES

class Song {
  final int? id;
  final String title;
  final int? artistId;
  final int? albumId;
  final int duration;
  final String path;
  final int? size;
  final int? dateAdded;
  final int playCount;

  Song({
    this.id,
    required this.title,
    this.artistId,
    this.albumId,
    required this.duration,
    required this.path,
    this.size,
    this.dateAdded,
    this.playCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'artist_id': artistId,
      'album_id': albumId,
      'duration': duration,
      'path': path,
      'size': size,
      'date_added': dateAdded ?? DateTime.now().millisecondsSinceEpoch,
      'play_count': playCount,
    };
  }

  static Song fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artistId: map['artist_id'],
      albumId: map['album_id'],
      duration: map['duration'],
      path: map['path'],
      size: map['size'],
      dateAdded: map['date_added'],
      playCount: map['play_count'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Song{id: $id, title: $title, duration: $duration}';
  }
}

class Artist {
  final int? id;
  final String name;
  final String? imagePath;

  Artist({
    this.id,
    required this.name,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image_path': imagePath,
    };
  }

  static Artist fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'],
      name: map['name'],
      imagePath: map['image_path'],
    );
  }
}

class Album {
  final int? id;
  final String title;
  final int? artistId;
  final int? year;
  final String? coverArtPath;

  Album({
    this.id,
    required this.title,
    this.artistId,
    this.year,
    this.coverArtPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'artist_id': artistId,
      'year': year,
      'cover_art_path': coverArtPath,
    };
  }

  static Album fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      title: map['title'],
      artistId: map['artist_id'],
      year: map['year'],
      coverArtPath: map['cover_art_path'],
    );
  }
}

class Playlist {
  final int? id;
  final String name;
  final int? dateCreated;
  final int? dateModified;
  final String? coverImage;

  Playlist({
    this.id,
    required this.name,
    this.dateCreated,
    this.dateModified,
    this.coverImage,
  });

  Map<String, dynamic> toMap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      if (id != null) 'id': id,
      'name': name,
      'date_created': dateCreated ?? now,
      'date_modified': dateModified ?? now,
      'cover_image': coverImage,
    };
  }

  static Playlist fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      dateCreated: map['date_created'],
      dateModified: map['date_modified'],
      coverImage: map['cover_image'],
    );
  }
}
