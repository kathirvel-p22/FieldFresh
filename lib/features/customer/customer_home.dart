import 'package:flutter/material.dart';
import 'feed/customer_feed_screen.dart';
import 'farmers/nearby_farmers_screen.dart';
import 'order/customer_orders_screen.dart';
import 'group_buy/group_buy_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/customer_profile_screen.dart';
import 'wallet/customer_wallet_screen.dart';
import '../community/groups_list_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const CustomerFeedScreen(),
      const NearbyFarmersScreen(),
      const CustomerOrdersScreen(),
      const CustomerWalletScreen(), // Wallet
      const GroupBuyScreen(),
      const GroupsListScreen(), // Community Groups
      const NotificationsScreen(),
      const CustomerProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Market'),
          NavigationDestination(
              icon: Icon(Icons.agriculture_outlined),
              selectedIcon: Icon(Icons.agriculture),
              label: 'Farmers'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet'),
          NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Group Buy'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Community'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
