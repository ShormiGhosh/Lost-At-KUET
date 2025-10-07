import 'dart:math';

import 'package:LostAtKuet/chat_detail_screen.dart';
import 'package:LostAtKuet/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_post_screen.dart';
import 'models/chat.dart';
import 'models/post.dart';
import 'models/profile.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'chat_screen.dart';

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
  List<Post> get _filteredPosts => _posts.where((post) =>
  post.status.toLowerCase() == _status.toLowerCase()
  ).toList();

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // replace with your asset
                          // put assets/lostatkuet_icon.png in pubspec
                          Image.asset(
                            'assets/lostatkuet_icon.png',
                            height: 36,
                            errorBuilder: (_, __, ___) {
                              return Icon(
                                Icons.location_on,
                                size: 36,
                                color: _amber,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Lost @ KUET',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const _LocRow(),
                        ],
                      ),
                    ),
                    const Spacer(),
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
                        onPressed: () {},
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
                    decoration: const InputDecoration(
                      hintText: 'Search item, color, place…',
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
                                    ? _amber.withOpacity(.25)
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
                  IconButton(
                    onPressed:
                        () => setState(
                          () => _filtersExpanded = !_filtersExpanded,
                        ),
                    icon: const Icon(Icons.tune, color: Colors.white),
                    tooltip: 'Filters',
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedOpacity(
              opacity: _filtersExpanded ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: SizedBox(
                  height: _filtersExpanded ? 46 : 0,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _Chip('Category'),
                      _Chip('Distance'),
                      _Chip('Time'),
                      _Chip('Reward'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Near you
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Near you',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(onPressed: () {}, child: const Text('See all')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder:
                    (_, i) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      builder:
                          (_, s, child) =>
                              Transform.scale(scale: s, child: child),
                      child: _MiniCard(i: i),
                    ),
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
                  status: post.status, // Changed from isLost
                  chipColor:
                      post.status.toLowerCase() == 'lost'
                          ? Colors.red[400]!
                          : Colors.green[400]!,
                  imageUrl: post.imageUrl,
                  location: post.location,
                  createdAt: post.createdAt,
                  onTap:
                      () => Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 350),
                          pageBuilder:
                              (_, a, __) => FadeTransition(
                                opacity: a,
                                child: _DetailsPage(
                                  heroTag: 'post-$i',
                                  imageUrl:
                                      post.imageUrl ??
                                      'https://picsum.photos/seed/$i/1000/600',
                                  title: post.title, description: '${post.description}', status: post.status, location: post.location, category: post.category, createdAt: post.createdAt,
                                ),
                              ),
                        ),
                      ), category: '${post.category}',
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
      final posts = await _postService.getPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e'); // Add debug print
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
      setState(() => _isLoading = false);
    }
  }
}

class _LocRow extends StatelessWidget {
  const _LocRow();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
        SizedBox(width: 4),
        Text(
          'KUET, Khulna',
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        onSelected: (_) {},
        selectedColor: _amber.withOpacity(.25),
        showCheckmark: false,
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final int i;
  const _MiniCard({required this.i});
  @override
  Widget build(BuildContext context) {
    final img = 'https://picsum.photos/seed/mini$i/600/340';
    return SizedBox(
      width: 160,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => _DetailsPage(
                        heroTag: 'mini-$i',
                        imageUrl: img,
                        title: 'Black Wallet', description: 'A black leather wallet lost near cafeteria.', status: 'Lost', location: 'Cafeteria', category: 'Accessories', createdAt: DateTime.now().subtract(const Duration(hours: 2)),
                      ),
                ),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'mini-$i',
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(img, fit: BoxFit.cover),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Black Wallet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  '📍 Cafeteria • 2h',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final String status; // Changed from bool isLost
  final Color chipColor;
  final String location;
  final DateTime createdAt;
  final String? imageUrl;
  final String category;
  final VoidCallback onTap;

  const _PostCard({
    required this.index,
    required this.title,
    required this.description,
    required this.status, // Changed from isLost
    required this.chipColor,
    required this.location,
    required this.createdAt,
    this.imageUrl,
    required this.category,
    required this.onTap,
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
      return '${difference.inMinutes} minutes ago';  // Added 'return' here
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'post-$index',
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: imageUrl != null
                    ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text('No image available'),
                    ),
                  ),
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
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
                      const Icon(Icons.location_on, size: 16, color: Colors.black54),
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
      return '${difference.inMinutes} minutes ago';  // Added 'return' here
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
        // Hero image
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
            backgroundColor: status.toLowerCase() == 'lost'
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

        // Contact button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              final chat = Chat(
                id: 'chat_${title.hashCode}',
                user1Id: 'current_user_id',
                user2Id: 'poster_id',
                otherUser: Profile(
                  id: 'poster_id',
                  username: 'Poster Name',
                ),
                createdAt: DateTime.now(),
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(chat: chat),
                ),
              );
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
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
