import "package:flutter/material.dart";
import "package:just_audio/just_audio.dart";
import "package:wawehead/components/db.dart";
import "package:wawehead/components/playlist_editor.dart";
import "package:wawehead/screens/home.dart";

class Playlists extends StatefulWidget {
  const Playlists({super.key});

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  final DBMS dbms = DBMS();
  List<Song> songs = [];
  List<Song> selectedSongs = [];
  String playlistName = "";
  bool isLoading = true;
  List<Playlist> createdPlaylists = [];
  bool isPlaylistLoading = true;

  @override
  void initState() {
    super.initState();
    loadSongs();
    loadPlaylists();
  }

  Future<void> loadSongs() async {
    setState(() => isLoading = true);
    final songList = await dbms.getSongs();
    setState(() {
      songs = songList;
      isLoading = false;
    });
  }

  Future<void> loadPlaylists() async {
    setState(() => isPlaylistLoading = true);
    final playlists = await dbms.getPlaylists();
    setState(() {
      createdPlaylists = playlists;
      isPlaylistLoading = false;
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

    setState(() {
      playlistName = "";
      selectedSongs = [];
    });

    // Refresh the created playlists list
    await loadPlaylists();
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
      appBar: AppBar(
        title: const Text("Playlists"),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Create Playlist section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Playlist Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          setState(() => playlistName = value),
                      controller: TextEditingController(text: playlistName),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: createPlaylist,
                    child: const Text("Create Playlist"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Select Songs",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade50,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isSelected =
                          selectedSongs.any((s) => s.id == song.id);
                      return ListTile(
                        title: Text(song.title),
                        subtitle: Text("Duration: ${song.duration} sec"),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                        onTap: () => toggleSongSelection(song),
                      );
                    },
                  ),
                  const Divider(),
                  // Created Playlists Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Created Playlists",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade50,
                      ),
                    ),
                  ),
                  isPlaylistLoading
                      ? const Center(child: CircularProgressIndicator())
                      : createdPlaylists.isEmpty
                          ? Center(
                              child: Text(
                                "No playlists created yet",
                                style: TextStyle(color: Colors.blue.shade50),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: createdPlaylists.length,
                              itemBuilder: (context, index) {
                                final playlist = createdPlaylists[index];
                                return ListTile(
                                  leading: Icon(
                                    Icons.playlist_play,
                                    color: Colors.blue.shade50,
                                  ),
                                  title: Text(playlist.name),
                                  subtitle: Text(
                                    "Created: ${DateTime.fromMillisecondsSinceEpoch(playlist.dateCreated ?? 0)}",
                                  ),
                                  onTap: () async {
                                    // Fetch songs for the tapped playlist
                                    final songs = await dbms
                                        .getPlaylistSongs(playlist.id!);

                                    // Build a list of AudioSource objects from songs
                                    final audioSources = songs.map((song) {
                                      return AudioSource.uri(
                                        Uri.parse(song.path),
                                        tag: song.title,
                                      );
                                    }).toList();

                                    // Create a ConcatenatingAudioSource for gapless playback
                                    final concatenatedSource =
                                        ConcatenatingAudioSource(
                                            children: audioSources);

                                    // Stop any existing playback before starting a new playlist
                                    // You might want to pass a global AudioPlayer or use a state management solution
                                    // For now, we'll navigate and start a new player
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomePage(
                                          playlistAudioSource:
                                              concatenatedSource,
                                          queue: songs,
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => PlaylistEditor(
                                              playlist: playlist)),
                                    ).then((_) {
                                      // Refresh playlists after returning from the editor
                                      loadPlaylists();
                                    });
                                  },
                                );
                              },
                            ),
                ],
              ),
            ),
    );
  }
}
