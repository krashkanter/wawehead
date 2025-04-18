import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wawehead/main.dart';
import 'package:wawehead/screens/player.dart';
import 'package:wawehead/screens/library.dart';

import '../components/db.dart';
import '../components/refresh.dart';
import 'db_view_page/db_view.dart';

class HomePage extends StatefulWidget {
  final String? uri;
  final int? id;
  final ConcatenatingAudioSource?
      playlistAudioSource; // Accepts a playlist for gapless playback
  final List<Song>? queue; // Accepts a list of songs to show as the queue

  const HomePage(
      {super.key, this.id, this.uri, this.playlistAudioSource, this.queue});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPageIndex = 0; // Hive.box<int>('homePage').get(0) ?? 0;
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
          actions: [
            IconButton(
              onPressed: () async {
                final musicFiles = await mediaStorePlugin.requestForAccess(
                    initialRelativePath: "");
                if (kDebugMode) {
                  print(musicFiles?.childrenUriList);
                }
                await resetDatabase();
                await importMusicFilesToDatabase();
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: Colors.blue.shade50,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DbView()),
                );
              },
              icon: Icon(
                Icons.dataset_rounded,
                color: Colors.blue.shade50,
              ),
            ),
          ],
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          title: Text(
            'wawehead',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade50,
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
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.music_note,
                color: Colors.blue.shade50,
              ),
              label: "Player",
            ),
            NavigationDestination(
              icon: Icon(
                Icons.library_music_rounded,
                color: Colors.blue.shade50,
              ),
              label: "Library",
            ),
          ],
        ),
        body: IndexedStack(
          index: currentPageIndex,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PlayerPage(
                  id: widget.id,
                  uri: widget.uri,
                  playlistAudioSource: widget.playlistAudioSource,
                  queue: widget.queue),
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
