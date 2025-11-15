import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../utils/constants.dart';
import '../worker/worker_all_reviews_screen.dart';

/// Worker detail screen showing full profile and hire option
class WorkerDetailScreen extends StatefulWidget {
  final UserModel worker;

  const WorkerDetailScreen({Key? key, required this.worker}) : super(key: key);

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showHireDialog() async {
    // Capture the parent context before dialog
    final parentContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Job Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Your Budget (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate fields
              if (_priceController.text.trim().isEmpty) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your budget'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
                return;
              }

              if (_descriptionController.text.trim().isEmpty) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter job description'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
                return;
              }

              final price = double.tryParse(_priceController.text.trim());
              if (price == null || price <= 0) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
                return;
              }

              try {
                print('Button pressed - starting request creation');
                final authProvider = parentContext.read<AuthProvider>();
                final requestProvider = parentContext.read<RequestProvider>();
                final customer = authProvider.userModel;

                if (customer == null) {
                  throw Exception('Customer user model is null');
                }

                print('Customer: ${customer.uid} - ${customer.name}');
                print('Worker: ${widget.worker.uid} - ${widget.worker.name}');
                print('Service: ${widget.worker.serviceType}');
                print('City: ${widget.worker.city}');
                print('Price: $price');

                final success = await requestProvider.createRequest(
                  customerId: customer.uid,
                  customerName: customer.name,
                  workerId: widget.worker.uid,
                  workerName: widget.worker.name,
                  serviceType: widget.worker.serviceType!,
                  city: widget.worker.city!,
                  price: price,
                  description: _descriptionController.text.trim(),
                );

                print('Request creation result: $success');

                if (!mounted) return;

                // Close dialog first
                Navigator.pop(dialogContext);

                // Clear fields
                _priceController.clear();
                _descriptionController.clear();

                // Show result using parent context
                if (success) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Request sent successfully!'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        requestProvider.errorMessage ??
                            'Failed to send request',
                      ),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              } catch (e, stackTrace) {
                print('Worker detail screen error: $e');
                print('Stack trace: $stackTrace');

                if (!mounted) return;

                // Close dialog
                Navigator.pop(dialogContext);

                // Show error using parent context
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: AppConstants.errorColor,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate rating from completed requests
    final requestProvider = context.watch<RequestProvider>();
    final completedRequests = requestProvider.requests
        .where(
          (r) =>
              r.workerId == widget.worker.uid &&
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
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.worker.profileImage != null
                  ? CachedNetworkImage(
                      imageUrl: widget.worker.profileImage!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      child: Center(
                        child: Text(
                          widget.worker.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and service
                  Text(
                    widget.worker.name,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.worker.serviceType ?? 'Professional',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppConstants.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rating and location
                  Row(
                    children: [
                      if (reviewCount > 0) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(width: 16),
                      ] else ...[
                        const Icon(
                          Icons.star_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'No reviews yet',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                      ],
                      const Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppConstants.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.worker.city ?? 'Not specified',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Reviews Section
                  if (widget.worker.reviewCount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reviews',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkerAllReviewsScreen(
                                  workerId: widget.worker.uid,
                                  workerName: widget.worker.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ReviewsSectionWidget(workerId: widget.worker.uid),
                    const SizedBox(height: 24),
                  ],

                  // Rate
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hourly Rate',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '\$${widget.worker.rate?.toStringAsFixed(0) ?? "0"}/hr',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Text('About', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    widget.worker.description ?? 'No description provided.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Hire button
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showHireDialog,
            child: const Text('Hire Now'),
          ),
        ),
      ),
    );
  }
}

// Reviews Section Widget
class _ReviewsSectionWidget extends StatelessWidget {
  final String workerId;

  const _ReviewsSectionWidget({Key? key, required this.workerId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.requestsCollection)
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: AppConstants.statusCompleted)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final reviewedRequests = snapshot.data!.docs
            .map(
              (doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>),
            )
            .where((request) => request.customerRating != null)
            .toList();

        if (reviewedRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Reviews',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${reviewedRequests.length} ${reviewedRequests.length == 1 ? 'review' : 'reviews'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...reviewedRequests.take(3).map((request) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            request.customerName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.customerRating!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (request.customerReview != null &&
                        request.customerReview!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        request.customerReview!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
