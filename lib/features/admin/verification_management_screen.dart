import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../services/verification_service.dart';
import '../../services/supabase_service.dart';

class VerificationManagementScreen extends StatefulWidget {
  const VerificationManagementScreen({super.key});

  @override
  State<VerificationManagementScreen> createState() => _VerificationManagementScreenState();
}

class _VerificationManagementScreenState extends State<VerificationManagementScreen> {
  List<VerificationDocument> _pendingVerifications = [];
  bool _loading = true;
  String _selectedFilter = 'all';
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, String> _filterLabels = {
    'all': 'All Pending',
    'phone': 'Phone Verification',
    'document': 'Document Verification',
    'location': 'Location Verification',
    'selfie': 'Selfie Verification',
    'address': 'Address Verification',
  };

  @override
  void initState() {
    super.initState();
    _loadPendingVerifications();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() => _loading = true);
    try {
      // Get all pending verifications from database
      final verifications = await _supabase
          .from('user_verifications')
          .select('*, users!inner(name, role, phone)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        _pendingVerifications = verifications
            .map((v) => VerificationDocument.fromJson(v))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load verifications: $e')),
        );
      }
    }
  }

  List<VerificationDocument> get _filteredVerifications {
    if (_selectedFilter == 'all') return _pendingVerifications;
    return _pendingVerifications
        .where((v) => v.type.name == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPendingVerifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterLabels.length,
              itemBuilder: (context, index) {
                final filter = _filterLabels.keys.elementAt(index);
                final label = _filterLabels[filter]!;
                final isSelected = _selectedFilter == filter;
                final count = filter == 'all'
                    ? _pendingVerifications.length
                    : _pendingVerifications.where((v) => v.type.name == filter).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('$label ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Verifications list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVerifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'all'
                                  ? 'No pending verifications'
                                  : 'No pending ${_filterLabels[_selectedFilter]?.toLowerCase()}',
                              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPendingVerifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredVerifications.length,
                          itemBuilder: (context, index) {
                            final verification = _filteredVerifications[index];
                            return _buildVerificationCard(verification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(VerificationDocument verification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getTypeColor(verification.type),
                  child: Icon(
                    _getTypeIcon(verification.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeTitle(verification.type),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        verification.documentType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // User info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'User ID: ${verification.userId}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Images
            if (verification.imageUrls.isNotEmpty) ...[
              const Text(
                'Submitted Images:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: verification.imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _showImageDialog(verification.imageUrls[index]),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: verification.imageUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Extracted data
            if (verification.extractedData.isNotEmpty) ...[
              const Text(
                'Submitted Data:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: verification.extractedData.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Submission time
            Text(
              'Submitted: ${_formatDateTime(verification.createdAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectVerification(verification),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveVerification(verification),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Verification Image'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, size: 64),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveVerification(VerificationDocument verification) async {
    final adminId = SupabaseService.currentUserId;
    if (adminId == null) return;

    try {
      await VerificationService().approveVerification(
        verification.id,
        adminId,
        notes: 'Approved by admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPendingVerifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve verification: $e')),
        );
      }
    }
  }

  Future<void> _rejectVerification(VerificationDocument verification) async {
    final adminId = SupabaseService.currentUserId;
    if (adminId == null) return;

    // Show reason dialog
    final reason = await _showReasonDialog();
    if (reason == null || reason.isEmpty) return;

    try {
      await VerificationService().rejectVerification(
        verification.id,
        adminId,
        reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification rejected'),
            backgroundColor: AppColors.error,
          ),
        );
        _loadPendingVerifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject verification: $e')),
        );
      }
    }
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter the reason why this verification is being rejected',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(VerificationType type) {
    switch (type) {
      case VerificationType.phone:
        return AppColors.primary;
      case VerificationType.document:
        return AppColors.secondary;
      case VerificationType.location:
        return AppColors.info;
      case VerificationType.selfie:
        return AppColors.accent;
      case VerificationType.address:
        return AppColors.warning;
    }
  }

  IconData _getTypeIcon(VerificationType type) {
    switch (type) {
      case VerificationType.phone:
        return Icons.phone;
      case VerificationType.document:
        return Icons.description;
      case VerificationType.location:
        return Icons.location_on;
      case VerificationType.selfie:
        return Icons.face;
      case VerificationType.address:
        return Icons.home;
    }
  }

  String _getTypeTitle(VerificationType type) {
    switch (type) {
      case VerificationType.phone:
        return 'Phone Verification';
      case VerificationType.document:
        return 'Document Verification';
      case VerificationType.location:
        return 'Location Verification';
      case VerificationType.selfie:
        return 'Selfie Verification';
      case VerificationType.address:
        return 'Address Verification';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
}