import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/navigation_guard.dart';
import '../core/constants.dart';

class SecureLogoutButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final bool showConfirmation;
  final VoidCallback? onLogoutComplete;

  const SecureLogoutButton({
    super.key,
    this.icon = Icons.logout,
    this.text,
    this.showConfirmation = true,
    this.onLogoutComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final isLoggingOut = authService.isLoggingOut;
        
        if (text != null) {
          // Text button version
          return TextButton.icon(
            onPressed: isLoggingOut ? null : () => _handleLogout(context, authService),
            icon: isLoggingOut 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: AppColors.error),
            label: Text(
              isLoggingOut ? 'Signing out...' : text!,
              style: TextStyle(
                color: isLoggingOut ? Colors.grey : AppColors.error,
              ),
            ),
          );
        } else {
          // Icon button version
          return IconButton(
            onPressed: isLoggingOut ? null : () => _handleLogout(context, authService),
            icon: isLoggingOut 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: AppColors.error),
            tooltip: isLoggingOut ? 'Signing out...' : 'Sign Out',
          );
        }
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthService authService) async {
    bool shouldLogout = true;

    // Show confirmation dialog if requested
    if (showConfirmation) {
      shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: AppColors.error),
              SizedBox(width: 8),
              Text('Sign Out'),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out?\n\nYou will need to log in again to access your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ) ?? false;
    }

    if (shouldLogout && context.mounted) {
      try {
        // Perform secure logout with navigation handling
        await NavigationGuard.secureLogout(context);

        // Call completion callback
        onLogoutComplete?.call();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Signed out successfully'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}

// Specialized logout button for list tiles (like in profile screens)
class LogoutListTile extends StatelessWidget {
  final VoidCallback? onLogoutComplete;

  const LogoutListTile({
    super.key,
    this.onLogoutComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final isLoggingOut = authService.isLoggingOut;
        
        return ListTile(
          leading: isLoggingOut 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout, color: AppColors.error),
          title: Text(
            isLoggingOut ? 'Signing out...' : 'Sign Out',
            style: TextStyle(
              color: isLoggingOut ? Colors.grey : AppColors.error,
            ),
          ),
          subtitle: Text(
            'Signed in as ${authService.currentUser?['name'] ?? 'User'}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: isLoggingOut ? null : () => _handleLogout(context, authService),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthService authService) async {
    final secureLogout = SecureLogoutButton(onLogoutComplete: onLogoutComplete);
    await secureLogout._handleLogout(context, authService);
  }
}