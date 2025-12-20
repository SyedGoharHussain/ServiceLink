import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// How to Use screen explaining the app functionality
class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'How to Use ServiceLink',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Welcome to ServiceLink!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your one-stop platform to find skilled professionals or offer your services to customers.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // For Customers Section
            _buildSectionHeader(
              'For Customers',
              Icons.person_outline_rounded,
              AppConstants.primaryColor,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              '1',
              'Browse Services',
              'Explore a wide range of service categories including plumbers, electricians, carpenters, and more.',
              Icons.search_rounded,
              AppConstants.primaryColor,
            ),
            _buildStepCard(
              '2',
              'Find Workers',
              'Use filters to search by location, rating, and price. View worker profiles with reviews and ratings.',
              Icons.people_outline_rounded,
              AppConstants.primaryColor,
            ),
            _buildStepCard(
              '3',
              'Send Request',
              'Select a worker and send a job request with your budget and requirements. You can share your location for easier navigation.',
              Icons.send_rounded,
              AppConstants.primaryColor,
            ),
            _buildStepCard(
              '4',
              'Chat & Hire',
              'Once the worker accepts, use the in-app chat to discuss details and coordinate the service.',
              Icons.chat_bubble_outline_rounded,
              AppConstants.primaryColor,
            ),
            _buildStepCard(
              '5',
              'Complete & Review',
              'After the job is done, mark it complete and leave a review to help other customers.',
              Icons.star_outline_rounded,
              AppConstants.primaryColor,
            ),

            const SizedBox(height: 32),

            // For Workers Section
            _buildSectionHeader(
              'For Workers',
              Icons.work_outline_rounded,
              AppConstants.secondaryColor,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              '1',
              'Set Up Profile',
              'Create your profile with service type, location, hourly rate, and profile picture.',
              Icons.person_add_outlined,
              AppConstants.secondaryColor,
            ),
            _buildStepCard(
              '2',
              'Receive Requests',
              'Get notifications when customers send you job requests based on your service type.',
              Icons.notifications_outlined,
              AppConstants.secondaryColor,
            ),
            _buildStepCard(
              '3',
              'Accept Jobs',
              'Review request details including budget, description, and location. Accept jobs that fit your schedule.',
              Icons.check_circle_outline_rounded,
              AppConstants.secondaryColor,
            ),
            _buildStepCard(
              '4',
              'Navigate & Work',
              'Use the map feature to navigate to customer location. Chat with customers for any clarifications.',
              Icons.map_outlined,
              AppConstants.secondaryColor,
            ),
            _buildStepCard(
              '5',
              'Complete & Earn',
              'Mark the job as complete when finished. Build your reputation through customer reviews.',
              Icons.payments_outlined,
              AppConstants.secondaryColor,
            ),

            const SizedBox(height: 32),

            // Key Features Section
            _buildSectionHeader(
              'Key Features',
              Icons.star_rounded,
              AppConstants.successColor,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              'Real-time Chat',
              'Communicate directly with workers or customers through our secure chat system.',
              Icons.chat_bubble_rounded,
              Colors.blue,
            ),
            _buildFeatureCard(
              'Location Sharing',
              'Share your location with workers to help them find you easily.',
              Icons.location_on_rounded,
              Colors.red,
            ),
            _buildFeatureCard(
              'Ratings & Reviews',
              'Build trust with our transparent rating and review system.',
              Icons.star_rounded,
              Colors.amber,
            ),
            _buildFeatureCard(
              'Push Notifications',
              'Stay updated with real-time notifications for messages and request updates.',
              Icons.notifications_active_rounded,
              Colors.purple,
            ),
            _buildFeatureCard(
              'Secure Platform',
              'Your data is protected with industry-standard security measures.',
              Icons.security_rounded,
              Colors.green,
            ),

            const SizedBox(height: 32),

            // Tips Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded, color: Colors.blue.shade700, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Pro Tips',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTip('Always communicate clearly about job requirements and expectations'),
                  _buildTip('Check worker ratings and reviews before sending a request'),
                  _buildTip('Enable location sharing for faster service'),
                  _buildTip('Leave honest reviews to help the community'),
                  _buildTip('Enable push notifications to never miss important updates'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Support Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 48, color: AppConstants.primaryColor),
                  const SizedBox(height: 12),
                  const Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you have any questions or need assistance, feel free to contact our support team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConstants.textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(String step, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppConstants.textSecondaryColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: AppConstants.textSecondaryColor,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
