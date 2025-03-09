import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:uri_to_file/uri_to_file.dart';

Future<AudioMetadata> getTag(String filePath) async {
  File track = await toFile(filePath);

  final metadata = readMetadata(track);

  return metadata;
}