import "package:flutter/material.dart";
import "package:wawehead/screens/library/playlists.dart";
import "package:wawehead/screens/library/all_songs.dart";
import "package:wawehead/screens/library/favourites.dart";
import "package:wawehead/screens/library/history.dart";

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String songName = "";
  double initialProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: 0, length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: TabBarView(
            controller: _tabController,
            children: [
              Favourites(),
              Playlists(),
              AllSongs(),
              History(),
            ],
          ),
        ),
        Stack(
          children: [
            TabBar(
              tabs: [
                Icon(Icons.favorite_rounded),
                Icon(Icons.album_rounded),
                Icon(Icons.all_inclusive_rounded),
                Icon(Icons.history_rounded)
              ],
              controller: _tabController,
              dividerColor: Colors.transparent,
            ),
          ],
        ),
      ],
    );
  }
}
