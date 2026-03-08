import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});
  @override
  State<DeliveryAddressesScreen> createState() =>
      _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': '1',
      'label': 'Home',
      'address': '123 Main Street, Chennai, Tamil Nadu 600001',
      'isDefault': true,
    },
    {
      'id': '2',
      'label': 'Office',
      'address': '456 Business Park, Chennai, Tamil Nadu 600002',
      'isDefault': false,
    },
  ];

  void _addAddress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Label (Home, Office, etc.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Full Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address added successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _setDefault(String id) {
    setState(() {
      for (var addr in _addresses) {
        addr['isDefault'] = addr['id'] == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default address updated')),
    );
  }

  void _deleteAddress(String id) {
    setState(() {
      _addresses.removeWhere((addr) => addr['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addAddress,
          ),
        ],
      ),
      body: _addresses.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📍', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 12),
                  Text('No saved addresses',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Add an address to get started',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                final isDefault = address['isDefault'] ?? false;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDefault
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.textHint.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isDefault ? Icons.home : Icons.location_on,
                        color:
                            isDefault ? AppColors.primary : AppColors.textHint,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          address['label'] ?? 'Address',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      address['address'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        if (!isDefault)
                          PopupMenuItem(
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Set as Default'),
                              ],
                            ),
                            onTap: () => _setDefault(address['id']),
                          ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () {},
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                          onTap: () => _deleteAddress(address['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAddress,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }
}
