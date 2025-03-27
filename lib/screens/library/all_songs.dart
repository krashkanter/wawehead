import 'package:flutter/material.dart';
import 'package:wawehead/components/db.dart';
import 'package:wawehead/screens/home.dart';

class AllSongs extends StatefulWidget {
  const AllSongs({super.key});

  @override
  State<AllSongs> createState() => _AllSongsState();
}

class _AllSongsState extends State<AllSongs> {
  final List<Song> _musicFiles = []; // List to store music file data
  final List<Artist> _artists = []; // List to store artist data
  final DBMS dbms = DBMS();
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    loadSongs();
    loadArtists();
  }

  Future<void> loadSongs() async {
    final songList = await dbms.getSongs();
    setState(() {
      _musicFiles.addAll(songList);
      _isLoading = false;
    });
  }

  Future<void> loadArtists() async {
    final artistList = await dbms.getArtists();
    setState(() {
      _artists.addAll(artistList);
    });
  }

  String _getArtistName(int artistId) {
    final artist = _artists.firstWhere(
      (artist) => artist.id == artistId,
      orElse: () =>
          Artist(id: -1, name: "Unknown Artist"), // Handle missing artist
    );
    return artist.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _musicFiles.isEmpty
              ? const Center(
                  child: Text("No music files found."),
                )
              : ListView.builder(
                  itemCount: _musicFiles.length,
                  itemBuilder: (BuildContext context, int index) {
                    final song = _musicFiles[index];
                    return ListTile(
                      leading: Icon(
                        Icons.music_note_rounded,
                        color: Colors.blue.shade50,
                      ),
                      title: Text(song.title),
                      subtitle: Text(_getArtistName(song.artistId!)),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(
                              uri: song.path,
                              id: song.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
