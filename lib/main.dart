import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/friend_list_screen.dart';

import 'screens/fridge_list_screen.dart';
import 'screens/add_fridge_screen.dart';
import 'utils/constants.dart';
import 'services/auth_service.dart';
import 'services/fridge_item_service.dart';

// Global instance of AuthService for persistence
final AuthService authService = AuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Set persistence mode to LOCAL for Auth
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Disable offline persistence for friend requests to prevent cache issues
    // This will be handled manually in the friend service

    // Initialize auth service after Firebase
    print(
      'Firebase initialized, current user: ${FirebaseAuth.instance.currentUser?.uid ?? 'None'}',
    );
  } catch (e) {
    print('Error during Firebase initialization: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _statusUpdateTimer;
  final FridgeItemService _fridgeItemService = FridgeItemService();

  @override
  void initState() {
    super.initState();
    _startStatusUpdateTimer();
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _startStatusUpdateTimer() {
    // Update status immediately when app starts
    _fridgeItemService.updateAllItemsStatus();

    // Update status every 5 minutes
    _statusUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fridgeItemService.updateAllItemsStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.tertiary,
        ),
        useMaterial3: true,
      ),
      // Define named routes
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/friends': (context) => const FriendListScreen(),

        '/fridges': (context) => const FridgeListScreen(),
        '/add_fridge': (context) => const AddFridgeScreen(),
        // Note: Routes that require parameters (like fridge_detail and add_fridge_item)
        // are handled via MaterialPageRoute in the code instead of named routes
      },
      initialRoute: '/',
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Debug print to track auth state changes
        print(
          'Auth state changed: ${snapshot.hasData ? 'User authenticated' : 'User not authenticated'}',
        );

        // Check for error in authentication state
        if (snapshot.hasError) {
          print('Auth state error: ${snapshot.error}');
          return const LoginScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          print('User authenticated: ID=${snapshot.data!.uid}');

          // Extra validation to ensure user is really authenticated
          if (FirebaseAuth.instance.currentUser != null) {
            print(
              'Current user matches stream: ${FirebaseAuth.instance.currentUser!.uid}',
            );
            return const HomeScreen();
          } else {
            print('WARNING: Stream has user but currentUser is null');
          }
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Default to login screen
        print('No authenticated user, showing login screen');
        return const LoginScreen();
      },
    );
  }
}
