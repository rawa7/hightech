import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/admin_api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Order> _allOrders = [];
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, pending, Accepted, delivered

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedFilter = 'all';
              break;
            case 1:
              _selectedFilter = 'pending';
              break;
            case 2:
              _selectedFilter = 'Accepted';
              break;
            case 3:
              _selectedFilter = 'delivered';
              break;
          }
        });
      }
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    final orders = await AdminApiService.getAllOrders();

    setState(() {
      _allOrders = orders;
      _isLoading = false;
    });
  }

  List<Order> get _filteredOrders {
    if (_selectedFilter == 'all') {
      return _allOrders;
    }
    return _allOrders
        .where((order) => order.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  int _getOrderCountByStatus(String status) {
    if (status == 'all') return _allOrders.length;
    return _allOrders
        .where((order) => order.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    if (order.id == null) return;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await AdminApiService.updateOrderStatus(order.id!, newStatus);

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    if (result['success'] == true) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Reload orders
      await _loadOrders();
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update order'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${order.id ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1C69),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.createdAt != null ? _formatDate(order.createdAt!) : 'N/A',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Customer Info
                      _buildSectionTitle('Customer Information'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(Icons.person, 'Name', order.fullName ?? 'N/A'),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.email, 'Email', order.email ?? 'N/A'),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.phone, 'Phone', order.phone ?? 'N/A'),
                      ]),
                      const SizedBox(height: 20),

                      // Order Summary
                      _buildSectionTitle('Order Summary'),
                      const SizedBox(height: 12),
                      _buildInfoCard([
                        _buildInfoRow(
                          Icons.shopping_bag,
                          'Items',
                          '${order.itemCount ?? 0} item(s)',
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.attach_money,
                          'Total Amount',
                          '\$${order.totalAmount.toStringAsFixed(2)}',
                        ),
                        if (order.pointsUsed > 0) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.card_giftcard,
                            'Points Used',
                            '${order.pointsUsed} points',
                          ),
                        ],
                        if (order.totalPointsEarned != null && order.totalPointsEarned! > 0) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.stars,
                            'Points Earned',
                            '${order.totalPointsEarned} points',
                          ),
                        ],
                        if (order.isPointsOrder) ...[
                          const Divider(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Points Order',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 20),

                      // Items
                      _buildSectionTitle('Items'),
                      const SizedBox(height: 12),
                      if (order.items != null)
                        ...order.items!.map((item) => _buildOrderItemCard(item)),
                      const SizedBox(height: 20),

                      // Action Buttons
                      if (order.status.toLowerCase() != 'delivered') ...[
                        if (order.status.toLowerCase() == 'pending')
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateOrderStatus(order, 'Accepted');
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text(
                                'Accept Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF316AE9),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (order.status.toLowerCase() == 'accepted') ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateOrderStatus(order, 'delivered');
                              },
                              icon: const Icon(Icons.local_shipping),
                              label: const Text(
                                'Mark as Delivered',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1C69),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Orders Management',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: false,
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('All', style: TextStyle(fontSize: 13)),
                  Text(
                    '${_getOrderCountByStatus('all')}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending', style: TextStyle(fontSize: 13)),
                  Text(
                    '${_getOrderCountByStatus('pending')}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Accepted', style: TextStyle(fontSize: 13)),
                  Text(
                    '${_getOrderCountByStatus('accepted')}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Delivered', style: TextStyle(fontSize: 13)),
                  Text(
                    '${_getOrderCountByStatus('delivered')}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderListWithSubTabs('all'),
                _buildOrderListWithSubTabs('pending'),
                _buildOrderListWithSubTabs('accepted'),
                _buildOrderListWithSubTabs('delivered'),
              ],
            ),
    );
  }

  Widget _buildOrderListWithSubTabs(String status) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF1E1C69),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF316AE9),
              tabs: [
                Tab(
                  icon: Icon(Icons.shopping_cart, size: 20),
                  text: 'Normal Orders',
                ),
                Tab(
                  icon: Icon(Icons.card_giftcard, size: 20),
                  text: 'Points Orders',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrderList(status, false), // Normal orders
                _buildOrderList(status, true),  // Points orders
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status, bool isPointsOrder) {
    List<Order> orders;
    if (status == 'all') {
      orders = _allOrders.where((order) => order.isPointsOrder == isPointsOrder).toList();
    } else {
      orders = _allOrders
          .where((order) =>
              order.status.toLowerCase() == status.toLowerCase() &&
              order.isPointsOrder == isPointsOrder)
          .toList();
    }

    // Debug logging
    debugPrint('📊 Admin Dashboard Filter:');
    debugPrint('   Status: $status, isPointsOrder: $isPointsOrder');
    debugPrint('   Total orders: ${_allOrders.length}');
    debugPrint('   Filtered orders: ${orders.length}');
    
    // Show order details for debugging
    for (var order in _allOrders) {
      debugPrint('   Order #${order.id}: status=${order.status}, isPoints=${order.isPointsOrder}, amount=${order.totalAmount}, pointsUsed=${order.pointsUsed}');
    }

    if (orders.isEmpty) {
      return _buildEmptyState(isPointsOrder);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isPointsOrder) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPointsOrder ? Icons.card_giftcard : Icons.shopping_bag_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isPointsOrder ? 'No points orders found' : 'No normal orders found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1C69),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.createdAt != null ? _formatDate(order.createdAt!) : 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Customer Info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.fullName ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    order.phone ?? 'N/A',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Order Summary
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildSummaryItem(
                    Icons.shopping_bag,
                    '${order.itemCount ?? 0} items',
                  ),
                  _buildSummaryItem(
                    Icons.attach_money,
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                  ),
                  if (order.isPointsOrder)
                    _buildSummaryItem(
                      Icons.card_giftcard,
                      '${order.pointsUsed} pts',
                    )
                  else if (order.totalPointsEarned != null && order.totalPointsEarned! > 0)
                    _buildSummaryItem(
                      Icons.stars,
                      '+${order.totalPointsEarned} pts',
                    ),
                ],
              ),

              // Action Buttons
              if (order.status.toLowerCase() != 'delivered') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (order.status.toLowerCase() == 'pending')
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(order, 'Accepted'),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF316AE9),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (order.status.toLowerCase() == 'accepted')
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _updateOrderStatus(order, 'delivered'),
                          icon: const Icon(Icons.local_shipping, size: 18),
                          label: const Text('Deliver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => _showOrderDetails(order),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showOrderDetails(order),
                    child: const Text('View Details →'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'accepted':
        color = const Color(0xFF316AE9);
        icon = Icons.check_circle;
        break;
      case 'delivered':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.toLowerCase() == 'accepted' ? 'Accepted' : 
            status.toLowerCase() == 'delivered' ? 'Delivered' : 
            'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E1C69),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.brandName != null)
                    Text(
                      item.brandName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Qty: ${item.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '\$${(item.unitPrice ?? item.productPrice ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF316AE9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Total Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1C69),
                  ),
                ),
                if (item.pointsEarned > 0)
                  Text(
                    '+${item.pointsEarned} pts',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }
}
