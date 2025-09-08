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

  @override
  void initState() {
    super.initState();
    // Load orders when entering the table
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTableOrders();
    });
  }

  @override
  void dispose() {
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
    }
  }

  String _trimProductName(String name) {
    if (name.length > 17) {
      return '${name.substring(0, 17)}...';
    }
    return name;
  }

  Future<void> _searchProducts(String query) async {
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

    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        final results = await apiService.searchProducts(query);
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } else {
        // Fallback to local search if API not configured
        final allMenu = ref.read(menuProvider);
        final results = allMenu.where((item) => 
          item.name.toLowerCase().contains(query.toLowerCase())
        ).toList();
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search failed: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
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
    final categories = ['All', ...menu.map((item) => item.category).toSet().toList()];
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
                onPressed: () => _showPaymentDialog(context, ref, tableOrders.where((order) => !order.id.startsWith('temp_')).toList()),
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
            onShowPayment: canShowPayment ? () => _showPaymentDialog(context, ref, tableOrders.where((order) => !order.id.startsWith('temp_')).toList()) : null,
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
                  onTap: () => _addItemToOrder(item),
                  onLongPress: () => _showAddItemDialog(context, item),
                  userColor: const Color(0xFF000000), // Uber Black
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
                        onTap: () => _addItemToOrder(item),
                        onLongPress: () => _showAddItemDialog(context, item),
                        userColor: const Color(0xFF000000), // Uber Black
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

  void _addItemToOrder(MenuItem item) {
    // Create order if none exists
    final activeOrder = ref.read(ordersProvider).where((order) => 
      order.tableId == widget.tableId && order.status == OrderStatus.open && order.id.startsWith('temp_')
    ).firstOrNull;
    
    if (activeOrder == null) {
      ref.read(ordersProvider.notifier).createOrder(widget.tableId);
    }
    
    final comment = itemComments[item.id];
    ref.read(ordersProvider.notifier).addItemToOrder(
      widget.tableId,
      item,
      comment: comment,
    );
  }

  void _showAddItemDialog(BuildContext context, MenuItem item) {
    final commentController = TextEditingController();
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${AppTranslations.addItem} ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: AppTranslations.commentOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantity > 1 ? () {
                      setState(() => quantity--);
                    } : null,
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => quantity++);
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppTranslations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                _addItemToOrderWithDetails(item, quantity, commentController.text);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000000),
                foregroundColor: Colors.white,
              ),
              child: Text('${AppTranslations.addToOrder} $quantity'),
            ),
          ],
        ),
      ),
    );
  }

  void _addItemToOrderWithDetails(MenuItem item, int quantity, String comment) {
    // Create order if none exists
    final activeOrder = ref.read(ordersProvider).where((order) => 
      order.tableId == widget.tableId && order.status == OrderStatus.open && order.id.startsWith('temp_')
    ).firstOrNull;
    
    if (activeOrder == null) {
      ref.read(ordersProvider.notifier).createOrder(widget.tableId);
    }
    
    // Add multiple items with comment
    for (int i = 0; i < quantity; i++) {
      ref.read(ordersProvider.notifier).addItemToOrder(
        widget.tableId,
        item,
        comment: comment.isNotEmpty ? comment : null,
      );
    }
  }

  void _removeItem(int index) {
    ref.read(ordersProvider.notifier).removeOrderItem(widget.tableId, index);
  }

  void _removeItemFromOrder(String orderId, OrderItem item) {
    // Find the order and the item index
    final orders = ref.read(ordersProvider);
    final order = orders.firstWhere((o) => o.id == orderId);
    final itemIndex = order.items.indexOf(item);
    if (itemIndex != -1) {
      ref.read(ordersProvider.notifier).removeOrderItem(widget.tableId, itemIndex);
    }
  }

  void _updateItemComment(int index, String comment) {
    ref.read(ordersProvider.notifier).updateOrderItemComment(widget.tableId, index, comment);
  }

  void _updateItemQuantity(int index, int quantity) {
    ref.read(ordersProvider.notifier).updateOrderItemQuantity(widget.tableId, index, quantity);
  }

  void _printOrder(Order order) {
    print('🎯 _printOrder called in UI for order: ${order.id} with ${order.items.length} items');
    print('📊 Order details: ${order.items.map((item) => '${item.name} x${item.quantity}').join(', ')}');
    
    ref.read(ordersProvider.notifier).printOrder(order.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.orderSentToKitchen),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    
    // Navigate back to halls after a short delay
    Future.delayed(const Duration(seconds: 1), () async {
      if (context.mounted) {
        // Check and free table if needed
        if (mounted) {
          await _checkAndFreeTable();
        }
        
        // Refresh halls data before navigating back
        print('🔄 Refreshing halls data before navigation...');
        if (mounted) {
          await ref.read(hallsProvider.notifier).loadFromApi();
          print('✅ Halls data refreshed');
          
          if (context.mounted) {
            context.go('/halls');
          }
        }
      }
    });
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

  void _showPaymentDialog(BuildContext context, WidgetRef ref, List<Order> orders) {
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentDialog(
        orders: orders,
        tableId: widget.tableId,
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
