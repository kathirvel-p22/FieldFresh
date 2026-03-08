import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _harvestBlasts = true;
  bool _orderUpdates = true;
  bool _priceDrops = true;
  bool _groupBuyAlerts = true;
  bool _farmerUpdates = true;
  bool _expiryWarnings = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose what notifications you want to receive',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Product Alerts',
            [
              _buildSwitch(
                '🌾 Harvest Blasts',
                'Get notified when farmers post fresh produce nearby',
                _harvestBlasts,
                (val) => setState(() => _harvestBlasts = val),
              ),
              _buildSwitch(
                '💰 Price Drops',
                'Alert when prices drop on products you viewed',
                _priceDrops,
                (val) => setState(() => _priceDrops = val),
              ),
              _buildSwitch(
                '⏰ Expiry Warnings',
                'Reminder when products are about to expire',
                _expiryWarnings,
                (val) => setState(() => _expiryWarnings = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Order Updates',
            [
              _buildSwitch(
                '📦 Order Status',
                'Updates on order confirmation, packing, and delivery',
                _orderUpdates,
                (val) => setState(() => _orderUpdates = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Community',
            [
              _buildSwitch(
                '👥 Group Buy Alerts',
                'Notifications about group buying opportunities',
                _groupBuyAlerts,
                (val) => setState(() => _groupBuyAlerts = val),
              ),
              _buildSwitch(
                '👨‍🌾 Farmer Updates',
                'Updates from farmers you follow',
                _farmerUpdates,
                (val) => setState(() => _farmerUpdates = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Marketing',
            [
              _buildSwitch(
                '🎁 Promotions & Offers',
                'Special deals and promotional offers',
                _promotions,
                (val) => setState(() => _promotions = val),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change these settings anytime. Critical order updates will always be sent.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitch(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}
