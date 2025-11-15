import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../services/storage_service.dart';
//import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../auth/signin_screen.dart';

/// Profile screen for viewing and editing user profile
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final _storageService = StorageService();
  bool _isEditing = false;
  File? _imageFile;

  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _rateController;
  late TextEditingController _descriptionController;
  String? _selectedServiceType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final user = context.read<AuthProvider>().userModel;
    _nameController = TextEditingController(text: user?.name);
    _cityController = TextEditingController(text: user?.city);
    _rateController = TextEditingController(text: user?.rate?.toString());
    _descriptionController = TextEditingController(text: user?.description);
    _selectedServiceType = user?.serviceType;
    // Refresh profile to get latest rating
    _refreshProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when returning to the app or screen
      _refreshProfile();
    }
  }

  void _refreshProfile() async {
    if (!mounted) return;
    try {
      print('Profile screen: Refreshing...');
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUserProfile();
      // Update controllers if profile changed
      if (mounted) {
        final user = authProvider.userModel;
        print(
          'Profile screen: User rating ${user?.rating}, reviews ${user?.reviewCount}',
        );
        setState(() {
          _nameController.text = user?.name ?? '';
          _cityController.text = user?.city ?? '';
          _rateController.text = user?.rate?.toString() ?? '';
          _descriptionController.text = user?.description ?? '';
          _selectedServiceType = user?.serviceType;
        });
      }
    } catch (e) {
      print('Profile refresh error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _cityController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _storageService.pickImageFromGallery();
    if (file != null) {
      setState(() {
        _imageFile = file;
      });
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel!;

    String? imageUrl = user.profileImage;

    // Upload image if selected
    if (_imageFile != null) {
      imageUrl = await _storageService.uploadProfileImage(
        imageFile: _imageFile!,
        userId: user.uid,
      );
    }

    // Update user model
    final updatedUser = user.copyWith(
      name: _nameController.text,
      city: _cityController.text,
      serviceType: _selectedServiceType,
      rate: double.tryParse(_rateController.text),
      description: _descriptionController.text,
      profileImage: imageUrl,
      updatedAt: DateTime.now(),
    );

    final success = await authProvider.updateUserProfile(updatedUser);

    if (success && mounted) {
      setState(() {
        _isEditing = false;
        _imageFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isWorker = user.role == AppConstants.roleWorker;

    // Calculate rating from completed requests
    final completedRequests = requestProvider.requests
        .where(
          (r) =>
              r.workerId == user.uid &&
              r.status == AppConstants.statusCompleted,
        )
        .toList();
    final reviewedRequests = completedRequests
        .where((r) => r.customerRating != null)
        .toList();
    final reviewCount = reviewedRequests.length;
    final avgRating = reviewCount > 0
        ? reviewedRequests.fold<double>(
                0.0,
                (sum, r) => sum + r.customerRating!,
              ) /
              reviewCount
        : 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            // Profile picture
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (user.profileImage != null
                                  ? NetworkImage(user.profileImage!)
                                  : null)
                              as ImageProvider?,
                    child: (user.profileImage == null && _imageFile == null)
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              enabled: _isEditing,
            ),

            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              enabled: _isEditing,
            ),

            if (isWorker) ...[
              const SizedBox(height: 16),

              // Service Type dropdown
              DropdownButtonFormField<String>(
                value: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: AppConstants.serviceTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: _isEditing
                    ? (value) => setState(() => _selectedServiceType = value)
                    : null,
              ),

              const SizedBox(height: 16),

              // Hourly Rate
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                enabled: _isEditing,
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 4,
                enabled: _isEditing,
              ),

              const SizedBox(height: 16),

              // Rating display
              if (!_isEditing && reviewCount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                )
              else if (!_isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_outline, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'No reviews yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
            ],

            const SizedBox(height: 32),

            // Edit/Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isEditing
                    ? _saveProfile
                    : () => setState(() => _isEditing = true),
                child: Text(_isEditing ? 'Save Profile' : 'Edit Profile'),
              ),
            ),

            const SizedBox(height: 16),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await authProvider.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
