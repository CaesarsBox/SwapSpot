import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      // Push login screen only once
      Future.microtask(() {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });

      // Show temporary placeholder while redirecting
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // User is authenticated → show protected content
    return child;
  }
}
