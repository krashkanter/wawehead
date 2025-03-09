import "package:flutter/material.dart";
import 'package:just_audio/just_audio.dart';

import '../components/db.dart';

class PlayerPage extends StatefulWidget {
  final String? uri;
  final int? id;

  const PlayerPage({super.key, this.id, this.uri});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with AutomaticKeepAliveClientMixin {
  String songName = "";
  bool shuffleState = false;
  bool likeState = false;
  bool repeatState = false;

  final DBMS dbms = DBMS();
  late var plr = AudioPlayer();

  @override
  void initState() {
    super.initState();
    isFav();
    plr = AudioPlayer(); // Initialize only once
    if (widget.uri != null) {
      _startPlaying(widget.uri);
      songName = _getCleanFileName(widget.uri.toString());
    }
  }

  Future<void> isFav() async {
    if (widget.id == null) return; // Prevent null errors
    bool isFavorite = await dbms.isFavorite(widget.id!);
    setState(() {
      likeState = isFavorite;
    });
  }

  Future<void> _startPlaying(String? uri) async {
    try {
      if (plr.playing) {
        // Stop playback before starting a new one
        await plr.stop();
      }
      await plr.setUrl(uri.toString());
      await plr.play();
    } catch (_) {}
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 10, right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        songName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 40),
                      ),
                    ),
                  ),
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
                      IconButton(
                          onPressed: () {
                            setState(() {
                              likeState ? likeState = false : likeState = true;
                            });
                          },
                          icon: Icon(
                            likeState
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: Colors.blue.shade50,
                          ))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            repeatState
                                ? repeatState = false
                                : repeatState = true;

                            repeatState
                                ? plr.setLoopMode(LoopMode.one)
                                : plr.setLoopMode(LoopMode.off);
                          });
                        },
                        icon: repeatState
                            ? Icon(
                                Icons.repeat_one_on_rounded,
                                color: Colors.blue.shade50,
                              )
                            : Icon(
                                Icons.repeat_rounded,
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
