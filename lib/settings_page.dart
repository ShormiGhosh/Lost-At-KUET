import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Login_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loaded = true;
    });
  }

  Future<void> _signOut() async {
    try {
      // Sign out from Supabase
      final supabase = Supabase.instance.client;
      await supabase.auth.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('email');

      // Navigate to login page
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    } catch (error) {
      print('Error during sign out: $error');
      // Even if there's an error, still navigate to login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    }
  }
  Future<void> _deleteAccount() async {
    try {
      final supabase = Supabase.instance.client;

      // Call the database function to delete user
      await supabase.rpc('delete_user_data');

      // Sign out from Supabase
      await supabase.auth.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('email');

      // Navigate to login page
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      }
    } catch (error) {
      print('Error during account deletion: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Add this method after _showSignOutDialog
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading ? _buildLoading() : _buildSettingsList(),
    );
  }

  bool get _isLoading => !_loaded;

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // App Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text('App Information', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(title: 'Version', value: '1.0.0'),
                      _InfoRow(title: 'Build', value: '2025.1.1'),
                      _InfoRow(title: 'Last Updated', value: 'Oct 11, 2025'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign Out Section
              // Sign Out Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_circle_outlined, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text('Account', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: Icon(Icons.logout_outlined, color: Colors.grey[600]),
                        title: const Text('Sign Out'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        contentPadding: EdgeInsets.zero,
                        onTap: _showSignOutDialog,
                      ),
                      // Add this new ListTile for delete account
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red[600]),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        contentPadding: EdgeInsets.zero,
                        onTap: _showDeleteAccountDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Credits Section at the bottom
        _buildCreditsSection(),
      ],
    );
  }

  Widget _buildCreditsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Developed by KUET Students',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Collaborators:',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'mostafa2107095@stud.kuet.ac.bd',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          Text(
            'sultana2107108@stud.kuet.ac.bd',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          Text(
            'ghosh2107109@stud.kuet.ac.bd',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }



}


class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}