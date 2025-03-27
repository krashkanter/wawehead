import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wawehead/components/metadata.dart';
import '../components/db.dart';

class PlayerPage extends StatefulWidget {
  final String? uri;
  final int? id;
  final ConcatenatingAudioSource?
      playlistAudioSource; // Accepts a playlist for gapless playback
  final List<Song>? queue; // Accepts a list of songs to show as the queue

  const PlayerPage({
    super.key,
    this.id,
    this.uri,
    this.playlistAudioSource,
    this.queue,
  });

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
  late AudioPlayer plr;

  @override
  void initState() {
    super.initState();
    _checkFavorite();

    // Dispose of any existing player before creating a new one
    try {
      plr.dispose();
    } catch (e) {
      // Handle error as needed
    }
    plr = AudioPlayer();

    if (widget.playlistAudioSource != null) {
      _startPlayingPlaylist(widget.playlistAudioSource!);

      // Track song changes and add to recently played
      plr.currentIndexStream.listen((index) {
        if (index != null &&
            widget.queue != null &&
            index < widget.queue!.length) {
          final currentSong = widget.queue![index];
          if (currentSong.id != null) {
            dbms.addToRecentlyPlayed(currentSong.id!);
          }
        }
      });
    } else if (widget.uri != null) {
      _startPlaying(widget.uri);
      songName = _getCleanFileName(widget.uri.toString());
      if (widget.id != null) {
        dbms.addToRecentlyPlayed(widget.id!);
      }
    }
  }

  @override
  void dispose() {
    plr.dispose();
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    if (widget.id == null) return;
    bool isFavorite = await dbms.isFavorite(widget.id!);
    setState(() {
      likeState = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      likeState = !likeState;
    });
    if (likeState) {
      await dbms.addToFavorites(widget.id!);
    } else {
      await dbms.removeFromFavorites(widget.id!);
    }
  }

  Future<void> _startPlaying(String? uri) async {
    try {
      if (plr.playing) {
        await plr.stop();
      }
      await plr.setUrl(uri.toString());
      await plr.play();
    } catch (e) {
      // Handle error as needed
    }
  }

  Future<void> _startPlayingPlaylist(ConcatenatingAudioSource source) async {
    try {
      await plr.setAudioSource(source, initialIndex: 0);
      await plr.play();

      // Add the first song in the playlist to recently played
      if (widget.queue != null && widget.queue!.isNotEmpty) {
        final firstSong = widget.queue!.first;
        if (firstSong.id != null) {
          await dbms.addToRecentlyPlayed(firstSong.id!);
        }
      }
    } catch (e) {
      // Handle error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Top: Album art display
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: FutureBuilder<Uint8List?>(
                  future: widget.uri != null
                      ? getArt(widget.uri!)
                      : Future.value(null),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: snapshot.hasData && snapshot.data != null
                            ? Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                height:
                                    MediaQuery.of(context).size.height / 2.5,
                                width: double.infinity,
                              )
                            : Image.asset(
                                "assets/icon/icon.png",
                                fit: BoxFit.cover,
                                height:
                                    MediaQuery.of(context).size.height / 2.5,
                                width: double.infinity,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Bottom: Queue (if available) and playback controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 10, right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.uri != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Align (
                        alignment: Alignment.centerLeft,
                        child: Text(
                          songName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Song Queue Display
                  if (widget.queue != null && widget.queue!.isNotEmpty)
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: ListView.builder(
                        itemCount: widget.queue!.length,
                        itemBuilder: (context, index) {
                          final song = widget.queue![index];
                          return StreamBuilder<int?>(
                              stream: plr.currentIndexStream,
                              builder: (context, snapshot) {
                                final currentIndex = snapshot.data;
                                bool isCurrent = currentIndex == index;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    song.title,
                                    style: TextStyle(
                                      fontSize: isCurrent ? 24 : 16,
                                      color: isCurrent
                                          ? Colors.blue.shade200
                                          : Colors.white.withAlpha(150),
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  onTap: () {
                                    plr.seek(Duration.zero, index: index);
                                  },
                                );
                              });
                        },
                      ),
                    ),
                  // Playback slider and favorite button
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<Duration>(
                          stream: plr.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final duration = plr.duration ?? Duration.zero;
                            final buffer = plr.bufferedPosition;
                            return Slider(
                              value: position.inSeconds.toDouble(),
                              secondaryTrackValue: buffer.inSeconds.toDouble(),
                              max: duration.inSeconds.toDouble() > 0
                                  ? duration.inSeconds.toDouble()
                                  : 1.0,
                              activeColor: Colors.blue.shade50,
                              inactiveColor: Colors.black,
                              onChanged: (double value) {
                                plr.seek(Duration(seconds: value.toInt()));
                              },
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          likeState
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: Colors.blue.shade50,
                        ),
                      ),
                    ],
                  ),
                  // Playback Controls: Repeat, rewind, play/pause, fast forward, shuffle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            repeatState = !repeatState;
                            if (repeatState) {
                              plr.setLoopMode(LoopMode.one);
                            } else {
                              plr.setLoopMode(LoopMode.off);
                            }
                          });
                        },
                        icon: repeatState
                            ? Icon(Icons.repeat_one_on_rounded,
                                color: Colors.blue.shade50)
                            : Icon(Icons.repeat_rounded,
                                color: Colors.blue.shade50),
                      ),
                      IconButton(
                        onPressed: () async {
                          final currentPosition = plr.position;
                          if (currentPosition > Duration(seconds: 5)) {
                            // If more than 5 seconds into the track, rewind to the start of the current track.
                            await plr.seek(Duration.zero);
                          } else {
                            // If within the first 5 seconds, attempt to go to the previous track.
                            await plr.seekToPrevious();
                          }
                        },
                        icon: Icon(Icons.fast_rewind_rounded,
                            color: Colors.blue.shade50),
                      ),
                      StreamBuilder<PlayerState>(
                        stream: plr.playerStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          return IconButton(
                            onPressed: () async {
                              if (playing) {
                                await plr.pause();
                              } else {
                                await plr.play();
                              }
                            },
                            icon: playing
                                ? Icon(Icons.pause_circle_filled_rounded,
                                    size: 64, color: Colors.blue.shade50)
                                : Icon(Icons.play_circle_fill_rounded,
                                    size: 64, color: Colors.blue.shade50),
                          );
                        },
                      ),
                      IconButton(
                        tooltip:
                            'Tap to fast forward 10 sec, long press for next track',
                        onPressed: () {
                          final currentPosition = plr.position;
                          final targetPosition =
                              currentPosition + const Duration(seconds: 10);
                          plr.seek(targetPosition);
                          HapticFeedback.lightImpact();
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          plr.seekToNext();
                        },
                        icon: Icon(Icons.fast_forward_rounded,
                            color: Colors.blue.shade50),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            shuffleState = !shuffleState;
                          });
                          plr.setShuffleModeEnabled(shuffleState);
                        },
                        icon: shuffleState
                            ? Icon(Icons.shuffle_on_rounded,
                                color: Colors.blue.shade50)
                            : Icon(Icons.shuffle_rounded,
                                color: Colors.blue.shade50),
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

  String _getCleanFileName(String uri) {
    final decodedUri = Uri.decodeComponent(uri.substring(0, uri.length - 4));
    return decodedUri.split('/').last;
  }

  @override
  bool get wantKeepAlive => true;
}
