import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/data_export_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _swapGuardEnabled = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DataExportService _dataExportService = DataExportService();

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _swapGuardEnabled = data['swapGuardEnabled'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Failed to load user preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Settings
          _buildSection(
            title: 'Account',
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pushNamed('/edit-profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location Settings'),
                subtitle: Text(_locationEnabled ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Privacy & Security'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showPrivacyDialog();
                },
              ),
            ],
          ),

          // App Preferences
          _buildSection(
            title: 'App Preferences',
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                subtitle: Text(_getThemeModeText(themeProvider.appThemeMode)),
                trailing: PopupMenuButton<AppThemeMode>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (mode) {
                    themeProvider.setThemeMode(mode);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: AppThemeMode.light, child: Text('Light')),
                    const PopupMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
                    const PopupMenuItem(value: AppThemeMode.system, child: Text('System')),
                  ],
                ),

              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(languageProvider.getLanguageName(languageProvider.currentLanguage)),
                trailing: PopupMenuButton<AppLanguage>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (language) {
                    languageProvider.setLanguage(language);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: AppLanguage.english,
                      child: Text('English'),
                    ),
                    const PopupMenuItem(
                      value: AppLanguage.swahili,
                      child: Text('Swahili'),
                    ),
                    const PopupMenuItem(
                      value: AppLanguage.french,
                      child: Text('French'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // SwapSpot Features
          _buildSection(
            title: 'SwapSpot Features',
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('SwapGuard'),
                subtitle: Text(_swapGuardEnabled ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: _swapGuardEnabled,
                  onChanged: (value) {
                    _toggleSwapGuard(value);
                  },
                ),
                onTap: () {
                  _showSwapGuardInfo();
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified),
                title: const Text('ID Verification'),
                subtitle: const Text('Verify your identity'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pushNamed('/id-verification');
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analytics'),
                subtitle: const Text('View your swap statistics'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pushNamed('/analytics');
                },
              ),
            ],
          ),

          // Support & Legal
          _buildSection(
            title: 'Support & Legal',
            children: [
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pushNamed('/help');
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pushNamed('/about');
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showTermsOfService();
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showPrivacyPolicy();
                },
              ),
            ],
          ),

          // Data & Storage
          _buildSection(
            title: 'Data & Storage',
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Data'),
                subtitle: const Text('Download your data'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _exportData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up storage space'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _clearCache();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showDeleteAccountDialog();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Your data is encrypted and secure'),
            Text('• We never share your personal information'),
            Text('• Location data is only used for nearby swaps'),
            Text('• You can delete your data anytime'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
      return 'System Default';
    }
  }

  Future<void> _toggleSwapGuard(bool enabled) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).update({
        'swapGuardEnabled': enabled,
      });

      setState(() {
        _swapGuardEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SwapGuard ${enabled ? 'enabled' : 'disabled'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update SwapGuard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSwapGuardInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SwapGuard'),
        content: const Text(
          'SwapGuard is our secure escrow service that protects both parties during a swap. '
              'Items are held securely until both parties confirm the swap is complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Learn More'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }



  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using SwapSpot, you agree to our terms of service...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Our privacy policy explains how we collect, use, and protect your data...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting your data...'),
            ],
          ),
        ),
      );

      final filePath = await _dataExportService.exportUserData();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Exported'),
            content: Text('Your data has been exported to:\n$filePath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will free up storage space. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                // Clear image cache
                final cacheDir = await getTemporaryDirectory();
                final imageCacheDir = Directory('${cacheDir.path}/image_cache');
                if (await imageCacheDir.exists()) {
                  await imageCacheDir.delete(recursive: true);
                }

                // Clear other temporary files
                final tempDir = Directory('${cacheDir.path}/temp');
                if (await tempDir.exists()) {
                  await tempDir.delete(recursive: true);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear cache: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Delete user's items
      final itemsQuery = await _firestore
          .collection('items')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in itemsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's offers
      final offersQuery = await _firestore
          .collection('offers')
          .where('offererId', isEqualTo: user.uid)
          .get();

      for (final doc in offersQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's chats and messages
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();

      for (final chatDoc in chatsQuery.docs) {
        final messagesQuery = await chatDoc.reference.collection('messages').get();
        for (final msgDoc in messagesQuery.docs) {
          await msgDoc.reference.delete();
        }
        await chatDoc.reference.delete();
      }

      // Delete user's profile image from storage
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data['profileImageUrl'] != null) {
          try {
            final storageRef = FirebaseStorage.instance.refFromURL(data['profileImageUrl']);
            await storageRef.delete();
          } catch (e) {
            // Ignore storage deletion errors
          }
        }
      }

      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}