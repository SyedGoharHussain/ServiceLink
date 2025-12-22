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
import '../services/call_service.dart';
import './review_dialog.dart';

/// Request card widget for displaying job requests
class RequestCard extends StatelessWidget {
  final RequestModel request;

  const RequestCard({super.key, required this.request});

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

  Future<void> _openMap(double latitude, double longitude) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _makeCall(
    BuildContext context, {
    required String otherUserId,
    String? personName,
    required String personRole,
    String? phoneNumber,
  }) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to make call. Please try again.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    CallService().showCallDialog(
      context,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      otherUserName: personName ?? personRole,
      otherUserRole: personRole,
      phoneNumber: phoneNumber,
    );
  }

  Widget _buildCallButton(
    BuildContext context, {
    required String otherUserId,
    String? personName,
    required String personRole,
    String? phoneNumber,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _makeCall(
          context,
          otherUserId: otherUserId,
          personName: personName,
          personRole: personRole,
          phoneNumber: phoneNumber,
        ),
        icon: const Icon(Icons.call_outlined, size: 18),
        label: Text('Call $personRole'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: BorderSide(color: Colors.green.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getServiceIcon(request.serviceType),
                      color: AppConstants.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.serviceType,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Customer: ${request.customerName}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppConstants.textSecondaryColor,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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

              const SizedBox(height: 12),
              Container(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 12),

              // Location and date row
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppConstants.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            request.city,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppConstants.textSecondaryColor,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppConstants.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd').format(request.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Map Location Button
              if (request.latitude != null && request.longitude != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _openMap(request.latitude!, request.longitude!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 18,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View on Map',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: AppConstants.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 12),

              // Budget and Location indicator row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '\$${request.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (request.latitude != null && request.longitude != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppConstants.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Location shared',
                          style: TextStyle(
                            color: AppConstants.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Actions
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isWorker = authProvider.userModel?.uid == request.workerId;
        final isCustomer = authProvider.userModel?.uid == request.customerId;

        if (request.status == AppConstants.statusPending && isWorker) {
          return Column(
            children: [
              // Call button for worker to call customer
              _buildCallButton(
                context,
                otherUserId: request.customerId,
                personName: request.customerName,
                personRole: 'Customer',
                phoneNumber: request.customerPhone,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<RequestProvider>().rejectRequest(
                          request.requestId,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.errorColor,
                        side: BorderSide(
                          color: AppConstants.errorColor.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final workerPhone = context.read<AuthProvider>().userModel?.phone;
                        final success = await context
                            .read<RequestProvider>()
                            .acceptRequest(request.requestId, workerPhone: workerPhone);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request accepted!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        if (request.status == AppConstants.statusAccepted) {
          // Determine who to call based on current user
          final userIdToCall = isWorker ? request.customerId : request.workerId;
          final nameToCall = isWorker ? request.customerName : request.workerName;
          final roleToCall = isWorker ? 'Customer' : 'Worker';
          final phoneToCall = isWorker ? request.customerPhone : request.workerPhone;

          return Column(
            children: [
              Row(
                children: [
                  // Call button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(
                        context,
                        otherUserId: userIdToCall,
                        personName: nameToCall,
                        personRole: roleToCall,
                        phoneNumber: phoneToCall,
                      ),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Chat button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openChat(context),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isWorker) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCompleteDialog(context),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark as Complete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.successColor,
                      side: BorderSide(
                        color: AppConstants.successColor.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        if (request.status == AppConstants.statusCompleted) {
          final hasReview = request.customerRating != null;

          if (!isCustomer) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    hasReview
                        ? '${request.customerRating!.toStringAsFixed(1)} rating'
                        : 'Awaiting review',
                    style: TextStyle(
                      color: hasReview
                          ? Colors.amber.shade700
                          : AppConstants.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (hasReview) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    'You rated ${request.customerRating!.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: AppConstants.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReviewDialog(context),
              icon: const Icon(Icons.star_outline, size: 18),
              label: const Text('Add Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _showCompleteDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Task'),
        content: const Text(
          'Are you sure you want to mark this task as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.successColor,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<RequestProvider>().completeRequest(
        request.requestId,
      );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task marked as completed!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    }
  }

  Future<void> _openChat(BuildContext context) async {
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

    final otherUserId = currentUserId == request.workerId
        ? request.customerId
        : request.workerId;
    final otherUserName = currentUserId == request.workerId
        ? request.customerName
        : request.workerName;

    try {
      final chatId = await context.read<ChatProvider>().createOrGetChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatRoomScreen(chatId: chatId, otherUserName: otherUserName),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    try {
      final requestProvider = context.read<RequestProvider>();
      final reviewed = await showDialog<bool>(
        context: context,
        builder: (context) =>
            ReviewDialog(request: request, requestProvider: requestProvider),
      );

      if (reviewed == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your review!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        await context.read<WorkerProvider>().refreshWorker(request.workerId);
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
  }
}
