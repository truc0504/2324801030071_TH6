import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/song_data.dart';
import 'firebase_options.dart';
import 'models/song.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/player_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/account_screen.dart';
import 'services/audio_service.dart';
import 'services/favorites_service.dart';
import 'services/playlist_service.dart';
import 'widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TryvMusicApp());
}

class TryvMusicApp extends StatelessWidget {
  const TryvMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tryv Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12121C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBB86FC),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Không thể kiểm tra đăng nhập.')),
            );
          }
          final user = snapshot.data;
          return MusicMainScreen(key: ValueKey(user?.uid ?? 'guest'), user: user);
        },
      ),
    );
  }
}

class MusicMainScreen extends StatefulWidget {
  final User? user;
  const MusicMainScreen({super.key, required this.user});

  @override
  State<MusicMainScreen> createState() => _MusicMainScreenState();
}

class _MusicMainScreenState extends State<MusicMainScreen> {
  final MusicService musicService = MusicService();
  final FavoritesService favoritesService = FavoritesService();
  final PlaylistService playlistService = PlaylistService();
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    musicService.addListener(_refreshPlayer);
    musicService.setPlaylist(demoSongs);
  }

  void _refreshPlayer() {
    if (mounted) setState(() {});
  }

  Future<void> _setFavorite(Song song, bool isFavorite) async {
    final user = widget.user;
    if (user == null) { _requireLogin(); return; }
    try {
      await favoritesService.setFavorite(user.uid, song.id, isFavorite);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được bài hát yêu thích. Kiểm tra Internet và quyền Firestore.')),
      );
    }
  }

  Future<void> _playSong(Song song, [List<Song>? queue]) async {
    final songs = queue ?? demoSongs;
    final index = songs.indexWhere((item) => item.id == song.id);
    if (index < 0) return;
    try {
      await musicService.setPlaylist(songs);
      await musicService.playSong(index);
      if (mounted) _openPlayer();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát bài hát. Kiểm tra Internet.')));
    }
  }

  Future<void> _addToPlaylist(Song song) async {
    final user = widget.user;
    if (user == null) { _requireLogin(); return; }
    try {
      final playlists = await playlistService.watchPlaylists(user.uid).first;
      if (!mounted) return;
      await showModalBottomSheet<void>(context: context, isScrollControlled: true,
        builder: (sheetContext) => SafeArea(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Thêm vào Playlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (playlists.isEmpty) const Padding(padding: EdgeInsets.all(12),
              child: Text('Chưa có Playlist. Vào Thư viện và nhấn + để tạo mới.')),
            for (final playlist in playlists) ListTile(
              leading: Icon(playlist.songIds.contains(song.id) ? Icons.check_circle : Icons.queue_music),
              title: Text(playlist.name),
              subtitle: playlist.songIds.contains(song.id) ? const Text('Đã có bài hát này') : null,
              onTap: playlist.songIds.contains(song.id) ? null : () async {
                try {
                  await playlistService.addSong(user.uid, playlist.id, song.id);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
              } catch (_) {
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể thêm bài hát. Kiểm tra Firestore.'),
                    ),
                  );
                }
              }
              },
            ),
          ]),
        )));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được Playlist. Kiểm tra Firestore.')));
    }
  }

  void _openPlayer() {
    if (musicService.currentSong == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(musicService: musicService)),
    );
  }

  Future<void> _requireLogin() async {
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng nhập để lưu nhạc'),
        content: const Text('Bạn cần đăng nhập để lưu bài hát yêu thích và quản lý Playlist cá nhân.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Để sau')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Đăng nhập')),
        ],
      ),
    );
    if (shouldLogin == true && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
    }
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
  }

  Future<void> _signOut() async {
    try {
      await musicService.player.stop();
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng xuất. Vui lòng thử lại.')),
      );
    }
  }

  @override
  void dispose() {
    musicService.removeListener(_refreshPlayer);
    musicService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: widget.user == null
          ? Stream<Set<String>>.value(<String>{})
          : favoritesService.watchFavorites(widget.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Không tải được bài hát yêu thích. Kiểm tra Firestore và kết nối mạng.')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final favoriteIds = snapshot.data!;
        final favoriteSongs = demoSongs
            .where((song) => favoriteIds.contains(song.id))
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF12121C),
          body: IndexedStack(
            index: selectedTab,
            children: [
              HomeScreen(
                onSongSelected: _playSong,
                favoriteIds: favoriteIds,
                onToggleFavorite: (song) => _setFavorite(
                  song, !favoriteIds.contains(song.id),
                ),
                onSignOut: widget.user == null ? null : _signOut,
                onAddToPlaylist: _addToPlaylist,
              ),
              if (widget.user == null)
                _GuestLibrary(onLogin: _openLogin)
              else PlaylistScreen(
                uid: widget.user!.uid,
                likedSongs: favoriteSongs,
                onSongSelected: (song, queue) => _playSong(song, queue),
                onRemoveLiked: (song) => _setFavorite(song, false),
                playlistService: playlistService,
              ),
              AccountScreen(user: widget.user, onSignOut: _signOut, onLogin: _openLogin),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiniPlayer(musicService: musicService, onTap: _openPlayer),
              NavigationBar(
                backgroundColor: const Color(0xFF1D1D2B),
                indicatorColor: const Color(0xFF473365),
                selectedIndex: selectedTab,
                onDestinationSelected: (index) => setState(() => selectedTab = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Trang chủ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music),
                    label: 'Thư viện',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Tài khoản',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


class _GuestLibrary extends StatelessWidget {
  final VoidCallback onLogin;
  const _GuestLibrary({required this.onLogin});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thư viện')),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.library_music_outlined, color: Color(0xFFBB86FC), size: 70),
        const SizedBox(height: 16),
        const Text('Thư viện cá nhân', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Đăng nhập để lưu bài hát đã thích, tạo Playlist và đồng bộ trên tài khoản của bạn.', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: onLogin, child: const Text('Đăng nhập / Đăng ký')),
      ]),
    )),
  );
}
