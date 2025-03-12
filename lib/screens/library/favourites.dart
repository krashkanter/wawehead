import "package:flutter/material.dart";

import "../../components/db.dart";
import "../home.dart";

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class Favourites extends StatefulWidget {
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> with RouteAware {
  final List<Song> _favourites = [];
  final DBMS dbms = DBMS();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSongs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    loadSongs();
  }

  Future<void> loadSongs() async {
    final songList = await dbms.getFavoriteSongs();
    setState(() {
      _favourites.clear();
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
                    "No Favourites 💔",
                    style: TextStyle(color: Colors.blue.shade50, fontSize: 20),
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
                        _favourites[index].title,
                      ),
                      onTap: () {
                        final id = _favourites[index].id;
                        final uri = _favourites[index].path;
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
