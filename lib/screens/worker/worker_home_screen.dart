import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';
import '../../widgets/profile_completion_dialog.dart';
import '../others/profile_screen.dart';

/// Worker home screen - view and manage job requests
class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen>
    with WidgetsBindingObserver {
  bool _hasCheckedProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRequests();
    _refreshProfile();
    // Check profile completion after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompletion();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshProfile();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadRequests() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userModel != null) {
      context.read<RequestProvider>().loadWorkerRequests(
        authProvider.userModel!.uid,
      );
    }
  }

  void _refreshProfile() async {
    if (!mounted) return;
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUserProfile();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Worker home refresh error: $e');
    }
  }

  void _checkProfileCompletion() {
    if (_hasCheckedProfile) return;
    _hasCheckedProfile = true;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    if (!ProfileCompletionHelper.isWorkerProfileComplete(user)) {
      final missingFields = ProfileCompletionHelper.getMissingWorkerFields(user);
      
      ProfileCompletionHelper.showProfileCompletionDialog(
        context,
        title: 'Complete Your Profile',
        message: 'Please complete your profile to start receiving job requests from customers.',
        missingFields: missingFields,
        onCompleteProfile: () {
          // Navigate to profile tab (index 3 in main screen)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final user = authProvider.userModel;

    final pendingRequests = requestProvider.getRequestsByStatus(
      AppConstants.statusPending,
    );
    final acceptedRequests = requestProvider.getRequestsByStatus(
      AppConstants.statusAccepted,
    );
    final completedRequests = requestProvider.getRequestsByStatus(
      AppConstants.statusCompleted,
    );

    // Calculate rating from completed requests
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
      body: RefreshIndicator(
        onRefresh: () async {
          _loadRequests();
          _refreshProfile();
        },
        child: CustomScrollView(
          slivers: [
            // Welcome Hero Card
            SliverToBoxAdapter(
              child: _buildHeroCard(user, avgRating, reviewCount),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: _buildStatsSection(
                pendingRequests.length,
                acceptedRequests.length,
                completedRequests.length,
              ),
            ),

            // Pending Requests Section
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Pending Requests',
                pendingRequests.length,
                Icons.pending_actions_rounded,
                AppConstants.warningColor,
              ),
            ),

            if (pendingRequests.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(
                  'No pending requests',
                  'New job requests will appear here',
                  Icons.inbox_rounded,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: RequestCard(request: pendingRequests[index]),
                  ),
                  childCount: pendingRequests.length > 3
                      ? 3
                      : pendingRequests.length,
                ),
              ),

            // Active Jobs Section
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Active Jobs',
                acceptedRequests.length,
                Icons.work_rounded,
                AppConstants.primaryColor,
              ),
            ),

            if (acceptedRequests.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(
                  'No active jobs',
                  'Accept requests to start working',
                  Icons.work_off_rounded,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: RequestCard(request: acceptedRequests[index]),
                  ),
                  childCount: acceptedRequests.length > 3
                      ? 3
                      : acceptedRequests.length,
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(dynamic user, double avgRating, int reviewCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.name ?? "Worker"}! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${user?.serviceType ?? "Service"} • ${user?.city ?? "City"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getServiceIcon(user?.serviceType ?? ''),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildHeroStat(
                      icon: Icons.star_rounded,
                      value: reviewCount > 0
                          ? avgRating.toStringAsFixed(1)
                          : '-',
                      label: 'Rating',
                      maxWidth: (constraints.maxWidth - 32) / 3,
                    ),
                    _buildVerticalDivider(),
                    _buildHeroStat(
                      icon: Icons.reviews_rounded,
                      value: '$reviewCount',
                      label: 'Reviews',
                      maxWidth: (constraints.maxWidth - 32) / 3,
                    ),
                    _buildVerticalDivider(),
                    _buildHeroStat(
                      icon: Icons.attach_money_rounded,
                      value: '\$${user?.rate?.toStringAsFixed(0) ?? "0"}',
                      label: '/hr',
                      maxWidth: (constraints.maxWidth - 32) / 3,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
    double? maxWidth,
  }) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int pending, int active, int completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Pending',
              '$pending',
              Icons.pending_actions_rounded,
              AppConstants.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active',
              '$active',
              Icons.work_rounded,
              AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Done',
              '$completed',
              Icons.check_circle_rounded,
              AppConstants.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppConstants.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'carpenter':
        return Icons.construction;
      case 'plumber':
        return Icons.plumbing;
      case 'electrician':
        return Icons.electrical_services;
      case 'mechanic':
        return Icons.build;
      case 'gardener':
        return Icons.grass;
      case 'cleaner':
        return Icons.cleaning_services;
      case 'painter':
        return Icons.format_paint;
      case 'handyman':
        return Icons.handyman;
      default:
        return Icons.work;
    }
  }
}
