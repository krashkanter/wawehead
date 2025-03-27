import "package:flutter/material.dart";

import "../../components/db.dart";
import "../home.dart";

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final List<Song> _recents = []; // List to store music file data
  final DBMS dbms = DBMS();
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    loadSongs();
  }

  Future<void> loadSongs() async {
    final songList = await dbms.getRecentlyPlayed();
    setState(() {
      _recents.addAll(songList);
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
          : _recents.isEmpty
              ? Center(
                  child: Text(
                    "No history. \nTry listening to some songs",
                    style: TextStyle(fontSize: 20, color: Colors.blue.shade50),
                  ),
                )
              : ListView.builder(
                  itemCount: _recents.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: Icon(
                        Icons.music_note_rounded,
                        color: Colors.blue.shade50,
                      ),
                      title: Text(
                        _recents.elementAt(index).title,
                      ),
                      onTap: () {
                        final id = _recents.elementAt(index).id;
                        final uri = _recents.elementAt(index).path;
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
