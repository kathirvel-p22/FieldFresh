import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/enterprise_service_manager.dart';
import '../../services/enhanced_admin_service.dart';
import '../../services/trust_service.dart';

class EnterpriseDashboardScreen extends StatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  State<EnterpriseDashboardScreen> createState() =>
      _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _enterpriseManager = EnterpriseServiceManager();
  late TabController _tabController;

  AdminStats? _stats;
  List<Map<String, dynamic>> _flaggedUsers = [];
  List<TrustVerification> _pendingVerifications = [];
  List<AdminAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        _enterpriseManager.getAdminStats(),
        _enterpriseManager.getFlaggedUsers(),
        _enterpriseManager.trustService.getPendingVerifications(),
        _enterpriseManager.adminService.getAdminAlerts(limit: 20),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as AdminStats;
          _flaggedUsers = results[1] as List<Map<String, dynamic>>;
          _pendingVerifications = results[2] as List<TrustVerification>;
          _alerts = results[3] as List<AdminAlert>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Enterprise Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (_alerts.where((a) => !a.isRead).isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotifications,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Verifications'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildVerificationsTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_stats == null) return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Users',
                  _stats!.totalUsers.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Orders',
                  _stats!.totalOrders.toString(),
                  Icons.shopping_cart,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Revenue',
                  '₹${_stats!.totalRevenue.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Pending Reviews',
                  _stats!.pendingVerifications.toString(),
                  Icons.pending_actions,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // User Distribution
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: _stats!.totalFarmers.toDouble(),
                          title: 'Farmers\n${_stats!.totalFarmers}',
                          color: Colors.green,
                          radius: 80,
                        ),
                        PieChartSectionData(
                          value: _stats!.totalCustomers.toDouble(),
                          title: 'Customers\n${_stats!.totalCustomers}',
                          color: Colors.blue,
                          radius: 80,
                        ),
                      ],
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Alerts
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _showNotifications,
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_alerts.isEmpty)
                  const Center(
                    child: Text(
                      'No recent alerts',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ..._alerts.take(3).map((alert) => _buildAlertItem(alert)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flagged Users Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Flagged Users',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text('${_flaggedUsers.length}'),
                      backgroundColor: Colors.red[100],
                      labelStyle: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_flaggedUsers.isEmpty)
                  const Center(
                    child: Text(
                      'No flagged users',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ..._flaggedUsers.map((user) => _buildFlaggedUserItem(user)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Bulk Approve',
                        Icons.check_circle,
                        Colors.green,
                        _showBulkApproveDialog,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        'Fraud Analysis',
                        Icons.security,
                        Colors.orange,
                        _runFraudAnalysis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Verifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text('${_pendingVerifications.length}'),
                      backgroundColor: Colors.orange[100],
                      labelStyle: TextStyle(color: Colors.orange[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_pendingVerifications.isEmpty)
                  const Center(
                    child: Text(
                      'No pending verifications',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ..._pendingVerifications.map(
                      (verification) => _buildVerificationItem(verification)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_stats == null) return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revenue Trend (Last 12 Months)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getRevenueSpots(),
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Order Status Distribution
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Status Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._stats!.ordersByStatus.entries
                    .map((entry) => _buildStatusItem(entry.key, entry.value)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(AdminAlert alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.grey[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: alert.isRead ? Colors.grey[200]! : Colors.blue[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getAlertIcon(alert.priority),
              color: _getAlertColor(alert.priority),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatDate(alert.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlaggedUserItem(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: Text(
                user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user['role'] ?? 'Unknown Role',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveUser(user['id'], user['name']),
                ),
                IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  onPressed: () => _suspendUser(user['id'], user['name']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationItem(TrustVerification verification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(
              _getVerificationIcon(verification.level),
              color: Colors.orange[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getVerificationTitle(verification.level),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'User ID: ${verification.userId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveVerification(verification),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectVerification(verification),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String status, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getRevenueSpots() {
    final revenueData = _stats!.revenueByMonth;
    final spots = <FlSpot>[];

    int index = 0;
    for (final entry in revenueData.entries) {
      spots.add(FlSpot(index.toDouble(), entry.value));
      index++;
    }

    return spots;
  }

  IconData _getAlertIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getAlertColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getVerificationIcon(VerificationLevel level) {
    switch (level) {
      case VerificationLevel.phone:
        return Icons.phone;
      case VerificationLevel.profile:
        return Icons.person;
      case VerificationLevel.farm:
        return Icons.agriculture;
      case VerificationLevel.admin:
        return Icons.admin_panel_settings;
      case VerificationLevel.reputation:
        return Icons.star;
      case VerificationLevel.government:
        return Icons.badge;
    }
  }

  String _getVerificationTitle(VerificationLevel level) {
    switch (level) {
      case VerificationLevel.phone:
        return 'Phone Verification';
      case VerificationLevel.profile:
        return 'Profile Verification';
      case VerificationLevel.farm:
        return 'Farm Verification';
      case VerificationLevel.admin:
        return 'Admin Verification';
      case VerificationLevel.reputation:
        return 'Reputation Verification';
      case VerificationLevel.government:
        return 'Government ID Verification';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showNotifications() {
    // Implement notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications screen coming soon')),
    );
  }

  void _approveUser(String userId, String userName) async {
    try {
      await _enterpriseManager.approveUser(userId, 'Approved by admin');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName approved successfully')),
      );
      _loadDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve user: $e')),
      );
    }
  }

  void _suspendUser(String userId, String userName) async {
    try {
      await _enterpriseManager.suspendUser(
        userId,
        const Duration(days: 7),
        'Suspended by admin for review',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName suspended for 7 days')),
      );
      _loadDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to suspend user: $e')),
      );
    }
  }

  void _approveVerification(TrustVerification verification) async {
    try {
      await _enterpriseManager.adminService.approveFarmVerification(
        verification.id,
        'Approved by admin',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification approved')),
      );
      _loadDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve verification: $e')),
      );
    }
  }

  void _rejectVerification(TrustVerification verification) async {
    try {
      await _enterpriseManager.adminService.rejectFarmVerification(
        verification.id,
        'Rejected by admin',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification rejected')),
      );
      _loadDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject verification: $e')),
      );
    }
  }

  void _showBulkApproveDialog() {
    // Implement bulk approve dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk approve dialog coming soon')),
    );
  }

  void _runFraudAnalysis() {
    // Implement fraud analysis
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Running fraud analysis...')),
    );
  }
}
