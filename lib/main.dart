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
import 'services/audio_service.dart';
import 'services/favorites_service.dart';
import 'widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MelodyMusicApp());
}

class MelodyMusicApp extends StatelessWidget {
  const MelodyMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melody Music',
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
        stream: FirebaseAuth.instance.authStateChanges(),
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
          return user == null
              ? const AuthScreen()
              : MusicMainScreen(key: ValueKey(user.uid), user: user);
        },
      ),
    );
  }
}

class MusicMainScreen extends StatefulWidget {
  final User user;
  const MusicMainScreen({super.key, required this.user});

  @override
  State<MusicMainScreen> createState() => _MusicMainScreenState();
}

class _MusicMainScreenState extends State<MusicMainScreen> {
  final MusicService musicService = MusicService();
  final FavoritesService favoritesService = FavoritesService();
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
    try {
      await favoritesService.setFavorite(widget.user.uid, song.id, isFavorite);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được Playlist. Kiểm tra Internet và quyền Firestore.')),
      );
    }
  }

  Future<void> _playSong(Song song) async {
    final index = demoSongs.indexWhere((item) => item.id == song.id);
    if (index < 0) return;
    try {
      await musicService.playSong(index);
      if (mounted) _openPlayer();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể phát bài hát. Hãy kiểm tra Internet.')),
      );
    }
  }

  void _openPlayer() {
    if (musicService.currentSong == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(musicService: musicService)),
    );
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
      stream: favoritesService.watchFavorites(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Không tải được Playlist. Kiểm tra Firestore và kết nối mạng.')),
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
                onSignOut: _signOut,
              ),
              PlaylistScreen(
                playlist: favoriteSongs,
                onSongSelected: _playSong,
                onRemoveSong: (song) => _setFavorite(song, false),
              ),
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
                    label: 'Playlist',
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
