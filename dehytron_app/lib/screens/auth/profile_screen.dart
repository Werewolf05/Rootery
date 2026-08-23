import 'package:flutter/material.dart';
import '../../theme/rootery_theme.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  String _theme = 'Dark';
  bool _loadingProfile = true;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getUserProfile();
    final cachedName = await AuthService.getCachedDisplayName();

    if (!mounted) return;
    setState(() {
      _nameController.text =
          (profile?['name']?.toString().trim().isNotEmpty ?? false)
          ? profile!['name'].toString().trim()
          : cachedName;
      _emailController.text = profile?['email']?.toString() ?? '';
      _phoneController.text = profile?['phone']?.toString() ?? '';
      _loadingProfile = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RooteryTheme.card,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: RooteryTheme.subText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_savingProfile) return;

    setState(() => _savingProfile = true);
    try {
      await AuthService.saveDisplayName(_nameController.text);
      if (AuthService.currentUser != null) {
        await AuthService.updateUserProfile({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.background,
      appBar: AppBar(
        backgroundColor: RooteryTheme.card,
        title: const Text('Profile & Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_loadingProfile) const LinearProgressIndicator(minHeight: 2),
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RooteryTheme.card,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          RooteryTheme.accentGreen,
                          RooteryTheme.accentGreen.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : 'Farmer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Farmer',
                    style: TextStyle(color: RooteryTheme.subText, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatChip('47', 'Batches', Icons.inventory),
                      _buildStatChip('94%', 'Success', Icons.check_circle),
                      _buildStatChip('342', 'kWh', Icons.bolt),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account section
            _buildSection('Account Information', [
              _buildTextField(
                'Full Name',
                _nameController,
                Icons.person_outline,
              ),
              _buildTextField('Email', _emailController, Icons.email_outlined),
              _buildTextField('Phone', _phoneController, Icons.phone_outlined),
              _buildActionTile(
                'Change Password',
                Icons.lock_outline,
                () => _showChangePasswordDialog(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _savingProfile ? null : _saveProfile,
                  icon: _savingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RooteryTheme.accentGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Notification settings
            _buildSection('Notifications', [
              _buildSwitchTile(
                'Push Notifications',
                Icons.notifications_outlined,
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
              ),
              _buildSwitchTile(
                'Email Notifications',
                Icons.mail_outline,
                _emailNotifications,
                (value) => setState(() => _emailNotifications = value),
              ),
            ]),
            const SizedBox(height: 16),

            // App settings
            _buildSection('App Settings', [
              _buildDropdownTile(
                'Theme',
                Icons.palette_outlined,
                _theme,
                ['Dark', 'Light', 'System'],
                (value) => setState(() => _theme = value!),
              ),
              _buildActionTile('Language', Icons.language, () {}),
              _buildActionTile(
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                () {},
              ),
              _buildActionTile(
                'Terms of Service',
                Icons.description_outlined,
                () {},
              ),
            ]),
            const SizedBox(height: 16),

            // Support section
            _buildSection('Support', [
              _buildActionTile('Help & FAQ', Icons.help_outline, () {}),
              _buildActionTile('Contact Support', Icons.support_agent, () {}),
              _buildActionTile('About', Icons.info_outline, () {}),
            ]),
            const SizedBox(height: 24),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Version 1.0.0',
              style: TextStyle(color: RooteryTheme.subText, fontSize: 12),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RooteryTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: RooteryTheme.subText),
          prefixIcon: Icon(icon, color: RooteryTheme.subText),
          filled: true,
          fillColor: RooteryTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: RooteryTheme.subText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right, color: RooteryTheme.subText),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: RooteryTheme.subText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RooteryTheme.accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    IconData icon,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: RooteryTheme.subText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: RooteryTheme.card,
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: RooteryTheme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: RooteryTheme.accentGreen, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: RooteryTheme.subText, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RooteryTheme.card,
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: const TextStyle(color: RooteryTheme.subText),
                filled: true,
                fillColor: RooteryTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: const TextStyle(color: RooteryTheme.subText),
                filled: true,
                fillColor: RooteryTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: const TextStyle(color: RooteryTheme.subText),
                filled: true,
                fillColor: RooteryTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RooteryTheme.accentGreen,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
