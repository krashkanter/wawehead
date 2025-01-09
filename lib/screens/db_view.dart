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

  List<Song> songs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
    loadSongs();
  }

  Future<void> loadSongs() async {
    final songList = await dbms.getSongs();
    setState(() {
      songs = songList;
    });
  }

  Future<void> addSong() async {
    final dog = Song(id: songs.length + 1, name: 'Song ${songs.length + 1}', year: 2);
    await dbms.insertSong(dog);
    await loadSongs();
  }

  Future<void> deleteSong(int id) async {
    await dbms.deleteSong(id);
    await loadSongs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // dbms.printDogColumns();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main Database View"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Songs"),
            Tab(text: "Favourites"),
          ],
          dividerColor: Colors.transparent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              ElevatedButton(
                onPressed: addSong,
                child: const Text("Add Song"),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      title: Text(song.name),
                      subtitle: Text("Year: ${song.year}\nID: ${song.id}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteSong(song.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Text("just testing table stuff"),)
            ],
          ),
        ],
      ),
    );
  }
}
