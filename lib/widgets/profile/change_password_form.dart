import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class ChangePasswordForm extends StatefulWidget {
  final Function(String currentPassword, String newPassword) onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ChangePasswordForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_updatePasswordStrength);
    _confirmPasswordController.addListener(_checkPasswordsMatch);
  }

  void _updatePasswordStrength() {
    final password = _newPasswordController.text;
    setState(() {
      _showValidation = true;
      _hasMinLength = Validators.hasMinLength(password);
      _hasUppercase = Validators.hasUppercase(password);
      _hasLowercase = Validators.hasLowercase(password);
      _hasDigit = Validators.hasDigit(password);
      _hasSpecialChar = Validators.hasSpecialChar(password);
      _checkPasswordsMatch();
    });
  }

  void _checkPasswordsMatch() {
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      _passwordsMatch = password.isNotEmpty && password == confirmPassword;
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
    } else {
      // Show validation indicators if form is invalid
      setState(() {
        _showValidation = true;
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Password field
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            decoration: InputDecoration(
              labelText: 'Current Password',
              hintText: 'Enter your current password',
              prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
              labelStyle: TextStyle(color: Colors.grey[600]),
              floatingLabelStyle: const TextStyle(color: AppColors.primary),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your current password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // New Password field
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter your new password',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.primary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
              labelStyle: TextStyle(color: Colors.grey[600]),
              floatingLabelStyle: const TextStyle(color: AppColors.primary),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a new password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              if (!_hasUppercase || !_hasLowercase || !_hasDigit) {
                return 'Password must include uppercase, lowercase letters and numbers';
              }
              return null;
            },
            onTap: () {
              setState(() {
                _showValidation = true;
              });
            },
          ),
          const SizedBox(height: 8),

          // Password strength indicators
          if (_showValidation)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password Requirements:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementRow(_hasMinLength, 'At least 8 characters'),
                  _buildRequirementRow(
                    _hasUppercase,
                    'Contains uppercase letter',
                  ),
                  _buildRequirementRow(
                    _hasLowercase,
                    'Contains lowercase letter',
                  ),
                  _buildRequirementRow(_hasDigit, 'Contains number'),
                  _buildRequirementRow(
                    _hasSpecialChar,
                    'Contains special character',
                    isOptional: true,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Confirm Password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              hintText: 'Confirm your new password',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.primary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
              labelStyle: TextStyle(color: Colors.grey[600]),
              floatingLabelStyle: const TextStyle(color: AppColors.primary),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your new password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          if (_showValidation)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildRequirementRow(
                _passwordsMatch,
                'Passwords match',
                isMatch: true,
              ),
            ),
          const SizedBox(height: 24),

          // Error message
          if (widget.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Success message
          if (widget.successMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.successMessage!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Update button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Update Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(
    bool isValid,
    String text, {
    bool isOptional = false,
    bool isMatch = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isValid
                  ? Colors.green
                  : (isOptional ? Colors.amber : Colors.grey[300]),
            ),
            child: Center(
              child: Icon(
                isValid
                    ? Icons.check
                    : (isOptional ? Icons.priority_high : Icons.close),
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isValid
                    ? Colors.green
                    : (isMatch ? Colors.red : Colors.grey[700]),
                fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
