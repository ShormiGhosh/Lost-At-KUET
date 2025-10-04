import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: cs.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: cs.onSurface),
            title: Text('Profile', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
            actions: [
              IconButton(icon: Icon(Icons.share_outlined, color: cs.onSurface), onPressed: _share),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(16, 36, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.surface, const Color(0xFFF3F4F6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _Header(onEdit: _edit, onVerify: _verify),
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
                        Tab(text: 'Settings'),
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
            _SettingsTab(),
          ],
        ),
      ),
    );
  }

  void _edit() {}
  void _verify() {}
  void _share() {}
}

class _Header extends StatelessWidget {
  final VoidCallback onEdit, onVerify;
  const _Header({required this.onEdit, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar
            Hero(
              tag: 'me-avatar',
              child: CircleAvatar(radius: 34, backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?img=12',
              )),
            ),
            const SizedBox(width: 12),
            // Name + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Sadia Mostafa',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    _badge('KUET', Icons.verified_rounded, Colors.green),
                  ]),
                  const SizedBox(height: 4),
                  Text('@sadia  •  +8801XXXXXXX',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('CSE • KUET • 2026', style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Actions
        Row(
          children: [
            FilledButton.tonal(onPressed: onEdit, child: const Text('Edit profile')),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onVerify,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Verify KUET'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Stats
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
    );
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
}

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

/// ----- TABS -----

class _PostsTab extends StatelessWidget {
  const _PostsTab();
  @override
  Widget build(BuildContext context) {
    // Replace with your provider/stream of user posts.
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

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        SwitchListTile(
          value: true, onChanged: (_) {},
          title: const Text('Show phone number on posts'),
          subtitle: const Text('You can hide your phone and allow in-app chat only'),
        ),
        SwitchListTile(
          value: true, onChanged: (_) {},
          title: const Text('Notifications'),
          subtitle: const Text('Nearby matches, claims, chat messages'),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change password'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Verify KUET ID'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () {},
        ),
      ],
    );
  }
}
