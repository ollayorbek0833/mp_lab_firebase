import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final newName = _nameCtl.text.trim();
    final newPhoto = _photoCtl.text.trim();

    setState(() => _updating = true);
    try {
      // Only call updates when value changed (optional)
      if (newName != (_currentUser.displayName ?? '')) {
        await _currentUser.updateDisplayName(newName.isEmpty ? null : newName);
      }
      if (newPhoto != (_currentUser.photoURL ?? '')) {
        await _currentUser.updatePhotoURL(newPhoto.isEmpty ? null : newPhoto);
      }

      // Must reload to get updated values from backend
      await _currentUser.reload();

      // Get fresh reference
      final reloaded = FirebaseAuth.instance.currentUser!;
      setState(() {
        _nameCtl.text = reloaded.displayName ?? '';
        _photoCtl.text = reloaded.photoURL ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Failed to update profile';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate or StreamBuilder should handle navigation away from HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final photo = user.photoURL;
    final displayName = user.displayName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Logout'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                if (photo != null && photo.isNotEmpty)
                  CircleAvatar(radius: 36, backgroundImage: NetworkImage(photo))
                else
                  const CircleAvatar(radius: 36, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email ?? 'No email', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (displayName.isNotEmpty) Text(displayName),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Update profile', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Display name')),
            const SizedBox(height: 8),
            TextField(controller: _photoCtl, decoration: const InputDecoration(labelText: 'Photo URL')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _updating ? null : _updateProfile,
              child: _updating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
