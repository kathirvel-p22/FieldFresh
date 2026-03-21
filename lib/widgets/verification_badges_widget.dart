import 'package:flutter/material.dart';
import '../services/verification_badge_service.dart';
import '../services/enterprise_service_manager.dart';

class VerificationBadgesWidget extends StatefulWidget {
  final String userId;
  final int maxBadges;
  final double badgeSize;
  final bool showLabels;
  final MainAxisAlignment alignment;

  const VerificationBadgesWidget({
    super.key,
    required this.userId,
    this.maxBadges = 5,
    this.badgeSize = 24.0,
    this.showLabels = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  State<VerificationBadgesWidget> createState() =>
      _VerificationBadgesWidgetState();
}

class _VerificationBadgesWidgetState extends State<VerificationBadgesWidget> {
  final _enterpriseManager = EnterpriseServiceManager();
  List<VerificationBadge> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _enterpriseManager.getUserBadges(widget.userId);
      if (mounted) {
        setState(() {
          _badges = badges.take(widget.maxBadges).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.badgeSize,
        child: Row(
          mainAxisAlignment: widget.alignment,
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: widget.badgeSize,
                height: widget.badgeSize,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_badges.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.showLabels) {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _badges.map((badge) => _buildBadgeChip(badge)).toList(),
      );
    }

    return Row(
      mainAxisAlignment: widget.alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._badges.map((badge) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildBadgeIcon(badge),
            )),
        if (_badges.length >= widget.maxBadges)
          GestureDetector(
            onTap: () => _showAllBadges(context),
            child: Container(
              width: widget.badgeSize,
              height: widget.badgeSize,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_horiz,
                size: widget.badgeSize * 0.6,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadgeIcon(VerificationBadge badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge),
      child: Container(
        width: widget.badgeSize,
        height: widget.badgeSize,
        decoration: BoxDecoration(
          color: _parseColor(badge.color),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          _getIconData(badge.iconName),
          size: widget.badgeSize * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBadgeChip(VerificationBadge badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _parseColor(badge.color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _parseColor(badge.color).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconData(badge.iconName),
              size: 16,
              color: _parseColor(badge.color),
            ),
            const SizedBox(width: 4),
            Text(
              badge.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _parseColor(badge.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'videocam':
        return Icons.videocam;
      case 'radio_button_checked':
        return Icons.radio_button_checked;
      case 'flash_on':
        return Icons.flash_on;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'verified':
        return Icons.verified;
      case 'new_releases':
        return Icons.new_releases;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'shield':
        return Icons.shield;
      default:
        return Icons.badge;
    }
  }

  void _showBadgeDetails(BuildContext context, VerificationBadge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconData(badge.iconName),
              color: _parseColor(badge.color),
            ),
            const SizedBox(width: 8),
            Text(badge.displayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: 8),
            Text(
              'Earned: ${_formatDate(badge.earnedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (badge.expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Expires: ${_formatDate(badge.expiresAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAllBadges(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AllBadgesSheet(userId: widget.userId),
    );
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
}

class AllBadgesSheet extends StatefulWidget {
  final String userId;

  const AllBadgesSheet({
    super.key,
    required this.userId,
  });

  @override
  State<AllBadgesSheet> createState() => _AllBadgesSheetState();
}

class _AllBadgesSheetState extends State<AllBadgesSheet> {
  final _enterpriseManager = EnterpriseServiceManager();
  List<VerificationBadge> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllBadges();
  }

  Future<void> _loadAllBadges() async {
    try {
      final badges = await _enterpriseManager.getUserBadges(widget.userId);
      if (mounted) {
        setState(() {
          _badges = badges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Row(
                  children: [
                    Icon(
                      Icons.badge,
                      color: Colors.blue,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'All Verification Badges',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_badges.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No badges earned yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(_badges.length, (index) {
                    final badge = _badges[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _parseColor(badge.color),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconData(badge.iconName),
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    badge.displayName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    badge.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Earned ${_formatDate(badge.earnedAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'videocam':
        return Icons.videocam;
      case 'radio_button_checked':
        return Icons.radio_button_checked;
      case 'flash_on':
        return Icons.flash_on;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'verified':
        return Icons.verified;
      case 'new_releases':
        return Icons.new_releases;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'shield':
        return Icons.shield;
      default:
        return Icons.badge;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }
}
