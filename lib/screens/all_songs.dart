import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wawehead/components/audiotagger.dart';
import 'package:wawehead/screens/home.dart';
import 'package:wawehead/screens/player.dart';

import '../main.dart';

class AllSongs extends StatefulWidget {
  const AllSongs({super.key});

  @override
  State<AllSongs> createState() => _AllSongsState();
}

class _AllSongsState extends State<AllSongs> {
  final List<Map<String, String>> _musicFiles =
      []; // List to store music file data
  bool _isLoading = true; // Track loading state


  @override
  void initState() {
    super.initState();
    _fetchMusicFiles();
  }

  Future<void> _fetchMusicFiles() async {
    try {
      final musicFiles = await mediaStorePlugin.getDocumentTree(
        uriString:
            "content://com.android.externalstorage.documents/tree/primary%3AMusic/",
      );

      if (musicFiles?.childrenUriList != null) {
        for (var uri in musicFiles!.childrenUriList.sublist(1)) {
          final decodedFileName = _getCleanFileName(uri.toString());
          _musicFiles.add({'uri': uri.toString(), 'name': decodedFileName});
          getTag(uri.toString());
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching music files: $e");
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getCleanFileName(String uri) {
    // Decode URI and extract the last part as the file name
    final decodedUri = Uri.decodeComponent(uri.substring(0, uri.length - 4));
    return decodedUri.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _musicFiles.isEmpty
              ? const Center(child: Text("No music files found."))
              : ListView.builder(
                  itemCount: _musicFiles.length,
                  itemBuilder: (BuildContext context, int index) {
                    final file = _musicFiles[index];
                    return ListTile(
                      leading: Icon(
                        Icons.music_note_rounded,
                        color: Colors.blue.shade50,
                      ),
                      title: Text(
                        file["name"]!,
                      ),
                      onTap: () {
                        final uri = file["uri"]!;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(uri: uri),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
