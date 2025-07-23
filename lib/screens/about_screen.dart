// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Logo and Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // App Logo Placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SwapSpot',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'C2C Barter Marketplace for Kenya',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Mission Statement
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Mission',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SwapSpot is revolutionizing the way Kenyans exchange goods and services. '
                        'We believe in the power of community, sustainability, and local commerce. '
                        'Our platform makes it easy, safe, and fun to swap items with people in your area.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Features',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.swap_horiz,
                    title: 'Peer-to-Peer Swapping',
                    description: 'Direct item exchanges between users',
                  ),
                  _buildFeatureItem(
                    icon: Icons.location_on,
                    title: 'Location-Based Matching',
                    description: 'Find swaps near you',
                  ),
                  _buildFeatureItem(
                    icon: Icons.verified,
                    title: 'Trust & Safety',
                    description: 'User verification and trust scores',
                  ),
                  _buildFeatureItem(
                    icon: Icons.chat,
                    title: 'Built-in Chat',
                    description: 'Coordinate swaps easily',
                  ),
                  _buildFeatureItem(
                    icon: Icons.security,
                    title: 'SwapGuard',
                    description: 'Optional escrow service for security',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Team
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Team',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTeamMember(
                    name: 'SwapSpot Team',
                    role: 'Development & Design',
                    description: 'A passionate team dedicated to building the best barter marketplace for Kenya.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Contact & Social
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect With Us',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSocialLink(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'hello@swapspot.co.ke',
                    onTap: () => _launchEmail(),
                  ),
                  _buildSocialLink(
                    icon: Icons.language,
                    title: 'Website',
                    subtitle: 'www.swapspot.co.ke',
                    onTap: () => _launchWebsite(),
                  ),
                  _buildSocialLink(
                    icon: Icons.facebook,
                    title: 'Facebook',
                    subtitle: '@SwapSpotKenya',
                    onTap: () => _launchFacebook(),
                  ),
                  _buildSocialLink(
                    icon: Icons.camera_alt,
                    title: 'Instagram',
                    subtitle: '@swapspot_kenya',
                    onTap: () => _launchInstagram(),
                  ),
                  _buildSocialLink(
                    icon: Icons.flutter_dash,
                    title: 'Twitter',
                    subtitle: '@SwapSpotKenya',
                    onTap: () => _launchTwitter(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legal Links
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLegalLink(
                    title: 'Terms of Service',
                    onTap: () => _showTerms(),
                  ),
                  _buildLegalLink(
                    title: 'Privacy Policy',
                    onTap: () => _showPrivacy(),
                  ),
                  _buildLegalLink(
                    title: 'Cookie Policy',
                    onTap: () => _showCookies(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Credits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credits',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Built with Flutter & Firebase',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 SwapSpot. All rights reserved.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required String description,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            name[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLink({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildLegalLink({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'hello@swapspot.co.ke',
      query: 'subject=Hello from SwapSpot App',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://www.swapspot.co.ke');

    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri);
    }
  }

  void _launchFacebook() async {
    final Uri facebookUri = Uri.parse('https://facebook.com/SwapSpotKenya');

    if (await canLaunchUrl(facebookUri)) {
      await launchUrl(facebookUri);
    }
  }

  void _launchInstagram() async {
    final Uri instagramUri = Uri.parse('https://instagram.com/swapspot_kenya');

    if (await canLaunchUrl(instagramUri)) {
      await launchUrl(instagramUri);
    }
  }

  void _launchTwitter() async {
    final Uri twitterUri = Uri.parse('https://twitter.com/SwapSpotKenya');

    if (await canLaunchUrl(twitterUri)) {
      await launchUrl(twitterUri);
    }
  }

  void _showTerms() {
    // TODO: Show terms of service
  }

  void _showPrivacy() {
    // TODO: Show privacy policy
  }

  void _showCookies() {
    // TODO: Show cookie policy
  }
}