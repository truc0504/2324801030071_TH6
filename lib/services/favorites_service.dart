import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('users').doc(uid);

  Stream<Set<String>> watchFavorites(String uid) {
    return _document(uid).snapshots().map((snapshot) {
      final values = snapshot.data()?['favoriteSongIds'];
      if (values is! List) return <String>{};
      return values.whereType<String>().toSet();
    });
  }

  Future<void> setFavorite(String uid, String songId, bool favorite) async {
    await _document(uid).set({
      'favoriteSongIds': favorite
          ? FieldValue.arrayUnion([songId])
          : FieldValue.arrayRemove([songId]),
    }, SetOptions(merge: true));
  }
}
