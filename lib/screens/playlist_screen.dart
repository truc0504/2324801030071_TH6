import 'package:flutter/material.dart';

import '../data/song_data.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';
import '../widgets/song_tile.dart';

class PlaylistScreen extends StatelessWidget {
  final String uid;
  final List<Song> likedSongs;
  final void Function(Song song, List<Song> queue) onSongSelected;
  final void Function(Song song) onRemoveLiked;
  final PlaylistService playlistService;

  const PlaylistScreen({
    super.key,
    required this.uid,
    required this.likedSongs,
    required this.onSongSelected,
    required this.onRemoveLiked,
    required this.playlistService,
  });

  Future<String?> _askName(BuildContext context, {String initial = ''}) {
    String name = initial;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(initial.isEmpty ? 'Tạo Playlist' : 'Đổi tên Playlist'),
        content: TextFormField(
          initialValue: initial,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Tên Playlist'),
          onChanged: (value) => name = value,
          onFieldSubmitted: (value) {
            final clean = value.trim();
            if (clean.isNotEmpty) Navigator.of(dialogContext).pop(clean);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final clean = name.trim();
              if (clean.isNotEmpty) Navigator.of(dialogContext).pop(clean);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<bool> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không lưu được. Kiểm tra Internet và quyền Firestore.'),
          ),
        );
      }
      return false;
    }
  }

  void _openLiked(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pageContext) => Scaffold(
          appBar: AppBar(title: const Text('Bài hát đã thích')),
          body: likedSongs.isEmpty
              ? const Center(child: Text('Bạn chưa thích bài hát nào'))
              : ListView.builder(
                  itemCount: likedSongs.length,
                  itemBuilder: (context, index) {
                    final song = likedSongs[index];
                    return SongTile(
                      song: song,
                      onTap: () => onSongSelected(song, likedSongs),
                      onRemovePressed: () {
                        onRemoveLiked(song);
                        Navigator.of(pageContext).pop();
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _openPlaylist(BuildContext context, MusicPlaylist selected) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pageContext) => StreamBuilder<List<MusicPlaylist>>(
          stream: playlistService.watchPlaylists(uid),
          builder: (context, snapshot) {
            final matches = snapshot.data
                ?.where((playlist) => playlist.id == selected.id)
                .toList();
            final playlist = (matches != null && matches.isNotEmpty)
                ? matches.first
                : selected;
            final songs = demoSongs
                .where((song) => playlist.songIds.contains(song.id))
                .toList();
            return Scaffold(
              appBar: AppBar(
                title: Text(playlist.name),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'rename') {
                        final name = await _askName(pageContext, initial: playlist.name);
                        if (name == null || !pageContext.mounted) return;
                        await _run(pageContext,
                            () => playlistService.rename(uid, playlist.id, name));
                      } else if (action == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: pageContext,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Xóa Playlist?'),
                            content: Text('Xóa "${playlist.name}"? Bài hát đã thích vẫn được giữ.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !pageContext.mounted) return;
                        final success = await _run(pageContext,
                            () => playlistService.delete(uid, playlist.id));
                        if (success && pageContext.mounted) {
                          Navigator.of(pageContext).pop();
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                      PopupMenuItem(value: 'delete', child: Text('Xóa Playlist')),
                    ],
                  ),
                ],
              ),
              body: snapshot.hasError
                  ? const Center(child: Text('Không tải được Playlist.'))
                  : songs.isEmpty
                      ? const Center(child: Text('Playlist chưa có bài hát nào'))
                      : ListView.builder(
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            return SongTile(
                              song: song,
                              onTap: () => onSongSelected(song, songs),
                              onRemovePressed: () => _run(pageContext, () =>
                                  playlistService.removeSong(uid, playlist.id, song.id)),
                            );
                          },
                        ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thư viện')),
      body: StreamBuilder<List<MusicPlaylist>>(
        stream: playlistService.watchPlaylists(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Không tải được Playlist. Kiểm tra Firestore.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final playlists = snapshot.data!;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.pinkAccent),
                title: const Text('Bài hát đã thích'),
                subtitle: Text('${likedSongs.length} bài hát'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLiked(context),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Playlist của tôi',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      tooltip: 'Tạo Playlist',
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final name = await _askName(context);
                        if (name == null || !context.mounted) return;
                        await _run(context, () => playlistService.create(uid, name));
                      },
                    ),
                  ],
                ),
              ),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có Playlist. Nhấn + để tạo mới.',
                      style: TextStyle(color: Colors.white60)),
                ),
              for (final playlist in playlists)
                ListTile(
                  leading: const Icon(Icons.queue_music, color: Color(0xFFBB86FC)),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.songIds.length} bài hát'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPlaylist(context, playlist),
                ),
            ],
          );
        },
      ),
    );
  }
}
