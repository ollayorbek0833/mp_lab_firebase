import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameCtl = TextEditingController();
  final _photoCtl = TextEditingController();
  bool _updating = false;

  User get _currentUser => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _nameCtl.text = widget.user.displayName ?? '';
    _photoCtl.text = widget.user.photoURL ?? '';
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _photoCtl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _updating = true);
    try {
      if (_nameCtl.text.trim() != (_currentUser.displayName ?? '')) {
        await _currentUser.updateDisplayName(_nameCtl.text.trim().isEmpty ? null : _nameCtl.text.trim());
      }
      if (_photoCtl.text.trim() != (_currentUser.photoURL ?? '')) {
        await _currentUser.updatePhotoURL(_photoCtl.text.trim().isEmpty ? null : _photoCtl.text.trim());
      }
      await _currentUser.reload();
      final reloaded = FirebaseAuth.instance.currentUser!;
      setState(() {
        _nameCtl.text = reloaded.displayName ?? '';
        _photoCtl.text = reloaded.photoURL ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error updating')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _refreshVerification() async {
    await _currentUser.reload();
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(verified ? 'Email is verified' : 'Email not verified')));
  }

  Future<void> _resendVerification() async {
    try {
      await _currentUser.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error sending')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final photo = user.photoURL;
    final displayName = user.displayName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          Row(children: [
            if (photo != null && photo.isNotEmpty) CircleAvatar(radius: 36, backgroundImage: NetworkImage(photo)) else const CircleAvatar(radius: 36, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.email ?? 'No email', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (displayName.isNotEmpty) Text(displayName),
                const SizedBox(height: 8),
                Text(user.emailVerified ? 'Verified' : 'Not verified', style: TextStyle(color: user.emailVerified ? Colors.green : Colors.orange)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          const Text('Update profile', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Display name')),
          const SizedBox(height: 8),
          TextField(controller: _photoCtl, decoration: const InputDecoration(labelText: 'Photo URL')),
          const SizedBox(height: 12),
          CustomButton(label: 'Save changes', onPressedAsync: _updateProfile),
          const SizedBox(height: 12),
          ElevatedButton(
            child: const Text("Open Messages"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: CustomButton(label: 'Resend verification', onPressedAsync: _resendVerification)),
            const SizedBox(width: 8),
            Expanded(child: CustomButton(label: 'Refresh status', onPressedAsync: _refreshVerification)),
          ]),
        ]),
      ),
    );
  }
}
