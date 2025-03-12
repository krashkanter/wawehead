import "package:flutter/material.dart";
import "package:wawehead/components/db.dart";

class Albums extends StatefulWidget {
  const Albums({super.key});

  @override
  State<Albums> createState() => _AlbumsState();
}

class _AlbumsState extends State<Albums> {
  final DBMS dbms = DBMS();
  List<Album> albums = [];
  List<Song> songs = [];
  List<Song> selectedSongs = [];
  String playlistName = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    final albumList = await dbms.getAlbums();
    final songList = await dbms.getSongs();
    setState(() {
      albums = albumList;
      songs = songList;
      isLoading = false;
    });
  }

  Future<void> createPlaylist() async {
    if (playlistName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name')),
      );
      return;
    }

    if (selectedSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one song')),
      );
      return;
    }

    final playlistId = await dbms.createPlaylist(Playlist(name: playlistName));

    for (var song in selectedSongs) {
      await dbms.addSongToPlaylist(playlistId, song.id!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playlist "$playlistName" created successfully')),
    );

    // Reset state
    setState(() {
      playlistName = "";
      selectedSongs = [];
    });
  }

  void toggleSongSelection(Song song) {
    setState(() {
      if (selectedSongs.any((s) => s.id == song.id)) {
        selectedSongs.removeWhere((s) => s.id == song.id);
      } else {
        selectedSongs.add(song);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Create Custom Playlist"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Playlist name input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white10,
              ),
              onChanged: (value) {
                setState(() {
                  playlistName = value;
                });
              },
            ),
          ),

          // Selected songs counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Selected Songs: ${selectedSongs.length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: createPlaylist,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text("Create Playlist"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Albums & Songs list
          Expanded(
            child: ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                final albumSongs = songs.where((song) => song.albumId == album.id).toList();

                if (albumSongs.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ExpansionTile(
                  title: Text(
                    album.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Artist ID: ${album.artistId} • Year: ${album.year}",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  children: albumSongs.map((song) {
                    final isSelected = selectedSongs.any((s) => s.id == song.id);
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(
                          "${(song.duration / 60).floor()}:${(song.duration % 60).toString().padLeft(2, '0')}"),
                      trailing: IconButton(
                        icon: Icon(
                          isSelected ? Icons.check_circle : Icons.add_circle_outline,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => toggleSongSelection(song),
                      ),
                      onTap: () => toggleSongSelection(song),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}