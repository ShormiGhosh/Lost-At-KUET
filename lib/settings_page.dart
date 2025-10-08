import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // initialize with defaults to avoid late initialization errors
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _biometricAuth = false;
  bool _autoSync = true;
  double _mapRadius = 5.0;
  String _language = 'English';
  String _themeColor = 'Amber';
  bool _loaded = false; // becomes true once settings are read

  final List<String> _languages = ['English', 'Bengali', 'Hindi', 'Arabic'];
  final List<String> _themeColors = ['Amber', 'Blue', 'Green', 'Purple', 'Pink'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _locationEnabled = prefs.getBool('location') ?? true;
      _biometricAuth = prefs.getBool('biometric') ?? false;
      _autoSync = prefs.getBool('autoSync') ?? true;
      _mapRadius = prefs.getDouble('mapRadius') ?? 5.0;
      _language = prefs.getString('language') ?? 'English';
      _themeColor = prefs.getString('themeColor') ?? 'Amber';
      _loaded = true;
    });
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _changeThemeMode(bool value) {
    setState(() => _isDarkMode = value);
    _saveSetting('darkMode', value);
    // Apply theme change immediately
    // You can integrate this with your theme provider
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    _saveSetting('notifications', value);
    // Actually enable/disable notifications
  }

  void _toggleLocation(bool value) {
    setState(() => _locationEnabled = value);
    _saveSetting('location', value);
    // Actually enable/disable location services
  }

  void _toggleBiometricAuth(bool value) {
    setState(() => _biometricAuth = value);
    _saveSetting('biometric', value);
    // Implement biometric authentication
  }

  void _toggleAutoSync(bool value) {
    setState(() => _autoSync = value);
    _saveSetting('autoSync', value);
    // Control auto-sync functionality
  }

  void _updateMapRadius(double value) {
    setState(() => _mapRadius = value);
    _saveSetting('mapRadius', value);
    // Update search radius in your app
  }

  void _changeLanguage(String? value) {
    if (value != null) {
      setState(() => _language = value);
      _saveSetting('language', value);
      // Implement language change
    }
  }

  void _changeThemeColor(String? value) {
    if (value != null) {
      setState(() => _themeColor = value);
      _saveSetting('themeColor', value);
      // Implement theme color change
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear cache-related data (keep settings)
    await prefs.remove('cachedPosts');
    await prefs.remove('cachedImages');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    }
  }

  Future<void> _resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This clears ALL settings

    // Reload default settings
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All settings reset to default')),
      );
    }
  }

  void _signOut() {
    // Implement actual sign out logic
    // Clear user data, tokens, etc.
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2E2F34),
        foregroundColor: Colors.white,
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Appearance Section
        _SettingsSection(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          children: [
            _SettingSwitch(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              value: _isDarkMode,
              onChanged: _changeThemeMode,
            ),
            _SettingDropdown(
              icon: Icons.color_lens_outlined,
              title: 'Theme Color',
              value: _themeColor,
              items: _themeColors,
              onChanged: _changeThemeColor,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Notifications Section
        _SettingsSection(
          title: 'Notifications',
          icon: Icons.notifications_outlined,
          children: [
            _SettingSwitch(
              icon: Icons.notifications_active,
              title: 'Push Notifications',
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
            _SettingSwitch(
              icon: Icons.vibration_outlined,
              title: 'Vibration',
              value: _notificationsEnabled, // Linked to main notification setting
              onChanged: _toggleNotifications,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Privacy & Security Section
        _SettingsSection(
          title: 'Privacy & Security',
          icon: Icons.security_outlined,
          children: [
            _SettingSwitch(
              icon: Icons.location_on_outlined,
              title: 'Location Services',
              value: _locationEnabled,
              onChanged: _toggleLocation,
            ),
            _SettingSwitch(
              icon: Icons.fingerprint_outlined,
              title: 'Biometric Authentication',
              value: _biometricAuth,
              onChanged: _toggleBiometricAuth,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // App Preferences Section
        _SettingsSection(
          title: 'App Preferences',
          icon: Icons.settings_outlined,
          children: [
            _SettingDropdown(
              icon: Icons.language_outlined,
              title: 'Language',
              value: _language,
              items: _languages,
              onChanged: _changeLanguage,
            ),
            _SettingSwitch(
              icon: Icons.sync_outlined,
              title: 'Auto Sync',
              value: _autoSync,
              onChanged: _toggleAutoSync,
            ),
            _SettingSlider(
              icon: Icons.map_outlined,
              title: 'Search Radius',
              value: _mapRadius,
              min: 1,
              max: 20,
              unit: 'km',
              onChanged: _updateMapRadius,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Support Section
        _SettingsSection(
          title: 'Support',
          icon: Icons.help_outline,
          children: [
            _SettingTile(
              icon: Icons.help_center_outlined,
              title: 'Help & Support',
              onTap: () => _showHelpSupport(),
            ),
            _SettingTile(
              icon: Icons.bug_report_outlined,
              title: 'Report a Bug',
              onTap: () => _reportBug(),
            ),
            _SettingTile(
              icon: Icons.star_outline,
              title: 'Rate App',
              onTap: () => _rateApp(),
            ),
            _SettingTile(
              icon: Icons.share_outlined,
              title: 'Share App',
              onTap: () => _shareApp(),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // App Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Information', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _InfoRow(title: 'Version', value: '1.0.0'),
                _InfoRow(title: 'Build', value: '2024.1.1'),
                _InfoRow(title: 'Last Updated', value: 'Dec 15, 2024'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Danger Zone
        Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Text('Danger Zone', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red[700])),
                  ],
                ),
                const SizedBox(height: 12),
                _DangerButton(
                  icon: Icons.delete_outline,
                  title: 'Clear Cache',
                  onTap: _showClearCacheDialog,
                ),
                _DangerButton(
                  icon: Icons.restart_alt_outlined,
                  title: 'Reset All Settings',
                  onTap: _showResetDialog,
                ),
                _DangerButton(
                  icon: Icons.logout_outlined,
                  title: 'Sign Out',
                  onTap: _showSignOutDialog,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  void _showHelpSupport() {
    // Implement help and support
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('Contact support at: support@lostatkuet.com'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _reportBug() {
    // Implement bug reporting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text('Send bug reports to: bugs@lostatkuet.com'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    // Implement app rating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to app store...')),
    );
  }

  void _shareApp() {
    // Implement app sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing app...')),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will remove all temporary data. Your settings will be preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings?'),
        content: const Text('All your app settings will be restored to default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAllSettings();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
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
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Reusable Widgets (same as before but now they actually work)
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final Function(bool) onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFF4B400),
      ),
      contentPadding: EdgeInsets.zero,
      onTap: () => onChanged(!value),
    );
  }
}

class _SettingDropdown extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

  const _SettingDropdown({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        underline: const SizedBox(),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Function(double) onChanged;

  const _SettingSlider({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[600]),
          title: Text(title),
          trailing: Text('${value.toStringAsFixed(1)} $unit'),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
          activeColor: const Color(0xFFF4B400),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
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

class _DangerButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DangerButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.red[700]),
      title: Text(title, style: TextStyle(color: Colors.red[700])),
      trailing: const Icon(Icons.chevron_right, color: Colors.red),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}