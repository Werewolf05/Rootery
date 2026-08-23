import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/rootery_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  bool _autoSync = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        backgroundColor: RooteryTheme.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            // Account Section
            _buildSectionHeader('Account'),
            _buildSettingTile(
              icon: Icons.person,
              title: 'Profile',
              subtitle: 'Manage your profile information',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Profile settings coming soon...'),
                    backgroundColor: RooteryTheme.accentGreen,
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.security,
              title: 'Password',
              subtitle: 'Change your password',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password change coming soon...'),
                    backgroundColor: RooteryTheme.accentGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              icon: Icons.notifications,
              title: 'Enable Notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
            _buildSettingTile(
              icon: Icons.notifications_active,
              title: 'Alert Preferences',
              subtitle: 'Configure alert types',
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // System Section
            _buildSectionHeader('System'),
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              value: _darkMode,
              onChanged: (value) {
                setState(() => _darkMode = value);
              },
            ),
            _buildSwitchTile(
              icon: Icons.cloud_sync,
              title: 'Auto Sync',
              value: _autoSync,
              onChanged: (value) {
                setState(() => _autoSync = value);
              },
            ),
            const SizedBox(height: 16),

            // Data Section
            _buildSectionHeader('Data'),
            _buildSettingTile(
              icon: Icons.storage,
              title: 'Cache',
              subtitle: 'Clear application cache',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.backup,
              title: 'Backup',
              subtitle: 'Backup your data',
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // About Section
            _buildSectionHeader('About'),
            _buildSettingTile(
              icon: Icons.info,
              title: 'About Rootery',
              subtitle: 'Version 1.0.0',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: RooteryTheme.card,
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: RooteryTheme.subText),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await AuthService.signOut();
                              if (!context.mounted) return;
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: RooteryTheme.accentGreen,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: RooteryTheme.accentGreen),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: RooteryTheme.subText, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white30,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: RooteryTheme.accentGreen),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: RooteryTheme.accentGreen,
        ),
      ),
    );
  }
}

