import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/profile/change_password_form.dart';

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
        setState(() {
          _errorMessage = 'Current password is incorrect. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Then update the password
      final updateResult = await _authService.updatePassword(newPassword);

      if (updateResult) {
        setState(() {
          _successMessage = 'Password updated successfully!';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to update password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
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
