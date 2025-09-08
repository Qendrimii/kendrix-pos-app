import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class HallsTablesScreen extends ConsumerStatefulWidget {
  const HallsTablesScreen({super.key});

  @override
  ConsumerState<HallsTablesScreen> createState() => _HallsTablesScreenState();
}

class _HallsTablesScreenState extends ConsumerState<HallsTablesScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        await Future.wait([
          ref.read(hallsProvider.notifier).loadFromApi(),
          ref.read(menuProvider.notifier).loadFromApi(),
          ref.read(waitersProvider.notifier).loadFromApi(),
        ]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data refreshed from API'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API not configured. Go to Settings to configure.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final halls = ref.watch(hallsProvider);
    final orders = ref.watch(ordersProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6), // Uber light grey
      appBar: AppBar(
        title: SizedBox(
          width: 40, // Increased from 32 to 40
          height: 40, // Increased from 32 to 40
          child: SvgPicture.asset(
            'assets/icons/logo.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFFFFF),
              BlendMode.srcIn,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF000000), // Uber Black
        foregroundColor: const Color(0xFFFFFFFF), // White text
        actions: [
          IconButton(
            icon: _isRefreshing 
              ? const SizedBox(
                  width: 24, // Increased from 20 to 24
                  height: 24, // Increased from 20 to 24
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, size: 28), // Increased icon size
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Refresh data from API',
            iconSize: 28, // Added icon size
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 28), // Increased icon size
            onPressed: () {
              ref.read(currentUserProvider.notifier).logout();
            },
            iconSize: 28, // Added icon size
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: halls.length,
          itemBuilder: (context, hallIndex) {
            final hall = halls[hallIndex];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: const Color(0xFFFFFFFF), // White cards
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hall.name,
                      style: const TextStyle(
                        fontSize: 24, // Increased from 20 to 24
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000), // Black textr
                      ),
                    ),
                    const SizedBox(height: 16), // Increased from 12 to 16
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // Changed from 4 to 3 tables per row
                        childAspectRatio: 0.9, // Decreased from 1.1 to 0.9 for bigger tiles
                        crossAxisSpacing: 16, // Increased from 12 to 16
                        mainAxisSpacing: 16, // Increased from 12 to 16
                      ),
                      itemCount: hall.tables.length,
                      itemBuilder: (context, tableIndex) {
                        final table = hall.tables[tableIndex];
                        
                        return TableTile(
                          table: table,
                          currentUser: currentUser!,
                          hasOrders: table.total > 0, // Use total from API instead of local orders
                          onTap: () async {
                            if (table.status == TableStatus.free) {
                              // Single API call to occupy table and assign waiter
                              await ref.read(hallsProvider.notifier).assignWaiter(table.id, currentUser.id);
                            }
                            // Format tableId as hallId_tableId for API compatibility
                            final formattedTableId = '${hall.id}_${table.id}';
                            context.go('/table/$formattedTableId');
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


