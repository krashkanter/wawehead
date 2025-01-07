import "package:flutter/material.dart";
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final TextEditingController _videoId = TextEditingController();
  String songName = "";
  bool shuffleState = false;
  int repeatState = 0;
  final plr = AudioPlayer();
  String videoId = "";
  String videoName = "";

  @override
  void initState() {
    super.initState();
  }

  Future<void> ytd() async {
    final yt = YoutubeExplode();

    final video = await yt.videos.get(videoId);
    setState(() {
      videoName = video.title;
    });
    final manifest = await yt.videos.streams.getManifest(videoId);
    final audio = manifest.audioOnly;
    await plr.setUrl("${audio.first.url}");
    yt.close();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: videoId.isEmpty
                  ? Image.asset(
                      "assets/icon/icon.png",
                      fit: BoxFit.cover,
                      height: MediaQuery.sizeOf(context).height / 3,
                    )
                  : Image.network(
                      "https://img.youtube.com/vi/$videoId/0.jpg",
                      fit: BoxFit.cover,
                      height: MediaQuery.sizeOf(context).height / 3,
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Text(
              videoName,
              style: TextStyle(fontWeight: FontWeight.bold),
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
                    plr.setLoopMode(LoopMode.values[repeatState]);
                  });
                },
                icon: repeatState == 0
                    ? Icon(
                        Icons.repeat_rounded,
                        color: Colors.black87,
                      )
                    : repeatState == 1
                        ? Icon(
                            Icons.repeat_on_rounded,
                            color: Colors.black87,
                          )
                        : Icon(
                            Icons.repeat_one_on_rounded,
                            color: Colors.black87,
                          ),
              ),
              IconButton(
                onPressed: () {
                  plr.seek(Duration.zero);
                },
                icon: Icon(
                  Icons.fast_rewind_rounded,
                  color: Colors.black87,
                ),
              ),
              StreamBuilder<PlayerState>(
                stream: plr.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final playing = playerState?.playing ?? false;

                  return IconButton(
                    onPressed: () async {
                      if (playing) {
                        await plr.pause();
                      } else {
                        await plr.play();
                      }
                    },
                    icon: playing
                        ? Icon(
                            Icons.pause_circle_filled_rounded,
                            size: 64,
                            color: Colors.black87,
                          )
                        : Icon(
                            Icons.play_circle_fill_rounded,
                            size: 64,
                            color: Colors.black87,
                          ),
                  );
                },
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.fast_forward_rounded,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    shuffleState = !shuffleState;
                    plr.setShuffleModeEnabled(shuffleState);
                  });
                },
                icon: shuffleState
                    ? Icon(
                        Icons.shuffle_on_rounded,
                        color: Colors.black87,
                      )
                    : Icon(
                        Icons.shuffle_rounded,
                        color: Colors.black87,
                      ),
              ),
            ],
          ),
        ),
        StreamBuilder<Duration>(
          stream: plr.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = plr.duration ?? Duration.zero;
            final buffer = plr.bufferedPosition;
            return Slider(
              value: position.inSeconds.toDouble(),
              secondaryTrackValue: buffer.inSeconds.toDouble(),
              max: duration.inSeconds.toDouble(),
              activeColor: Colors.black87,
              inactiveColor: Colors.white60,
              onChanged: (double value) {
                plr.seek(Duration(seconds: value.toInt()));
              },
            );
          },
        ),
        TextField(
          controller: _videoId,
        ),
        ElevatedButton(
            onPressed: () {
              setState(() {
                videoId = _videoId.text;
              });
              ytd();
            },
            child: Text("Fetch"))
      ],
    );
  }
}
