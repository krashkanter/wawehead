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
  bool playState = false;
  bool shuffleState = false;
  int repeatState = 0;

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
            padding: const EdgeInsets.only(top: 24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                "assets/icon/icon.png",
                fit: BoxFit.cover,
                height: MediaQuery.sizeOf(context).height / 3,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    repeatState = (repeatState + 1) % 3;
                  });
                },
                icon: repeatState == 0
                    ? Icon(Icons.repeat_rounded)
                    : repeatState == 1
                        ? Icon(Icons.repeat_on_rounded)
                        : Icon(Icons.repeat_one_on_rounded),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.fast_rewind_rounded),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (playState) {
                      playState = false;
                    } else {
                      playState = true;
                    }
                  });
                },
                icon: playState
                    ? Icon(
                        Icons.play_circle_fill_rounded,
                        size: 52,
                        color: Colors.black87,
                      )
                    : Icon(
                        Icons.pause_circle_filled_rounded,
                        size: 52,
                        color: Colors.black87,
                      ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.fast_forward_rounded),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (shuffleState) {
                      shuffleState = false;
                    } else {
                      shuffleState = true;
                    }
                  });
                },
                icon: shuffleState
                    ? Icon(Icons.shuffle_on_rounded)
                    : Icon(Icons.shuffle_rounded),
              ),
            ],
          ),
        ),
        Slider(
            value: initialProgress,
            activeColor: Colors.black87,
            inactiveColor: Colors.white60,
            onChanged: (double val) {
              setState(() {
                initialProgress = val;
              });
            })
      ],
    );
  }
}
