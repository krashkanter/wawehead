import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:uri_to_file/uri_to_file.dart';

Future<String> getTitle(String filePath) async {
  File track = await toFile(filePath);

  final metadata = readMetadata(track);

  return metadata.title!;
}

Future<Uint8List?> getArt(String filePath) async {
  File track = await toFile(filePath);
  final metadata = readMetadata(track);
  if (metadata.pictures.isNotEmpty) {
    return metadata.pictures[0].bytes; // Extract Uint8List
  }
  return null; // Return null if no picture found
}

Future<String> getArtist(String filePath) async {
  File track = await toFile(filePath);
  final metadata = readMetadata(track);

  return metadata.artist!;
}

Future<int> getDuration(String filePath) async {
  File track = await toFile(filePath);
  final metadata = readMetadata(track);

  return metadata.duration?.inSeconds ?? 0;
}

Future<int> getSize(String filePath) async {
  File track = await toFile(filePath);
  return track.length();
}
