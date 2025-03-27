import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wawehead/components/metadata.dart';

import '../main.dart';
import 'db.dart';

Future<List<Map<String, String>>> _fetchMusicFiles() async {
  final List<Map<String, String>> musicFiles = [];
  try {
    final musicFiles0 = await mediaStorePlugin.getDocumentTree(
      uriString:
          "content://com.android.externalstorage.documents/tree/primary%3AMusic/",
    );

    if (musicFiles0?.childrenUriList != null) {
      for (var uri in musicFiles0!.childrenUriList.sublist(1)) {
        final uriString = uri.toString();
        if (_isMusicFile(uriString)) {
          final decodedFileName = _getCleanFileName(uriString);
          musicFiles.add({'uri': uriString, 'name': decodedFileName});
        }
      }
    }

    return musicFiles;
  } catch (e) {
    if (kDebugMode) {
      print("Error fetching music files: $e");
    }
    return [];
  }
}

bool _isMusicFile(String uri) {
  final supportedExtensions = ['.mp3', '.wav', '.flac', '.m4a', '.ogg', '.aac'];
  return supportedExtensions.any((ext) => uri.toLowerCase().endsWith(ext));
}

String _getCleanFileName(String uri) {
  final decodedUri = Uri.decodeComponent(uri);
  return decodedUri.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
}

Future<void> importMusicFilesToDatabase() async {
  final DBMS dbms = DBMS();
  final List<Map<String, String>> musicFiles = await _fetchMusicFiles();

  if (musicFiles.isEmpty) {
    if (kDebugMode) {
      print("No music files found to import");
    }
    return;
  }

  int importedCount = 0;
  int updatedCount = 0;

  for (var musicFile in musicFiles) {
    try {
      final String uri = musicFile['uri'] ?? '';
      final String name = musicFile['name'] ?? 'Unknown';

      // Check if song already exists in database
      final existingSongs =
          await dbms.executeQueries("SELECT * FROM songs WHERE path = '$uri'");

      if (existingSongs.isNotEmpty) {
        // Song exists, update its metadata
        final songId = existingSongs.first['id'] as int;
        await updateSongMetadata(songId, uri);
        updatedCount++;
        continue;
      }

      // Fetch metadata
      final duration = await getDuration(uri) ?? 0;
      final artistName = await _getOrCreateArtist(dbms, uri);
      final albumName = await _getOrCreateAlbum(dbms, uri, artistName);

      // Insert the song with extracted metadata
      final songId = await dbms.insertSong(Song(
        title: name,
        artistId: artistName['id'],
        albumId: albumName['id'],
        duration: duration,
        path: uri,
        size: await getSize(uri),
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      ));

      importedCount++;

      if (kDebugMode) {
        print("Imported: $name");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error importing file ${musicFile['name']}: $e");
      }
    }
  }

  if (kDebugMode) {
    print(
        "Import complete. Added $importedCount songs, updated $updatedCount songs");
  }
}

Future<Map<String, dynamic>> _getOrCreateArtist(
    DBMS dbms, String filePath) async {
  try {
    final artistName = await getArtist(filePath);
    final artists = await dbms.getArtists();

    final existingArtist = artists.firstWhere(
        (a) => a.name.toLowerCase() == artistName.toLowerCase(),
        orElse: () => Artist(name: 'Unknown Artist'));

    if (existingArtist.id == null) {
      // Create new artist if not found
      final artistId = await dbms.insertArtist(Artist(name: artistName));
      return {'id': artistId, 'name': artistName};
    }

    return {'id': existingArtist.id!, 'name': existingArtist.name};
  } catch (e) {
    // Fallback to Unknown Artist
    final defaultArtistId =
        await dbms.insertArtist(Artist(name: 'Unknown Artist'));
    return {'id': defaultArtistId, 'name': 'Unknown Artist'};
  }
}

Future<Map<String, dynamic>> _getOrCreateAlbum(
    DBMS dbms, String filePath, Map<String, dynamic> artist) async {
  try {
    // You might want to extract album name from metadata
    final albumName = 'Unknown Album';
    final year = DateTime.now().year;

    final albums = await dbms.getAlbums();

    final existingAlbum = albums.firstWhere(
        (a) =>
            a.title.toLowerCase() == albumName.toLowerCase() &&
            a.artistId == artist['id'],
        orElse: () => Album(title: 'Unknown Album', artistId: artist['id']));

    if (existingAlbum.id == null) {
      // Create new album if not found
      final albumId = await dbms.insertAlbum(Album(
        title: albumName,
        artistId: artist['id'],
        year: year,
      ));
      return {'id': albumId, 'title': albumName};
    }

    return {'id': existingAlbum.id!, 'title': existingAlbum.title};
  } catch (e) {
    // Fallback to Unknown Album
    final defaultAlbumId = await dbms.insertAlbum(Album(
      title: 'Unknown Album',
      artistId: artist['id'],
      year: DateTime.now().year,
    ));
    return {'id': defaultAlbumId, 'title': 'Unknown Album'};
  }
}

Future<void> updateSongMetadata(int songId, String filePath) async {
  final DBMS dbms = DBMS();

  try {
    final song = await dbms.getSong(songId);
    if (song == null) return;

    final artistName = await _getOrCreateArtist(dbms, filePath);

    // Update the song with metadata
    await dbms.updateSong(Song(
      id: song.id,
      title: await getTitle(filePath) ?? song.title,
      artistId: artistName['id'],
      albumId: song.albumId,
      // Keep existing album for now
      duration: await getDuration(filePath),
      path: song.path,
      size: await getSize(filePath),
      dateAdded: song.dateAdded,
      playCount: song.playCount,
    ));
  } catch (e) {
    if (kDebugMode) {
      print("Error updating metadata for song $songId: $e");
    }
  }
}

// Batch update function to process all songs
Future<void> updateAllSongsMetadata() async {
  final DBMS dbms = DBMS();
  final songs = await dbms.getSongs();

  for (var song in songs) {
    await updateSongMetadata(song.id!, song.path);
  }

  if (kDebugMode) {
    print("Metadata update complete for ${songs.length} songs");
  }
}

Future<void> resetDatabase() async {
  databaseFactory.deleteDatabase("wawehead.db");
}
