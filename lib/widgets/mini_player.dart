
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/audio_service.dart';

class MiniPlayer extends StatelessWidget {
  final MusicService musicService;
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.musicService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: musicService,
      builder: (context, child) {
        return _buildMiniPlayer(context);
      },
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    final song = musicService.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF29293D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                song.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.music_note_rounded,
                    color: Color(0xFFBB86FC),
                    size: 40,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<PlayerState>(
            stream: musicService.player.playerStateStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data?.playing ?? false;

              return IconButton(
                onPressed: () async {
                  await musicService.togglePlayPause();
                },
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFFBB86FC),
                  size: 30,
                ),
              );
            },
          ),

          IconButton(
            onPressed: () async {
              await musicService.next();
            },
            icon: const Icon(
              Icons.skip_next,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
