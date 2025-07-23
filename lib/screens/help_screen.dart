import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How does SwapSpot work?',
      answer: 'SwapSpot is a peer-to-peer barter marketplace. Users list items they want to swap, browse other listings, and make offers. When both parties agree, they can chat to coordinate the exchange.',
    ),
    FAQItem(
      question: 'Is SwapSpot safe to use?',
      answer: 'Yes! We have several safety features: user verification, trust scores, SwapGuard escrow service, and a reporting system. Always meet in public places and trust your instincts.',
    ),
    FAQItem(
      question: 'How do I create a listing?',
      answer: 'Tap the + button on the My Items tab, fill in the details, add photos, and set your preferred swap. Make sure to describe your item accurately and set a fair estimated value.',
    ),
    FAQItem(
      question: 'Can I make multiple offers on the same item?',
      answer: 'No, you can only make one offer per item. This prevents spam and ensures fair competition. Choose your best offer carefully!',
    ),
    FAQItem(
      question: 'What is SwapGuard?',
      answer: 'SwapGuard is our optional escrow service that holds items securely until both parties confirm the swap is complete. This protects against fraud and ensures fair exchanges.',
    ),
    FAQItem(
      question: 'How do I report a problem?',
      answer: 'You can report issues through the app settings, contact our support team, or use the report button on any listing or user profile.',
    ),
    FAQItem(
      question: 'Is my location shared with other users?',
      answer: 'Your exact location is never shared. We only show approximate distances to help you find nearby swaps. You can control location permissions in settings.',
    ),
    FAQItem(
      question: 'What if someone doesn\'t show up for a swap?',
      answer: 'If someone doesn\'t show up, you can report them through the app. Repeated no-shows may result in account suspension. Always communicate clearly about meeting times and locations.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.email,
                          title: 'Email Support',
                          onTap: () => _contactEmail(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.phone,
                          title: 'Call Support',
                          onTap: () => _contactPhone(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.chat,
                          title: 'Live Chat',
                          onTap: () => _startLiveChat(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.bug_report,
                          title: 'Report Bug',
                          onTap: () => _reportBug(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Getting Started
          _buildSection(
            title: 'Getting Started',
            children: [
              _buildGuideItem(
                icon: Icons.person_add,
                title: 'Create Account',
                description: 'Sign up with email or phone number',
                onTap: () => _showGuide('account'),
              ),
              _buildGuideItem(
                icon: Icons.location_on,
                title: 'Set Location',
                description: 'Enable location to find nearby swaps',
                onTap: () => _showGuide('location'),
              ),
              _buildGuideItem(
                icon: Icons.add_photo_alternate,
                title: 'Add Your First Item',
                description: 'List an item you want to swap',
                onTap: () => _showGuide('listing'),
              ),
              _buildGuideItem(
                icon: Icons.swap_horiz,
                title: 'Make an Offer',
                description: 'Find items you want and make offers',
                onTap: () => _showGuide('offer'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Safety Tips
          _buildSection(
            title: 'Safety Tips',
            children: [
              _buildSafetyTip(
                icon: Icons.public,
                title: 'Meet in Public',
                description: 'Always meet in well-lit, public places',
              ),
              _buildSafetyTip(
                icon: Icons.people,
                title: 'Bring a Friend',
                description: 'Consider bringing someone with you',
              ),
              _buildSafetyTip(
                icon: Icons.verified,
                title: 'Check Trust Score',
                description: 'Look for users with higher trust scores',
              ),
              _buildSafetyTip(
                icon: Icons.photo_camera,
                title: 'Inspect Items',
                description: 'Carefully examine items before swapping',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // FAQ
          _buildSection(
            title: 'Frequently Asked Questions',
            children: _faqs.map((faq) => _buildFAQItem(faq)).toList(),
          ),

          const SizedBox(height: 24),

          // Contact Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'support@swapspot.co.ke',
                    onTap: () => _contactEmail(),
                  ),
                  _buildContactItem(
                    icon: Icons.phone,
                    title: 'Phone',
                    subtitle: '+254 700 000 000',
                    onTap: () => _contactPhone(),
                  ),
                  _buildContactItem(
                    icon: Icons.schedule,
                    title: 'Support Hours',
                    subtitle: 'Mon-Fri: 8AM-6PM EAT',
                    onTap: null,
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

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _QuickActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildSafetyTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: Icon(icon, color: Colors.green),
      ),
      title: Text(title),
      subtitle: Text(description),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(faq.answer),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios) : null,
      onTap: onTap,
    );
  }

  void _showGuide(String type) {
    String title = '';
    String content = '';

    switch (type) {
      case 'account':
        title = 'Creating Your Account';
        content = '1. Open SwapSpot app\n2. Tap "Sign Up"\n3. Enter your email or phone\n4. Create a password\n5. Verify your account';
        break;
      case 'location':
        title = 'Setting Your Location';
        content = '1. Go to Settings\n2. Tap "Location Settings"\n3. Enable location services\n4. Allow app access to location\n5. Your location helps find nearby swaps';
        break;
      case 'listing':
        title = 'Adding Your First Item';
        content = '1. Tap the + button on My Items\n2. Take clear photos\n3. Write a detailed description\n4. Set condition and value\n5. Add tags for better visibility';
        break;
      case 'offer':
        title = 'Making an Offer';
        content = '1. Browse items in Explore\n2. Tap on an item you want\n3. Tap "Make Offer"\n4. Select an item to offer\n5. Send your offer';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _contactEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@swapspot.co.ke',
      query: 'subject=SwapSpot Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  void _contactPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+254700000000');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone app')),
      );
    }
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live chat feature coming soon'),
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text(
          'Please describe the issue you encountered. Include steps to reproduce if possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _contactEmail();
            },
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}