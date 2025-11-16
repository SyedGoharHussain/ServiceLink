import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/worker_provider.dart';
import '../../models/request_model.dart';
import '../../utils/constants.dart';
import '../../widgets/review_dialog.dart';

/// Screen to display completed tasks
class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({Key? key}) : super(key: key);

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
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

    // Filter only completed requests
    final completedRequests = requestProvider.requests
        .where((request) => request.status == AppConstants.statusCompleted)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Completed Tasks'), elevation: 1),
      body: completedRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No completed tasks yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              itemCount: completedRequests.length,
              itemBuilder: (context, index) {
                final request = completedRequests[index];
                return _CompletedTaskCard(request: request, isWorker: isWorker);
              },
            ),
    );
  }
}

class _CompletedTaskCard extends StatelessWidget {
  final RequestModel request;
  final bool isWorker;

  const _CompletedTaskCard({
    Key? key,
    required this.request,
    required this.isWorker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.serviceType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppConstants.successColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: AppConstants.successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingSmall),

            // User name
            Text(
              isWorker
                  ? 'Customer: ${request.customerName}'
                  : 'Worker: ${request.workerName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            ),

            const SizedBox(height: 4),

            // Location and date
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppConstants.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  request.city,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppConstants.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat(
                    'MMM dd, yyyy',
                  ).format(request.completedAt ?? request.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingSmall),

            // Description
            Text(
              request.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppConstants.paddingSmall),

            // Price
            Text(
              'Earned: \$${request.price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Rating section
            if (request.customerRating != null) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    request.customerRating!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.customerReview ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Add review button for customers
            if (!isWorker && request.customerRating == null) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final requestProvider = context.read<RequestProvider>();
                      final reviewed = await showDialog<bool>(
                        context: context,
                        builder: (context) => ReviewDialog(
                          request: request,
                          requestProvider: requestProvider,
                        ),
                      );

                      if (reviewed == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for your review!'),
                            backgroundColor: AppConstants.successColor,
                          ),
                        );

                        // Reload tasks
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.userModel != null) {
                          context.read<RequestProvider>().loadRequests(
                            authProvider.userModel!.uid,
                            authProvider.userModel!.role,
                          );
                        }

                        // Refresh worker profile
                        try {
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                          await context.read<WorkerProvider>().refreshWorker(
                            request.workerId,
                          );
                          if (authProvider.userModel?.uid == request.workerId) {
                            await authProvider.refreshUserProfile();
                          }
                        } catch (e) {
                          print('Refresh error after review: $e');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: AppConstants.errorColor,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.star, size: 16),
                  label: const Text('Add Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
