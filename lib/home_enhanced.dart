import 'dart:math';

import 'package:LostAtKuet/chat_detail_screen.dart';
import 'package:LostAtKuet/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_post_screen.dart';
import 'models/chat.dart';
import 'models/post.dart';
import 'models/profile.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'chat_screen.dart';
import 'services/chat_service.dart';
import 'notifications_page.dart';

const _amber = Color(0xFFFFC815); // warm amber
const _charcoal = Color(0xFF292929); // dark header bg

ThemeData lostKuetTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _amber,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _charcoal,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  scaffoldBackgroundColor: const Color(0xFFF7F7F9),
);

/// ---------- ROOT WITH BOTTOM NAV ----------
class LostKuetShell extends StatefulWidget {
  const LostKuetShell({super.key});
  @override
  State<LostKuetShell> createState() => _LostKuetShellState();
}

class _LostKuetShellState extends State<LostKuetShell>
    with TickerProviderStateMixin {
  int _index = 0;
  final _pages = const [
    HomeEnhancedPage(),
    ProfilePage(),
    SettingsPage(),
    ChatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _pages[_index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        indicatorColor: _amber.withOpacity(.20),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: _AnimIcon(icon: Icons.home_outlined),
            selectedIcon: _AnimIcon(icon: Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _AnimIcon(icon: Icons.person_outline),
            selectedIcon: _AnimIcon(icon: Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: _AnimIcon(icon: Icons.settings_outlined),
            selectedIcon: _AnimIcon(icon: Icons.settings),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: _AnimIcon(icon: Icons.chat_bubble_outline),
            selectedIcon: _AnimIcon(icon: Icons.chat_bubble),
            label: 'Chat',
          ),
        ],
      ),
      floatingActionButton:
          _index == 0
              ? AnimatedScale(
                scale: 1,
                duration: const Duration(milliseconds: 250),
                child: FloatingActionButton.extended(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreatePostScreen(),
                        ),
                      ),
                  icon: const Icon(Icons.add),
                  label: const Text('Post'),
                ),
              )
              : null,
    );
  }
}

class _AnimIcon extends StatelessWidget {
  final IconData icon;
  const _AnimIcon({required this.icon});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.96, end: 1),
    duration: const Duration(milliseconds: 180),
    builder: (_, s, __) => Transform.scale(scale: s, child: Icon(icon)),
  );
}

void _showPostSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder:
        (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: const Text('Post Lost / Found form…'),
        ),
  );
}

/// ---------- HOME PAGE ----------
class HomeEnhancedPage extends StatefulWidget {
  const HomeEnhancedPage({super.key});
  @override
  State<HomeEnhancedPage> createState() => _HomeEnhancedPageState();
}

class _HomeEnhancedPageState extends State<HomeEnhancedPage>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();
  final _searchFocus = FocusNode();
  final supabase = Supabase.instance.client;
  List<Post> get _filteredPosts =>
      _posts
          .where((post) => post.status.toLowerCase() == _status.toLowerCase())
          .toList();

  bool _filtersExpanded = true;
  String _status = 'Lost';

  late final AnimationController _headerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();

  late final AnimationController _staggerCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  final _postService = PostService(Supabase.instance.client);
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scroll.addListener(() {
      final hide = _scroll.offset > 140;
      if (hide == _filtersExpanded) setState(() => _filtersExpanded = !hide);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchFocus.dispose();
    _headerCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: _charcoal,
              padding: const EdgeInsets.fromLTRB(16, 44, 8, 12),
              child: SafeArea(
                bottom: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + title + location (slide+fade in)
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _headerCtrl,
                        curve: const Interval(0, .9, curve: Curves.easeOut),
                      ),
                    ),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .15),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _headerCtrl,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically center
                            children: [
                              Image.asset(
                                'assets/images/lostatkuet_icon.png',
                                height: 32,
                                width: 32, // Add explicit width
                                fit: BoxFit.contain, // Ensure proper scaling
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                'Lost @ KUET',
                                style: TextStyle(
                                  fontFamily: 'Caveat-VariableFont_wght',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Search bar (expands when focused)
          SliverToBoxAdapter(
            child: Container(
              color: _charcoal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      _searchFocus.hasFocus
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                          : const [],
                ),
                child: Focus(
                  onFocusChange: (_) => setState(() {}),
                  child: TextField(
                    focusNode: _searchFocus,
                    readOnly: true, // Make it non-editable
                    onTap: () {
                      // Open SearchPage when tapped
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                      );
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search item, place…',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (q) {},
                  ),
                ),
              ),
            ),
          ),

          // Toggle + Filters
          SliverToBoxAdapter(
            child: Container(
              color: _charcoal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: SegmentedButton<String>(
                        key: ValueKey(_status),
                        segments: const [
                          ButtonSegment(value: 'Lost', label: Text('Lost')),
                          ButtonSegment(value: 'Found', label: Text('Found')),
                        ],
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (s) =>
                                s.contains(WidgetState.selected)
                                    ? const Color(0xFFFFC815)
                                    : Colors.white,
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            Colors.black87,
                          ),
                        ),
                        selected: {_status},
                        onSelectionChanged:
                            (s) => setState(() => _status = s.first),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),
                  // notifications (fade-in from right)
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _headerCtrl,
                      curve: const Interval(.3, 1, curve: Curves.easeOut),
                    ),
                  ),
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(.15, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _headerCtrl,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NotificationsPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Latest posts (staggered)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Latest posts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverList.builder(
            itemCount: _isLoading ? 1 : _filteredPosts.length,
            itemBuilder: (_, i) {
              if (_isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (_filteredPosts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('No ${_status.toLowerCase()} items found'),
                  ),
                );
              }

              final post = _filteredPosts[i];
              final anim = CurvedAnimation(
                parent: _staggerCtrl,
                curve: Interval(
                  i * 0.06,
                  min((i * 0.06) + 0.55, 1.0),
                  curve: Curves.easeOut,
                ),
              );

              return AnimatedBuilder(
                animation: anim,
                builder:
                    (context, child) => Opacity(
                      opacity: anim.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - anim.value) * 18),
                        child: child,
                      ),
                    ),
                child: _PostCard(
                  index: i,
                  title: post.title,
                  description: post.description,
                  status: post.status,
                  chipColor:
                      post.status.toLowerCase() == 'lost'
                          ? Colors.red[400]!
                          : Colors.green[400]!,
                  imageUrl: post.imageUrl,
                  location: post.location,
                  createdAt: post.createdAt,
                  category: post.category,
                  onTap:
                      () => Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 350),
                          pageBuilder:
                              (_, a, __) => FadeTransition(
                                opacity: a,
                                child: _DetailsPage(
                                  heroTag: 'post-$i',
                                  imageUrl: post.imageUrl ?? '',
                                  title: post.title,
                                  description: post.description,
                                  status: post.status,
                                  location: post.location,
                                  category: post.category,
                                  createdAt: post.createdAt,
                                  posterId: post.userId,
                                ),
                              ),
                        ),
                      ),
                  posterId: post.userId,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  Future<void> _loadPosts() async {
    try {
      setState(() => _isLoading = true);
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Modify getPosts to exclude current user's posts
      final posts = await supabase
          .from('posts')
          .select()
          .neq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _posts = posts.map((post) => Post.fromJson(post)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading posts: $e'); // Use debugPrint instead of print
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
      setState(() => _isLoading = false);
    }
  }
}

class _PostCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final String status;
  final Color chipColor;
  final String location;
  final DateTime createdAt;
  final String? imageUrl;
  final String category;
  final VoidCallback onTap;
  final String posterId;

  const _PostCard({
    required this.index,
    required this.title,
    required this.description,
    required this.status,
    required this.chipColor,
    required this.location,
    required this.createdAt,
    this.imageUrl,
    required this.category,
    required this.onTap,
    required this.posterId,
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
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Hero(
              tag: 'post-$index',
              flightShuttleBuilder: (_, animation, __, ___, ____) {
                return AnimatedBuilder(
                  animation: animation,
                  builder:
                      (context, child) => Container(
                        decoration: const BoxDecoration(color: Colors.white),
                        child: child,
                      ),
                );
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    (imageUrl != null && imageUrl!.isNotEmpty)
                        ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Text(
                                    'No image available',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text(
                              'No image available',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Chip(
                        label: Text(
                          status,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: chipColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const Spacer(),
                      Text(
                        _getTimeAgo(createdAt),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Chat button: open/create direct chat with poster
                      IconButton(
                        onPressed: () async {
                          final supabase = Supabase.instance.client;
                          final currentUser = supabase.auth.currentUser;
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sign in to message'),
                              ),
                            );
                            return;
                          }
                          final chatService = ChatService(supabase);
                          try {
                            final chat = await chatService
                                .createOrGetDirectChat(
                                  currentUser.id,
                                  posterId,
                                );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailPage(chat: chat),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error opening chat: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        tooltip: 'Message poster',
                      ),
                      // Inbox shortcut: open chat list
                      IconButton(
                        onPressed:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ChatPage()),
                            ),
                        icon: const Icon(Icons.mail_outline),
                        tooltip: 'Open inbox',
                      ),
                    ],
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
  final String title;
  final String description;
  final String status;
  final String location;
  final String category;
  final DateTime createdAt;
  final String posterId;

  const _DetailsPage({
    required this.heroTag,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.status,
    required this.location,
    required this.category,
    required this.createdAt,
    required this.posterId,
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
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rest of the build method remains the same
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
              child:
                  (imageUrl.isNotEmpty)
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Text(
                                  'No image available',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                      )
                      : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text(
                            'No image available',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
            ),
          ),
          // Status chip
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
              backgroundColor:
                  status.toLowerCase() == 'lost'
                      ? Colors.red[400]
                      : Colors.green[400],
            ),
          ),

          // Details form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailField(icon: Icons.title, label: 'Title', value: title),
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

          // Contact button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final supabase = Supabase.instance.client;
                final currentUser = supabase.auth.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You must be signed in to contact the poster',
                      ),
                    ),
                  );
                  return;
                }

                final chatService = ChatService(supabase);
                try {
                  final chat = await chatService.createOrGetDirectChat(
                    currentUser.id,
                    posterId,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailPage(chat: chat),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error opening chat: $e')),
                  );
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contact Poster'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF292929),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
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
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final supabase = Supabase.instance.client;
  List<Post> _allPosts = [];
  bool _isLoading = true;

  List<Post> get _filteredPosts {
    if (_searchQuery.isEmpty) return _allPosts;

    final query = _searchQuery.toLowerCase();

    return _allPosts.where((post) {
      return post.title.toLowerCase().contains(query) ||
          post.description.toLowerCase().contains(query) ||
          post.location.toLowerCase().contains(query) ||
          post.category.toLowerCase().contains(query) ||
          post.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAllPosts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPosts() async {
    try {
      setState(() => _isLoading = true);

      final posts = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allPosts = posts.map((post) => Post.fromJson(post)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading posts for search: $e');
      setState(() => _isLoading = false);
    }
  }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search item, color, place…',
            border: InputBorder.none,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchQuery.isEmpty
              ? _buildSearchSuggestions()
              : _buildSearchResults(),
    );
  }

  Widget _buildSearchSuggestions() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Type to search through all posts from the main newsfeed'),
          SizedBox(height: 8),
          Text('Examples: wallet, phone, cafeteria, library, academic'),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts found'),
            Text('Try different keywords'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];

        // Use the same _PostCard constructor that matches your home page
        return _PostCard(
          index: index,
          title: post.title,
          description: post.description,
          status: post.status,
          chipColor:
              post.status.toLowerCase() == 'lost'
                  ? Colors.red[400]!
                  : Colors.green[400]!,
          location: post.location,
          createdAt: post.createdAt,
          imageUrl: post.imageUrl,
          category: post.category,
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                pageBuilder:
                    (_, a, __) => FadeTransition(
                      opacity: a,
                      child: _DetailsPage(
                        heroTag: 'search-$index',
                        imageUrl:
                            post.imageUrl ??
                            'https://picsum.photos/seed/$index/1000/600',
                        title: post.title,
                        description: post.description,
                        status: post.status,
                        location: post.location,
                        category: post.category,
                        createdAt: post.createdAt,
                        posterId: post.userId,
                      ),
                    ),
              ),
            );
          },
          posterId: post.userId,
        );
      },
    );
  }
}
