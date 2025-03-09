import "package:flutter/material.dart";
import "package:wawehead/components/db.dart";
import "package:wawehead/screens/query.dart";

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
      length: 6, // six tabs
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
    final artistId =
        await dbms.insertArtist(Artist(name: 'Artist ${artists.length + 1}'));
    final albumId = await dbms.insertAlbum(Album(
      title: 'Album ${albums.length + 1}',
      artistId: artistId,
      year: 2023,
    ));
    await dbms.insertSong(Song(
      title: 'Song ${songs.length + 1}',
      artistId: artistId,
      albumId: albumId,
      duration: 180,
      // 3 minutes
      path: '/path/to/song${songs.length + 1}.mp3',
      size: 5000000, // 5MB
    ));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add songs first')));
      return;
    }
    final playlistId = await dbms
        .createPlaylist(Playlist(name: 'Playlist ${playlists.length + 1}'));
    final songsToAdd = songs.length > 3 ? 3 : songs.length;
    for (var i = 0; i < songsToAdd; i++) {
      await dbms.addSongToPlaylist(playlistId, songs[i].id!);
    }
    await loadPlaylists();
  }

  Future<void> deleteSong(int id) async {
    await dbms.deleteSong(id);
    await loadAllData(); // Reload all data since deletion might affect multiple tables
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method for building a DataTable within a horizontally scrollable container.
  Widget buildDataTable<T>({
    required List<T> data,
    required List<DataColumn> columns,
    required List<DataRow> Function(List<T> data) rowBuilder,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rowBuilder(data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.black, Colors.blue],
          center: Alignment.topRight,
          radius: 4,
          stops: [0.2, 1],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QueryBuilderPage(),
              ),
            );
          },
          child: Icon(Icons.code_rounded),
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
                  child: SingleChildScrollView(
                    child: buildDataTable<Song>(
                      data: songs,
                      columns: const [
                        DataColumn(label: Text("ID")),
                        DataColumn(label: Text("Title")),
                        DataColumn(label: Text("Duration")),
                        DataColumn(label: Text("Path")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rowBuilder: (songList) => songList.map((song) {
                        return DataRow(cells: [
                          DataCell(Text(song.id.toString())),
                          DataCell(Text(song.title)),
                          DataCell(Text(
                              "${(song.duration / 60).floor()}:${(song.duration % 60).toString().padLeft(2, '0')}")),
                          DataCell(Text(song.path)),
                          DataCell(Row(
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
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            // FAVORITES TAB
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: buildDataTable<Song>(
                      data: favoriteSongs,
                      columns: const [
                        DataColumn(label: Text("ID")),
                        DataColumn(label: Text("Title")),
                        DataColumn(label: Text("Duration")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rowBuilder: (favList) => favList.map((song) {
                        return DataRow(cells: [
                          DataCell(Text(song.id.toString())),
                          DataCell(Text(song.title)),
                          DataCell(Text(
                              "${(song.duration / 60).floor()}:${(song.duration % 60).toString().padLeft(2, '0')}")),
                          DataCell(IconButton(
                            icon: const Icon(Icons.favorite_outlined,
                                color: Colors.red),
                            onPressed: () => removeFromFavorites(song.id!),
                            tooltip: "Remove from favorites",
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            // ARTISTS TAB
            SingleChildScrollView(
              child: buildDataTable<Artist>(
                data: artists,
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Name")),
                ],
                rowBuilder: (artistList) => artistList.map((artist) {
                  return DataRow(cells: [
                    DataCell(Text(artist.id.toString())),
                    DataCell(Text(artist.name)),
                  ]);
                }).toList(),
              ),
            ),

            // ALBUMS TAB
            SingleChildScrollView(
              child: buildDataTable<Album>(
                data: albums,
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Title")),
                  DataColumn(label: Text("Artist ID")),
                  DataColumn(label: Text("Year")),
                ],
                rowBuilder: (albumList) => albumList.map((album) {
                  return DataRow(cells: [
                    DataCell(Text(album.id.toString())),
                    DataCell(Text(album.title)),
                    DataCell(Text(album.artistId.toString())),
                    DataCell(Text(album.year.toString())),
                  ]);
                }).toList(),
              ),
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
                  child: SingleChildScrollView(
                    child: buildDataTable<Playlist>(
                      data: playlists,
                      columns: const [
                        DataColumn(label: Text("ID")),
                        DataColumn(label: Text("Name")),
                      ],
                      rowBuilder: (playlistList) =>
                          playlistList.map((playlist) {
                        return DataRow(cells: [
                          DataCell(Text(playlist.id.toString())),
                          DataCell(Text(playlist.name)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            // RECENTLY PLAYED TAB
            SingleChildScrollView(
              child: buildDataTable<Song>(
                data: recentlyPlayed,
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Title")),
                  DataColumn(label: Text("Duration")),
                  DataColumn(label: Text("Actions")),
                ],
                rowBuilder: (songList) => songList.map((song) {
                  return DataRow(cells: [
                    DataCell(Text(song.id.toString())),
                    DataCell(Text(song.title)),
                    DataCell(Text(
                        "${(song.duration / 60).floor()}:${(song.duration % 60).toString().padLeft(2, '0')}")),
                    DataCell(IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () async {
                        await dbms.addToRecentlyPlayed(song.id!);
                        await loadRecentlyPlayed();
                      },
                      tooltip: "Play again",
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
