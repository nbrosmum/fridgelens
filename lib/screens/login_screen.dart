import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/login/login_form.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Ensure we're starting with a clean auth state
    _checkAndClearAuthState();
  }

  Future<void> _checkAndClearAuthState() async {
    // Check if there's any lingering auth state and clear it if needed
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        await _authService.signOut();
        print('Cleared existing auth state on login screen init');
      } catch (e) {
        print('Error clearing auth state: $e');
      }
    }
  }

  Future<void> _signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      // Debug print to see if we're getting a user back
      print('Login attempt result: ${user != null ? 'Success' : 'Failed'}');
      if (user != null) {
        print('Successfully logged in user: ${user.uid}');

        // Navigate to home screen on successful login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during login: ${e.code} - ${e.message}');
      if (mounted) {
        String errorMsg = 'An error occurred during sign in';

        // Provide more specific error messages
        if (e.code == 'wrong-password') {
          errorMsg = 'Incorrect password. Please try again.';
        } else if (e.code == 'user-not-found') {
          errorMsg = 'No account found with this email.';
        } else if (e.code == 'invalid-credential') {
          errorMsg =
              'Invalid login credentials. Please check your email and password.';
        } else if (e.message != null) {
          errorMsg = e.message!;
        }

        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } catch (e) {
      print('Unexpected error during login: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and App name in a stack
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.7),
                          AppColors.secondary.withOpacity(0.7),
                          AppColors.tertiary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(AppAssets.logo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // App name with gradient text
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Login form
              LoginForm(
                onSubmit: _signInWithEmailAndPassword,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
              ),

              const SizedBox(height: 16),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    AppStrings.forgotPassword,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.dontHaveAccount,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      AppStrings.register,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
