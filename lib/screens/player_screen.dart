
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/audio_service.dart';

class PlayerScreen extends StatelessWidget {
  final MusicService musicService;

  const PlayerScreen({
    super.key,
    required this.musicService,
  });

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: musicService,
      builder: (context, child) {
        return _buildPlayer(context);
      },
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final song = musicService.currentSong;

    if (song == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF12121C),
        body: Center(
          child: Text(
            'Chưa chọn bài hát',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121C),
        foregroundColor: Colors.white,
        title: const Text('Đang phát'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    song.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: Color(0xFF252538),
                        child: Icon(
                          Icons.music_note,
                          color: Color(0xFFBB86FC),
                          size: 100,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 35),

            Text(
              song.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              song.artist,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            StreamBuilder<Duration>(
              stream: musicService.player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration =
                    musicService.player.duration ?? Duration.zero;

                final maxSeconds =
                    duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0;

                final currentSeconds =
                    position.inMilliseconds.toDouble().clamp(
                      0.0,
                      maxSeconds,
                    );

                return Column(
                  children: [
                    Slider(
                      activeColor: const Color(0xFFBB86FC),
                      inactiveColor: Colors.white24,
                      min: 0,
                      max: maxSeconds,
                      value: currentSeconds,
                      onChanged: duration > Duration.zero
                          ? (value) {
                              musicService.seek(
                                Duration(
                                  milliseconds: value.toInt(),
                                ),
                              );
                            }
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    await musicService.previous();
                  },
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(width: 25),

                StreamBuilder<PlayerState>(
                  stream: musicService.player.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying =
                        snapshot.data?.playing ?? false;

                    return CircleAvatar(
                      radius: 35,
                      backgroundColor:
                          const Color(0xFFBB86FC),
                      child: IconButton(
                        onPressed: () async {
                          await musicService.togglePlayPause();
                        },
                        icon: Icon(
                          isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.black,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 25),

                IconButton(
                  onPressed: () async {
                    await musicService.next();
                  },
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
