import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/item_model.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/about_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'providers/language_provider.dart';
import 'screens/chat_details_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/help_screen.dart';
import 'screens/id_verification_screen.dart';
import 'screens/item_details_screen.dart';
import 'screens/make_offer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.location.request();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SwapSpotApp());
}

class SwapSpotApp extends StatelessWidget {
  const SwapSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SwapSpot',
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/add-item': (context) => const AddItemScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/help': (context) => const HelpScreen(),
              '/about': (context) => const AboutScreen(),
              '/edit-profile': (context) => const EditProfileScreen(),
              '/id-verification': (context) => const IDVerificationScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/item-details':
                  final item = settings.arguments as ItemModel;
                  return MaterialPageRoute(
                    builder: (context) => ItemDetailsScreen(item: item),
                  );
                case '/make-offer':
                  final item = settings.arguments as ItemModel;
                  return MaterialPageRoute(
                    builder: (context) => MakeOfferScreen(targetItem: item),
                  );
                case '/chat-details':
                  final chatId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (context) => ChatDetailsScreen(chatId: chatId),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (context) => const SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
