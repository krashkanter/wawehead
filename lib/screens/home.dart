import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:wawehead/screens/player_page.dart';
import 'package:wawehead/screens/playlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late var tf = "";
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPageIndex = Hive.box<int>('homePage').get(0) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          gradient: RadialGradient(
              colors: [Colors.white, Colors.blue],
              center: Alignment.topRight,
              radius: 4)),
      child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.settings,
                    color: Colors.black87,
                  ))
            ],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32))),
            backgroundColor: Colors.transparent,
            centerTitle: false,
            title: Text(
              'wawehead',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
          backgroundColor: Colors.transparent,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentPageIndex,
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
                Hive.box<int>('homePage').put(0, index);
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            destinations: [
              NavigationDestination(
                  icon: Icon(Icons.music_note), label: "Player"),
              NavigationDestination(
                  icon: Icon(Icons.featured_play_list_rounded),
                  label: "Playlist"),
            ],
          ),
          body: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PlayerPage(),
            ),Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: PlaylistPage(),
            ),
          ][currentPageIndex]),
    );
  }
}
