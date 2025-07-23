import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'tabs/explore_tab.dart';
import 'tabs/my_items_tab.dart';
import 'tabs/offers_tab.dart';
import 'tabs/chat_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isGuest = Provider.of<AuthProvider>(context).isGuest;

    final List<Widget> allTabs = [
      const ExploreTab(),
      const MyItemsTab(),
      const OffersTab(),
      const ChatTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: allTabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          final isGuest = Provider.of<AuthProvider>(context, listen: false).isGuest;
          // Index 0 (Explore) is always allowed
          if (isGuest && index != 0) {
            // Show snackbar and redirect to login
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('You must be logged in to use this feature.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
            // Optional: Redirect to LoginScreen after short delay
            Future.delayed(const Duration(milliseconds: 800), () {
              Navigator.of(context).pushNamed('/login');
            });

            return; // Don't switch tab
          }

          // Allowed
          setState(() {
            _currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'My Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 1 && !isGuest)
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-item');
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
