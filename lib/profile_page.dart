import 'dart:io';
// imports
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Functional profile page: reads/writes `profiles` table and uploads avatar to
/// Supabase Storage (bucket: `avatars`). See the notes at the end for required
/// setup steps (create bucket, set public or configure URL generation).

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() { _profile = null; _loading = false; });
      return;
    }

  final res = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
  // maybeSingle returns null if not found
  setState(() { _profile = res; _loading = false; });
  }

  // The upload helper was intentionally removed; full-screen editor uses
  // `_uploadAvatarLocal` inside `EditProfilePage` instead.

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());

    final name = (_profile?['name'] as String?) ?? 'Unknown';
    final username = (_profile?['username'] as String?) ?? '';
    final phone = (_profile?['phone'] as String?) ?? '';
    final avatar = (_profile?['avatar_url'] as String?);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: cs.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: cs.onSurface),
            title: Text('Profile', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
            actions: [
              IconButton(icon: Icon(Icons.share_outlined, color: cs.onSurface), onPressed: () {}),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SingleChildScrollView(
                child:Container(
                // ensure the flexible space content sits below the toolbar/title
                padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 12, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.surface, const Color(0xFFF3F4F6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final didSave = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(builder: (_) => EditProfilePage(profile: _profile)),
                            );
                            if (didSave == true) await _loadProfile();
                          },
                          child: Hero(
                            tag: 'me-avatar',
                            child: avatar != null
                                ? CircleAvatar(radius: 34, backgroundImage: NetworkImage(avatar))
                                : CircleAvatar(radius: 34, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                _badge('KUET', Icons.verified_rounded, Colors.green),
                              ]),
                              const SizedBox(height: 4),
                              Text('@$username  •  $phone', style: TextStyle(color: cs.onSurfaceVariant)),
                              const SizedBox(height: 6),
                              Text('CSE • KUET • 2026', style: TextStyle(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.tonal(onPressed: () async {
                          final didSave = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => EditProfilePage(profile: _profile)),
                          );
                          if (didSave == true) await _loadProfile();
                        }, child: const Text('Edit profile')),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.verified_user_outlined), label: const Text('Verify KUET')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            _Stat(label: 'Posts', value: '12'),
                            _Divider(),
                            _Stat(label: 'Returned', value: '4'),
                            _Divider(),
                            _Stat(label: 'Claims', value: '2'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Material(
                color: cs.primary,
                elevation: 2,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 56,
                    child: TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      indicatorColor: cs.onPrimary,
                      labelColor: cs.onPrimary,
                      unselectedLabelColor: cs.onSecondary,
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Claims'),
                        Tab(text: 'Saved'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: const [
            _PostsTab(),
            _ClaimsTab(),
            _SavedTab(),
          ],
        ),
      ),
    );
  }
}

Widget _badge(String text, IconData icon, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  decoration: BoxDecoration(
    color: color.withOpacity(.12),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(text, style: TextStyle(fontSize: 12, color: color)),
  ]),
);

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: Theme.of(context).dividerColor);
  }
}

/// ----- TABS (existing placeholders kept) -----

class _PostsTab extends StatelessWidget {
  const _PostsTab();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 8,
      itemBuilder: (_, i) => _postCard(i),
    );
  }

  Widget _postCard(int i) {
    final isLost = i.isEven;
    final chipColor = isLost ? Colors.red[400]! : Colors.green[400]!;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network('https://picsum.photos/seed/p$i/1000/600', fit: BoxFit.cover),
            ),
            Positioned(
              left: 12, top: 12,
              child: Chip(
                backgroundColor: chipColor,
                label: Text(isLost ? 'LOST' : 'FOUND',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ]),
          ListTile(
            title: Text(isLost ? 'Lost: Wallet #$i' : 'Found: Phone #$i'),
            subtitle: const Text('Cafeteria • 2h ago • Electronics'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {},
              tooltip: 'Edit post',
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimsTab extends StatelessWidget {
  const _ClaimsTab();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.assignment_turned_in)),
        title: Text('Claim: Black Wallet #$i'),
        subtitle: const Text('Status: Pending • Owner reply expected'),
        trailing: TextButton(onPressed: () {}, child: const Text('View')),
      ),
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 3/4, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: 6,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network('https://picsum.photos/seed/s$i/600/800', fit: BoxFit.cover),
            const Positioned(right: 8, top: 8, child: Icon(Icons.bookmark, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// Settings tab removed from the UI per request.

/// Full-screen profile editor. Returns true when the profile was saved.
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;
  const EditProfilePage({super.key, this.profile});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;
  late final TextEditingController _nameController = TextEditingController(text: widget.profile?['name'] ?? '');
  late final TextEditingController _usernameController = TextEditingController(text: widget.profile?['username'] ?? '');
  late final TextEditingController _phoneController = TextEditingController(text: widget.profile?['phone'] ?? '');
  XFile? _picked;
  bool _saving = false;
  bool _avatarRemoved = false;

  Future<String?> _uploadAvatarLocal(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final user = supabase.auth.currentUser;
      if (user == null) return null;
      final path = 'avatars/${user.id}.jpg';
      await supabase.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      return supabase.storage.from('avatars').getPublicUrl(path);
    } catch (e, st) {
      debugPrint('upload error: $e\n$st');
      // rethrow so caller can display the concrete error
      rethrow;
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      String? avatarUrlFinal = widget.profile?['avatar_url'];
      if (_picked != null) {
        try {
          final uploaded = await _uploadAvatarLocal(_picked!);
          avatarUrlFinal = uploaded;
        } catch (e) {
          debugPrint('upload exception: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload avatar: $e')));
          setState(() => _saving = false);
          return;
        }
      }
      // If user removed avatar in the editor and didn't pick a replacement,
      // ensure we persist avatar_url as null instead of restoring the old value.
      if (_avatarRemoved && _picked == null) {
        avatarUrlFinal = null;
      }

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not signed in');

      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': user.email ?? widget.profile?['email'],
        'phone': _phoneController.text.trim(),
        'avatar_url': avatarUrlFinal,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // check for error in response (supabase-dart usually throws on error)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('profile save error: $e\n$st');
      final msg = e.toString();
      if (msg.contains('column') && msg.contains('avatar_url')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database missing column `avatar_url`. Add this column to `profiles` table.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  final avatarUrl = widget.profile?['avatar_url'] as String?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(onPressed: _saving ? null : _saveProfile, child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save', style: TextStyle(color: Colors.white)))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
                if (img != null) setState(() => _picked = img);
              },
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Colors.grey.shade200,
        backgroundImage: _avatarRemoved
          ? null
          : (_picked == null
            ? (avatarUrl != null ? NetworkImage(avatarUrl) as ImageProvider : null)
            : FileImage(File(_picked!.path)) as ImageProvider),
        child: !_avatarRemoved && _picked == null && avatarUrl == null ? Text((_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?'), style: const TextStyle(fontSize: 36)) : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200);
                if (img != null) setState(() => _picked = img);
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit profile picture'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Remove profile picture'),
                    content: const Text('Are you sure you want to remove your profile picture?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
                    ],
                  ),
                );
                if (confirmed != true) return;
                // perform delete: delete object from storage and clear avatar_url
                  try {
                  final user = supabase.auth.currentUser;
                  if (user == null) throw Exception('Not signed in');
                  final path = 'avatars/${user.id}.jpg';
                  await supabase.storage.from('avatars').remove([path]);
                  // Try to update existing profile row. If it doesn't exist, upsert with required fields.
          final updated = await supabase.from('profiles')
            .update({'avatar_url': null, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', user.id)
            .select();
          // If update returned no rows, perform an upsert providing required NOT NULL fields.
          final updatedList = updated as List<dynamic>;
          if (updatedList.isEmpty) {
                    final defaultName = widget.profile?['name'] ?? user.email?.split('@').first ?? 'User';
                    final defaultUsername = widget.profile?['username'] ?? defaultName.toLowerCase().replaceAll(' ', '_');
                    await supabase.from('profiles').upsert({
                      'id': user.id,
                      'name': defaultName,
                      'username': defaultUsername,
                      'email': user.email,
                      'avatar_url': null,
                      'updated_at': DateTime.now().toIso8601String(),
                    });
                  }
                  setState(() {
                    _picked = null;
                    _avatarRemoved = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture removed')));
                } catch (e) {
                  debugPrint('remove avatar error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove avatar: $e')));
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove profile picture'),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
