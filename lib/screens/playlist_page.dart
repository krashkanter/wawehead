import "package:flutter/material.dart";
// import "package:hive_flutter/adapters.dart";

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  String songName = "";
  double initialProgress = 0;

  @override
  void initState() {
    super.initState();
    // songName = Hive.box<String>('playerPage').get(0) ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

      ],
    );
  }
}
