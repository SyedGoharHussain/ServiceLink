import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/worker_card.dart';
import 'worker_detail_screen.dart';

/// Customer home screen - browse and search workers
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String? _selectedCity;
  String? _selectedServiceType;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load all workers initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().loadAllWorkers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchWorkers() {
    context.read<WorkerProvider>().searchWorkers(
      city: _selectedCity,
      serviceType: _selectedServiceType,
    );
  }

  @override
  Widget build(BuildContext context) {
   //inal authProvider = context.watch<AuthProvider>();
    final workerProvider = context.watch<WorkerProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Search section
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: AppConstants.cardColor,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by city, service type...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppConstants.backgroundColor,
                  ),
                  onSubmitted: (_) => _searchWorkers(),
                ),
                const SizedBox(height: AppConstants.paddingSmall),

                // Filters row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Service type chips
                      ...AppConstants.serviceTypes.map((serviceType) {
                        final isSelected = _selectedServiceType == serviceType;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(serviceType),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedServiceType = selected
                                    ? serviceType
                                    : null;
                              });
                              _searchWorkers();
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Available Workerss
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Workers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingSmall),

          // Workers list
          Expanded(
            child: workerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : workerProvider.workers.isEmpty
                ? Center(
                    child: Text(
                      'No workers found',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                    ),
                    itemCount: workerProvider.workers.length,
                    itemBuilder: (context, index) {
                      final worker = workerProvider.workers[index];
                      return WorkerCard(
                        worker: worker,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkerDetailScreen(worker: worker),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
