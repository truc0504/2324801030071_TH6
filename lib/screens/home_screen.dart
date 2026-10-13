
import 'package:flutter/material.dart';

import '../data/song_data.dart';
import '../models/song.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Song song) onSongSelected;
  final Set<String> favoriteIds;
  final void Function(Song song) onToggleFavorite;
  final VoidCallback? onSignOut;
  final void Function(Song song) onAddToPlaylist;

  const HomeScreen({
    super.key,
    required this.onSongSelected,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onSignOut,
    required this.onAddToPlaylist,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.toLowerCase().trim();

    final filteredSongs = demoSongs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),

      appBar: AppBar(
        backgroundColor: const Color(0xFF12121C),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Melody Music',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.onSignOut != null) IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout, color: Colors.white70),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(
              Icons.headphones,
              color: Color(0xFFBB86FC),
              size: 28,
            ),
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm bài hát hoặc nghệ sĩ...',
                hintStyle: const TextStyle(
                  color: Colors.white54,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFBB86FC),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                          });

                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF252538),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFBB86FC),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  searchQuery.isEmpty
                      ? 'Khám phá âm nhạc'
                      : 'Kết quả tìm kiếm',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${filteredSongs.length} bài hát',
                  style: const TextStyle(
                    color: Color(0xFFBB86FC),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredSongs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off,
                          color: Color(0xFFBB86FC),
                          size: 70,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tìm thấy bài hát',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thử tìm kiếm với từ khóa khác nhé!',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 16,
                    ),
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];

                      final isFavorite =
                          widget.favoriteIds.contains(song.id);

                      return SongTile(
                        song: song,
                        isFavorite: isFavorite,
                        onFavoritePressed: () {
                          widget.onToggleFavorite(song);
                        },
                        onAddToPlaylist: () => widget.onAddToPlaylist(song),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          widget.onSongSelected(song);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
