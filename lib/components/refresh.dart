import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wawehead/components/metadata.dart';

import '../main.dart';
import 'db.dart';

Future<List<Map<String, String>>> _fetchMusicFiles() async {
  final List<Map<String, String>> _musicFiles = [];
  try {
    final musicFiles = await mediaStorePlugin.getDocumentTree(
      uriString:
          "content://com.android.externalstorage.documents/tree/primary%3AMusic/",
    );

    if (musicFiles?.childrenUriList != null) {
      for (var uri in musicFiles!.childrenUriList.sublist(1)) {
        final decodedFileName = _getCleanFileName(uri.toString());
        _musicFiles.add({'uri': uri.toString(), 'name': decodedFileName});
      }
    }

    return _musicFiles;
  } catch (e) {
    if (kDebugMode) {
      print("Error fetching music files: $e");
    }
  }

  return [];
}

String _getCleanFileName(String uri) {
  // Decode URI and extract the last part as the file name
  final decodedUri = Uri.decodeComponent(uri.substring(0, uri.length - 4));
  return decodedUri.split('/').last;
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

  for (var musicFile in musicFiles) {
    try {
      final String uri = musicFile['uri'] ?? '';
      final String name = musicFile['name'] ?? 'Unknown';
      final duration = await getDuration(uri) ?? 0;
      // Create a default artist entry if we don't have metadata yet
      final defaultArtistId =
          await dbms.insertArtist(Artist(name: 'Unknown Artist'));

      // Create a default album entry
      final defaultAlbumId = await dbms.insertAlbum(Album(
        title: 'Unknown Album',
        artistId: defaultArtistId,
        year: DateTime.now().year,
      ));

      // Insert the song with basic information
      // We can update metadata later
      final songId = await dbms.insertSong(Song(
        title: name,
        artistId: defaultArtistId,
        albumId: defaultAlbumId,
        duration: duration,
        // We'll update this with metadata later
        path: uri,
        size: 0,
        // We'll update this with metadata later
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
    print("Import complete. Added $importedCount songs to database");
  }
}

// Function to extract and update song metadata
// Call this after importing songs to enhance their information
Future<void> updateSongMetadata(int songId) async {
  final DBMS dbms = DBMS();

  try {
    // Get the song from database
    final song = await dbms.getSong(songId);
    if (song == null) return;

    // Here you would use a metadata extraction library like
    // flutter_media_metadata, just_audio, or audio_service
    // to extract metadata from the file at song.path

    // Example with a hypothetical metadata extractor:
    // final metadata = await MetadataRetriever.fromFile(song.path);

    // For now, we'll simulate with placeholder logic
    int durationInSeconds = 180; // 3 minutes placeholder
    String artistName = 'Unknown Artist';
    String albumName = 'Unknown Album';
    int year = 2023;

    // Find or create the artist
    int artistId;
    final artists = await dbms.getArtists();
    final existingArtist = artists.where((a) => a.name == artistName).toList();

    if (existingArtist.isNotEmpty) {
      artistId = existingArtist.first.id!;
    } else {
      artistId = await dbms.insertArtist(Artist(name: artistName));
    }

    // Find or create the album
    int albumId;
    final albums = await dbms.getAlbums();
    final existingAlbum = albums
        .where((a) => a.title == albumName && a.artistId == artistId)
        .toList();

    if (existingAlbum.isNotEmpty) {
      albumId = existingAlbum.first.id!;
    } else {
      albumId = await dbms.insertAlbum(Album(
        title: albumName,
        artistId: artistId,
        year: year,
      ));
    }

    // Update the song with metadata
    await dbms.updateSong(Song(
      id: song.id,
      title: song.title,
      // Keep original or update from metadata
      artistId: artistId,
      albumId: albumId,
      duration: durationInSeconds,
      path: song.path,
      size: song.size,
      // Can be updated if you get file size
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
    await updateSongMetadata(song.id!);
  }

  if (kDebugMode) {
    print("Metadata update complete for ${songs.length} songs");
  }
}

Future<void> resetDatabase() async {
  databaseFactory.deleteDatabase("wawehead.db");
}
