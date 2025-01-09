import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:wawehead/main.dart';
import 'package:wawehead/screens/player.dart';
import 'package:wawehead/screens/library.dart';

import 'db_view.dart';

class HomePage extends StatefulWidget {
  final String? uri;

  const HomePage({super.key, this.uri});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPageIndex = 0; //Hive.box<int>('homePage').get(0) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.white, Colors.blue],
          center: Alignment.topRight,
          radius: 4,
          stops: [.2, 1],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () async {
                final musicFiles = await mediaStorePlugin.requestForAccess(initialRelativePath: "");
                print(musicFiles?.childrenUriList);
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.black87,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DbView()),
                );
              },
              icon: const Icon(
                Icons.dataset_rounded,
                color: Colors.black87,
              ),
            ),
          ],
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          title: const Text(
            'wawehead',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentPageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.music_note),
              label: "Player",
            ),
            NavigationDestination(
              icon: Icon(Icons.library_music_rounded),
              label: "Library",
            ),
          ],
        ),
        body: IndexedStack(
          index: currentPageIndex,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PlayerPage(uri: widget.uri),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: LibraryPage(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Hive.box<int>('homePage').put(0, currentPageIndex);
    super.dispose();
  }
}
