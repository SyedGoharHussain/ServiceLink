import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/worker_card.dart';
import 'worker_detail_screen.dart';

/// Customer home screen - browse and search workers
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String? _selectedServiceType;
  String? _selectedCity;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().loadAllWorkers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _searchWorkers() {
    context.read<WorkerProvider>().searchWorkers(
      city: _selectedCity,
      serviceType: _selectedServiceType,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedServiceType = null;
      _selectedCity = null;
      _searchController.clear();
    });
    context.read<WorkerProvider>().clearFilters();
  }

  void _showSortDialog() {
    final workerProvider = context.read<WorkerProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort By',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSortOption(
              'Highest Rating',
              Icons.star_rounded,
              WorkerSortOption.rating,
              workerProvider.currentSort,
            ),
            _buildSortOption(
              'Most Reviews',
              Icons.reviews_rounded,
              WorkerSortOption.reviewCount,
              workerProvider.currentSort,
            ),
            _buildSortOption(
              'Price: High to Low',
              Icons.arrow_upward_rounded,
              WorkerSortOption.priceHigh,
              workerProvider.currentSort,
            ),
            _buildSortOption(
              'Price: Low to High',
              Icons.arrow_downward_rounded,
              WorkerSortOption.priceLow,
              workerProvider.currentSort,
            ),
            _buildSortOption(
              'Name (A-Z)',
              Icons.sort_by_alpha_rounded,
              WorkerSortOption.name,
              workerProvider.currentSort,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    String title,
    IconData icon,
    WorkerSortOption option,
    WorkerSortOption currentSort,
  ) {
    final isSelected = option == currentSort;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppConstants.primaryColor
            : AppConstants.textSecondaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.textPrimaryColor,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: AppConstants.primaryColor)
          : null,
      onTap: () {
        context.read<WorkerProvider>().sortWorkers(option);
        Navigator.pop(context);
      },
    );
  }

  void _showCityFilterDialog() {
    final workerProvider = context.read<WorkerProvider>();
    final cities = workerProvider.availableCities;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter by City',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.clear_all_rounded,
                color: _selectedCity == null
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondaryColor,
              ),
              title: Text(
                'All Cities',
                style: TextStyle(
                  fontWeight: _selectedCity == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedCity == null
                      ? AppConstants.primaryColor
                      : AppConstants.textPrimaryColor,
                ),
              ),
              trailing: _selectedCity == null
                  ? Icon(Icons.check_rounded, color: AppConstants.primaryColor)
                  : null,
              onTap: () {
                setState(() => _selectedCity = null);
                workerProvider.filterByCity(null);
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: cities.isEmpty
                  ? Center(
                      child: Text(
                        'No cities available',
                        style: TextStyle(
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: cities.length,
                      itemBuilder: (context, index) {
                        final city = cities[index];
                        final isSelected = _selectedCity == city;
                        return ListTile(
                          leading: Icon(
                            Icons.location_city_rounded,
                            color: isSelected
                                ? AppConstants.primaryColor
                                : AppConstants.textSecondaryColor,
                          ),
                          title: Text(
                            city,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : AppConstants.textPrimaryColor,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: AppConstants.primaryColor,
                                )
                              : null,
                          onTap: () {
                            setState(() => _selectedCity = city);
                            workerProvider.filterByCity(city);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final workerProvider = context.watch<WorkerProvider>();
    final userName = authProvider.userModel?.name.split(' ').first ?? 'there';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<WorkerProvider>().loadAllWorkers();
          },
          child: CustomScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // Hero Section
              SliverToBoxAdapter(child: _buildHeroSection(userName)),

              // Search Section
              SliverToBoxAdapter(child: _buildSearchSection()),

              // Service Categories
              SliverToBoxAdapter(child: _buildServiceCategories()),

              // Workers Header
              SliverToBoxAdapter(child: _buildWorkersHeader(workerProvider)),

              // Workers List
              _buildWorkersList(workerProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(String userName) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $userName! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find skilled professionals for your home services',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick Stats
          Row(
            children: [
              _buildQuickStat(
                Icons.verified_user_outlined,
                'Verified',
                'Workers',
              ),
              const SizedBox(width: 24),
              _buildQuickStat(Icons.star_outline_rounded, '4.5+', 'Rating'),
              const SizedBox(width: 24),
              _buildQuickStat(Icons.speed_outlined, 'Quick', 'Response'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search workers...',
                  hintStyle: TextStyle(color: AppConstants.textSecondaryColor),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppConstants.textSecondaryColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppConstants.textSecondaryColor,
                          ),
                          onPressed: _clearFilters,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) => _searchWorkers(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // City Filter Button
          GestureDetector(
            onTap: _showCityFilterDialog,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _selectedCity != null
                    ? AppConstants.primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_city_rounded,
                color: _selectedCity != null
                    ? Colors.white
                    : AppConstants.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_selectedServiceType != null)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.textSecondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: AppConstants.serviceTypes.length,
            itemBuilder: (context, index) {
              final serviceType = AppConstants.serviceTypes[index];
              final isSelected = _selectedServiceType == serviceType;
              return _buildCategoryCard(
                serviceType,
                isSelected,
                _getServiceIcon(serviceType),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String serviceType,
    bool isSelected,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedServiceType = isSelected ? null : serviceType;
        });
        _searchWorkers();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              serviceType,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppConstants.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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

  Widget _buildWorkersHeader(WorkerProvider workerProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedServiceType != null
                      ? '$_selectedServiceType Workers'
                      : _selectedCity != null
                      ? 'Workers in $_selectedCity'
                      : 'Available Workers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${workerProvider.workers.length} professionals found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showSortDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 16,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersList(WorkerProvider workerProvider) {
    if (workerProvider.isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppConstants.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Finding workers...',
                style: TextStyle(color: AppConstants.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    if (workerProvider.workers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No workers found',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(color: AppConstants.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final worker = workerProvider.workers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkerCard(
              worker: worker,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerDetailScreen(worker: worker),
                  ),
                );
              },
            ),
          );
        }, childCount: workerProvider.workers.length),
      ),
    );
  }
}
