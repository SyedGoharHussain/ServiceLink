import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'email_verification_screen.dart';

/// Role selection screen for new users
class RoleSelectionScreen extends StatefulWidget {
  final String? name;
  final String? email;
  final String? password;

  const RoleSelectionScreen({Key? key, this.name, this.email, this.password})
    : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.name != null) {
      _nameController.text = widget.name!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeSignup() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    bool success;

    try {
      // If coming from email signup
      if (widget.email != null && widget.password != null) {
        print('Completing email signup...');
        success = await authProvider.signUpWithEmail(
          email: widget.email!,
          password: widget.password!,
          name: _nameController.text.trim(),
          role: _selectedRole!,
        );
      } else {
        // If coming from Google sign-in
        print('Completing Google sign-in with role: $_selectedRole and name: ${_nameController.text.trim()}');
        success = await authProvider.completeGoogleSignIn(
          _nameController.text.trim(),
          _selectedRole!,
        );
      }
    } catch (e) {
      print('Error in _completeSignup: $e');
      success = false;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      final errorMsg = authProvider.errorMessage ?? 'Signup failed';
      print('Role selection signup failed: $errorMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppConstants.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      print('Role selection signup successful');
      // If email signup, navigate to email verification
      if (widget.email != null && widget.password != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(email: widget.email!),
          ),
        );
      }
      // For Google sign-in, navigation to main screen will be handled by auth state listener
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ServiceLink')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Toggle buttons for Customer/Worker
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RoleButton(
                        label: 'Customer',
                        isSelected: _selectedRole == AppConstants.roleCustomer,
                        onTap: () {
                          setState(() {
                            _selectedRole = AppConstants.roleCustomer;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RoleButton(
                        label: 'Worker',
                        isSelected: _selectedRole == AppConstants.roleWorker,
                        onTap: () {
                          setState(() {
                            _selectedRole = AppConstants.roleWorker;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Search bar placeholder image
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedRole == AppConstants.roleCustomer
                          ? Icons.search
                          : Icons.work_outline,
                      size: 80,
                      color: AppConstants.primaryColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedRole == AppConstants.roleCustomer
                          ? 'Browse & Hire\nLocal Workers'
                          : 'Receive Job Requests\n& Build Your Reputation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppConstants.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Name field
              if (widget.name == null || widget.email == null)
                Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],
                ),

              // Continue button
              ElevatedButton(
                onPressed: _isLoading ? null : _completeSignup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom role selection button
class _RoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected ? Colors.white : AppConstants.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
