import "package:flutter/material.dart";
import "package:media_store_plus/media_store_plus.dart";

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String songName = "";
  double initialProgress = 0;
  
  @override
  void initState() {
    super.initState();
    // MediaStore().isFileUriExist(uriString: uriString)
    // MediaStore().requestForAccess(initialRelativePath: "Music");
    // songName = Hive.box<String>('playerPage').get(0) ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}