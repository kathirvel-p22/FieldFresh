import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/trust_service.dart';

class TrustScoreWidget extends StatefulWidget {
  final String userId;
  final bool showDetails;
  final double size;
  final bool isCompact;
  final bool isClickable;

  const TrustScoreWidget({
    super.key,
    required this.userId,
    this.showDetails = false,
    this.size = 80,
    this.isCompact = false,
    this.isClickable = true,
  });

  @override
  State<TrustScoreWidget> createState() => _TrustScoreWidgetState();
}

class _TrustScoreWidgetState extends State<TrustScoreWidget> {
  TrustScore? _trustScore;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrustScore();
  }

  Future<void> _loadTrustScore() async {
    try {
      final trustScore =
          await TrustService().calculateTrustScore(widget.userId);
      if (mounted) {
        setState(() {
          _trustScore = trustScore;
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

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_trustScore == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Icon(
          Icons.error_outline,
          size: widget.size * 0.6,
          color: Colors.grey,
        ),
      );
    }

    final score = _trustScore!.score;
    final scoreColor = _getScoreColor(score);

    Widget scoreWidget = CircularPercentIndicator(
      radius: widget.size / 2,
      lineWidth: widget.size * 0.1,
      percent: score / 100,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${score.toInt()}%',
            style: TextStyle(
              fontSize: widget.size * 0.2,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          if (widget.size > 80)
            Text(
              'Trust',
              style: TextStyle(
                fontSize: widget.size * 0.12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      progressColor: scoreColor,
      backgroundColor: Colors.grey[300]!,
      circularStrokeCap: CircularStrokeCap.round,
    );

    if (widget.isClickable) {
      scoreWidget = GestureDetector(
        onTap: () => _showTrustScoreDetails(context),
        child: scoreWidget,
      );
    }

    if (!widget.showDetails) {
      return scoreWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        scoreWidget,
        const SizedBox(height: 8),
        Text(
          _trustScore!.trustLevel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scoreColor,
          ),
        ),
        if (widget.showDetails) ...[
          const SizedBox(height: 4),
          Text(
            'Last updated: ${_formatDate(_trustScore!.lastUpdated)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
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

  void _showTrustScoreDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrustScoreDetailsSheet(trustScore: _trustScore!),
    );
  }
}

class TrustScoreDetailsSheet extends StatelessWidget {
  final TrustScore trustScore;

  const TrustScoreDetailsSheet({
    super.key,
    required this.trustScore,
  });

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
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trust Score Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            trustScore.displayText,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Verification levels
                const Text(
                  'Verification Levels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                ...VerificationLevel.values.map((level) {
                  final isCompleted =
                      trustScore.completedLevels[level] ?? false;
                  final weight = TrustService.weights[level]! * 100;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isCompleted ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            getVerificationLevelName(level),
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isCompleted ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        ),
                        Text(
                          '${weight.toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isCompleted ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Trust level indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trust Level: ${trustScore.trustLevel}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Last updated: ${formatDate(trustScore.lastUpdated)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getVerificationLevelName(VerificationLevel level) {
    switch (level) {
      case VerificationLevel.phone:
        return 'Phone Verification';
      case VerificationLevel.profile:
        return 'Profile Completion';
      case VerificationLevel.farm:
        return 'Farm Verification';
      case VerificationLevel.admin:
        return 'Admin Approval';
      case VerificationLevel.reputation:
        return 'Reputation System';
      case VerificationLevel.government:
        return 'Government ID (Optional)';
    }
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
