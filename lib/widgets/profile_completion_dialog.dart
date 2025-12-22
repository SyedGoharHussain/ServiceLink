import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Helper class to check and prompt for profile completion
class ProfileCompletionHelper {
  /// Check if customer profile is complete (name, phone verified, city)
  static bool isCustomerProfileComplete(UserModel? user) {
    if (user == null) return false;
    return user.name.isNotEmpty &&
        user.phone != null &&
        user.phone!.isNotEmpty &&
        user.city != null &&
        user.city!.isNotEmpty;
  }

  /// Check if worker profile is complete (name, phone verified, city, serviceType, rate, description)
  static bool isWorkerProfileComplete(UserModel? user) {
    if (user == null) return false;
    return user.name.isNotEmpty &&
        user.phone != null &&
        user.phone!.isNotEmpty &&
        user.city != null &&
        user.city!.isNotEmpty &&
        user.serviceType != null &&
        user.serviceType!.isNotEmpty &&
        user.rate != null &&
        user.rate! > 0 &&
        user.description != null &&
        user.description!.isNotEmpty;
  }

  /// Get list of missing fields for customer
  static List<String> getMissingCustomerFields(UserModel? user) {
    if (user == null) return ['All fields'];
    final missing = <String>[];
    if (user.name.isEmpty) missing.add('Name');
    if (user.phone == null || user.phone!.isEmpty) {
      missing.add('Phone Number');
    }
    if (user.city == null || user.city!.isEmpty) missing.add('City');
    return missing;
  }

  /// Get list of missing fields for worker
  static List<String> getMissingWorkerFields(UserModel? user) {
    if (user == null) return ['All fields'];
    final missing = <String>[];
    if (user.name.isEmpty) missing.add('Name');
    if (user.phone == null || user.phone!.isEmpty) {
      missing.add('Phone Number');
    }
    if (user.city == null || user.city!.isEmpty) missing.add('City');
    if (user.serviceType == null || user.serviceType!.isEmpty) missing.add('Service Type');
    if (user.rate == null || user.rate! <= 0) missing.add('Hourly Rate');
    if (user.description == null || user.description!.isEmpty) missing.add('Description');
    return missing;
  }

  /// Show profile completion dialog
  static Future<bool?> showProfileCompletionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required List<String> missingFields,
    required VoidCallback onCompleteProfile,
  }) async {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.65,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.warningColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: AppConstants.warningColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstants.textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Missing Fields Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppConstants.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Missing Information:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppConstants.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...missingFields.map(
                          (field) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Icon(
                                    Icons.circle,
                                    size: 5,
                                    color: AppConstants.errorColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    field,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: Text(
                          'Later',
                          style: TextStyle(
                            color: AppConstants.textSecondaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                          onCompleteProfile();
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
