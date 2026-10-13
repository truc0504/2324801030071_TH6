
import 'package:flutter/material.dart';
import '../models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemovePressed;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onFavoritePressed,
    this.onAddToPlaylist,
    this.onRemovePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF252538),
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            song.imageUrl,
            width: 55,
            height: 55,
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
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          song.artist,
          style: const TextStyle(color: Colors.white60),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (onFavoritePressed != null) IconButton(
            tooltip: isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
            onPressed: onFavoritePressed,
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.pinkAccent : Colors.white70)),
          if (onAddToPlaylist != null) IconButton(
            tooltip: 'Thêm vào Playlist', onPressed: onAddToPlaylist,
            icon: const Icon(Icons.more_vert)),
          if (onRemovePressed != null) IconButton(
            tooltip: 'Xóa khỏi danh sách', onPressed: onRemovePressed,
            icon: const Icon(Icons.remove_circle_outline)),
          if (onFavoritePressed == null && onAddToPlaylist == null && onRemovePressed == null)
            const Icon(Icons.play_circle_fill, color: Color(0xFFBB86FC)),
        ]),
        onTap: onTap,
      ),
    );
  }
}
