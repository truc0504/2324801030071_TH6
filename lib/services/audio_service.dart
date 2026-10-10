
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class MusicService extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();

  List<Song> songs = [];
  int currentIndex = -1;

  Song? get currentSong {
    if (currentIndex < 0 || currentIndex >= songs.length) {
      return null;
    }
    return songs[currentIndex];
  }

  Future<void> setPlaylist(List<Song> playlist) async {
    songs = List.from(playlist);
    currentIndex = -1;
    await player.stop();
    notifyListeners();
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songs.length) return;

    currentIndex = index;
    notifyListeners();

    try {
      await player.stop();
      await player.setUrl(songs[index].audioUrl);

      player.play().catchError((Object error) {
        debugPrint('Lỗi phát nhạc: $error');
      });
    } catch (e) {
      debugPrint('Không thể tải bài hát: $e');
      rethrow;
    }
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await player.pause();
    } else {
      if (currentSong == null) return;

      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }

      player.play().catchError((Object error) {
        debugPrint('Lỗi phát nhạc: $error');
      });
    }
  }

  Future<void> next() async {
    if (songs.isEmpty) return;

    final nextIndex = (currentIndex + 1) % songs.length;
    await playSong(nextIndex);
  }

  Future<void> previous() async {
    if (songs.isEmpty) return;

    final previousIndex =
        (currentIndex - 1 + songs.length) % songs.length;

    await playSong(previousIndex);
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
