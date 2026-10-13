import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';

class AccountScreen extends StatefulWidget {
  final User? user;
  final Future<void> Function() onSignOut;
  final VoidCallback onLogin;

  const AccountScreen({super.key, required this.user, required this.onSignOut, required this.onLogin});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Future<void> _editName(User user) async {
    String value = user.displayName ?? '';
    final name = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Chỉnh sửa tên hiển thị'),
      content: TextFormField(initialValue: value, autofocus: true, maxLength: 50,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Họ và tên'),
        onChanged: (text) => value = text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
        FilledButton(onPressed: () { if (value.trim().isNotEmpty) Navigator.pop(dialogContext, value.trim()); }, child: const Text('Lưu')),
      ],
    ));
    if (name == null) return;
    try {
      await user.updateDisplayName(name);
      await user.reload();
      await UserProfileService.sync(user);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể cập nhật tên. Vui lòng thử lại.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    if (user == null) {
      return SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircleAvatar(radius: 42, backgroundColor: Color(0xFF473365), child: Icon(Icons.person_outline, size: 46)),
          const SizedBox(height: 18),
          const Text('Bạn đang nghe nhạc với tư cách Khách', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Đăng nhập để lưu bài hát yêu thích và tạo Playlist cá nhân.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: widget.onLogin, child: const Text('Đăng nhập / Đăng ký')),
        ]),
      )));
    }
    final currentUser = FirebaseAuth.instance.currentUser ?? user;
    final name = currentUser.displayName?.trim();
    final displayName = name != null && name.isNotEmpty ? name : 'Chưa cập nhật tên';
    final email = currentUser.email ?? 'Chưa có email';
    final isGoogle = currentUser.providerData.any((provider) => provider.providerId == 'google.com');
    return SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Tài khoản', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      Center(child: CircleAvatar(radius: 42, backgroundColor: const Color(0xFF473365),
        child: Text(name != null && name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
          style: const TextStyle(fontSize: 34, color: Colors.white)))),
      const SizedBox(height: 14),
      Text(displayName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(email, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 14),
      Center(child: TextButton.icon(onPressed: () => _editName(currentUser), icon: const Icon(Icons.edit_outlined), label: const Text('Chỉnh sửa tên hiển thị'))),
      const SizedBox(height: 18),
      Card(color: const Color(0xFF1D1D2B), child: Column(children: [
        ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(email)),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.verified_user_outlined), title: const Text('Phương thức đăng nhập'),
          subtitle: Text(isGoogle ? 'Google' : 'Email và mật khẩu')),
      ])),
      const SizedBox(height: 24),
      OutlinedButton.icon(onPressed: () async {
        final confirm = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text('Bạn muốn đăng xuất khỏi Tryv Music? Bạn vẫn có thể nghe nhạc ở chế độ Khách.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Đăng xuất')),
          ],
        ));
        if (confirm == true) await widget.onSignOut();
      }, icon: const Icon(Icons.logout), label: const Text('Đăng xuất'),
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFBB86FC), padding: const EdgeInsets.symmetric(vertical: 16))),
    ]));
  }
}
