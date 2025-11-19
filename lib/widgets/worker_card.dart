import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/image_base64_service.dart';
import '../utils/constants.dart';

/// Worker card widget for displaying worker information
class WorkerCard extends StatelessWidget {
  final UserModel worker;
  final VoidCallback onTap;

  const WorkerCard({Key? key, required this.worker, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Profile image
              CircleAvatar(
                radius: 30,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                backgroundImage: ImageBase64Service.base64ToImageProvider(
                  worker.profileImage,
                ),
                child: worker.profileImage == null
                    ? Text(
                        worker.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: AppConstants.paddingMedium),

              // Worker info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${worker.serviceType ?? "Professional"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppConstants.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          worker.city ?? 'Not specified',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rating and rate
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('requests')
                        .where('workerId', isEqualTo: worker.uid)
                        .where(
                          'status',
                          isEqualTo: AppConstants.statusCompleted,
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Calculate rating from available data
                      int reviewCount = 0;
                      double avgRating = 0.0;

                      if (snapshot.hasData && snapshot.data != null) {
                        final requests = snapshot.data!.docs;
                        final reviewedRequests = requests
                            .where(
                              (doc) =>
                                  doc.data() is Map &&
                                  (doc.data() as Map)['customerRating'] != null,
                            )
                            .toList();
                        reviewCount = reviewedRequests.length;
                        avgRating = reviewCount > 0
                            ? reviewedRequests.fold<double>(
                                    0.0,
                                    (sum, doc) =>
                                        sum +
                                        ((doc.data() as Map)['customerRating']
                                                as num)
                                            .toDouble(),
                                  ) /
                                  reviewCount
                            : 0.0;
                      }

                      // Show rating or "New" based on data
                      if (reviewCount > 0) {
                        return Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            const Icon(
                              Icons.star_outline,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'New',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${worker.rate?.toStringAsFixed(0) ?? "0"}/hr',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
