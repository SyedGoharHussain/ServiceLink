import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../services/storage_service.dart';
import '../../services/image_base64_service.dart';
import '../../utils/constants.dart';
import '../auth/signin_screen.dart';

/// Profile screen for viewing and editing user profile
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final _storageService = StorageService();
  bool _isEditing = false;
  String? _imageBase64;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
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
    _phoneController = TextEditingController(text: user?.phone);
    _rateController = TextEditingController(text: user?.rate?.toString());
    _descriptionController = TextEditingController(text: user?.description);
    _selectedServiceType = user?.serviceType;
    _refreshProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshProfile();
    }
  }

  void _refreshProfile() async {
    if (!mounted) return;
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUserProfile();
      if (mounted) {
        final user = authProvider.userModel;
        setState(() {
          _nameController.text = user?.name ?? '';
          _cityController.text = user?.city ?? '';
          _phoneController.text = user?.phone ?? '';
          _rateController.text = user?.rate?.toString() ?? '';
          _descriptionController.text = user?.description ?? '';
          _selectedServiceType = user?.serviceType;
        });
      }
    } catch (e) {
      debugPrint('Profile refresh error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final base64 = await _storageService.pickImageFromGallery();
    if (base64 != null) {
      setState(() {
        _imageBase64 = base64;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel!;

    String? imageBase64 = user.profileImage;
    if (_imageBase64 != null) {
      imageBase64 = _imageBase64;
    }

    final updatedUser = user.copyWith(
      name: _nameController.text,
      city: _cityController.text,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      serviceType: _selectedServiceType,
      rate: double.tryParse(_rateController.text),
      description: _descriptionController.text,
      profileImage: imageBase64,
      updatedAt: DateTime.now(),
    );

    final success = await authProvider.updateUserProfile(updatedUser);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        setState(() {
          _isEditing = false;
          _imageBase64 = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
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

    // Calculate rating
    final completedRequests = requestProvider.requests
        .where((r) => r.workerId == user.uid && r.status == AppConstants.statusCompleted)
        .toList();
    final reviewedRequests = completedRequests.where((r) => r.customerRating != null).toList();
    final reviewCount = reviewedRequests.length;
    final avgRating = reviewCount > 0
        ? reviewedRequests.fold<double>(0.0, (sum, r) => sum + r.customerRating!) / reviewCount
        : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: _buildProfileHeader(user, isWorker, avgRating, reviewCount),
          ),
          
          // Edit Form / Info Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isEditing
                  ? _buildEditForm(isWorker)
                  : _buildInfoCards(user, isWorker),
            ),
          ),
          
          // Action Buttons
          SliverToBoxAdapter(
            child: _buildActionButtons(authProvider),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user, bool isWorker, double avgRating, int reviewCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageBase64 != null
                            ? ImageBase64Service.base64ToImageProvider(_imageBase64)
                            : ImageBase64Service.base64ToImageProvider(user.profileImage),
                        child: (user.profileImage == null && _imageBase64 == null)
                            ? Text(
                                user.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryColor,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppConstants.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Name & Role Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isWorker ? Icons.handyman : Icons.person,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isWorker ? (user.serviceType ?? 'Worker') : 'Customer',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rating for workers
              if (isWorker) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        reviewCount > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reviewCount > 0
                            ? '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)'
                            : 'No reviews yet',
                        style: TextStyle(
                          color: Colors.white.withOpacity(reviewCount > 0 ? 1 : 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards(dynamic user, bool isWorker) {
    return Column(
      children: [
        // Contact Info Card
        _buildInfoCard(
          title: 'Contact Information',
          icon: Icons.contact_mail_rounded,
          children: [
            _buildInfoRow(Icons.person_outline, 'Name', user.name),
            _buildInfoRow(Icons.email_outlined, 'Email', user.email),
            _buildPhoneInfoRow(user),
            _buildInfoRow(Icons.location_on_outlined, 'City', user.city ?? 'Not set'),
          ],
        ),
        
        if (isWorker) ...[
          const SizedBox(height: 16),
          
          // Work Info Card
          _buildInfoCard(
            title: 'Work Information',
            icon: Icons.work_rounded,
            children: [
              _buildInfoRow(Icons.category_outlined, 'Service', user.serviceType ?? 'Not set'),
              _buildInfoRow(Icons.attach_money_rounded, 'Hourly Rate', '\$${user.rate?.toStringAsFixed(0) ?? "0"}'),
              if (user.description != null && user.description!.isNotEmpty)
                _buildInfoRow(Icons.description_outlined, 'About', user.description!),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppConstants.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.textSecondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInfoRow(dynamic user) {
    final hasPhone = user.phone != null && user.phone!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.phone_outlined, size: 20, color: AppConstants.textSecondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      hasPhone ? user.phone! : 'Not set',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isWorker) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_rounded, color: AppConstants.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildTextField(_nameController, 'Name', Icons.person_outline),
          const SizedBox(height: 16),
          _buildPhoneFieldWithVerification(user),
          const SizedBox(height: 16),
          _buildTextField(_cityController, 'City', Icons.location_on_outlined),
          
          if (isWorker) ...[
            const SizedBox(height: 16),
            _buildServiceDropdown(),
            const SizedBox(height: 16),
            _buildTextField(_rateController, 'Hourly Rate (\$)', Icons.attach_money, isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, 'Description', Icons.description_outlined, maxLines: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isPhone = false,
    int maxLines = 1,
  }) {
    TextInputType keyboardType = TextInputType.text;
    if (isNumber) {
      keyboardType = TextInputType.number;
    } else if (isPhone) {
      keyboardType = TextInputType.phone;
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: isPhone ? '+1 234 567 8900' : null,
        prefixIcon: Icon(icon, color: AppConstants.primaryColor),
        filled: true,
        fillColor: AppConstants.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildPhoneFieldWithVerification(dynamic user) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: '+1 234 567 8900',
        prefixIcon: Icon(Icons.phone_outlined, color: AppConstants.primaryColor),
        filled: true,
        fillColor: AppConstants.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedServiceType,
      decoration: InputDecoration(
        labelText: 'Service Type',
        prefixIcon: Icon(Icons.work_outline, color: AppConstants.primaryColor),
        filled: true,
        fillColor: AppConstants.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: AppConstants.serviceTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (value) => setState(() => _selectedServiceType = value),
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Edit/Save Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : (_isEditing ? _saveProfile : () => setState(() => _isEditing = true)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? AppConstants.successColor : AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing ? 'Save Changes' : 'Edit Profile',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Cancel Button (when editing)
          if (_isEditing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () {
                  _refreshProfile();
                  setState(() {
                    _isEditing = false;
                    _imageBase64 = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.textSecondaryColor,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded),
                    SizedBox(width: 8),
                    Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Logout Button
          if (!_isEditing)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(authProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.errorColor,
                  side: BorderSide(color: AppConstants.errorColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
