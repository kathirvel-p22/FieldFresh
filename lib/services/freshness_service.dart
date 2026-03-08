class FreshnessService {
  static int calculateScore({required DateTime harvestTime, required String category, required double farmerRating, required double distanceKm}) {
    final hoursOld = DateTime.now().difference(harvestTime).inHours;
    final maxHours = suggestValidityHours(category);
    final timeScore = ((1 - (hoursOld / maxHours)).clamp(0.0, 1.0) * 60).toInt();
    final ratingScore = ((farmerRating / 5.0) * 25).toInt();
    final distScore = ((1 - (distanceKm / 50.0)).clamp(0.0, 1.0) * 15).toInt();
    return (timeScore + ratingScore + distScore).clamp(0, 100);
  }

  static int suggestValidityHours(String category) {
    const h = {'leafy': 6,'herbs': 6,'dairy': 8,'vegetables': 12,'fruits': 24,'flowers': 24,'roots': 48,'grains': 168};
    return h[category] ?? 24;
  }

  static String getScoreLabel(int score) {
    if (score >= 85) return 'Ultra Fresh';
    if (score >= 70) return 'Very Fresh';
    if (score >= 55) return 'Fresh';
    if (score >= 40) return 'Good';
    return 'Aging';
  }

  static String getScoreEmoji(int score) {
    if (score >= 85) return '🌟';
    if (score >= 70) return '✅';
    if (score >= 55) return '🟡';
    if (score >= 40) return '🟠';
    return '🔴';
  }
}
