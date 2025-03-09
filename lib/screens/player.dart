import "package:flutter/material.dart";
import 'package:just_audio/just_audio.dart';

class PlayerPage extends StatefulWidget {
  final String? uri;

  const PlayerPage({super.key, this.uri});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with AutomaticKeepAliveClientMixin {
  // final TextEditingController _videoId = TextEditingController();
  String songName = "";
  bool shuffleState = false;
  int repeatState = 0;
  late var plr = AudioPlayer();

  @override
  void initState() {
    super.initState();
    plr = AudioPlayer(); // Initialize only once
    if (widget.uri != null) {
      _startPlaying(widget.uri);
      songName = _getCleanFileName(widget.uri.toString());
    }
  }

  Future<void> ytd() async {
    await plr.setUrl(
        "content://com.android.externalstorage.documents/tree/primary%3AMusic/document/primary%3AMusic%2FKalimba.mp3");
  }

  Future<void> _startPlaying(String? uri) async {
    try {
      if (plr.playing) {
        // Stop playback before starting a new one
        await plr.stop();
      }
      await plr.setUrl(uri.toString());
      await plr.play();
      setState(() {
        // songName = uri.toString(); // Set the song name if available
      });
    } catch (e) {
      // print("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    plr.dispose(); // Dispose of the player when the widget is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
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
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                songName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 10, right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StreamBuilder<Duration>(
                        stream: plr.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = plr.duration ?? Duration.zero;
                          final buffer = plr.bufferedPosition;
                          return Expanded(
                            child: Slider(
                              value: position.inSeconds.toDouble(),
                              secondaryTrackValue: buffer.inSeconds.toDouble(),
                              max: duration.inSeconds.toDouble(),
                              activeColor: Colors.blue.shade50,
                              inactiveColor: Colors.black,
                              onChanged: (double value) {
                                plr.seek(Duration(seconds: value.toInt()));
                              },
                            ),
                          );
                        },
                      ),
                      IconButton(onPressed: () {}, icon: Icon(Icons.thumb_up_alt_rounded, color: Colors.blue.shade50,))
                    ],
                  ),
                  Row(
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
                                color: Colors.blue.shade50,
                              )
                            : repeatState == 1
                                ? Icon(
                                    Icons.repeat_on_rounded,
                                    color: Colors.blue.shade50,
                                  )
                                : Icon(
                                    Icons.repeat_one_on_rounded,
                                    color: Colors.blue.shade50,
                                  ),
                      ),
                      IconButton(
                        onPressed: () {
                          plr.seek(Duration.zero);
                        },
                        icon: Icon(
                          Icons.fast_rewind_rounded,
                          color: Colors.blue.shade50,
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
                                    color: Colors.blue.shade50,
                                  )
                                : Icon(
                                    Icons.play_circle_fill_rounded,
                                    size: 64,
                                    color: Colors.blue.shade50,
                                  ),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.fast_forward_rounded,
                          color: Colors.blue.shade50,
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
                                color: Colors.blue.shade50,
                              )
                            : Icon(
                                Icons.shuffle_rounded,
                                color: Colors.blue.shade50,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

String _getCleanFileName(String uri) {
  // Decode URI and extract the last part as the file name
  final decodedUri = Uri.decodeComponent(uri.substring(0, uri.length - 4));
  return decodedUri.split('/').last;
}
