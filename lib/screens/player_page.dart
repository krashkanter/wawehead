import "package:flutter/material.dart";
// import "package:hive_flutter/adapters.dart";

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
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
        Center(
          child: Padding(
            padding:
            const EdgeInsets.only(top: 24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.network(
                "https://cdn.prod.website-files.com/62d84e447b4f9e7263d31e94/6399a4d27711a5ad2c9bf5cd_ben-sweet-2LowviVHZ-E-unsplash-1.jpeg",
                fit: BoxFit.cover,
                height: MediaQuery.sizeOf(context).height / 3,
              ),
            ),
          ),
        ),
        Slider(value: initialProgress, onChanged: (double val) {setState(() {
          initialProgress = val;
        });})
      ],
    );
  }
}
