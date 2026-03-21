import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';
import '../../services/image_service.dart';

class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});
  @override
  State<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _farmers = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';

  final _statusFilters = ['all', 'active', 'inactive', 'deleted'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final products = await SupabaseService.getAllProducts();
      final farmers = await SupabaseService.getAllFarmers();
      setState(() {
        _products = products;
        _farmers = farmers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          (product['name']?.toLowerCase() ?? '')
              .contains(_searchQuery.toLowerCase()) ||
          (product['users']?['name']?.toLowerCase() ?? '')
              .contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatus == 'all' || product['status'] == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    // Sort by created_at descending
    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _showAddProductDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search products or farmers...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),

                // Status filter chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    itemBuilder: (context, index) {
                      final status = _statusFilters[index];
                      final isSelected = _selectedStatus == status;
                      final count = status == 'all'
                          ? _products.length
                          : _products
                              .where((p) => p['status'] == status)
                              .length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${_capitalize(status)} ($count)'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedStatus = status);
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: AppColors.secondary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Products list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No products found for "$_searchQuery"'
                                  : 'No products found',
                              style: const TextStyle(
                                  fontSize: 16, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final status = product['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product['image_urls'] != null &&
                          (product['image_urls'] as List).isNotEmpty
                      ? Image.network(
                          product['image_urls'][0],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, size: 30),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2, size: 30),
                        ),
                ),
                const SizedBox(width: 12),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product['name'] ?? 'Unknown Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By: ${product['users']?['name'] ?? 'Unknown Farmer'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${product['price_per_unit']}/kg',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${product['quantity_left']} ${product['unit']} left',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                if (status != 'deleted') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProductDialog(product),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleProductStatus(product),
                      icon: Icon(
                        status == 'active'
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 16,
                      ),
                      label:
                          Text(status == 'active' ? 'Deactivate' : 'Activate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: status == 'active'
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _deleteProduct(product),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Icon(Icons.delete, size: 16),
                  ),
                ] else ...[
                  // For deleted products, show restore and permanent delete options
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreProduct(product),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Restore'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _permanentlyDeleteProduct(product),
                      icon: const Icon(Icons.delete_forever, size: 16),
                      label: const Text('Delete Forever'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'inactive':
        return AppColors.warning;
      case 'deleted':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        farmers: _farmers,
        onSave: (productData) async {
          try {
            await SupabaseService.createProduct(productData);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product created successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creating product: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        farmers: _farmers,
        product: product,
        onSave: (productData) async {
          try {
            await SupabaseService.updateProduct(product['id'], productData);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product updated successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating product: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _toggleProductStatus(Map<String, dynamic> product) async {
    final currentStatus = product['status'];
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';

    try {
      await SupabaseService.updateProduct(product['id'], {'status': newStatus});
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Product ${newStatus == 'active' ? 'activated' : 'deactivated'}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${product['name']}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• If this product has orders, it will be hidden from marketplace but preserved in database\n'
                    '• If no orders exist, it will be permanently deleted\n'
                    '• This action cannot be undone for permanently deleted products',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting product...'),
            ],
          ),
        ),
      );

      try {
        final result = await SupabaseService.deleteProduct(product['id']);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (result['success']) {
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ ${result['productName']} deleted successfully'),
                    const SizedBox(height: 4),
                    Text(
                      result['message'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('❌ Failed to delete ${product['name']}'),
                    const SizedBox(height: 4),
                    Text(
                      result['message'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting product: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Product'),
        content: Text(
          'Are you sure you want to restore "${product['name']}"?\n\nThis will make it available in the marketplace again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.updateProduct(
            product['id'], {'status': 'active'});
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product restored successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error restoring product: $e')),
          );
        }
      }
    }
  }

  Future<void> _permanentlyDeleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Are you sure you want to PERMANENTLY delete "${product['name']}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Text('Important:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Products with order history cannot be permanently deleted to preserve business records. If this product has orders, it will remain marked as "deleted" but hidden from customers.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Try Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Attempting permanent deletion...'),
            ],
          ),
        ),
      );

      try {
        final result =
            await SupabaseService.permanentlyDeleteProduct(product['id']);

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (result['success']) {
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ ${result['productName']} permanently deleted'),
                    const SizedBox(height: 4),
                    Text(
                      result['message'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('❌ Cannot permanently delete ${product['name']}'),
                    const SizedBox(height: 4),
                    Text(
                      result['message'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 6),
              ),
            );
          }
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          // Show detailed error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Cannot Permanently Delete'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This product cannot be permanently deleted because it has order history.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text('Why this happens:'),
                  const SizedBox(height: 4),
                  const Text('• The product has existing orders'),
                  const Text('• Deleting it would break order records'),
                  const Text('• This protects your business data'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.success, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Good news: The product is already hidden from customers and marked as deleted.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class ProductFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> farmers;
  final Map<String, dynamic>? product;
  final Function(Map<String, dynamic>) onSave;

  const ProductFormDialog({
    super.key,
    required this.farmers,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();

  String? _selectedFarmerId;
  String _selectedStatus = 'active';
  List<String> _imageUrls = [];
  bool _uploading = false;

  final _statusOptions = ['active', 'inactive'];
  final _unitOptions = ['kg', 'gram', 'piece', 'liter', 'dozen'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final product = widget.product!;
    _nameController.text = product['name'] ?? '';
    _descriptionController.text = product['description'] ?? '';
    _priceController.text = product['price_per_unit']?.toString() ?? '';
    _quantityController.text = product['quantity_left']?.toString() ?? '';
    _unitController.text = product['unit'] ?? 'kg';
    _selectedFarmerId = product['farmer_id'];
    _selectedStatus = product['status'] ?? 'active';
    _imageUrls = List<String>.from(product['image_urls'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.product == null ? 'Add Product' : 'Edit Product',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farmer selection
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFarmerId,
                        decoration: const InputDecoration(
                          labelText: 'Farmer',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.farmers
                            .map<DropdownMenuItem<String>>((farmer) {
                          return DropdownMenuItem<String>(
                            value: farmer['id'],
                            child: Text(farmer['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedFarmerId = value),
                        validator: (value) =>
                            value == null ? 'Please select a farmer' : null,
                      ),

                      const SizedBox(height: 16),

                      // Product name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter product name'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),

                      // Price and quantity row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price per Unit (₹)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty == true
                                  ? 'Please enter price'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity Available',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty == true
                                  ? 'Please enter quantity'
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Unit and status row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _unitController.text.isNotEmpty
                                  ? _unitController.text
                                  : 'kg',
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                              items: _unitOptions.map((unit) {
                                return DropdownMenuItem(
                                    value: unit, child: Text(unit));
                              }).toList(),
                              onChanged: (value) =>
                                  _unitController.text = value ?? 'kg',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: _statusOptions.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) => setState(
                                  () => _selectedStatus = value ?? 'active'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Images section
                      const Text(
                        'Product Images',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // Image grid
                      if (_imageUrls.isNotEmpty) ...[
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageUrls.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _imageUrls[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _imageUrls.removeAt(index)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Add image button
                      OutlinedButton.icon(
                        onPressed: _uploading ? null : _pickAndUploadImage,
                        icon: _uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate),
                        label: Text(_uploading ? 'Uploading...' : 'Add Image'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: Text(widget.product == null ? 'Create' : 'Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _uploading = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final imageUrl = await ImageService.uploadImage(image);
        if (imageUrl != null) {
          setState(() => _imageUrls.add(imageUrl));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() == true) {
      final productData = {
        'farmer_id': _selectedFarmerId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price_per_unit': double.tryParse(_priceController.text) ?? 0,
        'quantity_left': double.tryParse(_quantityController.text) ?? 0,
        'unit': _unitController.text.trim(),
        'status': _selectedStatus,
        'image_urls': _imageUrls,
      };

      widget.onSave(productData);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }
}
