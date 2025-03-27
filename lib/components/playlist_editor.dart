import 'package:flutter/material.dart';
import 'package:wawehead/components/db.dart';

class PlaylistEditor extends StatefulWidget {
  final Playlist playlist;

  const PlaylistEditor({super.key, required this.playlist});

  @override
  State<PlaylistEditor> createState() => _PlaylistEditorState();
}

class _PlaylistEditorState extends State<PlaylistEditor> {
  final DBMS dbms = DBMS();
  List<Song> playlistSongs = [];
  List<Song> allSongs = [];
  bool isLoading = true;
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.playlist.name;
    loadPlaylistData();
  }

  Future<void> loadPlaylistData() async {
    setState(() => isLoading = true);
    // Get songs already in the playlist
    playlistSongs = await dbms.getPlaylistSongs(widget.playlist.id!);
    // Get all songs available
    allSongs = await dbms.getSongs();
    setState(() => isLoading = false);
  }

  Future<void> removeSong(Song song) async {
    // Remove the song from the playlist_songs table
    final db = await dbms.init();
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [widget.playlist.id, song.id],
    );
    await loadPlaylistData();
  }

  Future<void> addSongs(List<Song> songsToAdd) async {
    // Add selected songs to the playlist
    for (var song in songsToAdd) {
      await dbms.addSongToPlaylist(widget.playlist.id!, song.id!);
    }
    await loadPlaylistData();
  }

  Future<void> updatePlaylistName() async {
    // Update the playlist name and modification date in the database
    final db = await dbms.init();
    await db.update(
      'playlists',
      {
        'name': nameController.text,
        'date_modified': DateTime.now().millisecondsSinceEpoch
      },
      where: 'id = ?',
      whereArgs: [widget.playlist.id],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Playlist name updated")),
    );
  }

  void showAddSongsDialog() async {
    // Filter songs not already in the playlist
    List<Song> availableSongs = allSongs
        .where((song) => !playlistSongs.any((s) => s.id == song.id))
        .toList();
    List<Song> selectedSongs = [];
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: const Text("Add Songs"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: availableSongs.length,
                itemBuilder: (context, index) {
                  final song = availableSongs[index];
                  bool isSelected = selectedSongs.contains(song);
                  return ListTile(
                    title: Text(song.title),
                    trailing: Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected ? Colors.blue : null,
                    ),
                    onTap: () {
                      setStateDialog(() {
                        if (isSelected) {
                          selectedSongs.remove(song);
                        } else {
                          selectedSongs.add(song);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await addSongs(selectedSongs);
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.black, Colors.blue],
          center: Alignment.topRight,
          radius: 4,
          stops: [.2, 1],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Playlist"),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: updatePlaylistName,
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: showAddSongsDialog,
          child: const Icon(Icons.add),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Playlist Name",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: updatePlaylistName,
                        ),
                      ),
                      onSubmitted: (_) => updatePlaylistName(),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: playlistSongs.isEmpty
                        ? Center(
                            child: Text(
                              "No songs in this playlist",
                              style: TextStyle(color: Colors.blue.shade50),
                            ),
                          )
                        : ListView.builder(
                            itemCount: playlistSongs.length,
                            itemBuilder: (context, index) {
                              final song = playlistSongs[index];
                              return ListTile(
                                title: Text(song.title),
                                subtitle:
                                    Text("Duration: ${song.duration} sec"),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await removeSong(song);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
