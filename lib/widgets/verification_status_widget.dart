import 'package:flutter/material.dart';
import '../services/verification_service.dart';
import '../core/constants.dart';

class VerificationStatusWidget extends StatefulWidget {
  final String userId;
  final bool showProgress;
  final bool compact;
  
  const VerificationStatusWidget({
    super.key,
    required this.userId,
    this.showProgress = false,
    this.compact = false,
  });

  @override
  State<VerificationStatusWidget> createState() => _VerificationStatusWidgetState();
}

class _VerificationStatusWidgetState extends State<VerificationStatusWidget> {
  bool _isVerified = false;
  double _progress = 0.0;
  bool _loading = true;
  Map<VerificationType, VerificationStatus> _status = {};

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final isVerified = await VerificationService().isUserFullyVerified(widget.userId);
      final progress = await VerificationService().getVerificationProgress(widget.userId);
      final status = await VerificationService().getUserVerificationStatus(widget.userId);
      
      if (mounted) {
        setState(() {
          _isVerified = isVerified;
          _progress = progress;
          _status = status;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.compact 
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const CircularProgressIndicator();
    }

    if (widget.compact) {
      return _buildCompactWidget();
    }

    return _buildFullWidget();
  }

  Widget _buildCompactWidget() {
    if (_isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: Colors.white, size: 12),
            SizedBox(width: 2),
            Text(
              'Verified',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: Colors.white, size: 12),
          SizedBox(width: 2),
          Text(
            'Unverified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isVerified ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isVerified ? AppColors.success : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isVerified ? Icons.verified : Icons.warning,
                color: _isVerified ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isVerified ? 'Fully Verified' : 'Verification Incomplete',
                style: TextStyle(
                  color: _isVerified ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          if (widget.showProgress) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isVerified ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_progress * 100).toInt()}% Complete',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          
          if (!_isVerified) ...[
            const SizedBox(height: 8),
            Text(
              _getIncompleteMessage(),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _getIncompleteMessage() {
    final missing = <String>[];
    
    if (_status[VerificationType.phone] != VerificationStatus.approved) {
      missing.add('Phone');
    }
    if (_status[VerificationType.document] != VerificationStatus.approved) {
      missing.add('Document');
    }
    if (_status[VerificationType.location] != VerificationStatus.approved) {
      missing.add('Location');
    }
    if (_status[VerificationType.selfie] != VerificationStatus.approved) {
      missing.add('Selfie');
    }
    
    if (missing.isEmpty) {
      return 'Verification in progress';
    }
    
    return 'Missing: ${missing.join(', ')}';
  }
}