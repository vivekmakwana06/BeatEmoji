import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:musicapp_/search%20Page/search.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'package:shimmer/shimmer.dart';

class NowPlayingPage extends StatefulWidget {
  final String title;
  final String path;
  final String subtitle;
  final List playlists;
  final String file;
  final String docId;

  const NowPlayingPage({
    Key? key,
    required this.title,
    required this.path,
    required this.subtitle,
    required this.playlists,
    required this.file,
    required this.docId,
  }) : super(key: key);

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with AutomaticKeepAliveClientMixin {
  bool _isPlaying = false;
  bool _play = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late final AssetsAudioPlayer assetsAudioPlayer;
  late double _rotationPercentage = 0.0;
  bool _isDisposed = false;
  bool _isLoading = true;
  @override
  void dispose() {
    super.dispose();
    _isDisposed = true;
    assetsAudioPlayer.stop();
    assetsAudioPlayer.dispose();
  }

  @override
  void initState() {
    super.initState();

    assetsAudioPlayer = AssetsAudioPlayer();

    assetsAudioPlayer.currentPosition.listen((position) {
      if (!_isDisposed) {
        setState(() {
          _currentPosition = position ?? Duration.zero;
          if (_totalDuration.inMilliseconds > 0) {
            _rotationPercentage =
                _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
          }
        });
      }
    });

    assetsAudioPlayer.current.listen((playingAudio) {
      if (!_isDisposed) {
        if (playingAudio != null) {
          setState(() {
            _totalDuration = playingAudio.audio.duration ?? Duration.zero;
            _isLoading =
                false; // Set loading state to false when music is loaded
          });
        }
      }
    });

    assetsAudioPlayer.open(
      Audio.network(widget.file),
      showNotification: true,
    );

    _isPlaying = true;

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!_isDisposed && _isPlaying) {
        assetsAudioPlayer.play();
      }
    });

    _playPauseMusic();
  }

  void _playPauseMusic() {
    if (_isPlaying) {
      assetsAudioPlayer.pause();
    } else {
      assetsAudioPlayer.open(
        Audio(widget.path,
            metas: Metas(title: widget.title, artist: widget.subtitle)),
      );
      assetsAudioPlayer.play();

      assetsAudioPlayer.playlistFinished.listen((finished) {
        if (finished) {
          assetsAudioPlayer.play();
        }
      });
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    super.build(context);

    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF121640),

                Color(0xFF1a1b1f), // Starting color
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      assetsAudioPlayer.pause();
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: screenHeight * 0.02,
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.42,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30384b),
                    borderRadius: BorderRadius.circular(18),
                    image: DecorationImage(
                      image: const AssetImage('assets/logo.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        const Color(0xFF1a1b1f)
                            .withOpacity(0.7), // Adjust the opacity as needed
                        BlendMode.multiply,
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.lightBlue!,
                          child: const CircleAvatar(
                            maxRadius: 80,
                          ),
                        )
                      : RotationTransition(
                          turns: AlwaysStoppedAnimation(_rotationPercentage),
                          child: const Padding(
                            padding: EdgeInsets.all(78.0),
                            child: CircleAvatar(
                              maxRadius: 80,
                              backgroundImage: AssetImage('assets/logo.png'),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // Inside the Row where the title is displayed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 15,
                  ),
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  IconButton(
                    onPressed: () {
                      // Toggle favorite when the heart icon is pressed
                      Provider.of<FavoriteModel>(context, listen: false)
                          .toggleFavorite(widget.docId);
                    },
                    icon: Icon(
                      Icons.favorite,
                      color: Provider.of<FavoriteModel>(context)
                              .favoriteSongs
                              .contains(widget.docId)
                          ? Colors.red
                          : Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),
              Slider(
                value: _currentPosition.inSeconds.toDouble(),
                min: 0,
                max: _totalDuration.inSeconds.toDouble(),
                onChanged: (double value) {
                  setState(() {
                    assetsAudioPlayer.seek(Duration(seconds: value.toInt()));
                    _currentPosition = Duration(seconds: value.toInt());
                  });
                },
                activeColor: Colors.green,
                inactiveColor: Colors.grey[600],
              ),
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(
                    color: Colors.white,
                    size: 30,
                    Icons.loop,
                  ),
                  IconButton(
                    onPressed: () {
                      // Seek backward by 10 seconds
                      assetsAudioPlayer.seekBy(const Duration(seconds: -10));
                    },
                    icon: const Icon(
                      Icons.replay_10,
                      size: 35,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _play ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 35,
                    ),
                    onPressed: () {
                      setState(() {
                        _play = !_play;
                        if (_play) {
                          assetsAudioPlayer.play();
                        } else {
                          assetsAudioPlayer.pause();
                        }
                      });
                    },
                  ),
                  IconButton(
                    onPressed: () {
                      // Seek forward by 10 seconds
                      assetsAudioPlayer.seekBy(const Duration(seconds: 10));
                    },
                    icon: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                  const Icon(
                    Icons.add,
                    color: Color(0xFFFFFFFF),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
