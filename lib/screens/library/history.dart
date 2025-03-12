import "package:flutter/material.dart";

import "../../components/db.dart";
import "../home.dart";

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final List<Song> _favourites = []; // List to store music file data
  final DBMS dbms = DBMS();
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    loadSongs();
  }

  Future<void> loadSongs() async {
    final songList = await dbms.getFavoriteSongs();
    setState(() {
      _favourites.addAll(songList);
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
          : _favourites.isEmpty
              ? Center(
                  child: Text(
                    "No history. \nTry listening to some songs",
                    style: TextStyle(fontSize: 20, color: Colors.blue.shade50),
                  ),
                )
              : ListView.builder(
                  itemCount: _favourites.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: Icon(
                        Icons.music_note_rounded,
                        color: Colors.blue.shade50,
                      ),
                      title: Text(
                        _favourites.elementAt(index).title,
                      ),
                      onTap: () {
                        final id = _favourites.elementAt(index).id;
                        final uri = _favourites.elementAt(index).path;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(id: id, uri: uri),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
