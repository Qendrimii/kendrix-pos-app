import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import '../utils/translations.dart';

class TableDetailScreen extends ConsumerStatefulWidget {
  final String tableId;

  const TableDetailScreen({super.key, required this.tableId});

  @override
  ConsumerState<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends ConsumerState<TableDetailScreen> {
  String selectedCategory = 'All';
  final Map<String, String> itemComments = {};
  String _searchQuery = '';
  List<MenuItem> _searchResults = [];
  bool _isSearching = false;
  List<String> _apiCategories = [];
  bool _isAddingItem = false;
  bool _isRemovingItem = false;
  bool _isPrintingOrder = false;
  bool _isGoingBack = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    // Load orders when entering the table
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTableOrders();
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        final categories = await apiService.getCategories();
        setState(() {
          _apiCategories = ['All', ...categories];
        });
        print('Loaded ${categories.length} categories from API: $categories');
      }
    } catch (e) {
      print('Failed to load categories from API: $e');
      // Fallback to extracting from menu items
      setState(() {
        _apiCategories = ['All'];
      });
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTableOrders() async {
    try {
      // Load table orders which now includes both TempTav and Orders data
      await ref.read(ordersProvider.notifier).loadTableOrders(widget.tableId);
    } catch (e) {
      print('Failed to load table orders: $e');
    }
  }

  Future<void> _checkAndFreeTable() async {
    if (_isGoingBack) return;
    _isGoingBack = true;
    try {
      // Check if widget is still mounted before using ref
      if (!mounted) {
        print('⚠️ Widget disposed, skipping table status check');
        return;
      }
      
      final orders = ref.read(ordersProvider);
      final tableOrders = orders.where((order) => 
        order.tableId == widget.tableId && 
        (order.status == OrderStatus.open || order.status == OrderStatus.printed)
      ).toList();
      
      // Check if there are any current orders (temp orders with items)
      final hasCurrentOrders = tableOrders.any((order) => 
        order.id.startsWith('temp_') && order.items.isNotEmpty
      );
      
      // Check if there are any past orders (non-temp orders)
      final hasPastOrders = tableOrders.any((order) => !order.id.startsWith('temp_'));
      
      print('🔍 Table ${widget.tableId} status check:');
      print('  - Current orders: $hasCurrentOrders');
      print('  - Past orders: $hasPastOrders');
      print('  - Total table orders: ${tableOrders.length}');
      
      // If no current orders and no past orders, free the table
      if (!hasCurrentOrders && !hasPastOrders) {
        print('🔄 No orders found - freeing table ${widget.tableId}');
        await ref.read(hallsProvider.notifier).freeTable(widget.tableId);
        print('✅ Table ${widget.tableId} freed automatically');
      } else {
        print('⏸️ Table ${widget.tableId} has orders - keeping occupied');
      }
    } catch (e) {
      print('❌ Error checking and freeing table: $e');
    } finally {
      _isGoingBack = false;
    }
  }

  String _trimProductName(String name) {
    if (name.length > 17) {
      return '${name.substring(0, 17)}...';
    }
    return name;
  }

  void _searchProducts(String query) {
    _searchDebounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _isSearching = false;
        selectedCategory = 'All';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
      selectedCategory = 'Search';
    });

    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final apiService = ApiService();
        if (apiService.isConfigured) {
          final results = await apiService.searchProducts(query);
          if (mounted) {
            setState(() {
              _searchResults = results;
              _isSearching = false;
            });
          }
        } else {
          final allMenu = ref.read(menuProvider);
          final results = allMenu.where((item) =>
            item.name.toLowerCase().contains(query.toLowerCase())
          ).toList();
          if (mounted) {
            setState(() {
              _searchResults = results;
              _isSearching = false;
            });
          }
        }
      } catch (e) {
        print('Search failed: $e');
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final halls = ref.watch(hallsProvider);
    final orders = ref.watch(ordersProvider);
    final menu = ref.watch(menuProvider);
    
    // Extract hall and table IDs from formatted tableId (hallId_tableId)
    final tableIdParts = widget.tableId.split('_');
    final hallId = tableIdParts.length >= 2 ? tableIdParts[0] : '';
    final actualTableId = tableIdParts.length >= 2 ? tableIdParts[1] : widget.tableId;
    
    // Find the table using the actual table ID
    TableInfo? table;
    for (final hall in halls) {
      final foundTable = hall.tables.where((t) => t.id == actualTableId).firstOrNull;
      if (foundTable != null) {
        table = foundTable;
        break;
      }
    }

    if (table == null || currentUser == null) {
      return Scaffold(
        body: Center(child: Text(AppTranslations.tableNotFound)),
      );
    }

    // Check access
    final canAccess = table.status == TableStatus.free || 
                     table.waiterId == currentUser.id;

    if (!canAccess) {
      return Scaffold(
        appBar: AppBar(
          title: Text(table.name),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                AppTranslations.accessDenied,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                AppTranslations.tableAssignedToAnotherWaiter,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Get table orders (using formatted tableId for API compatibility)
    final tableOrders = orders.where((order) => 
      order.tableId == widget.tableId && 
      (order.status == OrderStatus.open || order.status == OrderStatus.printed)
    ).toList();
    
    // Active order should ONLY be current orders (temp_ prefix), not previous orders
    final activeOrder = tableOrders.where((o) => 
      o.status == OrderStatus.open && o.id.startsWith('temp_')
    ).firstOrNull;
    
    // Check if there are current orders (temp orders with items)
    final hasCurrentOrders = tableOrders.any((order) => 
      order.id.startsWith('temp_') && order.items.isNotEmpty
    );
    
    // Check if there are past orders (non-temp orders)
    final hasPastOrders = tableOrders.any((order) => !order.id.startsWith('temp_'));
    
    // Payment should be disabled if there are current orders
    final canShowPayment = hasPastOrders && !hasCurrentOrders;
    
    // Debug: Log active order status
    if (activeOrder != null) {
      print('✅ Active order found: ${activeOrder.id} with ${activeOrder.items.length} items');
    } else {
      final tempOrders = tableOrders.where((o) => o.id.startsWith('temp_')).toList();
      print('❌ No active order found. TempTav orders: ${tempOrders.length}');
    }

    // Filter menu items
    final categories = _apiCategories.isNotEmpty ? _apiCategories : ['All', ...menu.map((item) => item.category).toSet().toList()];
    final filteredMenu = selectedCategory == 'Search' 
        ? _searchResults 
        : selectedCategory == 'All'
            ? menu 
            : menu.where((item) => item.category == selectedCategory).toList();

    final isMobile = MediaQuery.of(context).size.width < 800;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Check and free table if needed
          if (mounted) {
            await _checkAndFreeTable();
          }
          
          // Refresh halls data before going back
          print('🔄 Back button pressed - refreshing halls data...');
          if (mounted) {
            await ref.read(hallsProvider.notifier).loadFromApi();
            print('✅ Halls data refreshed via back button');
            
            if (context.mounted) {
              context.go('/halls');
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6), // Uber light grey
        resizeToAvoidBottomInset: false, // Prevent keyboard from resizing the view
        appBar: AppBar(
          title: SearchHeader(
            tableName: table.name,
            onSearchChanged: _searchProducts,
            isSearching: _isSearching,
            onBack: () async {
              // Check and free table if needed
              if (mounted) {
                await _checkAndFreeTable();
              }
              
              // Refresh halls data before going back
              print('🔄 Back button pressed - refreshing halls data...');
              if (mounted) {
                await ref.read(hallsProvider.notifier).loadFromApi();
                print('✅ Halls data refreshed via back button');
                
                if (context.mounted) {
                  context.go('/halls');
                }
              }
            },
          ),
          backgroundColor: const Color(0xFF000000), // Uber Black
          foregroundColor: const Color(0xFFFFFFFF), // White text
          automaticallyImplyLeading: false, // Disable default back button since we have custom one
          actions: [
            if (canShowPayment && !isMobile)
              IconButton(
                icon: const Icon(Icons.payment),
                onPressed: () => _showPaymentDialog(context, ref, tableOrders.where((order) => !order.id.startsWith('temp_')).toList(), tableName: table!.name),
              ),
          ],
        ),
        body: isMobile ? _buildMobileLayout(
          currentUser,
          categories,
          filteredMenu,
          activeOrder,
          tableOrders,
        ) : _buildDesktopLayout(
          currentUser,
          categories,
          filteredMenu,
          activeOrder,
          tableOrders,
        ),
        bottomNavigationBar: isMobile && (
          (activeOrder?.items.isNotEmpty ?? false) || 
          tableOrders.where((order) => !order.id.startsWith('temp_')).isNotEmpty
        ) ? 
          MobileBottomBar(
            currentUser: currentUser,
            activeOrder: activeOrder,
            tableOrders: tableOrders,
            onPrintOrder: () => activeOrder != null ? _printOrder(activeOrder) : null,
            onShowPayment: canShowPayment ? () => _showPaymentDialog(context, ref, tableOrders.where((order) => !order.id.startsWith('temp_')).toList(), tableName: table!.name) : null,
            isPrinting: _isPrintingOrder,
          ) : null,
      ),
    );
  }

  Widget _buildMobileLayout(
    Waiter currentUser,
    List<String> categories,
    List<MenuItem> filteredMenu,
    Order? activeOrder,
    List<Order> tableOrders,
  ) {
    return Column(
      children: [
        // Category filter
        CategoryFilter(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: (category) {
            setState(() {
              selectedCategory = category;
              _searchQuery = '';
              _searchResults = [];
              _isSearching = false;
            });
          },
        ),
        // Menu items
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filteredMenu.length,
              itemBuilder: (context, index) {
                final item = filteredMenu[index];
                return MenuItemCard(
                  item: item,
                  onTap: (_isAddingItem || _isPrintingOrder) ? null : () => _addItemToOrder(item),
                  onLongPress: (_isAddingItem || _isPrintingOrder) ? null : () => _showAddItemDialog(context, item),
                  userColor: const Color(0xFF000000),
                );
              },
            ),
          ),
        ),
        // Current order summary on mobile
        if (activeOrder?.items.isNotEmpty ?? false)
          MobileOrderSummary(
            currentUser: currentUser,
            activeOrder: activeOrder!,
            onRemoveItem: _removeItemFromOrder,
          ),
        // Past orders section on mobile
        MobilePastOrders(
          currentUser: currentUser,
          pastOrders: tableOrders.where((order) => !order.id.startsWith('temp_')).toList(),
          onTap: () => _showAllPreviousOrdersDialog(context, tableOrders.where((order) => !order.id.startsWith('temp_')).toList()),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    Waiter currentUser,
    List<String> categories,
    List<MenuItem> filteredMenu,
    Order? activeOrder,
    List<Order> tableOrders,
  ) {
    return Row(
      children: [
        // Menu section
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Category filter
              CategoryFilter(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    selectedCategory = category;
                    _searchQuery = '';
                    _searchResults = [];
                    _isSearching = false;
                  });
                },
              ),
              // Menu items
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // Increased from 4 to 5 columns for smaller cards
                      childAspectRatio: 0.8, // Reduced from 1.0 to 0.8 for taller cards to prevent overflow
                      crossAxisSpacing: 6, // Reduced spacing
                      mainAxisSpacing: 6, // Reduced spacing
                    ),
                    itemCount: filteredMenu.length,
                    itemBuilder: (context, index) {
                      final item = filteredMenu[index];
                      return MenuItemCard(
                        item: item,
                        onTap: _isAddingItem ? null : () => _addItemToOrder(item),
                        onLongPress: () => _showAddItemDialog(context, item),
                        userColor: const Color(0xFF000000),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Order section for desktop
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Current Order Section (60% of available space)
              Expanded(
                flex: 3,
                child: CurrentOrderSection(
                  activeOrder: activeOrder,
                  currentUser: currentUser,
                  onRemoveItem: _removeItem,
                  onCommentUpdate: _updateItemComment,
                  onQuantityUpdate: _updateItemQuantity,
                  onPrintOrder: () {
                    if (activeOrder != null) {
                      print('🔘 Desktop Order button clicked - activeOrder: ${activeOrder.id}, items: ${activeOrder.items.length}');
                      _printOrder(activeOrder);
                    }
                  },
                  isPrinting: _isPrintingOrder,
                ),
              ),
              // Previous Orders Section (40% of available space)
              Expanded(
                flex: 2,
                child: PreviousOrdersSection(
                  previousOrders: tableOrders.where((order) => !order.id.startsWith('temp_')).toList(),
                  onTap: () => _showAllPreviousOrdersDialog(context, tableOrders.where((order) => !order.id.startsWith('temp_')).toList()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _addItemToOrder(MenuItem item) async {
    if (_isAddingItem) return;
    setState(() => _isAddingItem = true);
    try {
      // Create order if none exists
      final activeOrder = ref.read(ordersProvider).where((order) =>
        order.tableId == widget.tableId && order.status == OrderStatus.open && order.id.startsWith('temp_')
      ).firstOrNull;

      if (activeOrder == null) {
        final createResult = await ref.read(ordersProvider.notifier).createOrder(widget.tableId);
        if (!createResult.success) {
          _showErrorSnackBar(createResult.errorMessage ?? AppTranslations.failedToCreateOrder);
          return;
        }
      }

      final comment = itemComments[item.id];
      final result = await ref.read(ordersProvider.notifier).addItemToOrder(
        widget.tableId,
        item,
        comment: comment,
      );

      if (!result.success) {
        _showErrorSnackBar(result.errorMessage ?? AppTranslations.failedToAddItem);
      }
    } finally {
      if (mounted) setState(() => _isAddingItem = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, MenuItem item) {
    final commentController = TextEditingController();
    int quantity = 1;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final subtotal = item.price * quantity;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery.of(dialogContext).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${item.price.toStringAsFixed(2)} / cope',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quantity selector
                  Text(
                    AppTranslations.quantity,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _quantityButton(
                        icon: Icons.remove,
                        onPressed: (quantity > 1 && !isSubmitting) ? () {
                          setDialogState(() => quantity--);
                        } : null,
                        backgroundColor: Colors.grey[200]!,
                        foregroundColor: Colors.black,
                      ),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      _quantityButton(
                        icon: Icons.add,
                        onPressed: isSubmitting ? null : () {
                          setDialogState(() => quantity++);
                        },
                        backgroundColor: const Color(0xFF000000),
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Comment field
                  Text(
                    AppTranslations.note,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: AppTranslations.commentOptional,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Subtotal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.total,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Add to Order button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        setDialogState(() => isSubmitting = true);
                        await _addItemToOrderWithDetails(item, quantity, commentController.text);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000000),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('${AppTranslations.addToOrder} ($quantity)'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _addItemToOrderWithDetails(MenuItem item, int quantity, String comment) async {
    if (_isAddingItem) return;
    setState(() => _isAddingItem = true);
    try {
      // Create order if none exists
      final activeOrder = ref.read(ordersProvider).where((order) =>
        order.tableId == widget.tableId && order.status == OrderStatus.open && order.id.startsWith('temp_')
      ).firstOrNull;

      if (activeOrder == null) {
        final createResult = await ref.read(ordersProvider.notifier).createOrder(widget.tableId);
        if (!createResult.success) {
          _showErrorSnackBar(createResult.errorMessage ?? AppTranslations.failedToCreateOrder);
          return;
        }
      }

      // Add items with comment - track failures
      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < quantity; i++) {
        final result = await ref.read(ordersProvider.notifier).addItemToOrder(
          widget.tableId,
          item,
          comment: comment.isNotEmpty ? comment : null,
        );

        if (result.success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      if (failCount > 0) {
        if (successCount > 0) {
          _showErrorSnackBar('${AppTranslations.addedItemsPartialFail.replaceFirst('{0}', successCount.toString()).replaceFirst('{1}', failCount.toString())}');
        } else {
          _showErrorSnackBar(AppTranslations.failedToAddItems);
        }
      }
    } finally {
      if (mounted) setState(() => _isAddingItem = false);
    }
  }

  Future<void> _removeItem(int index) async {
    if (_isRemovingItem) return;
    setState(() => _isRemovingItem = true);
    try {
      final result = await ref.read(ordersProvider.notifier).removeOrderItem(widget.tableId, index);
      if (!result.success) {
        _showErrorSnackBar(result.errorMessage ?? AppTranslations.failedToRemoveItem);
      }
    } finally {
      if (mounted) setState(() => _isRemovingItem = false);
    }
  }

  Future<void> _removeItemFromOrder(String orderId, OrderItem item) async {
    if (_isRemovingItem) return;
    setState(() => _isRemovingItem = true);
    try {
      final orders = ref.read(ordersProvider);
      final order = orders.firstWhere((o) => o.id == orderId);
      final itemIndex = order.items.indexOf(item);
      if (itemIndex != -1) {
        final result = await ref.read(ordersProvider.notifier).removeOrderItem(widget.tableId, itemIndex);
        if (!result.success) {
          _showErrorSnackBar(result.errorMessage ?? AppTranslations.failedToRemoveItem);
        }
      }
    } finally {
      if (mounted) setState(() => _isRemovingItem = false);
    }
  }

  void _updateItemComment(int index, String comment) {
    ref.read(ordersProvider.notifier).updateOrderItemComment(widget.tableId, index, comment);
  }

  void _updateItemQuantity(int index, int quantity) {
    ref.read(ordersProvider.notifier).updateOrderItemQuantity(widget.tableId, index, quantity);
  }

  Future<void> _printOrder(Order order) async {
    if (_isPrintingOrder) return;
    setState(() => _isPrintingOrder = true);

    print('_printOrder called in UI for order: ${order.id} with ${order.items.length} items');
    print('Order details: ${order.items.map((item) => '${item.name} x${item.quantity}').join(', ')}');

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(AppTranslations.sendingOrderToKitchen),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 10), // Will be dismissed when result comes
        ),
      );
    }

    final result = await ref.read(ordersProvider.notifier).printOrder(order.id);

    // Dismiss loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (result.success) {
      _showSuccessSnackBar(AppTranslations.orderSentToKitchen);

      // Navigate back to halls after a short delay
      Future.delayed(const Duration(seconds: 1), () async {
        if (context.mounted) {
          // Check and free table if needed
          if (mounted) {
            await _checkAndFreeTable();
          }

          // Refresh halls data before navigating back
          print('Refreshing halls data before navigation...');
          if (mounted) {
            await ref.read(hallsProvider.notifier).loadFromApi();
            print('Halls data refreshed');

            if (context.mounted) {
              context.go('/halls');
            }
          }
        }
      });
    } else {
      if (mounted) setState(() => _isPrintingOrder = false);
      // CRITICAL: Show error to user - order was NOT sent successfully
      _showErrorDialog(
        AppTranslations.orderFailed,
        result.errorMessage ?? AppTranslations.failedToSendOrder,
        result.isNetworkError,
      );
    }
  }

  void _showErrorDialog(String title, String message, bool isNetworkError) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (isNetworkError) ...[
              const SizedBox(height: 16),
              Text(
                AppTranslations.pleaseCheckNetworkConnection,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppTranslations.ok),
          ),
        ],
      ),
    );
  }

  void _showAllPreviousOrdersDialog(BuildContext context, List<Order> previousOrders) {
    // Extract all items from all previous orders and group by product name
    final Map<String, Map<String, dynamic>> productSummary = {};
    
    for (final order in previousOrders) {
      for (final item in order.items) {
        final key = item.name;
        if (productSummary.containsKey(key)) {
          productSummary[key]!['quantity'] += item.quantity;
          productSummary[key]!['total'] += item.price * item.quantity;
        } else {
          productSummary[key] = {
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'total': item.price * item.quantity,
            'comment': item.comment,
          };
        }
      }
    }
    
    final productList = productSummary.values.toList();
    final totalAmount = productList.fold<double>(0, (sum, item) => sum + item['total']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppTranslations.previousOrdersItems),
            Text(
              '${productList.length} ${AppTranslations.differentProducts} • \$${totalAmount.toStringAsFixed(2)} ${AppTranslations.total}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: productList.isEmpty
              ? Center(
                  child: Text(AppTranslations.noItemsFound),
                )
              : ListView.builder(
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    final product = productList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _trimProductName(product['name']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${AppTranslations.quantity}: ${product['quantity']} × \$${product['price'].toStringAsFixed(2)}'),
                            if (product['comment'] != null && product['comment'].toString().isNotEmpty)
                                                              Text(
                                  '${AppTranslations.note}: ${product['comment']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                          ],
                        ),
                        trailing: Text(
                          '\$${product['total'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppTranslations.close),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, List<Order> orders, {String tableName = ''}) {
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentDialog(
        orders: orders,
        tableId: widget.tableId,
        tableName: tableName,
        onPaymentComplete: () async {
          // Close the dialog first
          Navigator.of(dialogContext).pop();
          
          // Refresh halls data before navigating back
          print('🔄 Refreshing halls data after payment...');
          await ref.read(hallsProvider.notifier).loadFromApi();
          print('✅ Halls data refreshed after payment');
          
          // Navigate to halls using the main screen context
          if (mounted) {
            context.go('/halls');
          }
        },
      ),
    );
  }
}
