import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';

/// Worker home screen - view and manage job requests
class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRequests();
    _refreshProfile();
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
      print('Worker home: Refreshing profile...');
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUserProfile();
      if (mounted) {
        setState(() {}); // Force rebuild with new data
      }
      print('Worker home: Profile refreshed');
    } catch (e) {
      print('Worker home refresh error: $e');
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              margin: const EdgeInsets.all(AppConstants.paddingMedium),
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user?.name ?? "Worker"}!',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${user?.serviceType ?? "Service"} • ${user?.city ?? "City"}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  if (reviewCount > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No reviews yet',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                ],
              ),
            ),

            // Pending Requests
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Requests (${pendingRequests.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            if (pendingRequests.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Text(
                    'No pending requests',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ),
              )
            else
              ...pendingRequests.take(3).map((request) {
                return RequestCard(request: request);
              }).toList(),

            // Active Jobs
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Jobs (${acceptedRequests.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            if (acceptedRequests.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Text(
                    'No active jobs',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                ),
              )
            else
              ...acceptedRequests.take(3).map((request) {
                return RequestCard(request: request);
              }).toList(),
          ],
        ),
      ),
    );
  }
}
