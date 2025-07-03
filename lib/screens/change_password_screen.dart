import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/profile/change_password_form.dart';
import '../screens/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // First, reauthenticate the user
      final reauthResult = await _authService.reauthenticateUser(
        currentPassword,
      );

      if (!reauthResult) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Current password is incorrect. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Then update the password
      final updateResult = await _authService.updatePassword(newPassword);

      if (updateResult) {
        if (!mounted) return;

        setState(() {
          _successMessage = 'Password updated successfully!';
          _isLoading = false;
        });

        // Show success message with SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Sign out the user and navigate to login screen after a short delay
        Future.delayed(const Duration(seconds: 2), () async {
          if (!mounted) return;

          try {
            // Sign out the user completely
            await _authService.signOut();
            print('User signed out after password change');

            // Clear the navigation stack completely and go to login screen
            if (!mounted) return;

            // Navigate to login screen and clear the stack
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);

            // Show a message to the user to log in again with their new password
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please log in with your new password'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          } catch (e) {
            print('Error during logout after password change: $e');
            // Fallback navigation if there's an error
            if (!mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      } else {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'Failed to update password. Please try again.';
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'An error occurred. Please try again.';

      if (e.code == 'requires-recent-login') {
        message =
            'Please log out and log in again before changing your password.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Please choose a stronger password.';
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });

      print('Firebase auth error: ${e.code} - ${e.message}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });

      print('Error in change password: $e');
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
          'Change Password',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Your Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enter your current password and choose a new secure password.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            ChangePasswordForm(
              onSubmit: _changePassword,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              successMessage: _successMessage,
            ),
          ],
        ),
      ),
    );
  }
}
