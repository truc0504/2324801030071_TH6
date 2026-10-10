
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../widgets/song_tile.dart';

class PlaylistScreen extends StatelessWidget {
  final List<Song> playlist;
  final void Function(Song song) onSongSelected;
  final void Function(Song song) onRemoveSong;

  const PlaylistScreen({
    super.key,
    required this.playlist,
    required this.onSongSelected,
    required this.onRemoveSong,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121C),
        foregroundColor: Colors.white,
        title: const Text(
          'Playlist của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: playlist.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.queue_music,
                    size: 80,
                    color: Color(0xFFBB86FC),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Playlist chưa có bài hát',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hãy thêm bài hát từ trang chủ',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: playlist.length,
              itemBuilder: (context, index) {
                final song = playlist[index];

                return Dismissible(
                  key: ValueKey(song.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 28),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  onDismissed: (_) {
                    onRemoveSong(song);
                  },
                  child: SongTile(
                    song: song,
                    onTap: () => onSongSelected(song),
                  ),
                );
              },
            ),
    );
  }
}
