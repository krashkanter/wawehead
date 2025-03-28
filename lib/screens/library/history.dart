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
      _recents
        ..clear()
        ..addAll(songList);
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recents.isEmpty
              ? Center(
                  child: Text(
                    "No history. \nTry listening to some songs",
                    style: TextStyle(fontSize: 20, color: Colors.blue.shade50),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _recents.length,
                  itemBuilder: (BuildContext context, int index) {
                    final song = _recents[index];
                    return ListTile(
                      leading: Icon(
                        Icons.music_note_rounded,
                        color: Colors.blue.shade50,
                      ),
                      title: Text(song.title),
                      onTap: () {
                        final id = song.id;
                        final uri = song.path;
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
