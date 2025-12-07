import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/image_base64_service.dart';
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
  int _selectedDeadlineHours = 24;

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showHireDialog() async {
    // Capture the parent context before dialog
    final parentContext = context;
    bool shareLocation = true;
    int deadlineHours = _selectedDeadlineHours;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: deadlineHours,
                    decoration: const InputDecoration(
                      labelText: 'Deadline (Hours)',
                      prefixIcon: Icon(Icons.timer),
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(24, (index) => index + 1)
                        .map(
                          (hours) => DropdownMenuItem(
                            value: hours,
                            child: Text(
                              '$hours ${hours == 1 ? 'hour' : 'hours'}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        deadlineHours = value ?? 24;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Share my current location'),
                    subtitle: const Text('Helps worker find you easily'),
                    value: shareLocation,
                    onChanged: (value) {
                      setState(() {
                        shareLocation = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
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
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter your budget'),
                        backgroundColor: AppConstants.errorColor,
                      ),
                    );
                    return;
                  }

                  if (_descriptionController.text.trim().isEmpty) {
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
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid price'),
                        backgroundColor: AppConstants.errorColor,
                      ),
                    );
                    return;
                  }

                  // Close dialog first to avoid multiple clicks
                  Navigator.pop(dialogContext);

                  try {
                    // Get location if requested
                    double? latitude;
                    double? longitude;
                    String? locationAddress;

                    if (shareLocation) {
                      // Show loading message
                      if (mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Getting your location...'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }

                      // Directly request permission and get location
                      final position = await _determinePosition(parentContext);
                      if (position != null) {
                        latitude = position.latitude;
                        longitude = position.longitude;

                        if (mounted) {
                          ScaffoldMessenger.of(parentContext).clearSnackBars();
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✓ Location captured successfully!',
                              ),
                              duration: Duration(seconds: 2),
                              backgroundColor: AppConstants.successColor,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(parentContext).clearSnackBars();
                        }
                      }
                    }
                    final authProvider = parentContext.read<AuthProvider>();
                    final requestProvider = parentContext
                        .read<RequestProvider>();
                    final customer = authProvider.userModel;

                    if (customer == null) {
                      throw Exception('Customer user model is null');
                    }

                    final success = await requestProvider.createRequest(
                      customerId: customer.uid,
                      customerName: customer.name,
                      workerId: widget.worker.uid,
                      workerName: widget.worker.name,
                      serviceType: widget.worker.serviceType!,
                      city: widget.worker.city!,
                      price: price,
                      description: _descriptionController.text.trim(),
                      latitude: latitude,
                      longitude: longitude,
                      locationAddress: locationAddress,
                      deadlineHours: deadlineHours,
                    );

                    if (!mounted) return;

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
                  } catch (e) {
                    if (!mounted) return;

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
          );
        },
      ),
    );
  }

  Future<Position?> _determinePosition(BuildContext context) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return null;

        final bool? openSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                'Location services are turned off. Please enable location services in your device settings to share your location.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );

        if (openSettings == true) {
          await Geolocator.openLocationSettings();
        }
        return null;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Handle denied permission
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (!mounted) return null;

          await showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Permission Denied'),
                content: const Text(
                  'Location permission was denied. You need to allow location access to share your location with workers.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          return null;
        }
      }

      // Handle permanently denied permission
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return null;

        final bool? openSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permission is permanently denied. Please enable it manually in app settings to share your location with workers.\n\n'
                'Go to: Settings > Apps > mids_project > Permissions > Location',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );

        if (openSettings == true) {
          await Geolocator.openAppSettings();
        }
        return null;
      }

      // Permission granted, get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return null;
    }
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
                  ? ImageBase64Service.base64ToImage(
                      widget.worker.profileImage!,
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
