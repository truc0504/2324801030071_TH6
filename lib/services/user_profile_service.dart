import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Đồng bộ thông tin công khai của tài khoản vào users/{uid}.
/// Dùng merge để không ghi đè favoriteSongIds và các dữ liệu khác.
class UserProfileService {
  static Future<void> sync(User user) async {
    final data = <String, dynamic>{};
    final name = user.displayName?.trim();
    final email = user.email?.trim();

    if (name != null && name.isNotEmpty) {
      data['displayName'] = name;
    }
    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }

    if (data.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }
}
