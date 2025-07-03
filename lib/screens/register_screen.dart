import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/register/register_form.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if email already exists
      try {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
          email,
        );

        if (methods.isNotEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'This email address is already registered. Please use a different email or try logging in.';
          });
          return;
        }
      } catch (e) {
        // Continue with registration if error checking email
      }

      // Create user
      final user = await _authService.registerWithEmailAndPassword(
        email,
        password,
        name,
      );

      // Navigate back to login page
      if (user != null && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'An error occurred during registration';

      // Handle specific Firebase error codes
      if (e.code == 'email-already-in-use') {
        errorMsg =
            'This email address is already registered. Please use a different email.';
      } else if (e.message != null) {
        errorMsg = e.message!;
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          AppStrings.createAccount,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.7),
                      AppColors.secondary.withOpacity(0.7),
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
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(AppAssets.logo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create Account text
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  AppStrings.createAccount,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Register form
              RegisterForm(
                onSubmit: _registerWithEmailAndPassword,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
              ),

              const SizedBox(height: 24),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.alreadyHaveAccount,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      AppStrings.login,
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
