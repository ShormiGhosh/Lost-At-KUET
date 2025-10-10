import 'dart:io';
// imports
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/post.dart';

/// Functional profile page: reads/writes `profiles` table and uploads avatar to
/// Supabase Storage (bucket: `avatars`). See the notes at the end for required
/// setup steps (create bucket, set public or configure URL generation).

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  late final TabController _tabs = TabController(length: 3, vsync: this);
  int _postCount = 0;
  int _claimCount = 0;
  final GlobalKey<_PostsTabState> _postsTabKey = GlobalKey<_PostsTabState>();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPostCount();
    _loadClaimCount();
  }

  Future<void> _loadPostCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final countData = await supabase
          .from('posts')
          .select()
          .eq('user_id', user.id)
          .count();

      setState(() => _postCount = countData.count);
    } catch (e) {
      debugPrint('Error loading post count: $e');
    }
  }


  Future<void> _loadClaimCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final countData = await supabase
          .from('posts')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'Lost')
          .count();

      setState(() => _claimCount = countData.count);
    } catch (e) {
      debugPrint('Error loading claim count: $e');
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _profile = null;
        _loading = false;
      });
      return;
    }

    final res =
        await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
    // maybeSingle returns null if not found
    setState(() {
      _profile = res;
      _loading = false;
    });
  }
  void refreshAllTabs() {
    _loadPostCount();
    _loadClaimCount();
    // You can also trigger Posts tab refresh here if needed
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
    final department = (_profile?['department'] as String?) ?? 'Department';
    final batch = (_profile?['batch'] as String?) ?? 'Batch';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (_, __) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 260,
                backgroundColor: cs.surface,
                elevation: 0,
                iconTheme: IconThemeData(color: cs.onSurface),
                title: Text(
                  'Profile',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.share_outlined, color: cs.onSurface),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: SingleChildScrollView(
                    child: Container(
                      // ensure the flexible space content sits below the toolbar/title
                      padding: EdgeInsets.fromLTRB(
                        16,
                        kToolbarHeight + 12,
                        16,
                        12,
                      ),
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
                                  final didSave = await Navigator.of(
                                    context,
                                  ).push<bool>(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => EditProfilePage(
                                            profile: _profile,
                                          ),
                                    ),
                                  );
                                  if (didSave == true) await _loadProfile();
                                },
                                child: Hero(
                                  tag: 'me-avatar',
                                  child:
                                      avatar != null
                                          ? CircleAvatar(
                                            radius: 34,
                                            backgroundImage: NetworkImage(
                                              avatar,
                                            ),
                                          )
                                          : CircleAvatar(
                                            radius: 34,
                                            child: Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    phone.isNotEmpty
                                        ? Text('@$username  •  $phone')
                                        : Text('@$username'),

                                    const SizedBox(height: 6),
                                    Text(
                                      '$department • KUET • $batch',
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: () async {
                                  final didSave = await Navigator.of(
                                    context,
                                  ).push<bool>(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => EditProfilePage(
                                            profile: _profile,
                                          ),
                                    ),
                                  );
                                  if (didSave == true) await _loadProfile();
                                },
                                child: const Text('Edit profile'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                    child: TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      indicatorColor: cs.onPrimary,
                      labelColor: cs.onPrimary,
                      unselectedLabelColor: cs.onSecondary,
                      tabs: [
                        Tab(text: 'Posts ($_postCount)'),
                        Tab(text: 'Claims ($_claimCount)'), // Changed from 'Claims (4)'
                        Tab(text: 'Saved (2)'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _PostsTab(key: _postsTabKey, onPostUpdated: _loadPostCount), // Add key here
            _ClaimsTab(postsTabKey: _postsTabKey), // Pass the key to Claims tab
            _SavedTab(),
          ],
        ),
      ),
    );
  }
}

/// ----- TABS (existing placeholders kept) -----
class _PostsTab extends StatefulWidget {
  final VoidCallback? onPostUpdated;
  const _PostsTab({this.onPostUpdated, Key? key}) : super(key: key);
  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _userPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }
  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      await _loadUserPosts();
    } catch (e) {
      debugPrint('Error loading posts: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
  Future<void> _loadUserPosts() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final posts = await supabase
          .from('posts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _userPosts = List<Map<String, dynamic>>.from(posts as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading user posts: $e');
      setState(() => _loading = false);
    }
  }

  void _showPostDetails(Post post) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: _PostDetailsPage(
            heroTag: 'profile-post-${post.id}',
            imageUrl: post.imageUrl,
            title: post.title,
            description: post.description,
            status: post.status,
            location: post.location,
            category: post.category,
            createdAt: post.createdAt,
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userPosts.isEmpty) {
      return const Center(child: Text('No posts yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _userPosts.length,
      itemBuilder: (_, i) => _postCard(_userPosts[i]),
    );
  }

  Widget _postCard(Map<String, dynamic> postMap) {
    final post = Post.fromJson(postMap);
    final isLost = post.status.toLowerCase() == 'lost';
    final chipColor = isLost ? Colors.red[400]! : Colors.green[400]!;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPostDetails(post),
        child: Column(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: post.imageUrl != null
                      ? Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Text('No image available')),
                    ),
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: const Center(child: Text('No image available')),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Chip(
                    backgroundColor: chipColor,
                    label: Text(
                      post.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            ListTile(
              title: Text(post.title),
              subtitle: Text(
                [
                  post.location,
                  _getTimeAgo(post.createdAt),
                  post.category,
                ].join(' • '),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPostScreen(post: post),
                        ),
                      );
                      if (updated == true) {
                        await _loadPosts();
                      }
                    },
                    tooltip: 'Edit post',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete post?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && mounted) {
                        await _deletePost(post.id);
                      }
                    },
                    tooltip: 'Delete post',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
  Future<void> _deletePost(int postId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete post?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Delete from Supabase
      await supabase
          .from('posts')
          .delete()
          .match({'id': postId});

      // Remove post from local list and update UI
      if (mounted) {
        setState(() {
          // Remove post from local list
          _userPosts.removeWhere((post) => post['id'] == postId);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      debugPrint('Error deleting post: $error');
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ClaimsTab extends StatefulWidget {
  final GlobalKey<_PostsTabState>? postsTabKey;
  const _ClaimsTab({this.postsTabKey});
  @override
  State<_ClaimsTab> createState() => _ClaimsTabState();
}

class _ClaimsTabState extends State<_ClaimsTab> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _lostPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLostPosts();
  }

  Future<void> _loadLostPosts() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final posts = await supabase
          .from('posts')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'Lost') // Only get lost items
          .order('created_at', ascending: false);

      setState(() {
        _lostPosts = List<Map<String, dynamic>>.from(posts as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading lost posts: $e');
      setState(() => _loading = false);
    }
  }
  // Helper method to refresh Posts tab
  void _refreshPostsTab() {
    // Find the Posts tab state and refresh it
    final postsTabState = context.findAncestorStateOfType<_PostsTabState>();
    postsTabState?._loadUserPosts();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lostPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined,
                size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No lost items'),
            Text('All your items have been found!'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _lostPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final post = _lostPosts[index];
        return _claimCard(post, index);
      },
    );
  }

  Widget _claimCard(Map<String, dynamic> post, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Icon(Icons.assignment_turned_in,
              color: Colors.orange),
        ),
        title: Text(
          'Claim: ${post['title']} #$index',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Status: Pending • Owner reply expected'),
        trailing: TextButton(
          onPressed: () => _viewClaimDetails(post),
          child: const Text('View'),
        ),
      ),
    );
  }

  void _viewClaimDetails(Map<String, dynamic> post) async {
    final shouldRefresh = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ClaimDetailsPage(post: post),
      ),
    );

    // If the item was marked as found, refresh the claims list and counts
    if (shouldRefresh == true && mounted) {
      await _loadLostPosts(); // This will reload and exclude found items

      // Also refresh the post count
      final profileState = context.findAncestorStateOfType<_ProfilePageState>();
      if (profileState != null) {
        profileState._loadPostCount(); // Refresh post count
        profileState._loadClaimCount(); // Refresh claim count

        // Trigger refresh of Posts tab to show updated status using the GlobalKey
        if (widget.postsTabKey?.currentState != null) {
          widget.postsTabKey!.currentState!._loadUserPosts();
        }
      }
    }
  }


}
class _SavedTab extends StatelessWidget {
  const _SavedTab();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder:
          (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://picsum.photos/seed/s$i/600/800',
                  fit: BoxFit.cover,
                ),
                const Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(Icons.bookmark, color: Colors.white),
                ),
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
  late final TextEditingController _nameController = TextEditingController(
    text: widget.profile?['name'] ?? '',
  );
  late final TextEditingController _usernameController = TextEditingController(
    text: widget.profile?['username'] ?? '',
  );
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.profile?['phone'] ?? '',
  );
  late final TextEditingController _departmentController = TextEditingController(
    text: widget.profile?['department'] ?? '',
  );
  late final TextEditingController _batchController = TextEditingController(
    text: widget.profile?['batch'] ?? '',
  );
  XFile? _picked;
  bool _saving = false;
  bool _avatarRemoved = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _batchController.dispose();
    super.dispose();
  }
  Future<String?> _uploadAvatarLocal(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final user = supabase.auth.currentUser;
      if (user == null) return null;
      final path = 'avatars/${user.id}.jpg';
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload avatar: $e')),
          );
          setState(() => _saving = false);
          return;
        }
      }
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
        'department': _departmentController.text.trim(),
        'batch': _batchController.text.trim(),
        'avatar_url': avatarUrlFinal,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('profile save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
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
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white),
            )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1200,
                );
                if (img != null) setState(() => _picked = img);
              },
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    _avatarRemoved
                        ? null
                        : (_picked == null
                            ? (avatarUrl != null
                                ? NetworkImage(avatarUrl) as ImageProvider
                                : null)
                            : FileImage(File(_picked!.path)) as ImageProvider),
                child:
                    !_avatarRemoved && _picked == null && avatarUrl == null
                        ? Text(
                          (_nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : '?'),
                          style: const TextStyle(fontSize: 36),
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final img = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1200,
                );
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
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Remove profile picture'),
                        content: const Text(
                          'Are you sure you want to remove your profile picture?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Remove'),
                          ),
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
                  final updated =
                      await supabase
                          .from('profiles')
                          .update({
                            'avatar_url': null,
                            'updated_at': DateTime.now().toIso8601String(),
                          })
                          .eq('id', user.id)
                          .select();
                  // If update returned no rows, perform an upsert providing required NOT NULL fields.
                  final updatedList = updated as List<dynamic>;
                  if (updatedList.isEmpty) {
                    final defaultName =
                        widget.profile?['name'] ??
                        user.email?.split('@').first ??
                        'User';
                    final defaultUsername =
                        widget.profile?['username'] ??
                        defaultName.toLowerCase().replaceAll(' ', '_');
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile picture removed')),
                  );
                } catch (e) {
                  debugPrint('remove avatar error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove avatar: $e')),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove profile picture'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _batchController,
              decoration: const InputDecoration(
                labelText: 'Batch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ClaimDetailsPage extends StatelessWidget {
  final Map<String, dynamic> post;

  const _ClaimDetailsPage({required this.post});

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Card(
              color: Colors.orange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: Pending',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text('Owner reply expected'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Item image
            if (post['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post['image_url'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(child: Text('No image available')),
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Item details in card format with checkboxes
            _ClaimDetailItem(
              icon: Icons.title,
              label: 'Item',
              value: post['title'] ?? 'Untitled',
            ),
            SizedBox(height: 8),
            _ClaimDetailItem(
              icon: Icons.description,
              label: 'Description',
              value: post['description'] ?? 'No description',
            ),
            SizedBox(height: 8),
            _ClaimDetailItem(
              icon: Icons.category,
              label: 'Category',
              value: post['category'] ?? 'Uncategorized',
              isChecked: true,
            ),
            SizedBox(height: 8),
            _ClaimDetailItem(
              icon: Icons.location_on,
              label: 'Last Seen',
              value: post['location'] ?? 'Unknown location',
            ),
            SizedBox(height: 8),
            _ClaimDetailItem(
              icon: Icons.access_time,
              label: 'Reported',
              value: _getTimeAgo(DateTime.parse(post['created_at'])),
            ),

            SizedBox(height: 24),

            // Mark as Found button (full width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _markAsFound(context, post['id']);
                },
                icon: Icon(Icons.check_circle_outline),
                label: Text('Mark as Found'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAsFound(BuildContext context, int postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Found?'),
        content: const Text('This item will be marked as found and removed from your claims. The post will remain in your Posts section.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Found'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final supabase = Supabase.instance.client;
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Update post status to 'Found' - this keeps the post in "Posts" but removes it from "Claims"
        await supabase
            .from('posts')
            .update({'status': 'Found'})
            .eq('id', postId);

        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item marked as found!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to claims list with refresh signal
        Navigator.of(context).pop(true);

      } catch (e) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ClaimDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isChecked;

  const _ClaimDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox-like icon
            Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              color: isChecked ? Colors.green : Colors.grey,
              size: 20,
            ),
            SizedBox(width: 12),
            // Icon
            Icon(icon, size: 20, color: Colors.grey),
            SizedBox(width: 8),
            // Label and value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
class _DetailsPage extends StatelessWidget {
  final String heroTag;
  final String imageUrl;
  final String title;final String description;
  final String status;
  final String location;
  final String category;
  final DateTime createdAt;

  const _DetailsPage({
    required this.heroTag,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.status,
    required this.location,
    required this.category,
    required this.createdAt,
  });

  String _getTimeAgo(DateTime dateTime) {
    // ... (implementation of _getTimeAgo)
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (implementation of build method for _DetailsPage)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        backgroundColor: const Color(0xFF292929),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          Hero(
            tag: heroTag,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('No image available'),
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Text('No image available'),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Chip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: status.toLowerCase() == 'lost'
                  ? Colors.red[400]
                  : Colors.green[400],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailField(
                  icon: Icons.title,
                  label: 'Title',
                  value: title,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  icon: Icons.description,
                  label: 'Description',
                  value: description,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  icon: Icons.category,
                  label: 'Category',
                  value: category,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: location,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  icon: Icons.access_time,
                  label: 'Posted',
                  value: _getTimeAgo(createdAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
class _PostDetailsPage extends StatelessWidget {
  final String heroTag;
  final String? imageUrl;
  final String title;
  final String description;
  final String status;
  final String location;
  final String category;
  final DateTime createdAt;

  const _PostDetailsPage({
    required this.heroTag,
    this.imageUrl,
    required this.title,
    required this.description,
    required this.status,
    required this.location,
    required this.category,
    required this.createdAt,
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    }  else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: const Color(0xFF292929),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          Hero(
            tag: heroTag,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl != null
                  ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text('No image available')),
                ),
              )
                  : Container(
                color: Colors.grey[200],
                child: const Center(child: Text('No image available')),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Chip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: status.toLowerCase() == 'lost'
                  ? Colors.red[400]
                  : Colors.green[400],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailField(
                  icon: Icons.title,
                  label: 'Title',
                  value: title,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  icon: Icons.description,
                  label: 'Description',
                  value: description,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  icon: Icons.category,
                  label: 'Category',
                  value: category,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: location,
                ),
                const SizedBox(height: 16),
                _DetailField(
                  icon: Icons.access_time,
                  label: 'Posted',
                  value: _getTimeAgo(createdAt),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Electronics';
  String _selectedStatus = 'Lost';
  bool _loading = false;
  String? _imagePath;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing post data
    _titleController.text = widget.post.title;
    _descriptionController.text = widget.post.description;
    _locationController.text = widget.post.location;
    _selectedCategory = widget.post.category;
    _selectedStatus = widget.post.status;
    _imagePath = widget.post.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (_loading) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    setState(() => _loading = true);

    try {
      await _supabase
          .from('posts')
          .update({
        'title': title,
        'description': description,
        'location': location,
        'category': _selectedCategory,
        'status': _selectedStatus,
        'image_url': _imagePath,
      })
          .eq('id', widget.post.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating post: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    try {
      setState(() => _loading = true);

      // Delete old image if exists
      if (_imagePath != null) {
        final oldFileName = _imagePath!.split('/').last;
        try {
          await _supabase.storage.from('posts').remove([oldFileName]);
        } catch (e) {
          debugPrint('Error deleting old image: $e');
        }
      }

      // Upload new image
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}_${widget.post.id}.$fileExt';

      await _supabase.storage.from('posts').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final imageUrl = _supabase.storage.from('posts').getPublicUrl(fileName);

      setState(() => _imagePath = imageUrl);

      // Update post with new image URL
      await _supabase
          .from('posts')
          .update({'image_url': imageUrl})
          .eq('id', widget.post.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeImage() async {
    try {
      setState(() => _loading = true);

      // Delete image from storage
      if (_imagePath != null) {
        final fileName = _imagePath!.split('/').last;
        await _supabase.storage.from('posts').remove([fileName]);
      }

      // Update post to remove image URL
      await _supabase
          .from('posts')
          .update({'image_url': null})
          .eq('id', widget.post.id);

      setState(() => _imagePath = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing image: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updatePost,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_imagePath != null)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Text('Error loading image')),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _pickImage,
                        tooltip: 'Change image',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove image?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await _removeImage();
                          }
                        },
                        tooltip: 'Remove image',
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photo'),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: ['Lost', 'Found']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedStatus = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: [
              'Wallet',
              'Keys',
              'Electronics',
              'Clothing',
              'Book',
              'Stationary item',
              'Others',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}