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

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

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

  Widget _buildBottomNavigationBar(AuthProvider authProvider) {
    final chatProvider = context.watch<ChatProvider>();
    final requestProvider = context.watch<RequestProvider>();

    // Get unread counts
    final unreadChatCount = authProvider.userModel != null
        ? chatProvider.getTotalUnreadCount(authProvider.userModel!.uid)
        : 0;

    // Get pending requests count (for workers) or updated requests (for customers)
    final pendingRequestsCount = requestProvider
        .getRequestsByStatus('pending')
        .length;

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(Icons.work_outline, pendingRequestsCount),
          activeIcon: _buildIconWithBadge(Icons.work, pendingRequestsCount),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(Icons.chat_bubble_outline, unreadChatCount),
          activeIcon: _buildIconWithBadge(Icons.chat_bubble, unreadChatCount),
          label: 'Chat',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildIconWithBadge(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
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
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarIsClosed =
            _lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarIsClosed) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle(_currentIndex, userRole)),
          automaticallyImplyLeading: true,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppConstants.primaryColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        authProvider.userModel?.name[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authProvider.userModel?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      authProvider.userModel?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (userRole == AppConstants.roleWorker) ...[
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Earnings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EarningsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.star_rate),
                  title: const Text('My Reviews'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkerReviewsScreen(),
                      ),
                    );
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.task_alt),
                title: const Text('Completed Tasks'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompletedTasksScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
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
                            backgroundColor: Colors.red,
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
                        const SnackBar(
                          content: Text('Account deleted successfully'),
                          backgroundColor: AppConstants.successColor,
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.errorMessage ??
                                'Failed to delete account',
                          ),
                          backgroundColor: AppConstants.errorColor,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        body: screens[_currentIndex],
        bottomNavigationBar: _buildBottomNavigationBar(authProvider),
      ),
    );
  }
}
