import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';

/// Requests screen showing all job requests
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  void _loadRequests() {
    final authProvider = context.read<AuthProvider>();
    final requestProvider = context.read<RequestProvider>();

    if (authProvider.userModel != null) {
      if (authProvider.userModel!.role == AppConstants.roleWorker) {
        requestProvider.loadWorkerRequests(authProvider.userModel!.uid);
      } else {
        requestProvider.loadCustomerRequests(authProvider.userModel!.uid);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<RequestProvider>();

    return Scaffold(
      body: Column(
        children: [
          Material(
            elevation: 1,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Accepted'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(
                  requestProvider.getRequestsByStatus(
                    AppConstants.statusPending,
                  ),
                ),
                _buildRequestList(
                  requestProvider.getRequestsByStatus(
                    AppConstants.statusAccepted,
                  ),
                ),
                _buildRequestList(
                  requestProvider.getRequestsByStatus(
                    AppConstants.statusRejected,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List requests) {
    if (requests.isEmpty) {
      return const Center(child: Text('No requests found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return RequestCard(request: requests[index]);
      },
    );
  }
}
