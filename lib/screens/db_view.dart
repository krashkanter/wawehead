import "package:flutter/material.dart";
import "package:wawehead/components/db.dart";

class DbView extends StatefulWidget {
  const DbView({super.key});

  @override
  State<DbView> createState() => _DbViewState();
}

class _DbViewState extends State<DbView> with TickerProviderStateMixin {
  late TabController _tabController;
  final DBMS dbms = DBMS();

  // Data lists for different tabs
  List<Song> songs = [];
  List<Song> favoriteSongs = [];
  List<Artist> artists = [];
  List<Album> albums = [];
  List<Playlist> playlists = [];
  List<Song> recentlyPlayed = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 6, // Updated for new tabs
      vsync: this,
    );
    loadAllData();
  }

  Future<void> loadAllData() async {
    await loadSongs();
    await loadFavorites();
    await loadArtists();
    await loadAlbums();
    await loadPlaylists();
    await loadRecentlyPlayed();
  }

  Future<void> loadSongs() async {
    final songList = await dbms.getSongs();
    setState(() {
      songs = songList;
    });
  }

  Future<void> loadFavorites() async {
    final favoritesList = await dbms.getFavoriteSongs();
    setState(() {
      favoriteSongs = favoritesList;
    });
  }

  Future<void> loadArtists() async {
    final artistList = await dbms.getArtists();
    setState(() {
      artists = artistList;
    });
  }

  Future<void> loadAlbums() async {
    final albumList = await dbms.getAlbums();
    setState(() {
      albums = albumList;
    });
  }

  Future<void> loadPlaylists() async {
    final playlistList = await dbms.getPlaylists();
    setState(() {
      playlists = playlistList;
    });
  }

  Future<void> loadRecentlyPlayed() async {
    final recentList = await dbms.getRecentlyPlayed();
    setState(() {
      recentlyPlayed = recentList;
    });
  }

  // Mock data creation for testing
  Future<void> addMockSong() async {
    // Create a mock artist first
    final artistId = await dbms.insertArtist(
        Artist(name: 'Artist ${artists.length + 1}')
    );

    // Create a mock album
    final albumId = await dbms.insertAlbum(
        Album(
          title: 'Album ${albums.length + 1}',
          artistId: artistId,
          year: 2023,
        )
    );

    // Create a song
    final songId = await dbms.insertSong(
        Song(
          title: 'Song ${songs.length + 1}',
          artistId: artistId,
          albumId: albumId,
          duration: 180, // 3 minutes
          path: '/path/to/song${songs.length + 1}.mp3',
          size: 5000000, // 5MB
        )
    );

    // Refresh data
    await loadAllData();
  }

  Future<void> addToFavorites(int songId) async {
    await dbms.addToFavorites(songId);
    await loadFavorites();
  }

  Future<void> removeFromFavorites(int songId) async {
    await dbms.removeFromFavorites(songId);
    await loadFavorites();
  }

  Future<void> createMockPlaylist() async {
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add songs first'))
      );
      return;
    }

    final playlistId = await dbms.createPlaylist(
        Playlist(name: 'Playlist ${playlists.length + 1}')
    );

    // Add first 3 songs (or fewer if not enough)
    final songsToAdd = songs.length > 3 ? 3 : songs.length;
    for (var i = 0; i < songsToAdd; i++) {
      await dbms.addSongToPlaylist(playlistId, songs[i].id!);
    }

    await loadPlaylists();
  }

  Future<void> deleteSong(int id) async {
    await dbms.deleteSong(id);
    await loadAllData(); // Reload all since deletion affects multiple tables
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Database"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Songs"),
            Tab(text: "Favorites"),
            Tab(text: "Artists"),
            Tab(text: "Albums"),
            Tab(text: "Playlists"),
            Tab(text: "Recently Played"),
          ],
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // SONGS TAB
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: addMockSong,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Test Song"),
                ),
              ),
              Expanded(
                child: songs.isEmpty
                    ? const Center(child: Text("No songs in database"))
                    : ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song.title),
                      subtitle: Text(
                          "ID: ${song.id} · Duration: ${(song.duration / 60).floor()}:${(song.duration % 60).toString().padLeft(2, '0')}"
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () => addToFavorites(song.id!),
                            tooltip: "Add to favorites",
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteSong(song.id!),
                            tooltip: "Delete song",
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // FAVORITES TAB
          Column(
            children: [
              Expanded(
                child: favoriteSongs.isEmpty
                    ? const Center(child: Text("No favorite songs"))
                    : ListView.builder(
                  itemCount: favoriteSongs.length,
                  itemBuilder: (context, index) {
                    final song = favoriteSongs[index];
                    return ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: Text(song.title),
                      subtitle: Text(
                          "ID: ${song.id} · Duration: ${(song.duration / 60).floor()}:${(song.duration % 60).toString().padLeft(2, '0')}"
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_outlined, color: Colors.red),
                        onPressed: () => removeFromFavorites(song.id!),
                        tooltip: "Remove from favorites",
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // ARTISTS TAB
          Column(
            children: [
              Expanded(
                child: artists.isEmpty
                    ? const Center(child: Text("No artists in database"))
                    : ListView.builder(
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(artist.name),
                      subtitle: Text("ID: ${artist.id}"),
                    );
                  },
                ),
              ),
            ],
          ),

          // ALBUMS TAB
          Column(
            children: [
              Expanded(
                child: albums.isEmpty
                    ? const Center(child: Text("No albums in database"))
                    : ListView.builder(
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return ListTile(
                      leading: const Icon(Icons.album),
                      title: Text(album.title),
                      subtitle: Text(
                          "ID: ${album.id} · Artist ID: ${album.artistId} · Year: ${album.year}"
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // PLAYLISTS TAB
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: createMockPlaylist,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text("Create Test Playlist"),
                ),
              ),
              Expanded(
                child: playlists.isEmpty
                    ? const Center(child: Text("No playlists in database"))
                    : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ExpansionTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(playlist.name),
                      subtitle: Text("ID: ${playlist.id}"),
                      children: [
                        FutureBuilder<List<Song>>(
                          future: dbms.getPlaylistSongs(playlist.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("No songs in this playlist"),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, songIndex) {
                                final song = snapshot.data![songIndex];
                                return ListTile(
                                  leading: Text("${songIndex + 1}"),
                                  title: Text(song.title),
                                  dense: true,
                                  contentPadding: const EdgeInsets.only(left: 36.0, right: 16.0),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // RECENTLY PLAYED TAB
          Column(
            children: [
              Expanded(
                child: recentlyPlayed.isEmpty
                    ? const Center(child: Text("No recently played songs"))
                    : ListView.builder(
                  itemCount: recentlyPlayed.length,
                  itemBuilder: (context, index) {
                    final song = recentlyPlayed[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(song.title),
                      subtitle: Text(
                          "ID: ${song.id} · Duration: ${(song.duration / 60).floor()}:${(song.duration % 60).toString().padLeft(2, '0')}"
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () async {
                          // Simulate playing a song
                          await dbms.addToRecentlyPlayed(song.id!);
                          await loadRecentlyPlayed();
                        },
                        tooltip: "Play again",
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}