import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/request_model.dart';
import '../providers/request_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/worker_provider.dart';
import '../utils/constants.dart';
import '../screens/chat/chat_room_screen.dart';
import './review_dialog.dart';

/// Request card widget for displaying job requests
class RequestCard extends StatelessWidget {
  final RequestModel request;

  const RequestCard({Key? key, required this.request}) : super(key: key);

  Color _getStatusColor() {
    switch (request.status) {
      case AppConstants.statusPending:
        return AppConstants.warningColor;
      case AppConstants.statusAccepted:
        return AppConstants.primaryColor;
      case AppConstants.statusCompleted:
        return AppConstants.successColor;
      case AppConstants.statusRejected:
        return AppConstants.errorColor;
      default:
        return AppConstants.textSecondaryColor;
    }
  }

  String _getStatusText() {
    return request.status[0].toUpperCase() + request.status.substring(1);
  }

  String _getDeadlineText() {
    if (request.status == AppConstants.statusAccepted &&
        request.deadlineTime != null) {
      final now = DateTime.now();
      final deadline = request.deadlineTime!;
      final remaining = deadline.difference(now);

      if (remaining.isNegative) {
        final overdue = now.difference(deadline);
        if (overdue.inHours > 0) {
          return 'Overdue by ${overdue.inHours}h';
        } else {
          return 'Overdue by ${overdue.inMinutes}m';
        }
      } else {
        if (remaining.inHours > 0) {
          return '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
        } else {
          return '${remaining.inMinutes}m left';
        }
      }
    } else if (request.status == AppConstants.statusPending) {
      return 'Deadline: ${request.deadlineHours}h';
    }
    return '';
  }

  Color _getDeadlineColor() {
    if (request.status == AppConstants.statusAccepted &&
        request.deadlineTime != null) {
      final remaining = request.deadlineTime!.difference(DateTime.now());
      if (remaining.isNegative) return AppConstants.errorColor;
      if (remaining.inHours < 2) return AppConstants.warningColor;
    }
    return AppConstants.textSecondaryColor;
  }

  Future<void> _openMap(double latitude, double longitude) async {
    // Try Google Maps URL first
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    // Try geo URI as fallback
    final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');

    try {
      // Try launching with external application mode
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open maps';
      }
    } catch (e) {
      // Silent fail - map couldn't open
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.serviceType,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.customerName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location, date and budget in one row
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: AppConstants.textSecondaryColor,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    request.city,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: AppConstants.textSecondaryColor,
                ),
                const SizedBox(width: 2),
                Text(
                  DateFormat('MMM dd').format(request.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '\$${request.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Deadline indicator
            if (_getDeadlineText().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.timer, size: 12, color: _getDeadlineColor()),
                  const SizedBox(width: 3),
                  Text(
                    _getDeadlineText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getDeadlineColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),

            // Description
            Text(
              request.description,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Location shared indicator and map button
            if (request.latitude != null && request.longitude != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 12,
                    color: AppConstants.successColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Location shared',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.successColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () =>
                        _openMap(request.latitude!, request.longitude!),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.map,
                            size: 12,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'View Map',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (request.status == AppConstants.statusPending)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      // Only show accept/reject buttons if user is the worker
                      final isWorker =
                          authProvider.userModel?.uid == request.workerId;

                      if (!isWorker) {
                        return const SizedBox.shrink();
                      }

                      return Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              context.read<RequestProvider>().rejectRequest(
                                request.requestId,
                              );
                            },
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final success = await context
                                  .read<RequestProvider>()
                                  .acceptRequest(request.requestId);

                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request accepted!'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Accept'),
                          ),
                        ],
                      );
                    },
                  ),

                if (request.status == AppConstants.statusAccepted)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final isWorker =
                          authProvider.userModel?.uid == request.workerId;

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Complete Task Button (only for worker)
                          if (isWorker)
                            TextButton.icon(
                              onPressed: () async {
                                // Show confirmation dialog
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Complete Task'),
                                    content: const Text(
                                      'Are you sure you want to mark this task as completed?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Complete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && context.mounted) {
                                  final success = await context
                                      .read<RequestProvider>()
                                      .completeRequest(request.requestId);

                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Task marked as completed!',
                                        ),
                                        backgroundColor:
                                            AppConstants.successColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Complete'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          // Chat Button
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Get current user ID from auth provider
                              final authProvider = context.read<AuthProvider>();
                              final currentUserId = authProvider.userModel?.uid;

                              if (currentUserId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login first'),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                                return;
                              }

                              // Determine other user ID based on current user role
                              final otherUserId =
                                  currentUserId == request.workerId
                                  ? request.customerId
                                  : request.workerId;
                              final otherUserName =
                                  currentUserId == request.workerId
                                  ? request.customerName
                                  : request.workerName;

                              try {
                                print('DEBUG: Starting chat creation...');
                                print('DEBUG: Current User: $currentUserId');
                                print('DEBUG: Other User: $otherUserId');

                                // Create or get chat
                                final chatId = await context
                                    .read<ChatProvider>()
                                    .createOrGetChat(
                                      currentUserId: currentUserId,
                                      otherUserId: otherUserId,
                                    );

                                print('DEBUG: Chat created with ID: $chatId');

                                if (!context.mounted) {
                                  print(
                                    'DEBUG: Context not mounted, returning',
                                  );
                                  return;
                                }
                                // Navigate to chat room
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatRoomScreen(
                                      chatId: chatId,
                                      otherUserName: otherUserName,
                                    ),
                                  ),
                                );
                                print('DEBUG: Navigation completed');
                              } catch (e, stackTrace) {
                                print('DEBUG ERROR: $e');
                                print('DEBUG STACK: $stackTrace');

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to open chat: ${e.toString()}',
                                    ),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Chat'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                // Completed status - show review button for customer
                if (request.status == AppConstants.statusCompleted)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final isCustomer =
                          authProvider.userModel?.uid == request.customerId;
                      final hasReview = request.customerRating != null;

                      // For workers, show rating status
                      if (!isCustomer) {
                        return Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasReview
                                  ? '${request.customerRating!.toStringAsFixed(1)} rating'
                                  : 'Not rated yet',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                          ],
                        );
                      }

                      // For customers who already reviewed
                      if (hasReview) {
                        return Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Rated ${request.customerRating!.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppConstants.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (request.customerReview != null &&
                                request.customerReview!.isNotEmpty)
                              const Icon(
                                Icons.comment,
                                size: 14,
                                color: AppConstants.textSecondaryColor,
                              ),
                          ],
                        );
                      }

                      // For customers who haven't reviewed yet
                      return ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final requestProvider = context
                                .read<RequestProvider>();
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
                              // Refresh worker profile data after a short delay to ensure Firestore write completes
                              try {
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                                await context
                                    .read<WorkerProvider>()
                                    .refreshWorker(request.workerId);
                                // If worker is viewing their own profile, refresh AuthProvider too
                                final authProvider = context
                                    .read<AuthProvider>();
                                if (authProvider.userModel?.uid ==
                                    request.workerId) {
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
