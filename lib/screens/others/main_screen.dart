import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/request_provider.dart';
import '../../services/messaging_service.dart';
import '../../utils/constants.dart';
import '../customer/customer_home_screen.dart';
import '../worker/worker_home_screen.dart';
import '../customer/requests_screen.dart';
import '../chat/chat_list_screen.dart';
import 'profile_screen.dart';
import '../worker/earnings_screen.dart';
import '../worker/completed_tasks_screen.dart';
import '../worker/worker_reviews_screen.dart';
import 'how_to_use_screen.dart';

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    // Initialize messaging service
    _initializeMessaging();
    // Load data for badge counts
    _loadUserData();
    // Request notification permission after a short delay
    Future.delayed(const Duration(seconds: 1), _requestNotificationPermission);
  }

  Future<void> _initializeMessaging() async {
    final messagingService = MessagingService();
    await messagingService.initialize();
  }

  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userModel != null) {
        final userId = authProvider.userModel!.uid;
        final userRole = authProvider.userModel!.role;

        // Load chats for badge count
        context.read<ChatProvider>().loadUserChats(userId);

        // Load requests based on role
        if (userRole == AppConstants.roleWorker) {
          context.read<RequestProvider>().loadWorkerRequests(userId);
        } else {
          context.read<RequestProvider>().loadCustomerRequests(userId);
        }
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;

    final messagingService = MessagingService();

    // Check if permission is already granted
    final isGranted = await messagingService.isNotificationPermissionGranted();
    if (isGranted) return;

    // Show explanation dialog
    if (!mounted) return;

    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Stay updated with real-time notifications about:\n\n'
          '• New chat messages\n'
          '• Pending service requests\n'
          '• Request updates (accepted/rejected)\n'
          '• Completed tasks\n\n'
          'Enable notifications to get instant updates!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldRequest == true && mounted) {
      final granted = await messagingService.requestNotificationPermission();

      if (granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );

        // Update FCM token
        final authProvider = context.read<AuthProvider>();
        if (authProvider.userModel != null) {
          await messagingService.updateUserToken(authProvider.userModel!.uid);
        }
      }
    }
  }

  String _getAppBarTitle(int index, String? role) {
    switch (index) {
      case 0:
        return role == AppConstants.roleWorker
            ? 'Worker Dashboard'
            : 'Customer Dashboard';
      case 1:
        return 'Requests';
      case 2:
        return 'Chats';
      case 3:
        return 'Profile';
      default:
        return 'ServiceLink';
    }
  }

  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.userModel?.role;

    // Define screens based on role
    final List<Widget> screens = [
      userRole == AppConstants.roleWorker
          ? const WorkerHomeScreen()
          : const CustomerHomeScreen(),
      const RequestsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        // Check if we can pop the current navigator (i.e., there are screens on the stack)
        if (Navigator.of(context).canPop()) {
          // Let the normal back navigation happen
          return true;
        }
        
        // If we're not on the home tab (index 0), go back to home tab
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false; // Don't exit the app
        }
        
        // We're on the home tab, handle double-press to exit
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarIsClosed =
            _lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarIsClosed) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.exit_to_app, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Press back again to exit'),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(_currentIndex, userRole),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          automaticallyImplyLeading: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        drawer: _buildModernDrawer(context, authProvider, userRole),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: screens[_currentIndex],
        ),
        bottomNavigationBar: _buildModernBottomNav(authProvider),
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context, AuthProvider authProvider, String? userRole) {
    return Drawer(
      child: Column(
        children: [
          // Modern drawer header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage: authProvider.userModel?.profileImage != null
                        ? MemoryImage(
                            const Base64Decoder().convert(
                              authProvider.userModel!.profileImage!,
                            ),
                          )
                        : null,
                    child: authProvider.userModel?.profileImage == null
                        ? Text(
                            authProvider.userModel?.name[0].toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.userModel?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.userModel?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (userRole == AppConstants.roleWorker) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      authProvider.userModel?.serviceType ?? 'Worker',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (userRole == AppConstants.roleWorker) ...[
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Earnings',
                    subtitle: 'View your earnings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EarningsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.star_outline_rounded,
                    title: 'My Reviews',
                    subtitle: 'See customer feedback',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WorkerReviewsScreen()),
                      );
                    },
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.task_alt_outlined,
                  title: 'Completed Tasks',
                  subtitle: 'View task history',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CompletedTasksScreen()),
                    );
                  },
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  title: 'How to Use',
                  subtitle: 'Learn how to use the app',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HowToUseScreen()),
                    );
                  },
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove account',
                  isDestructive: true,
                  onTap: () => _showDeleteAccountDialog(context, authProvider),
                ),
              ],
            ),
          ),
          
          // App version
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ServiceLink v1.0.0',
              style: TextStyle(
                color: AppConstants.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppConstants.errorColor : AppConstants.textPrimaryColor;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? AppConstants.errorColor : AppConstants.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDestructive ? AppConstants.errorColor : AppConstants.primaryColor, size: 22),
      ),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: color.withOpacity(0.6), fontSize: 12)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, AuthProvider authProvider) async {
    Navigator.pop(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppConstants.errorColor),
            ),
            const SizedBox(width: 12),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await authProvider.deleteAccount();

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully'),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to delete account'),
            backgroundColor: AppConstants.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildModernBottomNav(AuthProvider authProvider) {
    final chatProvider = context.watch<ChatProvider>();
    final requestProvider = context.watch<RequestProvider>();

    final unreadChatCount = authProvider.userModel != null
        ? chatProvider.getTotalUnreadCount(authProvider.userModel!.uid)
        : 0;
    final pendingRequestsCount = requestProvider.getRequestsByStatus('pending').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', 0),
              _buildNavItem(1, Icons.work_outline_rounded, Icons.work_rounded, 'Requests', pendingRequestsCount),
              _buildNavItem(2, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat', unreadChatCount),
              _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, int badge) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppConstants.primaryColor : AppConstants.textSecondaryColor,
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppConstants.primaryColor : AppConstants.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
