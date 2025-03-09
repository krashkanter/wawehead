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
  final DBMS dbms = DBMS();
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    loadSongs();
  }

  Future<void> loadSongs() async {
    final songList = await dbms.getSongs();
    setState(() {
      _musicFiles.addAll(songList);
      _isLoading = false;
    });
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
                    return ListTile(
                      leading: Icon(
                        Icons.music_note_rounded,
                        color: Colors.blue.shade50,
                      ),
                      title: Text(
                        _musicFiles.elementAt(index).title,
                      ),
                      onTap: () {
                        final uri = _musicFiles.elementAt(index).path;
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
