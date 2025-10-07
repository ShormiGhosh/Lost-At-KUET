import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'chat_screen.dart';

/// ---------- THEME (pixie-like, yellow on dark header) ----------
const _amber = Color(0xFFF4B400); // warm amber
const _charcoal = Color(0xFF2E2F34); // dark header bg

ThemeData lostKuetTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _amber, brightness: Brightness.light),
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

class _LostKuetShellState extends State<LostKuetShell> with TickerProviderStateMixin {
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
          NavigationDestination(icon: _AnimIcon(icon: Icons.home_outlined), selectedIcon: _AnimIcon(icon: Icons.home), label: 'Home'),
          NavigationDestination(icon: _AnimIcon(icon: Icons.person_outline), selectedIcon: _AnimIcon(icon: Icons.person), label: 'Profile'),
          NavigationDestination(icon: _AnimIcon(icon: Icons.settings_outlined), selectedIcon: _AnimIcon(icon: Icons.settings), label: 'Settings'),
          NavigationDestination(icon: _AnimIcon(icon: Icons.chat_bubble_outline), selectedIcon: _AnimIcon(icon: Icons.chat_bubble), label: 'Chat'),
        ],
      ),
      floatingActionButton: _index == 0
          ? AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 250),
              child: FloatingActionButton.extended(
                onPressed: () => _showPostSheet(context),
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
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 8,
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

class _HomeEnhancedPageState extends State<HomeEnhancedPage> with TickerProviderStateMixin {
  final _scroll = ScrollController();
  final _searchFocus = FocusNode();




  bool _filtersExpanded = true;
  bool _isLost = true;

  late final AnimationController _headerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450))..forward();

  late final AnimationController _staggerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))..forward();


  @override
  void initState() {
    super.initState();
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
    return CustomScrollView(
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
                    opacity: CurvedAnimation(parent: _headerCtrl, curve: const Interval(0, .9, curve: Curves.easeOut))),
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // replace with your asset
                        // put assets/lostatkuet_icon.png in pubspec
                        Image.asset('assets/lostatkuet_icon.png', height: 36, errorBuilder: (_, __, ___) {
                          return Icon(Icons.location_on, size: 36, color: _amber);
                        }),
                        const SizedBox(height: 6),
                        const Text('Lost @ KUET',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        const SizedBox(height: 2),
                        const _LocRow(),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // notifications (fade-in from right)
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _headerCtrl, curve: const Interval(.3, 1, curve: Curves.easeOut))),
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(.15, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut)),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
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
                boxShadow: _searchFocus.hasFocus
                    ? [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 18, offset: const Offset(0, 8))]
                    : const [],
              ),
              child: Focus(
                onFocusChange: (_) => setState(() {}),
                child: TextField(
                  readOnly: true, // ADD THIS
                  onTap: () { // ADD THIS BLOCK
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchPage()),
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search item, color, place…',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ),

    // Show search results or normal UI

    ...[
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
    child: SegmentedButton<bool>(
    key: ValueKey(_isLost),
    segments: const [
    ButtonSegment(value: true, label: Text('Lost')),
    ButtonSegment(value: false, label: Text('Found')),
    ],
    style: ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((s) =>
    s.contains(WidgetState.selected) ? _amber.withOpacity(.25) : Colors.white),
    foregroundColor: WidgetStateProperty.all(Colors.black87),
    ),
    selected: {_isLost},
    onSelectionChanged: (s) => setState(() => _isLost = s.first),
    ),
    ),
    ),
    const SizedBox(width: 8),
    IconButton(
    onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
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
    children: const [_Chip('Category'), _Chip('Distance'), _Chip('Time'), _Chip('Reward')],
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
    Text('Near you', style: Theme.of(context).textTheme.titleMedium),
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
    itemBuilder: (_, i) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.92, end: 1),
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutBack,
    builder: (_, s, child) => Transform.scale(scale: s, child: child),
    child: _MiniCard(i: i),
    ),
    ),
    ),
    ),

    // Latest posts
    SliverToBoxAdapter(
    child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Text('Latest posts', style: Theme.of(context).textTheme.titleMedium),
    ),
    ),
      SliverList.builder(
        itemCount: 12,
        itemBuilder: (_, listIndex) {
          final i = listIndex;
    final start = i * 0.06;
    final end = (start + .55).clamp(0.0, 1.0);
    final anim = CurvedAnimation(parent: _staggerCtrl, curve: Interval(start, end, curve: Curves.easeOut));
    return AnimatedBuilder(
    animation: anim,
    builder: (context, child) => Opacity(
    opacity: anim.value,
    child: Transform.translate(offset: Offset(0, (1 - anim.value) * 18), child: child),
    ),
    child: _PostCard(
    index: i,
    isLost: _isLost ? i.isEven : !i.isEven,
    title: _isLost ? 'Lost: Black Wallet #$i' : 'Found: Phone #$i',
    subtitle: 'Near Cafeteria • ${i + 1}h ago • Electronics',
    chipColor: _isLost ? Colors.red[400]! : Colors.green[400]!,
    onTap: () => Navigator.of(context).push(
    PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, a, __) => FadeTransition(
    opacity: a,
    child: _DetailsPage(
    heroTag: 'post-$i',
    imageUrl: 'https://picsum.photos/seed/$i/1000/600',
    title: _isLost ? 'Lost: Black Wallet #$i' : 'Found: Phone #$i',
    ),

    ),
    ),
    ),
    ),
    );
    },
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 96)),
    ],
    ],
    );
  }
}

class _LocRow extends StatelessWidget {
  const _LocRow();
  @override
  Widget build(BuildContext context) {
    return Row(children: const [
      Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
      SizedBox(width: 4),
      Text('KUET, Khulna', style: TextStyle(fontSize: 13, color: Colors.white70)),
    ]);
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
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _DetailsPage(heroTag: 'mini-$i', imageUrl: img, title: 'Black Wallet'),
          )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'mini-$i',
                child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(img, fit: BoxFit.cover)),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Black Wallet', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text('📍 Cafeteria • 2h', style: TextStyle(fontSize: 12)),
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
  final String title, subtitle;
  final bool isLost;
  final Color chipColor;
  final VoidCallback onTap;
  const _PostCard({required this.index, required this.title, required this.subtitle, required this.isLost, required this.chipColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final img = 'https://picsum.photos/seed/$index/1000/600';
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'post-$index',
                  child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(img, fit: BoxFit.cover)),
                ),
                Positioned(
                  left: 12, top: 12,
                  child: Chip(label: Text(isLost ? 'LOST' : 'FOUND', style: const TextStyle(color: Colors.white)), backgroundColor: chipColor),
                ),
                Positioned(
                  right: 6, top: 6,
                  child: IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: () {}),
                ),
              ],
            ),
            ListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: FilledButton.tonal(onPressed: () {}, child: const Text('Contact')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsPage extends StatelessWidget {
  final String heroTag, imageUrl, title;
  const _DetailsPage({required this.heroTag, required this.imageUrl, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: ListView(
        children: [
          Hero(tag: heroTag, child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(imageUrl, fit: BoxFit.cover))),
          Padding(padding: const EdgeInsets.all(16), child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Description, time, location, contact, reward…'),
          ),
          const SizedBox(height: 40),
        ],
      ),
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

  List<Map<String, dynamic>> get _filteredPosts {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();

    // This EXACTLY matches what's shown on your home page
    final List<Map<String, dynamic>> allHomePagePosts = List.generate(12, (index) {
      final isLost = index.isEven;

      // Your home page shows: "Lost: Black Wallet #0", "Found: Phone #1", etc.
      return {
        'title': isLost ? 'Lost: Black Wallet #$index' : 'Found: Phone #$index',
        'location': 'Cafeteria',
        'time': '${index + 1}h',
        'category': 'Electronics',
        'isLost': isLost,
        'searchableText': isLost ?
        'lost black wallet cafeteria electronics ${index + 1}h' :
        'found phone cafeteria electronics ${index + 1}h',
      };
    });

    // Add "Near you" posts (6 Black Wallet posts)
    final List<Map<String, dynamic>> nearYouPosts = List.generate(6, (index) {
      return {
        'title': 'Black Wallet',
        'location': 'Cafeteria',
        'time': '2h',
        'category': 'Personal',
        'isLost': true,
        'searchableText': 'black wallet cafeteria personal 2h near you',
      };
    });

    // Combine all posts
    final List<Map<String, dynamic>> allPosts = [...allHomePagePosts, ...nearYouPosts];

    return allPosts.where((post) {
      final searchableText = post['searchableText'].toString().toLowerCase();
      final title = post['title'].toString().toLowerCase();

      // Search in the combined searchable text
      return searchableText.contains(query) || title.contains(query);
    }).toList();
  }
  @override
  void initState() {
    super.initState();
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
      body: _searchQuery.isEmpty
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
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        final i = index; // Use index for consistent image seeding

        return _PostCard(
          index: i,
          isLost: post['isLost'],
          title: post['title'],
          subtitle: 'Near ${post['location']} • ${post['time']} ago • ${post['category']}',
          chipColor: post['isLost'] ? Colors.red[400]! : Colors.green[400]!,
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (_, a, __) => FadeTransition(
                  opacity: a,
                  child: _DetailsPage(
                    heroTag: 'search-$i',
                    imageUrl: 'https://picsum.photos/seed/$i/1000/600',
                    title: post['title'],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

