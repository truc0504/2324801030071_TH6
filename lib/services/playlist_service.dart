import 'package:cloud_firestore/cloud_firestore.dart';

class MusicPlaylist {
  final String id;
  final String name;
  final List<String> songIds;
  const MusicPlaylist({required this.id, required this.name, required this.songIds});
}

class PlaylistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('playlists');

  Stream<List<MusicPlaylist>> watchPlaylists(String uid) =>
      _collection(uid).snapshots().map((query) {
        final result = query.docs.map((doc) {
          final data = doc.data();
          return MusicPlaylist(
            id: doc.id,
            name: (data['name'] as String?) ?? 'Playlist',
            songIds: (data['songIds'] as List?)?.whereType<String>().toList() ?? [],
          );
        }).toList();
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return result;
      });

  Future<void> create(String uid, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Tên Playlist không được để trống');
    await _collection(uid).add({
      'name': clean,
      'songIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rename(String uid, String id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Tên Playlist không được để trống');
    await _collection(uid).doc(id).update({'name': clean});
  }

  Future<void> delete(String uid, String id) => _collection(uid).doc(id).delete();

  Future<void> addSong(String uid, String id, String songId) =>
      _collection(uid).doc(id).update({'songIds': FieldValue.arrayUnion([songId])});

  Future<void> removeSong(String uid, String id, String songId) =>
      _collection(uid).doc(id).update({'songIds': FieldValue.arrayRemove([songId])});
}
