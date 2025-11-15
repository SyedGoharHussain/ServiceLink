import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../utils/constants.dart';

/// Screen to display earnings from completed tasks
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userModel != null) {
        context.read<RequestProvider>().loadRequests(
          authProvider.userModel!.uid,
          authProvider.userModel!.role,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final isWorker = authProvider.userModel?.role == AppConstants.roleWorker;

    // Calculate earnings from completed tasks
    final completedRequests = requestProvider.requests
        .where((request) => request.status == AppConstants.statusCompleted)
        .toList();

    final totalEarnings = completedRequests.fold<double>(
      0,
      (sum, request) => sum + request.price,
    );

    final averageRating =
        completedRequests.where((r) => r.customerRating != null).isEmpty
        ? 0.0
        : completedRequests
                  .where((r) => r.customerRating != null)
                  .map((r) => r.customerRating!)
                  .reduce((a, b) => a + b) /
              completedRequests.where((r) => r.customerRating != null).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings'), elevation: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Earnings Card
            Card(
              color: AppConstants.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Total Earnings',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 32,
                            color: AppConstants.successColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${completedRequests.length}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.star, size: 32, color: Colors.amber),
                          const SizedBox(height: 8),
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Avg Rating',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Earnings Breakdown
            Text(
              'Earnings Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (completedRequests.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.work_off_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No completed tasks yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...completedRequests.map((request) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppConstants.primaryColor.withOpacity(
                        0.1,
                      ),
                      child: Icon(
                        _getServiceIcon(request.serviceType),
                        color: AppConstants.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      request.serviceType,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isWorker ? request.customerName : request.workerName,
                    ),
                    trailing: Text(
                      '\$${request.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'plumber':
        return Icons.plumbing;
      case 'electrician':
        return Icons.electrical_services;
      case 'carpenter':
        return Icons.construction;
      case 'mechanic':
        return Icons.build;
      case 'painter':
        return Icons.format_paint;
      case 'cleaner':
        return Icons.cleaning_services;
      case 'gardener':
        return Icons.yard;
      case 'handyman':
        return Icons.handyman;
      default:
        return Icons.work;
    }
  }
}
