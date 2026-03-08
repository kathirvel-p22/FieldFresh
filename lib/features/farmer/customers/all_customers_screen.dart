import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class AllCustomersScreen extends StatefulWidget {
  const AllCustomersScreen({super.key});
  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllCustomers();
      setState(() {
        _customers = data;
        _loading = false;
      });
    } catch (e) {
      print('Error loading customers: $e');
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((customer) {
      final name = (customer['name'] ?? '').toString().toLowerCase();
      final phone = (customer['phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Customers'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // Customers list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('👥', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No customers found for "$_searchQuery"'
                                  : 'No customers yet',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            return _buildCustomerCard(customer);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = customer['name'] ?? 'Customer';
    final phone = customer['phone'] ?? '';
    final profileImage = customer['profile_image'];
    final rating = (customer['rating'] as num?)?.toDouble() ?? 0.0;
    final village = customer['village'] ?? '';
    final city = customer['city'] ?? '';
    final district = customer['district'] ?? '';
    final state = customer['state'] ?? '';

    // Build location string
    String locationStr = '';
    if (village.isNotEmpty) locationStr += village;
    if (city.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + city;
    if (district.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + district;
    if (state.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + state;
    if (locationStr.isEmpty) locationStr = 'Location not set';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Image
            profileImage != null
                ? CircleAvatar(
                    radius: 32,
                    backgroundImage: CachedNetworkImageProvider(profileImage),
                  )
                : CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 32, color: AppColors.primary),
                  ),
            const SizedBox(width: 16),
            // Customer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Contact button
            IconButton(
              onPressed: () {
                // Show contact options
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Contact $name'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Call'),
                          subtitle: Text(phone),
                          onTap: () {
                            Navigator.pop(context);
                            // Implement call functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling $phone...')),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.message),
                          title: const Text('Message'),
                          subtitle: Text(phone),
                          onTap: () {
                            Navigator.pop(context);
                            // Implement message functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Messaging $phone...')),
                            );
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.phone, color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
